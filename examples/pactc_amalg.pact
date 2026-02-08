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
type TokenKind {
    Fn, Let, Mut, Type, Trait, Impl, If, Else,
    Match, For, In, While, Loop, Break, Continue, Return,
    Pub, With, Handler, Self, Test, Import, As, Mod,
    Assert, AssertEq, AssertNe, Ident, Int, Float, StringStart, StringEnd,
    StringPart, InterpStart, InterpEnd, LParen, RParen, LBrace, RBrace, LBracket,
    RBracket, Colon, Comma, Dot, DotDot, DotDoteq, Arrow, FatArrow,
    At, Plus, Minus, Star, Slash, Percent, Equals, EqEq,
    NotEq, Less, Greater, LessEq, GreaterEq, And, Or, Bang,
    Question, DoubleQuestion, Pipe, PipeArrow, PlusEq, MinusEq, StarEq, SlashEq,
    Newline, EOF,
}

// -- Assertions --

// -- Literals and identifiers --

// -- String interpolation tokens --

// -- Delimiters --

// -- Punctuation --

// -- Operators --

// -- Compound assignment --

// -- Structural --

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
    if kind == TokenKind.Fn { "fn" }
    else if kind == TokenKind.Let { "let" }
    else if kind == TokenKind.Mut { "mut" }
    else if kind == TokenKind.Type { "type" }
    else if kind == TokenKind.Trait { "trait" }
    else if kind == TokenKind.Impl { "impl" }
    else if kind == TokenKind.If { "if" }
    else if kind == TokenKind.Else { "else" }
    else if kind == TokenKind.Match { "match" }
    else if kind == TokenKind.For { "for" }
    else if kind == TokenKind.In { "in" }
    else if kind == TokenKind.While { "while" }
    else if kind == TokenKind.Loop { "loop" }
    else if kind == TokenKind.Break { "break" }
    else if kind == TokenKind.Continue { "continue" }
    else if kind == TokenKind.Return { "return" }
    else if kind == TokenKind.Pub { "pub" }
    else if kind == TokenKind.With { "with" }
    else if kind == TokenKind.Handler { "handler" }
    else if kind == TokenKind.Self { "self" }
    else if kind == TokenKind.Test { "test" }
    else if kind == TokenKind.Import { "import" }
    else if kind == TokenKind.As { "as" }
    else if kind == TokenKind.Mod { "mod" }
    else if kind == TokenKind.Assert { "assert" }
    else if kind == TokenKind.AssertEq { "assert_eq" }
    else if kind == TokenKind.AssertNe { "assert_ne" }
    else if kind == TokenKind.Ident { "IDENT" }
    else if kind == TokenKind.Int { "INT" }
    else if kind == TokenKind.Float { "FLOAT" }
    else if kind == TokenKind.StringStart { "STRING_START" }
    else if kind == TokenKind.StringEnd { "STRING_END" }
    else if kind == TokenKind.StringPart { "STRING_PART" }
    else if kind == TokenKind.InterpStart { "INTERP_START" }
    else if kind == TokenKind.InterpEnd { "INTERP_END" }
    else if kind == TokenKind.LParen { "(" }
    else if kind == TokenKind.RParen { ")" }
    else if kind == TokenKind.LBrace { "\{" }
    else if kind == TokenKind.RBrace { "\}" }
    else if kind == TokenKind.LBracket { "[" }
    else if kind == TokenKind.RBracket { "]" }
    else if kind == TokenKind.Colon { ":" }
    else if kind == TokenKind.Comma { "," }
    else if kind == TokenKind.Dot { "." }
    else if kind == TokenKind.DotDot { ".." }
    else if kind == TokenKind.DotDoteq { "..=" }
    else if kind == TokenKind.Arrow { "->" }
    else if kind == TokenKind.FatArrow { "=>" }
    else if kind == TokenKind.At { "@" }
    else if kind == TokenKind.Plus { "+" }
    else if kind == TokenKind.Minus { "-" }
    else if kind == TokenKind.Star { "*" }
    else if kind == TokenKind.Slash { "/" }
    else if kind == TokenKind.Percent { "%" }
    else if kind == TokenKind.Equals { "=" }
    else if kind == TokenKind.EqEq { "==" }
    else if kind == TokenKind.NotEq { "!=" }
    else if kind == TokenKind.Less { "<" }
    else if kind == TokenKind.Greater { ">" }
    else if kind == TokenKind.LessEq { "<=" }
    else if kind == TokenKind.GreaterEq { ">=" }
    else if kind == TokenKind.And { "&&" }
    else if kind == TokenKind.Or { "||" }
    else if kind == TokenKind.Bang { "!" }
    else if kind == TokenKind.Question { "?" }
    else if kind == TokenKind.DoubleQuestion { "??" }
    else if kind == TokenKind.Pipe { "|" }
    else if kind == TokenKind.PipeArrow { "|>" }
    else if kind == TokenKind.PlusEq { "+=" }
    else if kind == TokenKind.MinusEq { "-=" }
    else if kind == TokenKind.StarEq { "*=" }
    else if kind == TokenKind.SlashEq { "/=" }
    else if kind == TokenKind.Newline { "NEWLINE" }
    else if kind == TokenKind.EOF { "EOF" }
    else { "UNKNOWN" }
}

// Helper: check if a token kind is a keyword
fn is_keyword(kind: Int) -> Int {
    kind >= TokenKind.Fn && kind <= TokenKind.Mod
}

// Helper: look up a keyword from its string value, returns TokenKind.Ident if not a keyword
fn keyword_lookup(name: Str) -> Int {
    if name == "fn" { TokenKind.Fn }
    else if name == "let" { TokenKind.Let }
    else if name == "mut" { TokenKind.Mut }
    else if name == "type" { TokenKind.Type }
    else if name == "trait" { TokenKind.Trait }
    else if name == "impl" { TokenKind.Impl }
    else if name == "if" { TokenKind.If }
    else if name == "else" { TokenKind.Else }
    else if name == "match" { TokenKind.Match }
    else if name == "for" { TokenKind.For }
    else if name == "in" { TokenKind.In }
    else if name == "while" { TokenKind.While }
    else if name == "loop" { TokenKind.Loop }
    else if name == "break" { TokenKind.Break }
    else if name == "continue" { TokenKind.Continue }
    else if name == "return" { TokenKind.Return }
    else if name == "pub" { TokenKind.Pub }
    else if name == "with" { TokenKind.With }
    else if name == "handler" { TokenKind.Handler }
    else if name == "self" { TokenKind.Self }
    else if name == "test" { TokenKind.Test }
    else if name == "import" { TokenKind.Import }
    else if name == "as" { TokenKind.As }
    else if name == "mod" { TokenKind.Mod }
    else if name == "assert" { TokenKind.Assert }
    else if name == "assert_eq" { TokenKind.AssertEq }
    else if name == "assert_ne" { TokenKind.AssertNe }
    else { TokenKind.Ident }
}

// === ast.pact ===

// ast.pact — AST node definitions for the self-hosting compiler
//
// Fat-node approach: a single Node struct carries fields for every
// possible node kind. Only the fields relevant to a given kind are
// meaningful; the rest are zero/empty. Ugly but bootstrappable —
// no enums or tagged unions in the C backend yet.

// -- Expression node kinds --
type NodeKind {
    IntLit, FloatLit, Ident, Call, MethodCall, BinOp, UnaryOp, InterpString,
    BoolLit, TupleLit, ListLit, StructLit, FieldAccess, IndexExpr, RangeLit, IfExpr,
    MatchExpr, Closure, LetBinding, ExprStmt, Assignment, CompoundAssign, Return, ForIn,
    WhileLoop, LoopExpr, Break, Continue, Block, FnDef, Param, Program,
    TypeDef, TypeField, TypeVariant, TraitDef, ImplBlock, TestBlock, IntPattern, WildcardPattern,
    IdentPattern, TuplePattern, StringPattern, OrPattern, RangePattern, StructPattern, EnumPattern, AsPattern,
    MatchArm, StructLitField, WithBlock, HandlerExpr, Annotation, ModBlock, ImportStmt, TypeAnn,
}

// -- Statement node kinds --

// -- Block / structural kinds --

// -- Type definition kinds --

// -- Pattern kinds --

// -- Struct literal field --

// -- With / handler / annotation --

// -- Module system --

// -- Type annotation --

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
    if kind == NodeKind.IntLit { "IntLit" }
    else if kind == NodeKind.FloatLit { "FloatLit" }
    else if kind == NodeKind.Ident { "Ident" }
    else if kind == NodeKind.Call { "Call" }
    else if kind == NodeKind.MethodCall { "MethodCall" }
    else if kind == NodeKind.BinOp { "BinOp" }
    else if kind == NodeKind.UnaryOp { "UnaryOp" }
    else if kind == NodeKind.InterpString { "InterpString" }
    else if kind == NodeKind.BoolLit { "BoolLit" }
    else if kind == NodeKind.TupleLit { "TupleLit" }
    else if kind == NodeKind.ListLit { "ListLit" }
    else if kind == NodeKind.StructLit { "StructLit" }
    else if kind == NodeKind.FieldAccess { "FieldAccess" }
    else if kind == NodeKind.IndexExpr { "IndexExpr" }
    else if kind == NodeKind.RangeLit { "RangeLit" }
    else if kind == NodeKind.IfExpr { "IfExpr" }
    else if kind == NodeKind.MatchExpr { "MatchExpr" }
    else if kind == NodeKind.Closure { "Closure" }
    else if kind == NodeKind.LetBinding { "LetBinding" }
    else if kind == NodeKind.ExprStmt { "ExprStmt" }
    else if kind == NodeKind.Assignment { "Assignment" }
    else if kind == NodeKind.CompoundAssign { "CompoundAssign" }
    else if kind == NodeKind.Return { "Return" }
    else if kind == NodeKind.ForIn { "ForIn" }
    else if kind == NodeKind.WhileLoop { "WhileLoop" }
    else if kind == NodeKind.LoopExpr { "LoopExpr" }
    else if kind == NodeKind.Break { "Break" }
    else if kind == NodeKind.Continue { "Continue" }
    else if kind == NodeKind.Block { "Block" }
    else if kind == NodeKind.FnDef { "FnDef" }
    else if kind == NodeKind.Param { "Param" }
    else if kind == NodeKind.Program { "Program" }
    else if kind == NodeKind.TypeDef { "TypeDef" }
    else if kind == NodeKind.TypeField { "TypeField" }
    else if kind == NodeKind.TypeVariant { "TypeVariant" }
    else if kind == NodeKind.TraitDef { "TraitDef" }
    else if kind == NodeKind.ImplBlock { "ImplBlock" }
    else if kind == NodeKind.TestBlock { "TestBlock" }
    else if kind == NodeKind.IntPattern { "IntPattern" }
    else if kind == NodeKind.WildcardPattern { "WildcardPattern" }
    else if kind == NodeKind.IdentPattern { "IdentPattern" }
    else if kind == NodeKind.TuplePattern { "TuplePattern" }
    else if kind == NodeKind.StringPattern { "StringPattern" }
    else if kind == NodeKind.OrPattern { "OrPattern" }
    else if kind == NodeKind.RangePattern { "RangePattern" }
    else if kind == NodeKind.StructPattern { "StructPattern" }
    else if kind == NodeKind.EnumPattern { "EnumPattern" }
    else if kind == NodeKind.AsPattern { "AsPattern" }
    else if kind == NodeKind.MatchArm { "MatchArm" }
    else if kind == NodeKind.StructLitField { "StructLitField" }
    else if kind == NodeKind.WithBlock { "WithBlock" }
    else if kind == NodeKind.HandlerExpr { "HandlerExpr" }
    else if kind == NodeKind.Annotation { "Annotation" }
    else if kind == NodeKind.ModBlock { "ModBlock" }
    else if kind == NodeKind.ImportStmt { "ImportStmt" }
    else if kind == NodeKind.TypeAnn { "TypeAnn" }
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
    if name == "fn" { TokenKind.Fn }
    else if name == "let" { TokenKind.Let }
    else if name == "mut" { TokenKind.Mut }
    else if name == "type" { TokenKind.Type }
    else if name == "trait" { TokenKind.Trait }
    else if name == "impl" { TokenKind.Impl }
    else if name == "if" { TokenKind.If }
    else if name == "else" { TokenKind.Else }
    else if name == "match" { TokenKind.Match }
    else if name == "for" { TokenKind.For }
    else if name == "in" { TokenKind.In }
    else if name == "while" { TokenKind.While }
    else if name == "loop" { TokenKind.Loop }
    else if name == "break" { TokenKind.Break }
    else if name == "continue" { TokenKind.Continue }
    else if name == "return" { TokenKind.Return }
    else if name == "pub" { TokenKind.Pub }
    else if name == "with" { TokenKind.With }
    else if name == "handler" { TokenKind.Handler }
    else if name == "self" { TokenKind.Self }
    else if name == "test" { TokenKind.Test }
    else if name == "import" { TokenKind.Import }
    else if name == "as" { TokenKind.As }
    else if name == "mod" { TokenKind.Mod }
    else if name == "assert" { TokenKind.Assert }
    else if name == "assert_eq" { TokenKind.AssertEq }
    else if name == "assert_ne" { TokenKind.AssertNe }
    else { TokenKind.Ident }
}

