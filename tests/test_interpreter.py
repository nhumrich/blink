import pathlib

import pact.lexer as lexer
import pact.parser as parser
import pact.interpreter as interpreter
import pact.runtime as runtime


EXAMPLES_DIR = pathlib.Path(__file__).resolve().parent.parent / "examples"


def run_pact(source, capsys, argv=None):
    tokens = lexer.lex(source)
    program = parser.parse(tokens)
    interp = interpreter.Interpreter(argv or [])
    interp.run(program)
    return capsys.readouterr().out


def run_pact_tests(source):
    tokens = lexer.lex(source)
    program = parser.parse(tokens)
    interp = interpreter.Interpreter([])
    return interp.run_tests(program)


def run_pact_file(path, capsys, argv=None):
    source = pathlib.Path(path).read_text()
    return run_pact(source, capsys, argv)


def test_println(capsys):
    out = run_pact('fn main() {\nio.println("hello")\n}', capsys)
    assert out == "hello\n"


def test_let_binding_and_interpolation(capsys):
    src = 'fn main() {\nlet x = "world"\nio.println("hello {x}")\n}'
    out = run_pact(src, capsys)
    assert out == "hello world\n"


def test_user_defined_fn(capsys):
    src = 'fn greet(name) {\nio.println("hi {name}")\n}\nfn main() {\ngreet("bob")\n}'
    out = run_pact(src, capsys)
    assert out == "hi bob\n"


def test_match_int_literal(capsys):
    src = 'fn main() {\nmatch 1 {\n1 => io.println("one")\n_ => io.println("other")\n}\n}'
    out = run_pact(src, capsys)
    assert out == "one\n"


def test_match_wildcard(capsys):
    src = 'fn main() {\nmatch 99 {\n1 => io.println("one")\n_ => io.println("other")\n}\n}'
    out = run_pact(src, capsys)
    assert out == "other\n"


def test_match_ident_binding(capsys):
    src = 'fn main() {\nmatch 42 {\nn => io.println("{n}")\n}\n}'
    out = run_pact(src, capsys)
    assert out == "42\n"


def test_match_tuple(capsys):
    src = 'fn main() {\nmatch (1, 2) {\n(1, 2) => io.println("yes")\n_ => io.println("no")\n}\n}'
    out = run_pact(src, capsys)
    assert out == "yes\n"


def test_for_in_range(capsys):
    src = 'fn main() {\nfor n in 1..4 {\nio.println("{n}")\n}\n}'
    out = run_pact(src, capsys)
    assert out == "1\n2\n3\n"


def test_modulo(capsys):
    src = 'fn main() {\nio.println("{10 % 3}")\n}'
    out = run_pact(src, capsys)
    assert out == "1\n"


def test_coalesce_default(capsys):
    src = 'fn main() {\nlet val = env.args().get(1) ?? "default"\nio.println(val)\n}'
    out = run_pact(src, capsys, argv=[])
    assert out == "default\n"


def test_e2e_hello(capsys):
    out = run_pact_file(EXAMPLES_DIR / "hello.pact", capsys)
    assert out == "Hello, world!\nWelcome to Pact.\n"


def test_e2e_fizzbuzz(capsys):
    out = run_pact_file(EXAMPLES_DIR / "fizzbuzz.pact", capsys)
    lines = out.strip().split("\n")
    expected_first_15 = [
        "1", "2", "Fizz", "4", "Buzz",
        "Fizz", "7", "8", "Fizz", "Buzz",
        "11", "Fizz", "13", "14", "FizzBuzz",
    ]
    assert lines[:15] == expected_first_15


def test_e2e_calculator(capsys):
    out = run_pact_file(EXAMPLES_DIR / "calculator.pact", capsys)
    lines = out.strip().split("\n")
    assert lines[0] == "Result: -20.0"
    assert "safe_div" in lines[1]
    assert "abs(-42) = 42" in lines[2]
    assert "clamp(150, 0, 100) = 100" in lines[3]


def test_if_expr(capsys):
    src = 'fn main() {\n    if 1 > 0 { io.println("yes")\n } else { io.println("no")\n }\n}'
    out = run_pact(src, capsys)
    assert out == "yes\n"


