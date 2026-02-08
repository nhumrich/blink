import pact.ast_nodes as ast
import pact.runtime as runtime


class EarlyReturn(Exception):
    def __init__(self, value):
        self.value = value


class BreakSignal(Exception):
    pass


class ContinueSignal(Exception):
    pass


class Interpreter:
    def __init__(self, argv: list[str]):
        net_error_type = runtime.PactEnumType("NetError", {"ConnectionRefused": 1, "Timeout": 0})
        self.functions: dict[str, ast.FnDef] = {}
        self.enum_types: dict[str, runtime.PactEnumType] = {"NetError": net_error_type}
        self.struct_types: dict[str, list[str]] = {}
        self.struct_field_defaults: dict[str, dict] = {}
        self.methods: dict[tuple[str, str], ast.FnDef] = {}
        self.handler_stack: list[_HandlerValue] = []
        self._derived_displays: set[str] = set()
        self._iterator_types: set[str] = set()
        self.test_mode = False
        self.globals = {
            "io": runtime.IOHandle(),
            "env": runtime.EnvHandle(argv),
            "fs": runtime.FSHandle(),
            "db": runtime.DBHandle(),
            "net": runtime.NetHandle(),
            "json": runtime.JSONHandle(),
            "Map": _MapConstructorNamespace(),
            "Response": _ResponseConstructorNamespace(),
            "NetError": _EnumConstructorNamespace(net_error_type),
            "Display": _DisplayTraitNamespace(),
        }

    def run(self, program: ast.Program):
        self._register_program(program)
        return self.call_function("main", [])

    def run_tests(self, program: ast.Program):
        self._register_program(program)
        self.test_mode = True
        results = []
        for tb in program.tests:
            try:
                env = dict(self.globals)
                self.exec_block(tb.body, env)
                results.append((tb.name, True, None))
            except Exception as e:
                results.append((tb.name, False, str(e)))
        return results

    def _register_program(self, program: ast.Program):
        for imp in program.imports:
            self._register_import(imp)
        for td in program.types:
            self._register_type(td)
        for fn in program.functions:
            self.functions[fn.name] = fn
        for impl in program.impls:
            self._register_impl(impl)
        for mod in program.modules:
            self._register_module(mod)

    def _register_module(self, mod: ast.ModBlock):
        ns = _ModuleNamespace(mod.name)
        inner = mod.body
        for td in inner.types:
            self._register_type(td)
            if td.name in self.globals:
                ns._members[td.name] = self.globals[td.name]
            if td.variants:
                enum_type = self.enum_types.get(td.name)
                if enum_type:
                    for v in td.variants:
                        if enum_type.variant_defs.get(v.name, 0) == 0:
                            ns._members[v.name] = enum_type.construct(v.name, [])
        for fn in inner.functions:
            self.functions[f"{mod.name}.{fn.name}"] = fn
            self.functions[fn.name] = fn
            ns._members[fn.name] = _FnRef(f"{mod.name}.{fn.name}")
        for impl in inner.impls:
            self._register_impl(impl)
        self.globals[mod.name] = ns

    def _register_import(self, imp: ast.ImportStmt):
        pass

    def _register_type(self, td: ast.TypeDef):
        if td.variants:
            variant_defs = {v.name: len(v.fields) for v in td.variants}
            enum_type = runtime.PactEnumType(td.name, variant_defs)
            self.enum_types[td.name] = enum_type
            self.globals[td.name] = _EnumConstructorNamespace(enum_type)
        elif td.fields:
            self.struct_types[td.name] = [f.name for f in td.fields]
            self.struct_field_defaults[td.name] = {
                f.name: f.default for f in td.fields if f.default is not None
            }
            self.globals[td.name] = _TypeNamespace(td.name)
        else:
            self.globals[td.name] = _TypeNamespace(td.name)
        for ann in td.annotations:
            if ann.name == "derive" and "Display" in ann.args:
                self._derived_displays.add(td.name)

    def _register_impl(self, impl: ast.ImplBlock):
        for method in impl.methods:
            self.methods[(impl.type_name, method.name)] = method
        if impl.trait_name == "Iterator":
            self._iterator_types.add(impl.type_name)

    def call_function(self, name: str, args: list):
        if name == "Ok":
            return runtime.PactOk(args[0] if args else None)
        if name == "Err":
            return runtime.PactErr(args[0] if args else None)
        if name == "Some":
            return runtime.PactSome(args[0] if args else None)
        if name == "None":
            return runtime.NONE
        if name == "assert":
            if not args[0]:
                raise AssertionError("assertion failed")
            return None
        if name == "assert_eq":
            if args[0] != args[1]:
                raise AssertionError(f"assert_eq failed: {args[0]!r} != {args[1]!r}")
            return None
        if name == "assert_ne":
            if args[0] == args[1]:
                raise AssertionError(f"assert_ne failed: {args[0]!r} == {args[1]!r}")
            return None
        if name == "capture_log":
            return _CaptureLogHandler(args[0] if args else runtime.PactList([]))
        if name == "prop_check":
            import random
            closure = args[0]
            num_runs = args[1] if len(args) > 1 else 100
            for i in range(num_runs):
                test_args = []
                for param in closure.params:
                    match param.type_name:
                        case "Int": test_args.append(random.randint(-1000, 1000))
                        case "Float": test_args.append(random.uniform(-1000.0, 1000.0))
                        case "Str": test_args.append("".join(random.choices("abcdefghijklmnopqrstuvwxyz", k=random.randint(0, 20))))
                        case "Bool": test_args.append(random.choice([True, False]))
                        case _: test_args.append(random.randint(-1000, 1000))
                closure(*test_args)
            return None
        fn_def = self.functions[name]
        for ann in fn_def.annotations:
            if ann.name == "deprecated":
                import sys
                msg = ann.args[0] if ann.args else f"{name} is deprecated"
                print(f"[WARNING] {msg}", file=sys.stderr)
                break
        env = dict(self.globals)
        for i, param in enumerate(fn_def.params):
            if i < len(args):
                env[param.name] = args[i]
            elif param.default is not None:
                env[param.name] = self.eval_expr(param.default, env)
            else:
                raise ValueError(f"missing argument: {param.name}")
        try:
            return self.exec_block(fn_def.body, env)
        except EarlyReturn as ret:
            return ret.value

    def exec_block(self, block: ast.Block, env: dict):
        result = None
        for stmt in block.stmts:
            result = self.exec_stmt(stmt, env)
        return result

    def exec_stmt(self, stmt, env: dict):
        match stmt:
            case ast.LetBinding(name, value) if stmt.pattern is not None:
                val = self.eval_expr(value, env)
                self._destructure(stmt.pattern, val, env)
                return None
            case ast.LetBinding(name, value):
                env[name] = self.eval_expr(value, env)
                return None
            case ast.ExprStmt(expr):
                return self.eval_expr(expr, env)
            case ast.ForIn(var_name, iterable, body):
                items = self.eval_expr(iterable, env)
                for item in items:
                    if stmt.pattern is not None:
                        self._destructure(stmt.pattern, item, env)
                    else:
                        env[var_name] = item
                    try:
                        self.exec_block(body, env)
                    except BreakSignal:
                        break
                    except ContinueSignal:
                        continue
                return None
            case ast.WhileLoop(condition, body):
                while self.eval_expr(condition, env):
                    try:
                        self.exec_block(body, env)
                    except BreakSignal:
                        break
                    except ContinueSignal:
                        continue
                return None
            case ast.LoopExpr(body):
                while True:
                    try:
                        self.exec_block(body, env)
                    except BreakSignal:
                        break
                    except ContinueSignal:
                        continue
                return None
            case ast.BreakStmt():
                raise BreakSignal()
            case ast.ContinueStmt():
                raise ContinueSignal()
            case ast.IfExpr():
                return self.eval_if_expr(stmt, env)
            case ast.Assignment(target, value):
                val = self.eval_expr(value, env)
                if isinstance(target, ast.Ident):
                    env[target.name] = val
                return None
            case ast.ReturnExpr(value):
                raise EarlyReturn(self.eval_expr(value, env) if value else None)
            case ast.WithBlock(handlers, body):
                handler_vals = [self.eval_expr(h, env) for h in handlers]
                saved_io = env.get("io")
                resource = None
                for h in handler_vals:
                    if isinstance(h, _HandlerValue):
                        self.handler_stack.append(h)
                    elif isinstance(h, _CaptureLogHandler):
                        env["io"] = _SilentIOHandle(saved_io)
                    else:
                        resource = h
                if stmt.as_binding and resource is not None:
                    env[stmt.as_binding] = resource
                try:
                    return self.exec_block(body, env)
                finally:
                    for h in handler_vals:
                        if isinstance(h, _HandlerValue) and h in self.handler_stack:
                            self.handler_stack.remove(h)
                    if saved_io:
                        env["io"] = saved_io
                    if resource is not None and hasattr(resource, 'close'):
                        resource.close()
            case ast.CompoundAssignment(op, target, value):
                val = self.eval_expr(value, env)
                if isinstance(target, ast.Ident):
                    old = env[target.name]
                    match op:
                        case "+": env[target.name] = old + val
                        case "-": env[target.name] = old - val
                        case "*": env[target.name] = old * val
                        case "/": env[target.name] = old / val
                elif isinstance(target, ast.FieldAccess):
                    obj = self.eval_expr(target.obj, env)
                    old = getattr(obj, target.field)
                    match op:
                        case "+": new_val = old + val
                        case "-": new_val = old - val
                        case "*": new_val = old * val
                        case "/": new_val = old / val
                    setattr(obj, target.field, new_val)
                return None
            case _:
                raise ValueError(f"Unknown statement: {stmt}")

    def eval_if_expr(self, expr: ast.IfExpr, env: dict):
        cond = self.eval_expr(expr.condition, env)
        if cond:
            return self.exec_block(expr.then_body, env)
        elif expr.else_body:
            return self.exec_block(expr.else_body, env)
        return None

    def eval_expr(self, expr, env: dict):
        match expr:
            case ast.Ident(name):
                if name == "None":
                    return runtime.NONE
                if name in env:
                    return env[name]
                if name in self.functions:
                    return _FnRef(name)
                for enum_type in self.enum_types.values():
                    if name in enum_type.variant_defs:
                        if enum_type.variant_defs[name] == 0:
                            return enum_type.construct(name, [])
                        return _EnumVariantConstructor(enum_type, name)
                raise ValueError(f"undefined: {name}")
            case ast.IntLit(value):
                return value
            case ast.FloatLit(value):
                return value
            case ast.BoolLit(value):
                return value
            case ast.InterpString(parts):
                pieces = []
                for part in parts:
                    if isinstance(part, str):
                        pieces.append(part)
                    else:
                        pieces.append(str(self.eval_expr(part, env)))
                return "".join(pieces)
            case ast.Call(func, args):
                evaluated_args = [self.eval_expr(a, env) for a in args]
                if isinstance(func, ast.Ident):
                    if func.name in env and callable(env[func.name]):
                        return env[func.name](*evaluated_args)
                    return self.call_function(func.name, evaluated_args)
                target = self.eval_expr(func, env)
                if callable(target):
                    return target(*evaluated_args)
                raise ValueError(f"Cannot call: {func}")
            case ast.MethodCall(obj, method, args):
                target = self.eval_expr(obj, env)
                if isinstance(target, _EnumConstructorNamespace):
                    evaluated_args = [self.eval_expr(a, env) for a in args]
                    return target.enum_type.construct(method, evaluated_args)
                if isinstance(target, _TypeNamespace):
                    evaluated_args = [self.eval_expr(a, env) for a in args]
                    static_method = self.methods.get((target.type_name, method))
                    if static_method:
                        return self._call_static_method(static_method, evaluated_args)
                    if method == "try_from":
                        val = evaluated_args[0]
                        if isinstance(val, runtime.PactOk):
                            return val
                        if isinstance(val, runtime.PactErr):
                            return val
                        return runtime.PactOk(val)
                    raise ValueError(f"{target.type_name} has no static method '{method}'")
                if isinstance(target, _ModuleNamespace):
                    evaluated_args = [self.eval_expr(a, env) for a in args]
                    fn_name = f"{target._name}.{method}"
                    if fn_name in self.functions:
                        return self.call_function(fn_name, evaluated_args)
                    member = target._members.get(method)
                    if member and callable(member):
                        return member(*evaluated_args)
                    raise ValueError(f"module '{target._name}' has no function '{method}'")
                evaluated_args = [self.eval_expr(a, env) for a in args]
                handler_method = self._find_handler_method(obj, method)
                if handler_method:
                    return self._call_handler_method(handler_method, evaluated_args, env)
                impl_method = self._resolve_method(target, method)
                if impl_method:
                    return self._call_method(impl_method, target, evaluated_args)
                if method == "display" and isinstance(target, (runtime.PactStruct, runtime.PactEnumVariant)):
                    type_name = target._type_name if isinstance(target, runtime.PactStruct) else target.type_name
                    if type_name in self._derived_displays:
                        return str(target)
                if isinstance(target, runtime.PactStruct) and target._type_name in self._iterator_types:
                    return self._call_custom_iterator_method(target, method, evaluated_args, env)
                if isinstance(target, str):
                    return self._call_string_method(target, method, evaluated_args)
                if isinstance(target, (int, float)):
                    return self._call_numeric_method(target, method, evaluated_args)
                return getattr(target, method)(*evaluated_args)
            case ast.FieldAccess(obj, field):
                target = self.eval_expr(obj, env)
                if isinstance(target, _EnumConstructorNamespace):
                    variant_name = field
                    arity = target.enum_type.variant_defs.get(variant_name, 0)
                    if arity == 0:
                        return target.enum_type.construct(variant_name, [])
                    return _EnumVariantConstructor(target.enum_type, variant_name)
                if isinstance(target, _TypeNamespace):
                    static_method = self.methods.get((target.type_name, field))
                    if static_method:
                        return _StaticMethodRef(static_method, self)
                    raise ValueError(f"{target.type_name} has no static method '{field}'")
                if isinstance(target, tuple) and field.isdigit():
                    return target[int(field)]
                return getattr(target, field)
            case ast.TupleLit(elements):
                return tuple(self.eval_expr(e, env) for e in elements)
            case ast.RangeLit(start, end):
                s = self.eval_expr(start, env)
                e = self.eval_expr(end, env)
                if expr.inclusive:
                    return range(s, e + 1)
                return range(s, e)
            case ast.ListLit(elements):
                return runtime.PactList([self.eval_expr(e, env) for e in elements])
            case ast.StructLit(type_name, fields):
                field_vals = [(f.name, self.eval_expr(f.value, env)) for f in fields]
                provided = {f.name for f in fields}
                resolved_name = type_name.rsplit(".", 1)[-1] if "." in type_name else type_name
                defaults = self.struct_field_defaults.get(resolved_name, self.struct_field_defaults.get(type_name, {}))
                for fname, default_expr in defaults.items():
                    if fname not in provided:
                        field_vals.append((fname, self.eval_expr(default_expr, env)))
                return runtime.PactStruct(resolved_name, field_vals)
            case ast.Closure(params, body):
                return _PactClosure(params, body, env, self)
            case ast.HandlerExpr(effect, methods):
                return _HandlerValue(effect, methods, dict(env))
            case ast.MatchExpr(scrutinee, arms):
                value = self.eval_expr(scrutinee, env)
                for arm in arms:
                    bindings = self.match_pattern(arm.pattern, value)
                    if bindings is not None:
                        saved = {k: env[k] for k in bindings if k in env}
                        env.update(bindings)
                        if arm.guard is not None:
                            if not self.eval_expr(arm.guard, env):
                                for k in bindings:
                                    if k in saved:
                                        env[k] = saved[k]
                                    else:
                                        env.pop(k, None)
                                continue
                        body = arm.body
                        try:
                            if isinstance(body, (ast.ExprStmt, ast.CompoundAssignment, ast.Assignment,
                                                 ast.ReturnExpr, ast.BreakStmt, ast.ContinueStmt)):
                                return self.exec_stmt(body, env)
                            return self.eval_expr(body, env)
                        finally:
                            for k in bindings:
                                if k in saved:
                                    env[k] = saved[k]
                                else:
                                    env.pop(k, None)
                raise ValueError(f"No matching arm for: {value}")
            case ast.IfExpr():
                return self.eval_if_expr(expr, env)
            case ast.UnaryOp("-", operand):
                return -self.eval_expr(operand, env)
            case ast.UnaryOp("!", operand):
                return not self.eval_expr(operand, env)
            case ast.UnaryOp("?", operand):
                val = self.eval_expr(operand, env)
                if isinstance(val, runtime.PactOk):
                    return val.value
                if isinstance(val, runtime.PactErr):
                    raise EarlyReturn(val)
                if isinstance(val, runtime.PactSome):
                    return val.value
                if isinstance(val, runtime._PactNone):
                    raise EarlyReturn(runtime.NONE)
                return val
            case ast.BinOp(op, left, right):
                return self._eval_binop(op, left, right, env)
            case ast.Block(stmts):
                return self.exec_block(expr, env)
            case ast.ReturnExpr(value):
                raise EarlyReturn(self.eval_expr(value, env) if value else None)
            case _:
                raise ValueError(f"Unknown expression: {expr}")

    def _eval_binop(self, op, left, right, env):
        lv = self.eval_expr(left, env)
        if op == "&&":
            return lv and self.eval_expr(right, env)
        if op == "||":
            return lv or self.eval_expr(right, env)
        if op == "??":
            if isinstance(lv, runtime._PactNone):
                return self.eval_expr(right, env)
            if isinstance(lv, runtime.PactSome):
                return lv.value
            return lv
        rv = self.eval_expr(right, env)
        match op:
            case "+": return lv + rv
            case "-": return lv - rv
            case "*": return lv * rv
            case "/": return lv / rv
            case "%": return lv % rv
            case "==": return lv == rv
            case "!=": return lv != rv
            case "<": return lv < rv
            case ">": return lv > rv
            case "<=": return lv <= rv
            case ">=": return lv >= rv
        raise ValueError(f"Unknown operator: {op}")

    def match_pattern(self, pattern, value):
        match pattern:
            case ast.IntPattern(n):
                if value == n:
                    return {}
                return None
            case ast.StringPattern(s):
                if isinstance(value, str) and value == s:
                    return {}
                return None
            case ast.OrPattern(alternatives):
                for alt in alternatives:
                    bindings = self.match_pattern(alt, value)
                    if bindings is not None:
                        return bindings
                return None
            case ast.RangePattern(start, end, inclusive):
                if inclusive:
                    return {} if start <= value <= end else None
                return {} if start <= value < end else None
            case ast.WildcardPattern():
                return {}
            case ast.IdentPattern(name):
                if name == "None":
                    return {} if isinstance(value, runtime._PactNone) else None
                for et in self.enum_types.values():
                    if name in et.variant_defs:
                        if isinstance(value, runtime.PactEnumVariant) and value.variant_name == name and not value.fields:
                            return {}
                        return None
                if isinstance(value, runtime.PactEnumVariant) and not value.fields:
                    if value.variant_name == name:
                        return {}
                return {name: value}
            case ast.TuplePattern(elements):
                if not isinstance(value, tuple) or len(value) != len(elements):
                    return None
                bindings = {}
                for pat, val in zip(elements, value):
                    result = self.match_pattern(pat, val)
                    if result is None:
                        return None
                    bindings.update(result)
                return bindings
            case ast.AsPattern(name, inner):
                bindings = self.match_pattern(inner, value)
                if bindings is not None:
                    bindings[name] = value
                    return bindings
                return None
            case ast.StructPattern(type_name, fields, rest):
                if not isinstance(value, runtime.PactStruct):
                    return None
                if value._type_name != type_name:
                    return None
                bindings = {}
                for field in fields:
                    if isinstance(field, ast.StructPatternField):
                        if field.name not in value._fields:
                            return None
                        field_val = value._fields[field.name]
                        if field.pattern is not None:
                            sub = self.match_pattern(field.pattern, field_val)
                            if sub is None:
                                return None
                            bindings.update(sub)
                        else:
                            bindings[field.name] = field_val
                    else:
                        if field not in value._fields:
                            return None
                        bindings[field] = value._fields[field]
                if not rest and len(fields) != len(value._fields):
                    return None
                return bindings
            case ast.EnumPattern(variant, fields):
                if variant == "Ok" and isinstance(value, runtime.PactOk):
                    if len(fields) == 1:
                        return self.match_pattern(fields[0], value.value)
                    return {} if not fields else None
                if variant == "Err" and isinstance(value, runtime.PactErr):
                    if len(fields) == 1:
                        return self.match_pattern(fields[0], value.value)
                    return {} if not fields else None
                if variant == "Some" and isinstance(value, runtime.PactSome):
                    if len(fields) == 1:
                        return self.match_pattern(fields[0], value.value)
                    return {} if not fields else None
                if variant in ("Ok", "Err", "Some"):
                    return None
                if not isinstance(value, runtime.PactEnumVariant):
                    return None
                full_variant = variant
                if "." in full_variant:
                    _, vname = full_variant.rsplit(".", 1)
                else:
                    vname = full_variant
                if value.variant_name != vname:
                    return None
                if len(fields) != len(value.fields):
                    return None
                bindings = {}
                for pat, val in zip(fields, value.fields):
                    result = self.match_pattern(pat, val)
                    if result is None:
                        return None
                    bindings.update(result)
                return bindings
            case _:
                raise ValueError(f"Unknown pattern: {pattern}")


    def _destructure(self, pattern, value, env):
        match pattern:
            case ast.TuplePattern(elements):
                if not isinstance(value, tuple):
                    raise ValueError(f"cannot destructure non-tuple: {value}")
                for pat, val in zip(elements, value):
                    self._destructure(pat, val, env)
            case ast.IdentPattern(name):
                env[name] = value
            case _:
                raise ValueError(f"cannot destructure with pattern: {pattern}")

    def _find_handler_method(self, obj_expr, method_name):
        if not isinstance(obj_expr, ast.Ident):
            return None
        obj_name = obj_expr.name
        for handler in reversed(self.handler_stack):
            effect_base = handler.effect.split(".")[0].lower()
            if obj_name == effect_base:
                for m in handler.methods:
                    if m.name == method_name:
                        return (handler, m)
        return None

    def _call_handler_method(self, handler_method, args, env):
        handler, fn_def = handler_method
        call_env = dict(handler.captured_env)
        call_env.update(self.globals)
        for param, arg in zip(fn_def.params, args):
            call_env[param.name] = arg
        try:
            return self.exec_block(fn_def.body, call_env)
        except EarlyReturn as ret:
            return ret.value

    def _resolve_method(self, target, method_name):
        if isinstance(target, runtime.PactStruct):
            key = (target._type_name, method_name)
            return self.methods.get(key)
        if isinstance(target, runtime.PactEnumVariant):
            key = (target.type_name, method_name)
            return self.methods.get(key)
        return None

    def _call_method(self, fn_def, target, args):
        env = dict(self.globals)
        params = fn_def.params
        if params and params[0].name == "self":
            env["self"] = target
            remaining_params = params[1:]
            for i, param in enumerate(remaining_params):
                if i < len(args):
                    env[param.name] = args[i]
                elif param.default is not None:
                    env[param.name] = self.eval_expr(param.default, env)
        else:
            all_args = [target] + args
            for i, param in enumerate(params):
                if i < len(all_args):
                    env[param.name] = all_args[i]
                elif param.default is not None:
                    env[param.name] = self.eval_expr(param.default, env)
        try:
            return self.exec_block(fn_def.body, env)
        except EarlyReturn as ret:
            return ret.value


    def _call_static_method(self, fn_def, args):
        env = dict(self.globals)
        for i, param in enumerate(fn_def.params):
            if i < len(args):
                env[param.name] = args[i]
            elif param.default is not None:
                env[param.name] = self.eval_expr(param.default, env)
        try:
            return self.exec_block(fn_def.body, env)
        except EarlyReturn as ret:
            return ret.value

    def _next_from_custom_iter(self, target, env):
        next_method = self.methods.get((target._type_name, "next"))
        if next_method:
            return self._call_method(next_method, target, [])
        raise ValueError(f"{target._type_name} has no next() method")

    def _collect_custom_iter(self, target, env):
        items = []
        while True:
            result = self._next_from_custom_iter(target, env)
            if isinstance(result, runtime.PactSome):
                items.append(result.value)
            elif isinstance(result, runtime._PactNone):
                break
            else:
                break
        return runtime.PactList(items)

    def _call_custom_iterator_method(self, target, method, args, env):
        if method == "collect":
            return self._collect_custom_iter(target, env)
        collected = self._collect_custom_iter(target, env)
        return getattr(collected, method)(*args)

    def _call_string_method(self, target, method, args):
        match method:
            case "split": return runtime.PactList(target.split(args[0]))
            case "contains": return args[0] in target
            case "starts_with": return target.startswith(args[0])
            case "ends_with": return target.endswith(args[0])
            case "trim": return target.strip()
            case "to_uppercase": return target.upper()
            case "to_lowercase": return target.lower()
            case "len": return len(target)
            case "parse_int":
                try:
                    return runtime.PactSome(int(target))
                except (ValueError, TypeError):
                    return runtime.NONE
            case "replace": return target.replace(args[0], args[1])
            case "chars": return runtime.PactList(list(target))
            case _: return getattr(target, method)(*args)

    def _call_numeric_method(self, target, method, args):
        match method:
            case "to_float": return float(target)
            case "to_int": return int(target)
            case "to_int_checked":
                if isinstance(target, float) and target != int(target):
                    return runtime.NONE
                return runtime.PactSome(int(target))
            case "to_u16_checked":
                val = int(target)
                if 0 <= val <= 65535:
                    return runtime.PactOk(val)
                return runtime.PactErr(runtime.PactStruct("ConversionError", [
                    ("message", f"value {val} out of U16 range"),
                    ("source_type", "Int"),
                    ("target_type", "U16"),
                ]))
            case "abs": return abs(target)
            case "cmp":
                other = args[0]
                if target < other:
                    return -1
                elif target > other:
                    return 1
                return 0
            case "min":
                return min(target, args[0])
            case "max":
                return max(target, args[0])
            case _: raise ValueError(f"unknown numeric method: {method}")


