#include "bus.h"
#include "plugin_api.h"
#include <stdlib.h>
#include <string.h>

/* Single shared instance of the host services + event bus, linked by both
 * the host (ocws-brokerd / ocws-appletd) and every plugin .so, so there is
 * exactly one bus in the process. */

static ocws_plugin_emit_fn   g_emit   = NULL;
static ocws_plugin_notify_fn g_notify = NULL;
static ocws_plugin_config_fn g_config = NULL;

void ocws_plugin_set_host(ocws_plugin_emit_fn emit,
                          ocws_plugin_notify_fn notify,
                          ocws_plugin_config_fn config) {
    g_emit   = emit;
    g_notify = notify;
    g_config = config;
}

void ocws_plugin_emit(const char *event, const char *payload) {
    if (g_emit) g_emit(event, payload);
    else ocws_bus_emit(event, payload);
}

void ocws_plugin_notify(const char *title, const char *body, const char *icon) {
    if (g_notify) g_notify(title, body, icon);
}

const char *ocws_plugin_config(const char *key, const char *def) {
    if (g_config) return g_config(key, def);
    return def;
}
