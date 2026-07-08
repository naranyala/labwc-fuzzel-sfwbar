#ifndef OCWS_NOTIFY_H
#define OCWS_NOTIFY_H

#include <stdio.h>
#include <string.h>
#include <stdlib.h>

/* Send a desktop notification through notify-send, which routes to the
 * active notification daemon (ocws-notify / mako / dunst) over D-Bus.
 * Falls back to the system logger when no client is available so errors
 * are never silently dropped.
 *
 * title/body are required; icon may be NULL. Single quotes inside title
 * or body are stripped to avoid breaking the shell invocation.
 *
 * Returns 0 on success, non-zero if the notification could not be sent. */
static inline int ocws_notify(const char *title, const char *body, const char *icon) {
    char safe_title[512];
    char safe_body[1024];
    const char *t = title ? title : "OCWS";
    const char *b = body ? body : "";

    /* Strip single quotes that would break the shell command. */
    size_t j = 0;
    for (size_t i = 0; t[i] && j < sizeof(safe_title) - 1; i++)
        if (t[i] != '\'') safe_title[j++] = t[i];
    safe_title[j] = '\0';

    j = 0;
    for (size_t i = 0; b[i] && j < sizeof(safe_body) - 1; i++)
        if (b[i] != '\'') safe_body[j++] = b[i];
    safe_body[j] = '\0';

    char cmd[1600];
    if (icon && icon[0]) {
        snprintf(cmd, sizeof(cmd),
                 "notify-send -a '%s' -t 3000 -i '%s' '%s' 2>/dev/null",
                 safe_title, icon, safe_body);
    } else {
        snprintf(cmd, sizeof(cmd),
                 "notify-send -a '%s' -t 3000 '%s' 2>/dev/null",
                 safe_title, safe_body);
    }

    int rc = system(cmd);
    if (rc != 0) {
        /* Client missing or call failed — keep the message visible. */
        if (system("command -v logger >/dev/null 2>&1") == 0)
            fprintf(stderr, "[%s] %s\n", safe_title, safe_body);
    }
    return rc;
}

/* Critical/error notification (routes with high urgency). */
static inline int ocws_notify_urgent(const char *title, const char *body) {
    char cmd[1600];
    const char *t = title ? title : "OCWS";
    const char *b = body ? body : "";
    char safe_title[512];
    char safe_body[1024];
    size_t j = 0;
    for (size_t i = 0; t[i] && j < sizeof(safe_title) - 1; i++)
        if (t[i] != '\'') safe_title[j++] = t[i];
    safe_title[j] = '\0';
    j = 0;
    for (size_t i = 0; b[i] && j < sizeof(safe_body) - 1; i++)
        if (b[i] != '\'') safe_body[j++] = b[i];
    safe_body[j] = '\0';
    snprintf(cmd, sizeof(cmd),
             "notify-send -u critical -a '%s' -t 5000 '%s' 2>/dev/null",
             safe_title, safe_body);
    return system(cmd);
}

/* Convenience wrappers with consistent naming for error handling. */
static inline int ocws_notify_error(const char *title, const char *body) {
    return ocws_notify_urgent(title ? title : "OCWS Error", body);
}

static inline int ocws_notify_warn(const char *title, const char *body) {
    return ocws_notify(title ? title : "OCWS Warning", body, NULL);
}

#endif
