#include <stdio.h>
#include "../libocws/plugin_api.h"

static int dummy_init(void) {
    printf("[DummyPlugin] Initializing...\n");
    return 0;
}

static void dummy_tick(void) {
    printf("[DummyPlugin] Tick.\n");
}

static void dummy_shutdown(void) {
    printf("[DummyPlugin] Shutting down.\n");
}

OcwsPlugin OCWS_PLUGIN_ENTRY = {
    .api_version = OCWS_PLUGIN_API_VERSION,
    .name = "Dummy",
    .tick_interval_sec = 5,
    .init = dummy_init,
    .on_tick = dummy_tick,
    .shutdown = dummy_shutdown,
    .on_event = NULL
};
