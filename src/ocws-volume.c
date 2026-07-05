#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <math.h>

static int run_cmd(const char *cmd) {
    return system(cmd);
}

static int get_volume(void) {
    FILE *f = popen("pactl get-sink-volume @DEFAULT_SINK@ 2>/dev/null | grep -oP '\\d+%' | head -1 | tr -d '%'", "r");
    if (!f) return -1;
    int vol = -1;
    fscanf(f, "%d", &vol);
    pclose(f);
    return vol;
}

static int is_muted(void) {
    FILE *f = popen("pactl get-sink-mute @DEFAULT_SINK@ 2>/dev/null", "r");
    if (!f) return 0;
    char buf[64] = {0};
    fgets(buf, sizeof(buf), f);
    pclose(f);
    return strstr(buf, "yes") != NULL;
}

static double ease_out_cubic(double t) {
    return 1.0 - pow(1.0 - t, 3);
}

static void animate_to(int target, int duration_ms) {
    int cur = get_volume();
    if (cur < 0) cur = target;
    if (cur == target) return;

    if (target < 0) target = 0;
    if (target > 150) target = 150;

    int steps = duration_ms / 10;
    if (steps < 1) steps = 1;

    double start_val = (double)cur;
    double end_val = (double)target;

    for (int i = 1; i <= steps; i++) {
        double t = (double)i / steps;
        double eased = ease_out_cubic(t);
        int val = (int)(start_val + (end_val - start_val) * eased + 0.5);
        if (val < 0) val = 0;
        if (val > 150) val = 150;

        char cmd[256];
        snprintf(cmd, sizeof(cmd), "pactl set-sink-volume @DEFAULT_SINK@ %d%% 2>/dev/null", val);
        run_cmd(cmd);
        usleep(10000);
    }
}

static void pct(int percent) {
    if (percent < 0) percent = 0;
    if (percent > 150) percent = 150;
    animate_to(percent, 200);
}

static void adjust(int delta) {
    int cur = get_volume();
    if (cur < 0) cur = 50;

    int step = 5;
    int target = cur + (delta > 0 ? step : -step);
    if (target < 0) target = 0;
    if (target > 150) target = 150;

    animate_to(target, 100);
}

static void toggle_mute(void) {
    run_cmd("pactl set-sink-mute @DEFAULT_SINK@ toggle 2>/dev/null");
}

static void show(void) {
    int vol = get_volume();
    int muted = is_muted();
    if (vol < 0) vol = 0;

    printf("VOLUME=%d\n", vol);
    printf("VOLUME_MUTED=%s\n", muted ? "true" : "false");

    /* Icon based on level */
    if (muted || vol == 0)
        printf("VOLUME_ICON=audio-volume-muted-symbolic\n");
    else if (vol < 33)
        printf("VOLUME_ICON=audio-volume-low-symbolic\n");
    else if (vol < 66)
        printf("VOLUME_ICON=audio-volume-medium-symbolic\n");
    else
        printf("VOLUME_ICON=audio-volume-high-symbolic\n");
}

static void monitor(void) {
    int last_vol = -1;
    int last_mute = -1;
    while (1) {
        int vol = get_volume();
        int muted = is_muted();
        if (vol >= 0 && (vol != last_vol || muted != last_mute)) {
            printf("VOLUME=%d\n", vol);
            printf("VOLUME_MUTED=%s\n", muted ? "true" : "false");
            fflush(stdout);
            last_vol = vol;
            last_mute = muted;
        }
        usleep(500000);
    }
}

static void set_default_sink(const char *name) {
    char cmd[256];
    snprintf(cmd, sizeof(cmd), "pactl set-default-sink %s 2>/dev/null", name);
    if (run_cmd(cmd) != 0) {
        fprintf(stderr, "error: failed to set default sink: %s\n", name);
    }
}

static void list_sinks(void) {
    run_cmd("pactl list sinks short 2>/dev/null");
}

static void usage(const char *prog) {
    fprintf(stderr,
        "Usage: %s <command> [args]\n\n"
        "Smooth PulseAudio volume control with animated transitions.\n\n"
        "Commands:\n"
        "  get              Show current volume (0-100, muted state, icon)\n"
        "  set <0-150>      Set volume with smooth animation\n"
        "  up               Increase by 5%% (smooth)\n"
        "  down             Decrease by 5%% (smooth)\n"
        "  mute             Toggle mute\n"
        "  min              Set to 0%%\n"
        "  max              Set to 100%%\n"
        "  monitor          Stream volume changes (for sfwbar source)\n"
        "  list             List available sinks\n"
        "  sink <name>      Set default sink\n"
        "  -h               Show this help\n\n"
        "Over-100%% is allowed (PulseAudio amplification).\n\n"
        "Examples:\n"
        "  %s set 50        # smooth transition to 50%%\n"
        "  %s up             # increase by 5%%\n"
        "  %s mute           # toggle mute\n",
        prog, prog, prog);
}

int main(int argc, char *argv[]) {
    if (argc < 2) { usage(argv[0]); return 1; }

    const char *cmd = argv[1];

    if (strcmp(cmd, "get") == 0) show();
    else if (strcmp(cmd, "set") == 0 && argc > 2) pct(atoi(argv[2]));
    else if (strcmp(cmd, "up") == 0) adjust(1);
    else if (strcmp(cmd, "down") == 0) adjust(-1);
    else if (strcmp(cmd, "mute") == 0) toggle_mute();
    else if (strcmp(cmd, "min") == 0) pct(0);
    else if (strcmp(cmd, "max") == 0) pct(100);
    else if (strcmp(cmd, "monitor") == 0) monitor();
    else if (strcmp(cmd, "list") == 0) list_sinks();
    else if (strcmp(cmd, "sink") == 0 && argc > 2) set_default_sink(argv[2]);
    else { usage(argv[0]); return 1; }

    return 0;
}