def test_if_no_else(capsys):
    src = 'fn main() {\n    if 1 > 2 { io.println("nope")\n }\n    io.println("done")\n}'
    out = run_pact(src, capsys)
    assert out == "done\n"


def test_float_arithmetic(capsys):
    src = 'fn main() {\n    io.println("{2.0 + 3.0}")\n}'
    out = run_pact(src, capsys)
    assert out == "5.0\n"


def test_bool_and_not(capsys):
    src = 'fn main() {\n    if !false { io.println("ok")\n }\n}'
    out = run_pact(src, capsys)
    assert out == "ok\n"


def test_comparison_ops(capsys):
    src = 'fn main() {\n    if 3 <= 3 && 4 >= 4 && 1 != 2 && 5 == 5 { io.println("all")\n }\n}'
    out = run_pact(src, capsys)
    assert out == "all\n"


def test_unary_negation(capsys):
    src = 'fn main() {\n    io.println("{-42}")\n}'
    out = run_pact(src, capsys)
    assert out == "-42\n"


def test_ok_err_result(capsys):
    src = """fn safe(x: Int) -> Result[Int, Str] {
    if x > 0 { Ok(x) } else { Err("bad") }
}
fn main() {
    match safe(1) {
        Ok(v) => io.println("{v}")
        Err(e) => io.println(e)
    }
    match safe(-1) {
        Ok(v) => io.println("{v}")
        Err(e) => io.println(e)
    }
}"""
    out = run_pact(src, capsys)
    assert out == "1\nbad\n"


def test_question_operator_ok(capsys):
    src = """fn inner() -> Result[Int, Str] {
    Ok(42)
}
fn outer() -> Result[Int, Str] {
    let x = inner()?
    Ok(x + 1)
}
fn main() {
    match outer() {
        Ok(v) => io.println("{v}")
        Err(e) => io.println(e)
    }
}"""
    out = run_pact(src, capsys)
    assert out == "43\n"


def test_question_operator_propagates_err(capsys):
    src = """fn inner() -> Result[Int, Str] {
    Err("fail")
}
fn outer() -> Result[Int, Str] {
    let x = inner()?
    Ok(x + 1)
}
fn main() {
    match outer() {
        Ok(v) => io.println("{v}")
        Err(e) => io.println(e)
    }
}"""
    out = run_pact(src, capsys)
    assert out == "fail\n"


def test_enum_construction_and_match(capsys):
    src = """type Color {
    Red
    Green
    Blue
}
fn describe(c: Color) -> Str {
    match c {
        Red => "red"
        Green => "green"
        Blue => "blue"
    }
}
fn main() {
    io.println(describe(Color.Red))
    io.println(describe(Color.Green))
}"""
    out = run_pact(src, capsys)
    assert out == "red\ngreen\n"


def test_enum_with_data_match(capsys):
    src = """type Shape {
    Circle(radius: Float)
    Rect(w: Float, h: Float)
}
fn area(s: Shape) -> Float {
    match s {
        Circle(r) => 3.14 * r * r
        Rect(w, h) => w * h
    }
}
fn main() {
    io.println("{area(Shape.Rect(3.0, 4.0))}")
}"""
    out = run_pact(src, capsys)
    assert out == "12.0\n"


def test_assignment(capsys):
    src = 'fn main() {\n    let mut x = 1\n    x = 2\n    io.println("{x}")\n}'
    out = run_pact(src, capsys)
    assert out == "2\n"


def test_return_early(capsys):
    src = """fn check(x: Int) -> Str {
    if x > 0 {
        return "positive"
    }
    "non-positive"
}
fn main() {
    io.println(check(5))
    io.println(check(-1))
}"""
    out = run_pact(src, capsys)
    assert out == "positive\nnon-positive\n"


def test_run_tests():
    src = """type Color {
    Red
    Green
}
fn main() {
    42
}
test "colors are distinct" {
    assert(true)
}
"""
    tokens = lexer.lex(src)
    program = parser.parse(tokens)
    interp = interpreter.Interpreter([])
    results = interp.run_tests(program)
    assert len(results) == 1
    assert results[0][0] == "colors are distinct"
    assert results[0][1] is True


