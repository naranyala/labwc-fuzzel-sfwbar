#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <math.h>
#include <dirent.h>
#include <time.h>

static int get_max_brightness(void) {
    DIR *d = opendir("/sys/class/backlight");
    if (!d) return -1;

    struct dirent *dir;
    int max_b = -1;
    while ((dir = readdir(d)) != NULL) {
        if (dir->d_name[0] == '.') continue;
        char path[256];
        snprintf(path, sizeof(path), "/sys/class/backlight/%s/max_brightness", dir->d_name);
        FILE *f = fopen(path, "r");
        if (f) { fscanf(f, "%d", &max_b); fclose(f); break; }
    }
    closedir(d);
    return max_b;
}

static int get_brightness(void) {
    DIR *d = opendir("/sys/class/backlight");
    if (!d) return -1;

    struct dirent *dir;
    int cur = -1;
    while ((dir = readdir(d)) != NULL) {
        if (dir->d_name[0] == '.') continue;
        char path[256];
        snprintf(path, sizeof(path), "/sys/class/backlight/%s/brightness", dir->d_name);
        FILE *f = fopen(path, "r");
        if (f) { fscanf(f, "%d", &cur); fclose(f); break; }
    }
    closedir(d);
    return cur;
}

static int set_brightness_raw(int value) {
    DIR *d = opendir("/sys/class/backlight");
    if (!d) return -1;

    struct dirent *dir;
    int ret = -1;
    while ((dir = readdir(d)) != NULL) {
        if (dir->d_name[0] == '.') continue;
        char path[256];
        snprintf(path, sizeof(path), "/sys/class/backlight/%s/brightness", dir->d_name);
        FILE *f = fopen(path, "w");
        if (f) { fprintf(f, "%d\n", value); fclose(f); ret = 0; break; }
    }
    closedir(d);
    return ret;
}

static double ease_out_cubic(double t) {
    return 1.0 - pow(1.0 - t, 3);
}

static void animate_to(int target, int duration_ms) {
    int max_b = get_max_brightness();
    if (max_b <= 0) { set_brightness_raw(target); return; }

    int cur = get_brightness();
    if (cur < 0) cur = target;

    if (cur == target) return;

    int steps = duration_ms / 8;
    if (steps < 1) steps = 1;

    double start_val = (double)cur;
    double end_val = (double)target;

    for (int i = 1; i <= steps; i++) {
        double t = (double)i / steps;
        double eased = ease_out_cubic(t);
        int val = (int)(start_val + (end_val - start_val) * eased + 0.5);
        if (val < 0) val = 0;
        if (val > max_b) val = max_b;
        set_brightness_raw(val);
        usleep(8000);
    }

    set_brightness_raw(target);
}

static void pct(int percent) {
    int max_b = get_max_brightness();
    if (max_b <= 0) { fprintf(stderr, "error: no backlight found\n"); return; }
    if (percent < 0) percent = 0;
    if (percent > 100) percent = 100;
    int target = (max_b * percent) / 100;
    animate_to(target, 200);
}

static void adjust(int delta) {
    int max_b = get_max_brightness();
    if (max_b <= 0) { fprintf(stderr, "error: no backlight found\n"); return; }
    int cur = get_brightness();
    if (cur < 0) cur = 0;

    int step = max_b / 20;
    if (step < 1) step = 1;
    int target = cur + (delta > 0 ? step : -step);

    if (target < 0) target = 0;
    if (target > max_b) target = max_b;

    animate_to(target, 100);
}

static void inc(void) { adjust(1); }
static void dec(void) { adjust(-1); }

static void show(void) {
    int max_b = get_max_brightness();
    int cur = get_brightness();
    if (max_b <= 0 || cur < 0) {
        fprintf(stderr, "error: no backlight found\n");
        return;
    }
    int pct_val = (cur * 100) / max_b;
    printf("BRIGHTNESS=%d\n", pct_val);
    printf("BRIGHTNESS_RAW=%d\n", cur);
    printf("BRIGHTNESS_MAX=%d\n", max_b);
}

static void monitor(void) {
    int last = -1;
    while (1) {
        int cur = get_brightness();
        if (cur >= 0 && cur != last) {
            int max_b = get_max_brightness();
            int pct_val = max_b > 0 ? (cur * 100) / max_b : 0;
            printf("BRIGHTNESS=%d\n", pct_val);
            fflush(stdout);
            last = cur;
        }
        usleep(500000);
    }
}

static void smooth_up(void) { adjust(1); }
static void smooth_down(void) { adjust(-1); }

static void usage(const char *prog) {
    fprintf(stderr,
        "Usage: %s <command> [args]\n\n"
        "Smooth hardware backlight control with animated transitions.\n\n"
        "Commands:\n"
        "  get              Show current brightness (0-100)\n"
        "  set <0-100>      Set brightness with smooth animation\n"
        "  up               Increase by 5%% (smooth)\n"
        "  down             Decrease by 5%% (smooth)\n"
        "  min              Set to 0%%\n"
        "  max              Set to 100%%\n"
        "  monitor          Stream brightness changes (for sfwbar source)\n"
        "  raw-get          Get raw brightness value\n"
        "  raw-set <val>    Set raw brightness value (no animation)\n"
        "  -h               Show this help\n\n"
        "Examples:\n"
        "  %s set 50        # smooth transition to 50%%\n"
        "  %s up             # increase by 5%%\n"
        "  %s monitor        # stream for sfwbar polling\n",
        prog, prog, prog);
}

int main(int argc, char *argv[]) {
    if (argc < 2) { usage(argv[0]); return 1; }

    const char *cmd = argv[1];

    if (strcmp(cmd, "get") == 0) show();
    else if (strcmp(cmd, "set") == 0 && argc > 2) pct(atoi(argv[2]));
    else if (strcmp(cmd, "up") == 0) inc();
    else if (strcmp(cmd, "down") == 0) dec();
    else if (strcmp(cmd, "min") == 0) pct(0);
    else if (strcmp(cmd, "max") == 0) pct(100);
    else if (strcmp(cmd, "monitor") == 0) monitor();
    else if (strcmp(cmd, "raw-get") == 0) {
        int v = get_brightness();
        if (v >= 0) printf("%d\n", v);
        else { fprintf(stderr, "error: no backlight\n"); return 1; }
    }
    else if (strcmp(cmd, "raw-set") == 0 && argc > 2) {
        if (set_brightness_raw(atoi(argv[2])) != 0) {
            fprintf(stderr, "error: failed to set brightness\n"); return 1;
        }
    }
    else { usage(argv[0]); return 1; }

    return 0;
}
