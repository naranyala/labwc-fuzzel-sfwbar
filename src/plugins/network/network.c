#include "../../libocws/plugin_api.h"
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <time.h>
#include <unistd.h>
#include <sys/types.h>
#include <sys/stat.h>

/* Simple IP parsing for demonstration */
static char g_current_ip[64] = "0.0.0.0";
static char g_interface[32] = "unknown";
static time_t g_last_check = 0;

static void discover_network(void) {
    FILE *fp = fopen("/proc/net/dev", "r");
    if (!fp) return;
    
    char line[256];
    while (fgets(line, sizeof(line), fp)) {
        if (strstr(line, "eth0") || strstr(line, "wlan0") || strstr(line, "enp0s25")) {
            char *iface = strtok(line, "");
            if (iface) {
                strncpy(g_interface, iface + 1, sizeof(g_interface) - 1);
                g_interface[sizeof(g_interface) - 1] = '\0';
                break;
            }
        }
    }
    fclose(fp);

    /* Try to get IP via ip command */
    char cmd[256];
    snprintf(cmd, sizeof(cmd), "ip -4 addr show %s | grep -oP '\\K\d+\.\d+\.\d+\.\d+' | head -1", g_interface);
    FILE *ipfp = popen(cmd, "r");
    if (ipfp) {
        if (fgets(g_current_ip, sizeof(g_current_ip), ipfp)) {
            g_current_ip[strcspn(g_current_ip, "\n")] = '\0';
        }
        pclose(ipfp);
    }
}

static int net_init(void) {
    discover_network();
    return 0;
}

static void on_event(const char *event, const char *payload) {
    if (!event || strcmp(event, "Config.Network") != 0) return;
    if (payload && strstr(payload, "\"reset\"")) {
        /* Reset plugin state */
        discover_network();
        char payload2[256];
        snprintf(payload2, sizeof(payload2), "{\"ip\":\"%s\",\"interface\":\"%s\"}", g_current_ip, g_interface);
        ocws_plugin_emit("Network.State", payload2);
    }
}

static void on_tick(void) {
    time_t now = time(NULL);
    if (now - g_last_check >= 30) {
        char old_ip[64];
        strncpy(old_ip, g_current_ip, sizeof(old_ip));
        
        discover_network();
        
        if (strcmp(old_ip, g_current_ip) != 0) {
            char payload[256];
            snprintf(payload, sizeof(payload), "{\"old_ip\":\"%s\",\"new_ip\":\"%s\",\"interface\":\"%s\"}", old_ip, g_current_ip, g_interface);
            ocws_plugin_emit("Network.IPChanged", payload);
            ocws_plugin_notify("Network", "IP address changed: "g_current_ip, "network-wireless");
        }
        
        g_last_check = now;
    }
}

OcwsPlugin OCWS_PLUGIN_ENTRY = {
    .api_version       = OCWS_PLUGIN_API_VERSION,
    .name              = "Network Monitor",
    .tick_interval_sec = 30,
    .init              = net_init,
    .on_tick           = on_tick,
    .shutdown          = NULL,
    .on_event          = on_event,
};