def test_assert_eq_passes():
    src = """fn main() { 42 }
test "equality" {
    assert_eq(1, 1)
}"""
    tokens = lexer.lex(src)
    program = parser.parse(tokens)
    interp = interpreter.Interpreter([])
    results = interp.run_tests(program)
    assert results[0][1] is True


def test_assert_eq_fails():
    src = """fn main() { 42 }
test "inequality" {
    assert_eq(1, 2)
}"""
    tokens = lexer.lex(src)
    program = parser.parse(tokens)
    interp = interpreter.Interpreter([])
    results = interp.run_tests(program)
    assert results[0][1] is False


def test_struct_construction_and_field_access(capsys):
    src = """type Point {
    x: Int
    y: Int
}
fn main() {
    let p = Point { x: 3, y: 4 }
    io.println("{p.x}")
    io.println("{p.y}")
}"""
    out = run_pact(src, capsys)
    assert out == "3\n4\n"


def test_impl_method_dispatch(capsys):
    src = """type Status {
    Open
    Done
}
trait Display {
    fn display(self) -> Str
}
impl Display for Status {
    fn display(self) -> Str {
        match self {
            Open => "open"
            Done => "done"
        }
    }
}
fn main() {
    io.println(Status.Open.display())
    io.println(Status.Done.display())
}"""
    out = run_pact(src, capsys)
    assert out == "open\ndone\n"


def test_struct_impl_method(capsys):
    src = """type Foo {
    val: Int
}
trait Show {
    fn show(self) -> Str
}
impl Show for Foo {
    fn show(self) -> Str {
        "val={self.val}"
    }
}
fn main() {
    let f = Foo { val: 42 }
    io.println(f.show())
}"""
    out = run_pact(src, capsys)
    assert out == "val=42\n"


def test_closure_as_arg(capsys):
    src = """fn apply(f, x: Int) -> Int {
    f(x)
}
fn main() {
    let double = fn(x) { x * 2 }
    io.println("{apply(double, 5)}")
}"""
    out = run_pact(src, capsys)
    assert out == "10\n"


def test_list_append_and_iterate(capsys):
    src = """fn main() {
    let mut items = []
    items = items.append(1)
    items = items.append(2)
    items = items.append(3)
    for x in items {
        io.println("{x}")
    }
}"""
    out = run_pact(src, capsys)
    assert out == "1\n2\n3\n"


def test_list_map_join(capsys):
    src = """fn main() {
    let items = [1, 2, 3]
    let strs = items.map(fn(x) { "{x}!" })
    io.println(strs.join(", "))
}"""
    out = run_pact(src, capsys)
    assert out == "1!, 2!, 3!\n"


def test_option_some_none_match(capsys):
    src = """fn main() {
    let items = [10, 20]
    match items.get(0) {
        Some(v) => io.println("{v}")
        None => io.println("nope")
    }
    match items.get(5) {
        Some(v) => io.println("{v}")
        None => io.println("nope")
    }
}"""
    out = run_pact(src, capsys)
    assert out == "10\nnope\n"


def test_option_unwrap(capsys):
    src = """fn main() {
    let items = [42]
    io.println("{items.get(0).unwrap()}")
}"""
    out = run_pact(src, capsys)
    assert out == "42\n"


def test_e2e_todo(capsys):
    out = run_pact_file(EXAMPLES_DIR / "todo.pact", capsys)
    lines = out.strip().split("\n")
    assert lines[0] == "[x] Write Pact spec"
    assert lines[1] == "[ ] Build compiler"
    assert lines[2] == "[ ] Ship v1"


def test_tuple_destructuring(capsys):
    src = """fn pair() -> (Int, Int) {
    (10, 20)
}
fn main() {
    let (a, b) = pair()
    io.println("{a}")
    io.println("{b}")
}"""
    out = run_pact(src, capsys)
    assert out == "10\n20\n"


