// pactc_amalg.pact — Amalgamated self-hosting Pact compiler
//
// Auto-generated: tokens.pact + ast.pact + lexer.pact + parser.pact + codegen.pact + compiler.pact
// Duplicates removed. Only compiler.pact main() kept.

// === tokens.pact ===

// tokens.pact — Token type definitions for the self-hosting compiler
//
// Tagged-int approach: no enums in the C backend yet, so token kinds
// are plain Int constants. Ugly but bootstrappable.

// -- Keywords --
let TK_FN = 0
let TK_LET = 1
let TK_MUT = 2
let TK_TYPE = 3
let TK_TRAIT = 4
let TK_IMPL = 5
let TK_IF = 6
let TK_ELSE = 7
let TK_MATCH = 8
let TK_FOR = 9
let TK_IN = 10
let TK_WHILE = 11
let TK_LOOP = 12
let TK_BREAK = 13
let TK_CONTINUE = 14
let TK_RETURN = 15
let TK_PUB = 16
let TK_WITH = 17
let TK_HANDLER = 18
let TK_SELF = 19
let TK_TEST = 20
let TK_IMPORT = 21
let TK_AS = 22
let TK_MOD = 23

// -- Assertions --
let TK_ASSERT = 24
let TK_ASSERT_EQ = 25
let TK_ASSERT_NE = 26

// -- Literals and identifiers --
let TK_IDENT = 30
let TK_INT = 31
let TK_FLOAT = 32

// -- String interpolation tokens --
let TK_STRING_START = 33
let TK_STRING_END = 34
let TK_STRING_PART = 35
let TK_INTERP_START = 36
let TK_INTERP_END = 37

// -- Delimiters --
let TK_LPAREN = 40
let TK_RPAREN = 41
let TK_LBRACE = 42
let TK_RBRACE = 43
let TK_LBRACKET = 44
let TK_RBRACKET = 45

// -- Punctuation --
let TK_COLON = 50
let TK_COMMA = 51
let TK_DOT = 52
let TK_DOTDOT = 53
let TK_DOTDOTEQ = 54
let TK_ARROW = 55
let TK_FAT_ARROW = 56
let TK_AT = 57

// -- Operators --
let TK_PLUS = 60
let TK_MINUS = 61
let TK_STAR = 62
let TK_SLASH = 63
let TK_PERCENT = 64
let TK_EQUALS = 65
let TK_EQEQ = 66
let TK_NOT_EQ = 67
let TK_LESS = 68
let TK_GREATER = 69
let TK_LESS_EQ = 70
let TK_GREATER_EQ = 71
let TK_AND = 72
let TK_OR = 73
let TK_BANG = 74
let TK_QUESTION = 75
let TK_DOUBLE_QUESTION = 76
let TK_PIPE = 77
let TK_PIPE_ARROW = 78

// -- Compound assignment --
let TK_PLUS_EQ = 80
let TK_MINUS_EQ = 81
let TK_STAR_EQ = 82
let TK_SLASH_EQ = 83

// -- Structural --
let TK_NEWLINE = 90
let TK_EOF = 91

type Token {
    kind: Int
    value: Str
    line: Int
    col: Int
}

// Helper: create a token
fn make_token(kind: Int, value: Str, line: Int, col: Int) -> Token {
    Token { kind: kind, value: value, line: line, col: col }
}

// Helper: human-readable name for a token kind (for error messages)
fn token_kind_name(kind: Int) -> Str {
    if kind == TK_FN { "fn" }
    else if kind == TK_LET { "let" }
    else if kind == TK_MUT { "mut" }
    else if kind == TK_TYPE { "type" }
    else if kind == TK_TRAIT { "trait" }
    else if kind == TK_IMPL { "impl" }
    else if kind == TK_IF { "if" }
    else if kind == TK_ELSE { "else" }
    else if kind == TK_MATCH { "match" }
    else if kind == TK_FOR { "for" }
    else if kind == TK_IN { "in" }
    else if kind == TK_WHILE { "while" }
    else if kind == TK_LOOP { "loop" }
    else if kind == TK_BREAK { "break" }
    else if kind == TK_CONTINUE { "continue" }
    else if kind == TK_RETURN { "return" }
    else if kind == TK_PUB { "pub" }
    else if kind == TK_WITH { "with" }
    else if kind == TK_HANDLER { "handler" }
    else if kind == TK_SELF { "self" }
    else if kind == TK_TEST { "test" }
    else if kind == TK_IMPORT { "import" }
    else if kind == TK_AS { "as" }
    else if kind == TK_MOD { "mod" }
    else if kind == TK_ASSERT { "assert" }
    else if kind == TK_ASSERT_EQ { "assert_eq" }
    else if kind == TK_ASSERT_NE { "assert_ne" }
    else if kind == TK_IDENT { "IDENT" }
    else if kind == TK_INT { "INT" }
    else if kind == TK_FLOAT { "FLOAT" }
    else if kind == TK_STRING_START { "STRING_START" }
    else if kind == TK_STRING_END { "STRING_END" }
    else if kind == TK_STRING_PART { "STRING_PART" }
    else if kind == TK_INTERP_START { "INTERP_START" }
    else if kind == TK_INTERP_END { "INTERP_END" }
    else if kind == TK_LPAREN { "(" }
    else if kind == TK_RPAREN { ")" }
    else if kind == TK_LBRACE { "\{" }
    else if kind == TK_RBRACE { "\}" }
    else if kind == TK_LBRACKET { "[" }
    else if kind == TK_RBRACKET { "]" }
    else if kind == TK_COLON { ":" }
    else if kind == TK_COMMA { "," }
    else if kind == TK_DOT { "." }
    else if kind == TK_DOTDOT { ".." }
    else if kind == TK_DOTDOTEQ { "..=" }
    else if kind == TK_ARROW { "->" }
    else if kind == TK_FAT_ARROW { "=>" }
    else if kind == TK_AT { "@" }
    else if kind == TK_PLUS { "+" }
    else if kind == TK_MINUS { "-" }
    else if kind == TK_STAR { "*" }
    else if kind == TK_SLASH { "/" }
    else if kind == TK_PERCENT { "%" }
    else if kind == TK_EQUALS { "=" }
    else if kind == TK_EQEQ { "==" }
    else if kind == TK_NOT_EQ { "!=" }
    else if kind == TK_LESS { "<" }
    else if kind == TK_GREATER { ">" }
    else if kind == TK_LESS_EQ { "<=" }
    else if kind == TK_GREATER_EQ { ">=" }
    else if kind == TK_AND { "&&" }
    else if kind == TK_OR { "||" }
    else if kind == TK_BANG { "!" }
    else if kind == TK_QUESTION { "?" }
    else if kind == TK_DOUBLE_QUESTION { "??" }
    else if kind == TK_PIPE { "|" }
    else if kind == TK_PIPE_ARROW { "|>" }
    else if kind == TK_PLUS_EQ { "+=" }
    else if kind == TK_MINUS_EQ { "-=" }
    else if kind == TK_STAR_EQ { "*=" }
    else if kind == TK_SLASH_EQ { "/=" }
    else if kind == TK_NEWLINE { "NEWLINE" }
    else if kind == TK_EOF { "EOF" }
    else { "UNKNOWN" }
}

// Helper: check if a token kind is a keyword
fn is_keyword(kind: Int) -> Int {
    kind >= TK_FN && kind <= TK_MOD
}

// Helper: look up a keyword from its string value, returns TK_IDENT if not a keyword
fn keyword_lookup(name: Str) -> Int {
    if name == "fn" { TK_FN }
    else if name == "let" { TK_LET }
    else if name == "mut" { TK_MUT }
    else if name == "type" { TK_TYPE }
    else if name == "trait" { TK_TRAIT }
    else if name == "impl" { TK_IMPL }
    else if name == "if" { TK_IF }
    else if name == "else" { TK_ELSE }
    else if name == "match" { TK_MATCH }
    else if name == "for" { TK_FOR }
    else if name == "in" { TK_IN }
    else if name == "while" { TK_WHILE }
    else if name == "loop" { TK_LOOP }
    else if name == "break" { TK_BREAK }
    else if name == "continue" { TK_CONTINUE }
    else if name == "return" { TK_RETURN }
    else if name == "pub" { TK_PUB }
    else if name == "with" { TK_WITH }
    else if name == "handler" { TK_HANDLER }
    else if name == "self" { TK_SELF }
    else if name == "test" { TK_TEST }
    else if name == "import" { TK_IMPORT }
    else if name == "as" { TK_AS }
    else if name == "mod" { TK_MOD }
    else if name == "assert" { TK_ASSERT }
    else if name == "assert_eq" { TK_ASSERT_EQ }
    else if name == "assert_ne" { TK_ASSERT_NE }
    else { TK_IDENT }
}

// === ast.pact ===

// ast.pact — AST node definitions for the self-hosting compiler
//
// Fat-node approach: a single Node struct carries fields for every
// possible node kind. Only the fields relevant to a given kind are
// meaningful; the rest are zero/empty. Ugly but bootstrappable —
// no enums or tagged unions in the C backend yet.

// -- Expression node kinds --
let ND_INT_LIT = 0
let ND_FLOAT_LIT = 1
let ND_IDENT = 2
let ND_CALL = 3
let ND_METHOD_CALL = 4
let ND_BIN_OP = 5
let ND_UNARY_OP = 6
let ND_INTERP_STRING = 7
let ND_BOOL_LIT = 8
let ND_TUPLE_LIT = 9
let ND_LIST_LIT = 10
let ND_STRUCT_LIT = 11
let ND_FIELD_ACCESS = 12
let ND_INDEX_EXPR = 13
let ND_RANGE_LIT = 14
let ND_IF_EXPR = 15
let ND_MATCH_EXPR = 16
let ND_CLOSURE = 17

// -- Statement node kinds --
let ND_LET_BINDING = 20
let ND_EXPR_STMT = 21
let ND_ASSIGNMENT = 22
let ND_COMPOUND_ASSIGN = 23
let ND_RETURN = 24
let ND_FOR_IN = 25
let ND_WHILE_LOOP = 26
let ND_LOOP_EXPR = 27
let ND_BREAK = 28
let ND_CONTINUE = 29

// -- Block / structural kinds --
let ND_BLOCK = 35
let ND_FN_DEF = 36
let ND_PARAM = 37
let ND_PROGRAM = 38

// -- Type definition kinds --
let ND_TYPE_DEF = 40
let ND_TYPE_FIELD = 41
let ND_TYPE_VARIANT = 42
let ND_TRAIT_DEF = 43
let ND_IMPL_BLOCK = 44
let ND_TEST_BLOCK = 45

// -- Pattern kinds --
let ND_INT_PATTERN = 50
let ND_WILDCARD_PATTERN = 51
let ND_IDENT_PATTERN = 52
let ND_TUPLE_PATTERN = 53
let ND_STRING_PATTERN = 54
let ND_OR_PATTERN = 55
let ND_RANGE_PATTERN = 56
let ND_STRUCT_PATTERN = 57
let ND_ENUM_PATTERN = 58
let ND_AS_PATTERN = 59
let ND_MATCH_ARM = 60

// -- Struct literal field --
let ND_STRUCT_LIT_FIELD = 61

// -- With / handler / annotation --
let ND_WITH_BLOCK = 65
let ND_HANDLER_EXPR = 66
let ND_ANNOTATION = 67

// -- Module system --
let ND_MOD_BLOCK = 70
let ND_IMPORT_STMT = 71

// -- Type annotation --
let ND_TYPE_ANN = 75

// The fat node. Every field lives here. Only the fields relevant
// to a given `kind` are meaningful; the rest hold default values.
//
// This is not pretty. It's the minimum viable representation that
// the C backend can compile today. Once the backend gains tagged
// unions or proper enum support, this gets replaced.
type Node {
    kind: Int

    // Literal values
    int_val: Int
    float_val: Int       // stored as int bits until C backend gets Float
    str_val: Str

    // Names (fn name, type name, variable name, field name, method name)
    name: Str

    // Binary / unary ops
    op: Str
    left: Node
    right: Node

    // Fn def / call / closure
    params: List[Node]
    body: Node
    return_type: Str

    // Block
    stmts: List[Node]

    // If / while
    condition: Node
    then_body: Node
    else_body: Node

    // Match
    arms: List[Node]
    pattern: Node
    scrutinee: Node
    guard: Node

    // Tuple / list / struct literal elements
    elements: List[Node]
    fields: List[Node]
    type_name: Str

    // Let binding / assignment
    is_mut: Int
    is_pub: Int
    value: Node
    target: Node

    // For-in
    iterable: Node
    var_name: Str

    // Range
    inclusive: Int
    start: Node
    end: Node

    // Field access / method call / index
    obj: Node
    method: Str
    index: Node
    args: List[Node]

    // Import
    path: Str
    names: List[Node]

    // Type annotation (generic params)
    type_params: List[Node]
    optional: Int

    // With block
    handlers: List[Node]
    as_binding: Str

    // Trait / impl
    super_traits: List[Node]
    trait_name: Str
    methods: List[Node]

    // Annotation
    ann_args: List[Node]

    // Struct pattern
    rest: Int

    // Enum pattern
    variant: Str
    enum_fields: List[Node]

    // Or pattern
    alternatives: List[Node]

    // As pattern
    inner: Node

    // Effects
    effects: List[Node]

    // Annotations list (on fn defs, type defs)
    annotations: List[Node]
}

// Helper: human-readable name for a node kind (for debugging)
fn node_kind_name(kind: Int) -> Str {
    if kind == ND_INT_LIT { "IntLit" }
    else if kind == ND_FLOAT_LIT { "FloatLit" }
    else if kind == ND_IDENT { "Ident" }
    else if kind == ND_CALL { "Call" }
    else if kind == ND_METHOD_CALL { "MethodCall" }
    else if kind == ND_BIN_OP { "BinOp" }
    else if kind == ND_UNARY_OP { "UnaryOp" }
    else if kind == ND_INTERP_STRING { "InterpString" }
    else if kind == ND_BOOL_LIT { "BoolLit" }
    else if kind == ND_TUPLE_LIT { "TupleLit" }
    else if kind == ND_LIST_LIT { "ListLit" }
    else if kind == ND_STRUCT_LIT { "StructLit" }
    else if kind == ND_FIELD_ACCESS { "FieldAccess" }
    else if kind == ND_INDEX_EXPR { "IndexExpr" }
    else if kind == ND_RANGE_LIT { "RangeLit" }
    else if kind == ND_IF_EXPR { "IfExpr" }
    else if kind == ND_MATCH_EXPR { "MatchExpr" }
    else if kind == ND_CLOSURE { "Closure" }
    else if kind == ND_LET_BINDING { "LetBinding" }
    else if kind == ND_EXPR_STMT { "ExprStmt" }
    else if kind == ND_ASSIGNMENT { "Assignment" }
    else if kind == ND_COMPOUND_ASSIGN { "CompoundAssign" }
    else if kind == ND_RETURN { "Return" }
    else if kind == ND_FOR_IN { "ForIn" }
    else if kind == ND_WHILE_LOOP { "WhileLoop" }
    else if kind == ND_LOOP_EXPR { "LoopExpr" }
    else if kind == ND_BREAK { "Break" }
    else if kind == ND_CONTINUE { "Continue" }
    else if kind == ND_BLOCK { "Block" }
    else if kind == ND_FN_DEF { "FnDef" }
    else if kind == ND_PARAM { "Param" }
    else if kind == ND_PROGRAM { "Program" }
    else if kind == ND_TYPE_DEF { "TypeDef" }
    else if kind == ND_TYPE_FIELD { "TypeField" }
    else if kind == ND_TYPE_VARIANT { "TypeVariant" }
    else if kind == ND_TRAIT_DEF { "TraitDef" }
    else if kind == ND_IMPL_BLOCK { "ImplBlock" }
    else if kind == ND_TEST_BLOCK { "TestBlock" }
    else if kind == ND_INT_PATTERN { "IntPattern" }
    else if kind == ND_WILDCARD_PATTERN { "WildcardPattern" }
    else if kind == ND_IDENT_PATTERN { "IdentPattern" }
    else if kind == ND_TUPLE_PATTERN { "TuplePattern" }
    else if kind == ND_STRING_PATTERN { "StringPattern" }
    else if kind == ND_OR_PATTERN { "OrPattern" }
    else if kind == ND_RANGE_PATTERN { "RangePattern" }
    else if kind == ND_STRUCT_PATTERN { "StructPattern" }
    else if kind == ND_ENUM_PATTERN { "EnumPattern" }
    else if kind == ND_AS_PATTERN { "AsPattern" }
    else if kind == ND_MATCH_ARM { "MatchArm" }
    else if kind == ND_STRUCT_LIT_FIELD { "StructLitField" }
    else if kind == ND_WITH_BLOCK { "WithBlock" }
    else if kind == ND_HANDLER_EXPR { "HandlerExpr" }
    else if kind == ND_ANNOTATION { "Annotation" }
    else if kind == ND_MOD_BLOCK { "ModBlock" }
    else if kind == ND_IMPORT_STMT { "ImportStmt" }
    else if kind == ND_TYPE_ANN { "TypeAnn" }
    else { "Unknown" }
}

// === lexer.pact ===

// lexer.pact — Self-hosting lexer for Pact, ported from Python
//
// Demonstrates: parallel arrays (workaround for no struct-in-list),
//               char_at / ASCII arithmetic, string interpolation scanning,
//               mode-stack-based string/normal interleaving.
//
// Constraints: C backend cannot store structs in List, so token output
// is 4 parallel lists (kinds, values, lines, cols). Mode stack is also
// parallel lists instead of tuples.

// ── Mode constants ───────────────────────────────────────────────────
let MODE_NORMAL = 0
let MODE_STRING = 1

// ── ASCII constants ──────────────────────────────────────────────────
let CH_TAB = 9
let CH_NEWLINE = 10
let CH_SPACE = 32
let CH_DQUOTE = 34
let CH_PERCENT = 37
let CH_LPAREN = 40
let CH_RPAREN = 41
let CH_STAR = 42
let CH_PLUS = 43
let CH_COMMA = 44
let CH_MINUS = 45
let CH_DOT = 46
let CH_SLASH = 47
let CH_0 = 48
let CH_9 = 57
let CH_COLON = 58
let CH_LESS = 60
let CH_EQUALS = 61
let CH_GREATER = 62
let CH_QUESTION = 63
let CH_AT = 64
let CH_A = 65
let CH_Z = 90
let CH_LBRACKET = 91
let CH_BACKSLASH = 92
let CH_RBRACKET = 93
let CH_UNDERSCORE = 95
let CH_a = 97
let CH_n = 110
let CH_t = 116
let CH_Z_LOWER = 122
let CH_LBRACE = 123
let CH_PIPE = 124
let CH_RBRACE = 125
let CH_BANG = 33
let CH_AMP = 38

// ── Character classification ─────────────────────────────────────────

fn is_alpha(c: Int) -> Int {
    (c >= CH_A && c <= CH_Z) || (c >= CH_a && c <= CH_Z_LOWER) || c == CH_UNDERSCORE
}

fn is_digit(c: Int) -> Int {
    c >= CH_0 && c <= CH_9
}

fn is_alnum(c: Int) -> Int {
    is_alpha(c) || is_digit(c)
}

fn is_whitespace(c: Int) -> Int {
    c == CH_SPACE || c == CH_TAB
}

// ── Peek helpers ─────────────────────────────────────────────────────

fn peek(source: Str, pos: Int) -> Int {
    if pos >= source.len() {
        0
    } else {
        source.char_at(pos)
    }
}

