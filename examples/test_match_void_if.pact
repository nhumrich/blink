fn check_value(x: Int) ! IO {
    match x {
        1 => {
            if x > 0 {
                io.println("positive one")
            }
            if x < 10 {
                io.println("single digit")
            }
            io.println("was one")
        }
        _ => {
            io.println("other")
        }
    }
}

fn main() ! IO {
    check_value(1)
    check_value(42)
}
