#include "runtime.h"

typedef enum { pact_TokenKind_Fn, pact_TokenKind_Let, pact_TokenKind_Mut, pact_TokenKind_Type, pact_TokenKind_Trait, pact_TokenKind_Impl, pact_TokenKind_If, pact_TokenKind_Else, pact_TokenKind_Match, pact_TokenKind_For, pact_TokenKind_In, pact_TokenKind_While, pact_TokenKind_Loop, pact_TokenKind_Break, pact_TokenKind_Continue, pact_TokenKind_Return, pact_TokenKind_Pub, pact_TokenKind_With, pact_TokenKind_Handler, pact_TokenKind_Self, pact_TokenKind_Test, pact_TokenKind_Import, pact_TokenKind_As, pact_TokenKind_Mod, pact_TokenKind_Assert, pact_TokenKind_AssertEq, pact_TokenKind_AssertNe, pact_TokenKind_Ident, pact_TokenKind_Int, pact_TokenKind_Float, pact_TokenKind_StringStart, pact_TokenKind_StringEnd, pact_TokenKind_StringPart, pact_TokenKind_InterpStart, pact_TokenKind_InterpEnd, pact_TokenKind_LParen, pact_TokenKind_RParen, pact_TokenKind_LBrace, pact_TokenKind_RBrace, pact_TokenKind_LBracket, pact_TokenKind_RBracket, pact_TokenKind_Colon, pact_TokenKind_Comma, pact_TokenKind_Dot, pact_TokenKind_DotDot, pact_TokenKind_DotDoteq, pact_TokenKind_Arrow, pact_TokenKind_FatArrow, pact_TokenKind_At, pact_TokenKind_Plus, pact_TokenKind_Minus, pact_TokenKind_Star, pact_TokenKind_Slash, pact_TokenKind_Percent, pact_TokenKind_Equals, pact_TokenKind_EqEq, pact_TokenKind_NotEq, pact_TokenKind_Less, pact_TokenKind_Greater, pact_TokenKind_LessEq, pact_TokenKind_GreaterEq, pact_TokenKind_And, pact_TokenKind_Or, pact_TokenKind_Bang, pact_TokenKind_Question, pact_TokenKind_DoubleQuestion, pact_TokenKind_Pipe, pact_TokenKind_PipeArrow, pact_TokenKind_PlusEq, pact_TokenKind_MinusEq, pact_TokenKind_StarEq, pact_TokenKind_SlashEq, pact_TokenKind_Newline, pact_TokenKind_EOF } pact_TokenKind;

typedef struct {
    int64_t kind;
    const char* value;
    int64_t line;
    int64_t col;
} pact_Token;

typedef enum { pact_NodeKind_IntLit, pact_NodeKind_FloatLit, pact_NodeKind_Ident, pact_NodeKind_Call, pact_NodeKind_MethodCall, pact_NodeKind_BinOp, pact_NodeKind_UnaryOp, pact_NodeKind_InterpString, pact_NodeKind_BoolLit, pact_NodeKind_TupleLit, pact_NodeKind_ListLit, pact_NodeKind_StructLit, pact_NodeKind_FieldAccess, pact_NodeKind_IndexExpr, pact_NodeKind_RangeLit, pact_NodeKind_IfExpr, pact_NodeKind_MatchExpr, pact_NodeKind_Closure, pact_NodeKind_LetBinding, pact_NodeKind_ExprStmt, pact_NodeKind_Assignment, pact_NodeKind_CompoundAssign, pact_NodeKind_Return, pact_NodeKind_ForIn, pact_NodeKind_WhileLoop, pact_NodeKind_LoopExpr, pact_NodeKind_Break, pact_NodeKind_Continue, pact_NodeKind_Block, pact_NodeKind_FnDef, pact_NodeKind_Param, pact_NodeKind_Program, pact_NodeKind_TypeDef, pact_NodeKind_TypeField, pact_NodeKind_TypeVariant, pact_NodeKind_TraitDef, pact_NodeKind_ImplBlock, pact_NodeKind_TestBlock, pact_NodeKind_IntPattern, pact_NodeKind_WildcardPattern, pact_NodeKind_IdentPattern, pact_NodeKind_TuplePattern, pact_NodeKind_StringPattern, pact_NodeKind_OrPattern, pact_NodeKind_RangePattern, pact_NodeKind_StructPattern, pact_NodeKind_EnumPattern, pact_NodeKind_AsPattern, pact_NodeKind_MatchArm, pact_NodeKind_StructLitField, pact_NodeKind_WithBlock, pact_NodeKind_HandlerExpr, pact_NodeKind_Annotation, pact_NodeKind_ModBlock, pact_NodeKind_ImportStmt, pact_NodeKind_TypeAnn } pact_NodeKind;

typedef struct {
    int64_t kind;
    int64_t int_val;
    int64_t float_val;
    const char* str_val;
    const char* name;
    const char* op;
    int64_t left;
    int64_t right;
    pact_list* params;
    int64_t body;
    const char* return_type;
    pact_list* stmts;
    int64_t condition;
    int64_t then_body;
    int64_t else_body;
    pact_list* arms;
    int64_t pattern;
    int64_t scrutinee;
    int64_t guard;
    pact_list* elements;
    pact_list* fields;
    const char* type_name;
    int64_t is_mut;
    int64_t is_pub;
    int64_t value;
    int64_t target;
    int64_t iterable;
    const char* var_name;
    int64_t inclusive;
    int64_t start;
    int64_t end;
    int64_t obj;
    const char* method;
    int64_t index;
    pact_list* args;
    const char* path;
    pact_list* names;
    pact_list* type_params;
    int64_t optional;
    pact_list* handlers;
    const char* as_binding;
    pact_list* super_traits;
    const char* trait_name;
    pact_list* methods;
    pact_list* ann_args;
    int64_t rest;
    const char* variant;
    pact_list* enum_fields;
    pact_list* alternatives;
    int64_t inner;
    pact_list* effects;
    pact_list* annotations;
} pact_Node;

static const int64_t MODE_NORMAL = 0;
static const int64_t MODE_STRING = 1;
static const int64_t CH_TAB = 9;
static const int64_t CH_NEWLINE = 10;
static const int64_t CH_SPACE = 32;
static const int64_t CH_DQUOTE = 34;
static const int64_t CH_PERCENT = 37;
static const int64_t CH_LPAREN = 40;
static const int64_t CH_RPAREN = 41;
static const int64_t CH_STAR = 42;
static const int64_t CH_PLUS = 43;
static const int64_t CH_COMMA = 44;
static const int64_t CH_MINUS = 45;
static const int64_t CH_DOT = 46;
static const int64_t CH_SLASH = 47;
static const int64_t CH_0 = 48;
static const int64_t CH_9 = 57;
static const int64_t CH_COLON = 58;
static const int64_t CH_LESS = 60;
static const int64_t CH_EQUALS = 61;
static const int64_t CH_GREATER = 62;
static const int64_t CH_QUESTION = 63;
static const int64_t CH_AT = 64;
static const int64_t CH_A = 65;
static const int64_t CH_Z = 90;
static const int64_t CH_LBRACKET = 91;
static const int64_t CH_BACKSLASH = 92;
static const int64_t CH_RBRACKET = 93;
static const int64_t CH_UNDERSCORE = 95;
static const int64_t CH_a = 97;
static const int64_t CH_n = 110;
static const int64_t CH_t = 116;
static const int64_t CH_Z_LOWER = 122;
static const int64_t CH_LBRACE = 123;
static const int64_t CH_PIPE = 124;
static const int64_t CH_RBRACE = 125;
static const int64_t CH_BANG = 33;
static const int64_t CH_AMP = 38;
static pact_list* tok_kinds;
static pact_list* tok_values;
static pact_list* tok_lines;
static pact_list* tok_cols;
static pact_list* np_kind;
static pact_list* np_int_val;
static pact_list* np_str_val;
static pact_list* np_name;
static pact_list* np_op;
static pact_list* np_left;
static pact_list* np_right;
static pact_list* np_body;
static pact_list* np_condition;
static pact_list* np_then_body;
static pact_list* np_else_body;
static pact_list* np_scrutinee;
static pact_list* np_pattern;
static pact_list* np_guard;
static pact_list* np_value;
static pact_list* np_target;
static pact_list* np_iterable;
static pact_list* np_var_name;
static pact_list* np_is_mut;
static pact_list* np_is_pub;
static pact_list* np_inclusive;
static pact_list* np_start;
static pact_list* np_end;
static pact_list* np_obj;
static pact_list* np_method;
static pact_list* np_index;
static pact_list* np_return_type;
static pact_list* np_type_name;
static pact_list* np_trait_name;
static pact_list* sl_items;
static pact_list* sl_start;
static pact_list* sl_len;
static pact_list* np_params;
static pact_list* np_args;
static pact_list* np_stmts;
static pact_list* np_arms;
static pact_list* np_fields;
static pact_list* np_elements;
static pact_list* np_methods;
static int64_t pos = 0;
static const int64_t CH_z = 122;
static const int64_t CT_INT = 0;
static const int64_t CT_FLOAT = 1;
static const int64_t CT_BOOL = 2;
static const int64_t CT_STRING = 3;
static const int64_t CT_LIST = 4;
static const int64_t CT_VOID = 5;
static pact_list* cg_lines;
static int64_t cg_indent = 0;
static int64_t cg_temp_counter = 0;
static pact_list* cg_global_inits;
static pact_list* struct_reg_names;
static pact_list* enum_reg_names;
static pact_list* enum_reg_variant_names;
static pact_list* enum_reg_variant_enum_idx;
static pact_list* var_enum_names;
static pact_list* var_enum_types;
static pact_list* fn_enum_ret_names;
static pact_list* fn_enum_ret_types;
static pact_list* emitted_let_names;
static pact_list* emitted_fn_names;
static pact_list* trait_reg_names;
static pact_list* trait_reg_method_sl;
static pact_list* impl_reg_trait;
static pact_list* impl_reg_type;
static pact_list* impl_reg_methods_sl;
static pact_list* var_struct_names;
static pact_list* var_struct_types;
static pact_list* scope_names;
static pact_list* scope_types;
static pact_list* scope_muts;
static pact_list* scope_frame_starts;
static pact_list* fn_reg_names;
static pact_list* fn_reg_ret;
static pact_list* var_list_elem_names;
static pact_list* var_list_elem_types;
static pact_list* match_scrut_strs;
static pact_list* match_scrut_types;
static const char* match_scrut_enum = "";
static const char* expr_result_str = "";
static int64_t expr_result_type = 0;

void pact_make_token(int64_t kind, const char* value, int64_t line, int64_t col);
const char* pact_token_kind_name(int64_t kind);
int64_t pact_is_keyword(int64_t kind);
int64_t pact_keyword_lookup(const char* name);
const char* pact_node_kind_name(int64_t kind);
int64_t pact_is_alpha(int64_t c);
int64_t pact_is_digit(int64_t c);
int64_t pact_is_alnum(int64_t c);
int64_t pact_is_whitespace(int64_t c);
int64_t pact_peek(const char* source, int64_t pos);
int64_t pact_peek_at(const char* source, int64_t pos, int64_t offset);
void pact_lex(const char* source);
int64_t pact_new_node(int64_t kind);
int64_t pact_new_sublist(void);
void pact_sublist_push(int64_t sl, int64_t node_id);
void pact_finalize_sublist(int64_t sl);
int64_t pact_sublist_get(int64_t sl, int64_t idx);
int64_t pact_sublist_length(int64_t sl);
int64_t pact_peek_kind(void);
const char* pact_peek_value(void);
int64_t pact_peek_line(void);
int64_t pact_peek_col(void);
int64_t pact_at(int64_t kind);
int64_t pact_advance(void);
const char* pact_advance_value(void);
int64_t pact_expect(int64_t kind);
const char* pact_expect_value(int64_t kind);
void pact_skip_newlines(void);
void pact_maybe_newline(void);
int64_t pact_parse_program(void);
int64_t pact_parse_type_def(void);
int64_t pact_parse_type_annotation(void);
int64_t pact_parse_fn_def(void);
int64_t pact_parse_param(void);
int64_t pact_parse_trait_def(void);
int64_t pact_parse_impl_block(void);
int64_t pact_parse_block(void);
int64_t pact_parse_stmt(void);
int64_t pact_parse_let_binding(void);
int64_t pact_parse_return_stmt(void);
int64_t pact_parse_if_expr(void);
int64_t pact_parse_while_loop(void);
int64_t pact_parse_loop_expr(void);
int64_t pact_parse_for_in(void);
int64_t pact_parse_expr(void);
int64_t pact_parse_or(void);
int64_t pact_parse_and(void);
int64_t pact_parse_equality(void);
int64_t pact_parse_comparison(void);
int64_t pact_parse_additive(void);
int64_t pact_parse_multiplicative(void);
int64_t pact_parse_unary(void);
int64_t pact_parse_postfix(void);
void pact_skip_named_arg_label(void);
const char* pact_flatten_field_access(int64_t node);
int64_t pact_looks_like_struct_lit(void);
int64_t pact_parse_primary(void);
int64_t pact_parse_struct_lit(const char* type_name);
int64_t pact_parse_list_lit(void);
int64_t pact_parse_interp_string(void);
int64_t pact_parse_match_expr(void);
int64_t pact_parse_match_arm(void);
int64_t pact_parse_pattern(void);
void pact_print_indent(int64_t depth);
void pact_print_node(int64_t id, int64_t depth);
int64_t pact_lpeek(const char* source, int64_t p);
void pact_mini_lex(const char* source);
void pact_push_scope(void);
void pact_pop_scope(void);
void pact_set_var(const char* name, int64_t ctype, int64_t is_mut);
int64_t pact_get_var_type(const char* name);
void pact_reg_fn(const char* name, int64_t ret);
int64_t pact_get_fn_ret(const char* name);
void pact_set_list_elem_type(const char* name, int64_t elem_type);
int64_t pact_get_list_elem_type(const char* name);
int64_t pact_is_struct_type(const char* name);
int64_t pact_is_enum_type(const char* name);
const char* pact_resolve_variant(const char* name);
const char* pact_get_var_enum(const char* name);
const char* pact_get_fn_enum_ret(const char* name);
void pact_set_var_struct(const char* name, const char* type_name);
const char* pact_get_var_struct(const char* name);
int64_t pact_is_trait_type(const char* name);
int64_t pact_lookup_impl_method(const char* type_name, const char* method);
int64_t pact_lookup_impl_type_for_trait(const char* trait_name, const char* type_name);
int64_t pact_get_impl_method_ret(const char* type_name, const char* method);
int64_t pact_is_emitted_let(const char* name);
int64_t pact_is_emitted_fn(const char* name);
const char* pact_c_type_str(int64_t ct);
int64_t pact_type_from_name(const char* name);
const char* pact_fresh_temp(const char* prefix);
void pact_emit_line(const char* line);
const char* pact_join_lines(void);
void pact_emit_expr(int64_t node);
void pact_emit_binop(int64_t node);
void pact_emit_unaryop(int64_t node);
void pact_emit_call(int64_t node);
void pact_emit_method_call(int64_t node);
const char* pact_escape_c_string(const char* s);
void pact_emit_interp_string(int64_t node);
void pact_emit_list_lit(int64_t node);
void pact_emit_struct_lit(int64_t node);
void pact_emit_if_expr(int64_t node);
void pact_emit_match_expr(int64_t node);
const char* pact_pattern_condition(int64_t pat, int64_t scrut_off, int64_t scrut_len);
void pact_bind_pattern_vars(int64_t pat, int64_t scrut_off, int64_t scrut_len);
void pact_emit_block_expr(int64_t node);
const char* pact_emit_arm_value(int64_t body);
const char* pact_emit_block_value(int64_t block);
int64_t pact_infer_block_type(int64_t block);
int64_t pact_infer_arm_type(int64_t arm);
int64_t pact_infer_expr_type(int64_t node);
void pact_emit_stmt(int64_t node);
const char* pact_infer_enum_from_node(int64_t val_node);
void pact_emit_let_binding(int64_t node);
void pact_emit_for_in(int64_t node);
void pact_emit_if_stmt(int64_t node);
void pact_emit_block(int64_t block);
const char* pact_format_params(int64_t fn_node);
const char* pact_format_impl_params(int64_t fn_node, const char* impl_type);
void pact_emit_impl_method_def(int64_t fn_node, const char* impl_type);
void pact_emit_fn_decl(int64_t fn_node);
void pact_emit_fn_def(int64_t fn_node);
void pact_emit_fn_body(int64_t block, int64_t ret_type);
void pact_emit_struct_typedef(int64_t td_node);
void pact_emit_enum_typedef(int64_t td_node);
void pact_emit_top_level_let(int64_t node);
const char* pact_generate(int64_t program);
void pact_main(void);

void pact_make_token(int64_t kind, const char* value, int64_t line, int64_t col) {
    pact_Token _s0 = { .kind = kind, .value = value, .line = line, .col = col };
    _s0;
}

const char* pact_token_kind_name(int64_t kind) {
    const char* _if_0;
    if ((kind == pact_TokenKind_Fn)) {
        _if_0 = "fn";
    } else {
        const char* _if_1;
        if ((kind == pact_TokenKind_Let)) {
            _if_1 = "let";
        } else {
            const char* _if_2;
            if ((kind == pact_TokenKind_Mut)) {
                _if_2 = "mut";
            } else {
                const char* _if_3;
                if ((kind == pact_TokenKind_Type)) {
                    _if_3 = "type";
                } else {
                    const char* _if_4;
                    if ((kind == pact_TokenKind_Trait)) {
                        _if_4 = "trait";
                    } else {
                        const char* _if_5;
                        if ((kind == pact_TokenKind_Impl)) {
                            _if_5 = "impl";
                        } else {
                            const char* _if_6;
                            if ((kind == pact_TokenKind_If)) {
                                _if_6 = "if";
                            } else {
                                const char* _if_7;
                                if ((kind == pact_TokenKind_Else)) {
                                    _if_7 = "else";
                                } else {
                                    const char* _if_8;
                                    if ((kind == pact_TokenKind_Match)) {
                                        _if_8 = "match";
                                    } else {
                                        const char* _if_9;
                                        if ((kind == pact_TokenKind_For)) {
                                            _if_9 = "for";
                                        } else {
                                            const char* _if_10;
                                            if ((kind == pact_TokenKind_In)) {
                                                _if_10 = "in";
                                            } else {
                                                const char* _if_11;
                                                if ((kind == pact_TokenKind_While)) {
                                                    _if_11 = "while";
                                                } else {
                                                    const char* _if_12;
                                                    if ((kind == pact_TokenKind_Loop)) {
                                                        _if_12 = "loop";
                                                    } else {
                                                        const char* _if_13;
                                                        if ((kind == pact_TokenKind_Break)) {
                                                            _if_13 = "break";
                                                        } else {
                                                            const char* _if_14;
                                                            if ((kind == pact_TokenKind_Continue)) {
                                                                _if_14 = "continue";
                                                            } else {
                                                                const char* _if_15;
                                                                if ((kind == pact_TokenKind_Return)) {
                                                                    _if_15 = "return";
                                                                } else {
                                                                    const char* _if_16;
                                                                    if ((kind == pact_TokenKind_Pub)) {
                                                                        _if_16 = "pub";
                                                                    } else {
                                                                        const char* _if_17;
                                                                        if ((kind == pact_TokenKind_With)) {
                                                                            _if_17 = "with";
                                                                        } else {
                                                                            const char* _if_18;
                                                                            if ((kind == pact_TokenKind_Handler)) {
                                                                                _if_18 = "handler";
                                                                            } else {
                                                                                const char* _if_19;
                                                                                if ((kind == pact_TokenKind_Self)) {
                                                                                    _if_19 = "self";
                                                                                } else {
                                                                                    const char* _if_20;
                                                                                    if ((kind == pact_TokenKind_Test)) {
                                                                                        _if_20 = "test";
                                                                                    } else {
                                                                                        const char* _if_21;
                                                                                        if ((kind == pact_TokenKind_Import)) {
                                                                                            _if_21 = "import";
                                                                                        } else {
                                                                                            const char* _if_22;
                                                                                            if ((kind == pact_TokenKind_As)) {
                                                                                                _if_22 = "as";
                                                                                            } else {
                                                                                                const char* _if_23;
                                                                                                if ((kind == pact_TokenKind_Mod)) {
                                                                                                    _if_23 = "mod";
                                                                                                } else {
                                                                                                    const char* _if_24;
                                                                                                    if ((kind == pact_TokenKind_Assert)) {
                                                                                                        _if_24 = "assert";
                                                                                                    } else {
                                                                                                        const char* _if_25;
                                                                                                        if ((kind == pact_TokenKind_AssertEq)) {
                                                                                                            _if_25 = "assert_eq";
                                                                                                        } else {
                                                                                                            const char* _if_26;
                                                                                                            if ((kind == pact_TokenKind_AssertNe)) {
                                                                                                                _if_26 = "assert_ne";
                                                                                                            } else {
                                                                                                                const char* _if_27;
                                                                                                                if ((kind == pact_TokenKind_Ident)) {
                                                                                                                    _if_27 = "IDENT";
                                                                                                                } else {
                                                                                                                    const char* _if_28;
                                                                                                                    if ((kind == pact_TokenKind_Int)) {
                                                                                                                        _if_28 = "INT";
                                                                                                                    } else {
                                                                                                                        const char* _if_29;
                                                                                                                        if ((kind == pact_TokenKind_Float)) {
                                                                                                                            _if_29 = "FLOAT";
                                                                                                                        } else {
                                                                                                                            const char* _if_30;
                                                                                                                            if ((kind == pact_TokenKind_StringStart)) {
                                                                                                                                _if_30 = "STRING_START";
                                                                                                                            } else {
                                                                                                                                const char* _if_31;
                                                                                                                                if ((kind == pact_TokenKind_StringEnd)) {
                                                                                                                                    _if_31 = "STRING_END";
                                                                                                                                } else {
                                                                                                                                    const char* _if_32;
                                                                                                                                    if ((kind == pact_TokenKind_StringPart)) {
                                                                                                                                        _if_32 = "STRING_PART";
                                                                                                                                    } else {
                                                                                                                                        const char* _if_33;
                                                                                                                                        if ((kind == pact_TokenKind_InterpStart)) {
                                                                                                                                            _if_33 = "INTERP_START";
                                                                                                                                        } else {
                                                                                                                                            const char* _if_34;
                                                                                                                                            if ((kind == pact_TokenKind_InterpEnd)) {
                                                                                                                                                _if_34 = "INTERP_END";
                                                                                                                                            } else {
                                                                                                                                                const char* _if_35;
                                                                                                                                                if ((kind == pact_TokenKind_LParen)) {
                                                                                                                                                    _if_35 = "(";
                                                                                                                                                } else {
                                                                                                                                                    const char* _if_36;
                                                                                                                                                    if ((kind == pact_TokenKind_RParen)) {
                                                                                                                                                        _if_36 = ")";
                                                                                                                                                    } else {
                                                                                                                                                        const char* _if_37;
                                                                                                                                                        if ((kind == pact_TokenKind_LBrace)) {
                                                                                                                                                            _if_37 = "{";
                                                                                                                                                        } else {
                                                                                                                                                            const char* _if_38;
                                                                                                                                                            if ((kind == pact_TokenKind_RBrace)) {
                                                                                                                                                                _if_38 = "\\";
                                                                                                                                                            } else {
                                                                                                                                                                const char* _if_39;
                                                                                                                                                                if ((kind == pact_TokenKind_LBracket)) {
                                                                                                                                                                    _if_39 = "[";
                                                                                                                                                                } else {
                                                                                                                                                                    const char* _if_40;
                                                                                                                                                                    if ((kind == pact_TokenKind_RBracket)) {
                                                                                                                                                                        _if_40 = "]";
                                                                                                                                                                    } else {
                                                                                                                                                                        const char* _if_41;
                                                                                                                                                                        if ((kind == pact_TokenKind_Colon)) {
                                                                                                                                                                            _if_41 = ":";
                                                                                                                                                                        } else {
                                                                                                                                                                            const char* _if_42;
                                                                                                                                                                            if ((kind == pact_TokenKind_Comma)) {
                                                                                                                                                                                _if_42 = ",";
                                                                                                                                                                            } else {
                                                                                                                                                                                const char* _if_43;
                                                                                                                                                                                if ((kind == pact_TokenKind_Dot)) {
                                                                                                                                                                                    _if_43 = ".";
                                                                                                                                                                                } else {
                                                                                                                                                                                    const char* _if_44;
                                                                                                                                                                                    if ((kind == pact_TokenKind_DotDot)) {
                                                                                                                                                                                        _if_44 = "..";
                                                                                                                                                                                    } else {
                                                                                                                                                                                        const char* _if_45;
                                                                                                                                                                                        if ((kind == pact_TokenKind_DotDoteq)) {
                                                                                                                                                                                            _if_45 = "..=";
                                                                                                                                                                                        } else {
                                                                                                                                                                                            const char* _if_46;
                                                                                                                                                                                            if ((kind == pact_TokenKind_Arrow)) {
                                                                                                                                                                                                _if_46 = "->";
                                                                                                                                                                                            } else {
                                                                                                                                                                                                const char* _if_47;
                                                                                                                                                                                                if ((kind == pact_TokenKind_FatArrow)) {
                                                                                                                                                                                                    _if_47 = "=>";
                                                                                                                                                                                                } else {
                                                                                                                                                                                                    const char* _if_48;
                                                                                                                                                                                                    if ((kind == pact_TokenKind_At)) {
                                                                                                                                                                                                        _if_48 = "@";
                                                                                                                                                                                                    } else {
                                                                                                                                                                                                        const char* _if_49;
                                                                                                                                                                                                        if ((kind == pact_TokenKind_Plus)) {
                                                                                                                                                                                                            _if_49 = "+";
                                                                                                                                                                                                        } else {
                                                                                                                                                                                                            const char* _if_50;
                                                                                                                                                                                                            if ((kind == pact_TokenKind_Minus)) {
                                                                                                                                                                                                                _if_50 = "-";
                                                                                                                                                                                                            } else {
                                                                                                                                                                                                                const char* _if_51;
                                                                                                                                                                                                                if ((kind == pact_TokenKind_Star)) {
                                                                                                                                                                                                                    _if_51 = "*";
                                                                                                                                                                                                                } else {
                                                                                                                                                                                                                    const char* _if_52;
                                                                                                                                                                                                                    if ((kind == pact_TokenKind_Slash)) {
                                                                                                                                                                                                                        _if_52 = "/";
                                                                                                                                                                                                                    } else {
                                                                                                                                                                                                                        const char* _if_53;
                                                                                                                                                                                                                        if ((kind == pact_TokenKind_Percent)) {
                                                                                                                                                                                                                            _if_53 = "%";
                                                                                                                                                                                                                        } else {
                                                                                                                                                                                                                            const char* _if_54;
                                                                                                                                                                                                                            if ((kind == pact_TokenKind_Equals)) {
                                                                                                                                                                                                                                _if_54 = "=";
                                                                                                                                                                                                                            } else {
                                                                                                                                                                                                                                const char* _if_55;
                                                                                                                                                                                                                                if ((kind == pact_TokenKind_EqEq)) {
                                                                                                                                                                                                                                    _if_55 = "==";
                                                                                                                                                                                                                                } else {
                                                                                                                                                                                                                                    const char* _if_56;
                                                                                                                                                                                                                                    if ((kind == pact_TokenKind_NotEq)) {
                                                                                                                                                                                                                                        _if_56 = "!=";
                                                                                                                                                                                                                                    } else {
                                                                                                                                                                                                                                        const char* _if_57;
                                                                                                                                                                                                                                        if ((kind == pact_TokenKind_Less)) {
                                                                                                                                                                                                                                            _if_57 = "<";
                                                                                                                                                                                                                                        } else {
                                                                                                                                                                                                                                            const char* _if_58;
                                                                                                                                                                                                                                            if ((kind == pact_TokenKind_Greater)) {
                                                                                                                                                                                                                                                _if_58 = ">";
                                                                                                                                                                                                                                            } else {
                                                                                                                                                                                                                                                const char* _if_59;
                                                                                                                                                                                                                                                if ((kind == pact_TokenKind_LessEq)) {
                                                                                                                                                                                                                                                    _if_59 = "<=";
                                                                                                                                                                                                                                                } else {
                                                                                                                                                                                                                                                    const char* _if_60;
                                                                                                                                                                                                                                                    if ((kind == pact_TokenKind_GreaterEq)) {
                                                                                                                                                                                                                                                        _if_60 = ">=";
                                                                                                                                                                                                                                                    } else {
                                                                                                                                                                                                                                                        const char* _if_61;
                                                                                                                                                                                                                                                        if ((kind == pact_TokenKind_And)) {
                                                                                                                                                                                                                                                            _if_61 = "&&";
                                                                                                                                                                                                                                                        } else {
                                                                                                                                                                                                                                                            const char* _if_62;
                                                                                                                                                                                                                                                            if ((kind == pact_TokenKind_Or)) {
                                                                                                                                                                                                                                                                _if_62 = "||";
                                                                                                                                                                                                                                                            } else {
                                                                                                                                                                                                                                                                const char* _if_63;
                                                                                                                                                                                                                                                                if ((kind == pact_TokenKind_Bang)) {
                                                                                                                                                                                                                                                                    _if_63 = "!";
                                                                                                                                                                                                                                                                } else {
                                                                                                                                                                                                                                                                    const char* _if_64;
                                                                                                                                                                                                                                                                    if ((kind == pact_TokenKind_Question)) {
                                                                                                                                                                                                                                                                        _if_64 = "?";
                                                                                                                                                                                                                                                                    } else {
                                                                                                                                                                                                                                                                        const char* _if_65;
                                                                                                                                                                                                                                                                        if ((kind == pact_TokenKind_DoubleQuestion)) {
                                                                                                                                                                                                                                                                            _if_65 = "??";
                                                                                                                                                                                                                                                                        } else {
                                                                                                                                                                                                                                                                            const char* _if_66;
                                                                                                                                                                                                                                                                            if ((kind == pact_TokenKind_Pipe)) {
                                                                                                                                                                                                                                                                                _if_66 = "|";
                                                                                                                                                                                                                                                                            } else {
                                                                                                                                                                                                                                                                                const char* _if_67;
                                                                                                                                                                                                                                                                                if ((kind == pact_TokenKind_PipeArrow)) {
                                                                                                                                                                                                                                                                                    _if_67 = "|>";
                                                                                                                                                                                                                                                                                } else {
                                                                                                                                                                                                                                                                                    const char* _if_68;
                                                                                                                                                                                                                                                                                    if ((kind == pact_TokenKind_PlusEq)) {
                                                                                                                                                                                                                                                                                        _if_68 = "+=";
                                                                                                                                                                                                                                                                                    } else {
                                                                                                                                                                                                                                                                                        const char* _if_69;
                                                                                                                                                                                                                                                                                        if ((kind == pact_TokenKind_MinusEq)) {
                                                                                                                                                                                                                                                                                            _if_69 = "-=";
                                                                                                                                                                                                                                                                                        } else {
                                                                                                                                                                                                                                                                                            const char* _if_70;
                                                                                                                                                                                                                                                                                            if ((kind == pact_TokenKind_StarEq)) {
                                                                                                                                                                                                                                                                                                _if_70 = "*=";
                                                                                                                                                                                                                                                                                            } else {
                                                                                                                                                                                                                                                                                                const char* _if_71;
                                                                                                                                                                                                                                                                                                if ((kind == pact_TokenKind_SlashEq)) {
                                                                                                                                                                                                                                                                                                    _if_71 = "/=";
                                                                                                                                                                                                                                                                                                } else {
                                                                                                                                                                                                                                                                                                    const char* _if_72;
                                                                                                                                                                                                                                                                                                    if ((kind == pact_TokenKind_Newline)) {
                                                                                                                                                                                                                                                                                                        _if_72 = "NEWLINE";
                                                                                                                                                                                                                                                                                                    } else {
                                                                                                                                                                                                                                                                                                        const char* _if_73;
                                                                                                                                                                                                                                                                                                        if ((kind == pact_TokenKind_EOF)) {
                                                                                                                                                                                                                                                                                                            _if_73 = "EOF";
                                                                                                                                                                                                                                                                                                        } else {
                                                                                                                                                                                                                                                                                                            _if_73 = "UNKNOWN";
                                                                                                                                                                                                                                                                                                        }
                                                                                                                                                                                                                                                                                                        _if_72 = _if_73;
                                                                                                                                                                                                                                                                                                    }
                                                                                                                                                                                                                                                                                                    _if_71 = _if_72;
                                                                                                                                                                                                                                                                                                }
                                                                                                                                                                                                                                                                                                _if_70 = _if_71;
                                                                                                                                                                                                                                                                                            }
                                                                                                                                                                                                                                                                                            _if_69 = _if_70;
                                                                                                                                                                                                                                                                                        }
                                                                                                                                                                                                                                                                                        _if_68 = _if_69;
                                                                                                                                                                                                                                                                                    }
                                                                                                                                                                                                                                                                                    _if_67 = _if_68;
                                                                                                                                                                                                                                                                                }
                                                                                                                                                                                                                                                                                _if_66 = _if_67;
                                                                                                                                                                                                                                                                            }
                                                                                                                                                                                                                                                                            _if_65 = _if_66;
                                                                                                                                                                                                                                                                        }
                                                                                                                                                                                                                                                                        _if_64 = _if_65;
                                                                                                                                                                                                                                                                    }
                                                                                                                                                                                                                                                                    _if_63 = _if_64;
                                                                                                                                                                                                                                                                }
                                                                                                                                                                                                                                                                _if_62 = _if_63;
                                                                                                                                                                                                                                                            }
                                                                                                                                                                                                                                                            _if_61 = _if_62;
                                                                                                                                                                                                                                                        }
                                                                                                                                                                                                                                                        _if_60 = _if_61;
                                                                                                                                                                                                                                                    }
                                                                                                                                                                                                                                                    _if_59 = _if_60;
                                                                                                                                                                                                                                                }
                                                                                                                                                                                                                                                _if_58 = _if_59;
                                                                                                                                                                                                                                            }
                                                                                                                                                                                                                                            _if_57 = _if_58;
                                                                                                                                                                                                                                        }
                                                                                                                                                                                                                                        _if_56 = _if_57;
                                                                                                                                                                                                                                    }
                                                                                                                                                                                                                                    _if_55 = _if_56;
                                                                                                                                                                                                                                }
                                                                                                                                                                                                                                _if_54 = _if_55;
                                                                                                                                                                                                                            }
                                                                                                                                                                                                                            _if_53 = _if_54;
                                                                                                                                                                                                                        }
                                                                                                                                                                                                                        _if_52 = _if_53;
                                                                                                                                                                                                                    }
                                                                                                                                                                                                                    _if_51 = _if_52;
                                                                                                                                                                                                                }
                                                                                                                                                                                                                _if_50 = _if_51;
                                                                                                                                                                                                            }
                                                                                                                                                                                                            _if_49 = _if_50;
                                                                                                                                                                                                        }
                                                                                                                                                                                                        _if_48 = _if_49;
                                                                                                                                                                                                    }
                                                                                                                                                                                                    _if_47 = _if_48;
                                                                                                                                                                                                }
                                                                                                                                                                                                _if_46 = _if_47;
                                                                                                                                                                                            }
                                                                                                                                                                                            _if_45 = _if_46;
                                                                                                                                                                                        }
                                                                                                                                                                                        _if_44 = _if_45;
                                                                                                                                                                                    }
                                                                                                                                                                                    _if_43 = _if_44;
                                                                                                                                                                                }
                                                                                                                                                                                _if_42 = _if_43;
                                                                                                                                                                            }
                                                                                                                                                                            _if_41 = _if_42;
                                                                                                                                                                        }
                                                                                                                                                                        _if_40 = _if_41;
                                                                                                                                                                    }
                                                                                                                                                                    _if_39 = _if_40;
                                                                                                                                                                }
                                                                                                                                                                _if_38 = _if_39;
                                                                                                                                                            }
                                                                                                                                                            _if_37 = _if_38;
                                                                                                                                                        }
                                                                                                                                                        _if_36 = _if_37;
                                                                                                                                                    }
                                                                                                                                                    _if_35 = _if_36;
                                                                                                                                                }
                                                                                                                                                _if_34 = _if_35;
                                                                                                                                            }
                                                                                                                                            _if_33 = _if_34;
                                                                                                                                        }
                                                                                                                                        _if_32 = _if_33;
                                                                                                                                    }
                                                                                                                                    _if_31 = _if_32;
                                                                                                                                }
                                                                                                                                _if_30 = _if_31;
                                                                                                                            }
                                                                                                                            _if_29 = _if_30;
                                                                                                                        }
                                                                                                                        _if_28 = _if_29;
                                                                                                                    }
                                                                                                                    _if_27 = _if_28;
                                                                                                                }
                                                                                                                _if_26 = _if_27;
                                                                                                            }
                                                                                                            _if_25 = _if_26;
                                                                                                        }
                                                                                                        _if_24 = _if_25;
                                                                                                    }
                                                                                                    _if_23 = _if_24;
                                                                                                }
                                                                                                _if_22 = _if_23;
                                                                                            }
                                                                                            _if_21 = _if_22;
                                                                                        }
                                                                                        _if_20 = _if_21;
                                                                                    }
                                                                                    _if_19 = _if_20;
                                                                                }
                                                                                _if_18 = _if_19;
                                                                            }
                                                                            _if_17 = _if_18;
                                                                        }
                                                                        _if_16 = _if_17;
                                                                    }
                                                                    _if_15 = _if_16;
                                                                }
                                                                _if_14 = _if_15;
                                                            }
                                                            _if_13 = _if_14;
                                                        }
                                                        _if_12 = _if_13;
                                                    }
                                                    _if_11 = _if_12;
                                                }
                                                _if_10 = _if_11;
                                            }
                                            _if_9 = _if_10;
                                        }
                                        _if_8 = _if_9;
                                    }
                                    _if_7 = _if_8;
                                }
                                _if_6 = _if_7;
                            }
                            _if_5 = _if_6;
                        }
                        _if_4 = _if_5;
                    }
                    _if_3 = _if_4;
                }
                _if_2 = _if_3;
            }
            _if_1 = _if_2;
        }
        _if_0 = _if_1;
    }
    return _if_0;
}