def test_named_args(capsys):
    src = """fn greet(-- name: Str, greeting: Str) -> Str {
    "{greeting}, {name}!"
}
fn main() {
    io.println(greet(name: "Alice", greeting: "Hello"))
}"""
    out = run_pact(src, capsys)
    assert out == "Hello, Alice!\n"


def test_e2e_bank(capsys):
    out = run_pact_file(EXAMPLES_DIR / "bank.pact", capsys)
    lines = out.strip().split("\n")
    assert lines[0] == "Alice: 750"
    assert lines[1] == "Bob: 250"


def test_e2e_fetch(capsys):
    out = run_pact_file(EXAMPLES_DIR / "fetch.pact", capsys)
    lines = out.strip().split("\n")
    assert "London" in lines[1]
    assert "Tokyo" in lines[3]
    assert "Portland" in lines[5]
    assert "Fetched 3 cities" in lines[6]


def test_e2e_web_api(capsys):
    out = run_pact_file(EXAMPLES_DIR / "web_api.pact", capsys)
    assert "Starting server on port 8080" in out


def test_with_handler_block(capsys):
    src = """fn main() {
    with handler IO {
        fn println(msg: Str) {
            42
        }
    }
    {
        io.println("suppressed")
    }
    io.println("visible")
}"""
    out = run_pact(src, capsys)
    assert out == "visible\n"


# --- pact-74: Closure mutable capture ---

def test_closure_mutable_capture(capsys):
    src = """fn main() {
    let mut count = 0
    let inc = fn() { count = count + 1 }
    inc()
    inc()
    inc()
    io.println("{count}")
}"""
    out = run_pact(src, capsys)
    assert out == "3\n"


def test_closure_shared_env_mutation(capsys):
    src = """fn main() {
    let mut x = 10
    let add = fn(n) { x = x + n }
    add(5)
    io.println("{x}")
}"""
    out = run_pact(src, capsys)
    assert out == "15\n"


# --- pact-85: Pipe operator |> ---

def test_pipe_operator(capsys):
    src = """fn double(x: Int) -> Int { x * 2 }
fn add_one(x: Int) -> Int { x + 1 }
fn main() {
    let result = 5 |> double |> add_one
    io.println("{result}")
}"""
    out = run_pact(src, capsys)
    assert out == "11\n"


def test_pipe_operator_chained(capsys):
    src = """fn negate(x: Int) -> Int { -x }
fn main() {
    let result = 3 |> negate
    io.println("{result}")
}"""
    out = run_pact(src, capsys)
    assert out == "-3\n"


# --- pact-84: Pattern binding with 'as' ---

def test_as_pattern(capsys):
    src = """fn main() {
    let x = 42
    match x {
        n as whole => io.println("{whole}")
    }
}"""
    out = run_pact(src, capsys)
    assert out == "42\n"


def test_as_pattern_with_enum(capsys):
    src = """fn main() {
    let x = Ok(5)
    match x {
        result as Ok(v) => io.println("{v}")
        _ => io.println("nope")
    }
}"""
    out = run_pact(src, capsys)
    assert out == "5\n"


# --- pact-88: PactMap improvements ---

def test_map_new(capsys):
    src = """fn main() {
    let m = Map.new()
    io.println("{m.len()}")
}"""
    out = run_pact(src, capsys)
    assert out == "0\n"


def test_map_insert_and_contains_key(capsys):
    src = """fn main() {
    let m = Map.new()
    let m2 = m.insert("a", 1)
    io.println("{m2.contains_key("a")}")
    io.println("{m2.contains_key("b")}")
}"""
    out = run_pact(src, capsys)
    assert out == "True\nFalse\n"


def test_map_keys_values(capsys):
    src = """fn main() {
    let pairs = [(\"x\", 1), (\"y\", 2)]
    let m = Map.of(pairs)
    io.println("{m.keys().len()}")
    io.println("{m.values().len()}")
}"""
    out = run_pact(src, capsys)
    assert out == "2\n2\n"


# --- pact-90: For-in tuple destructuring ---