// ── Token kind name (for debug output) ───────────────────────────────

fn token_kind_name(kind: Int) -> Str {
    if kind == TokenKind.Fn { "FN" }
    else if kind == TokenKind.Let { "LET" }
    else if kind == TokenKind.Mut { "MUT" }
    else if kind == TokenKind.Type { "TYPE" }
    else if kind == TokenKind.Trait { "TRAIT" }
    else if kind == TokenKind.Impl { "IMPL" }
    else if kind == TokenKind.If { "IF" }
    else if kind == TokenKind.Else { "ELSE" }
    else if kind == TokenKind.Match { "MATCH" }
    else if kind == TokenKind.For { "FOR" }
    else if kind == TokenKind.In { "IN" }
    else if kind == TokenKind.While { "WHILE" }
    else if kind == TokenKind.Loop { "LOOP" }
    else if kind == TokenKind.Break { "BREAK" }
    else if kind == TokenKind.Continue { "CONTINUE" }
    else if kind == TokenKind.Return { "RETURN" }
    else if kind == TokenKind.Pub { "PUB" }
    else if kind == TokenKind.With { "WITH" }
    else if kind == TokenKind.Handler { "HANDLER" }
    else if kind == TokenKind.Self { "SELF" }
    else if kind == TokenKind.Test { "TEST" }
    else if kind == TokenKind.Import { "IMPORT" }
    else if kind == TokenKind.As { "AS" }
    else if kind == TokenKind.Mod { "MOD" }
    else if kind == TokenKind.Assert { "ASSERT" }
    else if kind == TokenKind.AssertEq { "ASSERT_EQ" }
    else if kind == TokenKind.AssertNe { "ASSERT_NE" }
    else if kind == TokenKind.Ident { "IDENT" }
    else if kind == TokenKind.Int { "INT" }
    else if kind == TokenKind.Float { "FLOAT" }
    else if kind == TokenKind.StringStart { "STRING_START" }
    else if kind == TokenKind.StringEnd { "STRING_END" }
    else if kind == TokenKind.StringPart { "STRING_PART" }
    else if kind == TokenKind.InterpStart { "INTERP_START" }
    else if kind == TokenKind.InterpEnd { "INTERP_END" }
    else if kind == TokenKind.LParen { "LPAREN" }
    else if kind == TokenKind.RParen { "RPAREN" }
    else if kind == TokenKind.LBrace { "LBRACE" }
    else if kind == TokenKind.RBrace { "RBRACE" }
    else if kind == TokenKind.LBracket { "LBRACKET" }
    else if kind == TokenKind.RBracket { "RBRACKET" }
    else if kind == TokenKind.Colon { "COLON" }
    else if kind == TokenKind.Comma { "COMMA" }
    else if kind == TokenKind.Dot { "DOT" }
    else if kind == TokenKind.DotDot { "DOTDOT" }
    else if kind == TokenKind.DotDoteq { "DOTDOTEQ" }
    else if kind == TokenKind.Arrow { "ARROW" }
    else if kind == TokenKind.FatArrow { "FAT_ARROW" }
    else if kind == TokenKind.At { "AT" }
    else if kind == TokenKind.Plus { "PLUS" }
    else if kind == TokenKind.Minus { "MINUS" }
    else if kind == TokenKind.Star { "STAR" }
    else if kind == TokenKind.Slash { "SLASH" }
    else if kind == TokenKind.Percent { "PERCENT" }
    else if kind == TokenKind.Equals { "EQUALS" }
    else if kind == TokenKind.EqEq { "EQEQ" }
    else if kind == TokenKind.NotEq { "NOT_EQ" }
    else if kind == TokenKind.Less { "LESS" }
    else if kind == TokenKind.Greater { "GREATER" }
    else if kind == TokenKind.LessEq { "LESS_EQ" }
    else if kind == TokenKind.GreaterEq { "GREATER_EQ" }
    else if kind == TokenKind.And { "AND" }
    else if kind == TokenKind.Or { "OR" }
    else if kind == TokenKind.Bang { "BANG" }
    else if kind == TokenKind.Question { "QUESTION" }
    else if kind == TokenKind.DoubleQuestion { "DOUBLE_QUESTION" }
    else if kind == TokenKind.Pipe { "PIPE" }
    else if kind == TokenKind.PipeArrow { "PIPE_ARROW" }
    else if kind == TokenKind.PlusEq { "PLUS_EQ" }
    else if kind == TokenKind.MinusEq { "MINUS_EQ" }
    else if kind == TokenKind.StarEq { "STAR_EQ" }
    else if kind == TokenKind.SlashEq { "SLASH_EQ" }
    else if kind == TokenKind.Newline { "NEWLINE" }
    else if kind == TokenKind.EOF { "EOF" }
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
                    tok_kinds.push(TokenKind.SlashEq)
                    tok_values.push("/=")
                    tok_lines.push(t_line)
                    tok_cols.push(t_col)
                    last_kind = TokenKind.SlashEq
                } else {
                    tok_kinds.push(TokenKind.Slash)
                    tok_values.push("/")
                    tok_lines.push(t_line)
                    tok_cols.push(t_col)
                    last_kind = TokenKind.Slash
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
                if last_kind != TokenKind.Newline {
                    tok_kinds.push(TokenKind.Newline)
                    tok_values.push("\\n")
                    tok_lines.push(t_line)
                    tok_cols.push(t_col)
                    last_kind = TokenKind.Newline
                }
                continue
            }

            // String start: "
            if ch == CH_DQUOTE {
                let t_line = line
                let t_col = col
                pos = pos + 1
                col = col + 1
                tok_kinds.push(TokenKind.StringStart)
                tok_values.push("\"")
                tok_lines.push(t_line)
                tok_cols.push(t_col)
                last_kind = TokenKind.StringStart
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
                    tok_kinds.push(TokenKind.LBrace)
                    tok_values.push("\{")
                    tok_lines.push(t_line)
                    tok_cols.push(t_col)
                    last_kind = TokenKind.LBrace
                } else {
                    tok_kinds.push(TokenKind.LBrace)
                    tok_values.push("\{")
                    tok_lines.push(t_line)
                    tok_cols.push(t_col)
                    last_kind = TokenKind.LBrace
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
                    tok_kinds.push(TokenKind.RBrace)
                    tok_values.push("\}")
                    tok_lines.push(t_line)
                    tok_cols.push(t_col)
                    last_kind = TokenKind.RBrace
                } else if brace_depth == 1 {
                    // End of interpolation — pop back to string mode
                    mode_stack.pop()
                    brace_depth_stack.pop()
                    tok_kinds.push(TokenKind.InterpEnd)
                    tok_values.push("\}")
                    tok_lines.push(t_line)
                    tok_cols.push(t_col)
                    last_kind = TokenKind.InterpEnd
                    // Continue in string mode (loop will pick it up)
                } else {
                    tok_kinds.push(TokenKind.RBrace)
                    tok_values.push("\}")
                    tok_lines.push(t_line)
                    tok_cols.push(t_col)
                    last_kind = TokenKind.RBrace
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
                    tok_kinds.push(TokenKind.DoubleQuestion)
                    tok_values.push("??")
                    tok_lines.push(t_line)
                    tok_cols.push(t_col)
                    last_kind = TokenKind.DoubleQuestion
                } else {
                    tok_kinds.push(TokenKind.Question)
                    tok_values.push("?")
                    tok_lines.push(t_line)
                    tok_cols.push(t_col)
                    last_kind = TokenKind.Question
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
                    tok_kinds.push(TokenKind.Arrow)
                    tok_values.push("->")
                    tok_lines.push(t_line)
                    tok_cols.push(t_col)
                    last_kind = TokenKind.Arrow
                } else if peek_at(source, pos, 1) == CH_EQUALS {
                    pos = pos + 2
                    col = col + 2
                    tok_kinds.push(TokenKind.MinusEq)
                    tok_values.push("-=")
                    tok_lines.push(t_line)
                    tok_cols.push(t_col)
                    last_kind = TokenKind.MinusEq
                } else {
                    pos = pos + 1
                    col = col + 1
                    tok_kinds.push(TokenKind.Minus)
                    tok_values.push("-")
                    tok_lines.push(t_line)
                    tok_cols.push(t_col)
                    last_kind = TokenKind.Minus
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
                    tok_kinds.push(TokenKind.PlusEq)
                    tok_values.push("+=")
                    tok_lines.push(t_line)
                    tok_cols.push(t_col)
                    last_kind = TokenKind.PlusEq
                } else {
                    tok_kinds.push(TokenKind.Plus)
                    tok_values.push("+")
                    tok_lines.push(t_line)
                    tok_cols.push(t_col)
                    last_kind = TokenKind.Plus
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
                    tok_kinds.push(TokenKind.StarEq)
                    tok_values.push("*=")
                    tok_lines.push(t_line)
                    tok_cols.push(t_col)
                    last_kind = TokenKind.StarEq
                } else {
                    tok_kinds.push(TokenKind.Star)
                    tok_values.push("*")
                    tok_lines.push(t_line)
                    tok_cols.push(t_col)
                    last_kind = TokenKind.Star
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
                    tok_kinds.push(TokenKind.FatArrow)
                    tok_values.push("=>")
                    tok_lines.push(t_line)
                    tok_cols.push(t_col)
                    last_kind = TokenKind.FatArrow
                } else if pos < source.len() && peek(source, pos) == CH_EQUALS {
                    pos = pos + 1
                    col = col + 1
                    tok_kinds.push(TokenKind.EqEq)
                    tok_values.push("==")
                    tok_lines.push(t_line)
                    tok_cols.push(t_col)
                    last_kind = TokenKind.EqEq
                } else {
                    tok_kinds.push(TokenKind.Equals)
                    tok_values.push("=")
                    tok_lines.push(t_line)
                    tok_cols.push(t_col)
                    last_kind = TokenKind.Equals
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
                    tok_kinds.push(TokenKind.DotDoteq)
                    tok_values.push("..=")
                    tok_lines.push(t_line)
                    tok_cols.push(t_col)
                    last_kind = TokenKind.DotDoteq
                } else {
                    tok_kinds.push(TokenKind.DotDot)
                    tok_values.push("..")
                    tok_lines.push(t_line)
                    tok_cols.push(t_col)
                    last_kind = TokenKind.DotDot
                }
                continue
            }

            if ch == CH_DOT {
                let t_line = line
                let t_col = col
                pos = pos + 1
                col = col + 1
                tok_kinds.push(TokenKind.Dot)
                tok_values.push(".")
                tok_lines.push(t_line)
                tok_cols.push(t_col)
                last_kind = TokenKind.Dot
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
                    tok_kinds.push(TokenKind.NotEq)
                    tok_values.push("!=")
                    tok_lines.push(t_line)
                    tok_cols.push(t_col)
                    last_kind = TokenKind.NotEq
                } else {
                    tok_kinds.push(TokenKind.Bang)
                    tok_values.push("!")
                    tok_lines.push(t_line)
                    tok_cols.push(t_col)
                    last_kind = TokenKind.Bang
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
                    tok_kinds.push(TokenKind.LessEq)
                    tok_values.push("<=")
                    tok_lines.push(t_line)
                    tok_cols.push(t_col)
                    last_kind = TokenKind.LessEq
                } else {
                    tok_kinds.push(TokenKind.Less)
                    tok_values.push("<")
                    tok_lines.push(t_line)
                    tok_cols.push(t_col)
                    last_kind = TokenKind.Less
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
                    tok_kinds.push(TokenKind.GreaterEq)
                    tok_values.push(">=")
                    tok_lines.push(t_line)
                    tok_cols.push(t_col)
                    last_kind = TokenKind.GreaterEq
                } else {
                    tok_kinds.push(TokenKind.Greater)
                    tok_values.push(">")
                    tok_lines.push(t_line)
                    tok_cols.push(t_col)
                    last_kind = TokenKind.Greater
                }
                continue
            }

            // Ampersand: &&
            if ch == CH_AMP && peek_at(source, pos, 1) == CH_AMP {
                let t_line = line
                let t_col = col
                pos = pos + 2
                col = col + 2
                tok_kinds.push(TokenKind.And)
                tok_values.push("&&")
                tok_lines.push(t_line)
                tok_cols.push(t_col)
                last_kind = TokenKind.And
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
                    tok_kinds.push(TokenKind.Or)
                    tok_values.push("||")
                    tok_lines.push(t_line)
                    tok_cols.push(t_col)
                    last_kind = TokenKind.Or
                } else if pos < source.len() && peek(source, pos) == CH_GREATER {
                    pos = pos + 1
                    col = col + 1
                    tok_kinds.push(TokenKind.PipeArrow)
                    tok_values.push("|>")
                    tok_lines.push(t_line)
                    tok_cols.push(t_col)
                    last_kind = TokenKind.PipeArrow
                } else {
                    tok_kinds.push(TokenKind.Pipe)
                    tok_values.push("|")
                    tok_lines.push(t_line)
                    tok_cols.push(t_col)
                    last_kind = TokenKind.Pipe
                }
                continue
            }

            // Single-char tokens: ( ) : , % [ ] @
            if ch == CH_LPAREN {
                let t_line = line
                let t_col = col
                pos = pos + 1
                col = col + 1
                tok_kinds.push(TokenKind.LParen)
                tok_values.push("(")
                tok_lines.push(t_line)
                tok_cols.push(t_col)
                last_kind = TokenKind.LParen
                continue
            }
            if ch == CH_RPAREN {
                let t_line = line
                let t_col = col
                pos = pos + 1
                col = col + 1
                tok_kinds.push(TokenKind.RParen)
                tok_values.push(")")
                tok_lines.push(t_line)
                tok_cols.push(t_col)
                last_kind = TokenKind.RParen
                continue
            }
            if ch == CH_COLON {
                let t_line = line
                let t_col = col
                pos = pos + 1
                col = col + 1
                tok_kinds.push(TokenKind.Colon)
                tok_values.push(":")
                tok_lines.push(t_line)
                tok_cols.push(t_col)
                last_kind = TokenKind.Colon
                continue
            }
            if ch == CH_COMMA {
                let t_line = line
                let t_col = col
                pos = pos + 1
                col = col + 1
                tok_kinds.push(TokenKind.Comma)
                tok_values.push(",")
                tok_lines.push(t_line)
                tok_cols.push(t_col)
                last_kind = TokenKind.Comma
                continue
            }
            if ch == CH_PERCENT {
                let t_line = line
                let t_col = col
                pos = pos + 1
                col = col + 1
                tok_kinds.push(TokenKind.Percent)
                tok_values.push("%")
                tok_lines.push(t_line)
                tok_cols.push(t_col)
                last_kind = TokenKind.Percent
                continue
            }
            if ch == CH_LBRACKET {
                let t_line = line
                let t_col = col
                pos = pos + 1
                col = col + 1
                tok_kinds.push(TokenKind.LBracket)
                tok_values.push("[")
                tok_lines.push(t_line)
                tok_cols.push(t_col)
                last_kind = TokenKind.LBracket
                continue
            }
            if ch == CH_RBRACKET {
                let t_line = line
                let t_col = col
                pos = pos + 1
                col = col + 1
                tok_kinds.push(TokenKind.RBracket)
                tok_values.push("]")
                tok_lines.push(t_line)
                tok_cols.push(t_col)
                last_kind = TokenKind.RBracket
                continue
            }
            if ch == CH_AT {
                let t_line = line
                let t_col = col
                pos = pos + 1
                col = col + 1
                tok_kinds.push(TokenKind.At)
                tok_values.push("@")
                tok_lines.push(t_line)
                tok_cols.push(t_col)
                last_kind = TokenKind.At
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
                    tok_kinds.push(TokenKind.Float)
                    tok_values.push(source.substring(start, pos - start))
                    tok_lines.push(t_line)
                    tok_cols.push(t_col)
                    last_kind = TokenKind.Float
                } else {
                    tok_kinds.push(TokenKind.Int)
                    tok_values.push(source.substring(start, pos - start))
                    tok_lines.push(t_line)
                    tok_cols.push(t_col)
                    last_kind = TokenKind.Int
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
                tok_kinds.push(TokenKind.StringPart)
                tok_values.push(string_buf)
                tok_lines.push(t_line)
                tok_cols.push(t_col)
                last_kind = TokenKind.StringPart
                string_buf = ""
                tok_kinds.push(TokenKind.InterpStart)
                tok_values.push("\{")
                tok_lines.push(t_line)
                tok_cols.push(t_col)
                last_kind = TokenKind.InterpStart
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
                tok_kinds.push(TokenKind.StringPart)
                tok_values.push(string_buf)
                tok_lines.push(t_line)
                tok_cols.push(t_col)
                last_kind = TokenKind.StringPart
                string_buf = ""
                tok_kinds.push(TokenKind.StringEnd)
                tok_values.push("\"")
                tok_lines.push(t_line)
                tok_cols.push(t_col)
                last_kind = TokenKind.StringEnd
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
    tok_kinds.push(TokenKind.EOF)
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
let mut np_trait_name: List[Str] = []

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
let mut np_methods: List[Int] = []

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
    np_trait_name.push("")
    np_params.push(-1)
    np_args.push(-1)
    np_stmts.push(-1)
    np_arms.push(-1)
    np_fields.push(-1)
    np_elements.push(-1)
    np_methods.push(-1)
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
    while at(TokenKind.Newline) {
        advance()
    }
}

