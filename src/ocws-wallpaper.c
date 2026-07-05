#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <signal.h>
#include <time.h>
#include <math.h>
#include <cairo/cairo.h>

#define CHECK_INTERVAL_SEC 60

struct WallpaperState {
    cairo_surface_t *current_img;
    cairo_surface_t *next_img;
    double crossfade;
    int transitioning;
    int crossfade_ms;

    char current_path[512];
    char next_path[512];
};

static struct WallpaperState state = {0};
static volatile int running = 1;

static void on_signal(int sig) {
    (void)sig;
    running = 0;
}

static time_t get_time_of_day_slot(void) {
    time_t now = time(NULL);
    struct tm *tm = localtime(&now);
    int hour = tm->tm_hour;

    if (hour >= 5 && hour < 7) return 0;
    if (hour >= 7 && hour < 12) return 1;
    if (hour >= 12 && hour < 17) return 2;
    if (hour >= 17 && hour < 20) return 3;
    if (hour >= 20 && hour < 22) return 4;
    return 5;
}

static const char *slot_name(time_t slot) {
    static const char *names[] = {"dawn", "morning", "afternoon", "evening", "dusk", "night"};
    if (slot < 6) return names[slot];
    return "unknown";
}

static int find_wallpaper(const char *dir, time_t slot, char *out, size_t outlen) {
    char pattern[1024];
    snprintf(pattern, sizeof(pattern), "%s/*%s*", dir, slot_name(slot));

    char cmd[2048];
    snprintf(cmd, sizeof(cmd), "ls %s 2>/dev/null | head -1", pattern);

    FILE *f = popen(cmd, "r");
    if (!f) return -1;

    if (fgets(out, outlen, f)) {
        size_t len = strlen(out);
        if (len > 0 && out[len - 1] == '\n') out[len - 1] = '\0';
        pclose(f);
        return 0;
    }

    pclose(f);
    return -1;
}

static void transition_to(const char *path) {
    if (strcmp(path, state.current_path) == 0) return;

    cairo_surface_t *new_img = cairo_image_surface_create_from_png(path);
    if (cairo_surface_status(new_img) != CAIRO_STATUS_SUCCESS) {
        fprintf(stderr, "ocws-wallpaper: failed to load %s\n", path);
        cairo_surface_destroy(new_img);
        return;
    }

    if (state.next_img) cairo_surface_destroy(state.next_img);
    state.next_img = new_img;
    strncpy(state.next_path, path, sizeof(state.next_path) - 1);
    state.transitioning = 1;
    state.crossfade = 0.0;

    fprintf(stderr, "ocws-wallpaper: transitioning to %s\n", path);
}

static void check_and_update(const char *wallpaper_dir) {
    time_t slot = get_time_of_day_slot();
    char path[512];

    if (find_wallpaper(wallpaper_dir, slot, path, sizeof(path)) == 0) {
        transition_to(path);
    } else {
        snprintf(path, sizeof(path), "%s/wallpaper.png", wallpaper_dir);
        if (access(path, R_OK) == 0)
            transition_to(path);
    }
}

static double ease_in_out(double t) {
    return t < 0.5 ? 2 * t * t : 1 - pow(-2 * t + 2, 2) / 2;
}

static void usage(const char *prog) {
    fprintf(stderr,
        "Usage: %s [OPTIONS] <wallpaper-directory>\n\n"
        "Dynamic wallpaper engine — time-of-day wallpaper transitions.\n\n"
        "Wallpapers should be named with time slots:\n"
        "  <dir>/dawn-*.png      05:00 - 07:00\n"
        "  <dir>/morning-*.png   07:00 - 12:00\n"
        "  <dir>/afternoon-*.png 12:00 - 17:00\n"
        "  <dir>/evening-*.png   17:00 - 20:00\n"
        "  <dir>/dusk-*.png      20:00 - 22:00\n"
        "  <dir>/night-*.png     22:00 - 05:00\n\n"
        "Falls back to <dir>/wallpaper.png if no slot match.\n\n"
        "Outputs the selected wallpaper path on slot change.\n"
        "Designed to be polled by a Wayland wallpaper layer.\n\n"
        "Options:\n"
        "  -i SEC     Check interval in seconds (default: 60)\n"
        "  -w         Print wallpaper path on each check (for scripting)\n"
        "  -h         Show this help\n\n"
        "Examples:\n"
        "  %s ~/wallpapers/\n"
        "  %s -i 30 ~/wallpapers/\n"
        "  %s -w ~/wallpapers/ | while read f; do swaybg -i \"$f\" -m fill; done\n",
        prog, prog, prog, prog);
}

int main(int argc, char *argv[]) {
    int interval = CHECK_INTERVAL_SEC;
    int print_path = 0;

    int argi = 1;
    while (argi < argc && argv[argi][0] == '-') {
        if (strcmp(argv[argi], "-i") == 0 && argi + 1 < argc)
            interval = atoi(argv[++argi]);
        else if (strcmp(argv[argi], "-w") == 0)
            print_path = 1;
        else if (strcmp(argv[argi], "-h") == 0 || strcmp(argv[argi], "--help") == 0) {
            usage(argv[0]);
            return 0;
        } else break;
        argi++;
    }

    if (argi >= argc) {
        usage(argv[0]);
        return 1;
    }

    const char *wallpaper_dir = argv[argi];
    if (access(wallpaper_dir, R_OK | X_OK) != 0) {
        fprintf(stderr, "error: cannot access directory: %s\n", wallpaper_dir);
        return 1;
    }

    signal(SIGINT, on_signal);
    signal(SIGTERM, on_signal);

    fprintf(stderr, "ocws-wallpaper: started, dir=%s interval=%ds\n",
        wallpaper_dir, interval);

    check_and_update(wallpaper_dir);

    if (print_path && state.current_path[0])
        printf("%s\n", state.current_path);

    time_t last_check = time(NULL);

    while (running) {
        time_t now = time(NULL);

        if (state.transitioning) {
            state.crossfade += (double)interval / state.crossfade_ms;
            if (state.crossfade >= 1.0) {
                state.crossfade = 1.0;
                state.transitioning = 0;
                if (state.current_img) cairo_surface_destroy(state.current_img);
                state.current_img = state.next_img;
                state.next_img = NULL;
                strncpy(state.current_path, state.next_path, sizeof(state.current_path));
                fprintf(stderr, "ocws-wallpaper: transition complete -> %s\n", state.current_path);
            }
        }

        if (now - last_check >= interval) {
            check_and_update(wallpaper_dir);
            if (print_path && state.current_path[0])
                printf("%s\n", state.current_path);
            last_check = now;
        }

        usleep(500000);
    }

    if (state.current_img) cairo_surface_destroy(state.current_img);
    if (state.next_img) cairo_surface_destroy(state.next_img);

    fprintf(stderr, "ocws-wallpaper: shutdown\n");
    return 0;
}