int64_t pact_is_keyword(int64_t kind) {
    return ((kind >= pact_TokenKind_Fn) && (kind <= pact_TokenKind_Mod));
}

int64_t pact_keyword_lookup(const char* name) {
    int64_t _if_0;
    if (pact_str_eq(name, "fn")) {
        _if_0 = pact_TokenKind_Fn;
    } else {
        int64_t _if_1;
        if (pact_str_eq(name, "let")) {
            _if_1 = pact_TokenKind_Let;
        } else {
            int64_t _if_2;
            if (pact_str_eq(name, "mut")) {
                _if_2 = pact_TokenKind_Mut;
            } else {
                int64_t _if_3;
                if (pact_str_eq(name, "type")) {
                    _if_3 = pact_TokenKind_Type;
                } else {
                    int64_t _if_4;
                    if (pact_str_eq(name, "trait")) {
                        _if_4 = pact_TokenKind_Trait;
                    } else {
                        int64_t _if_5;
                        if (pact_str_eq(name, "impl")) {
                            _if_5 = pact_TokenKind_Impl;
                        } else {
                            int64_t _if_6;
                            if (pact_str_eq(name, "if")) {
                                _if_6 = pact_TokenKind_If;
                            } else {
                                int64_t _if_7;
                                if (pact_str_eq(name, "else")) {
                                    _if_7 = pact_TokenKind_Else;
                                } else {
                                    int64_t _if_8;
                                    if (pact_str_eq(name, "match")) {
                                        _if_8 = pact_TokenKind_Match;
                                    } else {
                                        int64_t _if_9;
                                        if (pact_str_eq(name, "for")) {
                                            _if_9 = pact_TokenKind_For;
                                        } else {
                                            int64_t _if_10;
                                            if (pact_str_eq(name, "in")) {
                                                _if_10 = pact_TokenKind_In;
                                            } else {
                                                int64_t _if_11;
                                                if (pact_str_eq(name, "while")) {
                                                    _if_11 = pact_TokenKind_While;
                                                } else {
                                                    int64_t _if_12;
                                                    if (pact_str_eq(name, "loop")) {
                                                        _if_12 = pact_TokenKind_Loop;
                                                    } else {
                                                        int64_t _if_13;
                                                        if (pact_str_eq(name, "break")) {
                                                            _if_13 = pact_TokenKind_Break;
                                                        } else {
                                                            int64_t _if_14;
                                                            if (pact_str_eq(name, "continue")) {
                                                                _if_14 = pact_TokenKind_Continue;
                                                            } else {
                                                                int64_t _if_15;
                                                                if (pact_str_eq(name, "return")) {
                                                                    _if_15 = pact_TokenKind_Return;
                                                                } else {
                                                                    int64_t _if_16;
                                                                    if (pact_str_eq(name, "pub")) {
                                                                        _if_16 = pact_TokenKind_Pub;
                                                                    } else {
                                                                        int64_t _if_17;
                                                                        if (pact_str_eq(name, "with")) {
                                                                            _if_17 = pact_TokenKind_With;
                                                                        } else {
                                                                            int64_t _if_18;
                                                                            if (pact_str_eq(name, "handler")) {
                                                                                _if_18 = pact_TokenKind_Handler;
                                                                            } else {
                                                                                int64_t _if_19;
                                                                                if (pact_str_eq(name, "self")) {
                                                                                    _if_19 = pact_TokenKind_Self;
                                                                                } else {
                                                                                    int64_t _if_20;
                                                                                    if (pact_str_eq(name, "test")) {
                                                                                        _if_20 = pact_TokenKind_Test;
                                                                                    } else {
                                                                                        int64_t _if_21;
                                                                                        if (pact_str_eq(name, "import")) {
                                                                                            _if_21 = pact_TokenKind_Import;
                                                                                        } else {
                                                                                            int64_t _if_22;
                                                                                            if (pact_str_eq(name, "as")) {
                                                                                                _if_22 = pact_TokenKind_As;
                                                                                            } else {
                                                                                                int64_t _if_23;
                                                                                                if (pact_str_eq(name, "mod")) {
                                                                                                    _if_23 = pact_TokenKind_Mod;
                                                                                                } else {
                                                                                                    int64_t _if_24;
                                                                                                    if (pact_str_eq(name, "assert")) {
                                                                                                        _if_24 = pact_TokenKind_Assert;
                                                                                                    } else {
                                                                                                        int64_t _if_25;
                                                                                                        if (pact_str_eq(name, "assert_eq")) {
                                                                                                            _if_25 = pact_TokenKind_AssertEq;
                                                                                                        } else {
                                                                                                            int64_t _if_26;
                                                                                                            if (pact_str_eq(name, "assert_ne")) {
                                                                                                                _if_26 = pact_TokenKind_AssertNe;
                                                                                                            } else {
                                                                                                                _if_26 = pact_TokenKind_Ident;
                                                                                                            }
                                                                                                            _if_25 = _if_26;
                                                                                                        }
                                                                                                        _if_24 = _if_25;
                                                                                                    }
                                                                                                    _if_23 = _if_24;
                                                                                                }
                                                                                                _if_22 = _if_23;
                                                                                            }
                                                                                            _if_21 = _if_22;
                                                                                        }
                                                                                        _if_20 = _if_21;
                                                                                    }
                                                                                    _if_19 = _if_20;
                                                                                }
                                                                                _if_18 = _if_19;
                                                                            }
                                                                            _if_17 = _if_18;
                                                                        }
                                                                        _if_16 = _if_17;
                                                                    }
                                                                    _if_15 = _if_16;
                                                                }
                                                                _if_14 = _if_15;
                                                            }
                                                            _if_13 = _if_14;
                                                        }
                                                        _if_12 = _if_13;
                                                    }
                                                    _if_11 = _if_12;
                                                }
                                                _if_10 = _if_11;
                                            }
                                            _if_9 = _if_10;
                                        }
                                        _if_8 = _if_9;
                                    }
                                    _if_7 = _if_8;
                                }
                                _if_6 = _if_7;
                            }
                            _if_5 = _if_6;
                        }
                        _if_4 = _if_5;
                    }
                    _if_3 = _if_4;
                }
                _if_2 = _if_3;
            }
            _if_1 = _if_2;
        }
        _if_0 = _if_1;
    }
    return _if_0;
}

const char* pact_node_kind_name(int64_t kind) {
    const char* _if_0;
    if ((kind == pact_NodeKind_IntLit)) {
        _if_0 = "IntLit";
    } else {
        const char* _if_1;
        if ((kind == pact_NodeKind_FloatLit)) {
            _if_1 = "FloatLit";
        } else {
            const char* _if_2;
            if ((kind == pact_NodeKind_Ident)) {
                _if_2 = "Ident";
            } else {
                const char* _if_3;
                if ((kind == pact_NodeKind_Call)) {
                    _if_3 = "Call";
                } else {
                    const char* _if_4;
                    if ((kind == pact_NodeKind_MethodCall)) {
                        _if_4 = "MethodCall";
                    } else {
                        const char* _if_5;
                        if ((kind == pact_NodeKind_BinOp)) {
                            _if_5 = "BinOp";
                        } else {
                            const char* _if_6;
                            if ((kind == pact_NodeKind_UnaryOp)) {
                                _if_6 = "UnaryOp";
                            } else {
                                const char* _if_7;
                                if ((kind == pact_NodeKind_InterpString)) {
                                    _if_7 = "InterpString";
                                } else {
                                    const char* _if_8;
                                    if ((kind == pact_NodeKind_BoolLit)) {
                                        _if_8 = "BoolLit";
                                    } else {
                                        const char* _if_9;
                                        if ((kind == pact_NodeKind_TupleLit)) {
                                            _if_9 = "TupleLit";
                                        } else {
                                            const char* _if_10;
                                            if ((kind == pact_NodeKind_ListLit)) {
                                                _if_10 = "ListLit";
                                            } else {
                                                const char* _if_11;
                                                if ((kind == pact_NodeKind_StructLit)) {
                                                    _if_11 = "StructLit";
                                                } else {
                                                    const char* _if_12;
                                                    if ((kind == pact_NodeKind_FieldAccess)) {
                                                        _if_12 = "FieldAccess";
                                                    } else {
                                                        const char* _if_13;
                                                        if ((kind == pact_NodeKind_IndexExpr)) {
                                                            _if_13 = "IndexExpr";
                                                        } else {
                                                            const char* _if_14;
                                                            if ((kind == pact_NodeKind_RangeLit)) {
                                                                _if_14 = "RangeLit";
                                                            } else {
                                                                const char* _if_15;
                                                                if ((kind == pact_NodeKind_IfExpr)) {
                                                                    _if_15 = "IfExpr";
                                                                } else {
                                                                    const char* _if_16;
                                                                    if ((kind == pact_NodeKind_MatchExpr)) {
                                                                        _if_16 = "MatchExpr";
                                                                    } else {
                                                                        const char* _if_17;
                                                                        if ((kind == pact_NodeKind_Closure)) {
                                                                            _if_17 = "Closure";
                                                                        } else {
                                                                            const char* _if_18;
                                                                            if ((kind == pact_NodeKind_LetBinding)) {
                                                                                _if_18 = "LetBinding";
                                                                            } else {
                                                                                const char* _if_19;
                                                                                if ((kind == pact_NodeKind_ExprStmt)) {
                                                                                    _if_19 = "ExprStmt";
                                                                                } else {
                                                                                    const char* _if_20;
                                                                                    if ((kind == pact_NodeKind_Assignment)) {
                                                                                        _if_20 = "Assignment";
                                                                                    } else {
                                                                                        const char* _if_21;
                                                                                        if ((kind == pact_NodeKind_CompoundAssign)) {
                                                                                            _if_21 = "CompoundAssign";
                                                                                        } else {
                                                                                            const char* _if_22;
                                                                                            if ((kind == pact_NodeKind_Return)) {
                                                                                                _if_22 = "Return";
                                                                                            } else {
                                                                                                const char* _if_23;
                                                                                                if ((kind == pact_NodeKind_ForIn)) {
                                                                                                    _if_23 = "ForIn";
                                                                                                } else {
                                                                                                    const char* _if_24;
                                                                                                    if ((kind == pact_NodeKind_WhileLoop)) {
                                                                                                        _if_24 = "WhileLoop";
                                                                                                    } else {
                                                                                                        const char* _if_25;
                                                                                                        if ((kind == pact_NodeKind_LoopExpr)) {
                                                                                                            _if_25 = "LoopExpr";
                                                                                                        } else {
                                                                                                            const char* _if_26;
                                                                                                            if ((kind == pact_NodeKind_Break)) {
                                                                                                                _if_26 = "Break";
                                                                                                            } else {
                                                                                                                const char* _if_27;
                                                                                                                if ((kind == pact_NodeKind_Continue)) {
                                                                                                                    _if_27 = "Continue";
                                                                                                                } else {
                                                                                                                    const char* _if_28;
                                                                                                                    if ((kind == pact_NodeKind_Block)) {
                                                                                                                        _if_28 = "Block";
                                                                                                                    } else {
                                                                                                                        const char* _if_29;
                                                                                                                        if ((kind == pact_NodeKind_FnDef)) {
                                                                                                                            _if_29 = "FnDef";
                                                                                                                        } else {
                                                                                                                            const char* _if_30;
                                                                                                                            if ((kind == pact_NodeKind_Param)) {
                                                                                                                                _if_30 = "Param";
                                                                                                                            } else {
                                                                                                                                const char* _if_31;
                                                                                                                                if ((kind == pact_NodeKind_Program)) {
                                                                                                                                    _if_31 = "Program";
                                                                                                                                } else {
                                                                                                                                    const char* _if_32;
                                                                                                                                    if ((kind == pact_NodeKind_TypeDef)) {
                                                                                                                                        _if_32 = "TypeDef";
                                                                                                                                    } else {
                                                                                                                                        const char* _if_33;
                                                                                                                                        if ((kind == pact_NodeKind_TypeField)) {
                                                                                                                                            _if_33 = "TypeField";
                                                                                                                                        } else {
                                                                                                                                            const char* _if_34;
                                                                                                                                            if ((kind == pact_NodeKind_TypeVariant)) {
                                                                                                                                                _if_34 = "TypeVariant";
                                                                                                                                            } else {
                                                                                                                                                const char* _if_35;
                                                                                                                                                if ((kind == pact_NodeKind_TraitDef)) {
                                                                                                                                                    _if_35 = "TraitDef";
                                                                                                                                                } else {
                                                                                                                                                    const char* _if_36;
                                                                                                                                                    if ((kind == pact_NodeKind_ImplBlock)) {
                                                                                                                                                        _if_36 = "ImplBlock";
                                                                                                                                                    } else {
                                                                                                                                                        const char* _if_37;
                                                                                                                                                        if ((kind == pact_NodeKind_TestBlock)) {
                                                                                                                                                            _if_37 = "TestBlock";
                                                                                                                                                        } else {
                                                                                                                                                            const char* _if_38;
                                                                                                                                                            if ((kind == pact_NodeKind_IntPattern)) {
                                                                                                                                                                _if_38 = "IntPattern";
                                                                                                                                                            } else {
                                                                                                                                                                const char* _if_39;
                                                                                                                                                                if ((kind == pact_NodeKind_WildcardPattern)) {
                                                                                                                                                                    _if_39 = "WildcardPattern";
                                                                                                                                                                } else {
                                                                                                                                                                    const char* _if_40;
                                                                                                                                                                    if ((kind == pact_NodeKind_IdentPattern)) {
                                                                                                                                                                        _if_40 = "IdentPattern";
                                                                                                                                                                    } else {
                                                                                                                                                                        const char* _if_41;
                                                                                                                                                                        if ((kind == pact_NodeKind_TuplePattern)) {
                                                                                                                                                                            _if_41 = "TuplePattern";
                                                                                                                                                                        } else {
                                                                                                                                                                            const char* _if_42;
                                                                                                                                                                            if ((kind == pact_NodeKind_StringPattern)) {
                                                                                                                                                                                _if_42 = "StringPattern";
                                                                                                                                                                            } else {
                                                                                                                                                                                const char* _if_43;
                                                                                                                                                                                if ((kind == pact_NodeKind_OrPattern)) {
                                                                                                                                                                                    _if_43 = "OrPattern";
                                                                                                                                                                                } else {
                                                                                                                                                                                    const char* _if_44;
                                                                                                                                                                                    if ((kind == pact_NodeKind_RangePattern)) {
                                                                                                                                                                                        _if_44 = "RangePattern";
                                                                                                                                                                                    } else {
                                                                                                                                                                                        const char* _if_45;
                                                                                                                                                                                        if ((kind == pact_NodeKind_StructPattern)) {
                                                                                                                                                                                            _if_45 = "StructPattern";
                                                                                                                                                                                        } else {
                                                                                                                                                                                            const char* _if_46;
                                                                                                                                                                                            if ((kind == pact_NodeKind_EnumPattern)) {
                                                                                                                                                                                                _if_46 = "EnumPattern";
                                                                                                                                                                                            } else {
                                                                                                                                                                                                const char* _if_47;
                                                                                                                                                                                                if ((kind == pact_NodeKind_AsPattern)) {
                                                                                                                                                                                                    _if_47 = "AsPattern";
                                                                                                                                                                                                } else {
                                                                                                                                                                                                    const char* _if_48;
                                                                                                                                                                                                    if ((kind == pact_NodeKind_MatchArm)) {
                                                                                                                                                                                                        _if_48 = "MatchArm";
                                                                                                                                                                                                    } else {
                                                                                                                                                                                                        const char* _if_49;
                                                                                                                                                                                                        if ((kind == pact_NodeKind_StructLitField)) {
                                                                                                                                                                                                            _if_49 = "StructLitField";
                                                                                                                                                                                                        } else {
                                                                                                                                                                                                            const char* _if_50;
                                                                                                                                                                                                            if ((kind == pact_NodeKind_WithBlock)) {
                                                                                                                                                                                                                _if_50 = "WithBlock";
                                                                                                                                                                                                            } else {
                                                                                                                                                                                                                const char* _if_51;
                                                                                                                                                                                                                if ((kind == pact_NodeKind_HandlerExpr)) {
                                                                                                                                                                                                                    _if_51 = "HandlerExpr";
                                                                                                                                                                                                                } else {
                                                                                                                                                                                                                    const char* _if_52;
                                                                                                                                                                                                                    if ((kind == pact_NodeKind_Annotation)) {
                                                                                                                                                                                                                        _if_52 = "Annotation";
                                                                                                                                                                                                                    } else {
                                                                                                                                                                                                                        const char* _if_53;
                                                                                                                                                                                                                        if ((kind == pact_NodeKind_ModBlock)) {
                                                                                                                                                                                                                            _if_53 = "ModBlock";
                                                                                                                                                                                                                        } else {
                                                                                                                                                                                                                            const char* _if_54;
                                                                                                                                                                                                                            if ((kind == pact_NodeKind_ImportStmt)) {
                                                                                                                                                                                                                                _if_54 = "ImportStmt";
                                                                                                                                                                                                                            } else {
                                                                                                                                                                                                                                const char* _if_55;
                                                                                                                                                                                                                                if ((kind == pact_NodeKind_TypeAnn)) {
                                                                                                                                                                                                                                    _if_55 = "TypeAnn";
                                                                                                                                                                                                                                } else {
                                                                                                                                                                                                                                    _if_55 = "Unknown";
                                                                                                                                                                                                                                }
                                                                                                                                                                                                                                _if_54 = _if_55;
                                                                                                                                                                                                                            }
                                                                                                                                                                                                                            _if_53 = _if_54;
                                                                                                                                                                                                                        }
                                                                                                                                                                                                                        _if_52 = _if_53;
                                                                                                                                                                                                                    }
                                                                                                                                                                                                                    _if_51 = _if_52;
                                                                                                                                                                                                                }
                                                                                                                                                                                                                _if_50 = _if_51;
                                                                                                                                                                                                            }
                                                                                                                                                                                                            _if_49 = _if_50;
                                                                                                                                                                                                        }
                                                                                                                                                                                                        _if_48 = _if_49;
                                                                                                                                                                                                    }
                                                                                                                                                                                                    _if_47 = _if_48;
                                                                                                                                                                                                }
                                                                                                                                                                                                _if_46 = _if_47;
                                                                                                                                                                                            }
                                                                                                                                                                                            _if_45 = _if_46;
                                                                                                                                                                                        }
                                                                                                                                                                                        _if_44 = _if_45;
                                                                                                                                                                                    }
                                                                                                                                                                                    _if_43 = _if_44;
                                                                                                                                                                                }
                                                                                                                                                                                _if_42 = _if_43;
                                                                                                                                                                            }
                                                                                                                                                                            _if_41 = _if_42;
                                                                                                                                                                        }
                                                                                                                                                                        _if_40 = _if_41;
                                                                                                                                                                    }
                                                                                                                                                                    _if_39 = _if_40;
                                                                                                                                                                }
                                                                                                                                                                _if_38 = _if_39;
                                                                                                                                                            }
                                                                                                                                                            _if_37 = _if_38;
                                                                                                                                                        }
                                                                                                                                                        _if_36 = _if_37;
                                                                                                                                                    }
                                                                                                                                                    _if_35 = _if_36;
                                                                                                                                                }
                                                                                                                                                _if_34 = _if_35;
                                                                                                                                            }
                                                                                                                                            _if_33 = _if_34;
                                                                                                                                        }
                                                                                                                                        _if_32 = _if_33;
                                                                                                                                    }
                                                                                                                                    _if_31 = _if_32;
                                                                                                                                }
                                                                                                                                _if_30 = _if_31;
                                                                                                                            }
                                                                                                                            _if_29 = _if_30;
                                                                                                                        }
                                                                                                                        _if_28 = _if_29;
                                                                                                                    }
                                                                                                                    _if_27 = _if_28;
                                                                                                                }
                                                                                                                _if_26 = _if_27;
                                                                                                            }
                                                                                                            _if_25 = _if_26;
                                                                                                        }
                                                                                                        _if_24 = _if_25;
                                                                                                    }
                                                                                                    _if_23 = _if_24;
                                                                                                }
                                                                                                _if_22 = _if_23;
                                                                                            }
                                                                                            _if_21 = _if_22;
                                                                                        }
                                                                                        _if_20 = _if_21;
                                                                                    }
                                                                                    _if_19 = _if_20;
                                                                                }
                                                                                _if_18 = _if_19;
                                                                            }
                                                                            _if_17 = _if_18;
                                                                        }
                                                                        _if_16 = _if_17;
                                                                    }
                                                                    _if_15 = _if_16;
                                                                }
                                                                _if_14 = _if_15;
                                                            }
                                                            _if_13 = _if_14;
                                                        }
                                                        _if_12 = _if_13;
                                                    }
                                                    _if_11 = _if_12;
                                                }
                                                _if_10 = _if_11;
                                            }
                                            _if_9 = _if_10;
                                        }
                                        _if_8 = _if_9;
                                    }
                                    _if_7 = _if_8;
                                }
                                _if_6 = _if_7;
                            }
                            _if_5 = _if_6;
                        }
                        _if_4 = _if_5;
                    }
                    _if_3 = _if_4;
                }
                _if_2 = _if_3;
            }
            _if_1 = _if_2;
        }
        _if_0 = _if_1;
    }
    return _if_0;
}

int64_t pact_is_alpha(int64_t c) {
    return ((((c >= CH_A) && (c <= CH_Z)) || ((c >= CH_a) && (c <= CH_Z_LOWER))) || (c == CH_UNDERSCORE));
}

int64_t pact_is_digit(int64_t c) {
    return ((c >= CH_0) && (c <= CH_9));
}

int64_t pact_is_alnum(int64_t c) {
    return (pact_is_alpha(c) || pact_is_digit(c));
}

int64_t pact_is_whitespace(int64_t c) {
    return ((c == CH_SPACE) || (c == CH_TAB));
}

int64_t pact_peek(const char* source, int64_t pos) {
    int64_t _if_0;
    if ((pos >= pact_str_len(source))) {
        _if_0 = 0;
    } else {
        _if_0 = pact_str_char_at(source, pos);
    }
    return _if_0;
}

int64_t pact_peek_at(const char* source, int64_t pos, int64_t offset) {
    return pact_peek(source, (pos + offset));
}

