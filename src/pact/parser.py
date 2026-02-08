import pact.tokens as tokens
import pact.ast_nodes as ast

TT = tokens.TokenType


class ParseError(Exception):
    def __init__(self, msg, token):
        self.token = token
        super().__init__(f"line {token.line}:{token.col}: {msg}")


class Parser:
    def __init__(self, token_list):
        self.tokens = token_list
        self.pos = 0

    def peek(self):
        return self.tokens[self.pos]

    def advance(self):
        tok = self.tokens[self.pos]
        self.pos += 1
        return tok

    def expect(self, token_type):
        tok = self.peek()
        if tok.type != token_type:
            raise ParseError(f"expected {token_type.value}, got {tok.type.value}", tok)
        return self.advance()

    def at(self, token_type):
        return self.peek().type == token_type

    def at_any(self, *types):
        return self.peek().type in types

    def skip_newlines(self):
        while self.at(TT.NEWLINE):
            self.advance()

    def maybe_newline(self):
        if self.at(TT.NEWLINE):
            self.advance()

    def skip_newlines_if_next(self, *token_types):
        saved = self.pos
        while self.at(TT.NEWLINE):
            self.advance()
        if self.peek().type not in token_types:
            self.pos = saved

    # --- Top-level ---

    def parse_program(self):
        prog = ast.Program(functions=[], types=[], traits=[], impls=[], tests=[], annotations=[])
        self.skip_newlines()
        while not self.at(TT.EOF):
            annotations = self.collect_annotations()
            self.skip_newlines()
            if self.at(TT.EOF):
                if annotations:
                    prog.annotations.extend(annotations)
                break

            if self.at(TT.IMPORT):
                prog.imports.append(self.parse_import())
                self.skip_newlines()
                continue
            elif self.at(TT.TYPE):
                td = self.parse_type_def(annotations)
                prog.types.append(td)
            elif self.at(TT.TRAIT):
                prog.traits.append(self.parse_trait_def())
            elif self.at(TT.IMPL):
                prog.impls.append(self.parse_impl_block())
            elif self.at(TT.TEST):
                prog.tests.append(self.parse_test_block())
            elif self.at(TT.MOD):
                prog.modules.append(self.parse_mod_block())
            elif self.at(TT.PUB):
                self.advance()
                self.skip_newlines()
                fn = self.parse_fn_def(annotations)
                fn.is_pub = True
                prog.functions.append(fn)
            elif self.at(TT.LET):
                prog.top_lets.append(self.parse_let_binding())
            elif self.at(TT.FN):
                prog.functions.append(self.parse_fn_def(annotations))
            else:
                if annotations:
                    prog.annotations.extend(annotations)
                else:
                    raise ParseError(f"unexpected token at top level: {self.peek().type.value}", self.peek())
            self.skip_newlines()
        return prog

    def parse_import(self):
        self.expect(TT.IMPORT)
        path_parts = [self.expect(TT.IDENT).value]
        while self.at(TT.DOT):
            self.advance()
            if self.at(TT.LBRACE):
                break
            path_parts.append(self.expect(TT.IDENT).value)
        path = ".".join(path_parts)
        names = []
        if self.at(TT.LBRACE):
            self.advance()
            self.skip_newlines()
            names.append(self.expect(TT.IDENT).value)
            while self.at(TT.COMMA):
                self.advance()
                self.skip_newlines()
                if self.at(TT.RBRACE):
                    break
                names.append(self.expect(TT.IDENT).value)
            self.expect(TT.RBRACE)
        self.maybe_newline()
        return ast.ImportStmt(path, names)

    def parse_mod_block(self):
        self.expect(TT.MOD)
        name = self.expect(TT.IDENT).value
        self.skip_newlines()
        self.expect(TT.LBRACE)
        self.skip_newlines()
        inner = ast.Program(functions=[], types=[], traits=[], impls=[], tests=[], annotations=[])
        while not self.at(TT.RBRACE):
            annotations = self.collect_annotations()
            self.skip_newlines()
            if self.at(TT.RBRACE):
                if annotations:
                    inner.annotations.extend(annotations)
                break
            if self.at(TT.TYPE):
                inner.types.append(self.parse_type_def(annotations))
            elif self.at(TT.TRAIT):
                inner.traits.append(self.parse_trait_def())
            elif self.at(TT.IMPL):
                inner.impls.append(self.parse_impl_block())
            elif self.at(TT.TEST):
                inner.tests.append(self.parse_test_block())
            elif self.at(TT.PUB):
                self.advance()
                self.skip_newlines()
                fn = self.parse_fn_def(annotations)
                fn.is_pub = True
                inner.functions.append(fn)
            elif self.at(TT.FN):
                inner.functions.append(self.parse_fn_def(annotations))
            else:
                raise ParseError(f"unexpected token in mod block: {self.peek().type.value}", self.peek())
            self.skip_newlines()
        self.expect(TT.RBRACE)
        return ast.ModBlock(name, inner)

    def collect_annotations(self):
        annotations = []
        while True:
            self.skip_newlines()
            if self.at(TT.AT):
                annotations.append(self.parse_annotation())
            else:
                break
        return annotations

    def parse_annotation(self):
        self.expect(TT.AT)
        name = self.expect(TT.IDENT).value
        args = []
        if self.at(TT.LPAREN):
            args = self.collect_balanced(TT.LPAREN, TT.RPAREN)
        return ast.Annotation(name, args)

    def collect_balanced(self, open_tt, close_tt):
        self.expect(open_tt)
        depth = 1
        collected = []
        while depth > 0:
            tok = self.advance()
            if tok.type == open_tt:
                depth += 1
                collected.append(tok.value)
            elif tok.type == close_tt:
                depth -= 1
                if depth > 0:
                    collected.append(tok.value)
            elif tok.type == TT.EOF:
                raise ParseError("unexpected EOF in balanced group", tok)
            else:
                collected.append(tok.value)
        return collected

    # --- Type Definitions ---

    def parse_type_def(self, annotations=None):
        self.expect(TT.TYPE)
        name = self.expect(TT.IDENT).value
        type_params = self.parse_type_params()

        if self.at(TT.EQUALS):
            self.advance()
            self.skip_newlines()
            self.parse_type_annotation()
            ann = annotations or []
            while self.at(TT.AT):
                ann.append(self.parse_annotation())
            return ast.TypeDef(name, type_params, [], [], ann)

        self.skip_newlines()
        self.expect(TT.LBRACE)
        self.skip_newlines()
        fields = []
        variants = []
        inner_annotations = []
        while not self.at(TT.RBRACE):
            if self.at(TT.AT):
                inner_annotations.append(self.parse_annotation())
                self.skip_newlines()
                continue
            saved = self.pos
            ident = self.expect(TT.IDENT).value
            if self.at(TT.COLON):
                self.advance()
                type_ann = self.parse_type_annotation()
                default_val = None
                if self.at(TT.EQUALS):
                    self.advance()
                    self.skip_newlines()
                    default_val = self.parse_expr()
                fields.append(ast.TypeField(ident, type_ann, default_val))
            elif self.at(TT.LPAREN):
                self.advance()
                vfields = []
                if not self.at(TT.RPAREN):
                    vfields = self.parse_variant_fields()
                self.expect(TT.RPAREN)
                variants.append(ast.TypeVariant(ident, vfields))
            else:
                variants.append(ast.TypeVariant(ident, []))
            self.skip_newlines()
        self.expect(TT.RBRACE)
        all_ann = (annotations or []) + inner_annotations
        return ast.TypeDef(name, type_params, fields, variants, all_ann)

    def parse_variant_fields(self):
        fields = [self.parse_variant_field(0)]
        while self.at(TT.COMMA):
            self.advance()
            if self.at(TT.RPAREN):
                break
            fields.append(self.parse_variant_field(len(fields)))
        return fields

    def parse_variant_field(self, index=0):
        name = self.expect(TT.IDENT).value
        if self.at(TT.COLON):
            self.advance()
            type_ann = self.parse_type_annotation()
            return ast.TypeField(name, type_ann)
        params = []
        if self.at(TT.LBRACKET):
            self.advance()
            params = [self.parse_type_annotation()]
            while self.at(TT.COMMA):
                self.advance()
                params.append(self.parse_type_annotation())
            self.expect(TT.RBRACKET)
        type_ann = ast.TypeAnnotation(name, params)
        return ast.TypeField(f"_{index}", type_ann)


    def parse_type_params(self):
        if not self.at(TT.LBRACKET):
            return []
        self.advance()
        params = [self.expect(TT.IDENT).value]
        if self.at(TT.COLON):
            self.advance()
            self.parse_type_annotation()
        while self.at(TT.COMMA):
            self.advance()
            params.append(self.expect(TT.IDENT).value)
            if self.at(TT.COLON):
                self.advance()
                self.parse_type_annotation()
        self.expect(TT.RBRACKET)
        return params

    # --- Trait / Impl / Test ---

    def parse_trait_def(self):
        self.expect(TT.TRAIT)
        name = self.expect(TT.IDENT).value
        type_params = self.parse_type_params()
        super_traits = []
        if self.at(TT.COLON):
            self.advance()
            super_traits.append(self.expect(TT.IDENT).value)
            while self.at(TT.PLUS):
                self.advance()
                super_traits.append(self.expect(TT.IDENT).value)
        self.skip_newlines()
        self.expect(TT.LBRACE)
        self.skip_newlines()
        methods = []
        while not self.at(TT.RBRACE):
            annotations = self.collect_annotations()
            self.skip_newlines()
            if self.at(TT.RBRACE):
                break
            methods.append(self.parse_fn_def(annotations))
            self.skip_newlines()
        self.expect(TT.RBRACE)
        return ast.TraitDef(name, type_params, super_traits, methods)

    def parse_impl_block(self):
        self.expect(TT.IMPL)
        trait_name = self.expect(TT.IDENT).value
        trait_type_params = []
        if self.at(TT.LBRACKET):
            trait_type_params = self.parse_type_params()

        self.expect(TT.FOR)
        type_name = self.expect(TT.IDENT).value
        self.skip_newlines()
        self.expect(TT.LBRACE)
        self.skip_newlines()
        methods = []
        while not self.at(TT.RBRACE):
            annotations = self.collect_annotations()
            self.skip_newlines()
            if self.at(TT.RBRACE):
                break
            methods.append(self.parse_fn_def(annotations))
            self.skip_newlines()
        self.expect(TT.RBRACE)
        return ast.ImplBlock(trait_name, type_name, trait_type_params, methods)

    def parse_test_block(self):
        self.expect(TT.TEST)
        name_parts = []
        self.expect(TT.STRING_START)
        while not self.at(TT.STRING_END):
            if self.at(TT.STRING_PART):
                name_parts.append(self.advance().value)
            else:
                self.advance()
        self.expect(TT.STRING_END)
        name = "".join(name_parts)
        self.skip_newlines()
        body = self.parse_block()
        return ast.TestBlock(name, body)

    # --- Function Definitions ---

    def parse_fn_def(self, annotations=None):
        self.expect(TT.FN)
        name = self.expect(TT.IDENT).value
        self.parse_type_params()
        self.expect(TT.LPAREN)
        params = []
        if not self.at(TT.RPAREN):
            params = self.parse_params()
        self.expect(TT.RPAREN)

        return_type = None
        if self.at(TT.ARROW):
            self.advance()
            return_type = self.parse_type_annotation()

        effects = []
        if self.at(TT.BANG):
            self.advance()
            effects = self.parse_effect_list()

        self.skip_newlines()
        if self.at(TT.LBRACE):
            body = self.parse_block()
        else:
            body = ast.Block([])
        fn = ast.FnDef(name, params, body, return_type=return_type, effects=effects, annotations=annotations or [])
        return fn

    def parse_params(self):
        self._skip_double_minus()
        params = [self.parse_param()]
        while self.at(TT.COMMA):
            self.advance()
            self._skip_double_minus()
            if self.at(TT.RPAREN):
                break
            params.append(self.parse_param())
        return params

    def _skip_double_minus(self):
        if self.at(TT.MINUS) and self.pos + 1 < len(self.tokens) and self.tokens[self.pos + 1].type == TT.MINUS:
            self.advance()
            self.advance()

    def parse_param(self):
        if self.at(TT.SELF):
            self.advance()
            return ast.Param("self")
        is_mut = False
        if self.at(TT.MUT):
            is_mut = True
            self.advance()
        name = self.expect(TT.IDENT).value
        type_name = None
        if self.at(TT.COLON):
            self.advance()
            type_ann = self.parse_type_annotation()
            type_name = type_ann.name
        default = None
        if self.at(TT.EQUALS):
            self.advance()
            self.skip_newlines()
            default = self.parse_expr()
        return ast.Param(name, type_name, default)

    def parse_effect_list(self):
        effects = [self.parse_effect_name()]
        while self.at(TT.COMMA):
            self.advance()
            self.skip_newlines()
            effects.append(self.parse_effect_name())
        return effects

    def parse_effect_name(self):
        name = self.expect(TT.IDENT).value
        while self.at(TT.DOT):
            self.advance()
            name += "." + self.expect(TT.IDENT).value
        return name

    # --- Type Annotations ---

    def parse_type_annotation(self):
        if self.at(TT.LPAREN):
            self.advance()
            if self.at(TT.RPAREN):
                self.advance()
                return ast.TypeAnnotation("Unit", [])
            types = [self.parse_type_annotation()]
            while self.at(TT.COMMA):
                self.advance()
                types.append(self.parse_type_annotation())
            self.expect(TT.RPAREN)
            return ast.TypeAnnotation("Tuple", types)

        if self.at(TT.LBRACKET):
            self.advance()
            inner = self.parse_type_annotation()
            self.expect(TT.RBRACKET)
            return ast.TypeAnnotation("List", [inner])

        name = self.expect(TT.IDENT).value
        while self.at(TT.DOT):
            self.advance()
            name += "." + self.expect(TT.IDENT).value

        params = []
        if self.at(TT.LBRACKET):
            self.advance()
            params = [self.parse_type_annotation()]
            while self.at(TT.COMMA):
                self.advance()
                self.skip_newlines()
                params.append(self.parse_type_annotation())
            self.expect(TT.RBRACKET)

        optional = False
        if self.at(TT.QUESTION):
            self.advance()
            optional = True

        return ast.TypeAnnotation(name, params, optional)

    # --- Block ---

    def parse_block(self):
        self.expect(TT.LBRACE)
        self.skip_newlines()
        stmts = []
        while not self.at(TT.RBRACE):
            stmts.append(self.parse_stmt())
            self.skip_newlines()
        self.expect(TT.RBRACE)
        return ast.Block(stmts)

    # --- Statements ---

    def parse_stmt(self):
        if self.at(TT.WHILE):
            return self.parse_while_loop()
        if self.at(TT.LOOP):
            return self.parse_loop_expr()
        if self.at(TT.BREAK):
            self.advance()
            self.maybe_newline()
            return ast.BreakStmt()
        if self.at(TT.CONTINUE):
            self.advance()
            self.maybe_newline()
            return ast.ContinueStmt()
        if self.at(TT.LET):
            return self.parse_let_binding()
        if self.at(TT.FOR):
            return self.parse_for_in()
        if self.at(TT.WITH):
            return self.parse_with_block()
        if self.at(TT.RETURN):
            return self.parse_return_stmt()
        if self.at(TT.IF):
            node = self.parse_if_expr()
            self.maybe_newline()
            return node
        expr = self.parse_expr()
        if self.at(TT.EQUALS):
            self.advance()
            self.skip_newlines()
            value = self.parse_expr()
            self.maybe_newline()
            return ast.Assignment(expr, value)
        if self.at_any(TT.PLUS_EQ, TT.MINUS_EQ, TT.STAR_EQ, TT.SLASH_EQ):
            op_map = {TT.PLUS_EQ: "+", TT.MINUS_EQ: "-", TT.STAR_EQ: "*", TT.SLASH_EQ: "/"}
            op = op_map[self.advance().type]
            self.skip_newlines()
            value = self.parse_expr()
            self.maybe_newline()
            return ast.CompoundAssignment(op, expr, value)
        self.maybe_newline()
        return ast.ExprStmt(expr)

    def parse_let_binding(self):
        self.expect(TT.LET)
        is_mut = False
        if self.at(TT.MUT):
            is_mut = True
            self.advance()
        if self.at(TT.LPAREN):
            pattern = self.parse_pattern()
            self.expect(TT.EQUALS)
            value = self.parse_expr()
            self.maybe_newline()
            return ast.LetBinding("_tuple", value, is_mut, pattern)
        name = self.expect(TT.IDENT).value
        type_ann = None
        if self.at(TT.COLON):
            self.advance()
            type_ann = self.parse_type_annotation()
        self.expect(TT.EQUALS)
        value = self.parse_expr()
        self.maybe_newline()
        return ast.LetBinding(name, value, is_mut, type_ann=type_ann)

    def parse_return_stmt(self):
        self.expect(TT.RETURN)
        if self.at_any(TT.NEWLINE, TT.RBRACE, TT.EOF):
            self.maybe_newline()
            return ast.ReturnExpr()
        value = self.parse_expr()
        self.maybe_newline()
        return ast.ReturnExpr(value)

    def parse_with_block(self):
        self.expect(TT.WITH)
        handlers = [self.parse_expr()]
        as_binding = None
        if self.at(TT.AS):
            self.advance()
            as_binding = self.expect(TT.IDENT).value
        while self.at(TT.COMMA):
            self.advance()
            self.skip_newlines()
            handlers.append(self.parse_expr())
        self.skip_newlines()
        body = self.parse_block()
        return ast.WithBlock(handlers, body, as_binding)

    # --- Expressions (precedence climbing) ---

    def parse_expr(self):
        return self.parse_coalesce()

    def parse_coalesce(self):
        left = self.parse_pipe()
        while True:
            self.skip_newlines_if_next(TT.DOUBLE_QUESTION)
            if not self.at(TT.DOUBLE_QUESTION):
                break
            self.advance()
            self.skip_newlines()
            if self.at(TT.RETURN):
                right = self.parse_return_expr()
            else:
                right = self.parse_pipe()
            left = ast.BinOp("??", left, right)
        return left

    def parse_pipe(self):
        left = self.parse_or()
        while True:
            self.skip_newlines_if_next(TT.PIPE_ARROW)
            if not self.at(TT.PIPE_ARROW):
                break
            self.advance()
            self.skip_newlines()
            right = self.parse_or()
            left = ast.Call(right, [left])
        return left

    def parse_return_expr(self):
        self.expect(TT.RETURN)
        value = self.parse_expr()
        return ast.ReturnExpr(value)

    def parse_or(self):
        left = self.parse_and()
        while self.at(TT.OR):
            self.advance()
            self.skip_newlines()
            left = ast.BinOp("||", left, self.parse_and())
        return left

    def parse_and(self):
        left = self.parse_equality()
        while self.at(TT.AND):
            self.advance()
            self.skip_newlines()
            left = ast.BinOp("&&", left, self.parse_equality())
        return left

    def parse_equality(self):
        left = self.parse_comparison()
        while self.at_any(TT.EQEQ, TT.NOT_EQ):
            op = self.advance().value
            self.skip_newlines()
            left = ast.BinOp(op, left, self.parse_comparison())
        return left

    def parse_comparison(self):
        left = self.parse_additive()
        while self.at_any(TT.LESS, TT.GREATER, TT.LESS_EQ, TT.GREATER_EQ):
            op = self.advance().value
            self.skip_newlines()
            left = ast.BinOp(op, left, self.parse_additive())
        return left

    def parse_additive(self):
        left = self.parse_multiplicative()
        while self.at_any(TT.PLUS, TT.MINUS):
            op = self.advance().value
            self.skip_newlines()
            left = ast.BinOp(op, left, self.parse_multiplicative())
        return left

    def parse_multiplicative(self):
        left = self.parse_unary()
        while self.at_any(TT.STAR, TT.SLASH, TT.PERCENT):
            op = self.advance().value
            self.skip_newlines()
            left = ast.BinOp(op, left, self.parse_unary())
        return left

    def parse_unary(self):
        if self.at(TT.MINUS):
            self.advance()
            return ast.UnaryOp("-", self.parse_unary())
        if self.at(TT.BANG):
            self.advance()
            return ast.UnaryOp("!", self.parse_unary())
        return self.parse_postfix()

    def parse_postfix(self):
        return self.parse_call_or_primary()

    def parse_call_or_primary(self):
        node = self.parse_primary()
        while True:
            self.skip_newlines_if_next(TT.DOT)
            if self.at(TT.QUESTION):
                self.advance()
                node = ast.UnaryOp("?", node)
                continue
            if not self.at_any(TT.DOT, TT.LPAREN, TT.LBRACKET):
                break
            if self.at(TT.LBRACKET):
                self.advance()
                self.skip_newlines()
                index_expr = self.parse_expr()
                self.skip_newlines()
                self.expect(TT.RBRACKET)
                node = ast.IndexExpr(node, index_expr)
                continue
            if self.at(TT.DOT):
                self.advance()
                if self.at(TT.INT):
                    member = self.advance().value
                    node = ast.FieldAccess(node, member)
                elif self.at(TT.IDENT):
                    member = self.advance().value
                    if self.at(TT.LPAREN):
                        self.advance()
                        args = []
                        if not self.at(TT.RPAREN):
                            args = self.parse_args()
                        self.expect(TT.RPAREN)
                        node = ast.MethodCall(node, member, args)
                    else:
                        node = ast.FieldAccess(node, member)
                        if self.at(TT.LBRACE) and self._looks_like_struct_lit():
                            dotted = self._flatten_field_access(node)
                            if dotted:
                                node = self.parse_struct_lit(dotted)
                else:
                    raise ParseError(f"expected identifier or integer after '.', got {self.peek().type.value}", self.peek())
            else:
                self.advance()
                args = []
                if not self.at(TT.RPAREN):
                    args = self.parse_args()
                self.expect(TT.RPAREN)
                node = ast.Call(node, args)
        return node

    def parse_primary(self):
        if self.at(TT.MATCH):
            return self.parse_match_expr()
        if self.at(TT.IF):
            return self.parse_if_expr()
        if self.at(TT.FN):
            return self.parse_closure()
        if self.at(TT.HANDLER):
            return self.parse_handler_expr()
        if self.at(TT.SELF):
            self.advance()
            return ast.Ident("self")
        if self.at(TT.ASSERT):
            self.advance()
            return ast.Ident("assert")
        if self.at(TT.ASSERT_EQ):
            self.advance()
            return ast.Ident("assert_eq")
        if self.at(TT.ASSERT_NE):
            self.advance()
            return ast.Ident("assert_ne")

        if self.at(TT.IDENT):
            tok = self.advance()
            name = tok.value
            if name in ("true", "false"):
                return ast.BoolLit(name == "true")
            if self.at(TT.LBRACE) and self._looks_like_struct_lit():
                return self.parse_struct_lit(name)
            return ast.Ident(name)

        if self.at(TT.INT):
            tok = self.advance()
            node = ast.IntLit(int(tok.value))
            if self.at(TT.DOTDOT):
                self.advance()
                if self.at(TT.INT):
                    end = ast.IntLit(int(self.advance().value))
                else:
                    end = self.parse_primary()
                return ast.RangeLit(node, end)
            if self.at(TT.DOTDOTEQ):
                self.advance()
                if self.at(TT.INT):
                    end = ast.IntLit(int(self.advance().value))
                else:
                    end = self.parse_primary()
                return ast.RangeLit(node, end, inclusive=True)
            return node

        if self.at(TT.FLOAT):
            return ast.FloatLit(float(self.advance().value))

        if self.at(TT.LPAREN):
            self.advance()
            self.skip_newlines()
            if self.at(TT.RPAREN):
                self.advance()
                return ast.TupleLit([])
            first = self.parse_expr()
            if self.at(TT.COMMA):
                elements = [first]
                while self.at(TT.COMMA):
                    self.advance()
                    self.skip_newlines()
                    if self.at(TT.RPAREN):
                        break
                    elements.append(self.parse_expr())
                self.expect(TT.RPAREN)
                return ast.TupleLit(elements)
            self.skip_newlines()
            self.expect(TT.RPAREN)
            return first

        if self.at(TT.LBRACKET):
            return self.parse_list_lit()

        if self.at(TT.STRING_START):
            return self.parse_interp_string()

        if self.at(TT.LBRACE):
            return self.parse_block_expr()

        raise ParseError(f"unexpected token {self.peek().type.value}", self.peek())

    def _flatten_field_access(self, node):
        if isinstance(node, ast.Ident):
            return node.name
        if isinstance(node, ast.FieldAccess):
            base = self._flatten_field_access(node.obj)
            if base:
                return base + "." + node.field
        return None

    def _looks_like_struct_lit(self):
        saved = self.pos
        try:
            self.expect(TT.LBRACE)
            self.skip_newlines()
            if self.at(TT.RBRACE):
                return True
            if not self.at(TT.IDENT):
                return False
            self.advance()
            return self.at(TT.COLON)
        finally:
            self.pos = saved

    def parse_struct_lit(self, type_name):
        self.expect(TT.LBRACE)
        self.skip_newlines()
        fields = []
        while not self.at(TT.RBRACE):
            fname = self.expect(TT.IDENT).value
            self.expect(TT.COLON)
            self.skip_newlines()
            fvalue = self.parse_expr()
            fields.append(ast.StructLitField(fname, fvalue))
            if self.at(TT.COMMA):
                self.advance()
            self.skip_newlines()
        self.expect(TT.RBRACE)
        return ast.StructLit(type_name, fields)

    def parse_list_lit(self):
        self.expect(TT.LBRACKET)
        self.skip_newlines()
        elements = []
        while not self.at(TT.RBRACKET):
            elements.append(self.parse_expr())
            if self.at(TT.COMMA):
                self.advance()
            self.skip_newlines()
        self.expect(TT.RBRACKET)
        return ast.ListLit(elements)

    def parse_block_expr(self):
        if self._looks_like_anon_struct():
            return self.parse_struct_lit("_Anon")
        block = self.parse_block()
        if len(block.stmts) == 1 and isinstance(block.stmts[0], ast.ExprStmt):
            return block.stmts[0].expr
        return block

    def _looks_like_anon_struct(self):
        saved = self.pos
        try:
            self.expect(TT.LBRACE)
            self.skip_newlines()
            if not self.at(TT.IDENT):
                return False
            self.advance()
            return self.at(TT.COLON)
        finally:
            self.pos = saved

    def parse_closure(self):
        self.expect(TT.FN)
        self.expect(TT.LPAREN)
        params = []
        if not self.at(TT.RPAREN):
            params = self.parse_params()
        self.expect(TT.RPAREN)
        if self.at(TT.ARROW):
            self.advance()
            self.parse_type_annotation()
        self.skip_newlines()
        body = self.parse_block()
        return ast.Closure(params, body)

    def parse_handler_expr(self):
        self.expect(TT.HANDLER)
        effect = self.parse_effect_name()
        self.skip_newlines()
        self.expect(TT.LBRACE)
        self.skip_newlines()
        methods = []
        while not self.at(TT.RBRACE):
            methods.append(self.parse_fn_def([]))
            self.skip_newlines()
        self.expect(TT.RBRACE)
        return ast.HandlerExpr(effect, methods)

    def parse_if_expr(self):
        self.expect(TT.IF)
        condition = self.parse_expr()
        self.skip_newlines()
        then_body = self.parse_block()
        else_body = None
        self.skip_newlines()
        if self.at(TT.ELSE):
            self.advance()
            self.skip_newlines()
            if self.at(TT.IF):
                inner = self.parse_if_expr()
                else_body = ast.Block([inner])
            else:
                else_body = self.parse_block()
        return ast.IfExpr(condition, then_body, else_body)

    # --- Match ---

    def parse_match_expr(self):
        self.expect(TT.MATCH)
        scrutinee = self.parse_expr()
        self.skip_newlines()
        self.expect(TT.LBRACE)
        self.skip_newlines()
        arms = []
        while not self.at(TT.RBRACE):
            arms.append(self.parse_match_arm())
            self.skip_newlines()
        self.expect(TT.RBRACE)
        return ast.MatchExpr(scrutinee, arms)

    def parse_match_arm(self):
        pattern = self.parse_pattern()
        guard = None
        self.skip_newlines()
        if self.at(TT.IF):
            self.advance()
            guard = self.parse_expr()
        self.skip_newlines()
        self.expect(TT.FAT_ARROW)
        self.skip_newlines()
        if self.at(TT.LBRACE):
            body = self.parse_block_expr()
        else:
            body = self.parse_stmt()
            if isinstance(body, ast.ExprStmt):
                body = body.expr
        return ast.MatchArm(pattern, body, guard)

    # --- Patterns ---

    def parse_pattern(self):
        first = self._parse_single_pattern()
        if self.at(TT.PIPE):
            alternatives = [first]
            while self.at(TT.PIPE):
                self.advance()
                self.skip_newlines()
                alternatives.append(self._parse_single_pattern())
            first = ast.OrPattern(alternatives)
        if self.at(TT.AS):
            self.advance()
            inner = self._parse_single_pattern()
            if isinstance(first, ast.IdentPattern):
                return ast.AsPattern(first.name, inner)
            return ast.AsPattern("_", inner)
        return first

    def _parse_single_pattern(self):
        if self.at(TT.LPAREN):
            self.advance()
            self.skip_newlines()
            elements = [self.parse_pattern()]
            while self.at(TT.COMMA):
                self.advance()
                self.skip_newlines()
                elements.append(self.parse_pattern())
            self.skip_newlines()
            self.expect(TT.RPAREN)
            return ast.TuplePattern(elements)
        if self.at(TT.INT):
            val = int(self.advance().value)
            if self.at(TT.DOTDOT):
                self.advance()
                end = int(self.expect(TT.INT).value)
                return ast.RangePattern(val, end, inclusive=False)
            if self.at(TT.DOTDOTEQ):
                self.advance()
                end = int(self.expect(TT.INT).value)
                return ast.RangePattern(val, end, inclusive=True)
            return ast.IntPattern(val)
        if self.at(TT.FLOAT):
            return ast.IntPattern(float(self.advance().value))
        if self.at(TT.STRING_START):
            s = self.parse_interp_string()
            if isinstance(s, ast.InterpString) and all(isinstance(p, str) for p in s.parts):
                return ast.StringPattern("".join(s.parts))
            return ast.StringPattern(str(s))
        if self.at(TT.IDENT):
            name = self.advance().value
            if name == "_":
                return ast.WildcardPattern()
            while self.at(TT.DOT):
                self.advance()
                name += "." + self.expect(TT.IDENT).value
            if self.at(TT.LBRACE):
                self.advance()
                self.skip_newlines()
                fields = []
                rest = False
                while not self.at(TT.RBRACE):
                    if self.at(TT.DOTDOT):
                        self.advance()
                        rest = True
                        self.skip_newlines()
                        break
                    field_name = self.expect(TT.IDENT).value
                    if self.at(TT.COLON):
                        self.advance()
                        self.skip_newlines()
                        pat = self.parse_pattern()
                        fields.append(ast.StructPatternField(field_name, pat))
                    else:
                        fields.append(ast.StructPatternField(field_name))
                    if self.at(TT.COMMA):
                        self.advance()
                        self.skip_newlines()
                self.expect(TT.RBRACE)
                return ast.StructPattern(name, fields, rest)
            if self.at(TT.LPAREN):
                self.advance()
                self.skip_newlines()
                fields = []
                if not self.at(TT.RPAREN):
                    fields.append(self.parse_pattern())
                    while self.at(TT.COMMA):
                        self.advance()
                        self.skip_newlines()
                        fields.append(self.parse_pattern())
                self.skip_newlines()
                self.expect(TT.RPAREN)
                return ast.EnumPattern(name, fields)
            return ast.IdentPattern(name)
        raise ParseError(f"unexpected token in pattern: {self.peek().type.value}", self.peek())

    # --- For-in ---

    def parse_for_in(self):
        self.expect(TT.FOR)
        pattern = None
        if self.at(TT.LPAREN):
            pattern = self.parse_pattern()
            var_name = "_tuple"
        else:
            var_name = self.expect(TT.IDENT).value
        self.expect(TT.IN)
        iterable = self.parse_expr()
        self.skip_newlines()
        body = self.parse_block()
        return ast.ForIn(var_name, iterable, body, pattern)

    def parse_while_loop(self):
        self.expect(TT.WHILE)
        condition = self.parse_expr()
        self.skip_newlines()
        body = self.parse_block()
        return ast.WhileLoop(condition, body)

    def parse_loop_expr(self):
        self.expect(TT.LOOP)
        self.skip_newlines()
        body = self.parse_block()
        return ast.LoopExpr(body)

    # --- Strings ---

    def parse_interp_string(self):
        self.expect(TT.STRING_START)
        parts = []
        while not self.at(TT.STRING_END):
            if self.at(TT.STRING_PART):
                parts.append(self.advance().value)
            elif self.at(TT.INTERP_START):
                self.advance()
                parts.append(self.parse_expr())
                self.expect(TT.INTERP_END)
            else:
                raise ParseError(f"unexpected token in string: {self.peek().type.value}", self.peek())
        self.expect(TT.STRING_END)
        return ast.InterpString(parts)

    # --- Arguments ---

    def parse_args(self):
        self.skip_newlines()
        self._skip_named_arg_label()
        args = [self.parse_expr()]
        while self.at(TT.COMMA):
            self.advance()
            self.skip_newlines()
            if self.at(TT.RPAREN):
                break
            self._skip_named_arg_label()
            args.append(self.parse_expr())
        self.skip_newlines()
        if not self.at(TT.RPAREN):
            self._skip_named_arg_label()
            args.append(self.parse_expr())
            while self.at(TT.COMMA):
                self.advance()
                self.skip_newlines()
                if self.at(TT.RPAREN):
                    break
                self._skip_named_arg_label()
                args.append(self.parse_expr())
            self.skip_newlines()
        return args

    def _skip_named_arg_label(self):
        if self.at(TT.IDENT) and self.pos + 1 < len(self.tokens) and self.tokens[self.pos + 1].type == TT.COLON:
            self.advance()
            self.advance()
            self.skip_newlines()


def parse(token_list: list[tokens.Token]) -> ast.Program:
    return Parser(token_list).parse_program()