fn peek_at(source: Str, pos: Int, offset: Int) -> Int {
    peek(source, pos + offset)
}

// ── Keyword lookup ───────────────────────────────────────────────────

fn keyword_lookup(name: Str) -> Int {
    if name == "fn" { TK_FN }
    else if name == "let" { TK_LET }
    else if name == "mut" { TK_MUT }
    else if name == "type" { TK_TYPE }
    else if name == "trait" { TK_TRAIT }
    else if name == "impl" { TK_IMPL }
    else if name == "if" { TK_IF }
    else if name == "else" { TK_ELSE }
    else if name == "match" { TK_MATCH }
    else if name == "for" { TK_FOR }
    else if name == "in" { TK_IN }
    else if name == "while" { TK_WHILE }
    else if name == "loop" { TK_LOOP }
    else if name == "break" { TK_BREAK }
    else if name == "continue" { TK_CONTINUE }
    else if name == "return" { TK_RETURN }
    else if name == "pub" { TK_PUB }
    else if name == "with" { TK_WITH }
    else if name == "handler" { TK_HANDLER }
    else if name == "self" { TK_SELF }
    else if name == "test" { TK_TEST }
    else if name == "import" { TK_IMPORT }
    else if name == "as" { TK_AS }
    else if name == "mod" { TK_MOD }
    else if name == "assert" { TK_ASSERT }
    else if name == "assert_eq" { TK_ASSERT_EQ }
    else if name == "assert_ne" { TK_ASSERT_NE }
    else { TK_IDENT }
}

// ── Token kind name (for debug output) ───────────────────────────────

fn token_kind_name(kind: Int) -> Str {
    if kind == TK_FN { "FN" }
    else if kind == TK_LET { "LET" }
    else if kind == TK_MUT { "MUT" }
    else if kind == TK_TYPE { "TYPE" }
    else if kind == TK_TRAIT { "TRAIT" }
    else if kind == TK_IMPL { "IMPL" }
    else if kind == TK_IF { "IF" }
    else if kind == TK_ELSE { "ELSE" }
    else if kind == TK_MATCH { "MATCH" }
    else if kind == TK_FOR { "FOR" }
    else if kind == TK_IN { "IN" }
    else if kind == TK_WHILE { "WHILE" }
    else if kind == TK_LOOP { "LOOP" }
    else if kind == TK_BREAK { "BREAK" }
    else if kind == TK_CONTINUE { "CONTINUE" }
    else if kind == TK_RETURN { "RETURN" }
    else if kind == TK_PUB { "PUB" }
    else if kind == TK_WITH { "WITH" }
    else if kind == TK_HANDLER { "HANDLER" }
    else if kind == TK_SELF { "SELF" }
    else if kind == TK_TEST { "TEST" }
    else if kind == TK_IMPORT { "IMPORT" }
    else if kind == TK_AS { "AS" }
    else if kind == TK_MOD { "MOD" }
    else if kind == TK_ASSERT { "ASSERT" }
    else if kind == TK_ASSERT_EQ { "ASSERT_EQ" }
    else if kind == TK_ASSERT_NE { "ASSERT_NE" }
    else if kind == TK_IDENT { "IDENT" }
    else if kind == TK_INT { "INT" }
    else if kind == TK_FLOAT { "FLOAT" }
    else if kind == TK_STRING_START { "STRING_START" }
    else if kind == TK_STRING_END { "STRING_END" }
    else if kind == TK_STRING_PART { "STRING_PART" }
    else if kind == TK_INTERP_START { "INTERP_START" }
    else if kind == TK_INTERP_END { "INTERP_END" }
    else if kind == TK_LPAREN { "LPAREN" }
    else if kind == TK_RPAREN { "RPAREN" }
    else if kind == TK_LBRACE { "LBRACE" }
    else if kind == TK_RBRACE { "RBRACE" }
    else if kind == TK_LBRACKET { "LBRACKET" }
    else if kind == TK_RBRACKET { "RBRACKET" }
    else if kind == TK_COLON { "COLON" }
    else if kind == TK_COMMA { "COMMA" }
    else if kind == TK_DOT { "DOT" }
    else if kind == TK_DOTDOT { "DOTDOT" }
    else if kind == TK_DOTDOTEQ { "DOTDOTEQ" }
    else if kind == TK_ARROW { "ARROW" }
    else if kind == TK_FAT_ARROW { "FAT_ARROW" }
    else if kind == TK_AT { "AT" }
    else if kind == TK_PLUS { "PLUS" }
    else if kind == TK_MINUS { "MINUS" }
    else if kind == TK_STAR { "STAR" }
    else if kind == TK_SLASH { "SLASH" }
    else if kind == TK_PERCENT { "PERCENT" }
    else if kind == TK_EQUALS { "EQUALS" }
    else if kind == TK_EQEQ { "EQEQ" }
    else if kind == TK_NOT_EQ { "NOT_EQ" }
    else if kind == TK_LESS { "LESS" }
    else if kind == TK_GREATER { "GREATER" }
    else if kind == TK_LESS_EQ { "LESS_EQ" }
    else if kind == TK_GREATER_EQ { "GREATER_EQ" }
    else if kind == TK_AND { "AND" }
    else if kind == TK_OR { "OR" }
    else if kind == TK_BANG { "BANG" }
    else if kind == TK_QUESTION { "QUESTION" }
    else if kind == TK_DOUBLE_QUESTION { "DOUBLE_QUESTION" }
    else if kind == TK_PIPE { "PIPE" }
    else if kind == TK_PIPE_ARROW { "PIPE_ARROW" }
    else if kind == TK_PLUS_EQ { "PLUS_EQ" }
    else if kind == TK_MINUS_EQ { "MINUS_EQ" }
    else if kind == TK_STAR_EQ { "STAR_EQ" }
    else if kind == TK_SLASH_EQ { "SLASH_EQ" }
    else if kind == TK_NEWLINE { "NEWLINE" }
    else if kind == TK_EOF { "EOF" }
    else { "UNKNOWN" }
}

// ── Lexer output: module-level globals ────────────────────────────────
// Shared with parser and codegen via imports.

let mut tok_kinds: List[Int] = []
let mut tok_values: List[Str] = []
let mut tok_lines: List[Int] = []
let mut tok_cols: List[Int] = []

// ── Main lexer ───────────────────────────────────────────────────────

fn lex(source: Str) {
    // Reset output arrays
    tok_kinds = []
    tok_values = []
    tok_lines = []
    tok_cols = []

    // Scanner state
    let mut pos = 0
    let mut line = 1
    let mut col = 1

    // Mode stack (parallel lists). Starts with one normal-mode entry.
    let mut mode_stack: List[Int] = []
    let mut brace_depth_stack: List[Int] = []
    mode_stack.push(MODE_NORMAL)
    brace_depth_stack.push(0)

    // String buffer for MODE_STRING
    let mut string_buf: Str = ""

    // Last emitted token kind (-1 means none)
    let mut last_kind = -1

    // ── emit: push a token to all 4 output lists ──────────────────
    // Inlined as a block since we can't capture mut locals in closures.
    // We use a helper pattern: just push inline everywhere.
    // (Ugly, but the C backend doesn't support closures that capture.)

    // ── Main loop ─────────────────────────────────────────────────
    while pos < source.len() {
        let mode = mode_stack.get(mode_stack.len() - 1)

        if mode == MODE_NORMAL {
            // ── NORMAL MODE ───────────────────────────────────────
            let brace_depth = brace_depth_stack.get(brace_depth_stack.len() - 1)
            let ch = peek(source, pos)

            // Skip whitespace (not newline)
            if is_whitespace(ch) {
                pos = pos + 1
                col = col + 1
                continue
            }

            // Comments: //
            if ch == CH_SLASH && peek_at(source, pos, 1) == CH_SLASH {
                pos = pos + 2
                col = col + 2
                while pos < source.len() && peek(source, pos) != CH_NEWLINE {
                    pos = pos + 1
                    col = col + 1
                }
                if pos < source.len() && peek(source, pos) == CH_NEWLINE {
                    pos = pos + 1
                    line = line + 1
                    col = 1
                }
                continue
            }

            // Slash or /=
            if ch == CH_SLASH {
                let t_line = line
                let t_col = col
                pos = pos + 1
                col = col + 1
                if pos < source.len() && peek(source, pos) == CH_EQUALS {
                    pos = pos + 1
                    col = col + 1
                    tok_kinds.push(TK_SLASH_EQ)
                    tok_values.push("/=")
                    tok_lines.push(t_line)
                    tok_cols.push(t_col)
                    last_kind = TK_SLASH_EQ
                } else {
                    tok_kinds.push(TK_SLASH)
                    tok_values.push("/")
                    tok_lines.push(t_line)
                    tok_cols.push(t_col)
                    last_kind = TK_SLASH
                }
                continue
            }

            // Newline
            if ch == CH_NEWLINE {
                let t_line = line
                let t_col = col
                pos = pos + 1
                line = line + 1
                col = 1
                if last_kind != TK_NEWLINE {
                    tok_kinds.push(TK_NEWLINE)
                    tok_values.push("\\n")
                    tok_lines.push(t_line)
                    tok_cols.push(t_col)
                    last_kind = TK_NEWLINE
                }
                continue
            }

            // String start: "
            if ch == CH_DQUOTE {
                let t_line = line
                let t_col = col
                pos = pos + 1
                col = col + 1
                tok_kinds.push(TK_STRING_START)
                tok_values.push("\"")
                tok_lines.push(t_line)
                tok_cols.push(t_col)
                last_kind = TK_STRING_START
                mode_stack.push(MODE_STRING)
                brace_depth_stack.push(0)
                string_buf = ""
                continue
            }

            // Left brace
            if ch == CH_LBRACE {
                let t_line = line
                let t_col = col
                pos = pos + 1
                col = col + 1
                if brace_depth > 0 {
                    // Inside interpolation: track nested braces
                    brace_depth_stack.push(brace_depth + 1)
                    mode_stack.push(MODE_NORMAL)
                    // Replace top of stack by popping and re-pushing
                    // Actually we need to update the current entry.
                    // Since List has no set(), we pop and push.
                    let mlen = mode_stack.len()
                    // We just pushed, so undo and fix the original entry.
                    // Simpler: the brace_depth_stack top IS the one we
                    // just pushed. Pop it, pop the old, push updated old,
                    // then we don't push a new mode frame — we update in place.
                    //
                    // Let me reconsider the stack design:
                    // In Python, mode_stack[-1] = ("normal", brace_depth+1)
                    // means we UPDATE the current frame, not push a new one.
                    // So we should pop the extra push we just did, and update
                    // the existing top.
                    mode_stack.pop()
                    brace_depth_stack.pop()
                    // Now update the real top
                    brace_depth_stack.pop()
                    brace_depth_stack.push(brace_depth + 1)
                    tok_kinds.push(TK_LBRACE)
                    tok_values.push("\{")
                    tok_lines.push(t_line)
                    tok_cols.push(t_col)
                    last_kind = TK_LBRACE
                } else {
                    tok_kinds.push(TK_LBRACE)
                    tok_values.push("\{")
                    tok_lines.push(t_line)
                    tok_cols.push(t_col)
                    last_kind = TK_LBRACE
                }
                continue
            }

            // Right brace
            if ch == CH_RBRACE {
                let t_line = line
                let t_col = col
                pos = pos + 1
                col = col + 1
                if brace_depth > 1 {
                    // Nested brace inside interpolation
                    brace_depth_stack.pop()
                    brace_depth_stack.push(brace_depth - 1)
                    tok_kinds.push(TK_RBRACE)
                    tok_values.push("\}")
                    tok_lines.push(t_line)
                    tok_cols.push(t_col)
                    last_kind = TK_RBRACE
                } else if brace_depth == 1 {
                    // End of interpolation — pop back to string mode
                    mode_stack.pop()
                    brace_depth_stack.pop()
                    tok_kinds.push(TK_INTERP_END)
                    tok_values.push("\}")
                    tok_lines.push(t_line)
                    tok_cols.push(t_col)
                    last_kind = TK_INTERP_END
                    // Continue in string mode (loop will pick it up)
                } else {
                    tok_kinds.push(TK_RBRACE)
                    tok_values.push("\}")
                    tok_lines.push(t_line)
                    tok_cols.push(t_col)
                    last_kind = TK_RBRACE
                }
                continue
            }

            // Question mark: ? or ??
            if ch == CH_QUESTION {
                let t_line = line
                let t_col = col
                pos = pos + 1
                col = col + 1
                if pos < source.len() && peek(source, pos) == CH_QUESTION {
                    pos = pos + 1
                    col = col + 1
                    tok_kinds.push(TK_DOUBLE_QUESTION)
                    tok_values.push("??")
                    tok_lines.push(t_line)
                    tok_cols.push(t_col)
                    last_kind = TK_DOUBLE_QUESTION
                } else {
                    tok_kinds.push(TK_QUESTION)
                    tok_values.push("?")
                    tok_lines.push(t_line)
                    tok_cols.push(t_col)
                    last_kind = TK_QUESTION
                }
                continue
            }

            // Minus: -, ->, -=
            if ch == CH_MINUS {
                let t_line = line
                let t_col = col
                if peek_at(source, pos, 1) == CH_GREATER {
                    pos = pos + 2
                    col = col + 2
                    tok_kinds.push(TK_ARROW)
                    tok_values.push("->")
                    tok_lines.push(t_line)
                    tok_cols.push(t_col)
                    last_kind = TK_ARROW
                } else if peek_at(source, pos, 1) == CH_EQUALS {
                    pos = pos + 2
                    col = col + 2
                    tok_kinds.push(TK_MINUS_EQ)
                    tok_values.push("-=")
                    tok_lines.push(t_line)
                    tok_cols.push(t_col)
                    last_kind = TK_MINUS_EQ
                } else {
                    pos = pos + 1
                    col = col + 1
                    tok_kinds.push(TK_MINUS)
                    tok_values.push("-")
                    tok_lines.push(t_line)
                    tok_cols.push(t_col)
                    last_kind = TK_MINUS
                }
                continue
            }

            // Plus: +, +=
            if ch == CH_PLUS {
                let t_line = line
                let t_col = col
                pos = pos + 1
                col = col + 1
                if pos < source.len() && peek(source, pos) == CH_EQUALS {
                    pos = pos + 1
                    col = col + 1
                    tok_kinds.push(TK_PLUS_EQ)
                    tok_values.push("+=")
                    tok_lines.push(t_line)
                    tok_cols.push(t_col)
                    last_kind = TK_PLUS_EQ
                } else {
                    tok_kinds.push(TK_PLUS)
                    tok_values.push("+")
                    tok_lines.push(t_line)
                    tok_cols.push(t_col)
                    last_kind = TK_PLUS
                }
                continue
            }

            // Star: *, *=
            if ch == CH_STAR {
                let t_line = line
                let t_col = col
                pos = pos + 1
                col = col + 1
                if pos < source.len() && peek(source, pos) == CH_EQUALS {
                    pos = pos + 1
                    col = col + 1
                    tok_kinds.push(TK_STAR_EQ)
                    tok_values.push("*=")
                    tok_lines.push(t_line)
                    tok_cols.push(t_col)
                    last_kind = TK_STAR_EQ
                } else {
                    tok_kinds.push(TK_STAR)
                    tok_values.push("*")
                    tok_lines.push(t_line)
                    tok_cols.push(t_col)
                    last_kind = TK_STAR
                }
                continue
            }

            // Equals: =, ==, =>
            if ch == CH_EQUALS {
                let t_line = line
                let t_col = col
                pos = pos + 1
                col = col + 1
                if pos < source.len() && peek(source, pos) == CH_GREATER {
                    pos = pos + 1
                    col = col + 1
                    tok_kinds.push(TK_FAT_ARROW)
                    tok_values.push("=>")
                    tok_lines.push(t_line)
                    tok_cols.push(t_col)
                    last_kind = TK_FAT_ARROW
                } else if pos < source.len() && peek(source, pos) == CH_EQUALS {
                    pos = pos + 1
                    col = col + 1
                    tok_kinds.push(TK_EQEQ)
                    tok_values.push("==")
                    tok_lines.push(t_line)
                    tok_cols.push(t_col)
                    last_kind = TK_EQEQ
                } else {
                    tok_kinds.push(TK_EQUALS)
                    tok_values.push("=")
                    tok_lines.push(t_line)
                    tok_cols.push(t_col)
                    last_kind = TK_EQUALS
                }
                continue
            }

            // Dot: ., .., ..=
            if ch == CH_DOT && peek_at(source, pos, 1) == CH_DOT {
                let t_line = line
                let t_col = col
                pos = pos + 2
                col = col + 2
                if pos < source.len() && peek(source, pos) == CH_EQUALS {
                    pos = pos + 1
                    col = col + 1
                    tok_kinds.push(TK_DOTDOTEQ)
                    tok_values.push("..=")
                    tok_lines.push(t_line)
                    tok_cols.push(t_col)
                    last_kind = TK_DOTDOTEQ
                } else {
                    tok_kinds.push(TK_DOTDOT)
                    tok_values.push("..")
                    tok_lines.push(t_line)
                    tok_cols.push(t_col)
                    last_kind = TK_DOTDOT
                }
                continue
            }

            if ch == CH_DOT {
                let t_line = line
                let t_col = col
                pos = pos + 1
                col = col + 1
                tok_kinds.push(TK_DOT)
                tok_values.push(".")
                tok_lines.push(t_line)
                tok_cols.push(t_col)
                last_kind = TK_DOT
                continue
            }

            // Bang: !, !=
            if ch == CH_BANG {
                let t_line = line
                let t_col = col
                pos = pos + 1
                col = col + 1
                if pos < source.len() && peek(source, pos) == CH_EQUALS {
                    pos = pos + 1
                    col = col + 1
                    tok_kinds.push(TK_NOT_EQ)
                    tok_values.push("!=")
                    tok_lines.push(t_line)
                    tok_cols.push(t_col)
                    last_kind = TK_NOT_EQ
                } else {
                    tok_kinds.push(TK_BANG)
                    tok_values.push("!")
                    tok_lines.push(t_line)
                    tok_cols.push(t_col)
                    last_kind = TK_BANG
                }
                continue
            }

            // Less: <, <=
            if ch == CH_LESS {
                let t_line = line
                let t_col = col
                pos = pos + 1
                col = col + 1
                if pos < source.len() && peek(source, pos) == CH_EQUALS {
                    pos = pos + 1
                    col = col + 1
                    tok_kinds.push(TK_LESS_EQ)
                    tok_values.push("<=")
                    tok_lines.push(t_line)
                    tok_cols.push(t_col)
                    last_kind = TK_LESS_EQ
                } else {
                    tok_kinds.push(TK_LESS)
                    tok_values.push("<")
                    tok_lines.push(t_line)
                    tok_cols.push(t_col)
                    last_kind = TK_LESS
                }
                continue
            }

            // Greater: >, >=
            if ch == CH_GREATER {
                let t_line = line
                let t_col = col
                pos = pos + 1
                col = col + 1
                if pos < source.len() && peek(source, pos) == CH_EQUALS {
                    pos = pos + 1
                    col = col + 1
                    tok_kinds.push(TK_GREATER_EQ)
                    tok_values.push(">=")
                    tok_lines.push(t_line)
                    tok_cols.push(t_col)
                    last_kind = TK_GREATER_EQ
                } else {
                    tok_kinds.push(TK_GREATER)
                    tok_values.push(">")
                    tok_lines.push(t_line)
                    tok_cols.push(t_col)
                    last_kind = TK_GREATER
                }
                continue
            }

            // Ampersand: &&
            if ch == CH_AMP && peek_at(source, pos, 1) == CH_AMP {
                let t_line = line
                let t_col = col
                pos = pos + 2
                col = col + 2
                tok_kinds.push(TK_AND)
                tok_values.push("&&")
                tok_lines.push(t_line)
                tok_cols.push(t_col)
                last_kind = TK_AND
                continue
            }

            // Pipe: |, ||, |>
            if ch == CH_PIPE {
                let t_line = line
                let t_col = col
                pos = pos + 1
                col = col + 1
                if pos < source.len() && peek(source, pos) == CH_PIPE {
                    pos = pos + 1
                    col = col + 1
                    tok_kinds.push(TK_OR)
                    tok_values.push("||")
                    tok_lines.push(t_line)
                    tok_cols.push(t_col)
                    last_kind = TK_OR
                } else if pos < source.len() && peek(source, pos) == CH_GREATER {
                    pos = pos + 1
                    col = col + 1
                    tok_kinds.push(TK_PIPE_ARROW)
                    tok_values.push("|>")
                    tok_lines.push(t_line)
                    tok_cols.push(t_col)
                    last_kind = TK_PIPE_ARROW
                } else {
                    tok_kinds.push(TK_PIPE)
                    tok_values.push("|")
                    tok_lines.push(t_line)
                    tok_cols.push(t_col)
                    last_kind = TK_PIPE
                }
                continue
            }

            // Single-char tokens: ( ) : , % [ ] @
            if ch == CH_LPAREN {
                let t_line = line
                let t_col = col
                pos = pos + 1
                col = col + 1
                tok_kinds.push(TK_LPAREN)
                tok_values.push("(")
                tok_lines.push(t_line)
                tok_cols.push(t_col)
                last_kind = TK_LPAREN
                continue
            }
            if ch == CH_RPAREN {
                let t_line = line
                let t_col = col
                pos = pos + 1
                col = col + 1
                tok_kinds.push(TK_RPAREN)
                tok_values.push(")")
                tok_lines.push(t_line)
                tok_cols.push(t_col)
                last_kind = TK_RPAREN
                continue
            }
            if ch == CH_COLON {
                let t_line = line
                let t_col = col
                pos = pos + 1
                col = col + 1
                tok_kinds.push(TK_COLON)
                tok_values.push(":")
                tok_lines.push(t_line)
                tok_cols.push(t_col)
                last_kind = TK_COLON
                continue
            }
            if ch == CH_COMMA {
                let t_line = line
                let t_col = col
                pos = pos + 1
                col = col + 1
                tok_kinds.push(TK_COMMA)
                tok_values.push(",")
                tok_lines.push(t_line)
                tok_cols.push(t_col)
                last_kind = TK_COMMA
                continue
            }
            if ch == CH_PERCENT {
                let t_line = line
                let t_col = col
                pos = pos + 1
                col = col + 1
                tok_kinds.push(TK_PERCENT)
                tok_values.push("%")
                tok_lines.push(t_line)
                tok_cols.push(t_col)
                last_kind = TK_PERCENT
                continue
            }
            if ch == CH_LBRACKET {
                let t_line = line
                let t_col = col
                pos = pos + 1
                col = col + 1
                tok_kinds.push(TK_LBRACKET)
                tok_values.push("[")
                tok_lines.push(t_line)
                tok_cols.push(t_col)
                last_kind = TK_LBRACKET
                continue
            }
            if ch == CH_RBRACKET {
                let t_line = line
                let t_col = col
                pos = pos + 1
                col = col + 1
                tok_kinds.push(TK_RBRACKET)
                tok_values.push("]")
                tok_lines.push(t_line)
                tok_cols.push(t_col)
                last_kind = TK_RBRACKET
                continue
            }
            if ch == CH_AT {
                let t_line = line
                let t_col = col
                pos = pos + 1
                col = col + 1
                tok_kinds.push(TK_AT)
                tok_values.push("@")
                tok_lines.push(t_line)
                tok_cols.push(t_col)
                last_kind = TK_AT
                continue
            }

            // Identifiers and keywords
            if is_alpha(ch) {
                let t_line = line
                let t_col = col
                let start = pos
                while pos < source.len() && is_alnum(peek(source, pos)) {
                    pos = pos + 1
                    col = col + 1
                }
                let word = source.substring(start, pos - start)
                let kind = keyword_lookup(word)
                tok_kinds.push(kind)
                tok_values.push(word)
                tok_lines.push(t_line)
                tok_cols.push(t_col)
                last_kind = kind
                continue
            }

            // Integer and float literals
            if is_digit(ch) {
                let t_line = line
                let t_col = col
                let start = pos
                while pos < source.len() && is_digit(peek(source, pos)) {
                    pos = pos + 1
                    col = col + 1
                }
                if pos < source.len() && peek(source, pos) == CH_DOT && is_digit(peek_at(source, pos, 1)) {
                    pos = pos + 1
                    col = col + 1
                    while pos < source.len() && is_digit(peek(source, pos)) {
                        pos = pos + 1
                        col = col + 1
                    }
                    tok_kinds.push(TK_FLOAT)
                    tok_values.push(source.substring(start, pos - start))
                    tok_lines.push(t_line)
                    tok_cols.push(t_col)
                    last_kind = TK_FLOAT
                } else {
                    tok_kinds.push(TK_INT)
                    tok_values.push(source.substring(start, pos - start))
                    tok_lines.push(t_line)
                    tok_cols.push(t_col)
                    last_kind = TK_INT
                }
                continue
            }

            // Unknown character — skip with a warning
            // (No exceptions in the C backend)
            io.println("lexer error: unexpected character at line {line} col {col}")
            pos = pos + 1
            col = col + 1

        } else {
            // ── STRING MODE ───────────────────────────────────────
            let ch = peek(source, pos)

            // Interpolation start: {
            if ch == CH_LBRACE {
                let t_line = line
                let t_col = col
                pos = pos + 1
                col = col + 1
                tok_kinds.push(TK_STRING_PART)
                tok_values.push(string_buf)
                tok_lines.push(t_line)
                tok_cols.push(t_col)
                last_kind = TK_STRING_PART
                string_buf = ""
                tok_kinds.push(TK_INTERP_START)
                tok_values.push("\{")
                tok_lines.push(t_line)
                tok_cols.push(t_col)
                last_kind = TK_INTERP_START
                mode_stack.push(MODE_NORMAL)
                brace_depth_stack.push(1)
                continue
            }

            // String end: "
            if ch == CH_DQUOTE {
                let t_line = line
                let t_col = col
                pos = pos + 1
                col = col + 1
                tok_kinds.push(TK_STRING_PART)
                tok_values.push(string_buf)
                tok_lines.push(t_line)
                tok_cols.push(t_col)
                last_kind = TK_STRING_PART
                string_buf = ""
                tok_kinds.push(TK_STRING_END)
                tok_values.push("\"")
                tok_lines.push(t_line)
                tok_cols.push(t_col)
                last_kind = TK_STRING_END
                mode_stack.pop()
                brace_depth_stack.pop()
                continue
            }

            // Escape sequences
            if ch == CH_BACKSLASH {
                pos = pos + 1
                col = col + 1
                if pos >= source.len() {
                    io.println("lexer error: unexpected end of string after backslash")
                    continue
                }
                let esc = peek(source, pos)
                pos = pos + 1
                col = col + 1
                if esc == CH_n {
                    string_buf = string_buf.concat("\n")
                } else if esc == CH_t {
                    string_buf = string_buf.concat("\t")
                } else if esc == CH_BACKSLASH {
                    string_buf = string_buf.concat("\\")
                } else if esc == CH_DQUOTE {
                    string_buf = string_buf.concat("\"")
                } else if esc == CH_LBRACE {
                    string_buf = string_buf.concat("\{")
                } else {
                    // Unknown escape — keep as-is
                    string_buf = string_buf.concat("\\")
                    // Can't easily append a char-as-int to a string in
                    // the C backend. For bootstrap, just drop unknown escapes.
                }
                continue
            }

            // Regular character — append to buffer
            // char_at returns int; substring(pos, 1) gets the char as string
            string_buf = string_buf.concat(source.substring(pos, 1))
            pos = pos + 1
            if ch == CH_NEWLINE {
                line = line + 1
                col = 1
            } else {
                col = col + 1
            }
        }
    }

    // Emit EOF
    tok_kinds.push(TK_EOF)
    tok_values.push("")
    tok_lines.push(line)
    tok_cols.push(col)
}


