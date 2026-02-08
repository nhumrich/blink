import pact.lexer as lexer
import pact.parser as parser
import pact.codegen as codegen


def gen_c(source):
    tokens = lexer.lex(source)
    program = parser.parse(tokens)
    gen = codegen.CCodeGen()
    return gen.generate(program)


def test_match_on_struct_field_access_int():
    source = '''
type Token {
    kind: Int
    value: Str
}

fn token_name(t: Token) -> Str {
    match t.kind {
        0 => "FN"
        1 => "LET"
        2 => "IDENT"
        _ => "UNKNOWN"
    }
}

fn main() {
    let t = Token { kind: 2, value: "foo" }
    io.println(token_name(t))
}
'''
    c_code = gen_c(source)

    assert 'pact_Token t' in c_code
    assert 'void t' not in c_code

    assert '(t.kind == 0)' in c_code
    assert '(t.kind == 1)' in c_code
    assert '(t.kind == 2)' in c_code
    assert '} else {' in c_code

    assert 'typedef struct {' in c_code
    assert 'int64_t kind;' in c_code
    assert 'const char* value;' in c_code
    assert '} pact_Token;' in c_code

    assert 'pact_Token _s0 = { .kind = 2, .value = "foo" };' in c_code


def test_struct_param_in_fn_decl_and_def():
    source = '''
type Point {
    x: Int
    y: Int
}

fn sum_point(p: Point) -> Int {
    p.x
}

fn main() {
    let p = Point { x: 1, y: 2 }
    io.println(sum_point(p))
}
'''
    c_code = gen_c(source)
    assert 'pact_Point p' in c_code
    assert 'int64_t pact_sum_point(pact_Point p);' in c_code
    assert 'int64_t pact_sum_point(pact_Point p) {' in c_code
    assert 'pact_sum_point(void p)' not in c_code


def test_enum_typedef_emitted():
    source = '''
type Color { Red, Green, Blue }

fn main() {
    let c = Color.Red
    io.println(0)
}
'''
    c_code = gen_c(source)
    assert 'typedef enum { pact_Color_Red, pact_Color_Green, pact_Color_Blue } pact_Color;' in c_code
    assert 'pact_Color_Red' in c_code


def test_enum_field_access():
    source = '''
type Color { Red, Green, Blue }

fn main() {
    let c = Color.Blue
    io.println(0)
}
'''
    c_code = gen_c(source)
    assert 'pact_Color c = pact_Color_Blue;' in c_code


def test_enum_param_type():
    source = '''
type Color { Red, Green, Blue }

fn show(c: Color) -> Int {
    0
}

fn main() {
    show(Color.Red)
}
'''
    c_code = gen_c(source)
    assert 'int64_t pact_show(pact_Color c);' in c_code
    assert 'int64_t pact_show(pact_Color c) {' in c_code


def test_enum_match_pattern():
    source = '''
type Color { Red, Green, Blue }

fn color_name(c: Color) -> Str {
    match c {
        Red => "red"
        Green => "green"
        Blue => "blue"
    }
}

fn main() {
    let c = Color.Red
    io.println(color_name(c))
}
'''
    c_code = gen_c(source)
    assert '(c == pact_Color_Red)' in c_code
    assert '(c == pact_Color_Green)' in c_code
    assert '(c == pact_Color_Blue)' in c_code
    assert 'const char* pact_color_name(pact_Color c);' in c_code