fn maybe_newline() {
    if at(TokenKind.Newline) {
        advance()
    }
}

// ── Top-level ───────────────────────────────────────────────────────

fn parse_program() -> Int {
    let mut fn_nodes: List[Int] = []
    let mut type_nodes: List[Int] = []
    let mut let_nodes: List[Int] = []
    let mut trait_nodes: List[Int] = []
    let mut impl_nodes: List[Int] = []
    let mut fn_pub: List[Int] = []
    skip_newlines()
    while !at(TokenKind.EOF) {
        skip_newlines()
        if at(TokenKind.EOF) {
            break
        }
        if at(TokenKind.Type) {
            let td = parse_type_def()
            type_nodes.push(td)
        } else if at(TokenKind.Trait) {
            let tr = parse_trait_def()
            trait_nodes.push(tr)
        } else if at(TokenKind.Impl) {
            let im = parse_impl_block()
            impl_nodes.push(im)
        } else if at(TokenKind.Let) {
            let lb = parse_let_binding()
            let_nodes.push(lb)
        } else if at(TokenKind.Pub) {
            advance()
            skip_newlines()
            let f = parse_fn_def()
            np_is_pub.set(f, 1)
            fn_nodes.push(f)
        } else if at(TokenKind.Fn) {
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
    let traits = new_sublist()
    i = 0
    while i < trait_nodes.len() {
        sublist_push(traits, trait_nodes.get(i))
        i = i + 1
    }
    finalize_sublist(traits)
    let impls = new_sublist()
    i = 0
    while i < impl_nodes.len() {
        sublist_push(impls, impl_nodes.get(i))
        i = i + 1
    }
    finalize_sublist(impls)
    let prog = new_node(NodeKind.Program)
    np_params.pop()
    np_params.push(fns)
    np_fields.pop()
    np_fields.push(types)
    np_stmts.pop()
    np_stmts.push(lets)
    np_arms.pop()
    np_arms.push(traits)
    np_methods.pop()
    np_methods.push(impls)
    prog
}

// ── Type definitions ────────────────────────────────────────────────

fn parse_type_def() -> Int {
    expect(TokenKind.Type)
    let name = expect_value(TokenKind.Ident)
    // Skip type params [T] if present
    if at(TokenKind.LBracket) {
        advance()
        while !at(TokenKind.RBracket) {
            advance()
        }
        expect(TokenKind.RBracket)
    }
    skip_newlines()
    let mut flds = -1
    if at(TokenKind.LBrace) {
        expect(TokenKind.LBrace)
        skip_newlines()
        let mut field_nodes: List[Int] = []
        while !at(TokenKind.RBrace) {
            let fname = expect_value(TokenKind.Ident)
            if at(TokenKind.Colon) {
                advance()
                let type_ann = parse_type_annotation()
                let tf = new_node(NodeKind.TypeField)
                np_name.pop()
                np_name.push(fname)
                np_value.pop()
                np_value.push(type_ann)
                field_nodes.push(tf)
            } else {
                let tv = new_node(NodeKind.TypeVariant)
                np_name.pop()
                np_name.push(fname)
                field_nodes.push(tv)
            }
            if at(TokenKind.Comma) {
                advance()
            }
            skip_newlines()
        }
        expect(TokenKind.RBrace)
        flds = new_sublist()
        let mut i = 0
        while i < field_nodes.len() {
            sublist_push(flds, field_nodes.get(i))
            i = i + 1
        }
        finalize_sublist(flds)
    }
    let td = new_node(NodeKind.TypeDef)
    np_name.pop()
    np_name.push(name)
    np_fields.pop()
    np_fields.push(flds)
    td
}

fn parse_type_annotation() -> Int {
    let name = expect_value(TokenKind.Ident)
    let mut elems = -1
    if at(TokenKind.LBracket) {
        advance()
        let mut type_nodes: List[Int] = []
        type_nodes.push(parse_type_annotation())
        while at(TokenKind.Comma) {
            advance()
            skip_newlines()
            type_nodes.push(parse_type_annotation())
        }
        expect(TokenKind.RBracket)
        elems = new_sublist()
        let mut i = 0
        while i < type_nodes.len() {
            sublist_push(elems, type_nodes.get(i))
            i = i + 1
        }
        finalize_sublist(elems)
    }
    let ta = new_node(NodeKind.TypeAnn)
    np_name.pop()
    np_name.push(name)
    np_elements.pop()
    np_elements.push(elems)
    ta
}

// ── Function definitions ────────────────────────────────────────────

fn parse_fn_def() -> Int {
    expect(TokenKind.Fn)
    let name = expect_value(TokenKind.Ident)
    // Skip type params
    if at(TokenKind.LBracket) {
        advance()
        while !at(TokenKind.RBracket) {
            advance()
        }
        expect(TokenKind.RBracket)
    }
    expect(TokenKind.LParen)
    let mut param_nodes: List[Int] = []
    if !at(TokenKind.RParen) {
        param_nodes.push(parse_param())
        while at(TokenKind.Comma) {
            advance()
            if at(TokenKind.RParen) {
                break
            }
            param_nodes.push(parse_param())
        }
    }
    expect(TokenKind.RParen)
    let ret_type = ""
    let mut ret_str = ""
    if at(TokenKind.Arrow) {
        advance()
        let rt = parse_type_annotation()
        ret_str = np_name.get(rt)
    }
    // Skip effects
    if at(TokenKind.Bang) {
        advance()
        expect_value(TokenKind.Ident)
        while at(TokenKind.Comma) {
            advance()
            skip_newlines()
            expect_value(TokenKind.Ident)
        }
    }
    skip_newlines()
    let body = -1
    let mut body_id = -1
    if at(TokenKind.LBrace) {
        body_id = parse_block()
    }
    let params = new_sublist()
    let mut pi = 0
    while pi < param_nodes.len() {
        sublist_push(params, param_nodes.get(pi))
        pi = pi + 1
    }
    finalize_sublist(params)
    let nd = new_node(NodeKind.FnDef)
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
    if at(TokenKind.Mut) {
        is_mut = 1
        advance()
    }
    let mut name = ""
    if at(TokenKind.Self) {
        name = "self"
        advance()
    } else {
        name = expect_value(TokenKind.Ident)
    }
    let mut type_str = ""
    if at(TokenKind.Colon) {
        advance()
        let ta = parse_type_annotation()
        type_str = np_name.get(ta)
    }
    let nd = new_node(NodeKind.Param)
    np_name.pop()
    np_name.push(name)
    np_type_name.pop()
    np_type_name.push(type_str)
    np_is_mut.pop()
    np_is_mut.push(is_mut)
    nd
}

// ── Trait definitions ────────────────────────────────────────────────

fn parse_trait_def() -> Int {
    expect(TokenKind.Trait)
    let name = expect_value(TokenKind.Ident)
    skip_newlines()
    expect(TokenKind.LBrace)
    skip_newlines()
    let mut method_nodes: List[Int] = []
    while !at(TokenKind.RBrace) {
        if at(TokenKind.Fn) {
            method_nodes.push(parse_fn_def())
        } else {
            advance()
        }
        skip_newlines()
    }
    expect(TokenKind.RBrace)
    let methods = new_sublist()
    let mut i = 0
    while i < method_nodes.len() {
        sublist_push(methods, method_nodes.get(i))
        i = i + 1
    }
    finalize_sublist(methods)
    let nd = new_node(NodeKind.TraitDef)
    np_name.pop()
    np_name.push(name)
    np_methods.pop()
    np_methods.push(methods)
    nd
}

// ── Impl blocks ─────────────────────────────────────────────────────

fn parse_impl_block() -> Int {
    expect(TokenKind.Impl)
    let trait_name = expect_value(TokenKind.Ident)
    skip_newlines()
    let mut type_name = ""
    if at(TokenKind.For) {
        advance()
        skip_newlines()
        type_name = expect_value(TokenKind.Ident)
    }
    skip_newlines()
    expect(TokenKind.LBrace)
    skip_newlines()
    let mut method_nodes: List[Int] = []
    while !at(TokenKind.RBrace) {
        if at(TokenKind.Fn) {
            method_nodes.push(parse_fn_def())
        } else {
            advance()
        }
        skip_newlines()
    }
    expect(TokenKind.RBrace)
    let methods = new_sublist()
    let mut i = 0
    while i < method_nodes.len() {
        sublist_push(methods, method_nodes.get(i))
        i = i + 1
    }
    finalize_sublist(methods)
    let nd = new_node(NodeKind.ImplBlock)
    np_trait_name.pop()
    np_trait_name.push(trait_name)
    np_name.pop()
    np_name.push(type_name)
    np_methods.pop()
    np_methods.push(methods)
    nd
}

// ── Block ───────────────────────────────────────────────────────────

fn parse_block() -> Int {
    expect(TokenKind.LBrace)
    skip_newlines()
    let mut stmt_nodes: List[Int] = []
    while !at(TokenKind.RBrace) {
        stmt_nodes.push(parse_stmt())
        skip_newlines()
    }
    expect(TokenKind.RBrace)
    let stmts = new_sublist()
    let mut i = 0
    while i < stmt_nodes.len() {
        sublist_push(stmts, stmt_nodes.get(i))
        i = i + 1
    }
    finalize_sublist(stmts)
    let nd = new_node(NodeKind.Block)
    np_stmts.pop()
    np_stmts.push(stmts)
    nd
}

// ── Statements ──────────────────────────────────────────────────────

fn parse_stmt() -> Int {
    if at(TokenKind.While) {
        return parse_while_loop()
    }
    if at(TokenKind.Loop) {
        return parse_loop_expr()
    }
    if at(TokenKind.Break) {
        advance()
        maybe_newline()
        return new_node(NodeKind.Break)
    }
    if at(TokenKind.Continue) {
        advance()
        maybe_newline()
        return new_node(NodeKind.Continue)
    }
    if at(TokenKind.Let) {
        return parse_let_binding()
    }
    if at(TokenKind.For) {
        return parse_for_in()
    }
    if at(TokenKind.Return) {
        return parse_return_stmt()
    }
    if at(TokenKind.If) {
        let nd = parse_if_expr()
        maybe_newline()
        return nd
    }

    let expr = parse_expr()

    if at(TokenKind.Equals) {
        advance()
        skip_newlines()
        let val = parse_expr()
        maybe_newline()
        let nd = new_node(NodeKind.Assignment)
        np_target.pop()
        np_target.push(expr)
        np_value.pop()
        np_value.push(val)
        return nd
    }

    if at(TokenKind.PlusEq) || at(TokenKind.MinusEq) || at(TokenKind.StarEq) || at(TokenKind.SlashEq) {
        let op_kind = peek_kind()
        advance()
        skip_newlines()
        let val = parse_expr()
        maybe_newline()
        let mut op_str = "+"
        if op_kind == TokenKind.MinusEq {
            op_str = "-"
        } else if op_kind == TokenKind.StarEq {
            op_str = "*"
        } else if op_kind == TokenKind.SlashEq {
            op_str = "/"
        }
        let nd = new_node(NodeKind.CompoundAssign)
        np_op.pop()
        np_op.push(op_str)
        np_target.pop()
        np_target.push(expr)
        np_value.pop()
        np_value.push(val)
        return nd
    }

    maybe_newline()
    let nd = new_node(NodeKind.ExprStmt)
    np_value.pop()
    np_value.push(expr)
    nd
}

fn parse_let_binding() -> Int {
    expect(TokenKind.Let)
    let mut is_mut = 0
    if at(TokenKind.Mut) {
        is_mut = 1
        advance()
    }
    let name = expect_value(TokenKind.Ident)
    let mut type_ann = -1
    if at(TokenKind.Colon) {
        advance()
        type_ann = parse_type_annotation()
    }
    expect(TokenKind.Equals)
    skip_newlines()
    let val = parse_expr()
    maybe_newline()
    let nd = new_node(NodeKind.LetBinding)
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
    expect(TokenKind.Return)
    if at(TokenKind.Newline) || at(TokenKind.RBrace) || at(TokenKind.EOF) {
        maybe_newline()
        let nd = new_node(NodeKind.Return)
        return nd
    }
    let val = parse_expr()
    maybe_newline()
    let nd = new_node(NodeKind.Return)
    np_value.pop()
    np_value.push(val)
    nd
}

fn parse_if_expr() -> Int {
    expect(TokenKind.If)
    let cond = parse_expr()
    skip_newlines()
    let then_b = parse_block()
    let mut else_b = -1
    skip_newlines()
    if at(TokenKind.Else) {
        advance()
        skip_newlines()
        if at(TokenKind.If) {
            let inner = parse_if_expr()
            let stmts = new_sublist()
            sublist_push(stmts, inner)
            finalize_sublist(stmts)
            let blk = new_node(NodeKind.Block)
            np_stmts.pop()
            np_stmts.push(stmts)
            else_b = blk
        } else {
            else_b = parse_block()
        }
    }
    let nd = new_node(NodeKind.IfExpr)
    np_condition.pop()
    np_condition.push(cond)
    np_then_body.pop()
    np_then_body.push(then_b)
    np_else_body.pop()
    np_else_body.push(else_b)
    nd
}

fn parse_while_loop() -> Int {
    expect(TokenKind.While)
    let cond = parse_expr()
    skip_newlines()
    let body = parse_block()
    let nd = new_node(NodeKind.WhileLoop)
    np_condition.pop()
    np_condition.push(cond)
    np_body.pop()
    np_body.push(body)
    nd
}

fn parse_loop_expr() -> Int {
    expect(TokenKind.Loop)
    skip_newlines()
    let body = parse_block()
    let nd = new_node(NodeKind.LoopExpr)
    np_body.pop()
    np_body.push(body)
    nd
}

fn parse_for_in() -> Int {
    expect(TokenKind.For)
    let mut var = ""
    let mut pat = -1
    if at(TokenKind.LParen) {
        pat = parse_pattern()
        var = "_tuple"
    } else {
        var = expect_value(TokenKind.Ident)
    }
    expect(TokenKind.In)
    let iter = parse_expr()
    skip_newlines()
    let body = parse_block()
    let nd = new_node(NodeKind.ForIn)
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
    while at(TokenKind.Or) {
        advance()
        skip_newlines()
        let right = parse_and()
        let nd = new_node(NodeKind.BinOp)
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
    while at(TokenKind.And) {
        advance()
        skip_newlines()
        let right = parse_equality()
        let nd = new_node(NodeKind.BinOp)
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
    while at(TokenKind.EqEq) || at(TokenKind.NotEq) {
        let op = advance_value()
        skip_newlines()
        let right = parse_comparison()
        let nd = new_node(NodeKind.BinOp)
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
    while at(TokenKind.Less) || at(TokenKind.Greater) || at(TokenKind.LessEq) || at(TokenKind.GreaterEq) {
        let op = advance_value()
        skip_newlines()
        let right = parse_additive()
        let nd = new_node(NodeKind.BinOp)
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
    while at(TokenKind.Plus) || at(TokenKind.Minus) {
        let op = advance_value()
        skip_newlines()
        let right = parse_multiplicative()
        let nd = new_node(NodeKind.BinOp)
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
    while at(TokenKind.Star) || at(TokenKind.Slash) || at(TokenKind.Percent) {
        let op = advance_value()
        skip_newlines()
        let right = parse_unary()
        let nd = new_node(NodeKind.BinOp)
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
    if at(TokenKind.Minus) {
        advance()
        let operand = parse_unary()
        let nd = new_node(NodeKind.UnaryOp)
        np_op.pop()
        np_op.push("-")
        np_left.pop()
        np_left.push(operand)
        return nd
    }
    if at(TokenKind.Bang) {
        advance()
        let operand = parse_unary()
        let nd = new_node(NodeKind.UnaryOp)
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
        if at(TokenKind.Dot) {
            advance()
            let member = expect_value(TokenKind.Ident)
            if at(TokenKind.LParen) {
                advance()
                let mut arg_nodes: List[Int] = []
                if !at(TokenKind.RParen) {
                    arg_nodes.push(parse_expr())
                    while at(TokenKind.Comma) {
                        advance()
                        skip_newlines()
                        if at(TokenKind.RParen) {
                            break
                        }
                        arg_nodes.push(parse_expr())
                    }
                    skip_newlines()
                }
                expect(TokenKind.RParen)
                let args = new_sublist()
                let mut ai = 0
                while ai < arg_nodes.len() {
                    sublist_push(args, arg_nodes.get(ai))
                    ai = ai + 1
                }
                finalize_sublist(args)
                let nd = new_node(NodeKind.MethodCall)
                np_obj.pop()
                np_obj.push(node)
                np_method.pop()
                np_method.push(member)
                np_args.pop()
                np_args.push(args)
                node = nd
            } else {
                let nd = new_node(NodeKind.FieldAccess)
                np_obj.pop()
                np_obj.push(node)
                np_name.pop()
                np_name.push(member)
                node = nd
                // Check for struct literal after field access (e.g. Foo.Bar { ... })
                if at(TokenKind.LBrace) {
                    if looks_like_struct_lit() {
                        // Reconstruct dotted name
                        let dotted = flatten_field_access(node)
                        if dotted != "" {
                            node = parse_struct_lit(dotted)
                        }
                    }
                }
            }
        } else if at(TokenKind.LParen) {
            advance()
            let mut call_arg_nodes: List[Int] = []
            if !at(TokenKind.RParen) {
                skip_newlines()
                skip_named_arg_label()
                call_arg_nodes.push(parse_expr())
                while at(TokenKind.Comma) {
                    advance()
                    skip_newlines()
                    if at(TokenKind.RParen) {
                        break
                    }
                    skip_named_arg_label()
                    call_arg_nodes.push(parse_expr())
                }
                skip_newlines()
            }
            expect(TokenKind.RParen)
            let args = new_sublist()
            let mut ci = 0
            while ci < call_arg_nodes.len() {
                sublist_push(args, call_arg_nodes.get(ci))
                ci = ci + 1
            }
            finalize_sublist(args)
            let nd = new_node(NodeKind.Call)
            np_left.pop()
            np_left.push(node)
            np_args.pop()
            np_args.push(args)
            node = nd
        } else if at(TokenKind.LBracket) {
            advance()
            skip_newlines()
            let idx = parse_expr()
            skip_newlines()
            expect(TokenKind.RBracket)
            let nd = new_node(NodeKind.IndexExpr)
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
    if at(TokenKind.Ident) {
        // Peek ahead to see if next is colon (named arg)
        let saved = pos
        advance()
        if at(TokenKind.Colon) {
            advance()
            skip_newlines()
        } else {
            pos = saved
        }
    }
}

fn flatten_field_access(node: Int) -> Str {
    let kind = np_kind.get(node)
    if kind == NodeKind.Ident {
        return np_name.get(node)
    }
    if kind == NodeKind.FieldAccess {
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
    if !at(TokenKind.LBrace) {
        return 0
    }
    advance()
    skip_newlines()
    if at(TokenKind.RBrace) {
        pos = saved
        return 1
    }
    if !at(TokenKind.Ident) {
        pos = saved
        return 0
    }
    advance()
    let result = at(TokenKind.Colon)
    pos = saved
    result
}

// ── Primary expressions ─────────────────────────────────────────────

fn parse_primary() -> Int {
    if at(TokenKind.Match) {
        return parse_match_expr()
    }
    if at(TokenKind.If) {
        return parse_if_expr()
    }
    if at(TokenKind.Self) {
        advance()
        let nd = new_node(NodeKind.Ident)
        np_name.pop()
        np_name.push("self")
        return nd
    }

    if at(TokenKind.Ident) {
        let name = advance_value()
        if name == "true" {
            let nd = new_node(NodeKind.BoolLit)
            np_int_val.pop()
            np_int_val.push(1)
            return nd
        }
        if name == "false" {
            let nd = new_node(NodeKind.BoolLit)
            np_int_val.pop()
            np_int_val.push(0)
            return nd
        }
        if at(TokenKind.LBrace) && looks_like_struct_lit() {
            return parse_struct_lit(name)
        }
        let nd = new_node(NodeKind.Ident)
        np_name.pop()
        np_name.push(name)
        return nd
    }

    if at(TokenKind.Int) {
        let val_str = advance_value()
        let nd = new_node(NodeKind.IntLit)
        np_str_val.pop()
        np_str_val.push(val_str)
        // Check for range
        if at(TokenKind.DotDot) {
            advance()
            let end_nd = parse_primary()
            let rng = new_node(NodeKind.RangeLit)
            np_start.pop()
            np_start.push(nd)
            np_end.pop()
            np_end.push(end_nd)
            return rng
        }
        if at(TokenKind.DotDoteq) {
            advance()
            let end_nd = parse_primary()
            let rng = new_node(NodeKind.RangeLit)
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

    if at(TokenKind.Float) {
        let val_str = advance_value()
        let nd = new_node(NodeKind.FloatLit)
        np_str_val.pop()
        np_str_val.push(val_str)
        return nd
    }

    if at(TokenKind.LParen) {
        advance()
        skip_newlines()
        if at(TokenKind.RParen) {
            advance()
            // Unit / empty tuple — represent as int lit 0 for simplicity
            return new_node(NodeKind.IntLit)
        }
        let first = parse_expr()
        if at(TokenKind.Comma) {
            let mut elem_nodes: List[Int] = [first]
            while at(TokenKind.Comma) {
                advance()
                skip_newlines()
                if at(TokenKind.RParen) {
                    break
                }
                elem_nodes.push(parse_expr())
            }
            expect(TokenKind.RParen)
            let elems = new_sublist()
            let mut ti = 0
            while ti < elem_nodes.len() {
                sublist_push(elems, elem_nodes.get(ti))
                ti = ti + 1
            }
            finalize_sublist(elems)
            let nd = new_node(NodeKind.TupleLit)
            np_elements.pop()
            np_elements.push(elems)
            return nd
        }
        skip_newlines()
        expect(TokenKind.RParen)
        return first
    }

    if at(TokenKind.LBracket) {
        return parse_list_lit()
    }

    if at(TokenKind.StringStart) {
        return parse_interp_string()
    }

    if at(TokenKind.LBrace) {
        return parse_block()
    }

    io.println("parse error: unexpected token {peek_kind()} at line {peek_line()}:{peek_col()}")
    advance()
    new_node(NodeKind.IntLit)
}

fn parse_struct_lit(type_name: Str) -> Int {
    expect(TokenKind.LBrace)
    skip_newlines()
    let mut field_nodes: List[Int] = []
    while !at(TokenKind.RBrace) {
        let fname = expect_value(TokenKind.Ident)
        expect(TokenKind.Colon)
        skip_newlines()
        let fval = parse_expr()
        let sf = new_node(NodeKind.StructLitField)
        np_name.pop()
        np_name.push(fname)
        np_value.pop()
        np_value.push(fval)
        field_nodes.push(sf)
        if at(TokenKind.Comma) {
            advance()
        }
        skip_newlines()
    }
    expect(TokenKind.RBrace)
    let flds = new_sublist()
    let mut i = 0
    while i < field_nodes.len() {
        sublist_push(flds, field_nodes.get(i))
        i = i + 1
    }
    finalize_sublist(flds)
    let nd = new_node(NodeKind.StructLit)
    np_type_name.pop()
    np_type_name.push(type_name)
    np_fields.pop()
    np_fields.push(flds)
    nd
}

fn parse_list_lit() -> Int {
    expect(TokenKind.LBracket)
    skip_newlines()
    let mut elem_nodes: List[Int] = []
    while !at(TokenKind.RBracket) {
        elem_nodes.push(parse_expr())
        if at(TokenKind.Comma) {
            advance()
        }
        skip_newlines()
    }
    expect(TokenKind.RBracket)
    let elems = new_sublist()
    let mut i = 0
    while i < elem_nodes.len() {
        sublist_push(elems, elem_nodes.get(i))
        i = i + 1
    }
    finalize_sublist(elems)
    let nd = new_node(NodeKind.ListLit)
    np_elements.pop()
    np_elements.push(elems)
    nd
}

fn parse_interp_string() -> Int {
    expect(TokenKind.StringStart)
    let mut part_nodes: List[Int] = []
    while !at(TokenKind.StringEnd) {
        if at(TokenKind.StringPart) {
            let s = advance_value()
            let sn = new_node(NodeKind.Ident)
            np_str_val.pop()
            np_str_val.push(s)
            np_name.pop()
            np_name.push(s)
            part_nodes.push(sn)
        } else if at(TokenKind.InterpStart) {
            advance()
            part_nodes.push(parse_expr())
            expect(TokenKind.InterpEnd)
        } else {
            io.println("parse error: unexpected token in string: {peek_kind()}")
            advance()
        }
    }
    expect(TokenKind.StringEnd)
    let parts = new_sublist()
    let mut i = 0
    while i < part_nodes.len() {
        sublist_push(parts, part_nodes.get(i))
        i = i + 1
    }
    finalize_sublist(parts)
    let nd = new_node(NodeKind.InterpString)
    np_elements.pop()
    np_elements.push(parts)
    nd
}

// ── Match ───────────────────────────────────────────────────────────

fn parse_match_expr() -> Int {
    expect(TokenKind.Match)
    let scrut = parse_expr()
    skip_newlines()
    expect(TokenKind.LBrace)
    skip_newlines()
    let mut arm_nodes: List[Int] = []
    while !at(TokenKind.RBrace) {
        arm_nodes.push(parse_match_arm())
        skip_newlines()
    }
    expect(TokenKind.RBrace)
    let arms = new_sublist()
    let mut i = 0
    while i < arm_nodes.len() {
        sublist_push(arms, arm_nodes.get(i))
        i = i + 1
    }
    finalize_sublist(arms)
    let nd = new_node(NodeKind.MatchExpr)
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
    if at(TokenKind.If) {
        advance()
        guard = parse_expr()
    }
    skip_newlines()
    expect(TokenKind.FatArrow)
    skip_newlines()
    let mut body = -1
    if at(TokenKind.LBrace) {
        body = parse_block()
    } else {
        body = parse_stmt()
    }
    let nd = new_node(NodeKind.MatchArm)
    np_pattern.pop()
    np_pattern.push(pat)
    np_body.pop()
    np_body.push(body)
    np_guard.pop()
    np_guard.push(guard)
    nd
}

fn parse_pattern() -> Int {
    if at(TokenKind.LParen) {
        advance()
        skip_newlines()
        let elems = new_sublist()
        sublist_push(elems, parse_pattern())
        while at(TokenKind.Comma) {
            advance()
            skip_newlines()
            sublist_push(elems, parse_pattern())
        }
        finalize_sublist(elems)
        skip_newlines()
        expect(TokenKind.RParen)
        let nd = new_node(NodeKind.TuplePattern)
        np_elements.pop()
        np_elements.push(elems)
        return nd
    }
    if at(TokenKind.StringStart) {
        let str_node = parse_interp_string()
        let nd = new_node(NodeKind.StringPattern)
        np_str_val.pop()
        np_str_val.push(np_str_val.get(str_node))
        return nd
    }
    if at(TokenKind.Int) {
        let v = advance_value()
        let nd = new_node(NodeKind.IntPattern)
        np_str_val.pop()
        np_str_val.push(v)
        return nd
    }
    if at(TokenKind.Ident) {
        let name = advance_value()
        if name == "_" {
            return new_node(NodeKind.WildcardPattern)
        }
        if at(TokenKind.LParen) {
            advance()
            skip_newlines()
            let flds = new_sublist()
            if !at(TokenKind.RParen) {
                sublist_push(flds, parse_pattern())
                while at(TokenKind.Comma) {
                    advance()
                    skip_newlines()
                    sublist_push(flds, parse_pattern())
                }
            }
            finalize_sublist(flds)
            skip_newlines()
            expect(TokenKind.RParen)
            let nd = new_node(NodeKind.EnumPattern)
            np_name.pop()
            np_name.push(name)
            np_fields.pop()
            np_fields.push(flds)
            return nd
        }
        let nd = new_node(NodeKind.IdentPattern)
        np_name.pop()
        np_name.push(name)
        return nd
    }
    io.println("parse error: unexpected token in pattern: {peek_kind()}")
    advance()
    new_node(NodeKind.WildcardPattern)
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
    if kind == NodeKind.IntLit { "IntLit" }
    else if kind == NodeKind.FloatLit { "FloatLit" }
    else if kind == NodeKind.Ident { "Ident" }
    else if kind == NodeKind.Call { "Call" }
    else if kind == NodeKind.MethodCall { "MethodCall" }
    else if kind == NodeKind.BinOp { "BinOp" }
    else if kind == NodeKind.UnaryOp { "UnaryOp" }
    else if kind == NodeKind.InterpString { "InterpStr" }
    else if kind == NodeKind.BoolLit { "BoolLit" }
    else if kind == NodeKind.ListLit { "ListLit" }
    else if kind == NodeKind.StructLit { "StructLit" }
    else if kind == NodeKind.FieldAccess { "FieldAccess" }
    else if kind == NodeKind.IndexExpr { "IndexExpr" }
    else if kind == NodeKind.RangeLit { "RangeLit" }
    else if kind == NodeKind.IfExpr { "IfExpr" }
    else if kind == NodeKind.MatchExpr { "MatchExpr" }
    else if kind == NodeKind.LetBinding { "LetBinding" }
    else if kind == NodeKind.ExprStmt { "ExprStmt" }
    else if kind == NodeKind.Assignment { "Assignment" }
    else if kind == NodeKind.CompoundAssign { "CompoundAssign" }
    else if kind == NodeKind.Return { "Return" }
    else if kind == NodeKind.ForIn { "ForIn" }
    else if kind == NodeKind.WhileLoop { "WhileLoop" }
    else if kind == NodeKind.LoopExpr { "LoopExpr" }
    else if kind == NodeKind.Break { "Break" }
    else if kind == NodeKind.Continue { "Continue" }
    else if kind == NodeKind.Block { "Block" }
    else if kind == NodeKind.FnDef { "FnDef" }
    else if kind == NodeKind.Param { "Param" }
    else if kind == NodeKind.Program { "Program" }
    else if kind == NodeKind.TypeDef { "TypeDef" }
    else if kind == NodeKind.TypeField { "TypeField" }
    else if kind == NodeKind.TypeVariant { "TypeVariant" }
    else if kind == NodeKind.IntPattern { "IntPattern" }
    else if kind == NodeKind.WildcardPattern { "WildcardPattern" }
    else if kind == NodeKind.IdentPattern { "IdentPattern" }
    else if kind == NodeKind.TuplePattern { "TuplePattern" }
    else if kind == NodeKind.StringPattern { "StringPattern" }
    else if kind == NodeKind.EnumPattern { "EnumPattern" }
    else if kind == NodeKind.MatchArm { "MatchArm" }
    else if kind == NodeKind.StructLitField { "StructLitField" }
    else if kind == NodeKind.TypeAnn { "TypeAnn" }
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

    if kind == NodeKind.Program {
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
    } else if kind == NodeKind.FnDef {
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
    } else if kind == NodeKind.Block {
        io.println("  Block")
        let stmts_sl = np_stmts.get(id)
        if stmts_sl != -1 {
            let mut i = 0
            while i < sublist_length(stmts_sl) {
                print_node(sublist_get(stmts_sl, i), depth + 1)
                i = i + 1
            }
        }
    } else if kind == NodeKind.LetBinding {
        io.println("    LetBinding: {name} (mut={np_is_mut.get(id)})")
        print_node(np_value.get(id), depth + 1)
    } else if kind == NodeKind.ExprStmt {
        io.println("    ExprStmt")
        print_node(np_value.get(id), depth + 1)
    } else if kind == NodeKind.BinOp {
        io.println("      BinOp: {op}")
        print_node(np_left.get(id), depth + 1)
        print_node(np_right.get(id), depth + 1)
    } else if kind == NodeKind.Call {
        io.println("      Call")
        print_node(np_left.get(id), depth + 1)
    } else if kind == NodeKind.MethodCall {
        io.println("      MethodCall: .{np_method.get(id)}()")
        print_node(np_obj.get(id), depth + 1)
    } else if kind == NodeKind.IntLit {
        io.println("      IntLit: {str_val}")
    } else if kind == NodeKind.Ident {
        io.println("      Ident: {name}")
    } else if kind == NodeKind.Return {
        io.println("    Return")
        print_node(np_value.get(id), depth + 1)
    } else if kind == NodeKind.IfExpr {
        io.println("    IfExpr")
        print_node(np_condition.get(id), depth + 1)
        print_node(np_then_body.get(id), depth + 1)
        print_node(np_else_body.get(id), depth + 1)
    } else if kind == NodeKind.WhileLoop {
        io.println("    WhileLoop")
        print_node(np_condition.get(id), depth + 1)
        print_node(np_body.get(id), depth + 1)
    } else if kind == NodeKind.ForIn {
        io.println("    ForIn: {np_var_name.get(id)}")
        print_node(np_iterable.get(id), depth + 1)
        print_node(np_body.get(id), depth + 1)
    } else if kind == NodeKind.Assignment {
        io.println("    Assignment")
        print_node(np_target.get(id), depth + 1)
        print_node(np_value.get(id), depth + 1)
    } else if kind == NodeKind.TypeDef {
        io.println("TypeDef: {name}")
    } else if kind == NodeKind.MatchExpr {
        io.println("    MatchExpr")
        print_node(np_scrutinee.get(id), depth + 1)
    } else if kind == NodeKind.InterpString {
        io.println("      InterpString")
    } else if kind == NodeKind.BoolLit {
        io.println("      BoolLit: {np_int_val.get(id)}")
    } else if kind == NodeKind.StructLit {
        io.println("      StructLit: {np_type_name.get(id)}")
    } else if kind == NodeKind.FieldAccess {
        io.println("      FieldAccess: .{name}")
        print_node(np_obj.get(id), depth + 1)
    } else if kind == NodeKind.UnaryOp {
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
    if name == "fn" { TokenKind.Fn }
    else if name == "let" { TokenKind.Let }
    else if name == "mut" { TokenKind.Mut }
    else if name == "type" { TokenKind.Type }
    else if name == "trait" { TokenKind.Trait }
    else if name == "impl" { TokenKind.Impl }
    else if name == "if" { TokenKind.If }
    else if name == "else" { TokenKind.Else }
    else if name == "match" { TokenKind.Match }
    else if name == "for" { TokenKind.For }
    else if name == "in" { TokenKind.In }
    else if name == "while" { TokenKind.While }
    else if name == "loop" { TokenKind.Loop }
    else if name == "break" { TokenKind.Break }
    else if name == "continue" { TokenKind.Continue }
    else if name == "return" { TokenKind.Return }
    else if name == "pub" { TokenKind.Pub }
    else if name == "self" { TokenKind.Self }
    else if name == "true" { TokenKind.Ident }
    else if name == "false" { TokenKind.Ident }
    else { TokenKind.Ident }
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
            if last_kind != TokenKind.Newline {
                tok_kinds.push(TokenKind.Newline)
                tok_values.push("")
                tok_lines.push(line)
                tok_cols.push(col)
                last_kind = TokenKind.Newline
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
            tok_kinds.push(TokenKind.StringStart)
            tok_values.push("")
            tok_lines.push(t_line)
            tok_cols.push(t_col)
            last_kind = TokenKind.StringStart
            let mut buf = ""
            let mut in_str = 1
            while in_str && p < source.len() {
                let sc = lpeek(source, p)
                if sc == CH_DQUOTE {
                    tok_kinds.push(TokenKind.StringPart)
                    tok_values.push(buf)
                    tok_lines.push(line)
                    tok_cols.push(col)
                    last_kind = TokenKind.StringPart
                    tok_kinds.push(TokenKind.StringEnd)
                    tok_values.push("")
                    tok_lines.push(line)
                    tok_cols.push(col)
                    last_kind = TokenKind.StringEnd
                    p = p + 1
                    col = col + 1
                    in_str = 0
                } else if sc == CH_LBRACE {
                    tok_kinds.push(TokenKind.StringPart)
                    tok_values.push(buf)
                    tok_lines.push(line)
                    tok_cols.push(col)
                    last_kind = TokenKind.StringPart
                    buf = ""
                    tok_kinds.push(TokenKind.InterpStart)
                    tok_values.push("")
                    tok_lines.push(line)
                    tok_cols.push(col)
                    last_kind = TokenKind.InterpStart
                    p = p + 1
                    col = col + 1
                    // Lex the interpolated expression until }
                    let mut depth = 1
                    while depth > 0 && p < source.len() {
                        let ic = lpeek(source, p)
                        if ic == CH_RBRACE {
                            depth = depth - 1
                            if depth == 0 {
                                tok_kinds.push(TokenKind.InterpEnd)
                                tok_values.push("")
                                tok_lines.push(line)
                                tok_cols.push(col)
                                last_kind = TokenKind.InterpEnd
                                p = p + 1
                                col = col + 1
                            } else {
                                tok_kinds.push(TokenKind.RBrace)
                                tok_values.push("}")
                                tok_lines.push(line)
                                tok_cols.push(col)
                                last_kind = TokenKind.RBrace
                                p = p + 1
                                col = col + 1
                            }
                        } else if ic == CH_LBRACE {
                            depth = depth + 1
                            tok_kinds.push(TokenKind.LBrace)
                            tok_values.push("\{")
                            tok_lines.push(line)
                            tok_cols.push(col)
                            last_kind = TokenKind.LBrace
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
                            tok_kinds.push(TokenKind.Int)
                            tok_values.push(source.substring(start, p - start))
                            tok_lines.push(line)
                            tok_cols.push(col)
                            last_kind = TokenKind.Int
                        } else if ic == CH_PLUS {
                            tok_kinds.push(TokenKind.Plus)
                            tok_values.push("+")
                            tok_lines.push(line)
                            tok_cols.push(col)
                            last_kind = TokenKind.Plus
                            p = p + 1
                            col = col + 1
                        } else if ic == CH_MINUS {
                            tok_kinds.push(TokenKind.Minus)
                            tok_values.push("-")
                            tok_lines.push(line)
                            tok_cols.push(col)
                            last_kind = TokenKind.Minus
                            p = p + 1
                            col = col + 1
                        } else if ic == CH_STAR {
                            tok_kinds.push(TokenKind.Star)
                            tok_values.push("*")
                            tok_lines.push(line)
                            tok_cols.push(col)
                            last_kind = TokenKind.Star
                            p = p + 1
                            col = col + 1
                        } else if ic == CH_DOT {
                            tok_kinds.push(TokenKind.Dot)
                            tok_values.push(".")
                            tok_lines.push(line)
                            tok_cols.push(col)
                            last_kind = TokenKind.Dot
                            p = p + 1
                            col = col + 1
                        } else if ic == CH_LPAREN {
                            tok_kinds.push(TokenKind.LParen)
                            tok_values.push("(")
                            tok_lines.push(line)
                            tok_cols.push(col)
                            last_kind = TokenKind.LParen
                            p = p + 1
                            col = col + 1
                        } else if ic == CH_RPAREN {
                            tok_kinds.push(TokenKind.RParen)
                            tok_values.push(")")
                            tok_lines.push(line)
                            tok_cols.push(col)
                            last_kind = TokenKind.RParen
                            p = p + 1
                            col = col + 1
                        } else if ic == CH_COMMA {
                            tok_kinds.push(TokenKind.Comma)
                            tok_values.push(",")
                            tok_lines.push(line)
                            tok_cols.push(col)
                            last_kind = TokenKind.Comma
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
            tok_kinds.push(TokenKind.Int)
            tok_values.push(source.substring(start, p - start))
            tok_lines.push(t_line)
            tok_cols.push(t_col)
            last_kind = TokenKind.Int
            continue
        }

        // Two-char operators
        if ch == CH_MINUS && lpeek(source, p + 1) == CH_GREATER {
            tok_kinds.push(TokenKind.Arrow)
            tok_values.push("->")
            tok_lines.push(line)
            tok_cols.push(col)
            last_kind = TokenKind.Arrow
            p = p + 2
            col = col + 2
            continue
        }
        if ch == CH_EQUALS && lpeek(source, p + 1) == CH_GREATER {
            tok_kinds.push(TokenKind.FatArrow)
            tok_values.push("=>")
            tok_lines.push(line)
            tok_cols.push(col)
            last_kind = TokenKind.FatArrow
            p = p + 2
            col = col + 2
            continue
        }
        if ch == CH_EQUALS && lpeek(source, p + 1) == CH_EQUALS {
            tok_kinds.push(TokenKind.EqEq)
            tok_values.push("==")
            tok_lines.push(line)
            tok_cols.push(col)
            last_kind = TokenKind.EqEq
            p = p + 2
            col = col + 2
            continue
        }
        if ch == CH_BANG && lpeek(source, p + 1) == CH_EQUALS {
            tok_kinds.push(TokenKind.NotEq)
            tok_values.push("!=")
            tok_lines.push(line)
            tok_cols.push(col)
            last_kind = TokenKind.NotEq
            p = p + 2
            col = col + 2
            continue
        }
        if ch == CH_LESS && lpeek(source, p + 1) == CH_EQUALS {
            tok_kinds.push(TokenKind.LessEq)
            tok_values.push("<=")
            tok_lines.push(line)
            tok_cols.push(col)
            last_kind = TokenKind.LessEq
            p = p + 2
            col = col + 2
            continue
        }
        if ch == CH_GREATER && lpeek(source, p + 1) == CH_EQUALS {
            tok_kinds.push(TokenKind.GreaterEq)
            tok_values.push(">=")
            tok_lines.push(line)
            tok_cols.push(col)
            last_kind = TokenKind.GreaterEq
            p = p + 2
            col = col + 2
            continue
        }
        if ch == CH_AMP && lpeek(source, p + 1) == CH_AMP {
            tok_kinds.push(TokenKind.And)
            tok_values.push("&&")
            tok_lines.push(line)
            tok_cols.push(col)
            last_kind = TokenKind.And
            p = p + 2
            col = col + 2
            continue
        }
        if ch == CH_PIPE && lpeek(source, p + 1) == CH_PIPE {
            tok_kinds.push(TokenKind.Or)
            tok_values.push("||")
            tok_lines.push(line)
            tok_cols.push(col)
            last_kind = TokenKind.Or
            p = p + 2
            col = col + 2
            continue
        }
        if ch == CH_PIPE && lpeek(source, p + 1) == CH_GREATER {
            tok_kinds.push(TokenKind.PipeArrow)
            tok_values.push("|>")
            tok_lines.push(line)
            tok_cols.push(col)
            last_kind = TokenKind.PipeArrow
            p = p + 2
            col = col + 2
            continue
        }
        if ch == CH_PLUS && lpeek(source, p + 1) == CH_EQUALS {
            tok_kinds.push(TokenKind.PlusEq)
            tok_values.push("+=")
            tok_lines.push(line)
            tok_cols.push(col)
            last_kind = TokenKind.PlusEq
            p = p + 2
            col = col + 2
            continue
        }
        if ch == CH_MINUS && lpeek(source, p + 1) == CH_EQUALS {
            tok_kinds.push(TokenKind.MinusEq)
            tok_values.push("-=")
            tok_lines.push(line)
            tok_cols.push(col)
            last_kind = TokenKind.MinusEq
            p = p + 2
            col = col + 2
            continue
        }
        if ch == CH_STAR && lpeek(source, p + 1) == CH_EQUALS {
            tok_kinds.push(TokenKind.StarEq)
            tok_values.push("*=")
            tok_lines.push(line)
            tok_cols.push(col)
            last_kind = TokenKind.StarEq
            p = p + 2
            col = col + 2
            continue
        }
        if ch == CH_DOT && lpeek(source, p + 1) == CH_DOT {
            if lpeek(source, p + 2) == CH_EQUALS {
                tok_kinds.push(TokenKind.DotDoteq)
                tok_values.push("..=")
                tok_lines.push(line)
                tok_cols.push(col)
                last_kind = TokenKind.DotDoteq
                p = p + 3
                col = col + 3
            } else {
                tok_kinds.push(TokenKind.DotDot)
                tok_values.push("..")
                tok_lines.push(line)
                tok_cols.push(col)
                last_kind = TokenKind.DotDot
                p = p + 2
                col = col + 2
            }
            continue
        }

        // Single-char tokens
        let t_line = line
        let t_col = col
        if ch == CH_LPAREN {
            tok_kinds.push(TokenKind.LParen)
            tok_values.push("(")
        } else if ch == CH_RPAREN {
            tok_kinds.push(TokenKind.RParen)
            tok_values.push(")")
        } else if ch == CH_LBRACE {
            tok_kinds.push(TokenKind.LBrace)
            tok_values.push("\{")
        } else if ch == CH_RBRACE {
            tok_kinds.push(TokenKind.RBrace)
            tok_values.push("\}")
        } else if ch == CH_LBRACKET {
            tok_kinds.push(TokenKind.LBracket)
            tok_values.push("[")
        } else if ch == CH_RBRACKET {
            tok_kinds.push(TokenKind.RBracket)
            tok_values.push("]")
        } else if ch == CH_COLON {
            tok_kinds.push(TokenKind.Colon)
            tok_values.push(":")
        } else if ch == CH_COMMA {
            tok_kinds.push(TokenKind.Comma)
            tok_values.push(",")
        } else if ch == CH_DOT {
            tok_kinds.push(TokenKind.Dot)
            tok_values.push(".")
        } else if ch == CH_PLUS {
            tok_kinds.push(TokenKind.Plus)
            tok_values.push("+")
        } else if ch == CH_MINUS {
            tok_kinds.push(TokenKind.Minus)
            tok_values.push("-")
        } else if ch == CH_STAR {
            tok_kinds.push(TokenKind.Star)
            tok_values.push("*")
        } else if ch == CH_SLASH {
            tok_kinds.push(TokenKind.Slash)
            tok_values.push("/")
        } else if ch == CH_PERCENT {
            tok_kinds.push(TokenKind.Percent)
            tok_values.push("%")
        } else if ch == CH_EQUALS {
            tok_kinds.push(TokenKind.Equals)
            tok_values.push("=")
        } else if ch == CH_LESS {
            tok_kinds.push(TokenKind.Less)
            tok_values.push("<")
        } else if ch == CH_GREATER {
            tok_kinds.push(TokenKind.Greater)
            tok_values.push(">")
        } else if ch == CH_BANG {
            tok_kinds.push(TokenKind.Bang)
            tok_values.push("!")
        } else if ch == CH_QUESTION {
            tok_kinds.push(TokenKind.Question)
            tok_values.push("?")
        } else if ch == CH_PIPE {
            tok_kinds.push(TokenKind.Pipe)
            tok_values.push("|")
        } else if ch == CH_AT {
            tok_kinds.push(TokenKind.At)
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

    tok_kinds.push(TokenKind.EOF)
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
let mut np_trait_name: List[Str] = []
let mut np_params: List[Int] = []
let mut np_args: List[Int] = []
let mut np_stmts: List[Int] = []
let mut np_arms: List[Int] = []
let mut np_fields: List[Int] = []
let mut np_elements: List[Int] = []
let mut np_methods: List[Int] = []

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
let mut enum_reg_names: List[Str] = []
let mut enum_reg_variant_names: List[Str] = []
let mut enum_reg_variant_enum_idx: List[Int] = []
let mut var_enum_names: List[Str] = []
let mut var_enum_types: List[Str] = []
let mut fn_enum_ret_names: List[Str] = []
let mut fn_enum_ret_types: List[Str] = []
let mut emitted_let_names: List[Str] = []
let mut emitted_fn_names: List[Str] = []

// Trait registry: maps trait name -> method names
let mut trait_reg_names: List[Str] = []
let mut trait_reg_method_sl: List[Int] = []

// Impl registry: maps (trait, type) -> method FnDef nodes
let mut impl_reg_trait: List[Str] = []
let mut impl_reg_type: List[Str] = []
let mut impl_reg_methods_sl: List[Int] = []

// Variable-to-struct-type tracking (for method resolution)
let mut var_struct_names: List[Str] = []
let mut var_struct_types: List[Str] = []

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
let mut match_scrut_enum: Str = ""

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

fn is_enum_type(name: Str) -> Int {
    let mut i = 0
    while i < enum_reg_names.len() {
        if enum_reg_names.get(i) == name {
            return 1
        }
        i = i + 1
    }
    0
}

fn resolve_variant(name: Str) -> Str {
    let mut i = 0
    while i < enum_reg_variant_names.len() {
        if enum_reg_variant_names.get(i) == name {
            return enum_reg_names.get(enum_reg_variant_enum_idx.get(i))
        }
        i = i + 1
    }
    ""
}

fn get_var_enum(name: Str) -> Str {
    let mut i = 0
    while i < var_enum_names.len() {
        if var_enum_names.get(i) == name {
            return var_enum_types.get(i)
        }
        i = i + 1
    }
    ""
}

fn get_fn_enum_ret(name: Str) -> Str {
    let mut i = 0
    while i < fn_enum_ret_names.len() {
        if fn_enum_ret_names.get(i) == name {
            return fn_enum_ret_types.get(i)
        }
        i = i + 1
    }
    ""
}

fn set_var_struct(name: Str, type_name: Str) {
    var_struct_names.push(name)
    var_struct_types.push(type_name)
}

fn get_var_struct(name: Str) -> Str {
    let mut i = 0
    while i < var_struct_names.len() {
        if var_struct_names.get(i) == name {
            return var_struct_types.get(i)
        }
        i = i + 1
    }
    ""
}

fn is_trait_type(name: Str) -> Int {
    let mut i = 0
    while i < trait_reg_names.len() {
        if trait_reg_names.get(i) == name {
            return 1
        }
        i = i + 1
    }
    0
}

fn lookup_impl_method(type_name: Str, method: Str) -> Int {
    let mut i = 0
    while i < impl_reg_type.len() {
        if impl_reg_type.get(i) == type_name {
            let methods_sl = impl_reg_methods_sl.get(i)
            let mut j = 0
            while j < sublist_length(methods_sl) {
                let m = sublist_get(methods_sl, j)
                if np_name.get(m) == method {
                    return 1
                }
                j = j + 1
            }
        }
        i = i + 1
    }
    0
}

fn lookup_impl_type_for_trait(trait_name: Str, type_name: Str) -> Int {
    let mut i = 0
    while i < impl_reg_trait.len() {
        if impl_reg_trait.get(i) == trait_name && impl_reg_type.get(i) == type_name {
            return 1
        }
        i = i + 1
    }
    0
}

fn get_impl_method_ret(type_name: Str, method: Str) -> Int {
    let mut i = 0
    while i < impl_reg_type.len() {
        if impl_reg_type.get(i) == type_name {
            let methods_sl = impl_reg_methods_sl.get(i)
            let mut j = 0
            while j < sublist_length(methods_sl) {
                let m = sublist_get(methods_sl, j)
                if np_name.get(m) == method {
                    let ret_str = np_return_type.get(m)
                    return type_from_name(ret_str)
                }
                j = j + 1
            }
        }
        i = i + 1
    }
    CT_VOID
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

    if kind == NodeKind.IntLit {
        let s = np_str_val.get(node)
        if s == "" {
            expr_result_str = "{np_int_val.get(node)}"
        } else {
            expr_result_str = s
        }
        expr_result_type = CT_INT
        return
    }

    if kind == NodeKind.FloatLit {
        expr_result_str = np_str_val.get(node)
        expr_result_type = CT_FLOAT
        return
    }

    if kind == NodeKind.BoolLit {
        if np_int_val.get(node) != 0 {
            expr_result_str = "1"
        } else {
            expr_result_str = "0"
        }
        expr_result_type = CT_BOOL
        return
    }

    if kind == NodeKind.Ident {
        let name = np_name.get(node)
        let variant_enum = resolve_variant(name)
        if variant_enum != "" {
            expr_result_str = "pact_{variant_enum}_{name}"
            expr_result_type = CT_INT
            return
        }
        expr_result_str = name
        expr_result_type = get_var_type(name)
        return
    }

    if kind == NodeKind.BinOp {
        emit_binop(node)
        return
    }

    if kind == NodeKind.UnaryOp {
        emit_unaryop(node)
        return
    }

    if kind == NodeKind.Call {
        emit_call(node)
        return
    }

    if kind == NodeKind.MethodCall {
        emit_method_call(node)
        return
    }

    if kind == NodeKind.InterpString {
        emit_interp_string(node)
        return
    }

    if kind == NodeKind.IfExpr {
        emit_if_expr(node)
        return
    }

    if kind == NodeKind.FieldAccess {
        let fa_obj = np_obj.get(node)
        let fa_field = np_name.get(node)
        if np_kind.get(fa_obj) == NodeKind.Ident {
            let obj_name = np_name.get(fa_obj)
            if is_enum_type(obj_name) != 0 {
                expr_result_str = "pact_{obj_name}_{fa_field}"
                expr_result_type = CT_INT
                return
            }
        }
        emit_expr(fa_obj)
        let obj_str = expr_result_str
        expr_result_str = "{obj_str}.{fa_field}"
        expr_result_type = CT_VOID
        return
    }

    if kind == NodeKind.IndexExpr {
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

    if kind == NodeKind.ListLit {
        emit_list_lit(node)
        return
    }

    if kind == NodeKind.RangeLit {
        expr_result_str = "0"
        expr_result_type = CT_VOID
        return
    }

    if kind == NodeKind.MatchExpr {
        emit_match_expr(node)
        return
    }

    if kind == NodeKind.Block {
        emit_block_expr(node)
        return
    }

    if kind == NodeKind.Return {
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

    if kind == NodeKind.StructLit {
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
    if func_kind == NodeKind.Ident {
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
    // Qualified trait call: Trait.method(x, ...)
    if func_kind == NodeKind.FieldAccess {
        let trait_obj = np_obj.get(func_node)
        if np_kind.get(trait_obj) == NodeKind.Ident {
            let trait_name = np_name.get(trait_obj)
            if is_trait_type(trait_name) != 0 {
                let method = np_name.get(func_node)
                let args_sl = np_args.get(node)
                // First arg determines the type
                if args_sl != -1 && sublist_length(args_sl) > 0 {
                    emit_expr(sublist_get(args_sl, 0))
                    let first_str = expr_result_str
                    let type_name = get_var_struct(first_str)
                    if type_name != "" {
                        let mangled = "{type_name}_{method}"
                        let mut args_str = first_str
                        let mut i = 1
                        while i < sublist_length(args_sl) {
                            args_str = args_str.concat(", ")
                            emit_expr(sublist_get(args_sl, i))
                            args_str = args_str.concat(expr_result_str)
                            i = i + 1
                        }
                        expr_result_str = "pact_{mangled}({args_str})"
                        expr_result_type = get_impl_method_ret(type_name, method)
                        return
                    }
                }
            }
        }
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
    if np_kind.get(obj_node) == NodeKind.Ident && np_name.get(obj_node) == "io" && method == "println" {
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

    // Qualified trait call: Trait.method(args) parsed as MethodCall(obj=Trait, method=method)
    if np_kind.get(obj_node) == NodeKind.Ident {
        let trait_name = np_name.get(obj_node)
        if is_trait_type(trait_name) != 0 {
            let args_sl = np_args.get(node)
            if args_sl != -1 && sublist_length(args_sl) > 0 {
                emit_expr(sublist_get(args_sl, 0))
                let first_str = expr_result_str
                let type_name = get_var_struct(first_str)
                if type_name != "" {
                    let mangled = "{type_name}_{method}"
                    let mut args_str = first_str
                    let mut i = 1
                    while i < sublist_length(args_sl) {
                        args_str = args_str.concat(", ")
                        emit_expr(sublist_get(args_sl, i))
                        args_str = args_str.concat(expr_result_str)
                        i = i + 1
                    }
                    expr_result_str = "pact_{mangled}({args_str})"
                    expr_result_type = get_impl_method_ret(type_name, method)
                    return
                }
            }
        }
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

    // Trait impl method resolution
    let struct_type = get_var_struct(obj_str)
    if struct_type != "" && lookup_impl_method(struct_type, method) != 0 {
        let mangled = "{struct_type}_{method}"
        let args_sl = np_args.get(node)
        let mut args_str = obj_str
        if args_sl != -1 {
            let mut i = 0
            while i < sublist_length(args_sl) {
                args_str = args_str.concat(", ")
                emit_expr(sublist_get(args_sl, i))
                args_str = args_str.concat(expr_result_str)
                i = i + 1
            }
        }
        expr_result_str = "pact_{mangled}({args_str})"
        expr_result_type = get_impl_method_ret(struct_type, method)
        return
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
        if !(pk == NodeKind.Ident && np_str_val.get(part) == np_name.get(part)) {
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
        // Literal string parts: parser stores them as NodeKind.Ident with str_val == name
        // Expression parts: NodeKind.Ident with str_val == "" (or other node kinds)
        if pk == NodeKind.Ident && np_str_val.get(part) == np_name.get(part) {
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
    set_var_struct(tmp, sname)
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
    match_scrut_enum = ""

    if np_kind.get(scrut) == NodeKind.TupleLit {
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
        if np_kind.get(scrut) == NodeKind.Ident {
            match_scrut_enum = get_var_enum(np_name.get(scrut))
        } else if np_kind.get(scrut) == NodeKind.FieldAccess {
            match_scrut_enum = infer_enum_from_node(scrut)
        }
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
    if pk == NodeKind.WildcardPattern {
        return ""
    }
    if pk == NodeKind.IdentPattern {
        let pat_name = np_name.get(pat)
        let mut enum_name = match_scrut_enum
        if enum_name == "" {
            enum_name = resolve_variant(pat_name)
        }
        if enum_name != "" {
            return "({match_scrut_strs.get(scrut_off)} == pact_{enum_name}_{pat_name})"
        }
        return ""
    }
    if pk == NodeKind.IntPattern {
        let pat_val = np_str_val.get(pat)
        return "({match_scrut_strs.get(scrut_off)} == {pat_val})"
    }
    if pk == NodeKind.TuplePattern {
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
    if pk == NodeKind.IdentPattern {
        let bind_name = np_name.get(pat)
        let mut enum_name = match_scrut_enum
        if enum_name == "" {
            enum_name = resolve_variant(bind_name)
        }
        if enum_name != "" {
            return
        }
        if scrut_len == 1 {
            let st = match_scrut_types.get(scrut_off)
            emit_line("{c_type_str(st)} {bind_name} = {match_scrut_strs.get(scrut_off)};")
            set_var(bind_name, st, 1)
        }
        return
    }
    if pk == NodeKind.TuplePattern {
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
        if last_kind == NodeKind.ExprStmt {
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
    if kind == NodeKind.Block {
        return emit_block_value(body)
    }
    if kind == NodeKind.ExprStmt {
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
    if last_kind == NodeKind.ExprStmt {
        emit_expr(np_value.get(last))
        return expr_result_str
    }
    if last_kind == NodeKind.IfExpr {
        emit_if_expr(last)
        return expr_result_str
    }
    if last_kind == NodeKind.Return {
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
    if last_kind == NodeKind.ExprStmt {
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
    if kind == NodeKind.Block {
        return infer_block_type(body)
    }
    if kind == NodeKind.ExprStmt {
        return infer_expr_type(np_value.get(body))
    }
    infer_expr_type(body)
}

fn infer_expr_type(node: Int) -> Int {
    if node == -1 {
        return CT_VOID
    }
    let kind = np_kind.get(node)
    if kind == NodeKind.IntLit { return CT_INT }
    if kind == NodeKind.FloatLit { return CT_FLOAT }
    if kind == NodeKind.BoolLit { return CT_BOOL }
    if kind == NodeKind.InterpString { return CT_STRING }
    if kind == NodeKind.ListLit { return CT_LIST }
    if kind == NodeKind.Ident {
        let iname = np_name.get(node)
        if resolve_variant(iname) != "" {
            return CT_INT
        }
        return get_var_type(iname)
    }
    if kind == NodeKind.FieldAccess {
        let fa_obj = np_obj.get(node)
        if np_kind.get(fa_obj) == NodeKind.Ident {
            if is_enum_type(np_name.get(fa_obj)) != 0 {
                return CT_INT
            }
        }
        return CT_VOID
    }
    if kind == NodeKind.IfExpr {
        return infer_block_type(np_then_body.get(node))
    }
    if kind == NodeKind.Call {
        let func_node = np_left.get(node)
        if np_kind.get(func_node) == NodeKind.Ident {
            return get_fn_ret(np_name.get(func_node))
        }
    }
    if kind == NodeKind.BinOp {
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

    if kind == NodeKind.ExprStmt {
        emit_expr(np_value.get(node))
        let s = expr_result_str
        if s != "" && s != "0" {
            emit_line("{s};")
        }
        return
    }

    if kind == NodeKind.LetBinding {
        emit_let_binding(node)
        return
    }

    if kind == NodeKind.Assignment {
        emit_expr(np_target.get(node))
        let target_str = expr_result_str
        emit_expr(np_value.get(node))
        let val_str = expr_result_str
        emit_line("{target_str} = {val_str};")
        return
    }

    if kind == NodeKind.CompoundAssign {
        emit_expr(np_target.get(node))
        let target_str = expr_result_str
        emit_expr(np_value.get(node))
        let val_str = expr_result_str
        let op = np_op.get(node)
        emit_line("{target_str} {op}= {val_str};")
        return
    }

    if kind == NodeKind.Return {
        if np_value.get(node) != -1 {
            emit_expr(np_value.get(node))
            let val_str = expr_result_str
            emit_line("return {val_str};")
        } else {
            emit_line("return;")
        }
        return
    }

    if kind == NodeKind.ForIn {
        emit_for_in(node)
        return
    }

    if kind == NodeKind.WhileLoop {
        emit_expr(np_condition.get(node))
        let cond_str = expr_result_str
        emit_line("while ({cond_str}) \{")
        cg_indent = cg_indent + 1
        emit_block(np_body.get(node))
        cg_indent = cg_indent - 1
        emit_line("}")
        return
    }

    if kind == NodeKind.LoopExpr {
        emit_line("while (1) \{")
        cg_indent = cg_indent + 1
        emit_block(np_body.get(node))
        cg_indent = cg_indent - 1
        emit_line("}")
        return
    }

    if kind == NodeKind.Break {
        emit_line("break;")
        return
    }

    if kind == NodeKind.Continue {
        emit_line("continue;")
        return
    }

    if kind == NodeKind.IfExpr {
        emit_if_stmt(node)
        return
    }

    if kind == NodeKind.MatchExpr {
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

fn infer_enum_from_node(val_node: Int) -> Str {
    let vk = np_kind.get(val_node)
    if vk == NodeKind.FieldAccess {
        let obj = np_obj.get(val_node)
        if np_kind.get(obj) == NodeKind.Ident {
            let obj_name = np_name.get(obj)
            if is_enum_type(obj_name) != 0 {
                return obj_name
            }
        }
    }
    if vk == NodeKind.Ident {
        return resolve_variant(np_name.get(val_node))
    }
    ""
}

fn emit_let_binding(node: Int) {
    let val_node = np_value.get(node)
    let mut enum_type = infer_enum_from_node(val_node)
    let type_ann = np_target.get(node)
    if enum_type == "" && type_ann != -1 {
        let ann_name = np_name.get(type_ann)
        if is_enum_type(ann_name) != 0 {
            enum_type = ann_name
        }
    }
    emit_expr(val_node)
    let val_str = expr_result_str
    let val_type = expr_result_type
    let name = np_name.get(node)
    let is_mut = np_is_mut.get(node)
    set_var(name, val_type, is_mut)
    if enum_type != "" {
        var_enum_names.push(name)
        var_enum_types.push(enum_type)
    }
    if np_kind.get(val_node) == NodeKind.StructLit {
        let sname = np_type_name.get(val_node)
        if is_struct_type(sname) != 0 {
            set_var_struct(name, sname)
        }
    } else if type_ann != -1 {
        let ann_name = np_name.get(type_ann)
        if is_struct_type(ann_name) != 0 {
            set_var_struct(name, ann_name)
        }
    }
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
    let struct_type = get_var_struct(name)
    if enum_type != "" {
        if is_mut != 0 {
            emit_line("pact_{enum_type} {name} = {val_str};")
        } else {
            emit_line("const pact_{enum_type} {name} = {val_str};")
        }
    } else if struct_type != "" {
        if is_mut != 0 {
            emit_line("pact_{struct_type} {name} = {val_str};")
        } else {
            emit_line("const pact_{struct_type} {name} = {val_str};")
        }
    } else {
        let ts = c_type_str(val_type)
        if is_mut != 0 || val_type == CT_STRING {
            emit_line("{ts} {name} = {val_str};")
        } else {
            emit_line("const {ts} {name} = {val_str};")
        }
    }
}

fn emit_for_in(node: Int) {
    let var_name = np_var_name.get(node)
    let iter_node = np_iterable.get(node)
    let iter_kind = np_kind.get(iter_node)

    if iter_kind == NodeKind.RangeLit {
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
            if np_kind.get(inner) == NodeKind.IfExpr {
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
        if i > 0 {
            result = result.concat(", ")
        }
        if is_enum_type(ptype) != 0 {
            result = result.concat("pact_{ptype} {pname}")
        } else {
            let ct = type_from_name(ptype)
            result = result.concat("{c_type_str(ct)} {pname}")
        }
        i = i + 1
    }
    result
}

fn format_impl_params(fn_node: Int, impl_type: Str) -> Str {
    let params_sl = np_params.get(fn_node)
    let mut result = "pact_{impl_type} self"
    if params_sl != -1 {
        let mut i = 0
        while i < sublist_length(params_sl) {
            let p = sublist_get(params_sl, i)
            let pname = np_name.get(p)
            if pname != "self" {
                let ptype = np_type_name.get(p)
                if is_enum_type(ptype) != 0 {
                    result = result.concat(", pact_{ptype} {pname}")
                } else {
                    let ct = type_from_name(ptype)
                    result = result.concat(", {c_type_str(ct)} {pname}")
                }
            }
            i = i + 1
        }
    }
    result
}

fn emit_impl_method_def(fn_node: Int, impl_type: Str) {
    push_scope()
    cg_temp_counter = 0
    let mname = np_name.get(fn_node)
    let mangled = "{impl_type}_{mname}"
    let ret_str = np_return_type.get(fn_node)
    let ret_type = type_from_name(ret_str)
    let params = format_impl_params(fn_node, impl_type)
    let enum_ret = get_fn_enum_ret(mangled)
    let mut sig = ""
    if enum_ret != "" {
        sig = "pact_{enum_ret} pact_{mangled}({params})"
    } else {
        sig = "{c_type_str(ret_type)} pact_{mangled}({params})"
    }

    set_var("self", CT_VOID, 0)
    set_var_struct("self", impl_type)

    let params_sl = np_params.get(fn_node)
    if params_sl != -1 {
        let mut i = 0
        while i < sublist_length(params_sl) {
            let p = sublist_get(params_sl, i)
            let pname = np_name.get(p)
            if pname != "self" {
                let ptype = np_type_name.get(p)
                set_var(pname, type_from_name(ptype), 1)
                if is_struct_type(ptype) != 0 {
                    set_var_struct(pname, ptype)
                }
                if is_enum_type(ptype) != 0 {
                    var_enum_names.push(pname)
                    var_enum_types.push(ptype)
                }
            }
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

fn emit_fn_decl(fn_node: Int) {
    let name = np_name.get(fn_node)
    if name == "main" {
        emit_line("void pact_main(void);")
        return
    }
    let params = format_params(fn_node)
    let enum_ret = get_fn_enum_ret(name)
    if enum_ret != "" {
        emit_line("pact_{enum_ret} pact_{name}({params});")
    } else {
        let ret_str = np_return_type.get(fn_node)
        let ret_type = type_from_name(ret_str)
        emit_line("{c_type_str(ret_type)} pact_{name}({params});")
    }
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
        let enum_ret = get_fn_enum_ret(name)
        if enum_ret != "" {
            sig = "pact_{enum_ret} pact_{name}({params})"
        } else {
            sig = "{c_type_str(ret_type)} pact_{name}({params})"
        }
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
            if is_struct_type(ptype) != 0 {
                set_var_struct(pname, ptype)
            }
            if is_enum_type(ptype) != 0 {
                var_enum_names.push(pname)
                var_enum_types.push(ptype)
            }
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
    if ret_type != CT_VOID && last_kind == NodeKind.ExprStmt {
        emit_expr(np_value.get(last))
        let val_str = expr_result_str
        emit_line("return {val_str};")
    } else if ret_type != CT_VOID && last_kind == NodeKind.IfExpr {
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
        if np_kind.get(first) == NodeKind.TypeVariant {
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

fn emit_enum_typedef(td_node: Int) {
    let name = np_name.get(td_node)
    let flds_sl = np_fields.get(td_node)
    if flds_sl == -1 {
        return
    }
    let enum_idx = enum_reg_names.len()
    enum_reg_names.push(name)
    let mut variants_str = ""
    let mut i = 0
    while i < sublist_length(flds_sl) {
        let v = sublist_get(flds_sl, i)
        let vname = np_name.get(v)
        enum_reg_variant_names.push(vname)
        enum_reg_variant_enum_idx.push(enum_idx)
        if i > 0 {
            variants_str = variants_str.concat(", ")
        }
        variants_str = variants_str.concat("pact_{name}_{vname}")
        i = i + 1
    }
    emit_line("typedef enum \{ {variants_str} } pact_{name};")
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
    enum_reg_names = []
    enum_reg_variant_names = []
    enum_reg_variant_enum_idx = []
    var_enum_names = []
    var_enum_types = []
    fn_enum_ret_names = []
    fn_enum_ret_types = []
    emitted_let_names = []
    emitted_fn_names = []
    trait_reg_names = []
    trait_reg_method_sl = []
    impl_reg_trait = []
    impl_reg_type = []
    impl_reg_methods_sl = []
    var_struct_names = []
    var_struct_types = []

    push_scope()

    // Register builtins
    reg_fn("arg_count", CT_INT)
    reg_fn("get_arg", CT_STRING)
    reg_fn("read_file", CT_STRING)
    reg_fn("write_file", CT_VOID)

    // Preamble: include runtime
    cg_lines.push("#include \"runtime.h\"")
    cg_lines.push("")

    // Register type names first (struct or enum)
    let types_sl = np_fields.get(program)
    if types_sl != -1 {
        let mut i = 0
        while i < sublist_length(types_sl) {
            let td = sublist_get(types_sl, i)
            let td_flds = np_fields.get(td)
            let mut is_enum = 0
            if td_flds != -1 && sublist_length(td_flds) > 0 {
                if np_kind.get(sublist_get(td_flds, 0)) == NodeKind.TypeVariant {
                    is_enum = 1
                }
            }
            if is_enum == 0 {
                struct_reg_names.push(np_name.get(td))
            }
            i = i + 1
        }
    }

    // Type definitions (structs and enums)
    if types_sl != -1 {
        let mut i = 0
        while i < sublist_length(types_sl) {
            let td = sublist_get(types_sl, i)
            let td_flds = np_fields.get(td)
            let mut is_enum = 0
            if td_flds != -1 && sublist_length(td_flds) > 0 {
                if np_kind.get(sublist_get(td_flds, 0)) == NodeKind.TypeVariant {
                    is_enum = 1
                }
            }
            if is_enum != 0 {
                emit_enum_typedef(td)
            } else {
                emit_struct_typedef(td)
            }
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
                if is_enum_type(ret_str) != 0 {
                    fn_enum_ret_names.push(fn_name)
                    fn_enum_ret_types.push(ret_str)
                    reg_fn(fn_name, CT_INT)
                } else {
                    reg_fn(fn_name, type_from_name(ret_str))
                }
                emitted_fn_names.push(fn_name)
            }
            i = i + 1
        }
    }

    // Register traits
    let traits_sl = np_arms.get(program)
    if traits_sl != -1 {
        let mut i = 0
        while i < sublist_length(traits_sl) {
            let tr = sublist_get(traits_sl, i)
            trait_reg_names.push(np_name.get(tr))
            trait_reg_method_sl.push(np_methods.get(tr))
            i = i + 1
        }
    }

    // Register impls and their methods
    let impls_sl = np_methods.get(program)
    if impls_sl != -1 {
        let mut i = 0
        while i < sublist_length(impls_sl) {
            let im = sublist_get(impls_sl, i)
            let impl_trait = np_trait_name.get(im)
            let impl_type = np_name.get(im)
            impl_reg_trait.push(impl_trait)
            impl_reg_type.push(impl_type)
            impl_reg_methods_sl.push(np_methods.get(im))
            let methods_sl = np_methods.get(im)
            if methods_sl != -1 {
                let mut j = 0
                while j < sublist_length(methods_sl) {
                    let m = sublist_get(methods_sl, j)
                    let mname = np_name.get(m)
                    let mangled = "{impl_type}_{mname}"
                    let ret_str = np_return_type.get(m)
                    if is_enum_type(ret_str) != 0 {
                        fn_enum_ret_names.push(mangled)
                        fn_enum_ret_types.push(ret_str)
                        reg_fn(mangled, CT_INT)
                    } else {
                        reg_fn(mangled, type_from_name(ret_str))
                    }
                    j = j + 1
                }
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

    // Impl method forward declarations
    if impls_sl != -1 {
        let mut i = 0
        while i < sublist_length(impls_sl) {
            let im = sublist_get(impls_sl, i)
            let impl_type = np_name.get(im)
            let methods_sl = np_methods.get(im)
            if methods_sl != -1 {
                let mut j = 0
                while j < sublist_length(methods_sl) {
                    let m = sublist_get(methods_sl, j)
                    let mname = np_name.get(m)
                    let mangled = "{impl_type}_{mname}"
                    let params = format_impl_params(m, impl_type)
                    let enum_ret = get_fn_enum_ret(mangled)
                    if enum_ret != "" {
                        emit_line("pact_{enum_ret} pact_{mangled}({params});")
                    } else {
                        let ret_str = np_return_type.get(m)
                        let ret_type = type_from_name(ret_str)
                        emit_line("{c_type_str(ret_type)} pact_{mangled}({params});")
                    }
                    j = j + 1
                }
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

    // Impl method definitions
    if impls_sl != -1 {
        let mut i = 0
        while i < sublist_length(impls_sl) {
            let im = sublist_get(impls_sl, i)
            let impl_type = np_name.get(im)
            let methods_sl = np_methods.get(im)
            if methods_sl != -1 {
                let mut j = 0
                while j < sublist_length(methods_sl) {
                    let m = sublist_get(methods_sl, j)
                    emit_impl_method_def(m, impl_type)
                    emit_line("")
                    j = j + 1
                }
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
