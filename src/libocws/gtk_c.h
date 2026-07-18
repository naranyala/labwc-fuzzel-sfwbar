// gtk_c.h — Thin C wrapper for GTK3 functions used by gtk_shell.zig
// Provides C-compatible declarations that Zig can @cImport cleanly.
#pragma once

#include <stdint.h>
#include <stdbool.h>

// Forward-declare opaque GTK types
typedef struct _GtkWidget GtkWidget;
typedef struct _GtkWindow GtkWindow;
typedef struct _GtkApplication GtkApplication;
typedef struct _GtkBox GtkBox;
typedef struct _GtkButton GtkButton;
typedef struct _GtkLabel GtkLabel;
typedef struct _GtkEntry GtkEntry;
typedef struct _GtkSearchEntry GtkSearchEntry;
typedef struct _GtkFlowBox GtkFlowBox;
typedef struct _GtkScrolledWindow GtkScrolledWindow;
typedef struct _GtkContainer GtkContainer;
typedef struct _GtkStyleContext GtkStyleContext;
typedef struct _GtkCssProvider GtkCssProvider;
typedef struct _GdkPixbuf GdkPixbuf;
typedef struct _GdkScreen GdkScreen;
typedef struct _GdkTexture GdkTexture;
typedef struct _GtkIconTheme GtkIconTheme;
typedef struct _GObject GObject;
typedef struct _GList GList;
typedef struct _GtkIconPaintable GtkIconPaintable;
typedef struct _GtkMenu GtkMenu;
typedef struct _GtkMenuItem GtkMenuItem;
typedef struct _GtkMenuShell GtkMenuShell;

// Wayland forward declaration
struct wl_display;

typedef int gboolean;
typedef int gint;
typedef unsigned int guint;
typedef void* gpointer;
typedef char gchar;

#define GTK_ORIENTATION_HORIZONTAL 0
#define GTK_ORIENTATION_VERTICAL 1
#define GTK_ALIGN_START 0
#define GTK_ALIGN_FILL 1
#define GTK_ALIGN_END 2
#define GTK_ALIGN_CENTER 3
#define GTK_SHADOW_NONE 0
#define GTK_POLICY_NEVER 1
#define GTK_POLICY_AUTOMATIC 0
#define GTK_WIN_POS_CENTER 1
#define GTK_WINDOW_TOPLEVEL 0
#define GTK_ICON_LOOKUP_FORCE_SIZE 1
#define G_APPLICATION_DEFAULT_FLAGS 0
#define G_CONNECT_AFTER 1
#define PANGO_ELLIPSIZE_END 3
#define WL_KEYBOARD_KEY_STATE_PRESSED 1

// GTK widget functions
GtkWidget* gtk_box_new(int orientation, int spacing);
GtkWidget* gtk_button_new(void);
GtkWidget* gtk_label_new(const char* text);
GtkWidget* gtk_entry_new(void);
GtkWidget* gtk_search_entry_new(void);
GtkWidget* gtk_flow_box_new(void);
GtkWidget* gtk_scrolled_window_new(void* hadjustment, void* vadjustment);
GtkWidget* gtk_window_new(int type);
void gtk_widget_set_name(GtkWidget* widget, const char* name);
void gtk_widget_set_halign(GtkWidget* widget, int align);
void gtk_widget_set_valign(GtkWidget* widget, int align);
void gtk_widget_set_margin_start(GtkWidget* widget, int margin);
void gtk_widget_set_margin_end(GtkWidget* widget, int margin);
void gtk_widget_set_margin_top(GtkWidget* widget, int margin);
void gtk_widget_set_margin_bottom(GtkWidget* widget, int margin);
void gtk_widget_set_size_request(GtkWidget* widget, int width, int height);
void gtk_widget_show_all(GtkWidget* widget);
void gtk_widget_show(GtkWidget* widget);
void gtk_widget_hide(GtkWidget* widget);
void gtk_widget_destroy(GtkWidget* widget);
void gtk_widget_grab_focus(GtkWidget* widget);
int gtk_widget_get_visible(GtkWidget* widget);
GtkStyleContext* gtk_widget_get_style_context(GtkWidget* widget);
void gtk_style_context_add_class(GtkStyleContext* context, const char* class_name);
void gtk_container_add(GtkContainer* container, GtkWidget* child);
void gtk_container_foreach(GtkContainer* container, void (*callback)(GtkWidget*, gpointer), gpointer data);
GList* gtk_container_get_children(GtkContainer* container);
void gtk_box_pack_start(GtkBox* box, GtkWidget* child, int expand, int fill, int padding);
void gtk_box_pack_end(GtkBox* box, GtkWidget* child, int expand, int fill, int padding);
void gtk_box_pack_start(GtkBox* box, GtkWidget* child, int expand, int fill, int padding);