void pact_lex(const char* source) {
    pact_list* _l0 = pact_list_new();
    tok_kinds = _l0;
    pact_list* _l1 = pact_list_new();
    tok_values = _l1;
    pact_list* _l2 = pact_list_new();
    tok_lines = _l2;
    pact_list* _l3 = pact_list_new();
    tok_cols = _l3;
    int64_t pos = 0;
    int64_t line = 1;
    int64_t col = 1;
    pact_list* _l4 = pact_list_new();
    pact_list* mode_stack = _l4;
    pact_list* _l5 = pact_list_new();
    pact_list* brace_depth_stack = _l5;
    pact_list_push(mode_stack, (void*)(intptr_t)MODE_NORMAL);
    pact_list_push(brace_depth_stack, (void*)(intptr_t)0);
    const char* string_buf = "";
    int64_t last_kind = (-1);
    while ((pos < pact_str_len(source))) {
        const int64_t mode = (int64_t)(intptr_t)pact_list_get(mode_stack, (pact_list_len(mode_stack) - 1));
        if ((mode == MODE_NORMAL)) {
            const int64_t brace_depth = (int64_t)(intptr_t)pact_list_get(brace_depth_stack, (pact_list_len(brace_depth_stack) - 1));
            const int64_t ch = pact_peek(source, pos);
            if (pact_is_whitespace(ch)) {
                pos = (pos + 1);
                col = (col + 1);
                continue;
            }
            if (((ch == CH_SLASH) && (pact_peek_at(source, pos, 1) == CH_SLASH))) {
                pos = (pos + 2);
                col = (col + 2);
                while (((pos < pact_str_len(source)) && (pact_peek(source, pos) != CH_NEWLINE))) {
                    pos = (pos + 1);
                    col = (col + 1);
                }
                if (((pos < pact_str_len(source)) && (pact_peek(source, pos) == CH_NEWLINE))) {
                    pos = (pos + 1);
                    line = (line + 1);
                    col = 1;
                }
                continue;
            }
            if ((ch == CH_SLASH)) {
                const int64_t t_line = line;
                const int64_t t_col = col;
                pos = (pos + 1);
                col = (col + 1);
                if (((pos < pact_str_len(source)) && (pact_peek(source, pos) == CH_EQUALS))) {
                    pos = (pos + 1);
                    col = (col + 1);
                    pact_list_push(tok_kinds, (void*)(intptr_t)pact_TokenKind_SlashEq);
                    pact_list_push(tok_values, (void*)"/=");
                    pact_list_push(tok_lines, (void*)(intptr_t)t_line);
                    pact_list_push(tok_cols, (void*)(intptr_t)t_col);
                    last_kind = pact_TokenKind_SlashEq;
                } else {
                    pact_list_push(tok_kinds, (void*)(intptr_t)pact_TokenKind_Slash);
                    pact_list_push(tok_values, (void*)"/");
                    pact_list_push(tok_lines, (void*)(intptr_t)t_line);
                    pact_list_push(tok_cols, (void*)(intptr_t)t_col);
                    last_kind = pact_TokenKind_Slash;
                }
                continue;
            }
            if ((ch == CH_NEWLINE)) {
                const int64_t t_line = line;
                const int64_t t_col = col;
                pos = (pos + 1);
                line = (line + 1);
                col = 1;
                if ((last_kind != pact_TokenKind_Newline)) {
                    pact_list_push(tok_kinds, (void*)(intptr_t)pact_TokenKind_Newline);
                    pact_list_push(tok_values, (void*)"\\n");
                    pact_list_push(tok_lines, (void*)(intptr_t)t_line);
                    pact_list_push(tok_cols, (void*)(intptr_t)t_col);
                    last_kind = pact_TokenKind_Newline;
                }
                continue;
            }
            if ((ch == CH_DQUOTE)) {
                const int64_t t_line = line;
                const int64_t t_col = col;
                pos = (pos + 1);
                col = (col + 1);
                pact_list_push(tok_kinds, (void*)(intptr_t)pact_TokenKind_StringStart);
                pact_list_push(tok_values, (void*)"\"");
                pact_list_push(tok_lines, (void*)(intptr_t)t_line);
                pact_list_push(tok_cols, (void*)(intptr_t)t_col);
                last_kind = pact_TokenKind_StringStart;
                pact_list_push(mode_stack, (void*)(intptr_t)MODE_STRING);
                pact_list_push(brace_depth_stack, (void*)(intptr_t)0);
                string_buf = "";
                continue;
            }
            if ((ch == CH_LBRACE)) {
                const int64_t t_line = line;
                const int64_t t_col = col;
                pos = (pos + 1);
                col = (col + 1);
                if ((brace_depth > 0)) {
                    pact_list_push(brace_depth_stack, (void*)(intptr_t)(brace_depth + 1));
                    pact_list_push(mode_stack, (void*)(intptr_t)MODE_NORMAL);
                    const int64_t mlen = pact_list_len(mode_stack);
                    pact_list_pop(mode_stack);
                    pact_list_pop(brace_depth_stack);
                    pact_list_pop(brace_depth_stack);
                    pact_list_push(brace_depth_stack, (void*)(intptr_t)(brace_depth + 1));
                    pact_list_push(tok_kinds, (void*)(intptr_t)pact_TokenKind_LBrace);
                    pact_list_push(tok_values, (void*)"{");
                    pact_list_push(tok_lines, (void*)(intptr_t)t_line);
                    pact_list_push(tok_cols, (void*)(intptr_t)t_col);
                    last_kind = pact_TokenKind_LBrace;
                } else {
                    pact_list_push(tok_kinds, (void*)(intptr_t)pact_TokenKind_LBrace);
                    pact_list_push(tok_values, (void*)"{");
                    pact_list_push(tok_lines, (void*)(intptr_t)t_line);
                    pact_list_push(tok_cols, (void*)(intptr_t)t_col);
                    last_kind = pact_TokenKind_LBrace;
                }
                continue;
            }
            if ((ch == CH_RBRACE)) {
                const int64_t t_line = line;
                const int64_t t_col = col;
                pos = (pos + 1);
                col = (col + 1);
                if ((brace_depth > 1)) {
                    pact_list_pop(brace_depth_stack);
                    pact_list_push(brace_depth_stack, (void*)(intptr_t)(brace_depth - 1));
                    pact_list_push(tok_kinds, (void*)(intptr_t)pact_TokenKind_RBrace);
                    pact_list_push(tok_values, (void*)"\\");
                    pact_list_push(tok_lines, (void*)(intptr_t)t_line);
                    pact_list_push(tok_cols, (void*)(intptr_t)t_col);
                    last_kind = pact_TokenKind_RBrace;
                } else if ((brace_depth == 1)) {
                    pact_list_pop(mode_stack);
                    pact_list_pop(brace_depth_stack);
                    pact_list_push(tok_kinds, (void*)(intptr_t)pact_TokenKind_InterpEnd);
                    pact_list_push(tok_values, (void*)"\\");
                    pact_list_push(tok_lines, (void*)(intptr_t)t_line);
                    pact_list_push(tok_cols, (void*)(intptr_t)t_col);
                    last_kind = pact_TokenKind_InterpEnd;
                } else {
                    pact_list_push(tok_kinds, (void*)(intptr_t)pact_TokenKind_RBrace);
                    pact_list_push(tok_values, (void*)"\\");
                    pact_list_push(tok_lines, (void*)(intptr_t)t_line);
                    pact_list_push(tok_cols, (void*)(intptr_t)t_col);
                    last_kind = pact_TokenKind_RBrace;
                }
                continue;
            }
            if ((ch == CH_QUESTION)) {
                const int64_t t_line = line;
                const int64_t t_col = col;
                pos = (pos + 1);
                col = (col + 1);
                if (((pos < pact_str_len(source)) && (pact_peek(source, pos) == CH_QUESTION))) {
                    pos = (pos + 1);
                    col = (col + 1);
                    pact_list_push(tok_kinds, (void*)(intptr_t)pact_TokenKind_DoubleQuestion);
                    pact_list_push(tok_values, (void*)"??");
                    pact_list_push(tok_lines, (void*)(intptr_t)t_line);
                    pact_list_push(tok_cols, (void*)(intptr_t)t_col);
                    last_kind = pact_TokenKind_DoubleQuestion;
                } else {
                    pact_list_push(tok_kinds, (void*)(intptr_t)pact_TokenKind_Question);
                    pact_list_push(tok_values, (void*)"?");
                    pact_list_push(tok_lines, (void*)(intptr_t)t_line);
                    pact_list_push(tok_cols, (void*)(intptr_t)t_col);
                    last_kind = pact_TokenKind_Question;
                }
                continue;
            }
            if ((ch == CH_MINUS)) {
                const int64_t t_line = line;
                const int64_t t_col = col;
                if ((pact_peek_at(source, pos, 1) == CH_GREATER)) {
                    pos = (pos + 2);
                    col = (col + 2);
                    pact_list_push(tok_kinds, (void*)(intptr_t)pact_TokenKind_Arrow);
                    pact_list_push(tok_values, (void*)"->");
                    pact_list_push(tok_lines, (void*)(intptr_t)t_line);
                    pact_list_push(tok_cols, (void*)(intptr_t)t_col);
                    last_kind = pact_TokenKind_Arrow;
                } else if ((pact_peek_at(source, pos, 1) == CH_EQUALS)) {
                    pos = (pos + 2);
                    col = (col + 2);
                    pact_list_push(tok_kinds, (void*)(intptr_t)pact_TokenKind_MinusEq);
                    pact_list_push(tok_values, (void*)"-=");
                    pact_list_push(tok_lines, (void*)(intptr_t)t_line);
                    pact_list_push(tok_cols, (void*)(intptr_t)t_col);
                    last_kind = pact_TokenKind_MinusEq;
                } else {
                    pos = (pos + 1);
                    col = (col + 1);
                    pact_list_push(tok_kinds, (void*)(intptr_t)pact_TokenKind_Minus);
                    pact_list_push(tok_values, (void*)"-");
                    pact_list_push(tok_lines, (void*)(intptr_t)t_line);
                    pact_list_push(tok_cols, (void*)(intptr_t)t_col);
                    last_kind = pact_TokenKind_Minus;
                }
                continue;
            }
            if ((ch == CH_PLUS)) {
                const int64_t t_line = line;
                const int64_t t_col = col;
                pos = (pos + 1);
                col = (col + 1);
                if (((pos < pact_str_len(source)) && (pact_peek(source, pos) == CH_EQUALS))) {
                    pos = (pos + 1);
                    col = (col + 1);
                    pact_list_push(tok_kinds, (void*)(intptr_t)pact_TokenKind_PlusEq);
                    pact_list_push(tok_values, (void*)"+=");
                    pact_list_push(tok_lines, (void*)(intptr_t)t_line);
                    pact_list_push(tok_cols, (void*)(intptr_t)t_col);
                    last_kind = pact_TokenKind_PlusEq;
                } else {
                    pact_list_push(tok_kinds, (void*)(intptr_t)pact_TokenKind_Plus);
                    pact_list_push(tok_values, (void*)"+");
                    pact_list_push(tok_lines, (void*)(intptr_t)t_line);
                    pact_list_push(tok_cols, (void*)(intptr_t)t_col);
                    last_kind = pact_TokenKind_Plus;
                }
                continue;
            }
            if ((ch == CH_STAR)) {
                const int64_t t_line = line;
                const int64_t t_col = col;
                pos = (pos + 1);
                col = (col + 1);
                if (((pos < pact_str_len(source)) && (pact_peek(source, pos) == CH_EQUALS))) {
                    pos = (pos + 1);
                    col = (col + 1);
                    pact_list_push(tok_kinds, (void*)(intptr_t)pact_TokenKind_StarEq);
                    pact_list_push(tok_values, (void*)"*=");
                    pact_list_push(tok_lines, (void*)(intptr_t)t_line);
                    pact_list_push(tok_cols, (void*)(intptr_t)t_col);
                    last_kind = pact_TokenKind_StarEq;
                } else {
                    pact_list_push(tok_kinds, (void*)(intptr_t)pact_TokenKind_Star);
                    pact_list_push(tok_values, (void*)"*");
                    pact_list_push(tok_lines, (void*)(intptr_t)t_line);
                    pact_list_push(tok_cols, (void*)(intptr_t)t_col);
                    last_kind = pact_TokenKind_Star;
                }
                continue;
            }
            if ((ch == CH_EQUALS)) {
                const int64_t t_line = line;
                const int64_t t_col = col;
                pos = (pos + 1);
                col = (col + 1);
                if (((pos < pact_str_len(source)) && (pact_peek(source, pos) == CH_GREATER))) {
                    pos = (pos + 1);
                    col = (col + 1);
                    pact_list_push(tok_kinds, (void*)(intptr_t)pact_TokenKind_FatArrow);
                    pact_list_push(tok_values, (void*)"=>");
                    pact_list_push(tok_lines, (void*)(intptr_t)t_line);
                    pact_list_push(tok_cols, (void*)(intptr_t)t_col);
                    last_kind = pact_TokenKind_FatArrow;
                } else if (((pos < pact_str_len(source)) && (pact_peek(source, pos) == CH_EQUALS))) {
                    pos = (pos + 1);
                    col = (col + 1);
                    pact_list_push(tok_kinds, (void*)(intptr_t)pact_TokenKind_EqEq);
                    pact_list_push(tok_values, (void*)"==");
                    pact_list_push(tok_lines, (void*)(intptr_t)t_line);
                    pact_list_push(tok_cols, (void*)(intptr_t)t_col);
                    last_kind = pact_TokenKind_EqEq;
                } else {
                    pact_list_push(tok_kinds, (void*)(intptr_t)pact_TokenKind_Equals);
                    pact_list_push(tok_values, (void*)"=");
                    pact_list_push(tok_lines, (void*)(intptr_t)t_line);
                    pact_list_push(tok_cols, (void*)(intptr_t)t_col);
                    last_kind = pact_TokenKind_Equals;
                }
                continue;
            }
            if (((ch == CH_DOT) && (pact_peek_at(source, pos, 1) == CH_DOT))) {
                const int64_t t_line = line;
                const int64_t t_col = col;
                pos = (pos + 2);
                col = (col + 2);
                if (((pos < pact_str_len(source)) && (pact_peek(source, pos) == CH_EQUALS))) {
                    pos = (pos + 1);
                    col = (col + 1);
                    pact_list_push(tok_kinds, (void*)(intptr_t)pact_TokenKind_DotDoteq);
                    pact_list_push(tok_values, (void*)"..=");
                    pact_list_push(tok_lines, (void*)(intptr_t)t_line);
                    pact_list_push(tok_cols, (void*)(intptr_t)t_col);
                    last_kind = pact_TokenKind_DotDoteq;
                } else {
                    pact_list_push(tok_kinds, (void*)(intptr_t)pact_TokenKind_DotDot);
                    pact_list_push(tok_values, (void*)"..");
                    pact_list_push(tok_lines, (void*)(intptr_t)t_line);
                    pact_list_push(tok_cols, (void*)(intptr_t)t_col);
                    last_kind = pact_TokenKind_DotDot;
                }
                continue;
            }
            if ((ch == CH_DOT)) {
                const int64_t t_line = line;
                const int64_t t_col = col;
                pos = (pos + 1);
                col = (col + 1);
                pact_list_push(tok_kinds, (void*)(intptr_t)pact_TokenKind_Dot);
                pact_list_push(tok_values, (void*)".");
                pact_list_push(tok_lines, (void*)(intptr_t)t_line);
                pact_list_push(tok_cols, (void*)(intptr_t)t_col);
                last_kind = pact_TokenKind_Dot;
                continue;
            }
            if ((ch == CH_BANG)) {
                const int64_t t_line = line;
                const int64_t t_col = col;
                pos = (pos + 1);
                col = (col + 1);
                if (((pos < pact_str_len(source)) && (pact_peek(source, pos) == CH_EQUALS))) {
                    pos = (pos + 1);
                    col = (col + 1);
                    pact_list_push(tok_kinds, (void*)(intptr_t)pact_TokenKind_NotEq);
                    pact_list_push(tok_values, (void*)"!=");
                    pact_list_push(tok_lines, (void*)(intptr_t)t_line);
                    pact_list_push(tok_cols, (void*)(intptr_t)t_col);
                    last_kind = pact_TokenKind_NotEq;
                } else {
                    pact_list_push(tok_kinds, (void*)(intptr_t)pact_TokenKind_Bang);
                    pact_list_push(tok_values, (void*)"!");
                    pact_list_push(tok_lines, (void*)(intptr_t)t_line);
                    pact_list_push(tok_cols, (void*)(intptr_t)t_col);
                    last_kind = pact_TokenKind_Bang;
                }
                continue;
            }
            if ((ch == CH_LESS)) {
                const int64_t t_line = line;
                const int64_t t_col = col;
                pos = (pos + 1);
                col = (col + 1);
                if (((pos < pact_str_len(source)) && (pact_peek(source, pos) == CH_EQUALS))) {
                    pos = (pos + 1);
                    col = (col + 1);
                    pact_list_push(tok_kinds, (void*)(intptr_t)pact_TokenKind_LessEq);
                    pact_list_push(tok_values, (void*)"<=");
                    pact_list_push(tok_lines, (void*)(intptr_t)t_line);
                    pact_list_push(tok_cols, (void*)(intptr_t)t_col);
                    last_kind = pact_TokenKind_LessEq;
                } else {
                    pact_list_push(tok_kinds, (void*)(intptr_t)pact_TokenKind_Less);
                    pact_list_push(tok_values, (void*)"<");
                    pact_list_push(tok_lines, (void*)(intptr_t)t_line);
                    pact_list_push(tok_cols, (void*)(intptr_t)t_col);
                    last_kind = pact_TokenKind_Less;
                }
                continue;
            }
            if ((ch == CH_GREATER)) {
                const int64_t t_line = line;
                const int64_t t_col = col;
                pos = (pos + 1);
                col = (col + 1);
                if (((pos < pact_str_len(source)) && (pact_peek(source, pos) == CH_EQUALS))) {
                    pos = (pos + 1);
                    col = (col + 1);
                    pact_list_push(tok_kinds, (void*)(intptr_t)pact_TokenKind_GreaterEq);
                    pact_list_push(tok_values, (void*)">=");
                    pact_list_push(tok_lines, (void*)(intptr_t)t_line);
                    pact_list_push(tok_cols, (void*)(intptr_t)t_col);
                    last_kind = pact_TokenKind_GreaterEq;
                } else {
                    pact_list_push(tok_kinds, (void*)(intptr_t)pact_TokenKind_Greater);
                    pact_list_push(tok_values, (void*)">");
                    pact_list_push(tok_lines, (void*)(intptr_t)t_line);
                    pact_list_push(tok_cols, (void*)(intptr_t)t_col);
                    last_kind = pact_TokenKind_Greater;
                }
                continue;
            }
            if (((ch == CH_AMP) && (pact_peek_at(source, pos, 1) == CH_AMP))) {
                const int64_t t_line = line;
                const int64_t t_col = col;
                pos = (pos + 2);
                col = (col + 2);
                pact_list_push(tok_kinds, (void*)(intptr_t)pact_TokenKind_And);
                pact_list_push(tok_values, (void*)"&&");
                pact_list_push(tok_lines, (void*)(intptr_t)t_line);
                pact_list_push(tok_cols, (void*)(intptr_t)t_col);
                last_kind = pact_TokenKind_And;
                continue;
            }
            if ((ch == CH_PIPE)) {
                const int64_t t_line = line;
                const int64_t t_col = col;
                pos = (pos + 1);
                col = (col + 1);
                if (((pos < pact_str_len(source)) && (pact_peek(source, pos) == CH_PIPE))) {
                    pos = (pos + 1);
                    col = (col + 1);
                    pact_list_push(tok_kinds, (void*)(intptr_t)pact_TokenKind_Or);
                    pact_list_push(tok_values, (void*)"||");
                    pact_list_push(tok_lines, (void*)(intptr_t)t_line);
                    pact_list_push(tok_cols, (void*)(intptr_t)t_col);
                    last_kind = pact_TokenKind_Or;
                } else if (((pos < pact_str_len(source)) && (pact_peek(source, pos) == CH_GREATER))) {
                    pos = (pos + 1);
                    col = (col + 1);
                    pact_list_push(tok_kinds, (void*)(intptr_t)pact_TokenKind_PipeArrow);
                    pact_list_push(tok_values, (void*)"|>");
                    pact_list_push(tok_lines, (void*)(intptr_t)t_line);
                    pact_list_push(tok_cols, (void*)(intptr_t)t_col);
                    last_kind = pact_TokenKind_PipeArrow;
                } else {
                    pact_list_push(tok_kinds, (void*)(intptr_t)pact_TokenKind_Pipe);
                    pact_list_push(tok_values, (void*)"|");
                    pact_list_push(tok_lines, (void*)(intptr_t)t_line);
                    pact_list_push(tok_cols, (void*)(intptr_t)t_col);
                    last_kind = pact_TokenKind_Pipe;
                }
                continue;
            }
            if ((ch == CH_LPAREN)) {
                const int64_t t_line = line;
                const int64_t t_col = col;
                pos = (pos + 1);
                col = (col + 1);
                pact_list_push(tok_kinds, (void*)(intptr_t)pact_TokenKind_LParen);
                pact_list_push(tok_values, (void*)"(");
                pact_list_push(tok_lines, (void*)(intptr_t)t_line);
                pact_list_push(tok_cols, (void*)(intptr_t)t_col);
                last_kind = pact_TokenKind_LParen;
                continue;
            }
            if ((ch == CH_RPAREN)) {
                const int64_t t_line = line;
                const int64_t t_col = col;
                pos = (pos + 1);
                col = (col + 1);
                pact_list_push(tok_kinds, (void*)(intptr_t)pact_TokenKind_RParen);
                pact_list_push(tok_values, (void*)")");
                pact_list_push(tok_lines, (void*)(intptr_t)t_line);
                pact_list_push(tok_cols, (void*)(intptr_t)t_col);
                last_kind = pact_TokenKind_RParen;
                continue;
            }
            if ((ch == CH_COLON)) {
                const int64_t t_line = line;
                const int64_t t_col = col;
                pos = (pos + 1);
                col = (col + 1);
                pact_list_push(tok_kinds, (void*)(intptr_t)pact_TokenKind_Colon);
                pact_list_push(tok_values, (void*)":");
                pact_list_push(tok_lines, (void*)(intptr_t)t_line);
                pact_list_push(tok_cols, (void*)(intptr_t)t_col);
                last_kind = pact_TokenKind_Colon;
                continue;
            }
            if ((ch == CH_COMMA)) {
                const int64_t t_line = line;
                const int64_t t_col = col;
                pos = (pos + 1);
                col = (col + 1);
                pact_list_push(tok_kinds, (void*)(intptr_t)pact_TokenKind_Comma);
                pact_list_push(tok_values, (void*)",");
                pact_list_push(tok_lines, (void*)(intptr_t)t_line);
                pact_list_push(tok_cols, (void*)(intptr_t)t_col);
                last_kind = pact_TokenKind_Comma;
                continue;
            }
            if ((ch == CH_PERCENT)) {
                const int64_t t_line = line;
                const int64_t t_col = col;
                pos = (pos + 1);
                col = (col + 1);
                pact_list_push(tok_kinds, (void*)(intptr_t)pact_TokenKind_Percent);
                pact_list_push(tok_values, (void*)"%");
                pact_list_push(tok_lines, (void*)(intptr_t)t_line);
                pact_list_push(tok_cols, (void*)(intptr_t)t_col);
                last_kind = pact_TokenKind_Percent;
                continue;
            }
            if ((ch == CH_LBRACKET)) {
                const int64_t t_line = line;
                const int64_t t_col = col;
                pos = (pos + 1);
                col = (col + 1);
                pact_list_push(tok_kinds, (void*)(intptr_t)pact_TokenKind_LBracket);
                pact_list_push(tok_values, (void*)"[");
                pact_list_push(tok_lines, (void*)(intptr_t)t_line);
                pact_list_push(tok_cols, (void*)(intptr_t)t_col);
                last_kind = pact_TokenKind_LBracket;
                continue;
            }
            if ((ch == CH_RBRACKET)) {
                const int64_t t_line = line;
                const int64_t t_col = col;
                pos = (pos + 1);
                col = (col + 1);
                pact_list_push(tok_kinds, (void*)(intptr_t)pact_TokenKind_RBracket);
                pact_list_push(tok_values, (void*)"]");
                pact_list_push(tok_lines, (void*)(intptr_t)t_line);
                pact_list_push(tok_cols, (void*)(intptr_t)t_col);
                last_kind = pact_TokenKind_RBracket;
                continue;
            }
            if ((ch == CH_AT)) {
                const int64_t t_line = line;
                const int64_t t_col = col;
                pos = (pos + 1);
                col = (col + 1);
                pact_list_push(tok_kinds, (void*)(intptr_t)pact_TokenKind_At);
                pact_list_push(tok_values, (void*)"@");
                pact_list_push(tok_lines, (void*)(intptr_t)t_line);
                pact_list_push(tok_cols, (void*)(intptr_t)t_col);
                last_kind = pact_TokenKind_At;
                continue;
            }
            if (pact_is_alpha(ch)) {
                const int64_t t_line = line;
                const int64_t t_col = col;
                const int64_t start = pos;
                while (((pos < pact_str_len(source)) && pact_is_alnum(pact_peek(source, pos)))) {
                    pos = (pos + 1);
                    col = (col + 1);
                }
                const char* word = pact_str_substr(source, start, (pos - start));
                const int64_t kind = pact_keyword_lookup(word);
                pact_list_push(tok_kinds, (void*)(intptr_t)kind);
                pact_list_push(tok_values, (void*)word);
                pact_list_push(tok_lines, (void*)(intptr_t)t_line);
                pact_list_push(tok_cols, (void*)(intptr_t)t_col);
                last_kind = kind;
                continue;
            }
            if (pact_is_digit(ch)) {
                const int64_t t_line = line;
                const int64_t t_col = col;
                const int64_t start = pos;
                while (((pos < pact_str_len(source)) && pact_is_digit(pact_peek(source, pos)))) {
                    pos = (pos + 1);
                    col = (col + 1);
                }
                if ((((pos < pact_str_len(source)) && (pact_peek(source, pos) == CH_DOT)) && pact_is_digit(pact_peek_at(source, pos, 1)))) {
                    pos = (pos + 1);
                    col = (col + 1);
                    while (((pos < pact_str_len(source)) && pact_is_digit(pact_peek(source, pos)))) {
                        pos = (pos + 1);
                        col = (col + 1);
                    }
                    pact_list_push(tok_kinds, (void*)(intptr_t)pact_TokenKind_Float);
                    pact_list_push(tok_values, (void*)pact_str_substr(source, start, (pos - start)));
                    pact_list_push(tok_lines, (void*)(intptr_t)t_line);
                    pact_list_push(tok_cols, (void*)(intptr_t)t_col);
                    last_kind = pact_TokenKind_Float;
                } else {
                    pact_list_push(tok_kinds, (void*)(intptr_t)pact_TokenKind_Int);
                    pact_list_push(tok_values, (void*)pact_str_substr(source, start, (pos - start)));
                    pact_list_push(tok_lines, (void*)(intptr_t)t_line);
                    pact_list_push(tok_cols, (void*)(intptr_t)t_col);
                    last_kind = pact_TokenKind_Int;
                }
                continue;
            }
            char _si_6[4096];
            snprintf(_si_6, 4096, "lexer error: unexpected character at line %lld col %lld", (long long)line, (long long)col);
            printf("%s\n", strdup(_si_6));
            pos = (pos + 1);
            col = (col + 1);
        } else {
            const int64_t ch = pact_peek(source, pos);
            if ((ch == CH_LBRACE)) {
                const int64_t t_line = line;
                const int64_t t_col = col;
                pos = (pos + 1);
                col = (col + 1);
                pact_list_push(tok_kinds, (void*)(intptr_t)pact_TokenKind_StringPart);
                pact_list_push(tok_values, (void*)string_buf);
                pact_list_push(tok_lines, (void*)(intptr_t)t_line);
                pact_list_push(tok_cols, (void*)(intptr_t)t_col);
                last_kind = pact_TokenKind_StringPart;
                string_buf = "";
                pact_list_push(tok_kinds, (void*)(intptr_t)pact_TokenKind_InterpStart);
                pact_list_push(tok_values, (void*)"{");
                pact_list_push(tok_lines, (void*)(intptr_t)t_line);
                pact_list_push(tok_cols, (void*)(intptr_t)t_col);
                last_kind = pact_TokenKind_InterpStart;
                pact_list_push(mode_stack, (void*)(intptr_t)MODE_NORMAL);
                pact_list_push(brace_depth_stack, (void*)(intptr_t)1);
                continue;
            }
            if ((ch == CH_DQUOTE)) {
                const int64_t t_line = line;
                const int64_t t_col = col;
                pos = (pos + 1);
                col = (col + 1);
                pact_list_push(tok_kinds, (void*)(intptr_t)pact_TokenKind_StringPart);
                pact_list_push(tok_values, (void*)string_buf);
                pact_list_push(tok_lines, (void*)(intptr_t)t_line);
                pact_list_push(tok_cols, (void*)(intptr_t)t_col);
                last_kind = pact_TokenKind_StringPart;
                string_buf = "";
                pact_list_push(tok_kinds, (void*)(intptr_t)pact_TokenKind_StringEnd);
                pact_list_push(tok_values, (void*)"\"");
                pact_list_push(tok_lines, (void*)(intptr_t)t_line);
                pact_list_push(tok_cols, (void*)(intptr_t)t_col);
                last_kind = pact_TokenKind_StringEnd;
                pact_list_pop(mode_stack);
                pact_list_pop(brace_depth_stack);
                continue;
            }
            if ((ch == CH_BACKSLASH)) {
                pos = (pos + 1);
                col = (col + 1);
                if ((pos >= pact_str_len(source))) {
                    printf("%s\n", "lexer error: unexpected end of string after backslash");
                    continue;
                }
                const int64_t esc = pact_peek(source, pos);
                pos = (pos + 1);
                col = (col + 1);
                if ((esc == CH_n)) {
                    string_buf = pact_str_concat(string_buf, "\n");
                } else if ((esc == CH_t)) {
                    string_buf = pact_str_concat(string_buf, "\t");
                } else {
                    if ((esc == CH_BACKSLASH)) {
                        string_buf = pact_str_concat(string_buf, "\\");
                    } else if ((esc == CH_DQUOTE)) {
                        string_buf = pact_str_concat(string_buf, "\"");
                    } else {
                        if ((esc == CH_LBRACE)) {
                            string_buf = pact_str_concat(string_buf, "{");
                        } else {
                            string_buf = pact_str_concat(string_buf, "\\");
                        }
                    }
                }
                continue;
            }
            string_buf = pact_str_concat(string_buf, pact_str_substr(source, pos, 1));
            pos = (pos + 1);
            if ((ch == CH_NEWLINE)) {
                line = (line + 1);
                col = 1;
            } else {
                col = (col + 1);
            }
        }
    }
    pact_list_push(tok_kinds, (void*)(intptr_t)pact_TokenKind_EOF);
    pact_list_push(tok_values, (void*)"");
    pact_list_push(tok_lines, (void*)(intptr_t)line);
    pact_list_push(tok_cols, (void*)(intptr_t)col);
}

int64_t pact_new_node(int64_t kind) {
    const int64_t id = pact_list_len(np_kind);
    pact_list_push(np_kind, (void*)(intptr_t)kind);
    pact_list_push(np_int_val, (void*)(intptr_t)0);
    pact_list_push(np_str_val, (void*)"");
    pact_list_push(np_name, (void*)"");
    pact_list_push(np_op, (void*)"");
    pact_list_push(np_left, (void*)(intptr_t)(-1));
    pact_list_push(np_right, (void*)(intptr_t)(-1));
    pact_list_push(np_body, (void*)(intptr_t)(-1));
    pact_list_push(np_condition, (void*)(intptr_t)(-1));
    pact_list_push(np_then_body, (void*)(intptr_t)(-1));
    pact_list_push(np_else_body, (void*)(intptr_t)(-1));
    pact_list_push(np_scrutinee, (void*)(intptr_t)(-1));
    pact_list_push(np_pattern, (void*)(intptr_t)(-1));
    pact_list_push(np_guard, (void*)(intptr_t)(-1));
    pact_list_push(np_value, (void*)(intptr_t)(-1));
    pact_list_push(np_target, (void*)(intptr_t)(-1));
    pact_list_push(np_iterable, (void*)(intptr_t)(-1));
    pact_list_push(np_var_name, (void*)"");
    pact_list_push(np_is_mut, (void*)(intptr_t)0);
    pact_list_push(np_is_pub, (void*)(intptr_t)0);
    pact_list_push(np_inclusive, (void*)(intptr_t)0);
    pact_list_push(np_start, (void*)(intptr_t)(-1));
    pact_list_push(np_end, (void*)(intptr_t)(-1));
    pact_list_push(np_obj, (void*)(intptr_t)(-1));
    pact_list_push(np_method, (void*)"");
    pact_list_push(np_index, (void*)(intptr_t)(-1));
    pact_list_push(np_return_type, (void*)"");
    pact_list_push(np_type_name, (void*)"");
    pact_list_push(np_trait_name, (void*)"");
    pact_list_push(np_params, (void*)(intptr_t)(-1));
    pact_list_push(np_args, (void*)(intptr_t)(-1));
    pact_list_push(np_stmts, (void*)(intptr_t)(-1));
    pact_list_push(np_arms, (void*)(intptr_t)(-1));
    pact_list_push(np_fields, (void*)(intptr_t)(-1));
    pact_list_push(np_elements, (void*)(intptr_t)(-1));
    pact_list_push(np_methods, (void*)(intptr_t)(-1));
    return id;
}

int64_t pact_new_sublist(void) {
    const int64_t id = pact_list_len(sl_start);
    pact_list_push(sl_start, (void*)(intptr_t)pact_list_len(sl_items));
    pact_list_push(sl_len, (void*)(intptr_t)0);
    return id;
}

void pact_sublist_push(int64_t sl, int64_t node_id) {
    pact_list_push(sl_items, (void*)(intptr_t)node_id);
}

void pact_finalize_sublist(int64_t sl) {
    const int64_t start = (int64_t)(intptr_t)pact_list_get(sl_start, sl);
    const int64_t length = (pact_list_len(sl_items) - start);
    pact_list_set(sl_len, sl, (void*)(intptr_t)length);
}

int64_t pact_sublist_get(int64_t sl, int64_t idx) {
    return (int64_t)(intptr_t)pact_list_get(sl_items, ((int64_t)(intptr_t)pact_list_get(sl_start, sl) + idx));
}

int64_t pact_sublist_length(int64_t sl) {
    return (int64_t)(intptr_t)pact_list_get(sl_len, sl);
}

int64_t pact_peek_kind(void) {
    return (int64_t)(intptr_t)pact_list_get(tok_kinds, pos);
}

const char* pact_peek_value(void) {
    return (const char*)pact_list_get(tok_values, pos);
}

int64_t pact_peek_line(void) {
    return (int64_t)(intptr_t)pact_list_get(tok_lines, pos);
}

int64_t pact_peek_col(void) {
    return (int64_t)(intptr_t)pact_list_get(tok_cols, pos);
}

int64_t pact_at(int64_t kind) {
    return (pact_peek_kind() == kind);
}

int64_t pact_advance(void) {
    const int64_t old = pos;
    pos = (pos + 1);
    return old;
}

const char* pact_advance_value(void) {
    const char* v = (const char*)pact_list_get(tok_values, pos);
    pos = (pos + 1);
    return v;
}

int64_t pact_expect(int64_t kind) {
    if ((pact_peek_kind() != kind)) {
        char _si_0[4096];
        snprintf(_si_0, 4096, "parse error at line %lld:%lld: expected token kind %lld, got %lld", (long long)pact_peek_line(), (long long)pact_peek_col(), (long long)kind, (long long)pact_peek_kind());
        printf("%s\n", strdup(_si_0));
    }
    return pact_advance();
}

const char* pact_expect_value(int64_t kind) {
    if ((pact_peek_kind() != kind)) {
        char _si_0[4096];
        snprintf(_si_0, 4096, "parse error at line %lld:%lld: expected token kind %lld, got %lld", (long long)pact_peek_line(), (long long)pact_peek_col(), (long long)kind, (long long)pact_peek_kind());
        printf("%s\n", strdup(_si_0));
    }
    return pact_advance_value();
}

void pact_skip_newlines(void) {
    while (pact_at(pact_TokenKind_Newline)) {
        pact_advance();
    }
}

void pact_maybe_newline(void) {
    if (pact_at(pact_TokenKind_Newline)) {
        pact_advance();
    }
}

int64_t pact_parse_program(void) {
    pact_list* _l0 = pact_list_new();
    pact_list* fn_nodes = _l0;
    pact_list* _l1 = pact_list_new();
    pact_list* type_nodes = _l1;
    pact_list* _l2 = pact_list_new();
    pact_list* let_nodes = _l2;
    pact_list* _l3 = pact_list_new();
    pact_list* trait_nodes = _l3;
    pact_list* _l4 = pact_list_new();
    pact_list* impl_nodes = _l4;
    pact_list* _l5 = pact_list_new();
    pact_list* fn_pub = _l5;
    pact_skip_newlines();
    while ((!pact_at(pact_TokenKind_EOF))) {
        pact_skip_newlines();
        if (pact_at(pact_TokenKind_EOF)) {
            break;
        }
        if (pact_at(pact_TokenKind_Type)) {
            const int64_t td = pact_parse_type_def();
            pact_list_push(type_nodes, (void*)(intptr_t)td);
        } else if (pact_at(pact_TokenKind_Trait)) {
            const int64_t tr = pact_parse_trait_def();
            pact_list_push(trait_nodes, (void*)(intptr_t)tr);
        } else {
            if (pact_at(pact_TokenKind_Impl)) {
                const int64_t im = pact_parse_impl_block();
                pact_list_push(impl_nodes, (void*)(intptr_t)im);
            } else if (pact_at(pact_TokenKind_Let)) {
                const int64_t lb = pact_parse_let_binding();
                pact_list_push(let_nodes, (void*)(intptr_t)lb);
            } else {
                if (pact_at(pact_TokenKind_Pub)) {
                    pact_advance();
                    pact_skip_newlines();
                    const int64_t f = pact_parse_fn_def();
                    pact_list_set(np_is_pub, f, (void*)(intptr_t)1);
                    pact_list_push(fn_nodes, (void*)(intptr_t)f);
                } else if (pact_at(pact_TokenKind_Fn)) {
                    const int64_t f = pact_parse_fn_def();
                    pact_list_push(fn_nodes, (void*)(intptr_t)f);
                } else {
                    char _si_6[4096];
                    snprintf(_si_6, 4096, "parse error: unexpected token at top level: %lld", (long long)pact_peek_kind());
                    printf("%s\n", strdup(_si_6));
                    pact_advance();
                }
            }
        }
        pact_skip_newlines();
    }
    const int64_t fns = pact_new_sublist();
    int64_t i = 0;
    while ((i < pact_list_len(fn_nodes))) {
        pact_sublist_push(fns, (int64_t)(intptr_t)pact_list_get(fn_nodes, i));
        i = (i + 1);
    }
    pact_finalize_sublist(fns);
    const int64_t types = pact_new_sublist();
    i = 0;
    while ((i < pact_list_len(type_nodes))) {
        pact_sublist_push(types, (int64_t)(intptr_t)pact_list_get(type_nodes, i));
        i = (i + 1);
    }
    pact_finalize_sublist(types);
    const int64_t lets = pact_new_sublist();
    i = 0;
    while ((i < pact_list_len(let_nodes))) {
        pact_sublist_push(lets, (int64_t)(intptr_t)pact_list_get(let_nodes, i));
        i = (i + 1);
    }
    pact_finalize_sublist(lets);
    const int64_t traits = pact_new_sublist();
    i = 0;
    while ((i < pact_list_len(trait_nodes))) {
        pact_sublist_push(traits, (int64_t)(intptr_t)pact_list_get(trait_nodes, i));
        i = (i + 1);
    }
    pact_finalize_sublist(traits);
    const int64_t impls = pact_new_sublist();
    i = 0;
    while ((i < pact_list_len(impl_nodes))) {
        pact_sublist_push(impls, (int64_t)(intptr_t)pact_list_get(impl_nodes, i));
        i = (i + 1);
    }
    pact_finalize_sublist(impls);
    const int64_t prog = pact_new_node(pact_NodeKind_Program);
    pact_list_pop(np_params);
    pact_list_push(np_params, (void*)(intptr_t)fns);
    pact_list_pop(np_fields);
    pact_list_push(np_fields, (void*)(intptr_t)types);
    pact_list_pop(np_stmts);
    pact_list_push(np_stmts, (void*)(intptr_t)lets);
    pact_list_pop(np_arms);
    pact_list_push(np_arms, (void*)(intptr_t)traits);
    pact_list_pop(np_methods);
    pact_list_push(np_methods, (void*)(intptr_t)impls);
    return prog;
}

int64_t pact_parse_type_def(void) {
    pact_expect(pact_TokenKind_Type);
    const char* name = pact_expect_value(pact_TokenKind_Ident);
    if (pact_at(pact_TokenKind_LBracket)) {
        pact_advance();
        while ((!pact_at(pact_TokenKind_RBracket))) {
            pact_advance();
        }
        pact_expect(pact_TokenKind_RBracket);
    }
    pact_skip_newlines();
    int64_t flds = (-1);
    if (pact_at(pact_TokenKind_LBrace)) {
        pact_expect(pact_TokenKind_LBrace);
        pact_skip_newlines();
        pact_list* _l0 = pact_list_new();
        pact_list* field_nodes = _l0;
        while ((!pact_at(pact_TokenKind_RBrace))) {
            const char* fname = pact_expect_value(pact_TokenKind_Ident);
            if (pact_at(pact_TokenKind_Colon)) {
                pact_advance();
                const int64_t type_ann = pact_parse_type_annotation();
                const int64_t tf = pact_new_node(pact_NodeKind_TypeField);
                pact_list_pop(np_name);
                pact_list_push(np_name, (void*)fname);
                pact_list_pop(np_value);
                pact_list_push(np_value, (void*)(intptr_t)type_ann);
                pact_list_push(field_nodes, (void*)(intptr_t)tf);
            } else {
                const int64_t tv = pact_new_node(pact_NodeKind_TypeVariant);
                pact_list_pop(np_name);
                pact_list_push(np_name, (void*)fname);
                pact_list_push(field_nodes, (void*)(intptr_t)tv);
            }
            if (pact_at(pact_TokenKind_Comma)) {
                pact_advance();
            }
            pact_skip_newlines();
        }
        pact_expect(pact_TokenKind_RBrace);
        flds = pact_new_sublist();
        int64_t i = 0;
        while ((i < pact_list_len(field_nodes))) {
            pact_sublist_push(flds, (int64_t)(intptr_t)pact_list_get(field_nodes, i));
            i = (i + 1);
        }
        pact_finalize_sublist(flds);
    }
    const int64_t td = pact_new_node(pact_NodeKind_TypeDef);
    pact_list_pop(np_name);
    pact_list_push(np_name, (void*)name);
    pact_list_pop(np_fields);
    pact_list_push(np_fields, (void*)(intptr_t)flds);
    return td;
}

int64_t pact_parse_type_annotation(void) {
    const char* name = pact_expect_value(pact_TokenKind_Ident);
    int64_t elems = (-1);
    if (pact_at(pact_TokenKind_LBracket)) {
        pact_advance();
        pact_list* _l0 = pact_list_new();
        pact_list* type_nodes = _l0;
        pact_list_push(type_nodes, (void*)(intptr_t)pact_parse_type_annotation());
        while (pact_at(pact_TokenKind_Comma)) {
            pact_advance();
            pact_skip_newlines();
            pact_list_push(type_nodes, (void*)(intptr_t)pact_parse_type_annotation());
        }
        pact_expect(pact_TokenKind_RBracket);
        elems = pact_new_sublist();
        int64_t i = 0;
        while ((i < pact_list_len(type_nodes))) {
            pact_sublist_push(elems, (int64_t)(intptr_t)pact_list_get(type_nodes, i));
            i = (i + 1);
        }
        pact_finalize_sublist(elems);
    }
    const int64_t ta = pact_new_node(pact_NodeKind_TypeAnn);
    pact_list_pop(np_name);
    pact_list_push(np_name, (void*)name);
    pact_list_pop(np_elements);
    pact_list_push(np_elements, (void*)(intptr_t)elems);
    return ta;
}

int64_t pact_parse_fn_def(void) {
    pact_expect(pact_TokenKind_Fn);
    const char* name = pact_expect_value(pact_TokenKind_Ident);
    if (pact_at(pact_TokenKind_LBracket)) {
        pact_advance();
        while ((!pact_at(pact_TokenKind_RBracket))) {
            pact_advance();
        }
        pact_expect(pact_TokenKind_RBracket);
    }
    pact_expect(pact_TokenKind_LParen);
    pact_list* _l0 = pact_list_new();
    pact_list* param_nodes = _l0;
    if ((!pact_at(pact_TokenKind_RParen))) {
        pact_list_push(param_nodes, (void*)(intptr_t)pact_parse_param());
        while (pact_at(pact_TokenKind_Comma)) {
            pact_advance();
            if (pact_at(pact_TokenKind_RParen)) {
                break;
            }
            pact_list_push(param_nodes, (void*)(intptr_t)pact_parse_param());
        }
    }
    pact_expect(pact_TokenKind_RParen);
    const char* ret_type = "";
    const char* ret_str = "";
    if (pact_at(pact_TokenKind_Arrow)) {
        pact_advance();
        const int64_t rt = pact_parse_type_annotation();
        ret_str = (const char*)pact_list_get(np_name, rt);
    }
    if (pact_at(pact_TokenKind_Bang)) {
        pact_advance();
        pact_expect_value(pact_TokenKind_Ident);
        while (pact_at(pact_TokenKind_Comma)) {
            pact_advance();
            pact_skip_newlines();
            pact_expect_value(pact_TokenKind_Ident);
        }
    }
    pact_skip_newlines();
    const int64_t body = (-1);
    int64_t body_id = (-1);
    if (pact_at(pact_TokenKind_LBrace)) {
        body_id = pact_parse_block();
    }
    const int64_t params = pact_new_sublist();
    int64_t pi = 0;
    while ((pi < pact_list_len(param_nodes))) {
        pact_sublist_push(params, (int64_t)(intptr_t)pact_list_get(param_nodes, pi));
        pi = (pi + 1);
    }
    pact_finalize_sublist(params);
    const int64_t nd = pact_new_node(pact_NodeKind_FnDef);
    pact_list_pop(np_name);
    pact_list_push(np_name, (void*)name);
    pact_list_pop(np_params);
    pact_list_push(np_params, (void*)(intptr_t)params);
    pact_list_pop(np_body);
    pact_list_push(np_body, (void*)(intptr_t)body_id);
    pact_list_pop(np_return_type);
    pact_list_push(np_return_type, (void*)ret_str);
    return nd;
}

