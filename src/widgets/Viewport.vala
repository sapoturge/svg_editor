public class Viewport : Gtk.DrawingArea, Gtk.Scrollable {
    private int scroll_x;
    private int scroll_y;
    private int base_x;
    private int base_y;
    private double zoom = 1;
    private int width = 0;
    private int height = 0;

    private Gdk.RGBA background;

    private Image _image;
    private Gtk.Adjustment horizontal;
    private Gtk.Adjustment vertical;

    public Image image {
        get {
            return _image;
        }
        set {
            _image = value;
            _image.update.connect (() => {
                queue_draw_area (0, 0, width, height);
            });
            scroll_x = -_image.width / 2;
            scroll_y = -_image.height / 2;
        }
    }
            
    public Gtk.Adjustment hadjustment {
        get {
            return horizontal;
        }
        set construct {
            horizontal = value;
            if (horizontal == null) {
                horizontal = new Gtk.Adjustment (0, 0, 0, 0, 0, 0);
            }
            // Set values
            if (image != null) {
                horizontal.lower = scale_x (0) / image.width;
                horizontal.value = scale_x (width/2) / image.width;
                horizontal.upper = scale_x (width) / image.width;
                horizontal.page_size = image.width;
            }
            // Bind events
            
        }
    }
    public Gtk.Adjustment vadjustment {
        get {
            return vertical;
        }
        set construct {
            vertical = value;
            if (vertical == null) {
                vertical = new Gtk.Adjustment (0, 0, 0, 0, 0, 0);
            }
            // Set values
            if (image != null) {
                vertical.lower = scale_y (0) / image.height;
                vertical.value = scale_y (height / 2) / image.height;
                vertical.upper = scale_y (height) / image.height;
                vertical.page_size = image.height;
            }
            // Bind events
        }
    }

    public Gtk.ScrollablePolicy hscroll_policy {
        get {
            return Gtk.ScrollablePolicy.NATURAL;
        }
        set {
        }
    }

    public Gtk.ScrollablePolicy vscroll_policy {
        get {
            return Gtk.ScrollablePolicy.NATURAL;
        }
        set {
        }
    }

    public Viewport () {}

    public Viewport.with_image (Image image) {
        this.image = image;
    }

    private double scale_x (double x) {
        return (x - width / 2 + scroll_x) / zoom;
    }

    private double scale_y (double y) {
        return (y - height / 2 + scroll_y) / zoom;
    }

    construct {
        background = {0.7, 0.7, 0.7, 1.0};

        add_events (Gdk.EventMask.BUTTON_RELEASE_MASK |
                    Gdk.EventMask.BUTTON_PRESS_MASK |
                    Gdk.EventMask.BUTTON_MOTION_MASK |
                    Gdk.EventMask.SCROLL_MASK);

        draw.connect ((cr) => {
            cr.set_source_rgb (background.red, background.green, background.blue);
            cr.paint ();

            cr.translate (width / 2, height / 2);
            cr.translate (scroll_x, scroll_y);
            cr.save ();
            cr.scale (zoom, zoom);

            // Draw Image
            image.draw (cr);

            // Draw Grid

            // Draw Control Handles

            cr.restore();
            return false;
        });

        size_allocate.connect ((alloc) => {
            width = alloc.width;
            height = alloc.height;
        });
        
        button_press_event.connect ((event) => {
            var x = scale_x (event.x);
            var y = scale_y (event.y);
            // Check for clicking on a control handle
            // Check for clicking on a segment
            // Assume dragging
        });

        motion_notify_event.connect ((event) => {
            // Drag control handle
            // Drag entire segment?
            // Scroll
        });

        button_release_event.connect ((event) => {
            // Stop scrolling, dragging, etc.
            return false;
        });

        /* // From EditorView, working scroll code and such.
        drawing_area.button_press_event.connect ((event) => {
            var scaled_x = (event.x - width / 2 + scroll_x) / zoom;
            var scaled_y = (event.y - height / 2 + scroll_y) / zoom;
            if (image.button_press (scaled_x, scaled_y, zoom)) {
                image_handling = true;
                return false;
            }
            scrolling = true;
            base_x = ((int)event.x)-scroll_x;
            base_y = ((int)event.y)-scroll_y;
            return false;
        });
        drawing_area.motion_notify_event.connect ((event) => {
            if (image_handling) {
                image.motion (event);
            }
            if (scrolling) {
                scroll_x = ((int)event.x)-base_x;
                scroll_y = ((int)event.y)-base_y;
                updated = true;
            }
            return false;
        });
        */

        scroll_event.connect ((event) => {
            if (event.direction == Gdk.ScrollDirection.UP) {
                zoom *= 2;
                scroll_x *= 2;
                scroll_y *= 2;
            } else if (event.direction == Gdk.ScrollDirection.DOWN && zoom > 1) {
                zoom /= 2;
                scroll_x /= 2;
                scroll_y /= 2;
            }
            queue_draw_area (0, 0, width, height);
            return false;
        });
    }

    public bool get_border (out Gtk.Border border) {
        border = {0, 0, 0, 0};
        return true;
    }
}