// Window functions
void gtk_window_set_title(GtkWindow* window, const char* title);
void gtk_window_set_default_size(GtkWindow* window, int width, int height);
void gtk_window_set_position(GtkWindow* window, int position);
void gtk_window_set_decorated(GtkWindow* window, int setting);
void gtk_window_set_keep_above(GtkWindow* window, int setting);

// Menu functions
GtkWidget* gtk_menu_new(void);
GtkWidget* gtk_menu_item_new_with_label(const char* label);
void gtk_menu_shell_append(GtkMenuShell* shell, GtkWidget* child);
void gtk_menu_popup_at_pointer(GtkMenu* menu, void* event);
void gtk_menu_popdown(GtkMenu* menu);
void gtk_widget_set_sensitive(GtkWidget* widget, int sensitive);

// Label functions
void gtk_label_set_markup(GtkLabel* label, const char* markup);
void gtk_label_set_text(GtkLabel* label, const char* text);
void gtk_label_set_ellipsize(GtkLabel* label, int mode);
void gtk_label_set_max_width_chars(GtkLabel* label, int n_chars);

// Flow box functions
void gtk_flow_box_set_homogeneous(GtkFlowBox* box, int homogeneous);
void gtk_flow_box_set_column_spacing(GtkFlowBox* box, int spacing);
void gtk_flow_box_set_row_spacing(GtkFlowBox* box, int spacing);
void gtk_flow_box_insert(GtkFlowBox* box, GtkWidget* child, int position);

// Scrolled window functions
void gtk_scrolled_window_set_policy(GtkScrolledWindow* window, int hscrollbar, int vscrollbar);

// Icon theme functions
GtkIconTheme* gtk_icon_theme_get_default(void);
GtkIconPaintable* gtk_icon_theme_lookup_by_gicon(GtkIconTheme* theme, void* icon, int size, int flags);

// GdkPixbuf functions
GdkPixbuf* gdk_pixbuf_get_from_texture(GdkTexture* texture);

// GIcon functions
void* g_icon_new_for_string(const char* str, void** error);

// GtkImage functions
GtkWidget* gtk_image_new_from_pixbuf(GdkPixbuf* pixbuf);
GtkWidget* gtk_image_new_from_icon_name(const char* icon_name, int size);

// GdkPixbuf scaling
GdkPixbuf* gdk_pixbuf_scale_simple(const GdkPixbuf* src, int dest_width, int dest_height, int interp_type);

// GObject functions
void g_object_set_data(GObject* object, const char* key, gpointer data);
gpointer g_object_get_data(GObject* object, const char* key);
void g_object_unref(gpointer object);

// GLib functions
guint g_timeout_add(guint interval, void* function_ptr, gpointer data);
gint g_strcmp0(const char* str1, const char* str2);

// System functions
int system(const char* command);

// GList functions
#define g_list_foreach(list, func, data) \
    for (GList* _l = list; _l != NULL; _l = _l->next) \
        func(_l->data, data)
