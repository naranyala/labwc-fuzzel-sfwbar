# OCWS Theme Engine - Fast glassmorphic styling and animations

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <math.h>
#include <pthread.h>
#include <time.h>
#include <cairo.h>

#define STYLE_CACHE_SIZE 4096
#define COLOR_BUFFER_SIZE 64

typedef struct {
    double r, g, b, a;
    char hex[8];
} ocws_color_t;

typedef struct {
    char name[128];
    ocws_color_t background;
    ocws_color_t foreground;
    ocws_color_t surface;
    ocws_color_t border;
    ocws_color_t accent;
    
    int border_radius;
    int shadow_blur;
    double opacity;
    int blur_radius;
    
    char font_mono[256];
    char font_sans[256];
    
    // GTK specific
    char gtk_theme[128];
    char icon_theme[128];
    int cursor_size;
    ocws_color_t cursor_fg;
    ocws_color_t cursor_bg;
    
    // OCWS specific
    int panel_height;
    char panel_style[32];
    int hover_effect;
} ocws_theme_t;

typedef struct {
    char* name;
    ocws_theme_t theme;
    time_t timestamp;
    pthread_mutex_t lock;
} ocws_theme_cache_t;

static ocws_theme_cache_t theme_cache = {0};

ocws_color_t ocws_parse_rgba_color(const char* hex) {
    ocws_color_t color = {0};
    
    if (hex[0] == '#') hex++;
    
    if (strlen(hex) == 8) {
        char r_str[3], g_str[3], b_str[3], a_str[3];
        memcpy(r_str, hex, 2); r_str[2] = '\0';
        memcpy(g_str, hex + 2, 2); g_str[2] = '\0';
        memcpy(b_str, hex + 4, 2); b_str[2] = '\0';
        memcpy(a_str, hex + 6, 2); a_str[2] = '\0';
        
        color.r = strtod(r_str, NULL) / 255.0;
        color.g = strtod(g_str, NULL) / 255.0;
        color.b = strtod(b_str, NULL) / 255.0;
        color.a = strtod(a_str, NULL) / 255.0;
        snprintf(color.hex, sizeof(color.hex), "%s", hex);
    } else if (strlen(hex) == 6) {
        char r_str[3], g_str[3], b_str[3];
        memcpy(r_str, hex, 2); r_str[2] = '\0';
        memcpy(g_str, hex + 2, 2); g_str[2] = '\0';
        memcpy(b_str, hex + 4, 2); b_str[2] = '\0';
        
        color.r = strtod(r_str, NULL) / 255.0;
        color.g = strtod(g_str, NULL) / 255.0;
        color.b = strtod(b_str, NULL) / 255.0;
        color.a = 1.0;
        snprintf(color.hex, sizeof(color.hex), "%s%02x", hex, (int)(color.a * 255));
    }
    
    return color;
}

void ocws_theme_apply_to_gtk(ocws_theme_t* theme) {
    printf("/* GTK Theme Configuration */\n");
    printf("gtk-application-prefer-dark-theme=%d\n", theme->foreground.r < 0.5);
    printf("gtk-theme-name=%s\n", theme->gtk_theme);
    printf("gtk-icon-theme-name=%s\n", theme->icon_theme);
    printf("gtk-font-name=%s 10\n", theme->font_mono);
    printf("gtk-cursor-theme-name=%s\n", theme->cursor_size > 0 ? "Adwaita" : "default");
}