int64_t pact_parse_param(void) {
    int64_t is_mut = 0;
    if (pact_at(pact_TokenKind_Mut)) {
        is_mut = 1;
        pact_advance();
    }
    const char* name = "";
    if (pact_at(pact_TokenKind_Self)) {
        name = "self";
        pact_advance();
    } else {
        name = pact_expect_value(pact_TokenKind_Ident);
    }
    const char* type_str = "";
    if (pact_at(pact_TokenKind_Colon)) {
        pact_advance();
        const int64_t ta = pact_parse_type_annotation();
        type_str = (const char*)pact_list_get(np_name, ta);
    }
    const int64_t nd = pact_new_node(pact_NodeKind_Param);
    pact_list_pop(np_name);
    pact_list_push(np_name, (void*)name);
    pact_list_pop(np_type_name);
    pact_list_push(np_type_name, (void*)type_str);
    pact_list_pop(np_is_mut);
    pact_list_push(np_is_mut, (void*)(intptr_t)is_mut);
    return nd;
}

int64_t pact_parse_trait_def(void) {
    pact_expect(pact_TokenKind_Trait);
    const char* name = pact_expect_value(pact_TokenKind_Ident);
    pact_skip_newlines();
    pact_expect(pact_TokenKind_LBrace);
    pact_skip_newlines();
    pact_list* _l0 = pact_list_new();
    pact_list* method_nodes = _l0;
    while ((!pact_at(pact_TokenKind_RBrace))) {
        if (pact_at(pact_TokenKind_Fn)) {
            pact_list_push(method_nodes, (void*)(intptr_t)pact_parse_fn_def());
        } else {
            pact_advance();
        }
        pact_skip_newlines();
    }
    pact_expect(pact_TokenKind_RBrace);
    const int64_t methods = pact_new_sublist();
    int64_t i = 0;
    while ((i < pact_list_len(method_nodes))) {
        pact_sublist_push(methods, (int64_t)(intptr_t)pact_list_get(method_nodes, i));
        i = (i + 1);
    }
    pact_finalize_sublist(methods);
    const int64_t nd = pact_new_node(pact_NodeKind_TraitDef);
    pact_list_pop(np_name);
    pact_list_push(np_name, (void*)name);
    pact_list_pop(np_methods);
    pact_list_push(np_methods, (void*)(intptr_t)methods);
    return nd;
}

int64_t pact_parse_impl_block(void) {
    pact_expect(pact_TokenKind_Impl);
    const char* trait_name = pact_expect_value(pact_TokenKind_Ident);
    pact_skip_newlines();
    const char* type_name = "";
    if (pact_at(pact_TokenKind_For)) {
        pact_advance();
        pact_skip_newlines();
        type_name = pact_expect_value(pact_TokenKind_Ident);
    }
    pact_skip_newlines();
    pact_expect(pact_TokenKind_LBrace);
    pact_skip_newlines();
    pact_list* _l0 = pact_list_new();
    pact_list* method_nodes = _l0;
    while ((!pact_at(pact_TokenKind_RBrace))) {
        if (pact_at(pact_TokenKind_Fn)) {
            pact_list_push(method_nodes, (void*)(intptr_t)pact_parse_fn_def());
        } else {
            pact_advance();
        }
        pact_skip_newlines();
    }
    pact_expect(pact_TokenKind_RBrace);
    const int64_t methods = pact_new_sublist();
    int64_t i = 0;
    while ((i < pact_list_len(method_nodes))) {
        pact_sublist_push(methods, (int64_t)(intptr_t)pact_list_get(method_nodes, i));
        i = (i + 1);
    }
    pact_finalize_sublist(methods);
    const int64_t nd = pact_new_node(pact_NodeKind_ImplBlock);
    pact_list_pop(np_trait_name);
    pact_list_push(np_trait_name, (void*)trait_name);
    pact_list_pop(np_name);
    pact_list_push(np_name, (void*)type_name);
    pact_list_pop(np_methods);
    pact_list_push(np_methods, (void*)(intptr_t)methods);
    return nd;
}

int64_t pact_parse_block(void) {
    pact_expect(pact_TokenKind_LBrace);
    pact_skip_newlines();
    pact_list* _l0 = pact_list_new();
    pact_list* stmt_nodes = _l0;
    while ((!pact_at(pact_TokenKind_RBrace))) {
        pact_list_push(stmt_nodes, (void*)(intptr_t)pact_parse_stmt());
        pact_skip_newlines();
    }
    pact_expect(pact_TokenKind_RBrace);
    const int64_t stmts = pact_new_sublist();
    int64_t i = 0;
    while ((i < pact_list_len(stmt_nodes))) {
        pact_sublist_push(stmts, (int64_t)(intptr_t)pact_list_get(stmt_nodes, i));
        i = (i + 1);
    }
    pact_finalize_sublist(stmts);
    const int64_t nd = pact_new_node(pact_NodeKind_Block);
    pact_list_pop(np_stmts);
    pact_list_push(np_stmts, (void*)(intptr_t)stmts);
    return nd;
}

int64_t pact_parse_stmt(void) {
    if (pact_at(pact_TokenKind_While)) {
        return pact_parse_while_loop();
    }
    if (pact_at(pact_TokenKind_Loop)) {
        return pact_parse_loop_expr();
    }
    if (pact_at(pact_TokenKind_Break)) {
        pact_advance();
        pact_maybe_newline();
        return pact_new_node(pact_NodeKind_Break);
    }
    if (pact_at(pact_TokenKind_Continue)) {
        pact_advance();
        pact_maybe_newline();
        return pact_new_node(pact_NodeKind_Continue);
    }
    if (pact_at(pact_TokenKind_Let)) {
        return pact_parse_let_binding();
    }
    if (pact_at(pact_TokenKind_For)) {
        return pact_parse_for_in();
    }
    if (pact_at(pact_TokenKind_Return)) {
        return pact_parse_return_stmt();
    }
    if (pact_at(pact_TokenKind_If)) {
        const int64_t nd = pact_parse_if_expr();
        pact_maybe_newline();
        return nd;
    }
    const int64_t expr = pact_parse_expr();
    if (pact_at(pact_TokenKind_Equals)) {
        pact_advance();
        pact_skip_newlines();
        const int64_t val = pact_parse_expr();
        pact_maybe_newline();
        const int64_t nd = pact_new_node(pact_NodeKind_Assignment);
        pact_list_pop(np_target);
        pact_list_push(np_target, (void*)(intptr_t)expr);
        pact_list_pop(np_value);
        pact_list_push(np_value, (void*)(intptr_t)val);
        return nd;
    }
    if ((((pact_at(pact_TokenKind_PlusEq) || pact_at(pact_TokenKind_MinusEq)) || pact_at(pact_TokenKind_StarEq)) || pact_at(pact_TokenKind_SlashEq))) {
        const int64_t op_kind = pact_peek_kind();
        pact_advance();
        pact_skip_newlines();
        const int64_t val = pact_parse_expr();
        pact_maybe_newline();
        const char* op_str = "+";
        if ((op_kind == pact_TokenKind_MinusEq)) {
            op_str = "-";
        } else if ((op_kind == pact_TokenKind_StarEq)) {
            op_str = "*";
        } else {
            if ((op_kind == pact_TokenKind_SlashEq)) {
                op_str = "/";
            }
        }
        const int64_t nd = pact_new_node(pact_NodeKind_CompoundAssign);
        pact_list_pop(np_op);
        pact_list_push(np_op, (void*)op_str);
        pact_list_pop(np_target);
        pact_list_push(np_target, (void*)(intptr_t)expr);
        pact_list_pop(np_value);
        pact_list_push(np_value, (void*)(intptr_t)val);
        return nd;
    }
    pact_maybe_newline();
    const int64_t nd = pact_new_node(pact_NodeKind_ExprStmt);
    pact_list_pop(np_value);
    pact_list_push(np_value, (void*)(intptr_t)expr);
    return nd;
}

int64_t pact_parse_let_binding(void) {
    pact_expect(pact_TokenKind_Let);
    int64_t is_mut = 0;
    if (pact_at(pact_TokenKind_Mut)) {
        is_mut = 1;
        pact_advance();
    }
    const char* name = pact_expect_value(pact_TokenKind_Ident);
    int64_t type_ann = (-1);
    if (pact_at(pact_TokenKind_Colon)) {
        pact_advance();
        type_ann = pact_parse_type_annotation();
    }
    pact_expect(pact_TokenKind_Equals);
    pact_skip_newlines();
    const int64_t val = pact_parse_expr();
    pact_maybe_newline();
    const int64_t nd = pact_new_node(pact_NodeKind_LetBinding);
    pact_list_pop(np_name);
    pact_list_push(np_name, (void*)name);
    pact_list_pop(np_value);
    pact_list_push(np_value, (void*)(intptr_t)val);
    pact_list_pop(np_is_mut);
    pact_list_push(np_is_mut, (void*)(intptr_t)is_mut);
    pact_list_pop(np_target);
    pact_list_push(np_target, (void*)(intptr_t)type_ann);
    return nd;
}

int64_t pact_parse_return_stmt(void) {
    pact_expect(pact_TokenKind_Return);
    if (((pact_at(pact_TokenKind_Newline) || pact_at(pact_TokenKind_RBrace)) || pact_at(pact_TokenKind_EOF))) {
        pact_maybe_newline();
        const int64_t nd = pact_new_node(pact_NodeKind_Return);
        return nd;
    }
    const int64_t val = pact_parse_expr();
    pact_maybe_newline();
    const int64_t nd = pact_new_node(pact_NodeKind_Return);
    pact_list_pop(np_value);
    pact_list_push(np_value, (void*)(intptr_t)val);
    return nd;
}

int64_t pact_parse_if_expr(void) {
    pact_expect(pact_TokenKind_If);
    const int64_t cond = pact_parse_expr();
    pact_skip_newlines();
    const int64_t then_b = pact_parse_block();
    int64_t else_b = (-1);
    pact_skip_newlines();
    if (pact_at(pact_TokenKind_Else)) {
        pact_advance();
        pact_skip_newlines();
        if (pact_at(pact_TokenKind_If)) {
            const int64_t inner = pact_parse_if_expr();
            const int64_t stmts = pact_new_sublist();
            pact_sublist_push(stmts, inner);
            pact_finalize_sublist(stmts);
            const int64_t blk = pact_new_node(pact_NodeKind_Block);
            pact_list_pop(np_stmts);
            pact_list_push(np_stmts, (void*)(intptr_t)stmts);
            else_b = blk;
        } else {
            else_b = pact_parse_block();
        }
    }
    const int64_t nd = pact_new_node(pact_NodeKind_IfExpr);
    pact_list_pop(np_condition);
    pact_list_push(np_condition, (void*)(intptr_t)cond);
    pact_list_pop(np_then_body);
    pact_list_push(np_then_body, (void*)(intptr_t)then_b);
    pact_list_pop(np_else_body);
    pact_list_push(np_else_body, (void*)(intptr_t)else_b);
    return nd;
}

int64_t pact_parse_while_loop(void) {
    pact_expect(pact_TokenKind_While);
    const int64_t cond = pact_parse_expr();
    pact_skip_newlines();
    const int64_t body = pact_parse_block();
    const int64_t nd = pact_new_node(pact_NodeKind_WhileLoop);
    pact_list_pop(np_condition);
    pact_list_push(np_condition, (void*)(intptr_t)cond);
    pact_list_pop(np_body);
    pact_list_push(np_body, (void*)(intptr_t)body);
    return nd;
}

int64_t pact_parse_loop_expr(void) {
    pact_expect(pact_TokenKind_Loop);
    pact_skip_newlines();
    const int64_t body = pact_parse_block();
    const int64_t nd = pact_new_node(pact_NodeKind_LoopExpr);
    pact_list_pop(np_body);
    pact_list_push(np_body, (void*)(intptr_t)body);
    return nd;
}

int64_t pact_parse_for_in(void) {
    pact_expect(pact_TokenKind_For);
    const char* var = "";
    int64_t pat = (-1);
    if (pact_at(pact_TokenKind_LParen)) {
        pat = pact_parse_pattern();
        var = "_tuple";
    } else {
        var = pact_expect_value(pact_TokenKind_Ident);
    }
    pact_expect(pact_TokenKind_In);
    const int64_t iter = pact_parse_expr();
    pact_skip_newlines();
    const int64_t body = pact_parse_block();
    const int64_t nd = pact_new_node(pact_NodeKind_ForIn);
    pact_list_pop(np_var_name);
    pact_list_push(np_var_name, (void*)var);
    pact_list_pop(np_iterable);
    pact_list_push(np_iterable, (void*)(intptr_t)iter);
    pact_list_pop(np_body);
    pact_list_push(np_body, (void*)(intptr_t)body);
    if ((pat != (-1))) {
        pact_list_pop(np_elements);
        pact_list_push(np_elements, (void*)(intptr_t)pat);
    }
    return nd;
}

int64_t pact_parse_expr(void) {
    return pact_parse_or();
}

int64_t pact_parse_or(void) {
    int64_t left = pact_parse_and();
    while (pact_at(pact_TokenKind_Or)) {
        pact_advance();
        pact_skip_newlines();
        const int64_t right = pact_parse_and();
        const int64_t nd = pact_new_node(pact_NodeKind_BinOp);
        pact_list_pop(np_op);
        pact_list_push(np_op, (void*)"||");
        pact_list_pop(np_left);
        pact_list_push(np_left, (void*)(intptr_t)left);
        pact_list_pop(np_right);
        pact_list_push(np_right, (void*)(intptr_t)right);
        left = nd;
    }
    return left;
}

int64_t pact_parse_and(void) {
    int64_t left = pact_parse_equality();
    while (pact_at(pact_TokenKind_And)) {
        pact_advance();
        pact_skip_newlines();
        const int64_t right = pact_parse_equality();
        const int64_t nd = pact_new_node(pact_NodeKind_BinOp);
        pact_list_pop(np_op);
        pact_list_push(np_op, (void*)"&&");
        pact_list_pop(np_left);
        pact_list_push(np_left, (void*)(intptr_t)left);
        pact_list_pop(np_right);
        pact_list_push(np_right, (void*)(intptr_t)right);
        left = nd;
    }
    return left;
}

int64_t pact_parse_equality(void) {
    int64_t left = pact_parse_comparison();
    while ((pact_at(pact_TokenKind_EqEq) || pact_at(pact_TokenKind_NotEq))) {
        const char* op = pact_advance_value();
        pact_skip_newlines();
        const int64_t right = pact_parse_comparison();
        const int64_t nd = pact_new_node(pact_NodeKind_BinOp);
        pact_list_pop(np_op);
        pact_list_push(np_op, (void*)op);
        pact_list_pop(np_left);
        pact_list_push(np_left, (void*)(intptr_t)left);
        pact_list_pop(np_right);
        pact_list_push(np_right, (void*)(intptr_t)right);
        left = nd;
    }
    return left;
}

int64_t pact_parse_comparison(void) {
    int64_t left = pact_parse_additive();
    while ((((pact_at(pact_TokenKind_Less) || pact_at(pact_TokenKind_Greater)) || pact_at(pact_TokenKind_LessEq)) || pact_at(pact_TokenKind_GreaterEq))) {
        const char* op = pact_advance_value();
        pact_skip_newlines();
        const int64_t right = pact_parse_additive();
        const int64_t nd = pact_new_node(pact_NodeKind_BinOp);
        pact_list_pop(np_op);
        pact_list_push(np_op, (void*)op);
        pact_list_pop(np_left);
        pact_list_push(np_left, (void*)(intptr_t)left);
        pact_list_pop(np_right);
        pact_list_push(np_right, (void*)(intptr_t)right);
        left = nd;
    }
    return left;
}

int64_t pact_parse_additive(void) {
    int64_t left = pact_parse_multiplicative();
    while ((pact_at(pact_TokenKind_Plus) || pact_at(pact_TokenKind_Minus))) {
        const char* op = pact_advance_value();
        pact_skip_newlines();
        const int64_t right = pact_parse_multiplicative();
        const int64_t nd = pact_new_node(pact_NodeKind_BinOp);
        pact_list_pop(np_op);
        pact_list_push(np_op, (void*)op);
        pact_list_pop(np_left);
        pact_list_push(np_left, (void*)(intptr_t)left);
        pact_list_pop(np_right);
        pact_list_push(np_right, (void*)(intptr_t)right);
        left = nd;
    }
    return left;
}

int64_t pact_parse_multiplicative(void) {
    int64_t left = pact_parse_unary();
    while (((pact_at(pact_TokenKind_Star) || pact_at(pact_TokenKind_Slash)) || pact_at(pact_TokenKind_Percent))) {
        const char* op = pact_advance_value();
        pact_skip_newlines();
        const int64_t right = pact_parse_unary();
        const int64_t nd = pact_new_node(pact_NodeKind_BinOp);
        pact_list_pop(np_op);
        pact_list_push(np_op, (void*)op);
        pact_list_pop(np_left);
        pact_list_push(np_left, (void*)(intptr_t)left);
        pact_list_pop(np_right);
        pact_list_push(np_right, (void*)(intptr_t)right);
        left = nd;
    }
    return left;
}

int64_t pact_parse_unary(void) {
    if (pact_at(pact_TokenKind_Minus)) {
        pact_advance();
        const int64_t operand = pact_parse_unary();
        const int64_t nd = pact_new_node(pact_NodeKind_UnaryOp);
        pact_list_pop(np_op);
        pact_list_push(np_op, (void*)"-");
        pact_list_pop(np_left);
        pact_list_push(np_left, (void*)(intptr_t)operand);
        return nd;
    }
    if (pact_at(pact_TokenKind_Bang)) {
        pact_advance();
        const int64_t operand = pact_parse_unary();
        const int64_t nd = pact_new_node(pact_NodeKind_UnaryOp);
        pact_list_pop(np_op);
        pact_list_push(np_op, (void*)"!");
        pact_list_pop(np_left);
        pact_list_push(np_left, (void*)(intptr_t)operand);
        return nd;
    }
    return pact_parse_postfix();
}

int64_t pact_parse_postfix(void) {
    int64_t node = pact_parse_primary();
    int64_t running = 1;
    while (running) {
        if (pact_at(pact_TokenKind_Dot)) {
            pact_advance();
            const char* member = pact_expect_value(pact_TokenKind_Ident);
            if (pact_at(pact_TokenKind_LParen)) {
                pact_advance();
                pact_list* _l0 = pact_list_new();
                pact_list* arg_nodes = _l0;
                if ((!pact_at(pact_TokenKind_RParen))) {
                    pact_list_push(arg_nodes, (void*)(intptr_t)pact_parse_expr());
                    while (pact_at(pact_TokenKind_Comma)) {
                        pact_advance();
                        pact_skip_newlines();
                        if (pact_at(pact_TokenKind_RParen)) {
                            break;
                        }
                        pact_list_push(arg_nodes, (void*)(intptr_t)pact_parse_expr());
                    }
                    pact_skip_newlines();
                }
                pact_expect(pact_TokenKind_RParen);
                const int64_t args = pact_new_sublist();
                int64_t ai = 0;
                while ((ai < pact_list_len(arg_nodes))) {
                    pact_sublist_push(args, (int64_t)(intptr_t)pact_list_get(arg_nodes, ai));
                    ai = (ai + 1);
                }
                pact_finalize_sublist(args);
                const int64_t nd = pact_new_node(pact_NodeKind_MethodCall);
                pact_list_pop(np_obj);
                pact_list_push(np_obj, (void*)(intptr_t)node);
                pact_list_pop(np_method);
                pact_list_push(np_method, (void*)member);
                pact_list_pop(np_args);
                pact_list_push(np_args, (void*)(intptr_t)args);
                node = nd;
            } else {
                const int64_t nd = pact_new_node(pact_NodeKind_FieldAccess);
                pact_list_pop(np_obj);
                pact_list_push(np_obj, (void*)(intptr_t)node);
                pact_list_pop(np_name);
                pact_list_push(np_name, (void*)member);
                node = nd;
                if (pact_at(pact_TokenKind_LBrace)) {
                    if (pact_looks_like_struct_lit()) {
                        const char* dotted = pact_flatten_field_access(node);
                        if ((!pact_str_eq(dotted, ""))) {
                            node = pact_parse_struct_lit(dotted);
                        }
                    }
                }
            }
        } else if (pact_at(pact_TokenKind_LParen)) {
            pact_advance();
            pact_list* _l1 = pact_list_new();
            pact_list* call_arg_nodes = _l1;
            if ((!pact_at(pact_TokenKind_RParen))) {
                pact_skip_newlines();
                pact_skip_named_arg_label();
                pact_list_push(call_arg_nodes, (void*)(intptr_t)pact_parse_expr());
                while (pact_at(pact_TokenKind_Comma)) {
                    pact_advance();
                    pact_skip_newlines();
                    if (pact_at(pact_TokenKind_RParen)) {
                        break;
                    }
                    pact_skip_named_arg_label();
                    pact_list_push(call_arg_nodes, (void*)(intptr_t)pact_parse_expr());
                }
                pact_skip_newlines();
            }
            pact_expect(pact_TokenKind_RParen);
            const int64_t args = pact_new_sublist();
            int64_t ci = 0;
            while ((ci < pact_list_len(call_arg_nodes))) {
                pact_sublist_push(args, (int64_t)(intptr_t)pact_list_get(call_arg_nodes, ci));
                ci = (ci + 1);
            }
            pact_finalize_sublist(args);
            const int64_t nd = pact_new_node(pact_NodeKind_Call);
            pact_list_pop(np_left);
            pact_list_push(np_left, (void*)(intptr_t)node);
            pact_list_pop(np_args);
            pact_list_push(np_args, (void*)(intptr_t)args);
            node = nd;
        } else {
            if (pact_at(pact_TokenKind_LBracket)) {
                pact_advance();
                pact_skip_newlines();
                const int64_t idx = pact_parse_expr();
                pact_skip_newlines();
                pact_expect(pact_TokenKind_RBracket);
                const int64_t nd = pact_new_node(pact_NodeKind_IndexExpr);
                pact_list_pop(np_obj);
                pact_list_push(np_obj, (void*)(intptr_t)node);
                pact_list_pop(np_index);
                pact_list_push(np_index, (void*)(intptr_t)idx);
                node = nd;
            } else {
                running = 0;
            }
        }
    }
    return node;
}

void pact_skip_named_arg_label(void) {
    if (pact_at(pact_TokenKind_Ident)) {
        const int64_t saved = pos;
        pact_advance();
        if (pact_at(pact_TokenKind_Colon)) {
            pact_advance();
            pact_skip_newlines();
        } else {
            pos = saved;
        }
    }
}

const char* pact_flatten_field_access(int64_t node) {
    const int64_t kind = (int64_t)(intptr_t)pact_list_get(np_kind, node);
    if ((kind == pact_NodeKind_Ident)) {
        return (const char*)pact_list_get(np_name, node);
    }
    if ((kind == pact_NodeKind_FieldAccess)) {
        const char* base = pact_flatten_field_access((int64_t)(intptr_t)pact_list_get(np_obj, node));
        if ((!pact_str_eq(base, ""))) {
            return pact_str_concat(pact_str_concat(base, "."), (const char*)pact_list_get(np_name, node));
        }
    }
    return "";
}

int64_t pact_looks_like_struct_lit(void) {
    const int64_t saved = pos;
    if ((!pact_at(pact_TokenKind_LBrace))) {
        return 0;
    }
    pact_advance();
    pact_skip_newlines();
    if (pact_at(pact_TokenKind_RBrace)) {
        pos = saved;
        return 1;
    }
    if ((!pact_at(pact_TokenKind_Ident))) {
        pos = saved;
        return 0;
    }
    pact_advance();
    const int64_t result = pact_at(pact_TokenKind_Colon);
    pos = saved;
    return result;
}

int64_t pact_parse_primary(void) {
    if (pact_at(pact_TokenKind_Match)) {
        return pact_parse_match_expr();
    }
    if (pact_at(pact_TokenKind_If)) {
        return pact_parse_if_expr();
    }
    if (pact_at(pact_TokenKind_Self)) {
        pact_advance();
        const int64_t nd = pact_new_node(pact_NodeKind_Ident);
        pact_list_pop(np_name);
        pact_list_push(np_name, (void*)"self");
        return nd;
    }
    if (pact_at(pact_TokenKind_Ident)) {
        const char* name = pact_advance_value();
        if (pact_str_eq(name, "true")) {
            const int64_t nd = pact_new_node(pact_NodeKind_BoolLit);
            pact_list_pop(np_int_val);
            pact_list_push(np_int_val, (void*)(intptr_t)1);
            return nd;
        }
        if (pact_str_eq(name, "false")) {
            const int64_t nd = pact_new_node(pact_NodeKind_BoolLit);
            pact_list_pop(np_int_val);
            pact_list_push(np_int_val, (void*)(intptr_t)0);
            return nd;
        }
        if ((pact_at(pact_TokenKind_LBrace) && pact_looks_like_struct_lit())) {
            return pact_parse_struct_lit(name);
        }
        const int64_t nd = pact_new_node(pact_NodeKind_Ident);
        pact_list_pop(np_name);
        pact_list_push(np_name, (void*)name);
        return nd;
    }
    if (pact_at(pact_TokenKind_Int)) {
        const char* val_str = pact_advance_value();
        const int64_t nd = pact_new_node(pact_NodeKind_IntLit);
        pact_list_pop(np_str_val);
        pact_list_push(np_str_val, (void*)val_str);
        if (pact_at(pact_TokenKind_DotDot)) {
            pact_advance();
            const int64_t end_nd = pact_parse_primary();
            const int64_t rng = pact_new_node(pact_NodeKind_RangeLit);
            pact_list_pop(np_start);
            pact_list_push(np_start, (void*)(intptr_t)nd);
            pact_list_pop(np_end);
            pact_list_push(np_end, (void*)(intptr_t)end_nd);
            return rng;
        }
        if (pact_at(pact_TokenKind_DotDoteq)) {
            pact_advance();
            const int64_t end_nd = pact_parse_primary();
            const int64_t rng = pact_new_node(pact_NodeKind_RangeLit);
            pact_list_pop(np_start);
            pact_list_push(np_start, (void*)(intptr_t)nd);
            pact_list_pop(np_end);
            pact_list_push(np_end, (void*)(intptr_t)end_nd);
            pact_list_pop(np_inclusive);
            pact_list_push(np_inclusive, (void*)(intptr_t)1);
            return rng;
        }
        return nd;
    }
    if (pact_at(pact_TokenKind_Float)) {
        const char* val_str = pact_advance_value();
        const int64_t nd = pact_new_node(pact_NodeKind_FloatLit);
        pact_list_pop(np_str_val);
        pact_list_push(np_str_val, (void*)val_str);
        return nd;
    }
    if (pact_at(pact_TokenKind_LParen)) {
        pact_advance();
        pact_skip_newlines();
        if (pact_at(pact_TokenKind_RParen)) {
            pact_advance();
            return pact_new_node(pact_NodeKind_IntLit);
        }
        const int64_t first = pact_parse_expr();
        if (pact_at(pact_TokenKind_Comma)) {
            pact_list* _l0 = pact_list_new();
            pact_list_push(_l0, (void*)(intptr_t)first);
            pact_list* elem_nodes = _l0;
            while (pact_at(pact_TokenKind_Comma)) {
                pact_advance();
                pact_skip_newlines();
                if (pact_at(pact_TokenKind_RParen)) {
                    break;
                }
                pact_list_push(elem_nodes, (void*)(intptr_t)pact_parse_expr());
            }
            pact_expect(pact_TokenKind_RParen);
            const int64_t elems = pact_new_sublist();
            int64_t ti = 0;
            while ((ti < pact_list_len(elem_nodes))) {
                pact_sublist_push(elems, (int64_t)(intptr_t)pact_list_get(elem_nodes, ti));
                ti = (ti + 1);
            }
            pact_finalize_sublist(elems);
            const int64_t nd = pact_new_node(pact_NodeKind_TupleLit);
            pact_list_pop(np_elements);
            pact_list_push(np_elements, (void*)(intptr_t)elems);
            return nd;
        }
        pact_skip_newlines();
        pact_expect(pact_TokenKind_RParen);
        return first;
    }
    if (pact_at(pact_TokenKind_LBracket)) {
        return pact_parse_list_lit();
    }
    if (pact_at(pact_TokenKind_StringStart)) {
        return pact_parse_interp_string();
    }
    if (pact_at(pact_TokenKind_LBrace)) {
        return pact_parse_block();
    }
    char _si_1[4096];
    snprintf(_si_1, 4096, "parse error: unexpected token %lld at line %lld:%lld", (long long)pact_peek_kind(), (long long)pact_peek_line(), (long long)pact_peek_col());
    printf("%s\n", strdup(_si_1));
    pact_advance();
    return pact_new_node(pact_NodeKind_IntLit);
}

int64_t pact_parse_struct_lit(const char* type_name) {
    pact_expect(pact_TokenKind_LBrace);
    pact_skip_newlines();
    pact_list* _l0 = pact_list_new();
    pact_list* field_nodes = _l0;
    while ((!pact_at(pact_TokenKind_RBrace))) {
        const char* fname = pact_expect_value(pact_TokenKind_Ident);
        pact_expect(pact_TokenKind_Colon);
        pact_skip_newlines();
        const int64_t fval = pact_parse_expr();
        const int64_t sf = pact_new_node(pact_NodeKind_StructLitField);
        pact_list_pop(np_name);
        pact_list_push(np_name, (void*)fname);
        pact_list_pop(np_value);
        pact_list_push(np_value, (void*)(intptr_t)fval);
        pact_list_push(field_nodes, (void*)(intptr_t)sf);
        if (pact_at(pact_TokenKind_Comma)) {
            pact_advance();
        }
        pact_skip_newlines();
    }
    pact_expect(pact_TokenKind_RBrace);
    const int64_t flds = pact_new_sublist();
    int64_t i = 0;
    while ((i < pact_list_len(field_nodes))) {
        pact_sublist_push(flds, (int64_t)(intptr_t)pact_list_get(field_nodes, i));
        i = (i + 1);
    }
    pact_finalize_sublist(flds);
    const int64_t nd = pact_new_node(pact_NodeKind_StructLit);
    pact_list_pop(np_type_name);
    pact_list_push(np_type_name, (void*)type_name);
    pact_list_pop(np_fields);
    pact_list_push(np_fields, (void*)(intptr_t)flds);
    return nd;
}

int64_t pact_parse_list_lit(void) {
    pact_expect(pact_TokenKind_LBracket);
    pact_skip_newlines();
    pact_list* _l0 = pact_list_new();
    pact_list* elem_nodes = _l0;
    while ((!pact_at(pact_TokenKind_RBracket))) {
        pact_list_push(elem_nodes, (void*)(intptr_t)pact_parse_expr());
        if (pact_at(pact_TokenKind_Comma)) {
            pact_advance();
        }
        pact_skip_newlines();
    }
    pact_expect(pact_TokenKind_RBracket);
    const int64_t elems = pact_new_sublist();
    int64_t i = 0;
    while ((i < pact_list_len(elem_nodes))) {
        pact_sublist_push(elems, (int64_t)(intptr_t)pact_list_get(elem_nodes, i));
        i = (i + 1);
    }
    pact_finalize_sublist(elems);
    const int64_t nd = pact_new_node(pact_NodeKind_ListLit);
    pact_list_pop(np_elements);
    pact_list_push(np_elements, (void*)(intptr_t)elems);
    return nd;
}

int64_t pact_parse_interp_string(void) {
    pact_expect(pact_TokenKind_StringStart);
    pact_list* _l0 = pact_list_new();
    pact_list* part_nodes = _l0;
    while ((!pact_at(pact_TokenKind_StringEnd))) {
        if (pact_at(pact_TokenKind_StringPart)) {
            const char* s = pact_advance_value();
            const int64_t sn = pact_new_node(pact_NodeKind_Ident);
            pact_list_pop(np_str_val);
            pact_list_push(np_str_val, (void*)s);
            pact_list_pop(np_name);
            pact_list_push(np_name, (void*)s);
            pact_list_push(part_nodes, (void*)(intptr_t)sn);
        } else if (pact_at(pact_TokenKind_InterpStart)) {
            pact_advance();
            pact_list_push(part_nodes, (void*)(intptr_t)pact_parse_expr());
            pact_expect(pact_TokenKind_InterpEnd);
        } else {
            char _si_1[4096];
            snprintf(_si_1, 4096, "parse error: unexpected token in string: %lld", (long long)pact_peek_kind());
            printf("%s\n", strdup(_si_1));
            pact_advance();
        }
    }
    pact_expect(pact_TokenKind_StringEnd);
    const int64_t parts = pact_new_sublist();
    int64_t i = 0;
    while ((i < pact_list_len(part_nodes))) {
        pact_sublist_push(parts, (int64_t)(intptr_t)pact_list_get(part_nodes, i));
        i = (i + 1);
    }
    pact_finalize_sublist(parts);
    const int64_t nd = pact_new_node(pact_NodeKind_InterpString);
    pact_list_pop(np_elements);
    pact_list_push(np_elements, (void*)(intptr_t)parts);
    return nd;
}

int64_t pact_parse_match_expr(void) {
    pact_expect(pact_TokenKind_Match);
    const int64_t scrut = pact_parse_expr();
    pact_skip_newlines();
    pact_expect(pact_TokenKind_LBrace);
    pact_skip_newlines();
    pact_list* _l0 = pact_list_new();
    pact_list* arm_nodes = _l0;
    while ((!pact_at(pact_TokenKind_RBrace))) {
        pact_list_push(arm_nodes, (void*)(intptr_t)pact_parse_match_arm());
        pact_skip_newlines();
    }
    pact_expect(pact_TokenKind_RBrace);
    const int64_t arms = pact_new_sublist();
    int64_t i = 0;
    while ((i < pact_list_len(arm_nodes))) {
        pact_sublist_push(arms, (int64_t)(intptr_t)pact_list_get(arm_nodes, i));
        i = (i + 1);
    }
    pact_finalize_sublist(arms);
    const int64_t nd = pact_new_node(pact_NodeKind_MatchExpr);
    pact_list_pop(np_scrutinee);
    pact_list_push(np_scrutinee, (void*)(intptr_t)scrut);
    pact_list_pop(np_arms);
    pact_list_push(np_arms, (void*)(intptr_t)arms);
    return nd;
}

