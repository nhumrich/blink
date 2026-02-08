# Getting Started with Pact

Pact is a statically typed, effect-tracked language designed for correctness and clarity.
For a full language tour, see [README.md](README.md).

> **Note:** Pact is in early development (spec v0.3). Installation methods below describe the intended experience;
> some are not yet available.

## Installation

### Package Manager (planned)

```sh
pact install
```

### Binary Download (planned)

Download a prebuilt binary from the [releases page](#) for your platform.

### Build from Source

Pact is self-hosting — the compiler is written in Pact and compiles itself. A checked-in C file provides the bootstrap:

```sh
git clone https://github.com/nhumrich/pact.git
cd pact
./bootstrap/bootstrap.sh
```

This compiles the bootstrap C file with your system's C compiler, then uses it to compile the Pact compiler source (`examples/pactc_amalg.pact`), verifying the self-compilation is stable. The result lands at `build/pactc`.

## Your First Program

Create a file called `hello.pact`:

```pact
fn greet(name: Str) ! IO {
    io.println("Hello, {name}!")
}

fn main() {
    let name = env.args().get(1) ?? "world"
    greet(name)
    io.println("Welcome to Pact.")
}
```

Run it:

```sh
pact run hello.pact
# Hello, world!
# Welcome to Pact.

pact run hello.pact Alice
# Hello, Alice!
# Welcome to Pact.
```

## Compiling

Compile to C and then to a native binary:

```sh
build/pactc hello.pact hello.c
cc -o hello hello.c -lm
./hello
```

## Running Tests

Pact supports test blocks directly in source files:

```pact
fn add(a: Int, b: Int) -> Int {
    a + b
}

test "addition" {
    assert add(1, 2) == 3
}
```

Run tests with:

```sh
pact test myfile.pact
```

## Next Steps

- [README.md](README.md) — language tour and quick reference
- [SPEC.md](SPEC.md) — full language specification
- [examples/](examples/) — working example programs
- [sections/](sections/) — detailed spec sections (types, effects, contracts, etc.)
