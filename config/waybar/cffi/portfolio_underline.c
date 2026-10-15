/* A shared underline for Waybar's existing Hyprland workspace buttons.
 * Waybar CFFI ABI v2: include/modules/cffi.hpp, Waybar 0.15.0.
 * No IPC, polling, or replacement workspace controls are needed.
 */
#include <gtk/gtk.h>
#include <math.h>

typedef struct wbcffi_module wbcffi_module;
typedef struct {
    wbcffi_module *obj;
    const char *waybar_version;
    GtkContainer *(*get_root_widget)(wbcffi_module *);
    void (*queue_update)(wbcffi_module *);
} wbcffi_init_info;
typedef struct {
    const char *key;
    const char *value;
} wbcffi_config_entry;

typedef struct {
    GtkWidget *root;
    GtkWidget *workspaces;
    guint attach_source;
    guint tick_id;
    guint attach_attempts;
    gulong draw_handler;
    gboolean positioned;
    gboolean moving;
    double x, width;
    double from_x, from_width;
    double target_x, target_width;
    gint64 started;
    double duration_us;
} Underline;

/* Portfolio: cubic-bezier(0, .99, .62, 1.07). Solve x before sampling y. */
static double ease(double progress) {
    if (progress <= 0.0) return 0.0;
    if (progress >= 1.0) return 1.0;
    double low = 0.0, high = 1.0, t = 0.0;
    for (int i = 0; i < 28; ++i) {
        t = (low + high) / 2.0;
        double x = 3.0 * (1.0 - t) * t * t * .62 + t * t * t;
        if (x < progress) low = t;
        else high = t;
    }
    return 3.0 * (1.0 - t) * (1.0 - t) * t * .99
         + 3.0 * (1.0 - t) * t * t * 1.07 + t * t * t;
}

static void advance(Underline *line, gint64 now) {
    if (!line->moving) return;
    double progress = CLAMP((now - line->started) / line->duration_us, 0.0, 1.0);
    double amount = ease(progress);
    line->x = line->from_x + (line->target_x - line->from_x) * amount;
    line->width = line->from_width + (line->target_width - line->from_width) * amount;
    line->moving = progress < 1.0;
}

static gboolean tick(GtkWidget *widget, GdkFrameClock *clock, gpointer data) {
    Underline *line = data;
    advance(line, gdk_frame_clock_get_frame_time(clock));
    gtk_widget_queue_draw(widget);
    if (!line->moving) {
        line->tick_id = 0;
        return G_SOURCE_REMOVE;
    }
    return G_SOURCE_CONTINUE;
}

static void target(Underline *line, double x, double width, gint64 now) {
    if (!line->positioned) {
        line->x = line->target_x = x;
        line->width = line->target_width = width;
        line->positioned = TRUE;
        return;
    }
    if (fabs(x - line->target_x) < .01 && fabs(width - line->target_width) < .01)
        return;

    /* A quick second switch starts from the current, interpolated position. */
    advance(line, now);
    line->from_x = line->x;
    line->from_width = line->width;
    line->target_x = x;
    line->target_width = width;
    line->started = now;
    line->moving = TRUE;
    if (!line->tick_id)
        line->tick_id = gtk_widget_add_tick_callback(line->workspaces, tick, line, NULL);
}

static GtkWidget *active_button(GtkWidget *widget) {
    if (!gtk_widget_get_visible(widget)) return NULL;
    if (GTK_IS_BUTTON(widget) &&
        gtk_style_context_has_class(gtk_widget_get_style_context(widget), "active"))
        return widget;
    if (!GTK_IS_CONTAINER(widget)) return NULL;
    GList *children = gtk_container_get_children(GTK_CONTAINER(widget));
    GtkWidget *found = NULL;
    for (GList *item = children; item && !found; item = item->next)
        found = active_button(GTK_WIDGET(item->data));
    g_list_free(children);
    return found;
}