int64_t pact_parse_match_arm(void) {
    const int64_t pat = pact_parse_pattern();
    int64_t guard = (-1);
    pact_skip_newlines();
    if (pact_at(pact_TokenKind_If)) {
        pact_advance();
        guard = pact_parse_expr();
    }
    pact_skip_newlines();
    pact_expect(pact_TokenKind_FatArrow);
    pact_skip_newlines();
    int64_t body = (-1);
    if (pact_at(pact_TokenKind_LBrace)) {
        body = pact_parse_block();
    } else {
        body = pact_parse_stmt();
    }
    const int64_t nd = pact_new_node(pact_NodeKind_MatchArm);
    pact_list_pop(np_pattern);
    pact_list_push(np_pattern, (void*)(intptr_t)pat);
    pact_list_pop(np_body);
    pact_list_push(np_body, (void*)(intptr_t)body);
    pact_list_pop(np_guard);
    pact_list_push(np_guard, (void*)(intptr_t)guard);
    return nd;
}

int64_t pact_parse_pattern(void) {
    if (pact_at(pact_TokenKind_LParen)) {
        pact_advance();
        pact_skip_newlines();
        const int64_t elems = pact_new_sublist();
        pact_sublist_push(elems, pact_parse_pattern());
        while (pact_at(pact_TokenKind_Comma)) {
            pact_advance();
            pact_skip_newlines();
            pact_sublist_push(elems, pact_parse_pattern());
        }
        pact_finalize_sublist(elems);
        pact_skip_newlines();
        pact_expect(pact_TokenKind_RParen);
        const int64_t nd = pact_new_node(pact_NodeKind_TuplePattern);
        pact_list_pop(np_elements);
        pact_list_push(np_elements, (void*)(intptr_t)elems);
        return nd;
    }
    if (pact_at(pact_TokenKind_StringStart)) {
        const int64_t str_node = pact_parse_interp_string();
        const int64_t nd = pact_new_node(pact_NodeKind_StringPattern);
        pact_list_pop(np_str_val);
        pact_list_push(np_str_val, (void*)(const char*)pact_list_get(np_str_val, str_node));
        return nd;
    }
    if (pact_at(pact_TokenKind_Int)) {
        const char* v = pact_advance_value();
        const int64_t nd = pact_new_node(pact_NodeKind_IntPattern);
        pact_list_pop(np_str_val);
        pact_list_push(np_str_val, (void*)v);
        return nd;
    }
    if (pact_at(pact_TokenKind_Ident)) {
        const char* name = pact_advance_value();
        if (pact_str_eq(name, "_")) {
            return pact_new_node(pact_NodeKind_WildcardPattern);
        }
        if (pact_at(pact_TokenKind_LParen)) {
            pact_advance();
            pact_skip_newlines();
            const int64_t flds = pact_new_sublist();
            if ((!pact_at(pact_TokenKind_RParen))) {
                pact_sublist_push(flds, pact_parse_pattern());
                while (pact_at(pact_TokenKind_Comma)) {
                    pact_advance();
                    pact_skip_newlines();
                    pact_sublist_push(flds, pact_parse_pattern());
                }
            }
            pact_finalize_sublist(flds);
            pact_skip_newlines();
            pact_expect(pact_TokenKind_RParen);
            const int64_t nd = pact_new_node(pact_NodeKind_EnumPattern);
            pact_list_pop(np_name);
            pact_list_push(np_name, (void*)name);
            pact_list_pop(np_fields);
            pact_list_push(np_fields, (void*)(intptr_t)flds);
            return nd;
        }
        const int64_t nd = pact_new_node(pact_NodeKind_IdentPattern);
        pact_list_pop(np_name);
        pact_list_push(np_name, (void*)name);
        return nd;
    }
    char _si_0[4096];
    snprintf(_si_0, 4096, "parse error: unexpected token in pattern: %lld", (long long)pact_peek_kind());
    printf("%s\n", strdup(_si_0));
    pact_advance();
    return pact_new_node(pact_NodeKind_WildcardPattern);
}

void pact_print_indent(int64_t depth) {
    int64_t i = 0;
    while ((i < depth)) {
        printf("%s\n", "  ");
        i = (i + 1);
    }
}

