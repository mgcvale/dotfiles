#include "portfolio_underline.c"

static void pump(unsigned milliseconds) {
    gint64 until = g_get_monotonic_time() + milliseconds * 1000;
    do {
        while (g_main_context_iteration(NULL, FALSE)) {}
        g_usleep(1000);
    } while (g_get_monotonic_time() < until);
}

static GtkContainer *test_root(wbcffi_module *obj) {
    return GTK_CONTAINER(obj);
}

static void select_button(GtkWidget **buttons, int count, int index) {
    for (int i = 0; i < count; ++i) {
        GtkStyleContext *context = gtk_widget_get_style_context(buttons[i]);
        if (i == index) gtk_style_context_add_class(context, "active");
        else gtk_style_context_remove_class(context, "active");
    }
}

static void test_easing(void) {
    g_assert_cmpfloat(ease(0), ==, 0);
    g_assert_cmpfloat(ease(1), ==, 1);
    g_assert_cmpfloat(ease(.25), >, .6);
    g_assert_cmpfloat(ease(.8), >, 1);
}

static void test_retarget(void) {
    GtkWidget *widget = gtk_box_new(GTK_ORIENTATION_HORIZONTAL, 0);
    g_object_ref_sink(widget);
    Underline line = {.workspaces = widget, .duration_us = 300000};
    target(&line, 0, 28, 1000000);
    target(&line, 128, 28, 1000000);
    advance(&line, 1050000);
    double midway = line.x;
    g_assert_cmpfloat(midway, >, 0);
    g_assert_cmpfloat(midway, <, 128);
    target(&line, 32, 28, 1050000);
    g_assert_cmpfloat(line.x, ==, midway);
    advance(&line, 1350000);
    g_assert_cmpfloat(line.x, ==, 32);
    g_assert_false(line.moving);
    gtk_widget_remove_tick_callback(widget, line.tick_id);
    gtk_widget_destroy(widget);
    g_object_unref(widget);
}

static void test_render_lifecycle(void) {
    GtkWidget *window = gtk_offscreen_window_new();
    GtkWidget *box = gtk_box_new(GTK_ORIENTATION_HORIZONTAL, 0);
    GtkWidget *workspaces = gtk_box_new(GTK_ORIENTATION_HORIZONTAL, 4);
    GtkWidget *root = gtk_event_box_new();
    gtk_widget_set_name(workspaces, "workspaces");
    gtk_container_add(GTK_CONTAINER(window), box);
    gtk_container_add(GTK_CONTAINER(box), workspaces);
    gtk_container_add(GTK_CONTAINER(box), root);
    GtkWidget *buttons[6];
    for (int i = 0; i < 5; ++i) {
        buttons[i] = gtk_button_new_with_label("1");
        gtk_widget_set_size_request(buttons[i], 28, 24);
        gtk_container_add(GTK_CONTAINER(workspaces), buttons[i]);
    }
    select_button(buttons, 5, 0);
    wbcffi_init_info info = {.obj = (wbcffi_module *)root, .get_root_widget = test_root};
    Underline *line = wbcffi_init(&info, NULL, 0);
    gtk_widget_show_all(window);
    pump(100);
    g_assert_true(line->positioned);
    g_assert_false(gtk_widget_get_visible(root));
    g_assert_true(line->workspaces == workspaces);

    select_button(buttons, 5, 4);
    pump(50);
    g_assert_true(line->moving);
    g_assert_cmpfloat(line->x, >, 1);
    g_assert_cmpfloat(line->x, <, line->target_x);

    select_button(buttons, 5, 1);
    pump(380);
    int x, y;
    gtk_widget_translate_coordinates(buttons[1], workspaces, 0, 0, &x, &y);
    g_assert_cmpfloat(fabs(line->x - (x + 2)), <, .01);
    g_assert_false(line->moving);
    g_assert_cmpuint(line->tick_id, ==, 0);

    /* The actual rendered result contains one full-opacity underline. */
    GdkPixbuf *image = gtk_offscreen_window_get_pixbuf(GTK_OFFSCREEN_WINDOW(window));
    int row = y + gtk_widget_get_allocated_height(buttons[1]) - 1;
    guchar *pixels = gdk_pixbuf_get_pixels(image) + row * gdk_pixbuf_get_rowstride(image);
    int channels = gdk_pixbuf_get_n_channels(image), red_count = 0;
    for (int i = 0; i < gdk_pixbuf_get_width(image); ++i) {
        guchar *pixel = pixels + i * channels;
        if (pixel[0] > 240 && pixel[1] < 10 && pixel[2] < 10) ++red_count;
    }
    g_assert_cmpint(red_count, ==, gtk_widget_get_allocated_width(buttons[1]) - 4);
    g_object_unref(image);

    /* Newly created workspaces require no separate subscription or rebuild. */
    buttons[5] = gtk_button_new_with_label("6");
    gtk_widget_set_size_request(buttons[5], 28, 24);
    gtk_container_add(GTK_CONTAINER(workspaces), buttons[5]);
    gtk_widget_show_all(workspaces);
    select_button(buttons, 6, 5);
    pump(380);
    gtk_widget_translate_coordinates(buttons[5], workspaces, 0, 0, &x, &y);
    g_assert_cmpfloat(fabs(line->x - (x + 2)), <, .01);
    g_assert_cmpuint(line->tick_id, ==, 0);

    /* Tear down during motion, including when the native widgets die first. */
    select_button(buttons, 6, 0);
    pump(40);
    g_assert_true(line->moving);
    gtk_widget_destroy(window);
    wbcffi_deinit(line);
    pump(30);

    root = gtk_event_box_new();
    g_object_ref_sink(root);
    info.obj = (wbcffi_module *)root;
    line = wbcffi_init(&info, NULL, 0);
    wbcffi_deinit(line); /* Also cancel a pending attach on early reload. */
    gtk_widget_destroy(root);
    g_object_unref(root);
    pump(30);
}

int main(int argc, char **argv) {
    gtk_test_init(&argc, &argv, NULL);
    GtkCssProvider *provider = gtk_css_provider_new();
    gtk_css_provider_load_from_data(provider,
        "@define-color portfolio_accent #ff0000;"
        "* { min-height: 0; padding: 0; margin: 0; border: none; box-shadow: none; }"
        "window { background: black; }"
        "button { background: none; color: #aaaaaa; font-size: 14px; }"
        "button.active { color: white; }", -1, NULL);
    gtk_style_context_add_provider_for_screen(gdk_screen_get_default(),
        GTK_STYLE_PROVIDER(provider), GTK_STYLE_PROVIDER_PRIORITY_APPLICATION);
    g_test_add_func("/underline/easing", test_easing);
    g_test_add_func("/underline/rapid-retarget", test_retarget);
    g_test_add_func("/underline/render-and-lifecycle", test_render_lifecycle);
    int result = g_test_run();
    gtk_style_context_remove_provider_for_screen(gdk_screen_get_default(), GTK_STYLE_PROVIDER(provider));
    g_object_unref(provider);
    return result;
}