static gboolean draw_underline(GtkWidget *widget, cairo_t *cr, gpointer data) {
    Underline *line = data;
    GdkRGBA color;
    GtkStyleContext *context = gtk_widget_get_style_context(widget);
    /* Other themes keep their own workspace styles. */
    if (!gtk_style_context_lookup_color(context, "portfolio_accent", &color)) {
        line->positioned = FALSE;
        line->moving = FALSE;
        return FALSE;
    }
    GtkWidget *active = active_button(widget);
    int x, y;
    if (!active || !gtk_widget_translate_coordinates(active, widget, 0, 0, &x, &y)) {
        line->positioned = FALSE;
        line->moving = FALSE;
        return FALSE;
    }
    gint64 now = g_get_monotonic_time();
    target(line, x + 2, MAX(1, gtk_widget_get_allocated_width(active) - 4), now);
    advance(line, now);
    gdk_cairo_set_source_rgba(cr, &color);
    cairo_rectangle(cr, line->x, y + gtk_widget_get_allocated_height(active) - 2,
                    MAX(1.0, line->width), 2.0);
    cairo_fill(cr);
    return FALSE;
}

static GtkWidget *find_workspaces(GtkWidget *widget) {
    if (g_strcmp0(gtk_widget_get_name(widget), "workspaces") == 0)
        return widget;
    if (!GTK_IS_CONTAINER(widget)) return NULL;
    GList *children = gtk_container_get_children(GTK_CONTAINER(widget));
    GtkWidget *found = NULL;
    for (GList *item = children; item && !found; item = item->next)
        found = find_workspaces(GTK_WIDGET(item->data));
    g_list_free(children);
    return found;
}

static gboolean attach(gpointer data) {
    Underline *line = data;
    GtkWidget *widget = find_workspaces(gtk_widget_get_toplevel(line->root));
    if (!widget) {
        if (++line->attach_attempts < 40) return G_SOURCE_CONTINUE;
        g_warning("portfolio underline: no workspace widget found; keeping native underline");
        line->attach_source = 0;
        return G_SOURCE_REMOVE;
    }
    line->workspaces = g_object_ref(widget);
    line->draw_handler = g_signal_connect_after(widget, "draw", G_CALLBACK(draw_underline), line);
    gtk_style_context_add_class(gtk_widget_get_style_context(widget), "sliding-underline");
    gtk_widget_queue_draw(widget);
    line->attach_source = 0;
    return G_SOURCE_REMOVE;
}

const size_t wbcffi_version = 2;

void *wbcffi_init(const wbcffi_init_info *info, const wbcffi_config_entry *entries,
                  size_t count) {
    Underline *line = g_new0(Underline, 1);
    line->duration_us = 300000.0;
    for (size_t i = 0; i < count; ++i) {
        if (g_strcmp0(entries[i].key, "duration-ms") == 0) {
            double ms = g_ascii_strtod(entries[i].value, NULL);
            if (isfinite(ms) && ms >= 50 && ms <= 2000)
                line->duration_us = ms * 1000.0;
        }
    }
    line->root = g_object_ref(GTK_WIDGET(info->get_root_widget(info->obj)));
    /* This module draws over the native module and occupies no bar space. */
    gtk_widget_set_no_show_all(line->root, TRUE);
    gtk_widget_hide(line->root);
    line->attach_source = g_timeout_add(25, attach, line);
    return line;
}

void wbcffi_deinit(void *instance) {
    Underline *line = instance;
    if (!line) return;
    if (line->attach_source) g_source_remove(line->attach_source);
    if (line->workspaces) {
        if (line->tick_id) gtk_widget_remove_tick_callback(line->workspaces, line->tick_id);
        if (g_signal_handler_is_connected(line->workspaces, line->draw_handler))
            g_signal_handler_disconnect(line->workspaces, line->draw_handler);
        gtk_style_context_remove_class(gtk_widget_get_style_context(line->workspaces),
                                       "sliding-underline");
        gtk_widget_queue_draw(line->workspaces);
        g_object_unref(line->workspaces);
    }
    g_object_unref(line->root);
    g_free(line);
}