void pact_print_node(int64_t id, int64_t depth) {
    if ((id == (-1))) {
        return;
    }
    const int64_t kind = (int64_t)(intptr_t)pact_list_get(np_kind, id);
    const char* name = (const char*)pact_list_get(np_name, id);
    const char* op = (const char*)pact_list_get(np_op, id);
    const char* str_val = (const char*)pact_list_get(np_str_val, id);
    if ((kind == pact_NodeKind_Program)) {
        printf("%s\n", "Program");
        const int64_t fns_sl = (int64_t)(intptr_t)pact_list_get(np_params, id);
        if ((fns_sl != (-1))) {
            int64_t i = 0;
            while ((i < pact_sublist_length(fns_sl))) {
                pact_print_node(pact_sublist_get(fns_sl, i), (depth + 1));
                i = (i + 1);
            }
        }
        const int64_t types_sl = (int64_t)(intptr_t)pact_list_get(np_fields, id);
        if ((types_sl != (-1))) {
            int64_t i = 0;
            while ((i < pact_sublist_length(types_sl))) {
                pact_print_node(pact_sublist_get(types_sl, i), (depth + 1));
                i = (i + 1);
            }
        }
    } else if ((kind == pact_NodeKind_FnDef)) {
        char _si_0[4096];
        snprintf(_si_0, 4096, "%sFnDef: %s", pact_str_substr("  ", 0, 0), name);
        printf("%s\n", strdup(_si_0));
        const int64_t p_sl = (int64_t)(intptr_t)pact_list_get(np_params, id);
        if ((p_sl != (-1))) {
            int64_t i = 0;
            while ((i < pact_sublist_length(p_sl))) {
                const int64_t pid = pact_sublist_get(p_sl, i);
                char _si_1[4096];
                snprintf(_si_1, 4096, "  param: %s : %s", (const char*)pact_list_get(np_name, pid), (const char*)pact_list_get(np_type_name, pid));
                printf("%s\n", strdup(_si_1));
                i = (i + 1);
            }
        }
        const int64_t body = (int64_t)(intptr_t)pact_list_get(np_body, id);
        if ((body != (-1))) {
            pact_print_node(body, (depth + 1));
        }
    } else {
        if ((kind == pact_NodeKind_Block)) {
            printf("%s\n", "  Block");
            const int64_t stmts_sl = (int64_t)(intptr_t)pact_list_get(np_stmts, id);
            if ((stmts_sl != (-1))) {
                int64_t i = 0;
                while ((i < pact_sublist_length(stmts_sl))) {
                    pact_print_node(pact_sublist_get(stmts_sl, i), (depth + 1));
                    i = (i + 1);
                }
            }
        } else if ((kind == pact_NodeKind_LetBinding)) {
            char _si_2[4096];
            snprintf(_si_2, 4096, "    LetBinding: %s (mut=%lld)", name, (long long)(int64_t)(intptr_t)pact_list_get(np_is_mut, id));
            printf("%s\n", strdup(_si_2));
            pact_print_node((int64_t)(intptr_t)pact_list_get(np_value, id), (depth + 1));
        } else {
            if ((kind == pact_NodeKind_ExprStmt)) {
                printf("%s\n", "    ExprStmt");
                pact_print_node((int64_t)(intptr_t)pact_list_get(np_value, id), (depth + 1));
            } else if ((kind == pact_NodeKind_BinOp)) {
                char _si_3[4096];
                snprintf(_si_3, 4096, "      BinOp: %s", op);
                printf("%s\n", strdup(_si_3));
                pact_print_node((int64_t)(intptr_t)pact_list_get(np_left, id), (depth + 1));
                pact_print_node((int64_t)(intptr_t)pact_list_get(np_right, id), (depth + 1));
            } else {
                if ((kind == pact_NodeKind_Call)) {
                    printf("%s\n", "      Call");
                    pact_print_node((int64_t)(intptr_t)pact_list_get(np_left, id), (depth + 1));
                } else if ((kind == pact_NodeKind_MethodCall)) {
                    char _si_4[4096];
                    snprintf(_si_4, 4096, "      MethodCall: .%s()", (const char*)pact_list_get(np_method, id));
                    printf("%s\n", strdup(_si_4));
                    pact_print_node((int64_t)(intptr_t)pact_list_get(np_obj, id), (depth + 1));
                } else {
                    if ((kind == pact_NodeKind_IntLit)) {
                        char _si_5[4096];
                        snprintf(_si_5, 4096, "      IntLit: %s", str_val);
                        printf("%s\n", strdup(_si_5));
                    } else if ((kind == pact_NodeKind_Ident)) {
                        char _si_6[4096];
                        snprintf(_si_6, 4096, "      Ident: %s", name);
                        printf("%s\n", strdup(_si_6));
                    } else {
                        if ((kind == pact_NodeKind_Return)) {
                            printf("%s\n", "    Return");
                            pact_print_node((int64_t)(intptr_t)pact_list_get(np_value, id), (depth + 1));
                        } else if ((kind == pact_NodeKind_IfExpr)) {
                            printf("%s\n", "    IfExpr");
                            pact_print_node((int64_t)(intptr_t)pact_list_get(np_condition, id), (depth + 1));
                            pact_print_node((int64_t)(intptr_t)pact_list_get(np_then_body, id), (depth + 1));
                            pact_print_node((int64_t)(intptr_t)pact_list_get(np_else_body, id), (depth + 1));
                        } else {
                            if ((kind == pact_NodeKind_WhileLoop)) {
                                printf("%s\n", "    WhileLoop");
                                pact_print_node((int64_t)(intptr_t)pact_list_get(np_condition, id), (depth + 1));
                                pact_print_node((int64_t)(intptr_t)pact_list_get(np_body, id), (depth + 1));
                            } else if ((kind == pact_NodeKind_ForIn)) {
                                char _si_7[4096];
                                snprintf(_si_7, 4096, "    ForIn: %s", (const char*)pact_list_get(np_var_name, id));
                                printf("%s\n", strdup(_si_7));
                                pact_print_node((int64_t)(intptr_t)pact_list_get(np_iterable, id), (depth + 1));
                                pact_print_node((int64_t)(intptr_t)pact_list_get(np_body, id), (depth + 1));
                            } else {
                                if ((kind == pact_NodeKind_Assignment)) {
                                    printf("%s\n", "    Assignment");
                                    pact_print_node((int64_t)(intptr_t)pact_list_get(np_target, id), (depth + 1));
                                    pact_print_node((int64_t)(intptr_t)pact_list_get(np_value, id), (depth + 1));
                                } else if ((kind == pact_NodeKind_TypeDef)) {
                                    char _si_8[4096];
                                    snprintf(_si_8, 4096, "TypeDef: %s", name);
                                    printf("%s\n", strdup(_si_8));
                                } else {
                                    if ((kind == pact_NodeKind_MatchExpr)) {
                                        printf("%s\n", "    MatchExpr");
                                        pact_print_node((int64_t)(intptr_t)pact_list_get(np_scrutinee, id), (depth + 1));
                                    } else if ((kind == pact_NodeKind_InterpString)) {
                                        printf("%s\n", "      InterpString");
                                    } else {
                                        if ((kind == pact_NodeKind_BoolLit)) {
                                            char _si_9[4096];
                                            snprintf(_si_9, 4096, "      BoolLit: %lld", (long long)(int64_t)(intptr_t)pact_list_get(np_int_val, id));
                                            printf("%s\n", strdup(_si_9));
                                        } else if ((kind == pact_NodeKind_StructLit)) {
                                            char _si_10[4096];
                                            snprintf(_si_10, 4096, "      StructLit: %s", (const char*)pact_list_get(np_type_name, id));
                                            printf("%s\n", strdup(_si_10));
                                        } else {
                                            if ((kind == pact_NodeKind_FieldAccess)) {
                                                char _si_11[4096];
                                                snprintf(_si_11, 4096, "      FieldAccess: .%s", name);
                                                printf("%s\n", strdup(_si_11));
                                                pact_print_node((int64_t)(intptr_t)pact_list_get(np_obj, id), (depth + 1));
                                            } else if ((kind == pact_NodeKind_UnaryOp)) {
                                                char _si_12[4096];
                                                snprintf(_si_12, 4096, "      UnaryOp: %s", op);
                                                printf("%s\n", strdup(_si_12));
                                                pact_print_node((int64_t)(intptr_t)pact_list_get(np_left, id), (depth + 1));
                                            } else {
                                                char _si_13[4096];
                                                snprintf(_si_13, 4096, "      %s", pact_node_kind_name(kind));
                                                printf("%s\n", strdup(_si_13));
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}

int64_t pact_lpeek(const char* source, int64_t p) {
    int64_t _if_0;
    if ((p >= pact_str_len(source))) {
        _if_0 = 0;
    } else {
        _if_0 = pact_str_char_at(source, p);
    }
    return _if_0;
}

void pact_mini_lex(const char* source) {
    int64_t p = 0;
    int64_t line = 1;
    int64_t col = 1;
    int64_t last_kind = (-1);
    while ((p < pact_str_len(source))) {
        const int64_t ch = pact_lpeek(source, p);
        if (((ch == CH_SPACE) || (ch == CH_TAB))) {
            p = (p + 1);
            col = (col + 1);
            continue;
        }
        if (((ch == CH_SLASH) && (pact_lpeek(source, (p + 1)) == CH_SLASH))) {
            while (((p < pact_str_len(source)) && (pact_lpeek(source, p) != CH_NEWLINE))) {
                p = (p + 1);
            }
            continue;
        }
        if ((ch == CH_NEWLINE)) {
            if ((last_kind != pact_TokenKind_Newline)) {
                pact_list_push(tok_kinds, (void*)(intptr_t)pact_TokenKind_Newline);
                pact_list_push(tok_values, (void*)"");
                pact_list_push(tok_lines, (void*)(intptr_t)line);
                pact_list_push(tok_cols, (void*)(intptr_t)col);
                last_kind = pact_TokenKind_Newline;
            }
            p = (p + 1);
            line = (line + 1);
            col = 1;
            continue;
        }
        if ((ch == CH_DQUOTE)) {
            const int64_t t_line = line;
            const int64_t t_col = col;
            p = (p + 1);
            col = (col + 1);
            pact_list_push(tok_kinds, (void*)(intptr_t)pact_TokenKind_StringStart);
            pact_list_push(tok_values, (void*)"");
            pact_list_push(tok_lines, (void*)(intptr_t)t_line);
            pact_list_push(tok_cols, (void*)(intptr_t)t_col);
            last_kind = pact_TokenKind_StringStart;
            const char* buf = "";
            int64_t in_str = 1;
            while ((in_str && (p < pact_str_len(source)))) {
                const int64_t sc = pact_lpeek(source, p);
                if ((sc == CH_DQUOTE)) {
                    pact_list_push(tok_kinds, (void*)(intptr_t)pact_TokenKind_StringPart);
                    pact_list_push(tok_values, (void*)buf);
                    pact_list_push(tok_lines, (void*)(intptr_t)line);
                    pact_list_push(tok_cols, (void*)(intptr_t)col);
                    last_kind = pact_TokenKind_StringPart;
                    pact_list_push(tok_kinds, (void*)(intptr_t)pact_TokenKind_StringEnd);
                    pact_list_push(tok_values, (void*)"");
                    pact_list_push(tok_lines, (void*)(intptr_t)line);
                    pact_list_push(tok_cols, (void*)(intptr_t)col);
                    last_kind = pact_TokenKind_StringEnd;
                    p = (p + 1);
                    col = (col + 1);
                    in_str = 0;
                } else if ((sc == CH_LBRACE)) {
                    pact_list_push(tok_kinds, (void*)(intptr_t)pact_TokenKind_StringPart);
                    pact_list_push(tok_values, (void*)buf);
                    pact_list_push(tok_lines, (void*)(intptr_t)line);
                    pact_list_push(tok_cols, (void*)(intptr_t)col);
                    last_kind = pact_TokenKind_StringPart;
                    buf = "";
                    pact_list_push(tok_kinds, (void*)(intptr_t)pact_TokenKind_InterpStart);
                    pact_list_push(tok_values, (void*)"");
                    pact_list_push(tok_lines, (void*)(intptr_t)line);
                    pact_list_push(tok_cols, (void*)(intptr_t)col);
                    last_kind = pact_TokenKind_InterpStart;
                    p = (p + 1);
                    col = (col + 1);
                    int64_t depth = 1;
                    while (((depth > 0) && (p < pact_str_len(source)))) {
                        const int64_t ic = pact_lpeek(source, p);
                        if ((ic == CH_RBRACE)) {
                            depth = (depth - 1);
                            if ((depth == 0)) {
                                pact_list_push(tok_kinds, (void*)(intptr_t)pact_TokenKind_InterpEnd);
                                pact_list_push(tok_values, (void*)"");
                                pact_list_push(tok_lines, (void*)(intptr_t)line);
                                pact_list_push(tok_cols, (void*)(intptr_t)col);
                                last_kind = pact_TokenKind_InterpEnd;
                                p = (p + 1);
                                col = (col + 1);
                            } else {
                                pact_list_push(tok_kinds, (void*)(intptr_t)pact_TokenKind_RBrace);
                                pact_list_push(tok_values, (void*)"}");
                                pact_list_push(tok_lines, (void*)(intptr_t)line);
                                pact_list_push(tok_cols, (void*)(intptr_t)col);
                                last_kind = pact_TokenKind_RBrace;
                                p = (p + 1);
                                col = (col + 1);
                            }
                        } else if ((ic == CH_LBRACE)) {
                            depth = (depth + 1);
                            pact_list_push(tok_kinds, (void*)(intptr_t)pact_TokenKind_LBrace);
                            pact_list_push(tok_values, (void*)"{");
                            pact_list_push(tok_lines, (void*)(intptr_t)line);
                            pact_list_push(tok_cols, (void*)(intptr_t)col);
                            last_kind = pact_TokenKind_LBrace;
                            p = (p + 1);
                            col = (col + 1);
                        } else {
                            if (pact_is_alpha(ic)) {
                                const int64_t start = p;
                                while (((p < pact_str_len(source)) && pact_is_alnum(pact_lpeek(source, p)))) {
                                    p = (p + 1);
                                    col = (col + 1);
                                }
                                const char* word = pact_str_substr(source, start, (p - start));
                                const int64_t kind = pact_keyword_lookup(word);
                                pact_list_push(tok_kinds, (void*)(intptr_t)kind);
                                pact_list_push(tok_values, (void*)word);
                                pact_list_push(tok_lines, (void*)(intptr_t)line);
                                pact_list_push(tok_cols, (void*)(intptr_t)col);
                                last_kind = kind;
                            } else if (pact_is_digit(ic)) {
                                const int64_t start = p;
                                while (((p < pact_str_len(source)) && pact_is_digit(pact_lpeek(source, p)))) {
                                    p = (p + 1);
                                    col = (col + 1);
                                }
                                pact_list_push(tok_kinds, (void*)(intptr_t)pact_TokenKind_Int);
                                pact_list_push(tok_values, (void*)pact_str_substr(source, start, (p - start)));
                                pact_list_push(tok_lines, (void*)(intptr_t)line);
                                pact_list_push(tok_cols, (void*)(intptr_t)col);
                                last_kind = pact_TokenKind_Int;
                            } else {
                                if ((ic == CH_PLUS)) {
                                    pact_list_push(tok_kinds, (void*)(intptr_t)pact_TokenKind_Plus);
                                    pact_list_push(tok_values, (void*)"+");
                                    pact_list_push(tok_lines, (void*)(intptr_t)line);
                                    pact_list_push(tok_cols, (void*)(intptr_t)col);
                                    last_kind = pact_TokenKind_Plus;
                                    p = (p + 1);
                                    col = (col + 1);
                                } else if ((ic == CH_MINUS)) {
                                    pact_list_push(tok_kinds, (void*)(intptr_t)pact_TokenKind_Minus);
                                    pact_list_push(tok_values, (void*)"-");
                                    pact_list_push(tok_lines, (void*)(intptr_t)line);
                                    pact_list_push(tok_cols, (void*)(intptr_t)col);
                                    last_kind = pact_TokenKind_Minus;
                                    p = (p + 1);
                                    col = (col + 1);
                                } else {
                                    if ((ic == CH_STAR)) {
                                        pact_list_push(tok_kinds, (void*)(intptr_t)pact_TokenKind_Star);
                                        pact_list_push(tok_values, (void*)"*");
                                        pact_list_push(tok_lines, (void*)(intptr_t)line);
                                        pact_list_push(tok_cols, (void*)(intptr_t)col);
                                        last_kind = pact_TokenKind_Star;
                                        p = (p + 1);
                                        col = (col + 1);
                                    } else if ((ic == CH_DOT)) {
                                        pact_list_push(tok_kinds, (void*)(intptr_t)pact_TokenKind_Dot);
                                        pact_list_push(tok_values, (void*)".");
                                        pact_list_push(tok_lines, (void*)(intptr_t)line);
                                        pact_list_push(tok_cols, (void*)(intptr_t)col);
                                        last_kind = pact_TokenKind_Dot;
                                        p = (p + 1);
                                        col = (col + 1);
                                    } else {
                                        if ((ic == CH_LPAREN)) {
                                            pact_list_push(tok_kinds, (void*)(intptr_t)pact_TokenKind_LParen);
                                            pact_list_push(tok_values, (void*)"(");
                                            pact_list_push(tok_lines, (void*)(intptr_t)line);
                                            pact_list_push(tok_cols, (void*)(intptr_t)col);
                                            last_kind = pact_TokenKind_LParen;
                                            p = (p + 1);
                                            col = (col + 1);
                                        } else if ((ic == CH_RPAREN)) {
                                            pact_list_push(tok_kinds, (void*)(intptr_t)pact_TokenKind_RParen);
                                            pact_list_push(tok_values, (void*)")");
                                            pact_list_push(tok_lines, (void*)(intptr_t)line);
                                            pact_list_push(tok_cols, (void*)(intptr_t)col);
                                            last_kind = pact_TokenKind_RParen;
                                            p = (p + 1);
                                            col = (col + 1);
                                        } else {
                                            if ((ic == CH_COMMA)) {
                                                pact_list_push(tok_kinds, (void*)(intptr_t)pact_TokenKind_Comma);
                                                pact_list_push(tok_values, (void*)",");
                                                pact_list_push(tok_lines, (void*)(intptr_t)line);
                                                pact_list_push(tok_cols, (void*)(intptr_t)col);
                                                last_kind = pact_TokenKind_Comma;
                                                p = (p + 1);
                                                col = (col + 1);
                                            } else if (((ic == CH_SPACE) || (ic == CH_TAB))) {
                                                p = (p + 1);
                                                col = (col + 1);
                                            } else {
                                                p = (p + 1);
                                                col = (col + 1);
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                } else {
                    if ((sc == CH_BACKSLASH)) {
                        p = (p + 2);
                        col = (col + 2);
                        buf = pact_str_concat(buf, "?");
                    } else {
                        buf = pact_str_concat(buf, pact_str_substr(source, p, 1));
                        p = (p + 1);
                        col = (col + 1);
                    }
                }
            }
            continue;
        }
        if (pact_is_alpha(ch)) {
            const int64_t t_line = line;
            const int64_t t_col = col;
            const int64_t start = p;
            while (((p < pact_str_len(source)) && pact_is_alnum(pact_lpeek(source, p)))) {
                p = (p + 1);
                col = (col + 1);
            }
            const char* word = pact_str_substr(source, start, (p - start));
            const int64_t kind = pact_keyword_lookup(word);
            pact_list_push(tok_kinds, (void*)(intptr_t)kind);
            pact_list_push(tok_values, (void*)word);
            pact_list_push(tok_lines, (void*)(intptr_t)t_line);
            pact_list_push(tok_cols, (void*)(intptr_t)t_col);
            last_kind = kind;
            continue;
        }
        if (pact_is_digit(ch)) {
            const int64_t t_line = line;
            const int64_t t_col = col;
            const int64_t start = p;
            while (((p < pact_str_len(source)) && pact_is_digit(pact_lpeek(source, p)))) {
                p = (p + 1);
                col = (col + 1);
            }
            pact_list_push(tok_kinds, (void*)(intptr_t)pact_TokenKind_Int);
            pact_list_push(tok_values, (void*)pact_str_substr(source, start, (p - start)));
            pact_list_push(tok_lines, (void*)(intptr_t)t_line);
            pact_list_push(tok_cols, (void*)(intptr_t)t_col);
            last_kind = pact_TokenKind_Int;
            continue;
        }
        if (((ch == CH_MINUS) && (pact_lpeek(source, (p + 1)) == CH_GREATER))) {
            pact_list_push(tok_kinds, (void*)(intptr_t)pact_TokenKind_Arrow);
            pact_list_push(tok_values, (void*)"->");
            pact_list_push(tok_lines, (void*)(intptr_t)line);
            pact_list_push(tok_cols, (void*)(intptr_t)col);
            last_kind = pact_TokenKind_Arrow;
            p = (p + 2);
            col = (col + 2);
            continue;
        }
        if (((ch == CH_EQUALS) && (pact_lpeek(source, (p + 1)) == CH_GREATER))) {
            pact_list_push(tok_kinds, (void*)(intptr_t)pact_TokenKind_FatArrow);
            pact_list_push(tok_values, (void*)"=>");
            pact_list_push(tok_lines, (void*)(intptr_t)line);
            pact_list_push(tok_cols, (void*)(intptr_t)col);
            last_kind = pact_TokenKind_FatArrow;
            p = (p + 2);
            col = (col + 2);
            continue;
        }
        if (((ch == CH_EQUALS) && (pact_lpeek(source, (p + 1)) == CH_EQUALS))) {
            pact_list_push(tok_kinds, (void*)(intptr_t)pact_TokenKind_EqEq);
            pact_list_push(tok_values, (void*)"==");
            pact_list_push(tok_lines, (void*)(intptr_t)line);
            pact_list_push(tok_cols, (void*)(intptr_t)col);
            last_kind = pact_TokenKind_EqEq;
            p = (p + 2);
            col = (col + 2);
            continue;
        }
        if (((ch == CH_BANG) && (pact_lpeek(source, (p + 1)) == CH_EQUALS))) {
            pact_list_push(tok_kinds, (void*)(intptr_t)pact_TokenKind_NotEq);
            pact_list_push(tok_values, (void*)"!=");
            pact_list_push(tok_lines, (void*)(intptr_t)line);
            pact_list_push(tok_cols, (void*)(intptr_t)col);
            last_kind = pact_TokenKind_NotEq;
            p = (p + 2);
            col = (col + 2);
            continue;
        }
        if (((ch == CH_LESS) && (pact_lpeek(source, (p + 1)) == CH_EQUALS))) {
            pact_list_push(tok_kinds, (void*)(intptr_t)pact_TokenKind_LessEq);
            pact_list_push(tok_values, (void*)"<=");
            pact_list_push(tok_lines, (void*)(intptr_t)line);
            pact_list_push(tok_cols, (void*)(intptr_t)col);
            last_kind = pact_TokenKind_LessEq;
            p = (p + 2);
            col = (col + 2);
            continue;
        }
        if (((ch == CH_GREATER) && (pact_lpeek(source, (p + 1)) == CH_EQUALS))) {
            pact_list_push(tok_kinds, (void*)(intptr_t)pact_TokenKind_GreaterEq);
            pact_list_push(tok_values, (void*)">=");
            pact_list_push(tok_lines, (void*)(intptr_t)line);
            pact_list_push(tok_cols, (void*)(intptr_t)col);
            last_kind = pact_TokenKind_GreaterEq;
            p = (p + 2);
            col = (col + 2);
            continue;
        }
        if (((ch == CH_AMP) && (pact_lpeek(source, (p + 1)) == CH_AMP))) {
            pact_list_push(tok_kinds, (void*)(intptr_t)pact_TokenKind_And);
            pact_list_push(tok_values, (void*)"&&");
            pact_list_push(tok_lines, (void*)(intptr_t)line);
            pact_list_push(tok_cols, (void*)(intptr_t)col);
            last_kind = pact_TokenKind_And;
            p = (p + 2);
            col = (col + 2);
            continue;
        }
        if (((ch == CH_PIPE) && (pact_lpeek(source, (p + 1)) == CH_PIPE))) {
            pact_list_push(tok_kinds, (void*)(intptr_t)pact_TokenKind_Or);
            pact_list_push(tok_values, (void*)"||");
            pact_list_push(tok_lines, (void*)(intptr_t)line);
            pact_list_push(tok_cols, (void*)(intptr_t)col);
            last_kind = pact_TokenKind_Or;
            p = (p + 2);
            col = (col + 2);
            continue;
        }
        if (((ch == CH_PIPE) && (pact_lpeek(source, (p + 1)) == CH_GREATER))) {
            pact_list_push(tok_kinds, (void*)(intptr_t)pact_TokenKind_PipeArrow);
            pact_list_push(tok_values, (void*)"|>");
            pact_list_push(tok_lines, (void*)(intptr_t)line);
            pact_list_push(tok_cols, (void*)(intptr_t)col);
            last_kind = pact_TokenKind_PipeArrow;
            p = (p + 2);
            col = (col + 2);
            continue;
        }
        if (((ch == CH_PLUS) && (pact_lpeek(source, (p + 1)) == CH_EQUALS))) {
            pact_list_push(tok_kinds, (void*)(intptr_t)pact_TokenKind_PlusEq);
            pact_list_push(tok_values, (void*)"+=");
            pact_list_push(tok_lines, (void*)(intptr_t)line);
            pact_list_push(tok_cols, (void*)(intptr_t)col);
            last_kind = pact_TokenKind_PlusEq;
            p = (p + 2);
            col = (col + 2);
            continue;
        }
        if (((ch == CH_MINUS) && (pact_lpeek(source, (p + 1)) == CH_EQUALS))) {
            pact_list_push(tok_kinds, (void*)(intptr_t)pact_TokenKind_MinusEq);
            pact_list_push(tok_values, (void*)"-=");
            pact_list_push(tok_lines, (void*)(intptr_t)line);
            pact_list_push(tok_cols, (void*)(intptr_t)col);
            last_kind = pact_TokenKind_MinusEq;
            p = (p + 2);
            col = (col + 2);
            continue;
        }
        if (((ch == CH_STAR) && (pact_lpeek(source, (p + 1)) == CH_EQUALS))) {
            pact_list_push(tok_kinds, (void*)(intptr_t)pact_TokenKind_StarEq);
            pact_list_push(tok_values, (void*)"*=");
            pact_list_push(tok_lines, (void*)(intptr_t)line);
            pact_list_push(tok_cols, (void*)(intptr_t)col);
            last_kind = pact_TokenKind_StarEq;
            p = (p + 2);
            col = (col + 2);
            continue;
        }
        if (((ch == CH_DOT) && (pact_lpeek(source, (p + 1)) == CH_DOT))) {
            if ((pact_lpeek(source, (p + 2)) == CH_EQUALS)) {
                pact_list_push(tok_kinds, (void*)(intptr_t)pact_TokenKind_DotDoteq);
                pact_list_push(tok_values, (void*)"..=");
                pact_list_push(tok_lines, (void*)(intptr_t)line);
                pact_list_push(tok_cols, (void*)(intptr_t)col);
                last_kind = pact_TokenKind_DotDoteq;
                p = (p + 3);
                col = (col + 3);
            } else {
                pact_list_push(tok_kinds, (void*)(intptr_t)pact_TokenKind_DotDot);
                pact_list_push(tok_values, (void*)"..");
                pact_list_push(tok_lines, (void*)(intptr_t)line);
                pact_list_push(tok_cols, (void*)(intptr_t)col);
                last_kind = pact_TokenKind_DotDot;
                p = (p + 2);
                col = (col + 2);
            }
            continue;
        }
        const int64_t t_line = line;
        const int64_t t_col = col;
        if ((ch == CH_LPAREN)) {
            pact_list_push(tok_kinds, (void*)(intptr_t)pact_TokenKind_LParen);
            pact_list_push(tok_values, (void*)"(");
        } else if ((ch == CH_RPAREN)) {
            pact_list_push(tok_kinds, (void*)(intptr_t)pact_TokenKind_RParen);
            pact_list_push(tok_values, (void*)")");
        } else {
            if ((ch == CH_LBRACE)) {
                pact_list_push(tok_kinds, (void*)(intptr_t)pact_TokenKind_LBrace);
                pact_list_push(tok_values, (void*)"{");
            } else if ((ch == CH_RBRACE)) {
                pact_list_push(tok_kinds, (void*)(intptr_t)pact_TokenKind_RBrace);
                pact_list_push(tok_values, (void*)"\\");
            } else {
                if ((ch == CH_LBRACKET)) {
                    pact_list_push(tok_kinds, (void*)(intptr_t)pact_TokenKind_LBracket);
                    pact_list_push(tok_values, (void*)"[");
                } else if ((ch == CH_RBRACKET)) {
                    pact_list_push(tok_kinds, (void*)(intptr_t)pact_TokenKind_RBracket);
                    pact_list_push(tok_values, (void*)"]");
                } else {
                    if ((ch == CH_COLON)) {
                        pact_list_push(tok_kinds, (void*)(intptr_t)pact_TokenKind_Colon);
                        pact_list_push(tok_values, (void*)":");
                    } else if ((ch == CH_COMMA)) {
                        pact_list_push(tok_kinds, (void*)(intptr_t)pact_TokenKind_Comma);
                        pact_list_push(tok_values, (void*)",");
                    } else {
                        if ((ch == CH_DOT)) {
                            pact_list_push(tok_kinds, (void*)(intptr_t)pact_TokenKind_Dot);
                            pact_list_push(tok_values, (void*)".");
                        } else if ((ch == CH_PLUS)) {
                            pact_list_push(tok_kinds, (void*)(intptr_t)pact_TokenKind_Plus);
                            pact_list_push(tok_values, (void*)"+");
                        } else {
                            if ((ch == CH_MINUS)) {
                                pact_list_push(tok_kinds, (void*)(intptr_t)pact_TokenKind_Minus);
                                pact_list_push(tok_values, (void*)"-");
                            } else if ((ch == CH_STAR)) {
                                pact_list_push(tok_kinds, (void*)(intptr_t)pact_TokenKind_Star);
                                pact_list_push(tok_values, (void*)"*");
                            } else {
                                if ((ch == CH_SLASH)) {
                                    pact_list_push(tok_kinds, (void*)(intptr_t)pact_TokenKind_Slash);
                                    pact_list_push(tok_values, (void*)"/");
                                } else if ((ch == CH_PERCENT)) {
                                    pact_list_push(tok_kinds, (void*)(intptr_t)pact_TokenKind_Percent);
                                    pact_list_push(tok_values, (void*)"%");
                                } else {
                                    if ((ch == CH_EQUALS)) {
                                        pact_list_push(tok_kinds, (void*)(intptr_t)pact_TokenKind_Equals);
                                        pact_list_push(tok_values, (void*)"=");
                                    } else if ((ch == CH_LESS)) {
                                        pact_list_push(tok_kinds, (void*)(intptr_t)pact_TokenKind_Less);
                                        pact_list_push(tok_values, (void*)"<");
                                    } else {
                                        if ((ch == CH_GREATER)) {
                                            pact_list_push(tok_kinds, (void*)(intptr_t)pact_TokenKind_Greater);
                                            pact_list_push(tok_values, (void*)">");
                                        } else if ((ch == CH_BANG)) {
                                            pact_list_push(tok_kinds, (void*)(intptr_t)pact_TokenKind_Bang);
                                            pact_list_push(tok_values, (void*)"!");
                                        } else {
                                            if ((ch == CH_QUESTION)) {
                                                pact_list_push(tok_kinds, (void*)(intptr_t)pact_TokenKind_Question);
                                                pact_list_push(tok_values, (void*)"?");
                                            } else if ((ch == CH_PIPE)) {
                                                pact_list_push(tok_kinds, (void*)(intptr_t)pact_TokenKind_Pipe);
                                                pact_list_push(tok_values, (void*)"|");
                                            } else {
                                                if ((ch == CH_AT)) {
                                                    pact_list_push(tok_kinds, (void*)(intptr_t)pact_TokenKind_At);
                                                    pact_list_push(tok_values, (void*)"@");
                                                } else {
                                                    p = (p + 1);
                                                    col = (col + 1);
                                                    continue;
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
        pact_list_push(tok_lines, (void*)(intptr_t)t_line);
        pact_list_push(tok_cols, (void*)(intptr_t)t_col);
        last_kind = (int64_t)(intptr_t)pact_list_get(tok_kinds, (pact_list_len(tok_kinds) - 1));
        p = (p + 1);
        col = (col + 1);
    }
    pact_list_push(tok_kinds, (void*)(intptr_t)pact_TokenKind_EOF);
    pact_list_push(tok_values, (void*)"");
    pact_list_push(tok_lines, (void*)(intptr_t)line);
    pact_list_push(tok_cols, (void*)(intptr_t)col);
}

void pact_push_scope(void) {
    pact_list_push(scope_frame_starts, (void*)(intptr_t)pact_list_len(scope_names));
}

void pact_pop_scope(void) {
    const int64_t start = (int64_t)(intptr_t)pact_list_get(scope_frame_starts, (pact_list_len(scope_frame_starts) - 1));
    pact_list_pop(scope_frame_starts);
    while ((pact_list_len(scope_names) > start)) {
        pact_list_pop(scope_names);
        pact_list_pop(scope_types);
        pact_list_pop(scope_muts);
    }
}

void pact_set_var(const char* name, int64_t ctype, int64_t is_mut) {
    pact_list_push(scope_names, (void*)name);
    pact_list_push(scope_types, (void*)(intptr_t)ctype);
    pact_list_push(scope_muts, (void*)(intptr_t)is_mut);
}

int64_t pact_get_var_type(const char* name) {
    int64_t i = (pact_list_len(scope_names) - 1);
    while ((i >= 0)) {
        if (pact_str_eq((const char*)pact_list_get(scope_names, i), name)) {
            return (int64_t)(intptr_t)pact_list_get(scope_types, i);
        }
        i = (i - 1);
    }
    return CT_INT;
}

void pact_reg_fn(const char* name, int64_t ret) {
    pact_list_push(fn_reg_names, (void*)name);
    pact_list_push(fn_reg_ret, (void*)(intptr_t)ret);
}

int64_t pact_get_fn_ret(const char* name) {
    int64_t i = 0;
    while ((i < pact_list_len(fn_reg_names))) {
        if (pact_str_eq((const char*)pact_list_get(fn_reg_names, i), name)) {
            return (int64_t)(intptr_t)pact_list_get(fn_reg_ret, i);
        }
        i = (i + 1);
    }
    return CT_VOID;
}

void pact_set_list_elem_type(const char* name, int64_t elem_type) {
    pact_list_push(var_list_elem_names, (void*)name);
    pact_list_push(var_list_elem_types, (void*)(intptr_t)elem_type);
}

int64_t pact_get_list_elem_type(const char* name) {
    int64_t i = 0;
    while ((i < pact_list_len(var_list_elem_names))) {
        if (pact_str_eq((const char*)pact_list_get(var_list_elem_names, i), name)) {
            return (int64_t)(intptr_t)pact_list_get(var_list_elem_types, i);
        }
        i = (i + 1);
    }
    return CT_INT;
}

int64_t pact_is_struct_type(const char* name) {
    int64_t i = 0;
    while ((i < pact_list_len(struct_reg_names))) {
        if (pact_str_eq((const char*)pact_list_get(struct_reg_names, i), name)) {
            return 1;
        }
        i = (i + 1);
    }
    return 0;
}

int64_t pact_is_enum_type(const char* name) {
    int64_t i = 0;
    while ((i < pact_list_len(enum_reg_names))) {
        if (pact_str_eq((const char*)pact_list_get(enum_reg_names, i), name)) {
            return 1;
        }
        i = (i + 1);
    }
    return 0;
}

const char* pact_resolve_variant(const char* name) {
    int64_t i = 0;
    while ((i < pact_list_len(enum_reg_variant_names))) {
        if (pact_str_eq((const char*)pact_list_get(enum_reg_variant_names, i), name)) {
            return (const char*)pact_list_get(enum_reg_names, (int64_t)(intptr_t)pact_list_get(enum_reg_variant_enum_idx, i));
        }
        i = (i + 1);
    }
    return "";
}

const char* pact_get_var_enum(const char* name) {
    int64_t i = 0;
    while ((i < pact_list_len(var_enum_names))) {
        if (pact_str_eq((const char*)pact_list_get(var_enum_names, i), name)) {
            return (const char*)pact_list_get(var_enum_types, i);
        }
        i = (i + 1);
    }
    return "";
}

const char* pact_get_fn_enum_ret(const char* name) {
    int64_t i = 0;
    while ((i < pact_list_len(fn_enum_ret_names))) {
        if (pact_str_eq((const char*)pact_list_get(fn_enum_ret_names, i), name)) {
            return (const char*)pact_list_get(fn_enum_ret_types, i);
        }
        i = (i + 1);
    }
    return "";
}

void pact_set_var_struct(const char* name, const char* type_name) {
    pact_list_push(var_struct_names, (void*)name);
    pact_list_push(var_struct_types, (void*)type_name);
}

const char* pact_get_var_struct(const char* name) {
    int64_t i = 0;
    while ((i < pact_list_len(var_struct_names))) {
        if (pact_str_eq((const char*)pact_list_get(var_struct_names, i), name)) {
            return (const char*)pact_list_get(var_struct_types, i);
        }
        i = (i + 1);
    }
    return "";
}

int64_t pact_is_trait_type(const char* name) {
    int64_t i = 0;
    while ((i < pact_list_len(trait_reg_names))) {
        if (pact_str_eq((const char*)pact_list_get(trait_reg_names, i), name)) {
            return 1;
        }
        i = (i + 1);
    }
    return 0;
}

int64_t pact_lookup_impl_method(const char* type_name, const char* method) {
    int64_t i = 0;
    while ((i < pact_list_len(impl_reg_type))) {
        if (pact_str_eq((const char*)pact_list_get(impl_reg_type, i), type_name)) {
            const int64_t methods_sl = (int64_t)(intptr_t)pact_list_get(impl_reg_methods_sl, i);
            int64_t j = 0;
            while ((j < pact_sublist_length(methods_sl))) {
                const int64_t m = pact_sublist_get(methods_sl, j);
                if (pact_str_eq((const char*)pact_list_get(np_name, m), method)) {
                    return 1;
                }
                j = (j + 1);
            }
        }
        i = (i + 1);
    }
    return 0;
}

int64_t pact_lookup_impl_type_for_trait(const char* trait_name, const char* type_name) {
    int64_t i = 0;
    while ((i < pact_list_len(impl_reg_trait))) {
        if ((pact_str_eq((const char*)pact_list_get(impl_reg_trait, i), trait_name) && pact_str_eq((const char*)pact_list_get(impl_reg_type, i), type_name))) {
            return 1;
        }
        i = (i + 1);
    }
    return 0;
}

int64_t pact_get_impl_method_ret(const char* type_name, const char* method) {
    int64_t i = 0;
    while ((i < pact_list_len(impl_reg_type))) {
        if (pact_str_eq((const char*)pact_list_get(impl_reg_type, i), type_name)) {
            const int64_t methods_sl = (int64_t)(intptr_t)pact_list_get(impl_reg_methods_sl, i);
            int64_t j = 0;
            while ((j < pact_sublist_length(methods_sl))) {
                const int64_t m = pact_sublist_get(methods_sl, j);
                if (pact_str_eq((const char*)pact_list_get(np_name, m), method)) {
                    const char* ret_str = (const char*)pact_list_get(np_return_type, m);
                    return pact_type_from_name(ret_str);
                }
                j = (j + 1);
            }
        }
        i = (i + 1);
    }
    return CT_VOID;
}

int64_t pact_is_emitted_let(const char* name) {
    int64_t i = 0;
    while ((i < pact_list_len(emitted_let_names))) {
        if (pact_str_eq((const char*)pact_list_get(emitted_let_names, i), name)) {
            return 1;
        }
        i = (i + 1);
    }
    return 0;
}

int64_t pact_is_emitted_fn(const char* name) {
    int64_t i = 0;
    while ((i < pact_list_len(emitted_fn_names))) {
        if (pact_str_eq((const char*)pact_list_get(emitted_fn_names, i), name)) {
            return 1;
        }
        i = (i + 1);
    }
    return 0;
}

const char* pact_c_type_str(int64_t ct) {
    const char* _if_0;
    if ((ct == CT_INT)) {
        _if_0 = "int64_t";
    } else {
        const char* _if_1;
        if ((ct == CT_FLOAT)) {
            _if_1 = "double";
        } else {
            const char* _if_2;
            if ((ct == CT_BOOL)) {
                _if_2 = "int";
            } else {
                const char* _if_3;
                if ((ct == CT_STRING)) {
                    _if_3 = "const char*";
                } else {
                    const char* _if_4;
                    if ((ct == CT_LIST)) {
                        _if_4 = "pact_list*";
                    } else {
                        _if_4 = "void";
                    }
                    _if_3 = _if_4;
                }
                _if_2 = _if_3;
            }
            _if_1 = _if_2;
        }
        _if_0 = _if_1;
    }
    return _if_0;
}

int64_t pact_type_from_name(const char* name) {
    int64_t _if_0;
    if (pact_str_eq(name, "Int")) {
        _if_0 = CT_INT;
    } else {
        int64_t _if_1;
        if (pact_str_eq(name, "Str")) {
            _if_1 = CT_STRING;
        } else {
            int64_t _if_2;
            if (pact_str_eq(name, "Float")) {
                _if_2 = CT_FLOAT;
            } else {
                int64_t _if_3;
                if (pact_str_eq(name, "Bool")) {
                    _if_3 = CT_BOOL;
                } else {
                    int64_t _if_4;
                    if (pact_str_eq(name, "List")) {
                        _if_4 = CT_LIST;
                    } else {
                        _if_4 = CT_VOID;
                    }
                    _if_3 = _if_4;
                }
                _if_2 = _if_3;
            }
            _if_1 = _if_2;
        }
        _if_0 = _if_1;
    }
    return _if_0;
}

const char* pact_fresh_temp(const char* prefix) {
    const int64_t n = cg_temp_counter;
    cg_temp_counter = (cg_temp_counter + 1);
    char _si_0[4096];
    snprintf(_si_0, 4096, "%s%lld", prefix, (long long)n);
    return strdup(_si_0);
}

void pact_emit_line(const char* line) {
    if (pact_str_eq(line, "")) {
        pact_list_push(cg_lines, (void*)"");
    } else {
        const char* pad = "";
        int64_t i = 0;
        while ((i < cg_indent)) {
            pad = pact_str_concat(pad, "    ");
            i = (i + 1);
        }
        pact_list_push(cg_lines, (void*)pact_str_concat(pad, line));
    }
}

const char* pact_join_lines(void) {
    const char* result = "";
    int64_t i = 0;
    while ((i < pact_list_len(cg_lines))) {
        if ((i > 0)) {
            result = pact_str_concat(result, "\n");
        }
        result = pact_str_concat(result, (const char*)pact_list_get(cg_lines, i));
        i = (i + 1);
    }
    return result;
}

void pact_emit_expr(int64_t node) {
    const int64_t kind = (int64_t)(intptr_t)pact_list_get(np_kind, node);
    if ((kind == pact_NodeKind_IntLit)) {
        const char* s = (const char*)pact_list_get(np_str_val, node);
        if (pact_str_eq(s, "")) {
            char _si_0[4096];
            snprintf(_si_0, 4096, "%lld", (long long)(int64_t)(intptr_t)pact_list_get(np_int_val, node));
            expr_result_str = strdup(_si_0);
        } else {
            expr_result_str = s;
        }
        expr_result_type = CT_INT;
        return;
    }
    if ((kind == pact_NodeKind_FloatLit)) {
        expr_result_str = (const char*)pact_list_get(np_str_val, node);
        expr_result_type = CT_FLOAT;
        return;
    }
    if ((kind == pact_NodeKind_BoolLit)) {
        if (((int64_t)(intptr_t)pact_list_get(np_int_val, node) != 0)) {
            expr_result_str = "1";
        } else {
            expr_result_str = "0";
        }
        expr_result_type = CT_BOOL;
        return;
    }
    if ((kind == pact_NodeKind_Ident)) {
        const char* name = (const char*)pact_list_get(np_name, node);
        const char* variant_enum = pact_resolve_variant(name);
        if ((!pact_str_eq(variant_enum, ""))) {
            char _si_1[4096];
            snprintf(_si_1, 4096, "pact_%s_%s", variant_enum, name);
            expr_result_str = strdup(_si_1);
            expr_result_type = CT_INT;
            return;
        }
        expr_result_str = name;
        expr_result_type = pact_get_var_type(name);
        return;
    }
    if ((kind == pact_NodeKind_BinOp)) {
        pact_emit_binop(node);
        return;
    }
    if ((kind == pact_NodeKind_UnaryOp)) {
        pact_emit_unaryop(node);
        return;
    }
    if ((kind == pact_NodeKind_Call)) {
        pact_emit_call(node);
        return;
    }
    if ((kind == pact_NodeKind_MethodCall)) {
        pact_emit_method_call(node);
        return;
    }
    if ((kind == pact_NodeKind_InterpString)) {
        pact_emit_interp_string(node);
        return;
    }
    if ((kind == pact_NodeKind_IfExpr)) {
        pact_emit_if_expr(node);
        return;
    }
    if ((kind == pact_NodeKind_FieldAccess)) {
        const int64_t fa_obj = (int64_t)(intptr_t)pact_list_get(np_obj, node);
        const char* fa_field = (const char*)pact_list_get(np_name, node);
        if (((int64_t)(intptr_t)pact_list_get(np_kind, fa_obj) == pact_NodeKind_Ident)) {
            const char* obj_name = (const char*)pact_list_get(np_name, fa_obj);
            if ((pact_is_enum_type(obj_name) != 0)) {
                char _si_2[4096];
                snprintf(_si_2, 4096, "pact_%s_%s", obj_name, fa_field);
                expr_result_str = strdup(_si_2);
                expr_result_type = CT_INT;
                return;
            }
        }
        pact_emit_expr(fa_obj);
        const char* obj_str = expr_result_str;
        char _si_3[4096];
        snprintf(_si_3, 4096, "%s.%s", obj_str, fa_field);
        expr_result_str = strdup(_si_3);
        expr_result_type = CT_VOID;
        return;
    }
    if ((kind == pact_NodeKind_IndexExpr)) {
        pact_emit_expr((int64_t)(intptr_t)pact_list_get(np_obj, node));
        const char* obj_str = expr_result_str;
        const int64_t obj_type = expr_result_type;
        pact_emit_expr((int64_t)(intptr_t)pact_list_get(np_index, node));
        const char* idx_str = expr_result_str;
        if ((obj_type == CT_STRING)) {
            char _si_4[4096];
            snprintf(_si_4, 4096, "pact_str_char_at(%s, %s)", obj_str, idx_str);
            expr_result_str = strdup(_si_4);
            expr_result_type = CT_INT;
        } else {
            char _si_5[4096];
            snprintf(_si_5, 4096, "%s[%s]", obj_str, idx_str);
            expr_result_str = strdup(_si_5);
            expr_result_type = CT_INT;
        }
        return;
    }
    if ((kind == pact_NodeKind_ListLit)) {
        pact_emit_list_lit(node);
        return;
    }
    if ((kind == pact_NodeKind_RangeLit)) {
        expr_result_str = "0";
        expr_result_type = CT_VOID;
        return;
    }
    if ((kind == pact_NodeKind_MatchExpr)) {
        pact_emit_match_expr(node);
        return;
    }
    if ((kind == pact_NodeKind_Block)) {
        pact_emit_block_expr(node);
        return;
    }
    if ((kind == pact_NodeKind_Return)) {
        if (((int64_t)(intptr_t)pact_list_get(np_value, node) != (-1))) {
            pact_emit_expr((int64_t)(intptr_t)pact_list_get(np_value, node));
            const char* val_str = expr_result_str;
            char _si_6[4096];
            snprintf(_si_6, 4096, "return %s;", val_str);
            pact_emit_line(strdup(_si_6));
        } else {
            pact_emit_line("return;");
        }
        expr_result_str = "0";
        expr_result_type = CT_VOID;
        return;
    }
    if ((kind == pact_NodeKind_StructLit)) {
        pact_emit_struct_lit(node);
        return;
    }
    expr_result_str = "0";
    expr_result_type = CT_VOID;
}

void pact_emit_binop(int64_t node) {
    pact_emit_expr((int64_t)(intptr_t)pact_list_get(np_left, node));
    const char* left_str = expr_result_str;
    const int64_t left_type = expr_result_type;
    pact_emit_expr((int64_t)(intptr_t)pact_list_get(np_right, node));
    const char* right_str = expr_result_str;
    const int64_t right_type = expr_result_type;
    const char* op = (const char*)pact_list_get(np_op, node);
    if (((pact_str_eq(op, "==") && (left_type == CT_STRING)) && (right_type == CT_STRING))) {
        char _si_0[4096];
        snprintf(_si_0, 4096, "pact_str_eq(%s, %s)", left_str, right_str);
        expr_result_str = strdup(_si_0);
        expr_result_type = CT_BOOL;
        return;
    }
    if (((pact_str_eq(op, "!=") && (left_type == CT_STRING)) && (right_type == CT_STRING))) {
        char _si_1[4096];
        snprintf(_si_1, 4096, "(!pact_str_eq(%s, %s))", left_str, right_str);
        expr_result_str = strdup(_si_1);
        expr_result_type = CT_BOOL;
        return;
    }
    if ((pact_str_eq(op, "+") && ((left_type == CT_STRING) || (right_type == CT_STRING)))) {
        char _si_2[4096];
        snprintf(_si_2, 4096, "pact_str_concat(%s, %s)", left_str, right_str);
        expr_result_str = strdup(_si_2);
        expr_result_type = CT_STRING;
        return;
    }
    char _si_3[4096];
    snprintf(_si_3, 4096, "(%s %s %s)", left_str, op, right_str);
    expr_result_str = strdup(_si_3);
    if ((((((((pact_str_eq(op, "==") || pact_str_eq(op, "!=")) || pact_str_eq(op, "<")) || pact_str_eq(op, ">")) || pact_str_eq(op, "<=")) || pact_str_eq(op, ">=")) || pact_str_eq(op, "&&")) || pact_str_eq(op, "||"))) {
        expr_result_type = CT_BOOL;
    } else {
        expr_result_type = left_type;
    }
}

void pact_emit_unaryop(int64_t node) {
    pact_emit_expr((int64_t)(intptr_t)pact_list_get(np_left, node));
    const char* operand_str = expr_result_str;
    const int64_t operand_type = expr_result_type;
    const char* op = (const char*)pact_list_get(np_op, node);
    if (pact_str_eq(op, "-")) {
        char _si_0[4096];
        snprintf(_si_0, 4096, "(-%s)", operand_str);
        expr_result_str = strdup(_si_0);
        expr_result_type = operand_type;
    } else if (pact_str_eq(op, "!")) {
        char _si_1[4096];
        snprintf(_si_1, 4096, "(!%s)", operand_str);
        expr_result_str = strdup(_si_1);
        expr_result_type = CT_BOOL;
    } else {
        char _si_2[4096];
        snprintf(_si_2, 4096, "(%s%s)", op, operand_str);
        expr_result_str = strdup(_si_2);
        expr_result_type = operand_type;
    }
}

void pact_emit_call(int64_t node) {
    const int64_t func_node = (int64_t)(intptr_t)pact_list_get(np_left, node);
    const int64_t func_kind = (int64_t)(intptr_t)pact_list_get(np_kind, func_node);
    if ((func_kind == pact_NodeKind_Ident)) {
        const char* fn_name = (const char*)pact_list_get(np_name, func_node);
        const int64_t args_sl = (int64_t)(intptr_t)pact_list_get(np_args, node);
        const char* args_str = "";
        if ((args_sl != (-1))) {
            int64_t i = 0;
            while ((i < pact_sublist_length(args_sl))) {
                if ((i > 0)) {
                    args_str = pact_str_concat(args_str, ", ");
                }
                pact_emit_expr(pact_sublist_get(args_sl, i));
                args_str = pact_str_concat(args_str, expr_result_str);
                i = (i + 1);
            }
        }
        char _si_0[4096];
        snprintf(_si_0, 4096, "pact_%s(%s)", fn_name, args_str);
        expr_result_str = strdup(_si_0);
        expr_result_type = pact_get_fn_ret(fn_name);
        return;
    }
    if ((func_kind == pact_NodeKind_FieldAccess)) {
        const int64_t trait_obj = (int64_t)(intptr_t)pact_list_get(np_obj, func_node);
        if (((int64_t)(intptr_t)pact_list_get(np_kind, trait_obj) == pact_NodeKind_Ident)) {
            const char* trait_name = (const char*)pact_list_get(np_name, trait_obj);
            if ((pact_is_trait_type(trait_name) != 0)) {
                const char* method = (const char*)pact_list_get(np_name, func_node);
                const int64_t args_sl = (int64_t)(intptr_t)pact_list_get(np_args, node);
                if (((args_sl != (-1)) && (pact_sublist_length(args_sl) > 0))) {
                    pact_emit_expr(pact_sublist_get(args_sl, 0));
                    const char* first_str = expr_result_str;
                    const char* type_name = pact_get_var_struct(first_str);
                    if ((!pact_str_eq(type_name, ""))) {
                        char _si_1[4096];
                        snprintf(_si_1, 4096, "%s_%s", type_name, method);
                        const char* mangled = strdup(_si_1);
                        const char* args_str = first_str;
                        int64_t i = 1;
                        while ((i < pact_sublist_length(args_sl))) {
                            args_str = pact_str_concat(args_str, ", ");
                            pact_emit_expr(pact_sublist_get(args_sl, i));
                            args_str = pact_str_concat(args_str, expr_result_str);
                            i = (i + 1);
                        }
                        char _si_2[4096];
                        snprintf(_si_2, 4096, "pact_%s(%s)", mangled, args_str);
                        expr_result_str = strdup(_si_2);
                        expr_result_type = pact_get_impl_method_ret(type_name, method);
                        return;
                    }
                }
            }
        }
    }
    pact_emit_expr(func_node);
    const char* func_str = expr_result_str;
    const int64_t args_sl = (int64_t)(intptr_t)pact_list_get(np_args, node);
    const char* args_str = "";
    if ((args_sl != (-1))) {
        int64_t i = 0;
        while ((i < pact_sublist_length(args_sl))) {
            if ((i > 0)) {
                args_str = pact_str_concat(args_str, ", ");
            }
            pact_emit_expr(pact_sublist_get(args_sl, i));
            args_str = pact_str_concat(args_str, expr_result_str);
            i = (i + 1);
        }
    }
    char _si_3[4096];
    snprintf(_si_3, 4096, "%s(%s)", func_str, args_str);
    expr_result_str = strdup(_si_3);
    expr_result_type = CT_VOID;
}

void pact_emit_method_call(int64_t node) {
    const int64_t obj_node = (int64_t)(intptr_t)pact_list_get(np_obj, node);
    const char* method = (const char*)pact_list_get(np_method, node);
    if (((((int64_t)(intptr_t)pact_list_get(np_kind, obj_node) == pact_NodeKind_Ident) && pact_str_eq((const char*)pact_list_get(np_name, obj_node), "io")) && pact_str_eq(method, "println"))) {
        const int64_t args_sl = (int64_t)(intptr_t)pact_list_get(np_args, node);
        if (((args_sl != (-1)) && (pact_sublist_length(args_sl) > 0))) {
            pact_emit_expr(pact_sublist_get(args_sl, 0));
            const char* arg_str = expr_result_str;
            const int64_t arg_type = expr_result_type;
            if ((arg_type == CT_INT)) {
                char _si_0[4096];
                snprintf(_si_0, 4096, "printf(\"%%lld\\n\", (long long)%s);", arg_str);
                pact_emit_line(strdup(_si_0));
            } else if ((arg_type == CT_FLOAT)) {
                char _si_1[4096];
                snprintf(_si_1, 4096, "printf(\"%%g\\n\", %s);", arg_str);
                pact_emit_line(strdup(_si_1));
            } else {
                if ((arg_type == CT_BOOL)) {
                    char _si_2[4096];
                    snprintf(_si_2, 4096, "printf(\"%%s\\n\", %s ? \"true\" : \"false\");", arg_str);
                    pact_emit_line(strdup(_si_2));
                } else {
                    char _si_3[4096];
                    snprintf(_si_3, 4096, "printf(\"%%s\\n\", %s);", arg_str);
                    pact_emit_line(strdup(_si_3));
                }
            }
        } else {
            pact_emit_line("printf(\"\\n\");");
        }
        expr_result_str = "0";
        expr_result_type = CT_VOID;
        return;
    }
    if (((int64_t)(intptr_t)pact_list_get(np_kind, obj_node) == pact_NodeKind_Ident)) {
        const char* trait_name = (const char*)pact_list_get(np_name, obj_node);
        if ((pact_is_trait_type(trait_name) != 0)) {
            const int64_t args_sl = (int64_t)(intptr_t)pact_list_get(np_args, node);
            if (((args_sl != (-1)) && (pact_sublist_length(args_sl) > 0))) {
                pact_emit_expr(pact_sublist_get(args_sl, 0));
                const char* first_str = expr_result_str;
                const char* type_name = pact_get_var_struct(first_str);
                if ((!pact_str_eq(type_name, ""))) {
                    char _si_4[4096];
                    snprintf(_si_4, 4096, "%s_%s", type_name, method);
                    const char* mangled = strdup(_si_4);
                    const char* args_str = first_str;
                    int64_t i = 1;
                    while ((i < pact_sublist_length(args_sl))) {
                        args_str = pact_str_concat(args_str, ", ");
                        pact_emit_expr(pact_sublist_get(args_sl, i));
                        args_str = pact_str_concat(args_str, expr_result_str);
                        i = (i + 1);
                    }
                    char _si_5[4096];
                    snprintf(_si_5, 4096, "pact_%s(%s)", mangled, args_str);
                    expr_result_str = strdup(_si_5);
                    expr_result_type = pact_get_impl_method_ret(type_name, method);
                    return;
                }
            }
        }
    }
    pact_emit_expr(obj_node);
    const char* obj_str = expr_result_str;
    const int64_t obj_type = expr_result_type;
    if ((obj_type == CT_STRING)) {
        if (pact_str_eq(method, "len")) {
            char _si_6[4096];
            snprintf(_si_6, 4096, "pact_str_len(%s)", obj_str);
            expr_result_str = strdup(_si_6);
            expr_result_type = CT_INT;
            return;
        }
        if ((pact_str_eq(method, "char_at") || pact_str_eq(method, "charAt"))) {
            const int64_t args_sl = (int64_t)(intptr_t)pact_list_get(np_args, node);
            pact_emit_expr(pact_sublist_get(args_sl, 0));
            const char* idx_str = expr_result_str;
            char _si_7[4096];
            snprintf(_si_7, 4096, "pact_str_char_at(%s, %s)", obj_str, idx_str);
            expr_result_str = strdup(_si_7);
            expr_result_type = CT_INT;
            return;
        }
        if ((pact_str_eq(method, "substring") || pact_str_eq(method, "substr"))) {
            const int64_t args_sl = (int64_t)(intptr_t)pact_list_get(np_args, node);
            pact_emit_expr(pact_sublist_get(args_sl, 0));
            const char* start_str = expr_result_str;
            pact_emit_expr(pact_sublist_get(args_sl, 1));
            const char* len_str = expr_result_str;
            char _si_8[4096];
            snprintf(_si_8, 4096, "pact_str_substr(%s, %s, %s)", obj_str, start_str, len_str);
            expr_result_str = strdup(_si_8);
            expr_result_type = CT_STRING;
            return;
        }
        if (pact_str_eq(method, "contains")) {
            const int64_t args_sl = (int64_t)(intptr_t)pact_list_get(np_args, node);
            pact_emit_expr(pact_sublist_get(args_sl, 0));
            const char* needle_str = expr_result_str;
            char _si_9[4096];
            snprintf(_si_9, 4096, "pact_str_contains(%s, %s)", obj_str, needle_str);
            expr_result_str = strdup(_si_9);
            expr_result_type = CT_BOOL;
            return;
        }
        if (pact_str_eq(method, "starts_with")) {
            const int64_t args_sl = (int64_t)(intptr_t)pact_list_get(np_args, node);
            pact_emit_expr(pact_sublist_get(args_sl, 0));
            const char* pfx_str = expr_result_str;
            char _si_10[4096];
            snprintf(_si_10, 4096, "pact_str_starts_with(%s, %s)", obj_str, pfx_str);
            expr_result_str = strdup(_si_10);
            expr_result_type = CT_BOOL;
            return;
        }
        if (pact_str_eq(method, "concat")) {
            const int64_t args_sl = (int64_t)(intptr_t)pact_list_get(np_args, node);
            pact_emit_expr(pact_sublist_get(args_sl, 0));
            const char* other_str = expr_result_str;
            char _si_11[4096];
            snprintf(_si_11, 4096, "pact_str_concat(%s, %s)", obj_str, other_str);
            expr_result_str = strdup(_si_11);
            expr_result_type = CT_STRING;
            return;
        }
    }
    if ((obj_type == CT_LIST)) {
        if (pact_str_eq(method, "push")) {
            const int64_t args_sl = (int64_t)(intptr_t)pact_list_get(np_args, node);
            pact_emit_expr(pact_sublist_get(args_sl, 0));
            const char* val_str = expr_result_str;
            const int64_t val_type = expr_result_type;
            if ((val_type == CT_INT)) {
                char _si_12[4096];
                snprintf(_si_12, 4096, "pact_list_push(%s, (void*)(intptr_t)%s);", obj_str, val_str);
                pact_emit_line(strdup(_si_12));
            } else {
                char _si_13[4096];
                snprintf(_si_13, 4096, "pact_list_push(%s, (void*)%s);", obj_str, val_str);
                pact_emit_line(strdup(_si_13));
            }
            expr_result_str = "0";
            expr_result_type = CT_VOID;
            return;
        }
        if (pact_str_eq(method, "pop")) {
            char _si_14[4096];
            snprintf(_si_14, 4096, "pact_list_pop(%s);", obj_str);
            pact_emit_line(strdup(_si_14));
            expr_result_str = "0";
            expr_result_type = CT_VOID;
            return;
        }
        if (pact_str_eq(method, "len")) {
            char _si_15[4096];
            snprintf(_si_15, 4096, "pact_list_len(%s)", obj_str);
            expr_result_str = strdup(_si_15);
            expr_result_type = CT_INT;
            return;
        }
        if (pact_str_eq(method, "get")) {
            const int64_t args_sl = (int64_t)(intptr_t)pact_list_get(np_args, node);
            pact_emit_expr(pact_sublist_get(args_sl, 0));
            const char* idx_str = expr_result_str;
            const int64_t elem_type = pact_get_list_elem_type(obj_str);
            if ((elem_type == CT_STRING)) {
                char _si_16[4096];
                snprintf(_si_16, 4096, "(const char*)pact_list_get(%s, %s)", obj_str, idx_str);
                expr_result_str = strdup(_si_16);
                expr_result_type = CT_STRING;
            } else {
                char _si_17[4096];
                snprintf(_si_17, 4096, "(int64_t)(intptr_t)pact_list_get(%s, %s)", obj_str, idx_str);
                expr_result_str = strdup(_si_17);
                expr_result_type = CT_INT;
            }
            return;
        }
        if (pact_str_eq(method, "set")) {
            const int64_t args_sl = (int64_t)(intptr_t)pact_list_get(np_args, node);
            pact_emit_expr(pact_sublist_get(args_sl, 0));
            const char* idx_str = expr_result_str;
            pact_emit_expr(pact_sublist_get(args_sl, 1));
            const char* val_str2 = expr_result_str;
            const int64_t val_type2 = expr_result_type;
            if ((val_type2 == CT_INT)) {
                char _si_18[4096];
                snprintf(_si_18, 4096, "pact_list_set(%s, %s, (void*)(intptr_t)%s);", obj_str, idx_str, val_str2);
                pact_emit_line(strdup(_si_18));
            } else {
                char _si_19[4096];
                snprintf(_si_19, 4096, "pact_list_set(%s, %s, (void*)%s);", obj_str, idx_str, val_str2);
                pact_emit_line(strdup(_si_19));
            }
            expr_result_str = "0";
            expr_result_type = CT_VOID;
            return;
        }
    }
    const char* struct_type = pact_get_var_struct(obj_str);
    if (((!pact_str_eq(struct_type, "")) && (pact_lookup_impl_method(struct_type, method) != 0))) {
        char _si_20[4096];
        snprintf(_si_20, 4096, "%s_%s", struct_type, method);
        const char* mangled = strdup(_si_20);
        const int64_t args_sl = (int64_t)(intptr_t)pact_list_get(np_args, node);
        const char* args_str = obj_str;
        if ((args_sl != (-1))) {
            int64_t i = 0;
            while ((i < pact_sublist_length(args_sl))) {
                args_str = pact_str_concat(args_str, ", ");
                pact_emit_expr(pact_sublist_get(args_sl, i));
                args_str = pact_str_concat(args_str, expr_result_str);
                i = (i + 1);
            }
        }
        char _si_21[4096];
        snprintf(_si_21, 4096, "pact_%s(%s)", mangled, args_str);
        expr_result_str = strdup(_si_21);
        expr_result_type = pact_get_impl_method_ret(struct_type, method);
        return;
    }
    const int64_t args_sl = (int64_t)(intptr_t)pact_list_get(np_args, node);
    const char* args_str = "";
    if ((args_sl != (-1))) {
        int64_t i = 0;
        while ((i < pact_sublist_length(args_sl))) {
            if ((i > 0)) {
                args_str = pact_str_concat(args_str, ", ");
            }
            pact_emit_expr(pact_sublist_get(args_sl, i));
            args_str = pact_str_concat(args_str, expr_result_str);
            i = (i + 1);
        }
    }
    char _si_22[4096];
    snprintf(_si_22, 4096, "%s_%s(%s)", obj_str, method, args_str);
    expr_result_str = strdup(_si_22);
    expr_result_type = CT_VOID;
}

const char* pact_escape_c_string(const char* s) {
    const char* result = "";
    int64_t i = 0;
    while ((i < pact_str_len(s))) {
        const int64_t ch = pact_str_char_at(s, i);
        if ((ch == 92)) {
            result = pact_str_concat(result, "\\\\");
        } else if ((ch == 34)) {
            result = pact_str_concat(result, "\\\"");
        } else {
            if ((ch == 10)) {
                result = pact_str_concat(result, "\\n");
            } else if ((ch == 9)) {
                result = pact_str_concat(result, "\\t");
            } else {
                result = pact_str_concat(result, pact_str_substr(s, i, 1));
            }
        }
        i = (i + 1);
    }
    return result;
}

void pact_emit_interp_string(int64_t node) {
    const int64_t parts_sl = (int64_t)(intptr_t)pact_list_get(np_elements, node);
    if ((parts_sl == (-1))) {
        expr_result_str = "\"\"";
        expr_result_type = CT_STRING;
        return;
    }
    int64_t all_literal = 1;
    int64_t ai = 0;
    while ((ai < pact_sublist_length(parts_sl))) {
        const int64_t part = pact_sublist_get(parts_sl, ai);
        const int64_t pk = (int64_t)(intptr_t)pact_list_get(np_kind, part);
        if ((!((pk == pact_NodeKind_Ident) && pact_str_eq((const char*)pact_list_get(np_str_val, part), (const char*)pact_list_get(np_name, part))))) {
            all_literal = 0;
        }
        ai = (ai + 1);
    }
    if ((all_literal != 0)) {
        const char* concat_str = "";
        int64_t ci = 0;
        while ((ci < pact_sublist_length(parts_sl))) {
            const int64_t part = pact_sublist_get(parts_sl, ci);
            concat_str = pact_str_concat(concat_str, pact_escape_c_string((const char*)pact_list_get(np_str_val, part)));
            ci = (ci + 1);
        }
        expr_result_str = pact_str_concat(pact_str_concat("\"", concat_str), "\"");
        expr_result_type = CT_STRING;
        return;
    }
    const char* buf_name = pact_fresh_temp("_si_");
    char _si_0[4096];
    snprintf(_si_0, 4096, "char %s[4096];", buf_name);
    pact_emit_line(strdup(_si_0));
    const char* fmt = "";
    const char* args = "";
    int64_t has_args = 0;
    int64_t i = 0;
    while ((i < pact_sublist_length(parts_sl))) {
        const int64_t part = pact_sublist_get(parts_sl, i);
        const int64_t pk = (int64_t)(intptr_t)pact_list_get(np_kind, part);
        if (((pk == pact_NodeKind_Ident) && pact_str_eq((const char*)pact_list_get(np_str_val, part), (const char*)pact_list_get(np_name, part)))) {
            fmt = pact_str_concat(fmt, pact_escape_c_string((const char*)pact_list_get(np_str_val, part)));
        } else {
            pact_emit_expr(part);
            const char* e_str = expr_result_str;
            const int64_t e_type = expr_result_type;
            if ((e_type == CT_INT)) {
                fmt = pact_str_concat(fmt, "%lld");
                if (has_args) {
                    args = pact_str_concat(args, ", ");
                }
                args = pact_str_concat(args, "(long long)");
                args = pact_str_concat(args, e_str);
                has_args = 1;
            } else if ((e_type == CT_FLOAT)) {
                fmt = pact_str_concat(fmt, "%g");
                if (has_args) {
                    args = pact_str_concat(args, ", ");
                }
                args = pact_str_concat(args, e_str);
                has_args = 1;
            } else {
                if ((e_type == CT_BOOL)) {
                    fmt = pact_str_concat(fmt, "%s");
                    if (has_args) {
                        args = pact_str_concat(args, ", ");
                    }
                    args = pact_str_concat(args, e_str);
                    args = pact_str_concat(args, " ? \"true\" : \"false\"");
                    has_args = 1;
                } else {
                    fmt = pact_str_concat(fmt, "%s");
                    if (has_args) {
                        args = pact_str_concat(args, ", ");
                    }
                    args = pact_str_concat(args, e_str);
                    has_args = 1;
                }
            }
        }
        i = (i + 1);
    }
    if (has_args) {
        const char* line = pact_str_concat(pact_str_concat(pact_str_concat(pact_str_concat(pact_str_concat(pact_str_concat("snprintf(", buf_name), ", 4096, \""), fmt), "\", "), args), ");");
        pact_emit_line(line);
    } else {
        const char* line = pact_str_concat(pact_str_concat(pact_str_concat(pact_str_concat("snprintf(", buf_name), ", 4096, \""), fmt), "\");");
        pact_emit_line(line);
    }
    expr_result_str = pact_str_concat(pact_str_concat("strdup(", buf_name), ")");
    expr_result_type = CT_STRING;
}

void pact_emit_list_lit(int64_t node) {
    const char* tmp = pact_fresh_temp("_l");
    char _si_0[4096];
    snprintf(_si_0, 4096, "pact_list* %s = pact_list_new();", tmp);
    pact_emit_line(strdup(_si_0));
    const int64_t elems_sl = (int64_t)(intptr_t)pact_list_get(np_elements, node);
    if ((elems_sl != (-1))) {
        int64_t i = 0;
        while ((i < pact_sublist_length(elems_sl))) {
            pact_emit_expr(pact_sublist_get(elems_sl, i));
            const char* e_str = expr_result_str;
            const int64_t e_type = expr_result_type;
            if ((e_type == CT_INT)) {
                char _si_1[4096];
                snprintf(_si_1, 4096, "pact_list_push(%s, (void*)(intptr_t)%s);", tmp, e_str);
                pact_emit_line(strdup(_si_1));
            } else {
                char _si_2[4096];
                snprintf(_si_2, 4096, "pact_list_push(%s, (void*)%s);", tmp, e_str);
                pact_emit_line(strdup(_si_2));
            }
            i = (i + 1);
        }
    }
    expr_result_str = tmp;
    expr_result_type = CT_LIST;
}

void pact_emit_struct_lit(int64_t node) {
    const char* sname = (const char*)pact_list_get(np_type_name, node);
    char _si_0[4096];
    snprintf(_si_0, 4096, "pact_%s", sname);
    const char* c_type = strdup(_si_0);
    const char* tmp = pact_fresh_temp("_s");
    const int64_t flds_sl = (int64_t)(intptr_t)pact_list_get(np_fields, node);
    const char* inits = "";
    if ((flds_sl != (-1))) {
        int64_t i = 0;
        while ((i < pact_sublist_length(flds_sl))) {
            const int64_t sf = pact_sublist_get(flds_sl, i);
            const char* fname = (const char*)pact_list_get(np_name, sf);
            pact_emit_expr((int64_t)(intptr_t)pact_list_get(np_value, sf));
            const char* val_str = expr_result_str;
            if ((i > 0)) {
                inits = pact_str_concat(inits, ", ");
            }
            char _si_1[4096];
            snprintf(_si_1, 4096, ".%s = %s", fname, val_str);
            inits = pact_str_concat(inits, strdup(_si_1));
            i = (i + 1);
        }
    }
    char _si_2[4096];
    snprintf(_si_2, 4096, "%s %s = { %s };", c_type, tmp, inits);
    pact_emit_line(strdup(_si_2));
    pact_set_var_struct(tmp, sname);
    expr_result_str = tmp;
    expr_result_type = CT_VOID;
}

void pact_emit_if_expr(int64_t node) {
    const char* tmp = pact_fresh_temp("_if_");
    const int64_t then_type = pact_infer_block_type((int64_t)(intptr_t)pact_list_get(np_then_body, node));
    char _si_0[4096];
    snprintf(_si_0, 4096, "%s %s;", pact_c_type_str(then_type), tmp);
    pact_emit_line(strdup(_si_0));
    pact_emit_expr((int64_t)(intptr_t)pact_list_get(np_condition, node));
    const char* cond_str = expr_result_str;
    char _si_1[4096];
    snprintf(_si_1, 4096, "if (%s) {", cond_str);
    pact_emit_line(strdup(_si_1));
    cg_indent = (cg_indent + 1);
    const char* then_val = pact_emit_block_value((int64_t)(intptr_t)pact_list_get(np_then_body, node));
    char _si_2[4096];
    snprintf(_si_2, 4096, "%s = %s;", tmp, then_val);
    pact_emit_line(strdup(_si_2));
    cg_indent = (cg_indent - 1);
    if (((int64_t)(intptr_t)pact_list_get(np_else_body, node) != (-1))) {
        pact_emit_line("} else {");
        cg_indent = (cg_indent + 1);
        const char* else_val = pact_emit_block_value((int64_t)(intptr_t)pact_list_get(np_else_body, node));
        char _si_3[4096];
        snprintf(_si_3, 4096, "%s = %s;", tmp, else_val);
        pact_emit_line(strdup(_si_3));
        cg_indent = (cg_indent - 1);
    }
    pact_emit_line("}");
    pact_set_var(tmp, then_type, 1);
    expr_result_str = tmp;
    expr_result_type = then_type;
}

void pact_emit_match_expr(int64_t node) {
    const int64_t scrut = (int64_t)(intptr_t)pact_list_get(np_scrutinee, node);
    pact_list* _l0 = pact_list_new();
    match_scrut_strs = _l0;
    pact_list* _l1 = pact_list_new();
    match_scrut_types = _l1;
    match_scrut_enum = "";
    if (((int64_t)(intptr_t)pact_list_get(np_kind, scrut) == pact_NodeKind_TupleLit)) {
        const int64_t elems_sl = (int64_t)(intptr_t)pact_list_get(np_elements, scrut);
        if ((elems_sl != (-1))) {
            int64_t ei = 0;
            while ((ei < pact_sublist_length(elems_sl))) {
                pact_emit_expr(pact_sublist_get(elems_sl, ei));
                const char* tmp = pact_fresh_temp("_tup_");
                char _si_2[4096];
                snprintf(_si_2, 4096, "%s %s = %s;", pact_c_type_str(expr_result_type), tmp, expr_result_str);
                pact_emit_line(strdup(_si_2));
                pact_set_var(tmp, expr_result_type, 1);
                pact_list_push(match_scrut_strs, (void*)tmp);
                pact_list_push(match_scrut_types, (void*)(intptr_t)expr_result_type);
                ei = (ei + 1);
            }
        }
    } else {
        if (((int64_t)(intptr_t)pact_list_get(np_kind, scrut) == pact_NodeKind_Ident)) {
            match_scrut_enum = pact_get_var_enum((const char*)pact_list_get(np_name, scrut));
        } else if (((int64_t)(intptr_t)pact_list_get(np_kind, scrut) == pact_NodeKind_FieldAccess)) {
            match_scrut_enum = pact_infer_enum_from_node(scrut);
        }
        pact_emit_expr(scrut);
        pact_list_push(match_scrut_strs, (void*)expr_result_str);
        pact_list_push(match_scrut_types, (void*)(intptr_t)expr_result_type);
    }
    const int64_t arms_sl = (int64_t)(intptr_t)pact_list_get(np_arms, node);
    if ((arms_sl == (-1))) {
        expr_result_str = "0";
        expr_result_type = CT_VOID;
        return;
    }
    const int64_t first_arm = pact_sublist_get(arms_sl, 0);
    const int64_t result_type = pact_infer_arm_type(first_arm);
    const char* result_var = pact_fresh_temp("_match_");
    char _si_3[4096];
    snprintf(_si_3, 4096, "%s %s;", pact_c_type_str(result_type), result_var);
    pact_emit_line(strdup(_si_3));
    int64_t first = 1;
    int64_t i = 0;
    while ((i < pact_sublist_length(arms_sl))) {
        const int64_t arm = pact_sublist_get(arms_sl, i);
        const int64_t pat = (int64_t)(intptr_t)pact_list_get(np_pattern, arm);
        const char* cond = pact_pattern_condition(pat, 0, pact_list_len(match_scrut_strs));
        const int is_wildcard = pact_str_eq(cond, "");
        if (is_wildcard) {
            if (first) {
                pact_emit_line("{");
            } else {
                pact_emit_line("} else {");
            }
        } else if (first) {
            char _si_4[4096];
            snprintf(_si_4, 4096, "if (%s) {", cond);
            pact_emit_line(strdup(_si_4));
        } else {
            char _si_5[4096];
            snprintf(_si_5, 4096, "} else if (%s) {", cond);
            pact_emit_line(strdup(_si_5));
        }
        cg_indent = (cg_indent + 1);
        pact_bind_pattern_vars(pat, 0, pact_list_len(match_scrut_strs));
        const char* arm_val = pact_emit_arm_value((int64_t)(intptr_t)pact_list_get(np_body, arm));
        char _si_6[4096];
        snprintf(_si_6, 4096, "%s = %s;", result_var, arm_val);
        pact_emit_line(strdup(_si_6));
        cg_indent = (cg_indent - 1);
        first = 0;
        i = (i + 1);
    }
    pact_emit_line("}");
    pact_set_var(result_var, result_type, 1);
    expr_result_str = result_var;
    expr_result_type = result_type;
}

const char* pact_pattern_condition(int64_t pat, int64_t scrut_off, int64_t scrut_len) {
    const int64_t pk = (int64_t)(intptr_t)pact_list_get(np_kind, pat);
    if ((pk == pact_NodeKind_WildcardPattern)) {
        return "";
    }
    if ((pk == pact_NodeKind_IdentPattern)) {
        const char* pat_name = (const char*)pact_list_get(np_name, pat);
        const char* enum_name = match_scrut_enum;
        if (pact_str_eq(enum_name, "")) {
            enum_name = pact_resolve_variant(pat_name);
        }
        if ((!pact_str_eq(enum_name, ""))) {
            char _si_0[4096];
            snprintf(_si_0, 4096, "(%s == pact_%s_%s)", (const char*)pact_list_get(match_scrut_strs, scrut_off), enum_name, pat_name);
            return strdup(_si_0);
        }
        return "";
    }
    if ((pk == pact_NodeKind_IntPattern)) {
        const char* pat_val = (const char*)pact_list_get(np_str_val, pat);
        char _si_1[4096];
        snprintf(_si_1, 4096, "(%s == %s)", (const char*)pact_list_get(match_scrut_strs, scrut_off), pat_val);
        return strdup(_si_1);
    }
    if ((pk == pact_NodeKind_TuplePattern)) {
        const int64_t elems_sl = (int64_t)(intptr_t)pact_list_get(np_elements, pat);
        if ((elems_sl == (-1))) {
            return "";
        }
        const char* parts = "";
        int64_t parts_n = 0;
        int64_t j = 0;
        while ((j < pact_sublist_length(elems_sl))) {
            const int64_t sub_pat = pact_sublist_get(elems_sl, j);
            const char* sub_cond = pact_pattern_condition(sub_pat, (scrut_off + j), 1);
            if ((!pact_str_eq(sub_cond, ""))) {
                if ((parts_n > 0)) {
                    parts = pact_str_concat(parts, " && ");
                }
                parts = pact_str_concat(parts, sub_cond);
                parts_n = (parts_n + 1);
            }
            j = (j + 1);
        }
        return parts;
    }
    return "";
}

void pact_bind_pattern_vars(int64_t pat, int64_t scrut_off, int64_t scrut_len) {
    const int64_t pk = (int64_t)(intptr_t)pact_list_get(np_kind, pat);
    if ((pk == pact_NodeKind_IdentPattern)) {
        const char* bind_name = (const char*)pact_list_get(np_name, pat);
        const char* enum_name = match_scrut_enum;
        if (pact_str_eq(enum_name, "")) {
            enum_name = pact_resolve_variant(bind_name);
        }
        if ((!pact_str_eq(enum_name, ""))) {
            return;
        }
        if ((scrut_len == 1)) {
            const int64_t st = (int64_t)(intptr_t)pact_list_get(match_scrut_types, scrut_off);
            char _si_0[4096];
            snprintf(_si_0, 4096, "%s %s = %s;", pact_c_type_str(st), bind_name, (const char*)pact_list_get(match_scrut_strs, scrut_off));
            pact_emit_line(strdup(_si_0));
            pact_set_var(bind_name, st, 1);
        }
        return;
    }
    if ((pk == pact_NodeKind_TuplePattern)) {
        const int64_t elems_sl = (int64_t)(intptr_t)pact_list_get(np_elements, pat);
        if ((elems_sl != (-1))) {
            int64_t j = 0;
            while ((j < pact_sublist_length(elems_sl))) {
                const int64_t sub_pat = pact_sublist_get(elems_sl, j);
                pact_bind_pattern_vars(sub_pat, (scrut_off + j), 1);
                j = (j + 1);
            }
        }
        return;
    }
}

void pact_emit_block_expr(int64_t node) {
    const int64_t stmts_sl = (int64_t)(intptr_t)pact_list_get(np_stmts, node);
    if ((stmts_sl == (-1))) {
        expr_result_str = "0";
        expr_result_type = CT_VOID;
        return;
    }
    const int64_t count = pact_sublist_length(stmts_sl);
    int64_t i = 0;
    while ((i < (count - 1))) {
        pact_emit_stmt(pact_sublist_get(stmts_sl, i));
        i = (i + 1);
    }
    if ((count > 0)) {
        const int64_t last = pact_sublist_get(stmts_sl, (count - 1));
        const int64_t last_kind = (int64_t)(intptr_t)pact_list_get(np_kind, last);
        if ((last_kind == pact_NodeKind_ExprStmt)) {
            pact_emit_expr((int64_t)(intptr_t)pact_list_get(np_value, last));
            return;
        }
        pact_emit_stmt(last);
    }
    expr_result_str = "0";
    expr_result_type = CT_VOID;
}

const char* pact_emit_arm_value(int64_t body) {
    if ((body == (-1))) {
        return "0";
    }
    const int64_t kind = (int64_t)(intptr_t)pact_list_get(np_kind, body);
    if ((kind == pact_NodeKind_Block)) {
        return pact_emit_block_value(body);
    }
    if ((kind == pact_NodeKind_ExprStmt)) {
        pact_emit_expr((int64_t)(intptr_t)pact_list_get(np_value, body));
        return expr_result_str;
    }
    pact_emit_expr(body);
    return expr_result_str;
}

const char* pact_emit_block_value(int64_t block) {
    if ((block == (-1))) {
        return "0";
    }
    const int64_t stmts_sl = (int64_t)(intptr_t)pact_list_get(np_stmts, block);
    if ((stmts_sl == (-1))) {
        return "0";
    }
    const int64_t count = pact_sublist_length(stmts_sl);
    if ((count == 0)) {
        return "0";
    }
    int64_t i = 0;
    while ((i < (count - 1))) {
        pact_emit_stmt(pact_sublist_get(stmts_sl, i));
        i = (i + 1);
    }
    const int64_t last = pact_sublist_get(stmts_sl, (count - 1));
    const int64_t last_kind = (int64_t)(intptr_t)pact_list_get(np_kind, last);
    if ((last_kind == pact_NodeKind_ExprStmt)) {
        pact_emit_expr((int64_t)(intptr_t)pact_list_get(np_value, last));
        return expr_result_str;
    }
    if ((last_kind == pact_NodeKind_IfExpr)) {
        pact_emit_if_expr(last);
        return expr_result_str;
    }
    if ((last_kind == pact_NodeKind_Return)) {
        if (((int64_t)(intptr_t)pact_list_get(np_value, last) != (-1))) {
            pact_emit_expr((int64_t)(intptr_t)pact_list_get(np_value, last));
            const char* val_s = expr_result_str;
            char _si_0[4096];
            snprintf(_si_0, 4096, "return %s;", val_s);
            pact_emit_line(strdup(_si_0));
        } else {
            pact_emit_line("return;");
        }
        return "0";
    }
    pact_emit_stmt(last);
    return "0";
}

int64_t pact_infer_block_type(int64_t block) {
    if ((block == (-1))) {
        return CT_VOID;
    }
    const int64_t stmts_sl = (int64_t)(intptr_t)pact_list_get(np_stmts, block);
    if ((stmts_sl == (-1))) {
        return CT_VOID;
    }
    const int64_t count = pact_sublist_length(stmts_sl);
    if ((count == 0)) {
        return CT_VOID;
    }
    const int64_t last = pact_sublist_get(stmts_sl, (count - 1));
    const int64_t last_kind = (int64_t)(intptr_t)pact_list_get(np_kind, last);
    if ((last_kind == pact_NodeKind_ExprStmt)) {
        return pact_infer_expr_type((int64_t)(intptr_t)pact_list_get(np_value, last));
    }
    return CT_VOID;
}

int64_t pact_infer_arm_type(int64_t arm) {
    const int64_t body = (int64_t)(intptr_t)pact_list_get(np_body, arm);
    if ((body == (-1))) {
        return CT_VOID;
    }
    const int64_t kind = (int64_t)(intptr_t)pact_list_get(np_kind, body);
    if ((kind == pact_NodeKind_Block)) {
        return pact_infer_block_type(body);
    }
    if ((kind == pact_NodeKind_ExprStmt)) {
        return pact_infer_expr_type((int64_t)(intptr_t)pact_list_get(np_value, body));
    }
    return pact_infer_expr_type(body);
}

int64_t pact_infer_expr_type(int64_t node) {
    if ((node == (-1))) {
        return CT_VOID;
    }
    const int64_t kind = (int64_t)(intptr_t)pact_list_get(np_kind, node);
    if ((kind == pact_NodeKind_IntLit)) {
        return CT_INT;
    }
    if ((kind == pact_NodeKind_FloatLit)) {
        return CT_FLOAT;
    }
    if ((kind == pact_NodeKind_BoolLit)) {
        return CT_BOOL;
    }
    if ((kind == pact_NodeKind_InterpString)) {
        return CT_STRING;
    }
    if ((kind == pact_NodeKind_ListLit)) {
        return CT_LIST;
    }
    if ((kind == pact_NodeKind_Ident)) {
        const char* iname = (const char*)pact_list_get(np_name, node);
        if ((!pact_str_eq(pact_resolve_variant(iname), ""))) {
            return CT_INT;
        }
        return pact_get_var_type(iname);
    }
    if ((kind == pact_NodeKind_FieldAccess)) {
        const int64_t fa_obj = (int64_t)(intptr_t)pact_list_get(np_obj, node);
        if (((int64_t)(intptr_t)pact_list_get(np_kind, fa_obj) == pact_NodeKind_Ident)) {
            if ((pact_is_enum_type((const char*)pact_list_get(np_name, fa_obj)) != 0)) {
                return CT_INT;
            }
        }
        return CT_VOID;
    }
    if ((kind == pact_NodeKind_IfExpr)) {
        return pact_infer_block_type((int64_t)(intptr_t)pact_list_get(np_then_body, node));
    }
    if ((kind == pact_NodeKind_Call)) {
        const int64_t func_node = (int64_t)(intptr_t)pact_list_get(np_left, node);
        if (((int64_t)(intptr_t)pact_list_get(np_kind, func_node) == pact_NodeKind_Ident)) {
            return pact_get_fn_ret((const char*)pact_list_get(np_name, func_node));
        }
    }
    if ((kind == pact_NodeKind_BinOp)) {
        const char* op = (const char*)pact_list_get(np_op, node);
        if ((((((((pact_str_eq(op, "==") || pact_str_eq(op, "!=")) || pact_str_eq(op, "<")) || pact_str_eq(op, ">")) || pact_str_eq(op, "<=")) || pact_str_eq(op, ">=")) || pact_str_eq(op, "&&")) || pact_str_eq(op, "||"))) {
            return CT_BOOL;
        }
        return pact_infer_expr_type((int64_t)(intptr_t)pact_list_get(np_left, node));
    }
    return CT_VOID;
}

void pact_emit_stmt(int64_t node) {
    const int64_t kind = (int64_t)(intptr_t)pact_list_get(np_kind, node);
    if ((kind == pact_NodeKind_ExprStmt)) {
        pact_emit_expr((int64_t)(intptr_t)pact_list_get(np_value, node));
        const char* s = expr_result_str;
        if (((!pact_str_eq(s, "")) && (!pact_str_eq(s, "0")))) {
            char _si_0[4096];
            snprintf(_si_0, 4096, "%s;", s);
            pact_emit_line(strdup(_si_0));
        }
        return;
    }
    if ((kind == pact_NodeKind_LetBinding)) {
        pact_emit_let_binding(node);
        return;
    }
    if ((kind == pact_NodeKind_Assignment)) {
        pact_emit_expr((int64_t)(intptr_t)pact_list_get(np_target, node));
        const char* target_str = expr_result_str;
        pact_emit_expr((int64_t)(intptr_t)pact_list_get(np_value, node));
        const char* val_str = expr_result_str;
        char _si_1[4096];
        snprintf(_si_1, 4096, "%s = %s;", target_str, val_str);
        pact_emit_line(strdup(_si_1));
        return;
    }
    if ((kind == pact_NodeKind_CompoundAssign)) {
        pact_emit_expr((int64_t)(intptr_t)pact_list_get(np_target, node));
        const char* target_str = expr_result_str;
        pact_emit_expr((int64_t)(intptr_t)pact_list_get(np_value, node));
        const char* val_str = expr_result_str;
        const char* op = (const char*)pact_list_get(np_op, node);
        char _si_2[4096];
        snprintf(_si_2, 4096, "%s %s= %s;", target_str, op, val_str);
        pact_emit_line(strdup(_si_2));
        return;
    }
    if ((kind == pact_NodeKind_Return)) {
        if (((int64_t)(intptr_t)pact_list_get(np_value, node) != (-1))) {
            pact_emit_expr((int64_t)(intptr_t)pact_list_get(np_value, node));
            const char* val_str = expr_result_str;
            char _si_3[4096];
            snprintf(_si_3, 4096, "return %s;", val_str);
            pact_emit_line(strdup(_si_3));
        } else {
            pact_emit_line("return;");
        }
        return;
    }
    if ((kind == pact_NodeKind_ForIn)) {
        pact_emit_for_in(node);
        return;
    }
    if ((kind == pact_NodeKind_WhileLoop)) {
        pact_emit_expr((int64_t)(intptr_t)pact_list_get(np_condition, node));
        const char* cond_str = expr_result_str;
        char _si_4[4096];
        snprintf(_si_4, 4096, "while (%s) {", cond_str);
        pact_emit_line(strdup(_si_4));
        cg_indent = (cg_indent + 1);
        pact_emit_block((int64_t)(intptr_t)pact_list_get(np_body, node));
        cg_indent = (cg_indent - 1);
        pact_emit_line("}");
        return;
    }
    if ((kind == pact_NodeKind_LoopExpr)) {
        pact_emit_line("while (1) {");
        cg_indent = (cg_indent + 1);
        pact_emit_block((int64_t)(intptr_t)pact_list_get(np_body, node));
        cg_indent = (cg_indent - 1);
        pact_emit_line("}");
        return;
    }
    if ((kind == pact_NodeKind_Break)) {
        pact_emit_line("break;");
        return;
    }
    if ((kind == pact_NodeKind_Continue)) {
        pact_emit_line("continue;");
        return;
    }
    if ((kind == pact_NodeKind_IfExpr)) {
        pact_emit_if_stmt(node);
        return;
    }
    if ((kind == pact_NodeKind_MatchExpr)) {
        pact_emit_match_expr(node);
        return;
    }
    pact_emit_expr(node);
    const char* s = expr_result_str;
    if ((!pact_str_eq(s, ""))) {
        char _si_5[4096];
        snprintf(_si_5, 4096, "%s;", s);
        pact_emit_line(strdup(_si_5));
    }
}

const char* pact_infer_enum_from_node(int64_t val_node) {
    const int64_t vk = (int64_t)(intptr_t)pact_list_get(np_kind, val_node);
    if ((vk == pact_NodeKind_FieldAccess)) {
        const int64_t obj = (int64_t)(intptr_t)pact_list_get(np_obj, val_node);
        if (((int64_t)(intptr_t)pact_list_get(np_kind, obj) == pact_NodeKind_Ident)) {
            const char* obj_name = (const char*)pact_list_get(np_name, obj);
            if ((pact_is_enum_type(obj_name) != 0)) {
                return obj_name;
            }
        }
    }
    if ((vk == pact_NodeKind_Ident)) {
        return pact_resolve_variant((const char*)pact_list_get(np_name, val_node));
    }
    return "";
}

void pact_emit_let_binding(int64_t node) {
    const int64_t val_node = (int64_t)(intptr_t)pact_list_get(np_value, node);
    const char* enum_type = pact_infer_enum_from_node(val_node);
    const int64_t type_ann = (int64_t)(intptr_t)pact_list_get(np_target, node);
    if ((pact_str_eq(enum_type, "") && (type_ann != (-1)))) {
        const char* ann_name = (const char*)pact_list_get(np_name, type_ann);
        if ((pact_is_enum_type(ann_name) != 0)) {
            enum_type = ann_name;
        }
    }
    pact_emit_expr(val_node);
    const char* val_str = expr_result_str;
    const int64_t val_type = expr_result_type;
    const char* name = (const char*)pact_list_get(np_name, node);
    const int64_t is_mut = (int64_t)(intptr_t)pact_list_get(np_is_mut, node);
    pact_set_var(name, val_type, is_mut);
    if ((!pact_str_eq(enum_type, ""))) {
        pact_list_push(var_enum_names, (void*)name);
        pact_list_push(var_enum_types, (void*)enum_type);
    }
    if (((int64_t)(intptr_t)pact_list_get(np_kind, val_node) == pact_NodeKind_StructLit)) {
        const char* sname = (const char*)pact_list_get(np_type_name, val_node);
        if ((pact_is_struct_type(sname) != 0)) {
            pact_set_var_struct(name, sname);
        }
    } else if ((type_ann != (-1))) {
        const char* ann_name = (const char*)pact_list_get(np_name, type_ann);
        if ((pact_is_struct_type(ann_name) != 0)) {
            pact_set_var_struct(name, ann_name);
        }
    }
    if (((val_type == CT_LIST) && (type_ann != (-1)))) {
        const char* ann_name = (const char*)pact_list_get(np_name, type_ann);
        if (pact_str_eq(ann_name, "List")) {
            const int64_t elems_sl = (int64_t)(intptr_t)pact_list_get(np_elements, type_ann);
            if (((elems_sl != (-1)) && (pact_sublist_length(elems_sl) > 0))) {
                const int64_t elem_ann = pact_sublist_get(elems_sl, 0);
                const char* elem_name = (const char*)pact_list_get(np_name, elem_ann);
                pact_set_list_elem_type(name, pact_type_from_name(elem_name));
            }
        }
    }
    const char* struct_type = pact_get_var_struct(name);
    if ((!pact_str_eq(enum_type, ""))) {
        if ((is_mut != 0)) {
            char _si_0[4096];
            snprintf(_si_0, 4096, "pact_%s %s = %s;", enum_type, name, val_str);
            pact_emit_line(strdup(_si_0));
        } else {
            char _si_1[4096];
            snprintf(_si_1, 4096, "const pact_%s %s = %s;", enum_type, name, val_str);
            pact_emit_line(strdup(_si_1));
        }
    } else if ((!pact_str_eq(struct_type, ""))) {
        if ((is_mut != 0)) {
            char _si_2[4096];
            snprintf(_si_2, 4096, "pact_%s %s = %s;", struct_type, name, val_str);
            pact_emit_line(strdup(_si_2));
        } else {
            char _si_3[4096];
            snprintf(_si_3, 4096, "const pact_%s %s = %s;", struct_type, name, val_str);
            pact_emit_line(strdup(_si_3));
        }
    } else {
        const char* ts = pact_c_type_str(val_type);
        if (((is_mut != 0) || (val_type == CT_STRING))) {
            char _si_4[4096];
            snprintf(_si_4, 4096, "%s %s = %s;", ts, name, val_str);
            pact_emit_line(strdup(_si_4));
        } else {
            char _si_5[4096];
            snprintf(_si_5, 4096, "const %s %s = %s;", ts, name, val_str);
            pact_emit_line(strdup(_si_5));
        }
    }
}

void pact_emit_for_in(int64_t node) {
    const char* var_name = (const char*)pact_list_get(np_var_name, node);
    const int64_t iter_node = (int64_t)(intptr_t)pact_list_get(np_iterable, node);
    const int64_t iter_kind = (int64_t)(intptr_t)pact_list_get(np_kind, iter_node);
    if ((iter_kind == pact_NodeKind_RangeLit)) {
        pact_emit_expr((int64_t)(intptr_t)pact_list_get(np_start, iter_node));
        const char* start_str = expr_result_str;
        pact_emit_expr((int64_t)(intptr_t)pact_list_get(np_end, iter_node));
        const char* end_str = expr_result_str;
        const char* op = "<";
        if (((int64_t)(intptr_t)pact_list_get(np_inclusive, iter_node) != 0)) {
            op = "<=";
        }
        char _si_0[4096];
        snprintf(_si_0, 4096, "for (int64_t %s = %s; %s %s %s; %s++) {", var_name, start_str, var_name, op, end_str, var_name);
        pact_emit_line(strdup(_si_0));
        pact_push_scope();
        pact_set_var(var_name, CT_INT, 1);
        cg_indent = (cg_indent + 1);
        pact_emit_block((int64_t)(intptr_t)pact_list_get(np_body, node));
        cg_indent = (cg_indent - 1);
        pact_pop_scope();
        pact_emit_line("}");
    } else {
        pact_emit_expr(iter_node);
        const char* iter_str = expr_result_str;
        const int64_t iter_type = expr_result_type;
        if ((iter_type == CT_LIST)) {
            const char* idx = pact_fresh_temp("_i");
            char _si_1[4096];
            snprintf(_si_1, 4096, "for (int64_t %s = 0; %s < pact_list_len(%s); %s++) {", idx, idx, iter_str, idx);
            pact_emit_line(strdup(_si_1));
            pact_push_scope();
            char _si_2[4096];
            snprintf(_si_2, 4096, "    int64_t %s = (int64_t)(intptr_t)pact_list_get(%s, %s);", var_name, iter_str, idx);
            pact_emit_line(strdup(_si_2));
            pact_set_var(var_name, CT_INT, 0);
            cg_indent = (cg_indent + 1);
            pact_emit_block((int64_t)(intptr_t)pact_list_get(np_body, node));
            cg_indent = (cg_indent - 1);
            pact_pop_scope();
            pact_emit_line("}");
        } else {
            pact_emit_line("/* unsupported iterable */");
        }
    }
}

void pact_emit_if_stmt(int64_t node) {
    pact_emit_expr((int64_t)(intptr_t)pact_list_get(np_condition, node));
    const char* cond_str = expr_result_str;
    char _si_0[4096];
    snprintf(_si_0, 4096, "if (%s) {", cond_str);
    pact_emit_line(strdup(_si_0));
    cg_indent = (cg_indent + 1);
    pact_emit_block((int64_t)(intptr_t)pact_list_get(np_then_body, node));
    cg_indent = (cg_indent - 1);
    if (((int64_t)(intptr_t)pact_list_get(np_else_body, node) != (-1))) {
        const int64_t else_b = (int64_t)(intptr_t)pact_list_get(np_else_body, node);
        const int64_t else_stmts = (int64_t)(intptr_t)pact_list_get(np_stmts, else_b);
        if (((else_stmts != (-1)) && (pact_sublist_length(else_stmts) == 1))) {
            const int64_t inner = pact_sublist_get(else_stmts, 0);
            if (((int64_t)(intptr_t)pact_list_get(np_kind, inner) == pact_NodeKind_IfExpr)) {
                const pact_list* saved_lines2 = cg_lines;
                pact_list* _l1 = pact_list_new();
                cg_lines = _l1;
                pact_emit_expr((int64_t)(intptr_t)pact_list_get(np_condition, inner));
                const pact_list* hoisted_lines = cg_lines;
                cg_lines = saved_lines2;
                if ((pact_list_len(hoisted_lines) > 0)) {
                    pact_emit_line("} else {");
                    cg_indent = (cg_indent + 1);
                    pact_emit_if_stmt(inner);
                    cg_indent = (cg_indent - 1);
                } else {
                    const char* inner_cond = expr_result_str;
                    char _si_2[4096];
                    snprintf(_si_2, 4096, "} else if (%s) {", inner_cond);
                    pact_emit_line(strdup(_si_2));
                    cg_indent = (cg_indent + 1);
                    pact_emit_block((int64_t)(intptr_t)pact_list_get(np_then_body, inner));
                    cg_indent = (cg_indent - 1);
                    if (((int64_t)(intptr_t)pact_list_get(np_else_body, inner) != (-1))) {
                        pact_emit_line("} else {");
                        cg_indent = (cg_indent + 1);
                        pact_emit_block((int64_t)(intptr_t)pact_list_get(np_else_body, inner));
                        cg_indent = (cg_indent - 1);
                    }
                }
                pact_emit_line("}");
                return;
            }
        }
        pact_emit_line("} else {");
        cg_indent = (cg_indent + 1);
        pact_emit_block(else_b);
        cg_indent = (cg_indent - 1);
    }
    pact_emit_line("}");
}

void pact_emit_block(int64_t block) {
    if ((block == (-1))) {
        return;
    }
    const int64_t stmts_sl = (int64_t)(intptr_t)pact_list_get(np_stmts, block);
    if ((stmts_sl == (-1))) {
        return;
    }
    int64_t i = 0;
    while ((i < pact_sublist_length(stmts_sl))) {
        pact_emit_stmt(pact_sublist_get(stmts_sl, i));
        i = (i + 1);
    }
}

const char* pact_format_params(int64_t fn_node) {
    const int64_t params_sl = (int64_t)(intptr_t)pact_list_get(np_params, fn_node);
    if ((params_sl == (-1))) {
        return "void";
    }
    const int64_t count = pact_sublist_length(params_sl);
    if ((count == 0)) {
        return "void";
    }
    const char* result = "";
    int64_t i = 0;
    while ((i < count)) {
        const int64_t p = pact_sublist_get(params_sl, i);
        const char* pname = (const char*)pact_list_get(np_name, p);
        const char* ptype = (const char*)pact_list_get(np_type_name, p);
        if ((i > 0)) {
            result = pact_str_concat(result, ", ");
        }
        if ((pact_is_enum_type(ptype) != 0)) {
            char _si_0[4096];
            snprintf(_si_0, 4096, "pact_%s %s", ptype, pname);
            result = pact_str_concat(result, strdup(_si_0));
        } else {
            const int64_t ct = pact_type_from_name(ptype);
            char _si_1[4096];
            snprintf(_si_1, 4096, "%s %s", pact_c_type_str(ct), pname);
            result = pact_str_concat(result, strdup(_si_1));
        }
        i = (i + 1);
    }
    return result;
}

const char* pact_format_impl_params(int64_t fn_node, const char* impl_type) {
    const int64_t params_sl = (int64_t)(intptr_t)pact_list_get(np_params, fn_node);
    char _si_0[4096];
    snprintf(_si_0, 4096, "pact_%s self", impl_type);
    const char* result = strdup(_si_0);
    if ((params_sl != (-1))) {
        int64_t i = 0;
        while ((i < pact_sublist_length(params_sl))) {
            const int64_t p = pact_sublist_get(params_sl, i);
            const char* pname = (const char*)pact_list_get(np_name, p);
            if ((!pact_str_eq(pname, "self"))) {
                const char* ptype = (const char*)pact_list_get(np_type_name, p);
                if ((pact_is_enum_type(ptype) != 0)) {
                    char _si_1[4096];
                    snprintf(_si_1, 4096, ", pact_%s %s", ptype, pname);
                    result = pact_str_concat(result, strdup(_si_1));
                } else {
                    const int64_t ct = pact_type_from_name(ptype);
                    char _si_2[4096];
                    snprintf(_si_2, 4096, ", %s %s", pact_c_type_str(ct), pname);
                    result = pact_str_concat(result, strdup(_si_2));
                }
            }
            i = (i + 1);
        }
    }
    return result;
}

void pact_emit_impl_method_def(int64_t fn_node, const char* impl_type) {
    pact_push_scope();
    cg_temp_counter = 0;
    const char* mname = (const char*)pact_list_get(np_name, fn_node);
    char _si_0[4096];
    snprintf(_si_0, 4096, "%s_%s", impl_type, mname);
    const char* mangled = strdup(_si_0);
    const char* ret_str = (const char*)pact_list_get(np_return_type, fn_node);
    const int64_t ret_type = pact_type_from_name(ret_str);
    const char* params = pact_format_impl_params(fn_node, impl_type);
    const char* enum_ret = pact_get_fn_enum_ret(mangled);
    const char* sig = "";
    if ((!pact_str_eq(enum_ret, ""))) {
        char _si_1[4096];
        snprintf(_si_1, 4096, "pact_%s pact_%s(%s)", enum_ret, mangled, params);
        sig = strdup(_si_1);
    } else {
        char _si_2[4096];
        snprintf(_si_2, 4096, "%s pact_%s(%s)", pact_c_type_str(ret_type), mangled, params);
        sig = strdup(_si_2);
    }
    pact_set_var("self", CT_VOID, 0);
    pact_set_var_struct("self", impl_type);
    const int64_t params_sl = (int64_t)(intptr_t)pact_list_get(np_params, fn_node);
    if ((params_sl != (-1))) {
        int64_t i = 0;
        while ((i < pact_sublist_length(params_sl))) {
            const int64_t p = pact_sublist_get(params_sl, i);
            const char* pname = (const char*)pact_list_get(np_name, p);
            if ((!pact_str_eq(pname, "self"))) {
                const char* ptype = (const char*)pact_list_get(np_type_name, p);
                pact_set_var(pname, pact_type_from_name(ptype), 1);
                if ((pact_is_struct_type(ptype) != 0)) {
                    pact_set_var_struct(pname, ptype);
                }
                if ((pact_is_enum_type(ptype) != 0)) {
                    pact_list_push(var_enum_names, (void*)pname);
                    pact_list_push(var_enum_types, (void*)ptype);
                }
            }
            i = (i + 1);
        }
    }
    char _si_3[4096];
    snprintf(_si_3, 4096, "%s {", sig);
    pact_emit_line(strdup(_si_3));
    cg_indent = (cg_indent + 1);
    pact_emit_fn_body((int64_t)(intptr_t)pact_list_get(np_body, fn_node), ret_type);
    cg_indent = (cg_indent - 1);
    pact_emit_line("}");
    pact_pop_scope();
}

void pact_emit_fn_decl(int64_t fn_node) {
    const char* name = (const char*)pact_list_get(np_name, fn_node);
    if (pact_str_eq(name, "main")) {
        pact_emit_line("void pact_main(void);");
        return;
    }
    const char* params = pact_format_params(fn_node);
    const char* enum_ret = pact_get_fn_enum_ret(name);
    if ((!pact_str_eq(enum_ret, ""))) {
        char _si_0[4096];
        snprintf(_si_0, 4096, "pact_%s pact_%s(%s);", enum_ret, name, params);
        pact_emit_line(strdup(_si_0));
    } else {
        const char* ret_str = (const char*)pact_list_get(np_return_type, fn_node);
        const int64_t ret_type = pact_type_from_name(ret_str);
        char _si_1[4096];
        snprintf(_si_1, 4096, "%s pact_%s(%s);", pact_c_type_str(ret_type), name, params);
        pact_emit_line(strdup(_si_1));
    }
}

void pact_emit_fn_def(int64_t fn_node) {
    pact_push_scope();
    cg_temp_counter = 0;
    const char* name = (const char*)pact_list_get(np_name, fn_node);
    const char* ret_str = (const char*)pact_list_get(np_return_type, fn_node);
    const int64_t ret_type = pact_type_from_name(ret_str);
    const char* sig = "";
    if (pact_str_eq(name, "main")) {
        sig = "void pact_main(void)";
    } else {
        const char* params = pact_format_params(fn_node);
        const char* enum_ret = pact_get_fn_enum_ret(name);
        if ((!pact_str_eq(enum_ret, ""))) {
            char _si_0[4096];
            snprintf(_si_0, 4096, "pact_%s pact_%s(%s)", enum_ret, name, params);
            sig = strdup(_si_0);
        } else {
            char _si_1[4096];
            snprintf(_si_1, 4096, "%s pact_%s(%s)", pact_c_type_str(ret_type), name, params);
            sig = strdup(_si_1);
        }
    }
    const int64_t params_sl = (int64_t)(intptr_t)pact_list_get(np_params, fn_node);
    if ((params_sl != (-1))) {
        int64_t i = 0;
        while ((i < pact_sublist_length(params_sl))) {
            const int64_t p = pact_sublist_get(params_sl, i);
            const char* pname = (const char*)pact_list_get(np_name, p);
            const char* ptype = (const char*)pact_list_get(np_type_name, p);
            pact_set_var(pname, pact_type_from_name(ptype), 1);
            if ((pact_is_struct_type(ptype) != 0)) {
                pact_set_var_struct(pname, ptype);
            }
            if ((pact_is_enum_type(ptype) != 0)) {
                pact_list_push(var_enum_names, (void*)pname);
                pact_list_push(var_enum_types, (void*)ptype);
            }
            i = (i + 1);
        }
    }
    char _si_2[4096];
    snprintf(_si_2, 4096, "%s {", sig);
    pact_emit_line(strdup(_si_2));
    cg_indent = (cg_indent + 1);
    pact_emit_fn_body((int64_t)(intptr_t)pact_list_get(np_body, fn_node), ret_type);
    cg_indent = (cg_indent - 1);
    pact_emit_line("}");
    pact_pop_scope();
}

void pact_emit_fn_body(int64_t block, int64_t ret_type) {
    if ((block == (-1))) {
        return;
    }
    const int64_t stmts_sl = (int64_t)(intptr_t)pact_list_get(np_stmts, block);
    if ((stmts_sl == (-1))) {
        return;
    }
    const int64_t count = pact_sublist_length(stmts_sl);
    if ((count == 0)) {
        return;
    }
    int64_t i = 0;
    while ((i < (count - 1))) {
        pact_emit_stmt(pact_sublist_get(stmts_sl, i));
        i = (i + 1);
    }
    const int64_t last = pact_sublist_get(stmts_sl, (count - 1));
    const int64_t last_kind = (int64_t)(intptr_t)pact_list_get(np_kind, last);
    if (((ret_type != CT_VOID) && (last_kind == pact_NodeKind_ExprStmt))) {
        pact_emit_expr((int64_t)(intptr_t)pact_list_get(np_value, last));
        const char* val_str = expr_result_str;
        char _si_0[4096];
        snprintf(_si_0, 4096, "return %s;", val_str);
        pact_emit_line(strdup(_si_0));
    } else if (((ret_type != CT_VOID) && (last_kind == pact_NodeKind_IfExpr))) {
        pact_emit_if_expr(last);
        const char* val_str = expr_result_str;
        char _si_1[4096];
        snprintf(_si_1, 4096, "return %s;", val_str);
        pact_emit_line(strdup(_si_1));
    } else {
        pact_emit_stmt(last);
    }
}

void pact_emit_struct_typedef(int64_t td_node) {
    const char* name = (const char*)pact_list_get(np_name, td_node);
    const int64_t flds_sl = (int64_t)(intptr_t)pact_list_get(np_fields, td_node);
    if ((flds_sl == (-1))) {
        return;
    }
    if ((pact_sublist_length(flds_sl) > 0)) {
        const int64_t first = pact_sublist_get(flds_sl, 0);
        if (((int64_t)(intptr_t)pact_list_get(np_kind, first) == pact_NodeKind_TypeVariant)) {
            return;
        }
    }
    pact_emit_line("typedef struct {");
    cg_indent = (cg_indent + 1);
    int64_t i = 0;
    while ((i < pact_sublist_length(flds_sl))) {
        const int64_t f = pact_sublist_get(flds_sl, i);
        const char* fname = (const char*)pact_list_get(np_name, f);
        const int64_t type_ann_node = (int64_t)(intptr_t)pact_list_get(np_value, f);
        if ((type_ann_node != (-1))) {
            const char* type_name = (const char*)pact_list_get(np_name, type_ann_node);
            if (pact_str_eq(type_name, name)) {
                char _si_0[4096];
                snprintf(_si_0, 4096, "int64_t %s;", fname);
                pact_emit_line(strdup(_si_0));
            } else if ((pact_is_struct_type(type_name) != 0)) {
                char _si_1[4096];
                snprintf(_si_1, 4096, "pact_%s %s;", type_name, fname);
                pact_emit_line(strdup(_si_1));
            } else {
                const int64_t ct = pact_type_from_name(type_name);
                char _si_2[4096];
                snprintf(_si_2, 4096, "%s %s;", pact_c_type_str(ct), fname);
                pact_emit_line(strdup(_si_2));
            }
        } else {
            char _si_3[4096];
            snprintf(_si_3, 4096, "int64_t %s;", fname);
            pact_emit_line(strdup(_si_3));
        }
        i = (i + 1);
    }
    cg_indent = (cg_indent - 1);
    char _si_4[4096];
    snprintf(_si_4, 4096, "} pact_%s;", name);
    pact_emit_line(strdup(_si_4));
    pact_emit_line("");
}

void pact_emit_enum_typedef(int64_t td_node) {
    const char* name = (const char*)pact_list_get(np_name, td_node);
    const int64_t flds_sl = (int64_t)(intptr_t)pact_list_get(np_fields, td_node);
    if ((flds_sl == (-1))) {
        return;
    }
    const int64_t enum_idx = pact_list_len(enum_reg_names);
    pact_list_push(enum_reg_names, (void*)name);
    const char* variants_str = "";
    int64_t i = 0;
    while ((i < pact_sublist_length(flds_sl))) {
        const int64_t v = pact_sublist_get(flds_sl, i);
        const char* vname = (const char*)pact_list_get(np_name, v);
        pact_list_push(enum_reg_variant_names, (void*)vname);
        pact_list_push(enum_reg_variant_enum_idx, (void*)(intptr_t)enum_idx);
        if ((i > 0)) {
            variants_str = pact_str_concat(variants_str, ", ");
        }
        char _si_0[4096];
        snprintf(_si_0, 4096, "pact_%s_%s", name, vname);
        variants_str = pact_str_concat(variants_str, strdup(_si_0));
        i = (i + 1);
    }
    char _si_1[4096];
    snprintf(_si_1, 4096, "typedef enum { %s } pact_%s;", variants_str, name);
    pact_emit_line(strdup(_si_1));
    pact_emit_line("");
}

void pact_emit_top_level_let(int64_t node) {
    const pact_list* saved_lines = cg_lines;
    pact_list* _l0 = pact_list_new();
    cg_lines = _l0;
    pact_emit_expr((int64_t)(intptr_t)pact_list_get(np_value, node));
    const char* val_str = expr_result_str;
    const int64_t val_type = expr_result_type;
    const pact_list* helper_lines = cg_lines;
    cg_lines = saved_lines;
    const char* name = (const char*)pact_list_get(np_name, node);
    const int64_t is_mut = (int64_t)(intptr_t)pact_list_get(np_is_mut, node);
    pact_set_var(name, val_type, is_mut);
    const int64_t type_ann = (int64_t)(intptr_t)pact_list_get(np_target, node);
    if (((val_type == CT_LIST) && (type_ann != (-1)))) {
        const char* ann_name = (const char*)pact_list_get(np_name, type_ann);
        if (pact_str_eq(ann_name, "List")) {
            const int64_t elems_sl = (int64_t)(intptr_t)pact_list_get(np_elements, type_ann);
            if (((elems_sl != (-1)) && (pact_sublist_length(elems_sl) > 0))) {
                const int64_t elem_ann = pact_sublist_get(elems_sl, 0);
                const char* elem_name = (const char*)pact_list_get(np_name, elem_ann);
                pact_set_list_elem_type(name, pact_type_from_name(elem_name));
            }
        }
    }
    const char* ts = pact_c_type_str(val_type);
    const int needs_init = ((pact_list_len(helper_lines) > 0) || (val_type == CT_LIST));
    if (needs_init) {
        char _si_1[4096];
        snprintf(_si_1, 4096, "static %s %s;", ts, name);
        pact_emit_line(strdup(_si_1));
        int64_t hi = 0;
        while ((hi < pact_list_len(helper_lines))) {
            pact_list_push(cg_global_inits, (void*)(intptr_t)(int64_t)(intptr_t)pact_list_get(helper_lines, hi));
            hi = (hi + 1);
        }
        char _si_2[4096];
        snprintf(_si_2, 4096, "    %s = %s;", name, val_str);
        pact_list_push(cg_global_inits, (void*)strdup(_si_2));
    } else if ((is_mut != 0)) {
        char _si_3[4096];
        snprintf(_si_3, 4096, "static %s %s = %s;", ts, name, val_str);
        pact_emit_line(strdup(_si_3));
    } else {
        char _si_4[4096];
        snprintf(_si_4, 4096, "static const %s %s = %s;", ts, name, val_str);
        pact_emit_line(strdup(_si_4));
    }
}

const char* pact_generate(int64_t program) {
    pact_list* _l0 = pact_list_new();
    cg_lines = _l0;
    cg_indent = 0;
    cg_temp_counter = 0;
    pact_list* _l1 = pact_list_new();
    scope_names = _l1;
    pact_list* _l2 = pact_list_new();
    scope_types = _l2;
    pact_list* _l3 = pact_list_new();
    scope_muts = _l3;
    pact_list* _l4 = pact_list_new();
    scope_frame_starts = _l4;
    pact_list* _l5 = pact_list_new();
    fn_reg_names = _l5;
    pact_list* _l6 = pact_list_new();
    fn_reg_ret = _l6;
    pact_list* _l7 = pact_list_new();
    cg_global_inits = _l7;
    pact_list* _l8 = pact_list_new();
    var_list_elem_names = _l8;
    pact_list* _l9 = pact_list_new();
    var_list_elem_types = _l9;
    pact_list* _l10 = pact_list_new();
    struct_reg_names = _l10;
    pact_list* _l11 = pact_list_new();
    enum_reg_names = _l11;
    pact_list* _l12 = pact_list_new();
    enum_reg_variant_names = _l12;
    pact_list* _l13 = pact_list_new();
    enum_reg_variant_enum_idx = _l13;
    pact_list* _l14 = pact_list_new();
    var_enum_names = _l14;
    pact_list* _l15 = pact_list_new();
    var_enum_types = _l15;
    pact_list* _l16 = pact_list_new();
    fn_enum_ret_names = _l16;
    pact_list* _l17 = pact_list_new();
    fn_enum_ret_types = _l17;
    pact_list* _l18 = pact_list_new();
    emitted_let_names = _l18;
    pact_list* _l19 = pact_list_new();
    emitted_fn_names = _l19;
    pact_list* _l20 = pact_list_new();
    trait_reg_names = _l20;
    pact_list* _l21 = pact_list_new();
    trait_reg_method_sl = _l21;
    pact_list* _l22 = pact_list_new();
    impl_reg_trait = _l22;
    pact_list* _l23 = pact_list_new();
    impl_reg_type = _l23;
    pact_list* _l24 = pact_list_new();
    impl_reg_methods_sl = _l24;
    pact_list* _l25 = pact_list_new();
    var_struct_names = _l25;
    pact_list* _l26 = pact_list_new();
    var_struct_types = _l26;
    pact_push_scope();
    pact_reg_fn("arg_count", CT_INT);
    pact_reg_fn("get_arg", CT_STRING);
    pact_reg_fn("read_file", CT_STRING);
    pact_reg_fn("write_file", CT_VOID);
    pact_list_push(cg_lines, (void*)"#include \"runtime.h\"");
    pact_list_push(cg_lines, (void*)"");
    const int64_t types_sl = (int64_t)(intptr_t)pact_list_get(np_fields, program);
    if ((types_sl != (-1))) {
        int64_t i = 0;
        while ((i < pact_sublist_length(types_sl))) {
            const int64_t td = pact_sublist_get(types_sl, i);
            const int64_t td_flds = (int64_t)(intptr_t)pact_list_get(np_fields, td);
            int64_t is_enum = 0;
            if (((td_flds != (-1)) && (pact_sublist_length(td_flds) > 0))) {
                if (((int64_t)(intptr_t)pact_list_get(np_kind, pact_sublist_get(td_flds, 0)) == pact_NodeKind_TypeVariant)) {
                    is_enum = 1;
                }
            }
            if ((is_enum == 0)) {
                pact_list_push(struct_reg_names, (void*)(const char*)pact_list_get(np_name, td));
            }
            i = (i + 1);
        }
    }
    if ((types_sl != (-1))) {
        int64_t i = 0;
        while ((i < pact_sublist_length(types_sl))) {
            const int64_t td = pact_sublist_get(types_sl, i);
            const int64_t td_flds = (int64_t)(intptr_t)pact_list_get(np_fields, td);
            int64_t is_enum = 0;
            if (((td_flds != (-1)) && (pact_sublist_length(td_flds) > 0))) {
                if (((int64_t)(intptr_t)pact_list_get(np_kind, pact_sublist_get(td_flds, 0)) == pact_NodeKind_TypeVariant)) {
                    is_enum = 1;
                }
            }
            if ((is_enum != 0)) {
                pact_emit_enum_typedef(td);
            } else {
                pact_emit_struct_typedef(td);
            }
            i = (i + 1);
        }
    }
    const int64_t lets_sl = (int64_t)(intptr_t)pact_list_get(np_stmts, program);
    if ((lets_sl != (-1))) {
        int64_t i = 0;
        while ((i < pact_sublist_length(lets_sl))) {
            const int64_t let_node = pact_sublist_get(lets_sl, i);
            const char* let_name = (const char*)pact_list_get(np_name, let_node);
            if ((pact_is_emitted_let(let_name) == 0)) {
                pact_emit_top_level_let(let_node);
                pact_list_push(emitted_let_names, (void*)let_name);
            }
            i = (i + 1);
        }
        pact_emit_line("");
    }
    const int64_t fns_sl = (int64_t)(intptr_t)pact_list_get(np_params, program);
    if ((fns_sl != (-1))) {
        int64_t i = 0;
        while ((i < pact_sublist_length(fns_sl))) {
            const int64_t fn_node = pact_sublist_get(fns_sl, i);
            const char* fn_name = (const char*)pact_list_get(np_name, fn_node);
            if ((pact_is_emitted_fn(fn_name) == 0)) {
                const char* ret_str = (const char*)pact_list_get(np_return_type, fn_node);
                if ((pact_is_enum_type(ret_str) != 0)) {
                    pact_list_push(fn_enum_ret_names, (void*)fn_name);
                    pact_list_push(fn_enum_ret_types, (void*)ret_str);
                    pact_reg_fn(fn_name, CT_INT);
                } else {
                    pact_reg_fn(fn_name, pact_type_from_name(ret_str));
                }
                pact_list_push(emitted_fn_names, (void*)fn_name);
            }
            i = (i + 1);
        }
    }
    const int64_t traits_sl = (int64_t)(intptr_t)pact_list_get(np_arms, program);
    if ((traits_sl != (-1))) {
        int64_t i = 0;
        while ((i < pact_sublist_length(traits_sl))) {
            const int64_t tr = pact_sublist_get(traits_sl, i);
            pact_list_push(trait_reg_names, (void*)(const char*)pact_list_get(np_name, tr));
            pact_list_push(trait_reg_method_sl, (void*)(intptr_t)(int64_t)(intptr_t)pact_list_get(np_methods, tr));
            i = (i + 1);
        }
    }
    const int64_t impls_sl = (int64_t)(intptr_t)pact_list_get(np_methods, program);
    if ((impls_sl != (-1))) {
        int64_t i = 0;
        while ((i < pact_sublist_length(impls_sl))) {
            const int64_t im = pact_sublist_get(impls_sl, i);
            const char* impl_trait = (const char*)pact_list_get(np_trait_name, im);
            const char* impl_type = (const char*)pact_list_get(np_name, im);
            pact_list_push(impl_reg_trait, (void*)impl_trait);
            pact_list_push(impl_reg_type, (void*)impl_type);
            pact_list_push(impl_reg_methods_sl, (void*)(intptr_t)(int64_t)(intptr_t)pact_list_get(np_methods, im));
            const int64_t methods_sl = (int64_t)(intptr_t)pact_list_get(np_methods, im);
            if ((methods_sl != (-1))) {
                int64_t j = 0;
                while ((j < pact_sublist_length(methods_sl))) {
                    const int64_t m = pact_sublist_get(methods_sl, j);
                    const char* mname = (const char*)pact_list_get(np_name, m);
                    char _si_27[4096];
                    snprintf(_si_27, 4096, "%s_%s", impl_type, mname);
                    const char* mangled = strdup(_si_27);
                    const char* ret_str = (const char*)pact_list_get(np_return_type, m);
                    if ((pact_is_enum_type(ret_str) != 0)) {
                        pact_list_push(fn_enum_ret_names, (void*)mangled);
                        pact_list_push(fn_enum_ret_types, (void*)ret_str);
                        pact_reg_fn(mangled, CT_INT);
                    } else {
                        pact_reg_fn(mangled, pact_type_from_name(ret_str));
                    }
                    j = (j + 1);
                }
            }
            i = (i + 1);
        }
    }
    pact_list* _l28 = pact_list_new();
    emitted_fn_names = _l28;
    if ((fns_sl != (-1))) {
        int64_t i = 0;
        while ((i < pact_sublist_length(fns_sl))) {
            const int64_t fn_node = pact_sublist_get(fns_sl, i);
            const char* fn_name = (const char*)pact_list_get(np_name, fn_node);
            if ((pact_is_emitted_fn(fn_name) == 0)) {
                pact_emit_fn_decl(fn_node);
                pact_list_push(emitted_fn_names, (void*)fn_name);
            }
            i = (i + 1);
        }
    }
    if ((impls_sl != (-1))) {
        int64_t i = 0;
        while ((i < pact_sublist_length(impls_sl))) {
            const int64_t im = pact_sublist_get(impls_sl, i);
            const char* impl_type = (const char*)pact_list_get(np_name, im);
            const int64_t methods_sl = (int64_t)(intptr_t)pact_list_get(np_methods, im);
            if ((methods_sl != (-1))) {
                int64_t j = 0;
                while ((j < pact_sublist_length(methods_sl))) {
                    const int64_t m = pact_sublist_get(methods_sl, j);
                    const char* mname = (const char*)pact_list_get(np_name, m);
                    char _si_29[4096];
                    snprintf(_si_29, 4096, "%s_%s", impl_type, mname);
                    const char* mangled = strdup(_si_29);
                    const char* params = pact_format_impl_params(m, impl_type);
                    const char* enum_ret = pact_get_fn_enum_ret(mangled);
                    if ((!pact_str_eq(enum_ret, ""))) {
                        char _si_30[4096];
                        snprintf(_si_30, 4096, "pact_%s pact_%s(%s);", enum_ret, mangled, params);
                        pact_emit_line(strdup(_si_30));
                    } else {
                        const char* ret_str = (const char*)pact_list_get(np_return_type, m);
                        const int64_t ret_type = pact_type_from_name(ret_str);
                        char _si_31[4096];
                        snprintf(_si_31, 4096, "%s pact_%s(%s);", pact_c_type_str(ret_type), mangled, params);
                        pact_emit_line(strdup(_si_31));
                    }
                    j = (j + 1);
                }
            }
            i = (i + 1);
        }
    }
    pact_emit_line("");
    pact_list* _l32 = pact_list_new();
    emitted_fn_names = _l32;
    if ((fns_sl != (-1))) {
        int64_t i = 0;
        while ((i < pact_sublist_length(fns_sl))) {
            const int64_t fn_node = pact_sublist_get(fns_sl, i);
            const char* fn_name = (const char*)pact_list_get(np_name, fn_node);
            if ((pact_is_emitted_fn(fn_name) == 0)) {
                pact_emit_fn_def(fn_node);
                pact_emit_line("");
                pact_list_push(emitted_fn_names, (void*)fn_name);
            }
            i = (i + 1);
        }
    }
    if ((impls_sl != (-1))) {
        int64_t i = 0;
        while ((i < pact_sublist_length(impls_sl))) {
            const int64_t im = pact_sublist_get(impls_sl, i);
            const char* impl_type = (const char*)pact_list_get(np_name, im);
            const int64_t methods_sl = (int64_t)(intptr_t)pact_list_get(np_methods, im);
            if ((methods_sl != (-1))) {
                int64_t j = 0;
                while ((j < pact_sublist_length(methods_sl))) {
                    const int64_t m = pact_sublist_get(methods_sl, j);
                    pact_emit_impl_method_def(m, impl_type);
                    pact_emit_line("");
                    j = (j + 1);
                }
            }
            i = (i + 1);
        }
    }
    if ((pact_list_len(cg_global_inits) > 0)) {
        pact_emit_line("static void __pact_init_globals(void) {");
        int64_t gi = 0;
        while ((gi < pact_list_len(cg_global_inits))) {
            pact_list_push(cg_lines, (void*)(const char*)pact_list_get(cg_global_inits, gi));
            gi = (gi + 1);
        }
        pact_emit_line("}");
        pact_emit_line("");
    }
    pact_emit_line("int main(int argc, char** argv) {");
    cg_indent = (cg_indent + 1);
    pact_emit_line("pact_g_argc = argc;");
    pact_emit_line("pact_g_argv = (const char**)argv;");
    if ((pact_list_len(cg_global_inits) > 0)) {
        pact_emit_line("__pact_init_globals();");
    }
    pact_emit_line("pact_main();");
    pact_emit_line("return 0;");
    cg_indent = (cg_indent - 1);
    pact_emit_line("}");
    pact_pop_scope();
    return pact_join_lines();
}

void pact_main(void) {
    if ((pact_arg_count() < 2)) {
        printf("%s\n", "Usage: pactc <source.pact> [output.c]");
        printf("%s\n", "  Compiles a Pact source file to C.");
        return;
    }
    const char* source_path = pact_get_arg(1);
    const char* source = pact_read_file(source_path);
    pact_lex(source);
    const int64_t program_node = pact_parse_program();
    const char* c_output = pact_generate(program_node);
    if ((pact_arg_count() >= 3)) {
        const char* out_path = pact_get_arg(2);
        pact_write_file(out_path, c_output);
    } else {
        printf("%s\n", c_output);
    }
}

static void __pact_init_globals(void) {
pact_list* _l0 = pact_list_new();
    tok_kinds = _l0;
pact_list* _l1 = pact_list_new();
    tok_values = _l1;
pact_list* _l2 = pact_list_new();
    tok_lines = _l2;
pact_list* _l3 = pact_list_new();
    tok_cols = _l3;
pact_list* _l4 = pact_list_new();
    np_kind = _l4;
pact_list* _l5 = pact_list_new();
    np_int_val = _l5;
pact_list* _l6 = pact_list_new();
    np_str_val = _l6;
pact_list* _l7 = pact_list_new();
    np_name = _l7;
pact_list* _l8 = pact_list_new();
    np_op = _l8;
pact_list* _l9 = pact_list_new();
    np_left = _l9;
pact_list* _l10 = pact_list_new();
    np_right = _l10;
pact_list* _l11 = pact_list_new();
    np_body = _l11;
pact_list* _l12 = pact_list_new();
    np_condition = _l12;
pact_list* _l13 = pact_list_new();
    np_then_body = _l13;
pact_list* _l14 = pact_list_new();
    np_else_body = _l14;
pact_list* _l15 = pact_list_new();
    np_scrutinee = _l15;
pact_list* _l16 = pact_list_new();
    np_pattern = _l16;
pact_list* _l17 = pact_list_new();
    np_guard = _l17;
pact_list* _l18 = pact_list_new();
    np_value = _l18;
pact_list* _l19 = pact_list_new();
    np_target = _l19;
pact_list* _l20 = pact_list_new();
    np_iterable = _l20;
pact_list* _l21 = pact_list_new();
    np_var_name = _l21;
pact_list* _l22 = pact_list_new();
    np_is_mut = _l22;
pact_list* _l23 = pact_list_new();
    np_is_pub = _l23;
pact_list* _l24 = pact_list_new();
    np_inclusive = _l24;
pact_list* _l25 = pact_list_new();
    np_start = _l25;
pact_list* _l26 = pact_list_new();
    np_end = _l26;
pact_list* _l27 = pact_list_new();
    np_obj = _l27;
pact_list* _l28 = pact_list_new();
    np_method = _l28;
pact_list* _l29 = pact_list_new();
    np_index = _l29;
pact_list* _l30 = pact_list_new();
    np_return_type = _l30;
pact_list* _l31 = pact_list_new();
    np_type_name = _l31;
pact_list* _l32 = pact_list_new();
    np_trait_name = _l32;
pact_list* _l33 = pact_list_new();
    sl_items = _l33;
pact_list* _l34 = pact_list_new();
    sl_start = _l34;
pact_list* _l35 = pact_list_new();
    sl_len = _l35;
pact_list* _l36 = pact_list_new();
    np_params = _l36;
pact_list* _l37 = pact_list_new();
    np_args = _l37;
pact_list* _l38 = pact_list_new();
    np_stmts = _l38;
pact_list* _l39 = pact_list_new();
    np_arms = _l39;
pact_list* _l40 = pact_list_new();
    np_fields = _l40;
pact_list* _l41 = pact_list_new();
    np_elements = _l41;
pact_list* _l42 = pact_list_new();
    np_methods = _l42;
pact_list* _l43 = pact_list_new();
    cg_lines = _l43;
pact_list* _l44 = pact_list_new();
    cg_global_inits = _l44;
pact_list* _l45 = pact_list_new();
    struct_reg_names = _l45;
pact_list* _l46 = pact_list_new();
    enum_reg_names = _l46;
pact_list* _l47 = pact_list_new();
    enum_reg_variant_names = _l47;
pact_list* _l48 = pact_list_new();
    enum_reg_variant_enum_idx = _l48;
pact_list* _l49 = pact_list_new();
    var_enum_names = _l49;
pact_list* _l50 = pact_list_new();
    var_enum_types = _l50;
pact_list* _l51 = pact_list_new();
    fn_enum_ret_names = _l51;
pact_list* _l52 = pact_list_new();
    fn_enum_ret_types = _l52;
pact_list* _l53 = pact_list_new();
    emitted_let_names = _l53;
pact_list* _l54 = pact_list_new();
    emitted_fn_names = _l54;
pact_list* _l55 = pact_list_new();
    trait_reg_names = _l55;
pact_list* _l56 = pact_list_new();
    trait_reg_method_sl = _l56;
pact_list* _l57 = pact_list_new();
    impl_reg_trait = _l57;
pact_list* _l58 = pact_list_new();
    impl_reg_type = _l58;
pact_list* _l59 = pact_list_new();
    impl_reg_methods_sl = _l59;
pact_list* _l60 = pact_list_new();
    var_struct_names = _l60;
pact_list* _l61 = pact_list_new();
    var_struct_types = _l61;
pact_list* _l62 = pact_list_new();
    scope_names = _l62;
pact_list* _l63 = pact_list_new();
    scope_types = _l63;
pact_list* _l64 = pact_list_new();
    scope_muts = _l64;
pact_list* _l65 = pact_list_new();
    scope_frame_starts = _l65;
pact_list* _l66 = pact_list_new();
    fn_reg_names = _l66;
pact_list* _l67 = pact_list_new();
    fn_reg_ret = _l67;
pact_list* _l68 = pact_list_new();
    var_list_elem_names = _l68;
pact_list* _l69 = pact_list_new();
    var_list_elem_types = _l69;
pact_list* _l70 = pact_list_new();
    match_scrut_strs = _l70;
pact_list* _l71 = pact_list_new();
    match_scrut_types = _l71;
}

int main(int argc, char** argv) {
    pact_g_argc = argc;
    pact_g_argv = (const char**)argv;
    __pact_init_globals();
    pact_main();
    return 0;
}