// === parser.pact ===

// parser.pact — Self-hosting recursive descent parser for Pact
//
// Port of src/pact/parser.py. Uses parallel-array node pool since
// the C backend can't store structs in List. Token input arrives as
// parallel arrays (from the lexer). AST output is a node pool: one
// set of parallel arrays indexed by node ID.

// ── Node pool (parallel arrays) ─────────────────────────────────────
// Each node is an index into these arrays. -1 means "no node".

let mut np_kind: List[Int] = []
let mut np_int_val: List[Int] = []
let mut np_str_val: List[Str] = []
let mut np_name: List[Str] = []
let mut np_op: List[Str] = []
let mut np_left: List[Int] = []
let mut np_right: List[Int] = []
let mut np_body: List[Int] = []
let mut np_condition: List[Int] = []
let mut np_then_body: List[Int] = []
let mut np_else_body: List[Int] = []
let mut np_scrutinee: List[Int] = []
let mut np_pattern: List[Int] = []
let mut np_guard: List[Int] = []
let mut np_value: List[Int] = []
let mut np_target: List[Int] = []
let mut np_iterable: List[Int] = []
let mut np_var_name: List[Str] = []
let mut np_is_mut: List[Int] = []
let mut np_is_pub: List[Int] = []
let mut np_inclusive: List[Int] = []
let mut np_start: List[Int] = []
let mut np_end: List[Int] = []
let mut np_obj: List[Int] = []
let mut np_method: List[Str] = []
let mut np_index: List[Int] = []
let mut np_return_type: List[Str] = []
let mut np_type_name: List[Str] = []

// Sublists: for lists of node references (params, args, stmts, etc.)
let mut sl_items: List[Int] = []
let mut sl_start: List[Int] = []
let mut sl_len: List[Int] = []

// Each node stores a sublist index for various list fields (-1 = none)
let mut np_params: List[Int] = []
let mut np_args: List[Int] = []
let mut np_stmts: List[Int] = []
let mut np_arms: List[Int] = []
let mut np_fields: List[Int] = []
let mut np_elements: List[Int] = []

fn new_node(kind: Int) -> Int {
    let id = np_kind.len()
    np_kind.push(kind)
    np_int_val.push(0)
    np_str_val.push("")
    np_name.push("")
    np_op.push("")
    np_left.push(-1)
    np_right.push(-1)
    np_body.push(-1)
    np_condition.push(-1)
    np_then_body.push(-1)
    np_else_body.push(-1)
    np_scrutinee.push(-1)
    np_pattern.push(-1)
    np_guard.push(-1)
    np_value.push(-1)
    np_target.push(-1)
    np_iterable.push(-1)
    np_var_name.push("")
    np_is_mut.push(0)
    np_is_pub.push(0)
    np_inclusive.push(0)
    np_start.push(-1)
    np_end.push(-1)
    np_obj.push(-1)
    np_method.push("")
    np_index.push(-1)
    np_return_type.push("")
    np_type_name.push("")
    np_params.push(-1)
    np_args.push(-1)
    np_stmts.push(-1)
    np_arms.push(-1)
    np_fields.push(-1)
    np_elements.push(-1)
    id
}

fn new_sublist() -> Int {
    let id = sl_start.len()
    sl_start.push(sl_items.len())
    sl_len.push(0)
    id
}

fn sublist_push(sl: Int, node_id: Int) {
    sl_items.push(node_id)
}

fn finalize_sublist(sl: Int) {
    let start = sl_start.get(sl)
    let length = sl_items.len() - start
    sl_len.set(sl, length)
}

fn sublist_get(sl: Int, idx: Int) -> Int {
    sl_items.get(sl_start.get(sl) + idx)
}

fn sublist_length(sl: Int) -> Int {
    sl_len.get(sl)
}

// ── Token input (parallel arrays from lexer) ────────────────────────

let mut tok_kinds: List[Int] = []
let mut tok_values: List[Str] = []
let mut tok_lines: List[Int] = []
let mut tok_cols: List[Int] = []
let mut pos: Int = 0

// ── Token navigation ────────────────────────────────────────────────

fn peek_kind() -> Int {
    tok_kinds.get(pos)
}

fn peek_value() -> Str {
    tok_values.get(pos)
}

fn peek_line() -> Int {
    tok_lines.get(pos)
}

fn peek_col() -> Int {
    tok_cols.get(pos)
}

fn at(kind: Int) -> Int {
    peek_kind() == kind
}

fn advance() -> Int {
    let old = pos
    pos = pos + 1
    old
}

fn advance_value() -> Str {
    let v = tok_values.get(pos)
    pos = pos + 1
    v
}

fn expect(kind: Int) -> Int {
    if peek_kind() != kind {
        io.println("parse error at line {peek_line()}:{peek_col()}: expected token kind {kind}, got {peek_kind()}")
    }
    advance()
}

fn expect_value(kind: Int) -> Str {
    if peek_kind() != kind {
        io.println("parse error at line {peek_line()}:{peek_col()}: expected token kind {kind}, got {peek_kind()}")
    }
    advance_value()
}

fn skip_newlines() {
    while at(TK_NEWLINE) {
        advance()
    }
}

fn maybe_newline() {
    if at(TK_NEWLINE) {
        advance()
    }
}

// ── Top-level ───────────────────────────────────────────────────────

fn parse_program() -> Int {
    let mut fn_nodes: List[Int] = []
    let mut type_nodes: List[Int] = []
    let mut let_nodes: List[Int] = []
    let mut fn_pub: List[Int] = []
    skip_newlines()
    while !at(TK_EOF) {
        skip_newlines()
        if at(TK_EOF) {
            break
        }
        if at(TK_TYPE) {
            let td = parse_type_def()
            type_nodes.push(td)
        } else if at(TK_LET) {
            let lb = parse_let_binding()
            let_nodes.push(lb)
        } else if at(TK_PUB) {
            advance()
            skip_newlines()
            let f = parse_fn_def()
            np_is_pub.set(f, 1)
            fn_nodes.push(f)
        } else if at(TK_FN) {
            let f = parse_fn_def()
            fn_nodes.push(f)
        } else {
            io.println("parse error: unexpected token at top level: {peek_kind()}")
            advance()
        }
        skip_newlines()
    }
    // Build sublists from collected node IDs
    let fns = new_sublist()
    let mut i = 0
    while i < fn_nodes.len() {
        sublist_push(fns, fn_nodes.get(i))
        i = i + 1
    }
    finalize_sublist(fns)
    let types = new_sublist()
    i = 0
    while i < type_nodes.len() {
        sublist_push(types, type_nodes.get(i))
        i = i + 1
    }
    finalize_sublist(types)
    let lets = new_sublist()
    i = 0
    while i < let_nodes.len() {
        sublist_push(lets, let_nodes.get(i))
        i = i + 1
    }
    finalize_sublist(lets)
    let prog = new_node(ND_PROGRAM)
    np_params.pop()
    np_params.push(fns)
    np_fields.pop()
    np_fields.push(types)
    np_stmts.pop()
    np_stmts.push(lets)
    prog
}

// ── Type definitions ────────────────────────────────────────────────

fn parse_type_def() -> Int {
    expect(TK_TYPE)
    let name = expect_value(TK_IDENT)
    // Skip type params [T] if present
    if at(TK_LBRACKET) {
        advance()
        while !at(TK_RBRACKET) {
            advance()
        }
        expect(TK_RBRACKET)
    }
    skip_newlines()
    let mut flds = -1
    if at(TK_LBRACE) {
        expect(TK_LBRACE)
        skip_newlines()
        let mut field_nodes: List[Int] = []
        while !at(TK_RBRACE) {
            let fname = expect_value(TK_IDENT)
            if at(TK_COLON) {
                advance()
                let type_ann = parse_type_annotation()
                let tf = new_node(ND_TYPE_FIELD)
                np_name.pop()
                np_name.push(fname)
                np_value.pop()
                np_value.push(type_ann)
                field_nodes.push(tf)
            } else {
                let tv = new_node(ND_TYPE_VARIANT)
                np_name.pop()
                np_name.push(fname)
                field_nodes.push(tv)
            }
            skip_newlines()
        }
        expect(TK_RBRACE)
        flds = new_sublist()
        let mut i = 0
        while i < field_nodes.len() {
            sublist_push(flds, field_nodes.get(i))
            i = i + 1
        }
        finalize_sublist(flds)
    }
    let td = new_node(ND_TYPE_DEF)
    np_name.pop()
    np_name.push(name)
    np_fields.pop()
    np_fields.push(flds)
    td
}

fn parse_type_annotation() -> Int {
    let name = expect_value(TK_IDENT)
    let mut elems = -1
    if at(TK_LBRACKET) {
        advance()
        let mut type_nodes: List[Int] = []
        type_nodes.push(parse_type_annotation())
        while at(TK_COMMA) {
            advance()
            skip_newlines()
            type_nodes.push(parse_type_annotation())
        }
        expect(TK_RBRACKET)
        elems = new_sublist()
        let mut i = 0
        while i < type_nodes.len() {
            sublist_push(elems, type_nodes.get(i))
            i = i + 1
        }
        finalize_sublist(elems)
    }
    let ta = new_node(ND_TYPE_ANN)
    np_name.pop()
    np_name.push(name)
    np_elements.pop()
    np_elements.push(elems)
    ta
}

// ── Function definitions ────────────────────────────────────────────

fn parse_fn_def() -> Int {
    expect(TK_FN)
    let name = expect_value(TK_IDENT)
    // Skip type params
    if at(TK_LBRACKET) {
        advance()
        while !at(TK_RBRACKET) {
            advance()
        }
        expect(TK_RBRACKET)
    }
    expect(TK_LPAREN)
    let mut param_nodes: List[Int] = []
    if !at(TK_RPAREN) {
        param_nodes.push(parse_param())
        while at(TK_COMMA) {
            advance()
            if at(TK_RPAREN) {
                break
            }
            param_nodes.push(parse_param())
        }
    }
    expect(TK_RPAREN)
    let ret_type = ""
    let mut ret_str = ""
    if at(TK_ARROW) {
        advance()
        let rt = parse_type_annotation()
        ret_str = np_name.get(rt)
    }
    // Skip effects
    if at(TK_BANG) {
        advance()
        expect_value(TK_IDENT)
        while at(TK_COMMA) {
            advance()
            skip_newlines()
            expect_value(TK_IDENT)
        }
    }
    skip_newlines()
    let body = -1
    let mut body_id = -1
    if at(TK_LBRACE) {
        body_id = parse_block()
    }
    let params = new_sublist()
    let mut pi = 0
    while pi < param_nodes.len() {
        sublist_push(params, param_nodes.get(pi))
        pi = pi + 1
    }
    finalize_sublist(params)
    let nd = new_node(ND_FN_DEF)
    np_name.pop()
    np_name.push(name)
    np_params.pop()
    np_params.push(params)
    np_body.pop()
    np_body.push(body_id)
    np_return_type.pop()
    np_return_type.push(ret_str)
    nd
}

