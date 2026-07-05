#include <gtk/gtk.h>
#include <gtk-layer-shell/gtk-layer-shell.h>
#include <math.h>

static double t = 0.0;

static gboolean on_draw(GtkWidget *widget, cairo_t *cr, gpointer data) {
    int width = gtk_widget_get_allocated_width(widget);
    int height = gtk_widget_get_allocated_height(widget);

    // Create an astonishing animated gradient
    cairo_pattern_t *pat = cairo_pattern_create_linear(0.0, 0.0, width, height);
    
    // Animate colors based on time
    double r1 = 0.5 + 0.5 * sin(t * 0.5);
    double g1 = 0.5 + 0.5 * sin(t * 0.7 + 2.0);
    double b1 = 0.5 + 0.5 * sin(t * 0.3 + 4.0);
    
    double r2 = 0.5 + 0.5 * sin(t * 0.4 + 1.0);
    double g2 = 0.5 + 0.5 * sin(t * 0.8 + 3.0);
    double b2 = 0.5 + 0.5 * sin(t * 0.6 + 5.0);

    cairo_pattern_add_color_stop_rgba(pat, 0, r1 * 0.3, g1 * 0.3, b1 * 0.5 + 0.2, 1.0);
    cairo_pattern_add_color_stop_rgba(pat, 1, r2 * 0.2, g2 * 0.4, b2 * 0.6 + 0.2, 1.0);

    cairo_set_source(cr, pat);
    cairo_paint(cr);
    cairo_pattern_destroy(pat);

    return FALSE;
}

static gboolean on_tick(GtkWidget *widget, GdkFrameClock *frame_clock, gpointer user_data) {
    t += 0.03;
    gtk_widget_queue_draw(widget);
    return G_SOURCE_CONTINUE;
}

static void activate(GtkApplication* app, gpointer user_data) {
    GtkWidget *window = gtk_application_window_new(app);

    // Initialize layer shell
    gtk_layer_init_for_window(GTK_WINDOW(window));
    gtk_layer_set_layer(GTK_WINDOW(window), GTK_LAYER_SHELL_LAYER_BACKGROUND);
    
    // Anchor to all edges to fill the screen
    gtk_layer_set_anchor(GTK_WINDOW(window), GTK_LAYER_SHELL_EDGE_LEFT, TRUE);
    gtk_layer_set_anchor(GTK_WINDOW(window), GTK_LAYER_SHELL_EDGE_RIGHT, TRUE);
    gtk_layer_set_anchor(GTK_WINDOW(window), GTK_LAYER_SHELL_EDGE_TOP, TRUE);
    gtk_layer_set_anchor(GTK_WINDOW(window), GTK_LAYER_SHELL_EDGE_BOTTOM, TRUE);
    
    gtk_layer_set_exclusive_zone(GTK_WINDOW(window), -1);

    // Create drawing area
    GtkWidget *drawing_area = gtk_drawing_area_new();
    gtk_container_add(GTK_CONTAINER(window), drawing_area);

    g_signal_connect(G_OBJECT(drawing_area), "draw", G_CALLBACK(on_draw), NULL);
    gtk_widget_add_tick_callback(drawing_area, on_tick, NULL, NULL);

    gtk_widget_show_all(window);
}

int main(int argc, char **argv) {
    GtkApplication *app = gtk_application_new("org.ocws.livebg", G_APPLICATION_FLAGS_NONE);
    g_signal_connect(app, "activate", G_CALLBACK(activate), NULL);
    int status = g_application_run(G_APPLICATION(app), argc, argv);
    g_object_unref(app);
    return status;
}
