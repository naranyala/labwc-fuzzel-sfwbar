#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <signal.h>
#include <sys/stat.h>
#include <sys/wait.h>
#include <time.h>
#include <dirent.h>

#define PID_FILE "/tmp/ocws-recorder.pid"
#define RECORD_DIR_DEFAULT "$HOME/Videos/recordings"
#define CODEC_DEFAULT "libx264"
#define CRF_DEFAULT "23"
#define AUDIO_DEFAULT "auto"

static volatile int running = 1;

static void on_signal(int sig) {
    (void)sig;
    running = 0;
}

static int check_cmd(const char *cmd) {
    char buf[256];
    snprintf(buf, sizeof(buf), "command -v %s >/dev/null 2>&1", cmd);
    return system(buf) == 0;
}

static pid_t read_pid(void) {
    FILE *f = fopen(PID_FILE, "r");
    if (!f) return -1;
    pid_t pid = -1;
    fscanf(f, "%d", &pid);
    fclose(f);
    return pid;
}

static void write_pid(pid_t pid) {
    FILE *f = fopen(PID_FILE, "w");
    if (f) { fprintf(f, "%d\n", pid); fclose(f); }
}

static void remove_pid(void) {
    remove(PID_FILE);
}

static int is_recording(void) {
    pid_t pid = read_pid();
    if (pid <= 0) return 0;
    return kill(pid, 0) == 0;
}

static void notify(const char *title, const char *body) {
    char cmd[1024];
    snprintf(cmd, sizeof(cmd),
        "notify-send -a ocws-recorder '%s' '%s' 2>/dev/null", title, body);
    system(cmd);
}

static const char *get_record_dir(void) {
    const char *dir = getenv("OCWS_RECORD_DIR");
    if (dir && *dir) return dir;
    return RECORD_DIR_DEFAULT;
}

static void start_recording(const char *audio, const char *codec, const char *crf, int fullscreen) {
    if (is_recording()) {
        fprintf(stderr, "Already recording (PID %d)\n", read_pid());
        return;
    }

    if (!check_cmd("wf-recorder")) {
        fprintf(stderr, "error: wf-recorder not found\n");
        fprintf(stderr, "install: sudo apt install wf-recorder\n");
        return;
    }

    /* Create output directory */
    char dir_expanded[512];
    snprintf(dir_expanded, sizeof(dir_expanded), "mkdir -p %s 2>/dev/null", get_record_dir());
    system(dir_expanded);

    /* Generate filename with timestamp */
    time_t now = time(NULL);
    struct tm *tm = localtime(&now);
    char filename[256];
    snprintf(filename, sizeof(filename), "%s/recording-%04d%02d%02d-%02d%02d%02d.mp4",
        get_record_dir(),
        tm->tm_year + 1900, tm->tm_mon + 1, tm->tm_mday,
        tm->tm_hour, tm->tm_min, tm->tm_sec);

    char cmd[2048];
    snprintf(cmd, sizeof(cmd), "wf-recorder -f '%s' -c %s --crf %s",
        filename, codec, crf);

    if (strcmp(audio, "none") != 0) {
        if (strcmp(audio, "auto") == 0) {
            strcat(cmd, " --audio");
        } else {
            char audio_opt[256];
            snprintf(audio_opt, sizeof(audio_opt), " --audio -A '%s'", audio);
            strcat(cmd, audio_opt);
        }
    }

    if (fullscreen) {
        /* Record full screen — no geometry flag needed */
    } else {
        /* Region selection */
        if (check_cmd("slurp")) {
            strcat(cmd, " -g \"$(slurp)\"");
        }
    }

    fprintf(stderr, "ocws-recorder: starting recording...\n");
    fprintf(stderr, "  file: %s\n", filename);

    pid_t pid = fork();
    if (pid == 0) {
        /* Child: run wf-recorder */
        execl("/bin/sh", "sh", "-c", cmd, (char *)NULL);
        exit(1);
    } else if (pid > 0) {
        write_pid(pid);
        notify("Recording Started", filename);
        fprintf(stderr, "  PID: %d\n", pid);
    } else {
        perror("fork");
    }
}

static void stop_recording(void) {
    pid_t pid = read_pid();
    if (pid <= 0 || !is_recording()) {
        fprintf(stderr, "No active recording\n");
        return;
    }

    kill(pid, SIGINT);
    fprintf(stderr, "ocws-recorder: stopping recording (PID %d)...\n", pid);

    int status;
    waitpid(pid, &status, 0);
    remove_pid();

    int success = WIFEXITED(status) && WEXITSTATUS(status) == 0;
    if (success) {
        notify("Recording Saved", "Recording completed successfully");
        fprintf(stderr, "Recording saved\n");
    } else {
        notify("Recording Failed", "Recording stopped with error");
        fprintf(stderr, "Recording failed\n");
    }
}

