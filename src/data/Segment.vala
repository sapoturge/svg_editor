public enum SegmentType {
    LINE,
    CURVE,
    ARC
}

public class Segment : Object {
    public SegmentType segment_type { get; set; }

    public Segment prev;
    public Segment next;
    
    // End points, used for all segments
    private Point _start;
    private Point _end;
    public Point start {
        get {
            return _start;
        }
        set {
            if (segment_type == ARC) {
                value = closest (value, out start_angle);
            }
            if (value != _start) {
                _start = value;
                if (prev != null && prev.end != value) {
                    prev.end = value;
                }
            }
        }
    }
            
    public Point end {
        get {
            return _end;
        }
        set {
            if (segment_type == ARC) {
                value = closest (value, out end_angle);
            }
            if (value != _end) {
                _end = value;
                if (next != null && next.start != value) {
                    next.start = value;
                }
            }
        }
    }

    // Control points, used for CURVE segments
    public Point p1 { get; set; }
    public Point p2 { get; set; }

    // SVG-based ARC control values
    public Point c { get; set; }
    public double rx { get; set; default = 16; }
    public double ry { get; set; default = 16; }
    public double angle { get; set; }
    public bool reverse { get; set; }
    // Easier to use and update than just points
    public double start_angle;
    public double end_angle;

    // Control points for ARC segments
    public Point topleft {
        get {
            return {c.x - Math.cos (angle) * rx + Math.sin (angle) * ry,
                    c.y - Math.cos (angle) * ry - Math.sin (angle) * rx};
        }
        set {
            c = {(value.x + bottomright.x) / 2, (value.y + bottomright.y) / 2};
            var a = Math.atan2 (value.y - c.y, value.x - c.x);
            var d = Math.sqrt (Math.pow (value.x - c.x, 2) + Math.pow (value.y - c.y, 2));
            rx = d * Math.cos (Math.PI + a - angle);
            ry = d * Math.sin (Math.PI + a - angle);
            start = point_from_angle(start_angle);
            end = point_from_angle(end_angle);
        }
    }

    public Point topright {
        get {
            return {c.x + Math.cos (angle) * rx + Math.sin (angle) * ry,
                    c.y - Math.cos (angle) * ry + Math.sin (angle) * rx};
        }
        set {
            c = {(value.x + bottomleft.x) / 2, (value.y + bottomleft.y) / 2};
            var a = Math.atan2 (value.y - c.y, value.x - c.x);
            var d = Math.sqrt (Math.pow (value.x - c.x, 2) + Math.pow (value.y - c.y, 2));
            rx = d * Math.cos (angle - a);
            ry = d * Math.sin (angle - a);
            start = point_from_angle(start_angle);
            end = point_from_angle(end_angle);
        }
    }

    public Point bottomleft {
        get {
            return {c.x - Math.cos (angle) * rx - Math.sin (angle) * ry,
                    c.y + Math.cos (angle) * ry - Math.sin (angle) * rx};
        }
        set {
            c = {(value.x + topright.x) / 2, (value.y + topright.y) / 2};
            var a = Math.atan2 (value.y - c.y, value.x - c.x);
            var d = Math.sqrt (Math.pow (value.x - c.x, 2) + Math.pow (value.y - c.y, 2));
            rx = d * Math.cos (Math.PI + angle - a);
            ry = d * Math.sin (Math.PI + angle - a);
            start = point_from_angle(start_angle);
            end = point_from_angle(end_angle);
        }
    }
    
    public Point bottomright {
        get {
            return {c.x + Math.cos (angle) * rx - Math.sin (angle) * ry,
                    c.y + Math.cos (angle) * ry + Math.sin (angle) * rx};
        }
        set {
            c = {(value.x + topleft.x) / 2, (value.y + topleft.y) / 2};
            var a = Math.atan2 (value.y - c.y, value.x - c.x);
            var d = Math.hypot (value.x - c.x, value.y - c.y);
            rx = d * Math.cos (a - angle);
            ry = d * Math.sin (a - angle);
            start = point_from_angle(start_angle);
            end = point_from_angle(end_angle);
        }
    }

