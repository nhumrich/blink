type Expr {
    Lit(value: Int)
    Add(left: Int, right: Int)
    Neg(inner: Int)
}

fn eval(e: Expr) -> Int {
    match e {
        Expr.Lit(v) => v
        Expr.Add(l, r) => l + r
        Expr.Neg(i) => 0 - i
    }
}

fn main() {
    let a = Expr.Lit(42)
    let b = Expr.Add(10, 20)
    let c = Expr.Neg(7)

    io.println(eval(a))
    io.println(eval(b))
    io.println(eval(c))

    // Test bare variant constructor
    let d = Lit(100)
    io.println(eval(d))
}