def test_for_in_tuple_destructuring(capsys):
    src = """fn main() {
    let pairs = [(1, "a"), (2, "b")]
    for (num, letter) in pairs {
        io.println("{num}:{letter}")
    }
}"""
    out = run_pact(src, capsys)
    assert out == "1:a\n2:b\n"


def test_for_in_enumerate_destructuring(capsys):
    src = """fn main() {
    let items = ["x", "y", "z"]
    for (i, item) in items.enumerate() {
        io.println("{i}={item}")
    }
}"""
    out = run_pact(src, capsys)
    assert out == "0=x\n1=y\n2=z\n"


# --- pact-91: Numeric type methods ---

def test_int_to_float(capsys):
    src = """fn main() {
    let x = 42
    let f = x.to_float()
    io.println("{f}")
}"""
    out = run_pact(src, capsys)
    assert out == "42.0\n"


def test_float_to_int(capsys):
    src = """fn main() {
    let f = 3.7
    let i = f.to_int()
    io.println("{i}")
}"""
    out = run_pact(src, capsys)
    assert out == "3\n"


def test_int_abs(capsys):
    src = """fn main() {
    let x = -5
    io.println("{x.abs()}")
}"""
    out = run_pact(src, capsys)
    assert out == "5\n"


def test_int_cmp(capsys):
    src = """fn main() {
    io.println("{1.cmp(2)}")
    io.println("{2.cmp(2)}")
    io.println("{3.cmp(2)}")
}"""
    out = run_pact(src, capsys)
    assert out == "-1\n0\n1\n"


# --- pact-93: Module (mod) blocks ---

def test_mod_block(capsys):
    src = """mod math {
    fn add(a: Int, b: Int) -> Int {
        a + b
    }
}
fn main() {
    let result = math.add(3, 4)
    io.println("{result}")
}"""
    out = run_pact(src, capsys)
    assert out == "7\n"


def test_mod_multiple_functions(capsys):
    src = """mod utils {
    fn double(x: Int) -> Int { x * 2 }
    fn triple(x: Int) -> Int { x * 3 }
}
fn main() {
    io.println("{utils.double(5)}")
    io.println("{utils.triple(5)}")
}"""
    out = run_pact(src, capsys)
    assert out == "10\n15\n"


# --- pact-95: Default parameter values ---

def test_default_param(capsys):
    src = """fn greet(name: Str = "world") {
    io.println("hello {name}")
}
fn main() {
    greet()
    greet("skippy")
}"""
    out = run_pact(src, capsys)
    assert out == "hello world\nhello skippy\n"


def test_default_param_int(capsys):
    src = """fn add(a: Int, b: Int = 10) -> Int {
    a + b
}
fn main() {
    io.println("{add(5)}")
    io.println("{add(5, 20)}")
}"""
    out = run_pact(src, capsys)
    assert out == "15\n25\n"


# --- pact-96: Struct field defaults ---

def test_struct_field_default(capsys):
    src = """type Config {
    host: Str = "localhost"
    port: Int = 8080
}
fn main() {
    let c = Config {}
    io.println("{c.host}:{c.port}")
}"""
    out = run_pact(src, capsys)
    assert out == "localhost:8080\n"


def test_struct_field_default_override(capsys):
    src = """type Config {
    host: Str = "localhost"
    port: Int = 8080
}
fn main() {
    let c = Config { port: 3000 }
    io.println("{c.host}:{c.port}")
}"""
    out = run_pact(src, capsys)
    assert out == "localhost:3000\n"


# --- pact-97: Type static methods ---

def test_type_static_method(capsys):
    src = """type Point {
    x: Int
    y: Int
}
impl Ops for Point {
    fn origin() -> Point {
        Point { x: 0, y: 0 }
    }
}
fn main() {
    let p = Point.origin()
    io.println("{p.x},{p.y}")
}"""
    out = run_pact(src, capsys)
    assert out == "0,0\n"


def test_type_static_method_with_args(capsys):
    src = """type Vec2 {
    x: Int
    y: Int
}
impl Ops for Vec2 {
    fn new(x: Int, y: Int) -> Vec2 {
        Vec2 { x: x, y: y }
    }
}
fn main() {
    let v = Vec2.new(3, 4)
    io.println("{v.x},{v.y}")
}"""
    out = run_pact(src, capsys)
    assert out == "3,4\n"