    public Point controller {
        get {
            return {c.x + Math.cos (angle) * (rx + 5),
                    c.y + Math.sin (angle) * (rx + 5)};
        }
        set {
            angle = Math.atan2 (value.y - c.y, value.x - c.x);
            start = point_from_angle(start_angle);
            end = point_from_angle(end_angle);
        }
    }
            
    // Constructors
    public Segment.line (double x, double y) {
        segment_type = LINE;
        this.end = {x, y};
    }

    public Segment.curve (double x1, double y1, double x2, double y2, double x, double y) {
        segment_type = CURVE;
        this.end = {x, y};
        this.p1 = {x1, y1};
        this.p2 = {x2, y2};
    }

    public Segment.arc (double x, double y, double xc, double yc, double rx, double ry, double angle, bool reverse) {
        segment_type = ARC;
        this.end = {x, y};
        this.c = {xc, yc};
        this.rx = rx;
        this.ry = ry;
        this.angle = angle;
        this.reverse = reverse;
    }

    public void do_command (Cairo.Context cr) {
        switch (segment_type) {
            case LINE:
                cr.line_to (end.x, end.y);
                break;
            case CURVE:
                cr.curve_to (p1.x, p1.y, p2.x, p2.y, end.x, end.y);
                break;
            case ARC:
                cr.save ();
                cr.translate (c.x, c.y);
                cr.rotate (angle);
                cr.scale (rx, ry);
                print ("%f\n", angle);
                if (reverse) {
                    cr.arc_negative (0, 0, 1, start_angle, end_angle);
                } else {
                    cr.arc (0, 0, 1, start_angle, end_angle);
                }
                cr.restore ();
                break;
        }
    }

    private Point closest (Point original, out double p_angle) {
        // Logic copied from https://stackoverflow.com/questions/22959698/distance-from-given-point-to-given-ellipse
        var dx = original.x - c.x;
        var dy = original.y - c.y;
        var an = Math.atan2 (dy, dx);
        var d = Math.hypot (dx, dy);
        var px = Math.cos (an - angle) * d;
        var py = Math.sin (an - angle) * d;

        var tx = 0.707;
        var ty = 0.707;

        var a = rx;
        var b = ry;

        for (int i = 0; i < 3; i++) {
            var x = a * tx;
            var y = b * ty;

            var ex = (a * a - b * b) * Math.pow (tx, 3) / a;
            var ey = (b * b - a * a) * Math.pow (ty, 3) / b;

            var r_x = x - ex;
            var r_y = y - ey;

            var qx = px - ex;
            var qy = py - ey;

            var r = Math.hypot (r_y, r_x);
            var q = Math.hypot (qy, qx);

            // tx = double.min (1, double.max (0, (qx * r / q + ex) / a));
            // ty = double.min (1, double.max (0, (qy * r / q + ey) / b));
            tx = (qx * r / q + ex) / a;
            ty = (qy * r / q + ey) / b;
            var t = Math.hypot (ty, tx);
            tx /= t;
            ty /= t;
        }
        px = Math.copysign (a * tx, px);
        py = Math.copysign (b * ty, py);
        var sx = px / rx;
        var sy = py / ry;
        p_angle = Math.atan2 (sy, sx);
        return {c.x + Math.cos (angle) * px - Math.sin (angle) * py,
                c.y + Math.cos (angle) * py + Math.sin (angle) * px};
    }

    private Point point_from_angle (double a) {
        var dx = Math.cos (a);
        var dy = Math.sin (a);
        return {c.x + Math.cos (angle) * dx * rx - Math.sin (angle) * dy * ry,
                c.y + Math.cos (angle) * dy * ry + Math.sin (angle) * dx * rx};
    }
}