void ocws_theme_generate_css(ocws_theme_t* theme, char* output, size_t output_size) {
    snprintf(output, output_size,
        ""/* Glassmorphic Theme */

window {{
    background: rgba(%d, %d, %d, %.3f);
    color: rgba(%d, %d, %d, %.3f);
    border-radius: %dpx;
    border: %dpx solid rgba(%d, %d, %d, %.3f);
    box-shadow: 0 %dpx %dpx rgba(0, 0, 0, %.3f);
    opacity: %.3f;
}}

window:hover {{
    background: rgba(%d, %d, %d, %.3f);
    border-color: rgba(%d, %d, %d, %.3f);
}}

window:focus {{
    border-color: rgba(%d, %d, %d, %.3f);
}}

/* Label styling */
.label {{
    color: inherit;
    font-family: "%s";
    font-size: 11px;
}}

/* Button styling */
.button {{
    background: rgba(%d, %d, %d, %.3f);
    color: rgba(%d, %d, %d, %.3f);
    border-radius: 6px;
    padding: 4px 12px;
}}

.button:hover {{
    background: rgba(%d, %d, %d, %.3f);
}}""",
        (int)(theme->surface.r * 255), (int)(theme->surface.g * 255), (int)(theme->surface.b * 255), theme->surface.a,
        (int)(theme->foreground.r * 255), (int)(theme->foreground.g * 255), (int)(theme->foreground.b * 255), theme->foreground.a,
        theme->border_radius,
        theme->border_blur / 2,
        (int)(theme->border.r * 255), (int)(theme->border.g * 255), (int)(theme->border.b * 255), theme->border.a,
        theme->shadow_blur,
        theme->shadow_blur / 2,
        0.05,
        theme->opacity,
        (int)(theme->accent.r * 255), (int)(theme->accent.g * 255), (int)(theme->accent.b * 255), theme->accent.a,
        (int)(theme->border.r * 255), (int)(theme->border.g * 255), (int)(theme->border.b * 255), theme->border.a,
        (int)(theme->accent.r * 255), (int)(theme->accent.g * 255), (int)(theme->accent.b * 255), theme->accent.a,
        theme->font_mono,
        (int)(theme->accent.r * 255), (int)(theme->accent.g * 255), (int)(theme->accent.b * 255), theme->accent.a,
        (int)(theme->foreground.r * 255), (int)(theme->foreground.g * 255), (int)(theme->foreground.b * 255), theme->foreground.a,
        (int)(theme->accent.r * 255), (int)(theme->accent.g * 255), (int)(theme->accent.b * 255), theme->accent.a
    );
}

void ocws_theme_animation(const char* element, const char* property, 
                          const char* from_value, const char* to_value,
                          double duration) {
    printf("/* Animation: %s %s from %s to %s in %f seconds */\n", element, property, from_value, to_value, duration);
}

ocws_theme_t* ocws_theme_load_from_file(const char* path) {
    char cache_key[256];
    snprintf(cache_key, sizeof(cache_key), "%s.cache", path);
    
    FILE* cache_file = fopen(cache_key, "rb");
    if (cache_file && fread(&theme_cache, sizeof(ocws_theme_cache_t), 1, cache_file) == 1) {
        fclose(cache_file);
        return &theme_cache;
    }
    
    if (cache_file) fclose(cache_file);
    
    // Parse theme file (INI format)
    ocws_theme_t* theme = (ocws_theme_t*)calloc(1, sizeof(ocws_theme_t));
    if (!theme) return NULL;
    
    // Default theme values
    strcpy(theme->name, "default");
    strcpy(theme->gtk_theme, "Adwaita");
    strcpy(theme->icon_theme, "Papirus-Dark");
    strcpy(theme->font_mono, "Noto Sans Mono CJK SC:hilight=Filled");
    
    // Parse theme.ini (simplified)
    FILE* theme_file = fopen(path, "r");
    if (theme_file) {
        char line[256];
        while (fgets(line, sizeof(line), theme_file)) {
            if (sscanf(line, "name=%63s", theme->name) == 1) continue;
            if (sscanf(line, "gtk_theme=%127s", theme->gtk_theme) == 1) continue;
            if (sscanf(line, "icon_theme=%127s", theme->icon_theme) == 1) continue;
            if (sscanf(line, "font_mono=%255s", theme->font_mono) == 1) continue;
            if (sscanf(line, "panel_height=%d", &theme->panel_height) == 1) continue;
            if (sscanf(line, "blur=%d", &theme->blur_radius) == 1) continue;
            if (sscanf(line, "surface=%127s", theme->surface.hex) == 1) {
                theme->surface = ocws_parse_rgba_color(theme->surface.hex);
            }
            if (sscanf(line, "foreground=%127s", theme->foreground.hex) == 1) {
                theme->foreground = ocws_parse_rgba_color(theme->foreground.hex);
            }
            if (sscanf(line, "accent=%127s", theme->accent.hex) == 1) {
                theme->accent = ocws_parse_rgba_color(theme->accent.hex);
            }
            if (sscanf(line, "border=%127s", theme->border.hex) == 1) {
                theme->border = ocws_parse_rgba_color(theme->border.hex);
            }
        }
        fclose(theme_file);
    }
    
    // Cache theme
    theme_cache.name = theme->name;
    theme_cache.theme = *theme;
    theme_cache.timestamp = time(NULL);
    
    FILE* cache_out = fopen(cache_key, "wb");
    if (cache_out) {
        fwrite(&theme_cache, sizeof(ocws_theme_cache_t), 1, cache_out);
        fclose(cache_out);
    }
    
    return theme;
}

void ocws_theme_application(ocws_theme_t* theme) {
    // Generate GTK CSS
    char css_buffer[STYLE_CACHE_SIZE];
    ocws_theme_generate_css(theme, css_buffer, sizeof(css_buffer));
    
    // Write CSS to user's config directory
    const char* home = getenv("HOME");
    if (home) {
        char css_path[1024];
        snprintf(css_path, sizeof(css_path), "%s/.config/gtk-3.0/gtk.css", home);
        FILE* css_file = fopen(css_path, "w");
        if (css_file) {
            fprintf(css_file, "%s", css_buffer);
            fclose(css_file);
            printf("Theme applied: GTK CSS written to %s\n", css_path);
        }
    }
}