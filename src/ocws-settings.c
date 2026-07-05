#include <gtk/gtk.h>
#include <stdlib.h>

static void execute_command(GtkWidget *widget, gpointer data) {
    const char *cmd = (const char *)data;
    if (system(cmd) == -1) {
        g_warning("Failed to execute command: %s", cmd);
    }
}

static GtkWidget* create_action_row(const char *title, const char *subtitle, const char *button_label, const char *command) {
    GtkWidget *row = gtk_box_new(GTK_ORIENTATION_HORIZONTAL, 10);
    gtk_widget_set_margin_bottom(row, 10);

    GtkWidget *vbox = gtk_box_new(GTK_ORIENTATION_VERTICAL, 2);
    
    char *markup = g_strdup_printf("<b>%s</b>", title);
    GtkWidget *lbl_title = gtk_label_new(NULL);
    gtk_label_set_markup(GTK_LABEL(lbl_title), markup);
    gtk_label_set_xalign(GTK_LABEL(lbl_title), 0.0);
    g_free(markup);
    
    GtkWidget *lbl_sub = gtk_label_new(subtitle);
    gtk_label_set_xalign(GTK_LABEL(lbl_sub), 0.0);
    gtk_style_context_add_class(gtk_widget_get_style_context(lbl_sub), "dim-label");

    gtk_box_pack_start(GTK_BOX(vbox), lbl_title, FALSE, FALSE, 0);
    gtk_box_pack_start(GTK_BOX(vbox), lbl_sub, FALSE, FALSE, 0);

    GtkWidget *btn = gtk_button_new_with_label(button_label);
    gtk_widget_set_valign(btn, GTK_ALIGN_CENTER);
    g_signal_connect(btn, "clicked", G_CALLBACK(execute_command), (gpointer)command);

    gtk_box_pack_start(GTK_BOX(row), vbox, TRUE, TRUE, 0);
    gtk_box_pack_start(GTK_BOX(row), btn, FALSE, FALSE, 0);

    return row;
}