fn parse_param() -> Int {
    let mut is_mut = 0
    if at(TK_MUT) {
        is_mut = 1
        advance()
    }
    let name = expect_value(TK_IDENT)
    let mut type_str = ""
    if at(TK_COLON) {
        advance()
        let ta = parse_type_annotation()
        type_str = np_name.get(ta)
    }
    let nd = new_node(ND_PARAM)
    np_name.pop()
    np_name.push(name)
    np_type_name.pop()
    np_type_name.push(type_str)
    np_is_mut.pop()
    np_is_mut.push(is_mut)
    nd
}

// ── Block ───────────────────────────────────────────────────────────

fn parse_block() -> Int {
    expect(TK_LBRACE)
    skip_newlines()
    let mut stmt_nodes: List[Int] = []
    while !at(TK_RBRACE) {
        stmt_nodes.push(parse_stmt())
        skip_newlines()
    }
    expect(TK_RBRACE)
    let stmts = new_sublist()
    let mut i = 0
    while i < stmt_nodes.len() {
        sublist_push(stmts, stmt_nodes.get(i))
        i = i + 1
    }
    finalize_sublist(stmts)
    let nd = new_node(ND_BLOCK)
    np_stmts.pop()
    np_stmts.push(stmts)
    nd
}

// ── Statements ──────────────────────────────────────────────────────

fn parse_stmt() -> Int {
    if at(TK_WHILE) {
        return parse_while_loop()
    }
    if at(TK_LOOP) {
        return parse_loop_expr()
    }
    if at(TK_BREAK) {
        advance()
        maybe_newline()
        return new_node(ND_BREAK)
    }
    if at(TK_CONTINUE) {
        advance()
        maybe_newline()
        return new_node(ND_CONTINUE)
    }
    if at(TK_LET) {
        return parse_let_binding()
    }
    if at(TK_FOR) {
        return parse_for_in()
    }
    if at(TK_RETURN) {
        return parse_return_stmt()
    }
    if at(TK_IF) {
        let nd = parse_if_expr()
        maybe_newline()
        return nd
    }

    let expr = parse_expr()

    if at(TK_EQUALS) {
        advance()
        skip_newlines()
        let val = parse_expr()
        maybe_newline()
        let nd = new_node(ND_ASSIGNMENT)
        np_target.pop()
        np_target.push(expr)
        np_value.pop()
        np_value.push(val)
        return nd
    }

    if at(TK_PLUS_EQ) || at(TK_MINUS_EQ) || at(TK_STAR_EQ) || at(TK_SLASH_EQ) {
        let op_kind = peek_kind()
        advance()
        skip_newlines()
        let val = parse_expr()
        maybe_newline()
        let mut op_str = "+"
        if op_kind == TK_MINUS_EQ {
            op_str = "-"
        } else if op_kind == TK_STAR_EQ {
            op_str = "*"
        } else if op_kind == TK_SLASH_EQ {
            op_str = "/"
        }
        let nd = new_node(ND_COMPOUND_ASSIGN)
        np_op.pop()
        np_op.push(op_str)
        np_target.pop()
        np_target.push(expr)
        np_value.pop()
        np_value.push(val)
        return nd
    }

    maybe_newline()
    let nd = new_node(ND_EXPR_STMT)
    np_value.pop()
    np_value.push(expr)
    nd
}

fn parse_let_binding() -> Int {
    expect(TK_LET)
    let mut is_mut = 0
    if at(TK_MUT) {
        is_mut = 1
        advance()
    }
    let name = expect_value(TK_IDENT)
    let mut type_ann = -1
    if at(TK_COLON) {
        advance()
        type_ann = parse_type_annotation()
    }
    expect(TK_EQUALS)
    skip_newlines()
    let val = parse_expr()
    maybe_newline()
    let nd = new_node(ND_LET_BINDING)
    np_name.pop()
    np_name.push(name)
    np_value.pop()
    np_value.push(val)
    np_is_mut.pop()
    np_is_mut.push(is_mut)
    np_target.pop()
    np_target.push(type_ann)
    nd
}

fn parse_return_stmt() -> Int {
    expect(TK_RETURN)
    if at(TK_NEWLINE) || at(TK_RBRACE) || at(TK_EOF) {
        maybe_newline()
        let nd = new_node(ND_RETURN)
        return nd
    }
    let val = parse_expr()
    maybe_newline()
    let nd = new_node(ND_RETURN)
    np_value.pop()
    np_value.push(val)
    nd
}

fn parse_if_expr() -> Int {
    expect(TK_IF)
    let cond = parse_expr()
    skip_newlines()
    let then_b = parse_block()
    let mut else_b = -1
    skip_newlines()
    if at(TK_ELSE) {
        advance()
        skip_newlines()
        if at(TK_IF) {
            let inner = parse_if_expr()
            let stmts = new_sublist()
            sublist_push(stmts, inner)
            finalize_sublist(stmts)
            let blk = new_node(ND_BLOCK)
            np_stmts.pop()
            np_stmts.push(stmts)
            else_b = blk
        } else {
            else_b = parse_block()
        }
    }
    let nd = new_node(ND_IF_EXPR)
    np_condition.pop()
    np_condition.push(cond)
    np_then_body.pop()
    np_then_body.push(then_b)
    np_else_body.pop()
    np_else_body.push(else_b)
    nd
}

fn parse_while_loop() -> Int {
    expect(TK_WHILE)
    let cond = parse_expr()
    skip_newlines()
    let body = parse_block()
    let nd = new_node(ND_WHILE_LOOP)
    np_condition.pop()
    np_condition.push(cond)
    np_body.pop()
    np_body.push(body)
    nd
}

fn parse_loop_expr() -> Int {
    expect(TK_LOOP)
    skip_newlines()
    let body = parse_block()
    let nd = new_node(ND_LOOP_EXPR)
    np_body.pop()
    np_body.push(body)
    nd
}

fn parse_for_in() -> Int {
    expect(TK_FOR)
    let mut var = ""
    let mut pat = -1
    if at(TK_LPAREN) {
        pat = parse_pattern()
        var = "_tuple"
    } else {
        var = expect_value(TK_IDENT)
    }
    expect(TK_IN)
    let iter = parse_expr()
    skip_newlines()
    let body = parse_block()
    let nd = new_node(ND_FOR_IN)
    np_var_name.pop()
    np_var_name.push(var)
    np_iterable.pop()
    np_iterable.push(iter)
    np_body.pop()
    np_body.push(body)
    if pat != -1 {
        np_elements.pop()
        np_elements.push(pat)
    }
    nd
}

// ── Expressions (precedence climbing) ───────────────────────────────

fn parse_expr() -> Int {
    parse_or()
}

fn parse_or() -> Int {
    let mut left = parse_and()
    while at(TK_OR) {
        advance()
        skip_newlines()
        let right = parse_and()
        let nd = new_node(ND_BIN_OP)
        np_op.pop()
        np_op.push("||")
        np_left.pop()
        np_left.push(left)
        np_right.pop()
        np_right.push(right)
        left = nd
    }
    left
}

fn parse_and() -> Int {
    let mut left = parse_equality()
    while at(TK_AND) {
        advance()
        skip_newlines()
        let right = parse_equality()
        let nd = new_node(ND_BIN_OP)
        np_op.pop()
        np_op.push("&&")
        np_left.pop()
        np_left.push(left)
        np_right.pop()
        np_right.push(right)
        left = nd
    }
    left
}

fn parse_equality() -> Int {
    let mut left = parse_comparison()
    while at(TK_EQEQ) || at(TK_NOT_EQ) {
        let op = advance_value()
        skip_newlines()
        let right = parse_comparison()
        let nd = new_node(ND_BIN_OP)
        np_op.pop()
        np_op.push(op)
        np_left.pop()
        np_left.push(left)
        np_right.pop()
        np_right.push(right)
        left = nd
    }
    left
}

fn parse_comparison() -> Int {
    let mut left = parse_additive()
    while at(TK_LESS) || at(TK_GREATER) || at(TK_LESS_EQ) || at(TK_GREATER_EQ) {
        let op = advance_value()
        skip_newlines()
        let right = parse_additive()
        let nd = new_node(ND_BIN_OP)
        np_op.pop()
        np_op.push(op)
        np_left.pop()
        np_left.push(left)
        np_right.pop()
        np_right.push(right)
        left = nd
    }
    left
}

fn parse_additive() -> Int {
    let mut left = parse_multiplicative()
    while at(TK_PLUS) || at(TK_MINUS) {
        let op = advance_value()
        skip_newlines()
        let right = parse_multiplicative()
        let nd = new_node(ND_BIN_OP)
        np_op.pop()
        np_op.push(op)
        np_left.pop()
        np_left.push(left)
        np_right.pop()
        np_right.push(right)
        left = nd
    }
    left
}

fn parse_multiplicative() -> Int {
    let mut left = parse_unary()
    while at(TK_STAR) || at(TK_SLASH) || at(TK_PERCENT) {
        let op = advance_value()
        skip_newlines()
        let right = parse_unary()
        let nd = new_node(ND_BIN_OP)
        np_op.pop()
        np_op.push(op)
        np_left.pop()
        np_left.push(left)
        np_right.pop()
        np_right.push(right)
        left = nd
    }
    left
}

fn parse_unary() -> Int {
    if at(TK_MINUS) {
        advance()
        let operand = parse_unary()
        let nd = new_node(ND_UNARY_OP)
        np_op.pop()
        np_op.push("-")
        np_left.pop()
        np_left.push(operand)
        return nd
    }
    if at(TK_BANG) {
        advance()
        let operand = parse_unary()
        let nd = new_node(ND_UNARY_OP)
        np_op.pop()
        np_op.push("!")
        np_left.pop()
        np_left.push(operand)
        return nd
    }
    parse_postfix()
}

// ── Postfix: calls, field access, index, method calls ───────────────

fn parse_postfix() -> Int {
    let mut node = parse_primary()
    let mut running = 1
    while running {
        if at(TK_DOT) {
            advance()
            let member = expect_value(TK_IDENT)
            if at(TK_LPAREN) {
                advance()
                let mut arg_nodes: List[Int] = []
                if !at(TK_RPAREN) {
                    arg_nodes.push(parse_expr())
                    while at(TK_COMMA) {
                        advance()
                        skip_newlines()
                        if at(TK_RPAREN) {
                            break
                        }
                        arg_nodes.push(parse_expr())
                    }
                    skip_newlines()
                }
                expect(TK_RPAREN)
                let args = new_sublist()
                let mut ai = 0
                while ai < arg_nodes.len() {
                    sublist_push(args, arg_nodes.get(ai))
                    ai = ai + 1
                }
                finalize_sublist(args)
                let nd = new_node(ND_METHOD_CALL)
                np_obj.pop()
                np_obj.push(node)
                np_method.pop()
                np_method.push(member)
                np_args.pop()
                np_args.push(args)
                node = nd
            } else {
                let nd = new_node(ND_FIELD_ACCESS)
                np_obj.pop()
                np_obj.push(node)
                np_name.pop()
                np_name.push(member)
                node = nd
                // Check for struct literal after field access (e.g. Foo.Bar { ... })
                if at(TK_LBRACE) {
                    if looks_like_struct_lit() {
                        // Reconstruct dotted name
                        let dotted = flatten_field_access(node)
                        if dotted != "" {
                            node = parse_struct_lit(dotted)
                        }
                    }
                }
            }
        } else if at(TK_LPAREN) {
            advance()
            let mut call_arg_nodes: List[Int] = []
            if !at(TK_RPAREN) {
                skip_newlines()
                skip_named_arg_label()
                call_arg_nodes.push(parse_expr())
                while at(TK_COMMA) {
                    advance()
                    skip_newlines()
                    if at(TK_RPAREN) {
                        break
                    }
                    skip_named_arg_label()
                    call_arg_nodes.push(parse_expr())
                }
                skip_newlines()
            }
            expect(TK_RPAREN)
            let args = new_sublist()
            let mut ci = 0
            while ci < call_arg_nodes.len() {
                sublist_push(args, call_arg_nodes.get(ci))
                ci = ci + 1
            }
            finalize_sublist(args)
            let nd = new_node(ND_CALL)
            np_left.pop()
            np_left.push(node)
            np_args.pop()
            np_args.push(args)
            node = nd
        } else if at(TK_LBRACKET) {
            advance()
            skip_newlines()
            let idx = parse_expr()
            skip_newlines()
            expect(TK_RBRACKET)
            let nd = new_node(ND_INDEX_EXPR)
            np_obj.pop()
            np_obj.push(node)
            np_index.pop()
            np_index.push(idx)
            node = nd
        } else {
            running = 0
        }
    }
    node
}

fn skip_named_arg_label() {
    if at(TK_IDENT) {
        // Peek ahead to see if next is colon (named arg)
        let saved = pos
        advance()
        if at(TK_COLON) {
            advance()
            skip_newlines()
        } else {
            pos = saved
        }
    }
}

fn flatten_field_access(node: Int) -> Str {
    let kind = np_kind.get(node)
    if kind == ND_IDENT {
        return np_name.get(node)
    }
    if kind == ND_FIELD_ACCESS {
        let base = flatten_field_access(np_obj.get(node))
        if base != "" {
            return base + "." + np_name.get(node)
        }
    }
    ""
}

fn looks_like_struct_lit() -> Int {
    let saved = pos
    // Expect { ident :
    if !at(TK_LBRACE) {
        return 0
    }
    advance()
    skip_newlines()
    if at(TK_RBRACE) {
        pos = saved
        return 1
    }
    if !at(TK_IDENT) {
        pos = saved
        return 0
    }
    advance()
    let result = at(TK_COLON)
    pos = saved
    result
}

// ── Primary expressions ─────────────────────────────────────────────

fn parse_primary() -> Int {
    if at(TK_MATCH) {
        return parse_match_expr()
    }
    if at(TK_IF) {
        return parse_if_expr()
    }
    if at(TK_SELF) {
        advance()
        let nd = new_node(ND_IDENT)
        np_name.pop()
        np_name.push("self")
        return nd
    }

    if at(TK_IDENT) {
        let name = advance_value()
        if name == "true" {
            let nd = new_node(ND_BOOL_LIT)
            np_int_val.pop()
            np_int_val.push(1)
            return nd
        }
        if name == "false" {
            let nd = new_node(ND_BOOL_LIT)
            np_int_val.pop()
            np_int_val.push(0)
            return nd
        }
        if at(TK_LBRACE) && looks_like_struct_lit() {
            return parse_struct_lit(name)
        }
        let nd = new_node(ND_IDENT)
        np_name.pop()
        np_name.push(name)
        return nd
    }

    if at(TK_INT) {
        let val_str = advance_value()
        let nd = new_node(ND_INT_LIT)
        np_str_val.pop()
        np_str_val.push(val_str)
        // Check for range
        if at(TK_DOTDOT) {
            advance()
            let end_nd = parse_primary()
            let rng = new_node(ND_RANGE_LIT)
            np_start.pop()
            np_start.push(nd)
            np_end.pop()
            np_end.push(end_nd)
            return rng
        }
        if at(TK_DOTDOTEQ) {
            advance()
            let end_nd = parse_primary()
            let rng = new_node(ND_RANGE_LIT)
            np_start.pop()
            np_start.push(nd)
            np_end.pop()
            np_end.push(end_nd)
            np_inclusive.pop()
            np_inclusive.push(1)
            return rng
        }
        return nd
    }

    if at(TK_FLOAT) {
        let val_str = advance_value()
        let nd = new_node(ND_FLOAT_LIT)
        np_str_val.pop()
        np_str_val.push(val_str)
        return nd
    }

    if at(TK_LPAREN) {
        advance()
        skip_newlines()
        if at(TK_RPAREN) {
            advance()
            // Unit / empty tuple — represent as int lit 0 for simplicity
            return new_node(ND_INT_LIT)
        }
        let first = parse_expr()
        if at(TK_COMMA) {
            let mut elem_nodes: List[Int] = [first]
            while at(TK_COMMA) {
                advance()
                skip_newlines()
                if at(TK_RPAREN) {
                    break
                }
                elem_nodes.push(parse_expr())
            }
            expect(TK_RPAREN)
            let elems = new_sublist()
            let mut ti = 0
            while ti < elem_nodes.len() {
                sublist_push(elems, elem_nodes.get(ti))
                ti = ti + 1
            }
            finalize_sublist(elems)
            let nd = new_node(ND_TUPLE_LIT)
            np_elements.pop()
            np_elements.push(elems)
            return nd
        }
        skip_newlines()
        expect(TK_RPAREN)
        return first
    }

    if at(TK_LBRACKET) {
        return parse_list_lit()
    }

    if at(TK_STRING_START) {
        return parse_interp_string()
    }

    if at(TK_LBRACE) {
        return parse_block()
    }

    io.println("parse error: unexpected token {peek_kind()} at line {peek_line()}:{peek_col()}")
    advance()
    new_node(ND_INT_LIT)
}

fn parse_struct_lit(type_name: Str) -> Int {
    expect(TK_LBRACE)
    skip_newlines()
    let mut field_nodes: List[Int] = []
    while !at(TK_RBRACE) {
        let fname = expect_value(TK_IDENT)
        expect(TK_COLON)
        skip_newlines()
        let fval = parse_expr()
        let sf = new_node(ND_STRUCT_LIT_FIELD)
        np_name.pop()
        np_name.push(fname)
        np_value.pop()
        np_value.push(fval)
        field_nodes.push(sf)
        if at(TK_COMMA) {
            advance()
        }
        skip_newlines()
    }
    expect(TK_RBRACE)
    let flds = new_sublist()
    let mut i = 0
    while i < field_nodes.len() {
        sublist_push(flds, field_nodes.get(i))
        i = i + 1
    }
    finalize_sublist(flds)
    let nd = new_node(ND_STRUCT_LIT)
    np_type_name.pop()
    np_type_name.push(type_name)
    np_fields.pop()
    np_fields.push(flds)
    nd
}

fn parse_list_lit() -> Int {
    expect(TK_LBRACKET)
    skip_newlines()
    let mut elem_nodes: List[Int] = []
    while !at(TK_RBRACKET) {
        elem_nodes.push(parse_expr())
        if at(TK_COMMA) {
            advance()
        }
        skip_newlines()
    }
    expect(TK_RBRACKET)
    let elems = new_sublist()
    let mut i = 0
    while i < elem_nodes.len() {
        sublist_push(elems, elem_nodes.get(i))
        i = i + 1
    }
    finalize_sublist(elems)
    let nd = new_node(ND_LIST_LIT)
    np_elements.pop()
    np_elements.push(elems)
    nd
}

fn parse_interp_string() -> Int {
    expect(TK_STRING_START)
    let mut part_nodes: List[Int] = []
    while !at(TK_STRING_END) {
        if at(TK_STRING_PART) {
            let s = advance_value()
            let sn = new_node(ND_IDENT)
            np_str_val.pop()
            np_str_val.push(s)
            np_name.pop()
            np_name.push(s)
            part_nodes.push(sn)
        } else if at(TK_INTERP_START) {
            advance()
            part_nodes.push(parse_expr())
            expect(TK_INTERP_END)
        } else {
            io.println("parse error: unexpected token in string: {peek_kind()}")
            advance()
        }
    }
    expect(TK_STRING_END)
    let parts = new_sublist()
    let mut i = 0
    while i < part_nodes.len() {
        sublist_push(parts, part_nodes.get(i))
        i = i + 1
    }
    finalize_sublist(parts)
    let nd = new_node(ND_INTERP_STRING)
    np_elements.pop()
    np_elements.push(parts)
    nd
}

// ── Match ───────────────────────────────────────────────────────────

