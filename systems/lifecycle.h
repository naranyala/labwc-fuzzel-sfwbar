#ifndef SYSTEMS_LIFECYCLE_H
#define SYSTEMS_LIFECYCLE_H

#include "widget.h"

typedef enum {
    LIFECYCLE_EVENT_START,
    LIFECYCLE_EVENT_STOP,
    LIFECYCLE_EVENT_UPDATE,
    LIFECYCLE_EVENT_RENDER,
    LIFECYCLE_EVENT_FOCUS,
    LIFECYCLE_EVENT_THEME,
    LIFECYCLE_EVENT_CONFIG,
    LIFECYCLE_EVENT_WINDOW_CREATE,
    LIFECYCLE_EVENT_MAX
} lifecycle_event_t;

typedef void (*lifecycle_callback)(lifecycle_event_t event, const char *data, void *user_data);

void emit_lifecycle_event(lifecycle_event_t event, const char *data);
void emit_lifecycle_event_with_data(lifecycle_event_t event, const char *data, void *user_data);
int register_lifecycle_callback(lifecycle_event_t event, lifecycle_callback callback, void *user_data);
void setup_window_creation_callback(void (*callback)(const char *title, const char *app_id, void *user_data), void *user_data);
void setup_widget_focus_callback(void (*callback)(const char *component_name, bool focused, void *user_data), void *user_data);
void setup_theme_change_callback(void (*callback)(const char *theme_name, void *user_data), void *user_data);
void setup_config_change_callback(void (*callback)(const char *config_name, void *user_data), void *user_data);
void cleanup_lifecycle_system();
void init_default_lifecycle_handlers();

/* Specialized window creation */
typedef void (*window_creation_cb)(const char *title, const char *app_id, void *user_data);
void register_window_creation_callback(window_creation_cb cb, void *user_data);
void trigger_window_creation(const char *title, const char *app_id);

#endif // SYSTEMS_LIFECYCLE_H
