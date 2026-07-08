#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "../libocws/plugin_api.h"

/* Previous CPU state for calculating usage */
static unsigned long long prev_user = 0, prev_nice = 0, prev_system = 0, prev_idle = 0, prev_iowait = 0, prev_irq = 0, prev_softirq = 0, prev_steal = 0;

static int sysmon_init(void) {
    printf("[SysmonPlugin] High-performance native system monitor initialized.\n");
    return 0;
}

static void sysmon_tick(void) {
    /* 1. Calculate CPU Usage */
    FILE *fp = fopen("/proc/stat", "r");
    if (fp) {
        char buffer[256];
        if (fgets(buffer, sizeof(buffer), fp)) {
            unsigned long long user, nice, system, idle, iowait, irq, softirq, steal;
            if (sscanf(buffer, "cpu %llu %llu %llu %llu %llu %llu %llu %llu",
                       &user, &nice, &system, &idle, &iowait, &irq, &softirq, &steal) == 8) {
                
                unsigned long long prev_idle_total = prev_idle + prev_iowait;
                unsigned long long idle_total = idle + iowait;

                unsigned long long prev_non_idle = prev_user + prev_nice + prev_system + prev_irq + prev_softirq + prev_steal;
                unsigned long long non_idle = user + nice + system + irq + softirq + steal;

                unsigned long long prev_total = prev_idle_total + prev_non_idle;
                unsigned long long total = idle_total + non_idle;

                unsigned long long totald = total - prev_total;
                unsigned long long idled = idle_total - prev_idle_total;

                if (totald > 0) {
                    double cpu_percentage = (double)(totald - idled) / totald * 100.0;
                    printf("[SysmonPlugin] CPU Usage: %.1f%%\n", cpu_percentage);
                }

                prev_user = user; prev_nice = nice; prev_system = system;
                prev_idle = idle; prev_iowait = iowait; prev_irq = irq;
                prev_softirq = softirq; prev_steal = steal;
            }
        }
        fclose(fp);
    }

    /* 2. Calculate Memory Usage */
    fp = fopen("/proc/meminfo", "r");
    if (fp) {
        char line[256];
        unsigned long mem_total = 0, mem_free = 0, buffers = 0, cached = 0;
        while (fgets(line, sizeof(line), fp)) {
            if (strncmp(line, "MemTotal:", 9) == 0) sscanf(line, "MemTotal: %lu kB", &mem_total);
            else if (strncmp(line, "MemFree:", 8) == 0) sscanf(line, "MemFree: %lu kB", &mem_free);
            else if (strncmp(line, "Buffers:", 8) == 0) sscanf(line, "Buffers: %lu kB", &buffers);
            else if (strncmp(line, "Cached:", 7) == 0) sscanf(line, "Cached: %lu kB", &cached);
        }
        fclose(fp);
        
        if (mem_total > 0) {
            unsigned long mem_used = mem_total - mem_free - buffers - cached;
            double mem_percentage = (double)mem_used / mem_total * 100.0;
            printf("[SysmonPlugin] RAM Usage: %.1f%%\n", mem_percentage);
        }
    }
}

static void sysmon_shutdown(void) {
    printf("[SysmonPlugin] Shutting down.\n");
}

OcwsPlugin OCWS_PLUGIN_ENTRY = {
    .api_version = OCWS_PLUGIN_API_VERSION,
    .name = "Sysmon",
    .tick_interval_sec = 2, /* Update every 2 seconds */
    .init = sysmon_init,
    .on_tick = sysmon_tick,
    .shutdown = sysmon_shutdown,
    .on_event = NULL
};