fn parse_match_expr() -> Int {
    expect(TK_MATCH)
    let scrut = parse_expr()
    skip_newlines()
    expect(TK_LBRACE)
    skip_newlines()
    let mut arm_nodes: List[Int] = []
    while !at(TK_RBRACE) {
        arm_nodes.push(parse_match_arm())
        skip_newlines()
    }
    expect(TK_RBRACE)
    let arms = new_sublist()
    let mut i = 0
    while i < arm_nodes.len() {
        sublist_push(arms, arm_nodes.get(i))
        i = i + 1
    }
    finalize_sublist(arms)
    let nd = new_node(ND_MATCH_EXPR)
    np_scrutinee.pop()
    np_scrutinee.push(scrut)
    np_arms.pop()
    np_arms.push(arms)
    nd
}

fn parse_match_arm() -> Int {
    let pat = parse_pattern()
    let mut guard = -1
    skip_newlines()
    if at(TK_IF) {
        advance()
        guard = parse_expr()
    }
    skip_newlines()
    expect(TK_FAT_ARROW)
    skip_newlines()
    let mut body = -1
    if at(TK_LBRACE) {
        body = parse_block()
    } else {
        body = parse_stmt()
    }
    let nd = new_node(ND_MATCH_ARM)
    np_pattern.pop()
    np_pattern.push(pat)
    np_body.pop()
    np_body.push(body)
    np_guard.pop()
    np_guard.push(guard)
    nd
}

fn parse_pattern() -> Int {
    if at(TK_LPAREN) {
        advance()
        skip_newlines()
        let elems = new_sublist()
        sublist_push(elems, parse_pattern())
        while at(TK_COMMA) {
            advance()
            skip_newlines()
            sublist_push(elems, parse_pattern())
        }
        finalize_sublist(elems)
        skip_newlines()
        expect(TK_RPAREN)
        let nd = new_node(ND_TUPLE_PATTERN)
        np_elements.pop()
        np_elements.push(elems)
        return nd
    }
    if at(TK_STRING_START) {
        let str_node = parse_interp_string()
        let nd = new_node(ND_STRING_PATTERN)
        np_str_val.pop()
        np_str_val.push(np_str_val.get(str_node))
        return nd
    }
    if at(TK_INT) {
        let v = advance_value()
        let nd = new_node(ND_INT_PATTERN)
        np_str_val.pop()
        np_str_val.push(v)
        return nd
    }
    if at(TK_IDENT) {
        let name = advance_value()
        if name == "_" {
            return new_node(ND_WILDCARD_PATTERN)
        }
        if at(TK_LPAREN) {
            advance()
            skip_newlines()
            let flds = new_sublist()
            if !at(TK_RPAREN) {
                sublist_push(flds, parse_pattern())
                while at(TK_COMMA) {
                    advance()
                    skip_newlines()
                    sublist_push(flds, parse_pattern())
                }
            }
            finalize_sublist(flds)
            skip_newlines()
            expect(TK_RPAREN)
            let nd = new_node(ND_ENUM_PATTERN)
            np_name.pop()
            np_name.push(name)
            np_fields.pop()
            np_fields.push(flds)
            return nd
        }
        let nd = new_node(ND_IDENT_PATTERN)
        np_name.pop()
        np_name.push(name)
        return nd
    }
    io.println("parse error: unexpected token in pattern: {peek_kind()}")
    advance()
    new_node(ND_WILDCARD_PATTERN)
}

// ── AST pretty-printer (for demo) ──────────────────────────────────

fn print_indent(depth: Int) {
    let mut i = 0
    while i < depth {
        io.println("  ")
        i = i + 1
    }
}

fn node_kind_name(kind: Int) -> Str {
    if kind == ND_INT_LIT { "IntLit" }
    else if kind == ND_FLOAT_LIT { "FloatLit" }
    else if kind == ND_IDENT { "Ident" }
    else if kind == ND_CALL { "Call" }
    else if kind == ND_METHOD_CALL { "MethodCall" }
    else if kind == ND_BIN_OP { "BinOp" }
    else if kind == ND_UNARY_OP { "UnaryOp" }
    else if kind == ND_INTERP_STRING { "InterpStr" }
    else if kind == ND_BOOL_LIT { "BoolLit" }
    else if kind == ND_LIST_LIT { "ListLit" }
    else if kind == ND_STRUCT_LIT { "StructLit" }
    else if kind == ND_FIELD_ACCESS { "FieldAccess" }
    else if kind == ND_INDEX_EXPR { "IndexExpr" }
    else if kind == ND_RANGE_LIT { "RangeLit" }
    else if kind == ND_IF_EXPR { "IfExpr" }
    else if kind == ND_MATCH_EXPR { "MatchExpr" }
    else if kind == ND_LET_BINDING { "LetBinding" }
    else if kind == ND_EXPR_STMT { "ExprStmt" }
    else if kind == ND_ASSIGNMENT { "Assignment" }
    else if kind == ND_COMPOUND_ASSIGN { "CompoundAssign" }
    else if kind == ND_RETURN { "Return" }
    else if kind == ND_FOR_IN { "ForIn" }
    else if kind == ND_WHILE_LOOP { "WhileLoop" }
    else if kind == ND_LOOP_EXPR { "LoopExpr" }
    else if kind == ND_BREAK { "Break" }
    else if kind == ND_CONTINUE { "Continue" }
    else if kind == ND_BLOCK { "Block" }
    else if kind == ND_FN_DEF { "FnDef" }
    else if kind == ND_PARAM { "Param" }
    else if kind == ND_PROGRAM { "Program" }
    else if kind == ND_TYPE_DEF { "TypeDef" }
    else if kind == ND_TYPE_FIELD { "TypeField" }
    else if kind == ND_TYPE_VARIANT { "TypeVariant" }
    else if kind == ND_INT_PATTERN { "IntPattern" }
    else if kind == ND_WILDCARD_PATTERN { "WildcardPattern" }
    else if kind == ND_IDENT_PATTERN { "IdentPattern" }
    else if kind == ND_TUPLE_PATTERN { "TuplePattern" }
    else if kind == ND_STRING_PATTERN { "StringPattern" }
    else if kind == ND_ENUM_PATTERN { "EnumPattern" }
    else if kind == ND_MATCH_ARM { "MatchArm" }
    else if kind == ND_STRUCT_LIT_FIELD { "StructLitField" }
    else if kind == ND_TYPE_ANN { "TypeAnn" }
    else { "Unknown" }
}

fn print_node(id: Int, depth: Int) {
    if id == -1 {
        return
    }
    let kind = np_kind.get(id)
    let name = np_name.get(id)
    let op = np_op.get(id)
    let str_val = np_str_val.get(id)

    if kind == ND_PROGRAM {
        io.println("Program")
        let fns_sl = np_params.get(id)
        if fns_sl != -1 {
            let mut i = 0
            while i < sublist_length(fns_sl) {
                print_node(sublist_get(fns_sl, i), depth + 1)
                i = i + 1
            }
        }
        let types_sl = np_fields.get(id)
        if types_sl != -1 {
            let mut i = 0
            while i < sublist_length(types_sl) {
                print_node(sublist_get(types_sl, i), depth + 1)
                i = i + 1
            }
        }
    } else if kind == ND_FN_DEF {
        io.println("{"  ".substring(0, 0)}FnDef: {name}")
        let p_sl = np_params.get(id)
        if p_sl != -1 {
            let mut i = 0
            while i < sublist_length(p_sl) {
                let pid = sublist_get(p_sl, i)
                io.println("  param: {np_name.get(pid)} : {np_type_name.get(pid)}")
                i = i + 1
            }
        }
        let body = np_body.get(id)
        if body != -1 {
            print_node(body, depth + 1)
        }
    } else if kind == ND_BLOCK {
        io.println("  Block")
        let stmts_sl = np_stmts.get(id)
        if stmts_sl != -1 {
            let mut i = 0
            while i < sublist_length(stmts_sl) {
                print_node(sublist_get(stmts_sl, i), depth + 1)
                i = i + 1
            }
        }
    } else if kind == ND_LET_BINDING {
        io.println("    LetBinding: {name} (mut={np_is_mut.get(id)})")
        print_node(np_value.get(id), depth + 1)
    } else if kind == ND_EXPR_STMT {
        io.println("    ExprStmt")
        print_node(np_value.get(id), depth + 1)
    } else if kind == ND_BIN_OP {
        io.println("      BinOp: {op}")
        print_node(np_left.get(id), depth + 1)
        print_node(np_right.get(id), depth + 1)
    } else if kind == ND_CALL {
        io.println("      Call")
        print_node(np_left.get(id), depth + 1)
    } else if kind == ND_METHOD_CALL {
        io.println("      MethodCall: .{np_method.get(id)}()")
        print_node(np_obj.get(id), depth + 1)
    } else if kind == ND_INT_LIT {
        io.println("      IntLit: {str_val}")
    } else if kind == ND_IDENT {
        io.println("      Ident: {name}")
    } else if kind == ND_RETURN {
        io.println("    Return")
        print_node(np_value.get(id), depth + 1)
    } else if kind == ND_IF_EXPR {
        io.println("    IfExpr")
        print_node(np_condition.get(id), depth + 1)
        print_node(np_then_body.get(id), depth + 1)
        print_node(np_else_body.get(id), depth + 1)
    } else if kind == ND_WHILE_LOOP {
        io.println("    WhileLoop")
        print_node(np_condition.get(id), depth + 1)
        print_node(np_body.get(id), depth + 1)
    } else if kind == ND_FOR_IN {
        io.println("    ForIn: {np_var_name.get(id)}")
        print_node(np_iterable.get(id), depth + 1)
        print_node(np_body.get(id), depth + 1)
    } else if kind == ND_ASSIGNMENT {
        io.println("    Assignment")
        print_node(np_target.get(id), depth + 1)
        print_node(np_value.get(id), depth + 1)
    } else if kind == ND_TYPE_DEF {
        io.println("TypeDef: {name}")
    } else if kind == ND_MATCH_EXPR {
        io.println("    MatchExpr")
        print_node(np_scrutinee.get(id), depth + 1)
    } else if kind == ND_INTERP_STRING {
        io.println("      InterpString")
    } else if kind == ND_BOOL_LIT {
        io.println("      BoolLit: {np_int_val.get(id)}")
    } else if kind == ND_STRUCT_LIT {
        io.println("      StructLit: {np_type_name.get(id)}")
    } else if kind == ND_FIELD_ACCESS {
        io.println("      FieldAccess: .{name}")
        print_node(np_obj.get(id), depth + 1)
    } else if kind == ND_UNARY_OP {
        io.println("      UnaryOp: {op}")
        print_node(np_left.get(id), depth + 1)
    } else {
        io.println("      {node_kind_name(kind)}")
    }
}

// ── Inline mini-lexer (to make this file self-contained for demo) ───
// Duplicated minimal lexer logic so we can demo-parse a string.

let CH_TAB = 9
let CH_NEWLINE = 10
let CH_SPACE = 32
let CH_DQUOTE = 34
let CH_PERCENT = 37
let CH_LPAREN = 40
let CH_RPAREN = 41
let CH_STAR = 42
let CH_PLUS = 43
let CH_COMMA = 44
let CH_MINUS = 45
let CH_DOT = 46
let CH_SLASH = 47
let CH_0 = 48
let CH_9 = 57
let CH_COLON = 58
let CH_LESS = 60
let CH_EQUALS = 61
let CH_GREATER = 62
let CH_QUESTION = 63
let CH_AT = 64
let CH_A = 65
let CH_Z = 90
let CH_LBRACKET = 91
let CH_BACKSLASH = 92
let CH_RBRACKET = 93
let CH_UNDERSCORE = 95
let CH_a = 97
let CH_n = 110
let CH_t = 116
let CH_z = 122
let CH_LBRACE = 123
let CH_PIPE = 124
let CH_RBRACE = 125
let CH_BANG = 33
let CH_AMP = 38

fn is_alpha(c: Int) -> Int {
    (c >= CH_A && c <= CH_Z) || (c >= CH_a && c <= CH_z) || c == CH_UNDERSCORE
}

fn is_digit(c: Int) -> Int {
    c >= CH_0 && c <= CH_9
}

fn is_alnum(c: Int) -> Int {
    is_alpha(c) || is_digit(c)
}

fn lpeek(source: Str, p: Int) -> Int {
    if p >= source.len() { 0 }
    else { source.char_at(p) }
}

fn keyword_lookup(name: Str) -> Int {
    if name == "fn" { TK_FN }
    else if name == "let" { TK_LET }
    else if name == "mut" { TK_MUT }
    else if name == "type" { TK_TYPE }
    else if name == "trait" { TK_TRAIT }
    else if name == "impl" { TK_IMPL }
    else if name == "if" { TK_IF }
    else if name == "else" { TK_ELSE }
    else if name == "match" { TK_MATCH }
    else if name == "for" { TK_FOR }
    else if name == "in" { TK_IN }
    else if name == "while" { TK_WHILE }
    else if name == "loop" { TK_LOOP }
    else if name == "break" { TK_BREAK }
    else if name == "continue" { TK_CONTINUE }
    else if name == "return" { TK_RETURN }
    else if name == "pub" { TK_PUB }
    else if name == "self" { TK_SELF }
    else if name == "true" { TK_IDENT }
    else if name == "false" { TK_IDENT }
    else { TK_IDENT }
}

