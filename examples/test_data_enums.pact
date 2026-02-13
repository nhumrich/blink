type Shape {
    Circle(radius: Float)
    Rectangle(width: Float, height: Float)
    Point
}

fn area(s: Shape) -> Float {
    match s {
        Shape.Circle(r) => 3.14159 * r * r
        Shape.Rectangle(w, h) => w * h
        Shape.Point => 0.0
    }
}

fn describe(s: Shape) -> Str {
    match s {
        Shape.Circle(_) => "circle"
        Shape.Rectangle(_, _) => "rectangle"
        Shape.Point => "point"
    }
}

fn main() {
    let c = Shape.Circle(5.0)
    let r = Shape.Rectangle(3.0, 4.0)
    let p = Shape.Point

    io.println("Circle area:")
    io.println(area(c))
    io.println("Rectangle area:")
    io.println(area(r))
    io.println("Point area:")
    io.println(area(p))

    io.println(describe(c))
    io.println(describe(r))
    io.println(describe(p))
}