static void activate(GtkApplication *app, gpointer user_data) {
    GtkWidget *window;
    GtkWidget *header;
    GtkWidget *hbox;
    GtkWidget *stack;
    GtkWidget *sidebar;

    // Window
    window = gtk_application_window_new(app);
    gtk_window_set_title(GTK_WINDOW(window), "OCWS Settings");
    gtk_window_set_default_size(GTK_WINDOW(window), 800, 550);
    gtk_window_set_position(GTK_WINDOW(window), GTK_WIN_POS_CENTER);

    // Header Bar
    header = gtk_header_bar_new();
    gtk_header_bar_set_show_close_button(GTK_HEADER_BAR(header), TRUE);
    gtk_header_bar_set_title(GTK_HEADER_BAR(header), "OCWS Settings");
    gtk_header_bar_set_subtitle(GTK_HEADER_BAR(header), "Our C-Written Shell Control Center");
    gtk_window_set_titlebar(GTK_WINDOW(window), header);

    // Main layout
    hbox = gtk_box_new(GTK_ORIENTATION_HORIZONTAL, 0);
    gtk_container_add(GTK_CONTAINER(window), hbox);

    // Sidebar & Stack
    sidebar = gtk_stack_sidebar_new();
    gtk_widget_set_size_request(sidebar, 200, -1);
    stack = gtk_stack_new();
    gtk_stack_set_transition_type(GTK_STACK(stack), GTK_STACK_TRANSITION_TYPE_SLIDE_UP_DOWN);
    gtk_stack_sidebar_set_stack(GTK_STACK_SIDEBAR(sidebar), GTK_STACK(stack));

    gtk_box_pack_start(GTK_BOX(hbox), sidebar, FALSE, FALSE, 0);
    gtk_box_pack_start(GTK_BOX(hbox), gtk_separator_new(GTK_ORIENTATION_VERTICAL), FALSE, FALSE, 0);
    gtk_box_pack_start(GTK_BOX(hbox), stack, TRUE, TRUE, 0);

    // ==========================================
    // Tab: Appearance
    // ==========================================
    GtkWidget *box_app = gtk_box_new(GTK_ORIENTATION_VERTICAL, 15);
    gtk_container_set_border_width(GTK_CONTAINER(box_app), 30);
    gtk_stack_add_titled(GTK_STACK(stack), box_app, "appearance", "Appearance");

    gtk_box_pack_start(GTK_BOX(box_app), create_action_row(
        "Theme Engine", "Manage colors, glassmorphism, and scheduling", "Open Themes", 
        "theme-scheduler.sh &"), FALSE, FALSE, 0);
        
    gtk_box_pack_start(GTK_BOX(box_app), create_action_row(
        "Icon Theme", "Switch global system icons for GTK and Docks", "Select Icons", 
        "icon-theme-picker.sh &"), FALSE, FALSE, 0);
        
    gtk_box_pack_start(GTK_BOX(box_app), create_action_row(
        "Download Icons", "Fetch community icon packs from GitHub", "Download", 
        "download-icons.sh &"), FALSE, FALSE, 0);

    gtk_box_pack_start(GTK_BOX(box_app), create_action_row(
        "Wallpaper Engine", "Randomize or set your desktop background", "Randomize", 
        "wallpaper random &"), FALSE, FALSE, 0);

    gtk_box_pack_start(GTK_BOX(box_app), create_action_row(
        "Font Scaling", "Adjust global UI font scaling", "Scale UI", 
        "font-scale.sh &"), FALSE, FALSE, 0);


    // ==========================================
    // Tab: Shell & UI
    // ==========================================
    GtkWidget *box_shell = gtk_box_new(GTK_ORIENTATION_VERTICAL, 15);
    gtk_container_set_border_width(GTK_CONTAINER(box_shell), 30);
    gtk_stack_add_titled(GTK_STACK(stack), box_shell, "shell", "Shell & Environment");

    gtk_box_pack_start(GTK_BOX(box_shell), create_action_row(
        "Mode: Noctalia (Default)", "Launch the Noctalia layer shell", "Activate", 
        "shell-switcher.sh noctalia"), FALSE, FALSE, 0);

    gtk_box_pack_start(GTK_BOX(box_shell), create_action_row(
        "Mode: SFWBar + Crystal Dock", "Top panel sfwbar + bottom macOS dock", "Activate", 
        "shell-switcher.sh crystal_dock"), FALSE, FALSE, 0);

    gtk_box_pack_start(GTK_BOX(box_shell), create_action_row(
        "Mode: SFWBar Dual Panel", "Top and bottom panels via sfwbar", "Activate", 
        "shell-switcher.sh double_panel"), FALSE, FALSE, 0);

    gtk_box_pack_start(GTK_BOX(box_shell), create_action_row(
        "Keybinding Presets", "Load and map LabWC keyboard shortcuts", "Keybinds", 
        "keybind-presets.sh &"), FALSE, FALSE, 0);

    gtk_box_pack_start(GTK_BOX(box_shell), create_action_row(
        "Workspace Layout", "Configure virtual desktop behaviors", "Workspaces", 
        "workspace-presets.sh &"), FALSE, FALSE, 0);
        
    gtk_box_pack_start(GTK_BOX(box_shell), create_action_row(
        "Natural Scrolling", "Toggle trackpad inverse scroll direction", "Toggle Scroll", 
        "toggle-natural-scroll.sh &"), FALSE, FALSE, 0);
        
    gtk_box_pack_start(GTK_BOX(box_shell), create_action_row(
        "Reload Compositor", "Soft-reload LabWC rules and configurations", "Reload Window Manager", 
        "labwc -r"), FALSE, FALSE, 0);


    // ==========================================
    // Tab: Utilities & Network
    // ==========================================
    GtkWidget *box_utils = gtk_box_new(GTK_ORIENTATION_VERTICAL, 15);
    gtk_container_set_border_width(GTK_CONTAINER(box_utils), 30);
    gtk_stack_add_titled(GTK_STACK(stack), box_utils, "utils", "Utilities");

    gtk_box_pack_start(GTK_BOX(box_utils), create_action_row(
        "Wi-Fi Manager", "Scan and connect to wireless networks", "Open Wi-Fi", 
        "wifi-menu.sh &"), FALSE, FALSE, 0);

    gtk_box_pack_start(GTK_BOX(box_utils), create_action_row(
        "Bluetooth Manager", "Pair and manage Bluetooth devices", "Open Bluetooth", 
        "bluetooth-menu.sh &"), FALSE, FALSE, 0);
        
    gtk_box_pack_start(GTK_BOX(box_utils), create_action_row(
        "Audio Settings", "Control PulseAudio/Pipewire volume levels", "Audio Controls", 
        "actions.sh audio &"), FALSE, FALSE, 0);
        
    gtk_box_pack_start(GTK_BOX(box_utils), create_action_row(
        "System Maintenance", "Run diagnostic and maintenance utilities", "Maintenance", 
        "actions.sh maintenance &"), FALSE, FALSE, 0);

    // ==========================================
    // Tab: Data & State
    // ==========================================
    GtkWidget *box_state = gtk_box_new(GTK_ORIENTATION_VERTICAL, 15);
    gtk_container_set_border_width(GTK_CONTAINER(box_state), 30);
    gtk_stack_add_titled(GTK_STACK(stack), box_state, "state", "Persistence");

    gtk_box_pack_start(GTK_BOX(box_state), create_action_row(
        "Backup Configuration", "Backup current OCWS KV state and dotfiles", "Backup", 
        "backup.sh &"), FALSE, FALSE, 0);

    gtk_box_pack_start(GTK_BOX(box_state), create_action_row(
        "Restore Configuration", "Restore previous configurations from backup", "Restore", 
        "restore.sh &"), FALSE, FALSE, 0);
        
    gtk_box_pack_start(GTK_BOX(box_state), create_action_row(
        "Dotfiles Sync", "Sync local configurations with remote Git branch", "Sync Git", 
        "dotfiles-sync.sh &"), FALSE, FALSE, 0);


    gtk_widget_show_all(window);
}

int main(int argc, char **argv) {
    GtkApplication *app;
    int status;

    app = gtk_application_new("org.ocws.settings", G_APPLICATION_DEFAULT_FLAGS);
    g_signal_connect(app, "activate", G_CALLBACK(activate), NULL);
    
    status = g_application_run(G_APPLICATION(app), argc, argv);
    g_object_unref(app);

    return status;
}