fn mini_lex(source: Str) {
    let mut p = 0
    let mut line = 1
    let mut col = 1
    let mut last_kind = -1

    while p < source.len() {
        let ch = lpeek(source, p)

        if ch == CH_SPACE || ch == CH_TAB {
            p = p + 1
            col = col + 1
            continue
        }

        // Line comments
        if ch == CH_SLASH && lpeek(source, p + 1) == CH_SLASH {
            while p < source.len() && lpeek(source, p) != CH_NEWLINE {
                p = p + 1
            }
            continue
        }

        if ch == CH_NEWLINE {
            if last_kind != TK_NEWLINE {
                tok_kinds.push(TK_NEWLINE)
                tok_values.push("")
                tok_lines.push(line)
                tok_cols.push(col)
                last_kind = TK_NEWLINE
            }
            p = p + 1
            line = line + 1
            col = 1
            continue
        }

        if ch == CH_DQUOTE {
            let t_line = line
            let t_col = col
            p = p + 1
            col = col + 1
            tok_kinds.push(TK_STRING_START)
            tok_values.push("")
            tok_lines.push(t_line)
            tok_cols.push(t_col)
            last_kind = TK_STRING_START
            let mut buf = ""
            let mut in_str = 1
            while in_str && p < source.len() {
                let sc = lpeek(source, p)
                if sc == CH_DQUOTE {
                    tok_kinds.push(TK_STRING_PART)
                    tok_values.push(buf)
                    tok_lines.push(line)
                    tok_cols.push(col)
                    last_kind = TK_STRING_PART
                    tok_kinds.push(TK_STRING_END)
                    tok_values.push("")
                    tok_lines.push(line)
                    tok_cols.push(col)
                    last_kind = TK_STRING_END
                    p = p + 1
                    col = col + 1
                    in_str = 0
                } else if sc == CH_LBRACE {
                    tok_kinds.push(TK_STRING_PART)
                    tok_values.push(buf)
                    tok_lines.push(line)
                    tok_cols.push(col)
                    last_kind = TK_STRING_PART
                    buf = ""
                    tok_kinds.push(TK_INTERP_START)
                    tok_values.push("")
                    tok_lines.push(line)
                    tok_cols.push(col)
                    last_kind = TK_INTERP_START
                    p = p + 1
                    col = col + 1
                    // Lex the interpolated expression until }
                    let mut depth = 1
                    while depth > 0 && p < source.len() {
                        let ic = lpeek(source, p)
                        if ic == CH_RBRACE {
                            depth = depth - 1
                            if depth == 0 {
                                tok_kinds.push(TK_INTERP_END)
                                tok_values.push("")
                                tok_lines.push(line)
                                tok_cols.push(col)
                                last_kind = TK_INTERP_END
                                p = p + 1
                                col = col + 1
                            } else {
                                tok_kinds.push(TK_RBRACE)
                                tok_values.push("}")
                                tok_lines.push(line)
                                tok_cols.push(col)
                                last_kind = TK_RBRACE
                                p = p + 1
                                col = col + 1
                            }
                        } else if ic == CH_LBRACE {
                            depth = depth + 1
                            tok_kinds.push(TK_LBRACE)
                            tok_values.push("\{")
                            tok_lines.push(line)
                            tok_cols.push(col)
                            last_kind = TK_LBRACE
                            p = p + 1
                            col = col + 1
                        } else if is_alpha(ic) {
                            let start = p
                            while p < source.len() && is_alnum(lpeek(source, p)) {
                                p = p + 1
                                col = col + 1
                            }
                            let word = source.substring(start, p - start)
                            let kind = keyword_lookup(word)
                            tok_kinds.push(kind)
                            tok_values.push(word)
                            tok_lines.push(line)
                            tok_cols.push(col)
                            last_kind = kind
                        } else if is_digit(ic) {
                            let start = p
                            while p < source.len() && is_digit(lpeek(source, p)) {
                                p = p + 1
                                col = col + 1
                            }
                            tok_kinds.push(TK_INT)
                            tok_values.push(source.substring(start, p - start))
                            tok_lines.push(line)
                            tok_cols.push(col)
                            last_kind = TK_INT
                        } else if ic == CH_PLUS {
                            tok_kinds.push(TK_PLUS)
                            tok_values.push("+")
                            tok_lines.push(line)
                            tok_cols.push(col)
                            last_kind = TK_PLUS
                            p = p + 1
                            col = col + 1
                        } else if ic == CH_MINUS {
                            tok_kinds.push(TK_MINUS)
                            tok_values.push("-")
                            tok_lines.push(line)
                            tok_cols.push(col)
                            last_kind = TK_MINUS
                            p = p + 1
                            col = col + 1
                        } else if ic == CH_STAR {
                            tok_kinds.push(TK_STAR)
                            tok_values.push("*")
                            tok_lines.push(line)
                            tok_cols.push(col)
                            last_kind = TK_STAR
                            p = p + 1
                            col = col + 1
                        } else if ic == CH_DOT {
                            tok_kinds.push(TK_DOT)
                            tok_values.push(".")
                            tok_lines.push(line)
                            tok_cols.push(col)
                            last_kind = TK_DOT
                            p = p + 1
                            col = col + 1
                        } else if ic == CH_LPAREN {
                            tok_kinds.push(TK_LPAREN)
                            tok_values.push("(")
                            tok_lines.push(line)
                            tok_cols.push(col)
                            last_kind = TK_LPAREN
                            p = p + 1
                            col = col + 1
                        } else if ic == CH_RPAREN {
                            tok_kinds.push(TK_RPAREN)
                            tok_values.push(")")
                            tok_lines.push(line)
                            tok_cols.push(col)
                            last_kind = TK_RPAREN
                            p = p + 1
                            col = col + 1
                        } else if ic == CH_COMMA {
                            tok_kinds.push(TK_COMMA)
                            tok_values.push(",")
                            tok_lines.push(line)
                            tok_cols.push(col)
                            last_kind = TK_COMMA
                            p = p + 1
                            col = col + 1
                        } else if ic == CH_SPACE || ic == CH_TAB {
                            p = p + 1
                            col = col + 1
                        } else {
                            p = p + 1
                            col = col + 1
                        }
                    }
                } else if sc == CH_BACKSLASH {
                    p = p + 2
                    col = col + 2
                    buf = buf + "?"
                } else {
                    buf = buf + source.substring(p, 1)
                    p = p + 1
                    col = col + 1
                }
            }
            continue
        }

        // Identifiers / keywords
        if is_alpha(ch) {
            let t_line = line
            let t_col = col
            let start = p
            while p < source.len() && is_alnum(lpeek(source, p)) {
                p = p + 1
                col = col + 1
            }
            let word = source.substring(start, p - start)
            let kind = keyword_lookup(word)
            tok_kinds.push(kind)
            tok_values.push(word)
            tok_lines.push(t_line)
            tok_cols.push(t_col)
            last_kind = kind
            continue
        }

        // Numbers
        if is_digit(ch) {
            let t_line = line
            let t_col = col
            let start = p
            while p < source.len() && is_digit(lpeek(source, p)) {
                p = p + 1
                col = col + 1
            }
            tok_kinds.push(TK_INT)
            tok_values.push(source.substring(start, p - start))
            tok_lines.push(t_line)
            tok_cols.push(t_col)
            last_kind = TK_INT
            continue
        }

        // Two-char operators
        if ch == CH_MINUS && lpeek(source, p + 1) == CH_GREATER {
            tok_kinds.push(TK_ARROW)
            tok_values.push("->")
            tok_lines.push(line)
            tok_cols.push(col)
            last_kind = TK_ARROW
            p = p + 2
            col = col + 2
            continue
        }
        if ch == CH_EQUALS && lpeek(source, p + 1) == CH_GREATER {
            tok_kinds.push(TK_FAT_ARROW)
            tok_values.push("=>")
            tok_lines.push(line)
            tok_cols.push(col)
            last_kind = TK_FAT_ARROW
            p = p + 2
            col = col + 2
            continue
        }
        if ch == CH_EQUALS && lpeek(source, p + 1) == CH_EQUALS {
            tok_kinds.push(TK_EQEQ)
            tok_values.push("==")
            tok_lines.push(line)
            tok_cols.push(col)
            last_kind = TK_EQEQ
            p = p + 2
            col = col + 2
            continue
        }
        if ch == CH_BANG && lpeek(source, p + 1) == CH_EQUALS {
            tok_kinds.push(TK_NOT_EQ)
            tok_values.push("!=")
            tok_lines.push(line)
            tok_cols.push(col)
            last_kind = TK_NOT_EQ
            p = p + 2
            col = col + 2
            continue
        }
        if ch == CH_LESS && lpeek(source, p + 1) == CH_EQUALS {
            tok_kinds.push(TK_LESS_EQ)
            tok_values.push("<=")
            tok_lines.push(line)
            tok_cols.push(col)
            last_kind = TK_LESS_EQ
            p = p + 2
            col = col + 2
            continue
        }
        if ch == CH_GREATER && lpeek(source, p + 1) == CH_EQUALS {
            tok_kinds.push(TK_GREATER_EQ)
            tok_values.push(">=")
            tok_lines.push(line)
            tok_cols.push(col)
            last_kind = TK_GREATER_EQ
            p = p + 2
            col = col + 2
            continue
        }
        if ch == CH_AMP && lpeek(source, p + 1) == CH_AMP {
            tok_kinds.push(TK_AND)
            tok_values.push("&&")
            tok_lines.push(line)
            tok_cols.push(col)
            last_kind = TK_AND
            p = p + 2
            col = col + 2
            continue
        }
        if ch == CH_PIPE && lpeek(source, p + 1) == CH_PIPE {
            tok_kinds.push(TK_OR)
            tok_values.push("||")
            tok_lines.push(line)
            tok_cols.push(col)
            last_kind = TK_OR
            p = p + 2
            col = col + 2
            continue
        }
        if ch == CH_PIPE && lpeek(source, p + 1) == CH_GREATER {
            tok_kinds.push(TK_PIPE_ARROW)
            tok_values.push("|>")
            tok_lines.push(line)
            tok_cols.push(col)
            last_kind = TK_PIPE_ARROW
            p = p + 2
            col = col + 2
            continue
        }
        if ch == CH_PLUS && lpeek(source, p + 1) == CH_EQUALS {
            tok_kinds.push(TK_PLUS_EQ)
            tok_values.push("+=")
            tok_lines.push(line)
            tok_cols.push(col)
            last_kind = TK_PLUS_EQ
            p = p + 2
            col = col + 2
            continue
        }
        if ch == CH_MINUS && lpeek(source, p + 1) == CH_EQUALS {
            tok_kinds.push(TK_MINUS_EQ)
            tok_values.push("-=")
            tok_lines.push(line)
            tok_cols.push(col)
            last_kind = TK_MINUS_EQ
            p = p + 2
            col = col + 2
            continue
        }
        if ch == CH_STAR && lpeek(source, p + 1) == CH_EQUALS {
            tok_kinds.push(TK_STAR_EQ)
            tok_values.push("*=")
            tok_lines.push(line)
            tok_cols.push(col)
            last_kind = TK_STAR_EQ
            p = p + 2
            col = col + 2
            continue
        }
        if ch == CH_DOT && lpeek(source, p + 1) == CH_DOT {
            if lpeek(source, p + 2) == CH_EQUALS {
                tok_kinds.push(TK_DOTDOTEQ)
                tok_values.push("..=")
                tok_lines.push(line)
                tok_cols.push(col)
                last_kind = TK_DOTDOTEQ
                p = p + 3
                col = col + 3
            } else {
                tok_kinds.push(TK_DOTDOT)
                tok_values.push("..")
                tok_lines.push(line)
                tok_cols.push(col)
                last_kind = TK_DOTDOT
                p = p + 2
                col = col + 2
            }
            continue
        }

        // Single-char tokens
        let t_line = line
        let t_col = col
        if ch == CH_LPAREN {
            tok_kinds.push(TK_LPAREN)
            tok_values.push("(")
        } else if ch == CH_RPAREN {
            tok_kinds.push(TK_RPAREN)
            tok_values.push(")")
        } else if ch == CH_LBRACE {
            tok_kinds.push(TK_LBRACE)
            tok_values.push("\{")
        } else if ch == CH_RBRACE {
            tok_kinds.push(TK_RBRACE)
            tok_values.push("\}")
        } else if ch == CH_LBRACKET {
            tok_kinds.push(TK_LBRACKET)
            tok_values.push("[")
        } else if ch == CH_RBRACKET {
            tok_kinds.push(TK_RBRACKET)
            tok_values.push("]")
        } else if ch == CH_COLON {
            tok_kinds.push(TK_COLON)
            tok_values.push(":")
        } else if ch == CH_COMMA {
            tok_kinds.push(TK_COMMA)
            tok_values.push(",")
        } else if ch == CH_DOT {
            tok_kinds.push(TK_DOT)
            tok_values.push(".")
        } else if ch == CH_PLUS {
            tok_kinds.push(TK_PLUS)
            tok_values.push("+")
        } else if ch == CH_MINUS {
            tok_kinds.push(TK_MINUS)
            tok_values.push("-")
        } else if ch == CH_STAR {
            tok_kinds.push(TK_STAR)
            tok_values.push("*")
        } else if ch == CH_SLASH {
            tok_kinds.push(TK_SLASH)
            tok_values.push("/")
        } else if ch == CH_PERCENT {
            tok_kinds.push(TK_PERCENT)
            tok_values.push("%")
        } else if ch == CH_EQUALS {
            tok_kinds.push(TK_EQUALS)
            tok_values.push("=")
        } else if ch == CH_LESS {
            tok_kinds.push(TK_LESS)
            tok_values.push("<")
        } else if ch == CH_GREATER {
            tok_kinds.push(TK_GREATER)
            tok_values.push(">")
        } else if ch == CH_BANG {
            tok_kinds.push(TK_BANG)
            tok_values.push("!")
        } else if ch == CH_QUESTION {
            tok_kinds.push(TK_QUESTION)
            tok_values.push("?")
        } else if ch == CH_PIPE {
            tok_kinds.push(TK_PIPE)
            tok_values.push("|")
        } else if ch == CH_AT {
            tok_kinds.push(TK_AT)
            tok_values.push("@")
        } else {
            // Unknown — skip
            p = p + 1
            col = col + 1
            continue
        }
        tok_lines.push(t_line)
        tok_cols.push(t_col)
        last_kind = tok_kinds.get(tok_kinds.len() - 1)
        p = p + 1
        col = col + 1
    }

    tok_kinds.push(TK_EOF)
    tok_values.push("")
    tok_lines.push(line)
    tok_cols.push(col)
}


// === codegen.pact ===

// codegen.pact — Self-hosting C code generator for Pact
//
// Minimal subset: enough to compile hello_compiled.pact via the
// Python C backend. Reads the parallel-array AST node pool produced
// by parser.pact and emits C source as a list of strings.
//
// Constraints: same as lexer/parser — parallel arrays, no struct-in-list,
// no closures, no imports. Constants duplicated for self-contained compilation.

// ── C type constants ────────────────────────────────────────────────
// Instead of enums, plain ints.

let CT_INT = 0
let CT_FLOAT = 1
let CT_BOOL = 2
let CT_STRING = 3
let CT_LIST = 4
let CT_VOID = 5

// ── Node pool (extern — set by caller before calling generate) ──────
// These are the same arrays from parser.pact. In the full compiler,
// they will be the SAME globals. For now, duplicated declarations.

let mut np_kind: List[Int] = []
let mut np_int_val: List[Int] = []
let mut np_str_val: List[Str] = []
let mut np_name: List[Str] = []
let mut np_op: List[Str] = []
let mut np_left: List[Int] = []
let mut np_right: List[Int] = []
let mut np_body: List[Int] = []
let mut np_condition: List[Int] = []
let mut np_then_body: List[Int] = []
let mut np_else_body: List[Int] = []
let mut np_scrutinee: List[Int] = []
let mut np_pattern: List[Int] = []
let mut np_guard: List[Int] = []
let mut np_value: List[Int] = []
let mut np_target: List[Int] = []
let mut np_iterable: List[Int] = []
let mut np_var_name: List[Str] = []
let mut np_is_mut: List[Int] = []
let mut np_is_pub: List[Int] = []
let mut np_inclusive: List[Int] = []
let mut np_start: List[Int] = []
let mut np_end: List[Int] = []
let mut np_obj: List[Int] = []
let mut np_method: List[Str] = []
let mut np_index: List[Int] = []
let mut np_return_type: List[Str] = []
let mut np_type_name: List[Str] = []
let mut np_params: List[Int] = []
let mut np_args: List[Int] = []
let mut np_stmts: List[Int] = []
let mut np_arms: List[Int] = []
let mut np_fields: List[Int] = []
let mut np_elements: List[Int] = []

// Sublists (same as parser.pact)
let mut sl_items: List[Int] = []
let mut sl_start: List[Int] = []
let mut sl_len: List[Int] = []


// ── Codegen state ───────────────────────────────────────────────────

let mut cg_lines: List[Str] = []
let mut cg_indent: Int = 0
let mut cg_temp_counter: Int = 0
let mut cg_global_inits: List[Str] = []
let mut struct_reg_names: List[Str] = []
let mut emitted_let_names: List[Str] = []
let mut emitted_fn_names: List[Str] = []

// Scope: parallel lists for variable names, types, and mutability.
// Each scope is a "frame" delimited by frame_starts.
let mut scope_names: List[Str] = []
let mut scope_types: List[Int] = []
let mut scope_muts: List[Int] = []
let mut scope_frame_starts: List[Int] = []

// Function registry: parallel lists (fn name -> return type, param count)
let mut fn_reg_names: List[Str] = []
let mut fn_reg_ret: List[Int] = []
let mut var_list_elem_names: List[Str] = []
let mut var_list_elem_types: List[Int] = []

// Scratch space for tuple match scrutinee temps
let mut match_scrut_strs: List[Str] = []
let mut match_scrut_types: List[Int] = []

fn push_scope() {
    scope_frame_starts.push(scope_names.len())
}

fn pop_scope() {
    let start = scope_frame_starts.get(scope_frame_starts.len() - 1)
    scope_frame_starts.pop()
    while scope_names.len() > start {
        scope_names.pop()
        scope_types.pop()
        scope_muts.pop()
    }
}

fn set_var(name: Str, ctype: Int, is_mut: Int) {
    scope_names.push(name)
    scope_types.push(ctype)
    scope_muts.push(is_mut)
}

fn get_var_type(name: Str) -> Int {
    let mut i = scope_names.len() - 1
    while i >= 0 {
        if scope_names.get(i) == name {
            return scope_types.get(i)
        }
        i = i - 1
    }
    CT_INT
}

fn reg_fn(name: Str, ret: Int) {
    fn_reg_names.push(name)
    fn_reg_ret.push(ret)
}

fn get_fn_ret(name: Str) -> Int {
    let mut i = 0
    while i < fn_reg_names.len() {
        if fn_reg_names.get(i) == name {
            return fn_reg_ret.get(i)
        }
        i = i + 1
    }
    CT_VOID
}

fn set_list_elem_type(name: Str, elem_type: Int) {
    var_list_elem_names.push(name)
    var_list_elem_types.push(elem_type)
}

fn get_list_elem_type(name: Str) -> Int {
    let mut i = 0
    while i < var_list_elem_names.len() {
        if var_list_elem_names.get(i) == name {
            return var_list_elem_types.get(i)
        }
        i = i + 1
    }
    CT_INT
}

fn is_struct_type(name: Str) -> Int {
    let mut i = 0
    while i < struct_reg_names.len() {
        if struct_reg_names.get(i) == name {
            return 1
        }
        i = i + 1
    }
    0
}

fn is_emitted_let(name: Str) -> Int {
    let mut i = 0
    while i < emitted_let_names.len() {
        if emitted_let_names.get(i) == name {
            return 1
        }
        i = i + 1
    }
    0
}

fn is_emitted_fn(name: Str) -> Int {
    let mut i = 0
    while i < emitted_fn_names.len() {
        if emitted_fn_names.get(i) == name {
            return 1
        }
        i = i + 1
    }
    0
}

// ── Helpers ─────────────────────────────────────────────────────────

fn c_type_str(ct: Int) -> Str {
    if ct == CT_INT { "int64_t" }
    else if ct == CT_FLOAT { "double" }
    else if ct == CT_BOOL { "int" }
    else if ct == CT_STRING { "const char*" }
    else if ct == CT_LIST { "pact_list*" }
    else { "void" }
}

fn type_from_name(name: Str) -> Int {
    if name == "Int" { CT_INT }
    else if name == "Str" { CT_STRING }
    else if name == "Float" { CT_FLOAT }
    else if name == "Bool" { CT_BOOL }
    else if name == "List" { CT_LIST }
    else { CT_VOID }
}

fn fresh_temp(prefix: Str) -> Str {
    let n = cg_temp_counter
    cg_temp_counter = cg_temp_counter + 1
    "{prefix}{n}"
}

fn emit_line(line: Str) {
    if line == "" {
        cg_lines.push("")
    } else {
        let mut pad = ""
        let mut i = 0
        while i < cg_indent {
            pad = pad.concat("    ")
            i = i + 1
        }
        cg_lines.push(pad.concat(line))
    }
}

fn join_lines() -> Str {
    let mut result = ""
    let mut i = 0
    while i < cg_lines.len() {
        if i > 0 {
            result = result.concat("\n")
        }
        result = result.concat(cg_lines.get(i))
        i = i + 1
    }
    result
}

// ── Expression codegen ──────────────────────────────────────────────
// Returns (expr_str, type) packed into parallel result slots.
// Since we can't return tuples in the C backend, we use mutable globals.

let mut expr_result_str: Str = ""
let mut expr_result_type: Int = 0

fn emit_expr(node: Int) {
    let kind = np_kind.get(node)

    if kind == ND_INT_LIT {
        let s = np_str_val.get(node)
        if s == "" {
            expr_result_str = "{np_int_val.get(node)}"
        } else {
            expr_result_str = s
        }
        expr_result_type = CT_INT
        return
    }

    if kind == ND_FLOAT_LIT {
        expr_result_str = np_str_val.get(node)
        expr_result_type = CT_FLOAT
        return
    }

    if kind == ND_BOOL_LIT {
        if np_int_val.get(node) != 0 {
            expr_result_str = "1"
        } else {
            expr_result_str = "0"
        }
        expr_result_type = CT_BOOL
        return
    }

    if kind == ND_IDENT {
        let name = np_name.get(node)
        expr_result_str = name
        expr_result_type = get_var_type(name)
        return
    }

    if kind == ND_BIN_OP {
        emit_binop(node)
        return
    }

    if kind == ND_UNARY_OP {
        emit_unaryop(node)
        return
    }

    if kind == ND_CALL {
        emit_call(node)
        return
    }

    if kind == ND_METHOD_CALL {
        emit_method_call(node)
        return
    }

    if kind == ND_INTERP_STRING {
        emit_interp_string(node)
        return
    }

    if kind == ND_IF_EXPR {
        emit_if_expr(node)
        return
    }

    if kind == ND_FIELD_ACCESS {
        emit_expr(np_obj.get(node))
        let obj_str = expr_result_str
        expr_result_str = "{obj_str}.{np_name.get(node)}"
        expr_result_type = CT_VOID
        return
    }

    if kind == ND_INDEX_EXPR {
        emit_expr(np_obj.get(node))
        let obj_str = expr_result_str
        let obj_type = expr_result_type
        emit_expr(np_index.get(node))
        let idx_str = expr_result_str
        if obj_type == CT_STRING {
            expr_result_str = "pact_str_char_at({obj_str}, {idx_str})"
            expr_result_type = CT_INT
        } else {
            expr_result_str = "{obj_str}[{idx_str}]"
            expr_result_type = CT_INT
        }
        return
    }

    if kind == ND_LIST_LIT {
        emit_list_lit(node)
        return
    }

    if kind == ND_RANGE_LIT {
        expr_result_str = "0"
        expr_result_type = CT_VOID
        return
    }

    if kind == ND_MATCH_EXPR {
        emit_match_expr(node)
        return
    }

    if kind == ND_BLOCK {
        emit_block_expr(node)
        return
    }

    if kind == ND_RETURN {
        if np_value.get(node) != -1 {
            emit_expr(np_value.get(node))
            let val_str = expr_result_str
            emit_line("return {val_str};")
        } else {
            emit_line("return;")
        }
        expr_result_str = "0"
        expr_result_type = CT_VOID
        return
    }

    if kind == ND_STRUCT_LIT {
        emit_struct_lit(node)
        return
    }

    expr_result_str = "0"
    expr_result_type = CT_VOID
}

fn emit_binop(node: Int) {
    emit_expr(np_left.get(node))
    let left_str = expr_result_str
    let left_type = expr_result_type
    emit_expr(np_right.get(node))
    let right_str = expr_result_str
    let right_type = expr_result_type
    let op = np_op.get(node)

    if op == "==" && left_type == CT_STRING && right_type == CT_STRING {
        expr_result_str = "pact_str_eq({left_str}, {right_str})"
        expr_result_type = CT_BOOL
        return
    }
    if op == "!=" && left_type == CT_STRING && right_type == CT_STRING {
        expr_result_str = "(!pact_str_eq({left_str}, {right_str}))"
        expr_result_type = CT_BOOL
        return
    }
    if op == "+" && (left_type == CT_STRING || right_type == CT_STRING) {
        expr_result_str = "pact_str_concat({left_str}, {right_str})"
        expr_result_type = CT_STRING
        return
    }

    expr_result_str = "({left_str} {op} {right_str})"
    if op == "==" || op == "!=" || op == "<" || op == ">" || op == "<=" || op == ">=" || op == "&&" || op == "||" {
        expr_result_type = CT_BOOL
    } else {
        expr_result_type = left_type
    }
}

