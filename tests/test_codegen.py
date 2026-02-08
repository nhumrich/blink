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
