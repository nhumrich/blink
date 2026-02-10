type Celsius {
    value: Float
}

type Fahrenheit {
    value: Float
}

impl From[Celsius] for Fahrenheit {
    fn from(c: Celsius) -> Self {
        Fahrenheit { value: c.value * 1.8 + 32.0 }
    }
}

fn main() {
    let c = Celsius { value: 100.0 }
    let f: Fahrenheit = c.into()
    io.println("{f.value}")

    let c2 = Celsius { value: 0.0 }
    let f2: Fahrenheit = c2.into()
    io.println("{f2.value}")

    io.println("PASS")
}