def test_compound_assignment_plus(capsys):
    src = """fn main() {
    let mut x = 10
    x += 5
    io.println("{x}")
}"""
    out = run_pact(src, capsys)
    assert out == "15\n"

def test_compound_assignment_all_ops(capsys):
    src = """fn main() {
    let mut a = 10
    a += 5
    a -= 3
    a *= 2
    io.println("{a}")
}"""
    out = run_pact(src, capsys)
    assert out == "24\n"


def test_pattern_guard(capsys):
    src = """fn classify(x: Int) -> Str {
    match x {
        n if n > 0 => "positive"
        n if n < 0 => "negative"
        _ => "zero"
    }
}
fn main() {
    io.println(classify(5))
    io.println(classify(-3))
    io.println(classify(0))
}"""
    out = run_pact(src, capsys)
    assert out == "positive\nnegative\nzero\n"


def test_struct_pattern_match(capsys):
    src = """type Point {
    x: Int
    y: Int
}
fn describe(p: Point) -> Str {
    match p {
        Point { x, y } => "{x},{y}"
    }
}
fn main() {
    let p = Point { x: 3, y: 4 }
    io.println(describe(p))
}"""
    out = run_pact(src, capsys)
    assert out == "3,4\n"


def test_struct_pattern_with_rest(capsys):
    src = """type Point {
    x: Int
    y: Int
}
fn get_x(p: Point) -> Int {
    match p {
        Point { x, .. } => x
    }
}
fn main() {
    let p = Point { x: 7, y: 9 }
    io.println("{get_x(p)}")
}"""
    out = run_pact(src, capsys)
    assert out == "7\n"


# --- pact-98: Bare enum variant resolution ---

def test_bare_enum_variant(capsys):
    src = """type Color {
    Red
    Green
    Blue
}
fn main() {
    let c = Red
    match c {
        Red => io.println("red")
        _ => io.println("other")
    }
}"""
    out = run_pact(src, capsys)
    assert out == "red\n"

def test_bare_enum_variant_in_match(capsys):
    src = """type Dir {
    Up
    Down
}
fn show(d: Dir) -> Str {
    match d {
        Up => "up"
        Down => "down"
    }
}
fn main() {
    io.println(show(Up))
}"""
    out = run_pact(src, capsys)
    assert out == "up\n"


# --- pact-99: @derive Display ---

def test_derive_display_struct(capsys):
    src = """@derive(Display)
type Point {
    x: Int
    y: Int
}
fn main() {
    let p = Point { x: 1, y: 2 }
    io.println(p.display())
}"""
    out = run_pact(src, capsys)
    assert "1" in out
    assert "2" in out


def test_derive_display_enum(capsys):
    src = """@derive(Display)
type Color {
    Red
    Green
}
fn main() {
    io.println(Color.Red.display())
}"""
    out = run_pact(src, capsys)
    assert "Red" in out


# --- pact-100: prop_check ---

def test_prop_check_basic():
    src = """fn main() { 42 }
test "addition is commutative" {
    prop_check(fn(a: Int, b: Int) {
        assert_eq(a + b, b + a)
    })
}"""
    results = run_pact_tests(src)
    assert results[0][1] is True


def test_prop_check_with_count():
    src = """fn main() { 42 }
test "positive abs" {
    prop_check(fn(x: Int) {
        assert(x.abs() >= 0)
    }, 50)
}"""
    results = run_pact_tests(src)
    assert results[0][1] is True


# --- pact-101: @deprecated warnings ---

def test_deprecated_warning(capsys):
    src = """@deprecated
fn old_fn() -> Int { 42 }
fn main() {
    io.println("{old_fn()}")
}"""
    tokens = lexer.lex(src)
    program = parser.parse(tokens)
    interp = interpreter.Interpreter([])
    interp.run(program)
    captured = capsys.readouterr()
    assert captured.out == "42\n"
    assert "WARNING" in captured.err or "deprecated" in captured.err.lower()