class _PactClosure:
    def __init__(self, params, body, captured_env, interp):
        self.params = params
        self.body = body
        self.captured_env = captured_env
        self.interp = interp

    def __call__(self, *args):
        env = _ClosureEnv(self.captured_env)
        for param, arg in zip(self.params, args):
            env[param.name] = arg
        try:
            return self.interp.exec_block(self.body, env)
        except EarlyReturn as ret:
            return ret.value


class _ClosureEnv(dict):
    def __init__(self, parent):
        super().__init__(parent)
        self._parent = parent

    def __setitem__(self, key, value):
        super().__setitem__(key, value)
        if key in self._parent:
            self._parent[key] = value


class _CaptureLogHandler:
    def __init__(self, log_list):
        self.log_list = log_list


class _SilentIOHandle:
    def __init__(self, real_io):
        self._real_io = real_io

    def println(self, value):
        self._real_io.println(value)

    def log(self, value):
        pass


class _HandlerValue:
    def __init__(self, effect, methods, captured_env):
        self.effect = effect
        self.methods = methods
        self.captured_env = captured_env


class _EnumConstructorNamespace:
    def __init__(self, enum_type):
        self.enum_type = enum_type


class _EnumVariantConstructor:
    def __init__(self, enum_type, variant_name):
        self.enum_type = enum_type
        self.variant_name = variant_name

    def __call__(self, *args):
        return self.enum_type.construct(self.variant_name, args)