fn emit_unaryop(node: Int) {
    emit_expr(np_left.get(node))
    let operand_str = expr_result_str
    let operand_type = expr_result_type
    let op = np_op.get(node)
    if op == "-" {
        expr_result_str = "(-{operand_str})"
        expr_result_type = operand_type
    } else if op == "!" {
        expr_result_str = "(!{operand_str})"
        expr_result_type = CT_BOOL
    } else {
        expr_result_str = "({op}{operand_str})"
        expr_result_type = operand_type
    }
}

fn emit_call(node: Int) {
    let func_node = np_left.get(node)
    let func_kind = np_kind.get(func_node)
    if func_kind == ND_IDENT {
        let fn_name = np_name.get(func_node)
        let args_sl = np_args.get(node)
        let mut args_str = ""
        if args_sl != -1 {
            let mut i = 0
            while i < sublist_length(args_sl) {
                if i > 0 {
                    args_str = args_str.concat(", ")
                }
                emit_expr(sublist_get(args_sl, i))
                args_str = args_str.concat(expr_result_str)
                i = i + 1
            }
        }
        expr_result_str = "pact_{fn_name}({args_str})"
        expr_result_type = get_fn_ret(fn_name)
        return
    }
    emit_expr(func_node)
    let func_str = expr_result_str
    let args_sl = np_args.get(node)
    let mut args_str = ""
    if args_sl != -1 {
        let mut i = 0
        while i < sublist_length(args_sl) {
            if i > 0 {
                args_str = args_str.concat(", ")
            }
            emit_expr(sublist_get(args_sl, i))
            args_str = args_str.concat(expr_result_str)
            i = i + 1
        }
    }
    expr_result_str = "{func_str}({args_str})"
    expr_result_type = CT_VOID
}

fn emit_method_call(node: Int) {
    let obj_node = np_obj.get(node)
    let method = np_method.get(node)

    // Special case: io.println
    if np_kind.get(obj_node) == ND_IDENT && np_name.get(obj_node) == "io" && method == "println" {
        let args_sl = np_args.get(node)
        if args_sl != -1 && sublist_length(args_sl) > 0 {
            emit_expr(sublist_get(args_sl, 0))
            let arg_str = expr_result_str
            let arg_type = expr_result_type
            if arg_type == CT_INT {
                emit_line("printf(\"%%lld\\n\", (long long){arg_str});")
            } else if arg_type == CT_FLOAT {
                emit_line("printf(\"%%g\\n\", {arg_str});")
            } else if arg_type == CT_BOOL {
                emit_line("printf(\"%%s\\n\", {arg_str} ? \"true\" : \"false\");")
            } else {
                emit_line("printf(\"%%s\\n\", {arg_str});")
            }
        } else {
            emit_line("printf(\"\\n\");")
        }
        expr_result_str = "0"
        expr_result_type = CT_VOID
        return
    }

    emit_expr(obj_node)
    let obj_str = expr_result_str
    let obj_type = expr_result_type

    // String methods
    if obj_type == CT_STRING {
        if method == "len" {
            expr_result_str = "pact_str_len({obj_str})"
            expr_result_type = CT_INT
            return
        }
        if method == "char_at" || method == "charAt" {
            let args_sl = np_args.get(node)
            emit_expr(sublist_get(args_sl, 0))
            let idx_str = expr_result_str
            expr_result_str = "pact_str_char_at({obj_str}, {idx_str})"
            expr_result_type = CT_INT
            return
        }
        if method == "substring" || method == "substr" {
            let args_sl = np_args.get(node)
            emit_expr(sublist_get(args_sl, 0))
            let start_str = expr_result_str
            emit_expr(sublist_get(args_sl, 1))
            let len_str = expr_result_str
            expr_result_str = "pact_str_substr({obj_str}, {start_str}, {len_str})"
            expr_result_type = CT_STRING
            return
        }
        if method == "contains" {
            let args_sl = np_args.get(node)
            emit_expr(sublist_get(args_sl, 0))
            let needle_str = expr_result_str
            expr_result_str = "pact_str_contains({obj_str}, {needle_str})"
            expr_result_type = CT_BOOL
            return
        }
        if method == "starts_with" {
            let args_sl = np_args.get(node)
            emit_expr(sublist_get(args_sl, 0))
            let pfx_str = expr_result_str
            expr_result_str = "pact_str_starts_with({obj_str}, {pfx_str})"
            expr_result_type = CT_BOOL
            return
        }
        if method == "concat" {
            let args_sl = np_args.get(node)
            emit_expr(sublist_get(args_sl, 0))
            let other_str = expr_result_str
            expr_result_str = "pact_str_concat({obj_str}, {other_str})"
            expr_result_type = CT_STRING
            return
        }
    }

    // List methods
    if obj_type == CT_LIST {
        if method == "push" {
            let args_sl = np_args.get(node)
            emit_expr(sublist_get(args_sl, 0))
            let val_str = expr_result_str
            let val_type = expr_result_type
            if val_type == CT_INT {
                emit_line("pact_list_push({obj_str}, (void*)(intptr_t){val_str});")
            } else {
                emit_line("pact_list_push({obj_str}, (void*){val_str});")
            }
            expr_result_str = "0"
            expr_result_type = CT_VOID
            return
        }
        if method == "pop" {
            emit_line("pact_list_pop({obj_str});")
            expr_result_str = "0"
            expr_result_type = CT_VOID
            return
        }
        if method == "len" {
            expr_result_str = "pact_list_len({obj_str})"
            expr_result_type = CT_INT
            return
        }
        if method == "get" {
            let args_sl = np_args.get(node)
            emit_expr(sublist_get(args_sl, 0))
            let idx_str = expr_result_str
            let elem_type = get_list_elem_type(obj_str)
            if elem_type == CT_STRING {
                expr_result_str = "(const char*)pact_list_get({obj_str}, {idx_str})"
                expr_result_type = CT_STRING
            } else {
                expr_result_str = "(int64_t)(intptr_t)pact_list_get({obj_str}, {idx_str})"
                expr_result_type = CT_INT
            }
            return
        }
        if method == "set" {
            let args_sl = np_args.get(node)
            emit_expr(sublist_get(args_sl, 0))
            let idx_str = expr_result_str
            emit_expr(sublist_get(args_sl, 1))
            let val_str2 = expr_result_str
            let val_type2 = expr_result_type
            if val_type2 == CT_INT {
                emit_line("pact_list_set({obj_str}, {idx_str}, (void*)(intptr_t){val_str2});")
            } else {
                emit_line("pact_list_set({obj_str}, {idx_str}, (void*){val_str2});")
            }
            expr_result_str = "0"
            expr_result_type = CT_VOID
            return
        }
    }

    // Generic fallback
    let args_sl = np_args.get(node)
    let mut args_str = ""
    if args_sl != -1 {
        let mut i = 0
        while i < sublist_length(args_sl) {
            if i > 0 {
                args_str = args_str.concat(", ")
            }
            emit_expr(sublist_get(args_sl, i))
            args_str = args_str.concat(expr_result_str)
            i = i + 1
        }
    }
    expr_result_str = "{obj_str}_{method}({args_str})"
    expr_result_type = CT_VOID
}

fn escape_c_string(s: Str) -> Str {
    let mut result = ""
    let mut i = 0
    while i < s.len() {
        let ch = s.char_at(i)
        if ch == 92 {
            result = result.concat("\\\\")
        } else if ch == 34 {
            result = result.concat("\\\"")
        } else if ch == 10 {
            result = result.concat("\\n")
        } else if ch == 9 {
            result = result.concat("\\t")
        } else {
            result = result.concat(s.substring(i, 1))
        }
        i = i + 1
    }
    result
}

fn emit_interp_string(node: Int) {
    let parts_sl = np_elements.get(node)
    if parts_sl == -1 {
        expr_result_str = "\"\""
        expr_result_type = CT_STRING
        return
    }

    // Fast path: if all parts are literal, emit a simple string constant
    let mut all_literal = 1
    let mut ai = 0
    while ai < sublist_length(parts_sl) {
        let part = sublist_get(parts_sl, ai)
        let pk = np_kind.get(part)
        if !(pk == ND_IDENT && np_str_val.get(part) == np_name.get(part)) {
            all_literal = 0
        }
        ai = ai + 1
    }
    if all_literal != 0 {
        let mut concat_str = ""
        let mut ci = 0
        while ci < sublist_length(parts_sl) {
            let part = sublist_get(parts_sl, ci)
            concat_str = concat_str.concat(escape_c_string(np_str_val.get(part)))
            ci = ci + 1
        }
        expr_result_str = "\"".concat(concat_str).concat("\"")
        expr_result_type = CT_STRING
        return
    }

    // Slow path: use snprintf for strings with expression parts
    let buf_name = fresh_temp("_si_")
    emit_line("char {buf_name}[4096];")
    let mut fmt = ""
    let mut args = ""
    let mut has_args = 0
    let mut i = 0
    while i < sublist_length(parts_sl) {
        let part = sublist_get(parts_sl, i)
        let pk = np_kind.get(part)
        // Literal string parts: parser stores them as ND_IDENT with str_val == name
        // Expression parts: ND_IDENT with str_val == "" (or other node kinds)
        if pk == ND_IDENT && np_str_val.get(part) == np_name.get(part) {
            fmt = fmt.concat(escape_c_string(np_str_val.get(part)))
        } else {
            // Expression part
            emit_expr(part)
            let e_str = expr_result_str
            let e_type = expr_result_type
            if e_type == CT_INT {
                fmt = fmt.concat("%lld")
                if has_args {
                    args = args.concat(", ")
                }
                args = args.concat("(long long)")
                args = args.concat(e_str)
                has_args = 1
            } else if e_type == CT_FLOAT {
                fmt = fmt.concat("%g")
                if has_args {
                    args = args.concat(", ")
                }
                args = args.concat(e_str)
                has_args = 1
            } else if e_type == CT_BOOL {
                fmt = fmt.concat("%s")
                if has_args {
                    args = args.concat(", ")
                }
                args = args.concat(e_str)
                args = args.concat(" ? \"true\" : \"false\"")
                has_args = 1
            } else {
                fmt = fmt.concat("%s")
                if has_args {
                    args = args.concat(", ")
                }
                args = args.concat(e_str)
                has_args = 1
            }
        }
        i = i + 1
    }
    if has_args {
        let line = "snprintf(".concat(buf_name).concat(", 4096, \"").concat(fmt).concat("\", ").concat(args).concat(");")
        emit_line(line)
    } else {
        let line = "snprintf(".concat(buf_name).concat(", 4096, \"").concat(fmt).concat("\");")
        emit_line(line)
    }
    expr_result_str = "strdup(".concat(buf_name).concat(")")
    expr_result_type = CT_STRING
}

fn emit_list_lit(node: Int) {
    let tmp = fresh_temp("_l")
    emit_line("pact_list* {tmp} = pact_list_new();")
    let elems_sl = np_elements.get(node)
    if elems_sl != -1 {
        let mut i = 0
        while i < sublist_length(elems_sl) {
            emit_expr(sublist_get(elems_sl, i))
            let e_str = expr_result_str
            let e_type = expr_result_type
            if e_type == CT_INT {
                emit_line("pact_list_push({tmp}, (void*)(intptr_t){e_str});")
            } else {
                emit_line("pact_list_push({tmp}, (void*){e_str});")
            }
            i = i + 1
        }
    }
    expr_result_str = tmp
    expr_result_type = CT_LIST
}

fn emit_struct_lit(node: Int) {
    let sname = np_type_name.get(node)
    let c_type = "pact_{sname}"
    let tmp = fresh_temp("_s")
    let flds_sl = np_fields.get(node)
    let mut inits = ""
    if flds_sl != -1 {
        let mut i = 0
        while i < sublist_length(flds_sl) {
            let sf = sublist_get(flds_sl, i)
            let fname = np_name.get(sf)
            emit_expr(np_value.get(sf))
            let val_str = expr_result_str
            if i > 0 {
                inits = inits.concat(", ")
            }
            inits = inits.concat(".{fname} = {val_str}")
            i = i + 1
        }
    }
    emit_line("{c_type} {tmp} = \{ {inits} };")
    expr_result_str = tmp
    expr_result_type = CT_VOID
}

fn emit_if_expr(node: Int) {
    let tmp = fresh_temp("_if_")
    // Infer type from then branch
    let then_type = infer_block_type(np_then_body.get(node))
    emit_line("{c_type_str(then_type)} {tmp};")
    emit_expr(np_condition.get(node))
    let cond_str = expr_result_str
    emit_line("if ({cond_str}) \{")
    cg_indent = cg_indent + 1
    let then_val = emit_block_value(np_then_body.get(node))
    emit_line("{tmp} = {then_val};")
    cg_indent = cg_indent - 1
    if np_else_body.get(node) != -1 {
        emit_line("} else \{")
        cg_indent = cg_indent + 1
        let else_val = emit_block_value(np_else_body.get(node))
        emit_line("{tmp} = {else_val};")
        cg_indent = cg_indent - 1
    }
    emit_line("}")
    set_var(tmp, then_type, 1)
    expr_result_str = tmp
    expr_result_type = then_type
}

fn emit_match_expr(node: Int) {
    let scrut = np_scrutinee.get(node)

    // Build list of scrutinee values (multiple if tuple literal)
    match_scrut_strs = []
    match_scrut_types = []

    if np_kind.get(scrut) == ND_TUPLE_LIT {
        let elems_sl = np_elements.get(scrut)
        if elems_sl != -1 {
            let mut ei = 0
            while ei < sublist_length(elems_sl) {
                emit_expr(sublist_get(elems_sl, ei))
                let tmp = fresh_temp("_tup_")
                emit_line("{c_type_str(expr_result_type)} {tmp} = {expr_result_str};")
                set_var(tmp, expr_result_type, 1)
                match_scrut_strs.push(tmp)
                match_scrut_types.push(expr_result_type)
                ei = ei + 1
            }
        }
    } else {
        emit_expr(scrut)
        match_scrut_strs.push(expr_result_str)
        match_scrut_types.push(expr_result_type)
    }

    let arms_sl = np_arms.get(node)
    if arms_sl == -1 {
        expr_result_str = "0"
        expr_result_type = CT_VOID
        return
    }

    let first_arm = sublist_get(arms_sl, 0)
    let result_type = infer_arm_type(first_arm)
    let result_var = fresh_temp("_match_")
    emit_line("{c_type_str(result_type)} {result_var};")

    let mut first = 1
    let mut i = 0
    while i < sublist_length(arms_sl) {
        let arm = sublist_get(arms_sl, i)
        let pat = np_pattern.get(arm)

        let cond = pattern_condition(pat, 0, match_scrut_strs.len())
        let is_wildcard = cond == ""

        if is_wildcard {
            if first {
                emit_line("\{")
            } else {
                emit_line("} else \{")
            }
        } else if first {
            emit_line("if ({cond}) \{")
        } else {
            emit_line("} else if ({cond}) \{")
        }

        cg_indent = cg_indent + 1
        bind_pattern_vars(pat, 0, match_scrut_strs.len())
        let arm_val = emit_arm_value(np_body.get(arm))
        emit_line("{result_var} = {arm_val};")
        cg_indent = cg_indent - 1

        first = 0
        i = i + 1
    }
    emit_line("}")
    set_var(result_var, result_type, 1)
    expr_result_str = result_var
    expr_result_type = result_type
}

// Build a C condition string for a pattern.
// scrut_off/scrut_len index into match_scrut_strs/match_scrut_types.
// Returns "" when the pattern always matches (wildcard/ident).
fn pattern_condition(pat: Int, scrut_off: Int, scrut_len: Int) -> Str {
    let pk = np_kind.get(pat)
    if pk == ND_WILDCARD_PATTERN || pk == ND_IDENT_PATTERN {
        return ""
    }
    if pk == ND_INT_PATTERN {
        let pat_val = np_str_val.get(pat)
        return "({match_scrut_strs.get(scrut_off)} == {pat_val})"
    }
    if pk == ND_TUPLE_PATTERN {
        let elems_sl = np_elements.get(pat)
        if elems_sl == -1 {
            return ""
        }
        let mut parts = ""
        let mut parts_n = 0
        let mut j = 0
        while j < sublist_length(elems_sl) {
            let sub_pat = sublist_get(elems_sl, j)
            let sub_cond = pattern_condition(sub_pat, scrut_off + j, 1)
            if sub_cond != "" {
                if parts_n > 0 {
                    parts = parts.concat(" && ")
                }
                parts = parts.concat(sub_cond)
                parts_n = parts_n + 1
            }
            j = j + 1
        }
        return parts
    }
    ""
}

// Emit C variable bindings for ident sub-patterns within a pattern.
// scrut_off/scrut_len index into match_scrut_strs/match_scrut_types.
fn bind_pattern_vars(pat: Int, scrut_off: Int, scrut_len: Int) {
    let pk = np_kind.get(pat)
    if pk == ND_IDENT_PATTERN {
        if scrut_len == 1 {
            let bind_name = np_name.get(pat)
            let st = match_scrut_types.get(scrut_off)
            emit_line("{c_type_str(st)} {bind_name} = {match_scrut_strs.get(scrut_off)};")
            set_var(bind_name, st, 1)
        }
        return
    }
    if pk == ND_TUPLE_PATTERN {
        let elems_sl = np_elements.get(pat)
        if elems_sl != -1 {
            let mut j = 0
            while j < sublist_length(elems_sl) {
                let sub_pat = sublist_get(elems_sl, j)
                bind_pattern_vars(sub_pat, scrut_off + j, 1)
                j = j + 1
            }
        }
        return
    }
}

fn emit_block_expr(node: Int) {
    let stmts_sl = np_stmts.get(node)
    if stmts_sl == -1 {
        expr_result_str = "0"
        expr_result_type = CT_VOID
        return
    }
    let count = sublist_length(stmts_sl)
    let mut i = 0
    while i < count - 1 {
        emit_stmt(sublist_get(stmts_sl, i))
        i = i + 1
    }
    if count > 0 {
        let last = sublist_get(stmts_sl, count - 1)
        let last_kind = np_kind.get(last)
        if last_kind == ND_EXPR_STMT {
            emit_expr(np_value.get(last))
            return
        }
        emit_stmt(last)
    }
    expr_result_str = "0"
    expr_result_type = CT_VOID
}

fn emit_arm_value(body: Int) -> Str {
    if body == -1 {
        return "0"
    }
    let kind = np_kind.get(body)
    if kind == ND_BLOCK {
        return emit_block_value(body)
    }
    if kind == ND_EXPR_STMT {
        emit_expr(np_value.get(body))
        return expr_result_str
    }
    emit_expr(body)
    expr_result_str
}

fn emit_block_value(block: Int) -> Str {
    if block == -1 {
        return "0"
    }
    let stmts_sl = np_stmts.get(block)
    if stmts_sl == -1 {
        return "0"
    }
    let count = sublist_length(stmts_sl)
    if count == 0 {
        return "0"
    }
    let mut i = 0
    while i < count - 1 {
        emit_stmt(sublist_get(stmts_sl, i))
        i = i + 1
    }
    let last = sublist_get(stmts_sl, count - 1)
    let last_kind = np_kind.get(last)
    if last_kind == ND_EXPR_STMT {
        emit_expr(np_value.get(last))
        return expr_result_str
    }
    if last_kind == ND_IF_EXPR {
        emit_if_expr(last)
        return expr_result_str
    }
    if last_kind == ND_RETURN {
        if np_value.get(last) != -1 {
            emit_expr(np_value.get(last))
            let val_s = expr_result_str
            emit_line("return {val_s};")
        } else {
            emit_line("return;")
        }
        return "0"
    }
    emit_stmt(last)
    "0"
}

