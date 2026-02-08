import enum
import os

import pact.ast_nodes as ast


class CType(enum.Enum):
    INT = "int64_t"
    FLOAT = "double"
    BOOL = "int"
    STRING = "const char*"
    LIST = "pact_list*"
    VOID = "void"


_ARITHMETIC_OPS = {"+", "-", "*", "/", "%"}
_COMPARISON_OPS = {"==", "!=", "<", ">", "<=", ">="}
_LOGICAL_OPS = {"&&", "||"}

_TYPE_MAP = {
    "Int": CType.INT,
    "Str": CType.STRING,
    "Float": CType.FLOAT,
    "Bool": CType.BOOL,
    "List": CType.LIST,
}

_PRINTF_SPECS = {
    CType.INT: ('%lld', lambda e: f'(long long){e}'),
    CType.FLOAT: ('%g', lambda e: e),
    CType.STRING: ('%s', lambda e: e),
    CType.BOOL: ('%s', lambda e: f'{e} ? "true" : "false"'),
}


class CCodeGen:
    def __init__(self):
        self.lines = []
        self.indent = 0
        self.scopes = [{}]
        self.fn_registry = {
            'get_arg': (CType.STRING, [CType.INT]),
            'arg_count': (CType.INT, []),
            'read_file': (CType.STRING, [CType.STRING]),
            'int_to_str': (CType.STRING, [CType.INT]),
        }
        self.temp_counter = 0
        self.struct_registry = {}
        self.var_struct = {}
        self._field_annotations = {}
        self.var_list_elem_type = {}
        self._global_init_lines = []

    def _get_runtime_preamble(self) -> str:
        runtime_path = os.path.join(os.path.dirname(__file__), 'runtime.h')
        with open(runtime_path) as f:
            return f.read()

    def generate(self, program: ast.Program) -> str:
        self.lines = [
            self._get_runtime_preamble(),
            '',
        ]

        for td in program.types:
            if td.variants:
                continue
            self._emit_struct_typedef(td)

        emitted_lets = set()
        for let_binding in program.top_lets:
            if let_binding.name not in emitted_lets:
                self._emit_top_level_let(let_binding)
                emitted_lets.add(let_binding.name)
        if program.top_lets:
            self._emit('')

        emitted_fns = set()
        for fn_def in program.functions:
            if fn_def.name not in emitted_fns:
                ret = self._type_from_annotation(fn_def.return_type)
                param_types = [self._type_from_param(p) for p in fn_def.params]
                self.fn_registry[fn_def.name] = (ret, param_types)
                emitted_fns.add(fn_def.name)

        emitted_fns.clear()
        for fn_def in program.functions:
            if fn_def.name not in emitted_fns:
                self._emit_fn_decl(fn_def)
                emitted_fns.add(fn_def.name)
        self._emit('')

        emitted_fns.clear()
        for fn_def in program.functions:
            if fn_def.name not in emitted_fns:
                self._emit_fn_def(fn_def)
                self._emit('')
                emitted_fns.add(fn_def.name)

        if self._global_init_lines:
            self._emit('static void __pact_init_globals(void) {')
            for line in self._global_init_lines:
                self.lines.append(line)
            self._emit('}')
            self._emit('')

        self._emit('int main(int argc, char** argv) {')
        self.indent += 1
        self._emit('pact_g_argc = argc;')
        self._emit('pact_g_argv = (const char**)argv;')
        if self._global_init_lines:
            self._emit('__pact_init_globals();')
        self._emit('pact_main();')
        self._emit('return 0;')
        self.indent -= 1
        self._emit('}')

        return '\n'.join(self.lines)

    def _emit_top_level_let(self, stmt: ast.LetBinding):
        saved_lines = self.lines
        self.lines = []
        expr_str, ctype = self._emit_expr(stmt.value)
        helper_lines = self.lines
        self.lines = saved_lines

        self._set_var(stmt.name, ctype, is_mut=stmt.is_mut)
        if ctype == CType.LIST and stmt.type_ann and stmt.type_ann.name == 'List' and stmt.type_ann.params:
            elem_type_name = stmt.type_ann.params[0].name
            self.var_list_elem_type[stmt.name] = _TYPE_MAP.get(elem_type_name, CType.INT)

        needs_runtime_init = len(helper_lines) > 0 or ctype == CType.LIST

        if needs_runtime_init:
            c_type_s = self._c_type_str(ctype)
            self._emit(f'static {c_type_s} {stmt.name};')
            for hl in helper_lines:
                self._global_init_lines.append(hl)
            self._global_init_lines.append(f'    {stmt.name} = {expr_str};')
        elif stmt.is_mut:
            self._emit(f'static {self._c_type_str(ctype)} {stmt.name} = {expr_str};')
        else:
            self._emit(f'static const {self._c_type_str(ctype)} {stmt.name} = {expr_str};')

    def _emit_struct_typedef(self, td: ast.TypeDef):
        fields = {}
        for f in td.fields:
            ctype = self._type_from_annotation(f.type_ann)
            fields[f.name] = ctype
            self._field_annotations[(td.name, f.name)] = f.type_ann
        self.struct_registry[td.name] = fields

        self._emit(f'typedef struct {{')
        self.indent += 1
        for f in td.fields:
            ctype = fields[f.name]
            if f.type_ann and f.type_ann.name == td.name:
                self._emit(f'int64_t {f.name};')
            elif f.type_ann and f.type_ann.name in self.struct_registry:
                self._emit(f'pact_{f.type_ann.name} {f.name};')
            else:
                self._emit(f'{self._c_type_str(ctype)} {f.name};')
        self.indent -= 1
        self._emit(f'}} pact_{td.name};')
        self._emit('')

    def _c_struct_type_str(self, struct_name: str) -> str:
        return f'pact_{struct_name}'

    def _type_from_annotation(self, ann) -> CType:
        if ann is None:
            return CType.VOID
        return _TYPE_MAP.get(ann.name, CType.VOID)

    def _type_from_param(self, param: ast.Param) -> CType:
        if param.type_name is None:
            return CType.VOID
        return _TYPE_MAP.get(param.type_name, CType.VOID)

    def _c_type_str(self, ctype: CType) -> str:
        return ctype.value

    def _emit(self, line: str):
        if line == '':
            self.lines.append('')
        else:
            self.lines.append('    ' * self.indent + line)

    def _push_scope(self):
        self.scopes.append({})

    def _pop_scope(self):
        self.scopes.pop()

    def _set_var(self, name: str, ctype: CType, is_mut: bool = False):
        self.scopes[-1][name] = (ctype, is_mut)

    def _get_var(self, name: str) -> tuple[CType, bool]:
        for scope in reversed(self.scopes):
            if name in scope:
                return scope[name]
        return (CType.INT, False)

    def _fresh_temp(self, prefix: str = "_t") -> str:
        name = f'{prefix}{self.temp_counter}'
        self.temp_counter += 1
        return name

    def _emit_fn_decl(self, fn_def: ast.FnDef):
        if fn_def.name == 'main':
            self._emit('void pact_main(void);')
            return
        ret = self._c_type_str(self.fn_registry[fn_def.name][0])
        params = self._format_params(fn_def)
        self._emit(f'{ret} pact_{fn_def.name}({params});')

    def _emit_fn_def(self, fn_def: ast.FnDef):
        self._push_scope()
        self.temp_counter = 0
        if fn_def.name == 'main':
            sig = 'void pact_main(void)'
            ret_type = CType.VOID
        else:
            ret_type = self.fn_registry[fn_def.name][0]
            ret = self._c_type_str(ret_type)
            params = self._format_params(fn_def)
            sig = f'{ret} pact_{fn_def.name}({params})'

        for i, p in enumerate(fn_def.params):
            ctype = self._type_from_param(p)
            self._set_var(p.name, ctype, is_mut=True)
            if p.type_name and p.type_name in self.struct_registry:
                self.var_struct[p.name] = p.type_name

        self._emit(f'{sig} {{')
        self.indent += 1
        self._emit_fn_body(fn_def.body, ret_type)
        self.indent -= 1
        self._emit('}')
        self._pop_scope()

    def _format_params(self, fn_def: ast.FnDef) -> str:
        if not fn_def.params:
            return 'void'
        parts = []
        for p in fn_def.params:
            if p.type_name and p.type_name in self.struct_registry:
                parts.append(f'{self._c_struct_type_str(p.type_name)} {p.name}')
            else:
                ctype = self._type_from_param(p)
                parts.append(f'{self._c_type_str(ctype)} {p.name}')
        return ', '.join(parts)

    def _emit_fn_body(self, block: ast.Block, ret_type: CType):
        if not block.stmts:
            return
        for stmt in block.stmts[:-1]:
            self._emit_stmt(stmt)
        last = block.stmts[-1]
        if ret_type != CType.VOID and isinstance(last, ast.ExprStmt):
            expr_str, _ = self._emit_expr(last.expr)
            self._emit(f'return {expr_str};')
        elif ret_type != CType.VOID and isinstance(last, ast.IfExpr):
            expr_str, _ = self._emit_if_expr(last)
            self._emit(f'return {expr_str};')
        else:
            self._emit_stmt(last)

    def _emit_block(self, block: ast.Block):
        for stmt in block.stmts:
            self._emit_stmt(stmt)

    def _emit_stmt(self, stmt):
        match stmt:
            case ast.ExprStmt():
                expr_str, _ = self._emit_expr(stmt.expr)
                if expr_str and expr_str != '0':
                    self._emit(f'{expr_str};')
            case ast.LetBinding():
                self._emit_let_binding(stmt)
            case ast.Assignment():
                target_str, _ = self._emit_expr(stmt.target)
                val_str, _ = self._emit_expr(stmt.value)
                self._emit(f'{target_str} = {val_str};')
            case ast.CompoundAssignment():
                target_str, _ = self._emit_expr(stmt.target)
                val_str, _ = self._emit_expr(stmt.value)
                self._emit(f'{target_str} {stmt.op}= {val_str};')
            case ast.ReturnExpr():
                if stmt.value is not None:
                    val_str, _ = self._emit_expr(stmt.value)
                    self._emit(f'return {val_str};')
                else:
                    self._emit('return;')
            case ast.ForIn():
                self._emit_for_in(stmt)
            case ast.WhileLoop():
                cond_str, _ = self._emit_expr(stmt.condition)
                self._emit(f'while ({cond_str}) {{')
                self.indent += 1
                self._emit_block(stmt.body)
                self.indent -= 1
                self._emit('}')
            case ast.LoopExpr():
                self._emit('while (1) {')
                self.indent += 1
                self._emit_block(stmt.body)
                self.indent -= 1
                self._emit('}')
            case ast.BreakStmt():
                self._emit('break;')
            case ast.ContinueStmt():
                self._emit('continue;')
            case ast.IfExpr():
                self._emit_if_stmt(stmt)
            case ast.MatchExpr():
                self._emit_expr(stmt)
            case _:
                expr_str, _ = self._emit_expr(stmt)
                if expr_str:
                    self._emit(f'{expr_str};')

    def _emit_let_binding(self, stmt: ast.LetBinding):
        if isinstance(stmt.value, ast.StructLit) and stmt.value.type_name in self.struct_registry:
            tmp_name = self._emit_struct_lit(stmt.value)
            struct_name = stmt.value.type_name
            self._set_var(stmt.name, CType.VOID, is_mut=stmt.is_mut)
            self.var_struct[stmt.name] = struct_name
            c_type = self._c_struct_type_str(struct_name)
            qualifier = '' if stmt.is_mut else 'const '
            self._emit(f'{qualifier}{c_type} {stmt.name} = {tmp_name};')
            return

        expr_str, ctype = self._emit_expr(stmt.value)
        if stmt.type_ann and stmt.type_ann.name == 'Str' and ctype != CType.STRING:
            ctype = CType.STRING
        self._set_var(stmt.name, ctype, is_mut=stmt.is_mut)
        if ctype == CType.LIST and stmt.type_ann and stmt.type_ann.name == 'List' and stmt.type_ann.params:
            elem_type_name = stmt.type_ann.params[0].name
            self.var_list_elem_type[stmt.name] = _TYPE_MAP.get(elem_type_name, CType.INT)
        c_type_s = self._c_type_str(ctype)
        if stmt.is_mut or c_type_s.startswith('const '):
            self._emit(f'{c_type_s} {stmt.name} = {expr_str};')
        else:
            self._emit(f'const {c_type_s} {stmt.name} = {expr_str};')

    def _emit_struct_lit(self, node: ast.StructLit) -> str:
        struct_name = node.type_name
        c_type = self._c_struct_type_str(struct_name)
        tmp = self._fresh_temp('_s')

        field_inits = []
        for sf in node.fields:
            val_str, _ = self._emit_expr(sf.value)
            field_inits.append(f'.{sf.name} = {val_str}')

        inits = ', '.join(field_inits)
        self._emit(f'{c_type} {tmp} = {{ {inits} }};')
        self.var_struct[tmp] = struct_name
        return tmp

    def _emit_field_access(self, node: ast.FieldAccess) -> tuple[str, CType]:
        obj_str, _ = self._emit_expr(node.obj)
        struct_name = self._resolve_obj_struct(node.obj)

        if struct_name and struct_name in self.struct_registry:
            fields = self.struct_registry[struct_name]
            if node.field in fields:
                field_ctype = fields[node.field]
                field_ann = self._field_annotations.get((struct_name, node.field))
                if field_ann and field_ann.name in self.struct_registry:
                    return (f'{obj_str}.{node.field}', CType.VOID)
                return (f'{obj_str}.{node.field}', field_ctype)

        return (f'{obj_str}.{node.field}', CType.VOID)

    def _resolve_obj_struct(self, node) -> str | None:
        if isinstance(node, ast.Ident):
            return self.var_struct.get(node.name)
        if isinstance(node, ast.FieldAccess):
            parent_struct = self._resolve_obj_struct(node.obj)
            if parent_struct and parent_struct in self.struct_registry:
                field_ann = self._field_annotations.get((parent_struct, node.field))
                if field_ann and field_ann.name in self.struct_registry:
                    return field_ann.name
        return None

    def _emit_for_in(self, stmt: ast.ForIn):
        if isinstance(stmt.iterable, ast.RangeLit):
            r = stmt.iterable
            start_str, _ = self._emit_expr(r.start)
            end_str, _ = self._emit_expr(r.end)
            op = '<=' if r.inclusive else '<'
            self._emit(f'for (int64_t {stmt.var_name} = {start_str}; {stmt.var_name} {op} {end_str}; {stmt.var_name}++) {{')
            self._push_scope()
            self._set_var(stmt.var_name, CType.INT, is_mut=True)
            self.indent += 1
            self._emit_block(stmt.body)
            self.indent -= 1
            self._pop_scope()
            self._emit('}')
        else:
            iterable_str, it_type = self._emit_expr(stmt.iterable)
            if it_type == CType.LIST:
                idx = self._fresh_temp('_i')
                self._emit(f'for (int64_t {idx} = 0; {idx} < pact_list_len({iterable_str}); {idx}++) {{')
                self._push_scope()
                self._emit(f'    int64_t {stmt.var_name} = (int64_t)(intptr_t)pact_list_get({iterable_str}, {idx});')
                self._set_var(stmt.var_name, CType.INT)
                self.indent += 1
                self._emit_block(stmt.body)
                self.indent -= 1
                self._pop_scope()
                self._emit('}')
            else:
                self._emit(f'/* unsupported iterable: {iterable_str} */')

    def _emit_if_stmt(self, stmt: ast.IfExpr):
        cond_str, _ = self._emit_expr(stmt.condition)
        self._emit(f'if ({cond_str}) {{')
        self.indent += 1
        self._emit_block(stmt.then_body)
        self.indent -= 1
        if stmt.else_body is not None:
            if (len(stmt.else_body.stmts) == 1
                    and isinstance(stmt.else_body.stmts[0], ast.IfExpr)):
                inner = stmt.else_body.stmts[0]
                saved = self.lines
                self.lines = []
                inner_cond, _ = self._emit_expr(inner.condition)
                hoisted = self.lines
                self.lines = saved
                if hoisted:
                    self._emit('} else {')
                    self.indent += 1
                    self._emit_if_stmt(inner)
                    self.indent -= 1
                else:
                    self._emit(f'}} else if ({inner_cond}) {{')
                    self.indent += 1
                    self._emit_block(inner.then_body)
                    self.indent -= 1
                    if inner.else_body is not None:
                        self._emit('} else {')
                        self.indent += 1
                        self._emit_block(inner.else_body)
                        self.indent -= 1
            else:
                self._emit('} else {')
                self.indent += 1
                self._emit_block(stmt.else_body)
                self.indent -= 1
        self._emit('}')

    def _emit_expr(self, node) -> tuple[str, CType]:
        match node:
            case ast.IntLit():
                return (str(node.value), CType.INT)
            case ast.FloatLit():
                return (repr(node.value), CType.FLOAT)
            case ast.BoolLit():
                return ('1' if node.value else '0', CType.BOOL)
            case ast.Ident():
                ctype, _ = self._get_var(node.name)
                return (node.name, ctype)
            case ast.BinOp():
                return self._emit_binop(node)
            case ast.UnaryOp():
                return self._emit_unaryop(node)
            case ast.Call():
                return self._emit_call(node)
            case ast.MethodCall():
                return self._emit_method_call(node)
            case ast.InterpString():
                return self._emit_interp_string(node)
            case ast.TupleLit():
                return self._emit_tuple_lit(node)
            case ast.ListLit():
                return self._emit_list_lit(node)
            case ast.IfExpr():
                return self._emit_if_expr(node)
            case ast.IndexExpr():
                return self._emit_index_expr(node)
            case ast.MatchExpr():
                return self._emit_match_expr(node)
            case ast.Block():
                return self._emit_block_expr(node)
            case ast.RangeLit():
                return ('0', CType.VOID)
            case ast.StructLit():
                tmp = self._emit_struct_lit(node)
                return (tmp, CType.VOID)
            case ast.FieldAccess():
                return self._emit_field_access(node)
            case ast.ReturnExpr():
                if node.value is not None:
                    val_str, _ = self._emit_expr(node.value)
                    self._emit(f'return {val_str};')
                else:
                    self._emit('return;')
                return ('0', CType.VOID)
            case _:
                return ('0', CType.VOID)

    def _emit_binop(self, node: ast.BinOp) -> tuple[str, CType]:
        left_str, left_type = self._emit_expr(node.left)
        right_str, right_type = self._emit_expr(node.right)
        op = node.op
        if op == '==' and left_type == CType.STRING and right_type == CType.STRING:
            return (f'pact_str_eq({left_str}, {right_str})', CType.BOOL)
        if op == '!=' and left_type == CType.STRING and right_type == CType.STRING:
            return (f'(!pact_str_eq({left_str}, {right_str}))', CType.BOOL)
        if op == '+' and (left_type == CType.STRING or right_type == CType.STRING):
            return (f'pact_str_concat({left_str}, {right_str})', CType.STRING)
        expr = f'({left_str} {op} {right_str})'
        if op in _COMPARISON_OPS or op in _LOGICAL_OPS:
            return (expr, CType.BOOL)
        return (expr, left_type)

    def _emit_unaryop(self, node: ast.UnaryOp) -> tuple[str, CType]:
        operand_str, operand_type = self._emit_expr(node.operand)
        if node.op == '-':
            return (f'(-{operand_str})', operand_type)
        if node.op == '!':
            return (f'(!{operand_str})', CType.BOOL)
        return (f'({node.op}{operand_str})', operand_type)

    def _emit_call(self, node: ast.Call) -> tuple[str, CType]:
        if isinstance(node.func, ast.Ident):
            fn_name = node.func.name
            arg_parts = []
            for a in node.args:
                a_str, _ = self._emit_expr(a)
                arg_parts.append(a_str)
            args_str = ', '.join(arg_parts)
            ret_type = CType.VOID
            if fn_name in self.fn_registry:
                ret_type = self.fn_registry[fn_name][0]
            return (f'pact_{fn_name}({args_str})', ret_type)
        func_str, _ = self._emit_expr(node.func)
        arg_parts = []
        for a in node.args:
            a_str, _ = self._emit_expr(a)
            arg_parts.append(a_str)
        args_str = ', '.join(arg_parts)
        return (f'{func_str}({args_str})', CType.VOID)

    def _emit_method_call(self, node: ast.MethodCall) -> tuple[str, CType]:
        if isinstance(node.obj, ast.Ident) and node.obj.name == 'io' and node.method == 'println':
            if node.args:
                arg_str, arg_type = self._emit_expr(node.args[0])
                spec, arg_fn = _PRINTF_SPECS.get(arg_type, ('%s', lambda e: e))
                self._emit(f'printf("{spec}\\n", {arg_fn(arg_str)});')
            else:
                self._emit('printf("\\n");')
            return ('0', CType.VOID)
        obj_str, obj_type = self._emit_expr(node.obj)
        if obj_type == CType.LIST:
            return self._emit_list_method(obj_str, node.method, node.args)
        if obj_type == CType.STRING:
            return self._emit_string_method(obj_str, node.method, node.args)
        arg_parts = []
        for a in node.args:
            a_str, _ = self._emit_expr(a)
            arg_parts.append(a_str)
        args_str = ', '.join(arg_parts)
        return (f'{obj_str}_{node.method}({args_str})', CType.VOID)

    def _emit_index_expr(self, node: ast.IndexExpr) -> tuple[str, CType]:
        obj_str, obj_type = self._emit_expr(node.obj)
        idx_str, _ = self._emit_expr(node.index)
        if obj_type == CType.STRING:
            return (f'pact_str_char_at({obj_str}, {idx_str})', CType.INT)
        return (f'{obj_str}[{idx_str}]', CType.INT)

    def _emit_string_method(self, obj_str: str, method: str, args: list) -> tuple[str, CType]:
        if method == 'len':
            return (f'pact_str_len({obj_str})', CType.INT)
        if method in ('char_at', 'charAt'):
            arg_str, _ = self._emit_expr(args[0])
            return (f'pact_str_char_at({obj_str}, {arg_str})', CType.INT)
        if method in ('substring', 'substr'):
            start_str, _ = self._emit_expr(args[0])
            len_str, _ = self._emit_expr(args[1])
            return (f'pact_str_substr({obj_str}, {start_str}, {len_str})', CType.STRING)
        if method == 'contains':
            arg_str, _ = self._emit_expr(args[0])
            return (f'pact_str_contains({obj_str}, {arg_str})', CType.BOOL)
        if method == 'starts_with':
            arg_str, _ = self._emit_expr(args[0])
            return (f'pact_str_starts_with({obj_str}, {arg_str})', CType.BOOL)
        if method == 'concat':
            arg_str, _ = self._emit_expr(args[0])
            return (f'pact_str_concat({obj_str}, {arg_str})', CType.STRING)
        if method == 'trim':
            return (f'/* TODO: pact_str_trim({obj_str}) */ {obj_str}', CType.STRING)
        arg_parts = []
        for a in args:
            a_str, _ = self._emit_expr(a)
            arg_parts.append(a_str)
        args_str = ', '.join(arg_parts)
        return (f'{obj_str}_{method}({args_str})', CType.VOID)

    def _emit_list_lit(self, node: ast.ListLit) -> tuple[str, CType]:
        tmp = self._fresh_temp('_l')
        self._emit(f'pact_list* {tmp} = pact_list_new();')
        for elem in node.elements:
            expr_str, expr_type = self._emit_expr(elem)
            if expr_type == CType.INT:
                self._emit(f'pact_list_push({tmp}, (void*)(intptr_t){expr_str});')
            else:
                self._emit(f'pact_list_push({tmp}, (void*){expr_str});')
        return (tmp, CType.LIST)

    def _emit_list_method(self, obj_str: str, method: str, args: list) -> tuple[str, CType]:
        elem_type = self.var_list_elem_type.get(obj_str, CType.INT)
        if method == 'push' and args:
            val_str, val_type = self._emit_expr(args[0])
            if val_type == CType.INT:
                self._emit(f'pact_list_push({obj_str}, (void*)(intptr_t){val_str});')
            else:
                self._emit(f'pact_list_push({obj_str}, (void*){val_str});')
            return ('0', CType.VOID)
        if method == 'pop':
            self._emit(f'pact_list_pop({obj_str});')
            return ('0', CType.VOID)
        if method == 'len':
            return (f'pact_list_len({obj_str})', CType.INT)
        if method == 'get' and args:
            idx_str, _ = self._emit_expr(args[0])
            if elem_type == CType.STRING:
                return (f'(const char*)pact_list_get({obj_str}, {idx_str})', CType.STRING)
            return (f'(int64_t)(intptr_t)pact_list_get({obj_str}, {idx_str})', CType.INT)
        if method == 'set' and len(args) == 2:
            idx_str, _ = self._emit_expr(args[0])
            val_str, val_type = self._emit_expr(args[1])
            if val_type == CType.INT:
                self._emit(f'pact_list_set({obj_str}, {idx_str}, (void*)(intptr_t){val_str});')
            else:
                self._emit(f'pact_list_set({obj_str}, {idx_str}, (void*){val_str});')
            return ('0', CType.VOID)
        return (f'{obj_str}_{method}()', CType.VOID)

    def _emit_interp_string(self, node: ast.InterpString) -> tuple[str, CType]:
        if all(isinstance(p, str) for p in node.parts):
            escaped = _escape_c_string(''.join(node.parts))
            return (f'"{escaped}"', CType.STRING)

        buf_name = self._fresh_temp('_si_')
        self._emit(f'char {buf_name}[4096];')
        fmt_parts = []
        arg_parts = []
        for p in node.parts:
            if isinstance(p, str):
                fmt_parts.append(_escape_c_string(p))
            else:
                expr_str, expr_type = self._emit_expr(p)
                spec, arg_fn = _PRINTF_SPECS.get(expr_type, ('%s', lambda e: e))
                fmt_parts.append(spec)
                arg_parts.append(arg_fn(expr_str))
        fmt = ''.join(fmt_parts)
        if arg_parts:
            args = ', '.join(arg_parts)
            self._emit(f'snprintf({buf_name}, 4096, "{fmt}", {args});')
        else:
            self._emit(f'snprintf({buf_name}, 4096, "{fmt}");')
        return (f'strdup({buf_name})', CType.STRING)

    def _emit_tuple_lit(self, node: ast.TupleLit) -> tuple[str, CType]:
        temps = []
        for i, elem in enumerate(node.elements):
            expr_str, expr_type = self._emit_expr(elem)
            tmp = self._fresh_temp('_tup_')
            self._emit(f'{self._c_type_str(expr_type)} {tmp} = {expr_str};')
            self._set_var(tmp, expr_type, is_mut=True)
            temps.append((tmp, expr_type))
        if temps:
            return (temps[0][0], temps[0][1])
        return ('0', CType.VOID)

    def _emit_if_expr(self, node: ast.IfExpr) -> tuple[str, CType]:
        then_type = self._infer_block_type(node.then_body)
        tmp = self._fresh_temp('_if_')
        self._emit(f'{self._c_type_str(then_type)} {tmp};')
        cond_str, _ = self._emit_expr(node.condition)
        self._emit(f'if ({cond_str}) {{')
        self.indent += 1
        then_val = self._emit_block_value(node.then_body)
        self._emit(f'{tmp} = {then_val};')
        self.indent -= 1
        if node.else_body is not None:
            self._emit('} else {')
            self.indent += 1
            else_val = self._emit_block_value(node.else_body)
            self._emit(f'{tmp} = {else_val};')
            self.indent -= 1
        self._emit('}')
        self._set_var(tmp, then_type, is_mut=True)
        return (tmp, then_type)

    def _emit_match_expr(self, node: ast.MatchExpr) -> tuple[str, CType]:
        tup_vars = []
        if isinstance(node.scrutinee, ast.TupleLit):
            for i, elem in enumerate(node.scrutinee.elements):
                expr_str, expr_type = self._emit_expr(elem)
                tmp = self._fresh_temp('_tup_')
                self._emit(f'{self._c_type_str(expr_type)} {tmp} = {expr_str};')
                self._set_var(tmp, expr_type, is_mut=True)
                tup_vars.append((tmp, expr_type))
        else:
            expr_str, expr_type = self._emit_expr(node.scrutinee)
            tup_vars.append((expr_str, expr_type))

        result_type = self._infer_arm_type(node.arms[0])
        result_var = self._fresh_temp('_match_')
        self._emit(f'{self._c_type_str(result_type)} {result_var};')

        first = True
        for arm in node.arms:
            cond = self._pattern_condition(arm.pattern, tup_vars)
            is_wildcard = cond is None

            if is_wildcard:
                if first:
                    self._emit('{')
                else:
                    self._emit('} else {')
            elif first:
                self._emit(f'if ({cond}) {{')
            else:
                self._emit(f'}} else if ({cond}) {{')

            self.indent += 1
            self._bind_pattern_vars(arm.pattern, tup_vars)
            val = self._emit_arm_value(arm.body)
            self._emit(f'{result_var} = {val};')
            self.indent -= 1
            first = False

        self._emit('}')
        self._set_var(result_var, result_type, is_mut=True)
        return (result_var, result_type)

    def _pattern_condition(self, pattern, tup_vars: list) -> str | None:
        match pattern:
            case ast.WildcardPattern():
                return None
            case ast.IdentPattern():
                return None
            case ast.IntPattern():
                if len(tup_vars) == 1:
                    return f'({tup_vars[0][0]} == {pattern.value})'
                return f'({tup_vars[0][0]} == {pattern.value})'
            case ast.TuplePattern():
                parts = []
                for i, elem_pat in enumerate(pattern.elements):
                    sub_cond = self._pattern_condition(elem_pat, [tup_vars[i]])
                    if sub_cond is not None:
                        parts.append(sub_cond)
                if not parts:
                    return None
                return ' && '.join(parts)
            case _:
                return None

    def _bind_pattern_vars(self, pattern, tup_vars: list):
        match pattern:
            case ast.IdentPattern():
                if len(tup_vars) == 1:
                    var, vtype = tup_vars[0]
                    self._emit(f'{self._c_type_str(vtype)} {pattern.name} = {var};')
                    self._set_var(pattern.name, vtype, is_mut=True)
            case ast.TuplePattern():
                for i, elem_pat in enumerate(pattern.elements):
                    self._bind_pattern_vars(elem_pat, [tup_vars[i]])
            case _:
                pass

    def _emit_arm_value(self, body) -> str:
        if isinstance(body, ast.Block):
            return self._emit_block_value(body)
        expr_str, _ = self._emit_expr(body)
        return expr_str

    def _emit_block_value(self, block: ast.Block) -> str:
        if not block.stmts:
            return '0'
        for stmt in block.stmts[:-1]:
            self._emit_stmt(stmt)
        last = block.stmts[-1]
        if isinstance(last, ast.ExprStmt):
            val, _ = self._emit_expr(last.expr)
            return val
        if isinstance(last, ast.IfExpr):
            val, _ = self._emit_if_expr(last)
            return val
        if isinstance(last, ast.ReturnExpr):
            if last.value is not None:
                val, _ = self._emit_expr(last.value)
                self._emit(f'return {val};')
            else:
                self._emit('return;')
            return '0'
        self._emit_stmt(last)
        return '0'

    def _emit_block_expr(self, block: ast.Block) -> tuple[str, CType]:
        if not block.stmts:
            return ('0', CType.VOID)
        for stmt in block.stmts[:-1]:
            self._emit_stmt(stmt)
        last = block.stmts[-1]
        if isinstance(last, ast.ExprStmt):
            return self._emit_expr(last.expr)
        self._emit_stmt(last)
        return ('0', CType.VOID)

    def _infer_block_type(self, block: ast.Block) -> CType:
        if not block.stmts:
            return CType.VOID
        last = block.stmts[-1]
        if isinstance(last, ast.ExprStmt):
            return self._infer_expr_type(last.expr)
        return CType.VOID

    def _infer_arm_type(self, arm: ast.MatchArm) -> CType:
        body = arm.body
        if isinstance(body, ast.Block):
            return self._infer_block_type(body)
        return self._infer_expr_type(body)

    def _infer_expr_type(self, node) -> CType:
        match node:
            case ast.IntLit():
                return CType.INT
            case ast.FloatLit():
                return CType.FLOAT
            case ast.BoolLit():
                return CType.BOOL
            case ast.InterpString():
                return CType.STRING
            case ast.ListLit():
                return CType.LIST
            case ast.Ident():
                ctype, _ = self._get_var(node.name)
                return ctype
            case ast.Call():
                if isinstance(node.func, ast.Ident) and node.func.name in self.fn_registry:
                    return self.fn_registry[node.func.name][0]
                return CType.VOID
            case ast.BinOp():
                if node.op in _COMPARISON_OPS or node.op in _LOGICAL_OPS:
                    return CType.BOOL
                return self._infer_expr_type(node.left)
            case _:
                return CType.VOID


def _escape_c_string(s: str) -> str:
    return s.replace('\\', '\\\\').replace('"', '\\"').replace('\n', '\\n').replace('\t', '\\t')
