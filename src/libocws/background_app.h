#ifndef OCWS_BACKGROUND_APP_H
#define OCWS_BACKGROUND_APP_H

#include <gtk/gtk.h>
#include <unistd.h>
#include <fcntl.h>
#include <sys/stat.h>

#define TRAY_APPINDICATOR 1
#include "../../libs/tray/tray.h"

//
// This abstraction allows turning any GTK OCWS application into a background
// tray application with minimal boilerplate.
//

static GtkWidget *_ocws_bg_main_window = NULL;

static void _ocws_bg_toggle_cb(struct tray_menu *item) {
    (void)item;
    if (_ocws_bg_main_window && gtk_widget_get_visible(_ocws_bg_main_window)) {
        gtk_widget_hide(_ocws_bg_main_window);
    } else if (_ocws_bg_main_window) {
        gtk_widget_show_all(_ocws_bg_main_window);
        gtk_window_present(GTK_WINDOW(_ocws_bg_main_window));
    }
}

static void _ocws_bg_quit_cb(struct tray_menu *item) {
    (void)item;
    exit(0);
}

static struct tray _ocws_bg_tray = {
    .icon = "application-default-icon", 
    .menu = (struct tray_menu[]) {
        {"Show/Hide", 0, 0, _ocws_bg_toggle_cb, NULL, NULL},
        {"-", 0, 0, NULL, NULL, NULL},
        {"Quit", 0, 0, _ocws_bg_quit_cb, NULL, NULL},
        {NULL, 0, 0, NULL, NULL, NULL}
    },
};

// Must be called early in main() before GTK initializes, if you want a true daemon
static inline int ocws_daemonize(void) {
    pid_t pid = fork();
    if (pid < 0) return -1;
    if (pid > 0) exit(0); // Parent exits

    if (setsid() < 0) return -1; // New session

    pid = fork();
    if (pid < 0) return -1;
    if (pid > 0) exit(0); // First child exits

    umask(0);
    
    // Redirect stdio
    int fd = open("/dev/null", O_RDWR);
    if (fd != -1) {
        dup2(fd, STDIN_FILENO);
        dup2(fd, STDOUT_FILENO);
        dup2(fd, STDERR_FILENO);
        if (fd > 2) close(fd);
    }
    return 0;
}

// Call inside your GtkApplication's "activate" signal
static inline void ocws_background_app_init(GtkApplication *app, GtkWidget *main_window, const char *tray_icon) {
    _ocws_bg_main_window = main_window;
    if (tray_icon) {
        _ocws_bg_tray.icon = (char*)tray_icon;
    }
    
    // Hold application so it doesn't exit when window is hidden
    g_application_hold(G_APPLICATION(app));

    // Hide instead of destroy on close
    g_signal_connect(main_window, "delete-event", G_CALLBACK(gtk_widget_hide_on_delete), NULL);

    if (tray_init(&_ocws_bg_tray) < 0) {
        g_printerr("Failed to initialize system tray\n");
    }
}

#endif