fn infer_block_type(block: Int) -> Int {
    if block == -1 {
        return CT_VOID
    }
    let stmts_sl = np_stmts.get(block)
    if stmts_sl == -1 {
        return CT_VOID
    }
    let count = sublist_length(stmts_sl)
    if count == 0 {
        return CT_VOID
    }
    let last = sublist_get(stmts_sl, count - 1)
    let last_kind = np_kind.get(last)
    if last_kind == ND_EXPR_STMT {
        return infer_expr_type(np_value.get(last))
    }
    CT_VOID
}

fn infer_arm_type(arm: Int) -> Int {
    let body = np_body.get(arm)
    if body == -1 {
        return CT_VOID
    }
    let kind = np_kind.get(body)
    if kind == ND_BLOCK {
        return infer_block_type(body)
    }
    if kind == ND_EXPR_STMT {
        return infer_expr_type(np_value.get(body))
    }
    infer_expr_type(body)
}

fn infer_expr_type(node: Int) -> Int {
    if node == -1 {
        return CT_VOID
    }
    let kind = np_kind.get(node)
    if kind == ND_INT_LIT { return CT_INT }
    if kind == ND_FLOAT_LIT { return CT_FLOAT }
    if kind == ND_BOOL_LIT { return CT_BOOL }
    if kind == ND_INTERP_STRING { return CT_STRING }
    if kind == ND_LIST_LIT { return CT_LIST }
    if kind == ND_IDENT {
        return get_var_type(np_name.get(node))
    }
    if kind == ND_CALL {
        let func_node = np_left.get(node)
        if np_kind.get(func_node) == ND_IDENT {
            return get_fn_ret(np_name.get(func_node))
        }
    }
    if kind == ND_BIN_OP {
        let op = np_op.get(node)
        if op == "==" || op == "!=" || op == "<" || op == ">" || op == "<=" || op == ">=" || op == "&&" || op == "||" {
            return CT_BOOL
        }
        return infer_expr_type(np_left.get(node))
    }
    CT_VOID
}

// ── Statement codegen ───────────────────────────────────────────────

fn emit_stmt(node: Int) {
    let kind = np_kind.get(node)

    if kind == ND_EXPR_STMT {
        emit_expr(np_value.get(node))
        let s = expr_result_str
        if s != "" && s != "0" {
            emit_line("{s};")
        }
        return
    }

    if kind == ND_LET_BINDING {
        emit_let_binding(node)
        return
    }

    if kind == ND_ASSIGNMENT {
        emit_expr(np_target.get(node))
        let target_str = expr_result_str
        emit_expr(np_value.get(node))
        let val_str = expr_result_str
        emit_line("{target_str} = {val_str};")
        return
    }

    if kind == ND_COMPOUND_ASSIGN {
        emit_expr(np_target.get(node))
        let target_str = expr_result_str
        emit_expr(np_value.get(node))
        let val_str = expr_result_str
        let op = np_op.get(node)
        emit_line("{target_str} {op}= {val_str};")
        return
    }

    if kind == ND_RETURN {
        if np_value.get(node) != -1 {
            emit_expr(np_value.get(node))
            let val_str = expr_result_str
            emit_line("return {val_str};")
        } else {
            emit_line("return;")
        }
        return
    }

    if kind == ND_FOR_IN {
        emit_for_in(node)
        return
    }

    if kind == ND_WHILE_LOOP {
        emit_expr(np_condition.get(node))
        let cond_str = expr_result_str
        emit_line("while ({cond_str}) \{")
        cg_indent = cg_indent + 1
        emit_block(np_body.get(node))
        cg_indent = cg_indent - 1
        emit_line("}")
        return
    }

    if kind == ND_LOOP_EXPR {
        emit_line("while (1) \{")
        cg_indent = cg_indent + 1
        emit_block(np_body.get(node))
        cg_indent = cg_indent - 1
        emit_line("}")
        return
    }

    if kind == ND_BREAK {
        emit_line("break;")
        return
    }

    if kind == ND_CONTINUE {
        emit_line("continue;")
        return
    }

    if kind == ND_IF_EXPR {
        emit_if_stmt(node)
        return
    }

    if kind == ND_MATCH_EXPR {
        emit_match_expr(node)
        return
    }

    // Fallback: treat as expression
    emit_expr(node)
    let s = expr_result_str
    if s != "" {
        emit_line("{s};")
    }
}

fn emit_let_binding(node: Int) {
    emit_expr(np_value.get(node))
    let val_str = expr_result_str
    let val_type = expr_result_type
    let name = np_name.get(node)
    let is_mut = np_is_mut.get(node)
    set_var(name, val_type, is_mut)
    let type_ann = np_target.get(node)
    if val_type == CT_LIST && type_ann != -1 {
        let ann_name = np_name.get(type_ann)
        if ann_name == "List" {
            let elems_sl = np_elements.get(type_ann)
            if elems_sl != -1 && sublist_length(elems_sl) > 0 {
                let elem_ann = sublist_get(elems_sl, 0)
                let elem_name = np_name.get(elem_ann)
                set_list_elem_type(name, type_from_name(elem_name))
            }
        }
    }
    let ts = c_type_str(val_type)
    if is_mut != 0 || val_type == CT_STRING {
        emit_line("{ts} {name} = {val_str};")
    } else {
        emit_line("const {ts} {name} = {val_str};")
    }
}

fn emit_for_in(node: Int) {
    let var_name = np_var_name.get(node)
    let iter_node = np_iterable.get(node)
    let iter_kind = np_kind.get(iter_node)

    if iter_kind == ND_RANGE_LIT {
        emit_expr(np_start.get(iter_node))
        let start_str = expr_result_str
        emit_expr(np_end.get(iter_node))
        let end_str = expr_result_str
        let mut op = "<"
        if np_inclusive.get(iter_node) != 0 {
            op = "<="
        }
        emit_line("for (int64_t {var_name} = {start_str}; {var_name} {op} {end_str}; {var_name}++) \{")
        push_scope()
        set_var(var_name, CT_INT, 1)
        cg_indent = cg_indent + 1
        emit_block(np_body.get(node))
        cg_indent = cg_indent - 1
        pop_scope()
        emit_line("}")
    } else {
        emit_expr(iter_node)
        let iter_str = expr_result_str
        let iter_type = expr_result_type
        if iter_type == CT_LIST {
            let idx = fresh_temp("_i")
            emit_line("for (int64_t {idx} = 0; {idx} < pact_list_len({iter_str}); {idx}++) \{")
            push_scope()
            emit_line("    int64_t {var_name} = (int64_t)(intptr_t)pact_list_get({iter_str}, {idx});")
            set_var(var_name, CT_INT, 0)
            cg_indent = cg_indent + 1
            emit_block(np_body.get(node))
            cg_indent = cg_indent - 1
            pop_scope()
            emit_line("}")
        } else {
            emit_line("/* unsupported iterable */")
        }
    }
}

fn emit_if_stmt(node: Int) {
    emit_expr(np_condition.get(node))
    let cond_str = expr_result_str
    emit_line("if ({cond_str}) \{")
    cg_indent = cg_indent + 1
    emit_block(np_then_body.get(node))
    cg_indent = cg_indent - 1
    if np_else_body.get(node) != -1 {
        let else_b = np_else_body.get(node)
        let else_stmts = np_stmts.get(else_b)
        // Check for else-if chain
        if else_stmts != -1 && sublist_length(else_stmts) == 1 {
            let inner = sublist_get(else_stmts, 0)
            if np_kind.get(inner) == ND_IF_EXPR {
                let saved_lines2 = cg_lines
                cg_lines = []
                emit_expr(np_condition.get(inner))
                let hoisted_lines = cg_lines
                cg_lines = saved_lines2
                if hoisted_lines.len() > 0 {
                    emit_line("} else \{")
                    cg_indent = cg_indent + 1
                    emit_if_stmt(inner)
                    cg_indent = cg_indent - 1
                } else {
                    let inner_cond = expr_result_str
                    emit_line("} else if ({inner_cond}) \{")
                    cg_indent = cg_indent + 1
                    emit_block(np_then_body.get(inner))
                    cg_indent = cg_indent - 1
                    if np_else_body.get(inner) != -1 {
                        emit_line("} else \{")
                        cg_indent = cg_indent + 1
                        emit_block(np_else_body.get(inner))
                        cg_indent = cg_indent - 1
                    }
                }
                emit_line("}")
                return
            }
        }
        emit_line("} else \{")
        cg_indent = cg_indent + 1
        emit_block(else_b)
        cg_indent = cg_indent - 1
    }
    emit_line("}")
}

fn emit_block(block: Int) {
    if block == -1 {
        return
    }
    let stmts_sl = np_stmts.get(block)
    if stmts_sl == -1 {
        return
    }
    let mut i = 0
    while i < sublist_length(stmts_sl) {
        emit_stmt(sublist_get(stmts_sl, i))
        i = i + 1
    }
}

// ── Function codegen ────────────────────────────────────────────────

fn format_params(fn_node: Int) -> Str {
    let params_sl = np_params.get(fn_node)
    if params_sl == -1 {
        return "void"
    }
    let count = sublist_length(params_sl)
    if count == 0 {
        return "void"
    }
    let mut result = ""
    let mut i = 0
    while i < count {
        let p = sublist_get(params_sl, i)
        let pname = np_name.get(p)
        let ptype = np_type_name.get(p)
        let ct = type_from_name(ptype)
        if i > 0 {
            result = result.concat(", ")
        }
        result = result.concat("{c_type_str(ct)} {pname}")
        i = i + 1
    }
    result
}

fn emit_fn_decl(fn_node: Int) {
    let name = np_name.get(fn_node)
    if name == "main" {
        emit_line("void pact_main(void);")
        return
    }
    let ret_str = np_return_type.get(fn_node)
    let ret_type = type_from_name(ret_str)
    let params = format_params(fn_node)
    emit_line("{c_type_str(ret_type)} pact_{name}({params});")
}

fn emit_fn_def(fn_node: Int) {
    push_scope()
    cg_temp_counter = 0
    let name = np_name.get(fn_node)
    let ret_str = np_return_type.get(fn_node)
    let ret_type = type_from_name(ret_str)
    let mut sig = ""
    if name == "main" {
        sig = "void pact_main(void)"
    } else {
        let params = format_params(fn_node)
        sig = "{c_type_str(ret_type)} pact_{name}({params})"
    }

    // Register params in scope
    let params_sl = np_params.get(fn_node)
    if params_sl != -1 {
        let mut i = 0
        while i < sublist_length(params_sl) {
            let p = sublist_get(params_sl, i)
            let pname = np_name.get(p)
            let ptype = np_type_name.get(p)
            set_var(pname, type_from_name(ptype), 1)
            i = i + 1
        }
    }

    emit_line("{sig} \{")
    cg_indent = cg_indent + 1
    emit_fn_body(np_body.get(fn_node), ret_type)
    cg_indent = cg_indent - 1
    emit_line("}")
    pop_scope()
}

fn emit_fn_body(block: Int, ret_type: Int) {
    if block == -1 {
        return
    }
    let stmts_sl = np_stmts.get(block)
    if stmts_sl == -1 {
        return
    }
    let count = sublist_length(stmts_sl)
    if count == 0 {
        return
    }
    let mut i = 0
    while i < count - 1 {
        emit_stmt(sublist_get(stmts_sl, i))
        i = i + 1
    }
    let last = sublist_get(stmts_sl, count - 1)
    let last_kind = np_kind.get(last)
    if ret_type != CT_VOID && last_kind == ND_EXPR_STMT {
        emit_expr(np_value.get(last))
        let val_str = expr_result_str
        emit_line("return {val_str};")
    } else if ret_type != CT_VOID && last_kind == ND_IF_EXPR {
        emit_if_expr(last)
        let val_str = expr_result_str
        emit_line("return {val_str};")
    } else {
        emit_stmt(last)
    }
}

// ── Type definition codegen ─────────────────────────────────────────

fn emit_struct_typedef(td_node: Int) {
    let name = np_name.get(td_node)
    let flds_sl = np_fields.get(td_node)
    if flds_sl == -1 {
        return
    }
    // Check if this is a variant-only type (enum), skip for now
    if sublist_length(flds_sl) > 0 {
        let first = sublist_get(flds_sl, 0)
        if np_kind.get(first) == ND_TYPE_VARIANT {
            return
        }
    }
    emit_line("typedef struct \{")
    cg_indent = cg_indent + 1
    let mut i = 0
    while i < sublist_length(flds_sl) {
        let f = sublist_get(flds_sl, i)
        let fname = np_name.get(f)
        let type_ann_node = np_value.get(f)
        if type_ann_node != -1 {
            let type_name = np_name.get(type_ann_node)
            if type_name == name {
                emit_line("int64_t {fname};")
            } else if is_struct_type(type_name) != 0 {
                emit_line("pact_{type_name} {fname};")
            } else {
                let ct = type_from_name(type_name)
                emit_line("{c_type_str(ct)} {fname};")
            }
        } else {
            emit_line("int64_t {fname};")
        }
        i = i + 1
    }
    cg_indent = cg_indent - 1
    emit_line("} pact_{name};")
    emit_line("")
}

// ── Top-level: generate ─────────────────────────────────────────────

fn emit_top_level_let(node: Int) {
    let saved_lines = cg_lines
    cg_lines = []
    emit_expr(np_value.get(node))
    let val_str = expr_result_str
    let val_type = expr_result_type
    let helper_lines = cg_lines
    cg_lines = saved_lines
    let name = np_name.get(node)
    let is_mut = np_is_mut.get(node)
    set_var(name, val_type, is_mut)
    // Track list element type from annotation
    let type_ann = np_target.get(node)
    if val_type == CT_LIST && type_ann != -1 {
        let ann_name = np_name.get(type_ann)
        if ann_name == "List" {
            let elems_sl = np_elements.get(type_ann)
            if elems_sl != -1 && sublist_length(elems_sl) > 0 {
                let elem_ann = sublist_get(elems_sl, 0)
                let elem_name = np_name.get(elem_ann)
                set_list_elem_type(name, type_from_name(elem_name))
            }
        }
    }
    let ts = c_type_str(val_type)
    let needs_init = helper_lines.len() > 0 || val_type == CT_LIST
    if needs_init {
        emit_line("static {ts} {name};")
        let mut hi = 0
        while hi < helper_lines.len() {
            cg_global_inits.push(helper_lines.get(hi))
            hi = hi + 1
        }
        cg_global_inits.push("    {name} = {val_str};")
    } else if is_mut != 0 {
        emit_line("static {ts} {name} = {val_str};")
    } else {
        emit_line("static const {ts} {name} = {val_str};")
    }
}

fn generate(program: Int) -> Str {
    // Reset state
    cg_lines = []
    cg_indent = 0
    cg_temp_counter = 0
    scope_names = []
    scope_types = []
    scope_muts = []
    scope_frame_starts = []
    fn_reg_names = []
    fn_reg_ret = []
    cg_global_inits = []
    var_list_elem_names = []
    var_list_elem_types = []
    struct_reg_names = []
    emitted_let_names = []
    emitted_fn_names = []

    push_scope()

    // Register builtins
    reg_fn("arg_count", CT_INT)
    reg_fn("get_arg", CT_STRING)
    reg_fn("read_file", CT_STRING)
    reg_fn("write_file", CT_VOID)

    // Preamble: include runtime
    cg_lines.push("#include \"runtime.h\"")
    cg_lines.push("")

    // Register struct names first
    let types_sl = np_fields.get(program)
    if types_sl != -1 {
        let mut i = 0
        while i < sublist_length(types_sl) {
            struct_reg_names.push(np_name.get(sublist_get(types_sl, i)))
            i = i + 1
        }
    }

    // Type definitions (structs)
    if types_sl != -1 {
        let mut i = 0
        while i < sublist_length(types_sl) {
            emit_struct_typedef(sublist_get(types_sl, i))
            i = i + 1
        }
    }

    // Top-level let bindings (deduplicated)
    let lets_sl = np_stmts.get(program)
    if lets_sl != -1 {
        let mut i = 0
        while i < sublist_length(lets_sl) {
            let let_node = sublist_get(lets_sl, i)
            let let_name = np_name.get(let_node)
            if is_emitted_let(let_name) == 0 {
                emit_top_level_let(let_node)
                emitted_let_names.push(let_name)
            }
            i = i + 1
        }
        emit_line("")
    }

    // Register all functions first (deduplicated)
    let fns_sl = np_params.get(program)
    if fns_sl != -1 {
        let mut i = 0
        while i < sublist_length(fns_sl) {
            let fn_node = sublist_get(fns_sl, i)
            let fn_name = np_name.get(fn_node)
            if is_emitted_fn(fn_name) == 0 {
                let ret_str = np_return_type.get(fn_node)
                reg_fn(fn_name, type_from_name(ret_str))
                emitted_fn_names.push(fn_name)
            }
            i = i + 1
        }
    }

    // Forward declarations (deduplicated)
    emitted_fn_names = []
    if fns_sl != -1 {
        let mut i = 0
        while i < sublist_length(fns_sl) {
            let fn_node = sublist_get(fns_sl, i)
            let fn_name = np_name.get(fn_node)
            if is_emitted_fn(fn_name) == 0 {
                emit_fn_decl(fn_node)
                emitted_fn_names.push(fn_name)
            }
            i = i + 1
        }
    }
    emit_line("")

    // Function definitions (deduplicated)
    emitted_fn_names = []
    if fns_sl != -1 {
        let mut i = 0
        while i < sublist_length(fns_sl) {
            let fn_node = sublist_get(fns_sl, i)
            let fn_name = np_name.get(fn_node)
            if is_emitted_fn(fn_name) == 0 {
                emit_fn_def(fn_node)
                emit_line("")
                emitted_fn_names.push(fn_name)
            }
            i = i + 1
        }
    }

    // Global init function (if needed)
    if cg_global_inits.len() > 0 {
        emit_line("static void __pact_init_globals(void) \{")
        let mut gi = 0
        while gi < cg_global_inits.len() {
            cg_lines.push(cg_global_inits.get(gi))
            gi = gi + 1
        }
        emit_line("}")
        emit_line("")
    }

    // C main wrapper
    emit_line("int main(int argc, char** argv) \{")
    cg_indent = cg_indent + 1
    emit_line("pact_g_argc = argc;")
    emit_line("pact_g_argv = (const char**)argv;")
    if cg_global_inits.len() > 0 {
        emit_line("__pact_init_globals();")
    }
    emit_line("pact_main();")
    emit_line("return 0;")
    cg_indent = cg_indent - 1
    emit_line("}")

    pop_scope()

    join_lines()
}


// === compiler.pact (entry point) ===

// compiler.pact — Self-hosting Pact compiler driver
//
// Ties together lexer, parser, and codegen into a complete compiler.
// Reads a .pact source file, lexes, parses, generates C, and writes output.
//
// Usage (once compiled): ./pactc <source.pact> [output.c]
// If no output file given, writes to stdout.


fn main() {
    if arg_count() < 2 {
        io.println("Usage: pactc <source.pact> [output.c]")
        io.println("  Compiles a Pact source file to C.")
        return
    }

    let source_path = get_arg(1)
    let source = read_file(source_path)

    lex(source)
    let program_node = parse_program()
    let c_output = generate(program_node)

    if arg_count() >= 3 {
        let out_path = get_arg(2)
        write_file(out_path, c_output)
    } else {
        io.println(c_output)
    }
}