class _FnRef:
    def __init__(self, name):
        self.name = name


class _TypeNamespace:
    def __init__(self, type_name):
        self.type_name = type_name


class _DisplayTraitNamespace:
    def display(self, value):
        if hasattr(value, 'display'):
            return value.display()
        return str(value)

    def __getattr__(self, name):
        if name == "display":
            return self.display
        raise AttributeError(name)


class _StaticMethodRef:
    def __init__(self, fn_def, interp):
        self.fn_def = fn_def
        self.interp = interp

    def __call__(self, *args):
        return self.interp._call_static_method(self.fn_def, list(args))


class _ModuleNamespace:
    def __init__(self, name):
        self._name = name
        self._members = {}

    def __getattr__(self, name):
        if name.startswith("_"):
            raise AttributeError(name)
        if name in self._members:
            return self._members[name]
        raise AttributeError(f"module '{self._name}' has no member '{name}'")


class _MapConstructorNamespace:
    def new(self):
        return runtime.PactMap.new()

    def of(self, pairs):
        if isinstance(pairs, runtime.PactList):
            return runtime.PactMap.of(list(pairs))
        return runtime.PactMap.of(pairs)

    def from_list(self, pairs):
        if isinstance(pairs, runtime.PactList):
            return runtime.PactMap.from_list(list(pairs))
        return runtime.PactMap.from_list(pairs)

    def __getattr__(self, name):
        if name == "from":
            return self.from_list
        raise AttributeError(name)


class _ResponseConstructorNamespace:
    def new(self, status, body):
        return runtime.PactResponse.new(status, body)

    def json(self, data):
        return runtime.PactResponseBuilder.json(data)

    def bad_request(self, msg):
        return runtime.PactResponseBuilder.bad_request(msg)

    def not_found(self, msg):
        return runtime.PactResponseBuilder.not_found(msg)

    def internal_error(self, msg):
        return runtime.PactResponseBuilder.internal_error(msg)