static void pause_recording(void) {
    pid_t pid = read_pid();
    if (pid <= 0 || !is_recording()) {
        fprintf(stderr, "No active recording\n");
        return;
    }

    kill(pid, SIGSTOP);
    fprintf(stderr, "ocws-recorder: paused\n");
    notify("Recording Paused", "Recording is paused");
}

static void resume_recording(void) {
    pid_t pid = read_pid();
    if (pid <= 0) {
        fprintf(stderr, "No paused recording\n");
        return;
    }

    kill(pid, SIGCONT);
    fprintf(stderr, "ocws-recorder: resumed\n");
    notify("Recording Resumed", "Recording is active again");
}

static void show_status(void) {
    if (is_recording()) {
        pid_t pid = read_pid();
        printf("RECORDING=true\n");
        printf("RECORDING_PID=%d\n", pid);

        /* Try to get file size */
        char proc_path[64];
        snprintf(proc_path, sizeof(proc_path), "/proc/%d/fd/1", pid);
        char link[512] = {0};
        ssize_t len = readlink(proc_path, link, sizeof(link) - 1);
        if (len > 0) {
            link[len] = '\0';
            struct stat st;
            if (stat(link, &st) == 0)
                printf("RECORDING_SIZE=%ld\n", (long)st.st_size);
            printf("RECORDING_FILE=%s\n", link);
        }
    } else {
        printf("RECORDING=false\n");
    }
}

static void list_recordings(void) {
    const char *dir = get_record_dir();
    char cmd[512];
    snprintf(cmd, sizeof(cmd), "ls -lt %s/*.mp4 2>/dev/null | head -20", dir);
    system(cmd);
}

static void usage(const char *prog) {
    fprintf(stderr,
        "Usage: %s <command> [args]\n\n"
        "Screen recording tool for OCWS desktop shell.\n\n"
        "Commands:\n"
        "  start [OPTIONS]   Start recording\n"
        "  stop              Stop current recording\n"
        "  pause             Pause recording\n"
        "  resume            Resume paused recording\n"
        "  toggle            Start/stop toggle\n"
        "  status            Show recording status\n"
        "  list              List recent recordings\n"
        "  -h                Show this help\n\n"
        "Start Options:\n"
        "  -r                Full screen (default: region select)\n"
        "  -a AUDIO          Audio: auto (default), none, or device name\n"
        "  -c CODEC          Video codec (default: libx264)\n"
        "  --crf N           Quality 0-51 (default: 23, lower=better)\n\n"
        "Environment:\n"
        "  OCWS_RECORD_DIR   Output directory (default: ~/Videos/recordings)\n\n"
        "Examples:\n"
        "  %s start              # select region, record with audio\n"
        "  %s start -r           # full screen recording\n"
        "  %s start -a none      # no audio\n"
        "  %s toggle             # toggle recording on/off\n",
        prog, prog, prog, prog);
}

int main(int argc, char *argv[]) {
    signal(SIGINT, on_signal);
    signal(SIGTERM, on_signal);

    if (argc < 2) { usage(argv[0]); return 1; }

    const char *cmd = argv[1];

    if (strcmp(cmd, "start") == 0) {
        const char *audio = AUDIO_DEFAULT;
        const char *codec = CODEC_DEFAULT;
        const char *crf = CRF_DEFAULT;
        int fullscreen = 0;

        for (int i = 2; i < argc; i++) {
            if (strcmp(argv[i], "-r") == 0) fullscreen = 1;
            else if (strcmp(argv[i], "-a") == 0 && i + 1 < argc) audio = argv[++i];
            else if (strcmp(argv[i], "-c") == 0 && i + 1 < argc) codec = argv[++i];
            else if (strcmp(argv[i], "--crf") == 0 && i + 1 < argc) crf = argv[++i];
        }

        start_recording(audio, codec, crf, fullscreen);
    } else if (strcmp(cmd, "stop") == 0) {
        stop_recording();
    } else if (strcmp(cmd, "pause") == 0) {
        pause_recording();
    } else if (strcmp(cmd, "resume") == 0) {
        resume_recording();
    } else if (strcmp(cmd, "toggle") == 0) {
        if (is_recording()) stop_recording();
        else start_recording(AUDIO_DEFAULT, CODEC_DEFAULT, CRF_DEFAULT, 0);
    } else if (strcmp(cmd, "status") == 0) {
        show_status();
    } else if (strcmp(cmd, "list") == 0) {
        list_recordings();
    } else if (strcmp(cmd, "-h") == 0 || strcmp(cmd, "--help") == 0) {
        usage(argv[0]);
    } else {
        fprintf(stderr, "unknown command: %s\n", cmd);
        usage(argv[0]);
        return 1;
    }

    return 0;
}
