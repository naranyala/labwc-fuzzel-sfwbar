#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include "../libocws/plugin_api.h"

static int battery_init(void) {
    if (access("/sys/class/power_supply/BAT0/capacity", R_OK) != 0) {
        printf("[BatteryPlugin] No BAT0 found, disabling battery plugin.\n");
        return -1; /* Fail to load if no battery */
    }
    printf("[BatteryPlugin] Native battery monitor initialized.\n");
    return 0;
}

static void battery_tick(void) {
    FILE *fp = fopen("/sys/class/power_supply/BAT0/capacity", "r");
    if (fp) {
        int capacity = 0;
        if (fscanf(fp, "%d", &capacity) == 1) {
            printf("[BatteryPlugin] BAT0 Capacity: %d%%\n", capacity);
        }
        fclose(fp);
    }
    
    fp = fopen("/sys/class/power_supply/BAT0/status", "r");
    if (fp) {
        char status[32] = {0};
        if (fscanf(fp, "%31s", status) == 1) {
            printf("[BatteryPlugin] BAT0 Status: %s\n", status);
        }
        fclose(fp);
    }
}

static void battery_shutdown(void) {
    printf("[BatteryPlugin] Shutting down.\n");
}

OcwsPlugin OCWS_PLUGIN_ENTRY = {
    .api_version = OCWS_PLUGIN_API_VERSION,
    .name = "Battery",
    .tick_interval_sec = 10, /* Update every 10 seconds */
    .init = battery_init,
    .on_tick = battery_tick,
    .shutdown = battery_shutdown,
    .on_event = NULL
};
