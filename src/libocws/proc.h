#ifndef OCWS_PROC_H
#define OCWS_PROC_H

#include <sys/types.h>
#include <unistd.h>
#include <signal.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

/*
 * ocws_proc — minimal background-process manager.
 *
 * Spawns commands via fork()+execl("/bin/sh","-c",...) and detaches them with
 * setsid() so they survive the parent. Tracks the real child PID so callers
 * can query/stop/restart managed processes. State lives in a small registry so
 * a UI (e.g. a tray icon) can enumerate and toggle every process.
 *
 * Header-only, matching the libocws convention (see spawn.h / daemon.h).
 */

#define OCWS_PROC_MAX 64

typedef struct {
    char name[64];
    char cmd[1024];
    pid_t pid;
    int running;
} ocws_proc_t;

static ocws_proc_t ocws_procs[OCWS_PROC_MAX];
static int ocws_procs_count = 0;

static ocws_proc_t *ocws_proc_find(const char *name) {
    for (int i = 0; i < ocws_procs_count; i++)
        if (strcmp(ocws_procs[i].name, name) == 0) return &ocws_procs[i];
    return NULL;
}

/* Register a managed process (idempotent). Returns NULL if registry is full. */
static ocws_proc_t *ocws_proc_add(const char *name, const char *cmd) {
    ocws_proc_t *p = ocws_proc_find(name);
    if (p) { snprintf(p->cmd, sizeof(p->cmd), "%s", cmd); return p; }
    if (ocws_procs_count >= OCWS_PROC_MAX) return NULL;
    p = &ocws_procs[ocws_procs_count++];
    snprintf(p->name, sizeof(p->name), "%s", name);
    snprintf(p->cmd, sizeof(p->cmd), "%s", cmd);
    p->pid = -1;
    p->running = 0;
    return p;
}

/* Re-check liveness via kill(pid, 0). Returns 1 if running. */
static int ocws_proc_refresh(ocws_proc_t *p) {
    if (p->pid > 0) p->running = (kill(p->pid, 0) == 0);
    else p->running = 0;
    return p->running;
}

/* Start if not already running. Returns 0 on success. */
static int ocws_proc_start(ocws_proc_t *p) {
    if (ocws_proc_refresh(p) && p->running) return 0;
    pid_t pid = fork();
    if (pid < 0) return -1;
    if (pid == 0) {
        setsid(); /* detach from controlling terminal / parent group */
        execl("/bin/sh", "sh", "-c", p->cmd, (char *)NULL);
        _exit(127); /* execl failed */
    }
    p->pid = pid;
    p->running = 1;
    return 0;
}

static int ocws_proc_stop(ocws_proc_t *p) {
    if (p->pid > 0) { kill(p->pid, SIGTERM); p->pid = -1; }
    p->running = 0;
    return 0;
}

static int ocws_proc_restart(ocws_proc_t *p) {
    ocws_proc_stop(p);
    return ocws_proc_start(p);
}

#endif /* OCWS_PROC_H */
