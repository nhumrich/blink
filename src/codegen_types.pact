import tokens
import ast
import parser

// codegen_types.pact — Type constants, global state, scope/registry helpers
//
// Minimal subset: enough to compile hello_compiled.pact via the
// Python C backend. Reads the parallel-array AST node pool produced
// by parser.pact and emits C source as a list of strings.
//
// Constraints: same as lexer/parser — parallel arrays, no struct-in-list,
// no closures, no imports. Constants duplicated for self-contained compilation.

// ── C type constants ────────────────────────────────────────────────
// Instead of enums, plain ints.

pub let CT_INT = 0
pub let CT_FLOAT = 1
pub let CT_BOOL = 2
pub let CT_STRING = 3
pub let CT_LIST = 4
pub let CT_VOID = 5
pub let CT_CLOSURE = 6
pub let CT_OPTION = 7
pub let CT_RESULT = 8


// ── Codegen state ───────────────────────────────────────────────────

pub let mut cg_lines: List[Str] = []
pub let mut cg_indent: Int = 0
pub let mut cg_temp_counter: Int = 0
pub let mut cg_global_inits: List[Str] = []
pub let mut struct_reg_names: List[Str] = []
pub let mut enum_reg_names: List[Str] = []
pub let mut enum_reg_variant_names: List[Str] = []
pub let mut enum_reg_variant_enum_idx: List[Int] = []
pub let mut var_enum_names: List[Str] = []
pub let mut var_enum_types: List[Str] = []
pub let mut fn_enum_ret_names: List[Str] = []
pub let mut fn_enum_ret_types: List[Str] = []
pub let mut emitted_let_names: List[Str] = []
pub let mut emitted_fn_names: List[Str] = []
pub let mut cg_closure_defs: List[Str] = []
pub let mut cg_closure_counter: Int = 0

// Capture analysis: per-closure capture info (flat list with start/count indexes)
pub let mut closure_capture_names: List[Str] = []
pub let mut closure_capture_types: List[Int] = []
pub let mut closure_capture_muts: List[Int] = []
pub let mut closure_capture_starts: List[Int] = []
pub let mut closure_capture_counts: List[Int] = []

// Active closure context: set while emitting a closure body, -1 otherwise
pub let mut cg_closure_cap_start: Int = -1
pub let mut cg_closure_cap_count: Int = 0

// Variables in the outer scope that are heap-boxed because a closure captures them mutably
pub let mut mut_captured_vars: List[Str] = []

// Trait registry: maps trait name -> method names
pub let mut trait_reg_names: List[Str] = []
pub let mut trait_reg_method_sl: List[Int] = []

// Impl registry: maps (trait, type) -> method FnDef nodes
pub let mut impl_reg_trait: List[Str] = []
pub let mut impl_reg_type: List[Str] = []
pub let mut impl_reg_methods_sl: List[Int] = []

// From impl registry: (source_type, target_type) -> methods sublist
pub let mut from_reg_source: List[Str] = []
pub let mut from_reg_target: List[Str] = []
pub let mut from_reg_method_sl: List[Int] = []

// TryFrom impl registry: (source_type, target_type) -> methods sublist
pub let mut tryfrom_reg_source: List[Str] = []
pub let mut tryfrom_reg_target: List[Str] = []
pub let mut tryfrom_reg_method_sl: List[Int] = []

// Variable-to-struct-type tracking (for method resolution)
pub let mut var_struct_names: List[Str] = []
pub let mut var_struct_types: List[Str] = []

// Struct field type registry: (struct_name, field_name) -> field C type
pub let mut sf_reg_struct: List[Str] = []
pub let mut sf_reg_field: List[Str] = []
pub let mut sf_reg_type: List[Int] = []
pub let mut sf_reg_stype: List[Str] = []

// Closure-typed variable tracking: (name) -> C function pointer signature
pub let mut var_closure_names: List[Str] = []
pub let mut var_closure_sigs: List[Str] = []

// Generic function definition registry: fn_name -> fn_node for generic fns
pub let mut generic_fn_names: List[Str] = []
pub let mut generic_fn_nodes: List[Int] = []

// Mono function instances to emit: (base_fn_name, concrete_args)
pub let mut mono_fn_bases: List[Str] = []
pub let mut mono_fn_args: List[Str] = []

// Generic monomorphic instance registry
pub let mut mono_base_names: List[Str] = []
pub let mut mono_concrete_args: List[Str] = []
pub let mut mono_c_names: List[Str] = []

// Option/Result type tracking
pub let mut var_option_names: List[Str] = []
pub let mut var_option_inner: List[Int] = []
pub let mut var_result_names: List[Str] = []
pub let mut var_result_ok: List[Int] = []
pub let mut var_result_err: List[Int] = []
pub let mut emitted_option_types: List[Int] = []
pub let mut emitted_result_types: List[Str] = []

// Assignment context for .into() type inference
pub let mut cg_let_target_type: Int = 0
pub let mut cg_let_target_name: Str = ""

// Handler vtable field set by emit_handler_expr for emit_with_block
pub let mut cg_handler_vtable_field: Str = ""
pub let mut cg_handler_is_user_effect: Int = 0
// Tracks the current handler's vtable type and field for default delegation
pub let mut cg_in_handler_body: Int = 0
pub let mut cg_handler_body_vtable_type: Str = ""
pub let mut cg_handler_body_field: Str = ""
pub let mut cg_handler_body_is_ue: Int = 0
pub let mut cg_handler_body_idx: Int = 0

// Scope: parallel lists for variable names, types, and mutability.
// Each scope is a "frame" delimited by frame_starts.
pub let mut scope_names: List[Str] = []
pub let mut scope_types: List[Int] = []
pub let mut scope_muts: List[Int] = []
pub let mut scope_frame_starts: List[Int] = []

// Function registry: parallel lists (fn name -> return type, param count)
pub let mut fn_reg_names: List[Str] = []
pub let mut fn_reg_ret: List[Int] = []
pub let mut fn_reg_effect_sl: List[Int] = []

// Function return type tracking for Result/Option/List
pub let mut fn_ret_result_names: List[Str] = []
pub let mut fn_ret_result_ok: List[Int] = []
pub let mut fn_ret_result_err: List[Int] = []
pub let mut fn_ret_option_names: List[Str] = []
pub let mut fn_ret_option_inner: List[Int] = []
pub let mut fn_ret_list_names: List[Str] = []
pub let mut fn_ret_list_elem: List[Int] = []

// Effect registry: name -> parent index (-1 = top-level)
pub let mut effect_reg_names: List[Str] = []
pub let mut effect_reg_parent: List[Int] = []

// User-defined effect registry: tracks vtable types and handle names
// ue_reg_names: top-level effect name (e.g. "Metrics")
// ue_reg_handle: handle name (e.g. "metrics")
// ue_reg_methods: comma-sep method names per effect (e.g. "counter,gauge,histogram")
// ue_reg_method_params: comma-sep C param strings per method (parallel to flattened methods)
// ue_reg_method_rets: C return type per method (parallel to flattened methods)
pub let mut ue_reg_names: List[Str] = []
pub let mut ue_reg_handle: List[Str] = []
pub let mut ue_reg_methods: List[Str] = []
pub let mut ue_reg_method_params: List[Str] = []
pub let mut ue_reg_method_rets: List[Str] = []
pub let mut ue_reg_method_effect: List[Str] = []

// @capabilities budget: allowed effects for the module (-1 = no budget)
pub let mut cap_budget_names: List[Str] = []
pub let mut cap_budget_active: Int = 0

// Current function being emitted (for effect propagation checking)
pub let mut cg_current_fn_name: Str = ""

pub let mut var_list_elem_names: List[Str] = []
pub let mut var_list_elem_types: List[Int] = []

// Scratch space for tuple match scrutinee temps
pub let mut cg_program_node: Int = 0

pub let mut match_scrut_strs: List[Str] = []
pub let mut match_scrut_types: List[Int] = []
pub let mut match_scrut_enum: Str = ""

pub fn push_scope() {
    scope_frame_starts.push(scope_names.len())
}

pub fn pop_scope() {
    let start = scope_frame_starts.get(scope_frame_starts.len() - 1)
    scope_frame_starts.pop()
    while scope_names.len() > start {
        scope_names.pop()
        scope_types.pop()
        scope_muts.pop()
    }
}

pub fn set_var(name: Str, ctype: Int, is_mut: Int) {
    scope_names.push(name)
    scope_types.push(ctype)
    scope_muts.push(is_mut)
}

pub fn get_var_type(name: Str) -> Int {
    let mut i = scope_names.len() - 1
    while i >= 0 {
        if scope_names.get(i) == name {
            return scope_types.get(i)
        }
        i = i - 1
    }
    CT_INT
}

pub fn get_var_mut(name: Str) -> Int {
    let mut i = scope_names.len() - 1
    while i >= 0 {
        if scope_names.get(i) == name {
            return scope_muts.get(i)
        }
        i = i - 1
    }
    0
}

pub fn is_mut_captured(name: Str) -> Int {
    let mut i = 0
    while i < mut_captured_vars.len() {
        if mut_captured_vars.get(i) == name {
            return 1
        }
        i = i + 1
    }
    0
}

pub fn get_capture_index(name: Str) -> Int {
    if cg_closure_cap_start < 0 {
        return -1
    }
    let mut i = 0
    while i < cg_closure_cap_count {
        if closure_capture_names.get(cg_closure_cap_start + i) == name {
            return i
        }
        i = i + 1
    }
    -1
}

pub fn capture_cast_expr(idx: Int) -> Str {
    let ct = closure_capture_types.get(cg_closure_cap_start + idx)
    if ct == CT_INT {
        "(int64_t)(intptr_t)pact_closure_get_capture(__self, {idx})"
    } else if ct == CT_FLOAT {
        "*(double*)pact_closure_get_capture(__self, {idx})"
    } else if ct == CT_STRING {
        "(const char*)pact_closure_get_capture(__self, {idx})"
    } else if ct == CT_BOOL {
        "(int)(intptr_t)pact_closure_get_capture(__self, {idx})"
    } else if ct == CT_LIST {
        "(pact_list*)pact_closure_get_capture(__self, {idx})"
    } else if ct == CT_CLOSURE {
        "(pact_closure*)pact_closure_get_capture(__self, {idx})"
    } else {
        "pact_closure_get_capture(__self, {idx})"
    }
}

pub fn reg_fn(name: Str, ret: Int) {
    fn_reg_names.push(name)
    fn_reg_ret.push(ret)
    fn_reg_effect_sl.push(-1)
}

pub fn reg_fn_with_effects(name: Str, ret: Int, effects_sl: Int) {
    fn_reg_names.push(name)
    fn_reg_ret.push(ret)
    fn_reg_effect_sl.push(effects_sl)
}

pub fn get_fn_effect_sl(name: Str) -> Int {
    let mut i = 0
    while i < fn_reg_names.len() {
        if fn_reg_names.get(i) == name {
            return fn_reg_effect_sl.get(i)
        }
        i = i + 1
    }
    -1
}

pub fn reg_fn_result_ret(name: Str, ok_t: Int, err_t: Int) {
    fn_ret_result_names.push(name)
    fn_ret_result_ok.push(ok_t)
    fn_ret_result_err.push(err_t)
}

pub fn reg_fn_option_ret(name: Str, inner: Int) {
    fn_ret_option_names.push(name)
    fn_ret_option_inner.push(inner)
}

pub fn get_fn_ret_result_ok(name: Str) -> Int {
    let mut i = fn_ret_result_names.len() - 1
    while i >= 0 {
        if fn_ret_result_names.get(i) == name {
            return fn_ret_result_ok.get(i)
        }
        i = i - 1
    }
    -1
}

pub fn get_fn_ret_result_err(name: Str) -> Int {
    let mut i = fn_ret_result_names.len() - 1
    while i >= 0 {
        if fn_ret_result_names.get(i) == name {
            return fn_ret_result_err.get(i)
        }
        i = i - 1
    }
    -1
}

pub fn get_fn_ret_option_inner(name: Str) -> Int {
    let mut i = fn_ret_option_names.len() - 1
    while i >= 0 {
        if fn_ret_option_names.get(i) == name {
            return fn_ret_option_inner.get(i)
        }
        i = i - 1
    }
    -1
}

pub fn reg_fn_list_ret(name: Str, elem_t: Int) {
    fn_ret_list_names.push(name)
    fn_ret_list_elem.push(elem_t)
}

pub fn get_fn_ret_list_elem(name: Str) -> Int {
    let mut i = fn_ret_list_names.len() - 1
    while i >= 0 {
        if fn_ret_list_names.get(i) == name {
            return fn_ret_list_elem.get(i)
        }
        i = i - 1
    }
    -1
}

pub fn resolve_ret_type_from_ann(fn_node: Int) -> Str {
    let ret_str = np_return_type.get(fn_node)
    let ta = np_type_ann.get(fn_node)
    if ret_str == "Result" && ta != -1 {
        let elems_sl = np_elements.get(ta)
        if elems_sl != -1 && sublist_length(elems_sl) >= 2 {
            let ok_ann = sublist_get(elems_sl, 0)
            let err_ann = sublist_get(elems_sl, 1)
            let ok_t = type_from_name(np_name.get(ok_ann))
            let err_t = type_from_name(np_name.get(err_ann))
            return result_c_type(ok_t, err_t)
        }
        return result_c_type(CT_INT, CT_STRING)
    }
    if ret_str == "Option" && ta != -1 {
        let elems_sl = np_elements.get(ta)
        if elems_sl != -1 && sublist_length(elems_sl) >= 1 {
            let inner_ann = sublist_get(elems_sl, 0)
            let inner_t = type_from_name(np_name.get(inner_ann))
            return option_c_type(inner_t)
        }
        return option_c_type(CT_INT)
    }
    ""
}

pub fn reg_fn_ret_from_ann(name: Str, fn_node: Int) {
    let ret_str = np_return_type.get(fn_node)
    let ta = np_type_ann.get(fn_node)
    if ret_str == "Result" && ta != -1 {
        let elems_sl = np_elements.get(ta)
        if elems_sl != -1 && sublist_length(elems_sl) >= 2 {
            let ok_ann = sublist_get(elems_sl, 0)
            let err_ann = sublist_get(elems_sl, 1)
            let ok_t = type_from_name(np_name.get(ok_ann))
            let err_t = type_from_name(np_name.get(err_ann))
            reg_fn_result_ret(name, ok_t, err_t)
            ensure_result_type(ok_t, err_t)
        }
    }
    if ret_str == "Option" && ta != -1 {
        let elems_sl = np_elements.get(ta)
        if elems_sl != -1 && sublist_length(elems_sl) >= 1 {
            let inner_ann = sublist_get(elems_sl, 0)
            let inner_t = type_from_name(np_name.get(inner_ann))
            reg_fn_option_ret(name, inner_t)
            ensure_option_type(inner_t)
        }
    }
    if ret_str == "List" && ta != -1 {
        let elems_sl = np_elements.get(ta)
        if elems_sl != -1 && sublist_length(elems_sl) >= 1 {
            let elem_ann = sublist_get(elems_sl, 0)
            let elem_t = type_from_name(np_name.get(elem_ann))
            reg_fn_list_ret(name, elem_t)
        }
    }
}

pub fn reg_effect(name: Str, parent: Int) -> Int {
    let idx = effect_reg_names.len()
    effect_reg_names.push(name)
    effect_reg_parent.push(parent)
    idx
}

pub fn get_effect_idx(name: Str) -> Int {
    let mut i = 0
    while i < effect_reg_names.len() {
        if effect_reg_names.get(i) == name {
            return i
        }
        i = i + 1
    }
    -1
}

pub fn effect_satisfies(caller_effect: Str, callee_effect: Str) -> Int {
    if caller_effect == callee_effect {
        return 1
    }
    let callee_idx = get_effect_idx(callee_effect)
    if callee_idx == -1 {
        return 0
    }
    let parent_idx = effect_reg_parent.get(callee_idx)
    if parent_idx == -1 {
        return 0
    }
    let parent_name = effect_reg_names.get(parent_idx)
    if parent_name == caller_effect {
        return 1
    }
    0
}

pub fn check_effect_propagation(callee_name: Str) {
    if cg_current_fn_name == "main" {
        return
    }
    let callee_sl = get_fn_effect_sl(callee_name)
    if callee_sl == -1 {
        return
    }
    let callee_count = sublist_length(callee_sl)
    if callee_count == 0 {
        return
    }
    let caller_sl = get_fn_effect_sl(cg_current_fn_name)
    let mut ci = 0
    while ci < callee_count {
        let callee_eff_node = sublist_get(callee_sl, ci)
        let callee_eff = np_name.get(callee_eff_node)
        let mut satisfied = 0
        if caller_sl != -1 {
            let caller_count = sublist_length(caller_sl)
            let mut ki = 0
            while ki < caller_count {
                let caller_eff_node = sublist_get(caller_sl, ki)
                let caller_eff = np_name.get(caller_eff_node)
                if effect_satisfies(caller_eff, callee_eff) != 0 {
                    satisfied = 1
                }
                ki = ki + 1
            }
        }
        if satisfied == 0 {
            io.println("error E0500: function '{callee_name}' requires effect '{callee_eff}' but caller '{cg_current_fn_name}' does not declare it")
        }
        ci = ci + 1
    }
}

pub fn check_capabilities_budget(fn_name: Str, effects_sl: Int) {
    if cap_budget_active == 0 {
        return
    }
    if fn_name == "main" {
        return
    }
    if effects_sl == -1 {
        return
    }
    let count = sublist_length(effects_sl)
    let mut ei = 0
    while ei < count {
        let eff_node = sublist_get(effects_sl, ei)
        let eff_name = np_name.get(eff_node)
        let mut allowed = 0
        let mut bi = 0
        while bi < cap_budget_names.len() {
            let budget_eff = cap_budget_names.get(bi)
            if effect_satisfies(budget_eff, eff_name) != 0 {
                allowed = 1
            }
            bi = bi + 1
        }
        if allowed == 0 {
            io.println("error E0501: function '{fn_name}' uses effect '{eff_name}' which is not in @capabilities budget")
        }
        ei = ei + 1
    }
}

pub fn init_builtin_effects() {
    let io_idx = reg_effect("IO", -1)
    reg_effect("IO.Print", io_idx)
    reg_effect("IO.Log", io_idx)
    let fs_idx = reg_effect("FS", -1)
    reg_effect("FS.Read", fs_idx)
    reg_effect("FS.Write", fs_idx)
    reg_effect("FS.Delete", fs_idx)
    reg_effect("FS.Watch", fs_idx)
    let net_idx = reg_effect("Net", -1)
    reg_effect("Net.Connect", net_idx)
    reg_effect("Net.Listen", net_idx)
    reg_effect("Net.DNS", net_idx)
    let db_idx = reg_effect("DB", -1)
    reg_effect("DB.Read", db_idx)
    reg_effect("DB.Write", db_idx)
    reg_effect("DB.Admin", db_idx)
    let env_idx = reg_effect("Env", -1)
    reg_effect("Env.Read", env_idx)
    reg_effect("Env.Write", env_idx)
    let time_idx = reg_effect("Time", -1)
    reg_effect("Time.Read", time_idx)
    reg_effect("Time.Sleep", time_idx)
    reg_effect("Rand", -1)
    let crypto_idx = reg_effect("Crypto", -1)
    reg_effect("Crypto.Hash", crypto_idx)
    reg_effect("Crypto.Sign", crypto_idx)
    reg_effect("Crypto.Encrypt", crypto_idx)
    reg_effect("Crypto.Decrypt", crypto_idx)
    let proc_idx = reg_effect("Process", -1)
    reg_effect("Process.Spawn", proc_idx)
    reg_effect("Process.Signal", proc_idx)
}

pub fn get_ue_handle(effect_name: Str) -> Str {
    let mut i = 0
    while i < ue_reg_names.len() {
        if ue_reg_names.get(i) == effect_name {
            return ue_reg_handle.get(i)
        }
        i = i + 1
    }
    ""
}

pub fn get_ue_top_for_handle(handle: Str) -> Str {
    let mut i = 0
    while i < ue_reg_handle.len() {
        if ue_reg_handle.get(i) == handle {
            return ue_reg_names.get(i)
        }
        i = i + 1
    }
    ""
}

pub fn is_user_effect_handle(name: Str) -> Int {
    let mut i = 0
    while i < ue_reg_handle.len() {
        if ue_reg_handle.get(i) == name {
            return 1
        }
        i = i + 1
    }
    0
}

pub fn ue_has_method(handle: Str, method: Str) -> Int {
    let mut i = 0
    while i < ue_reg_method_effect.len() {
        if ue_reg_method_effect.get(i) == handle {
            let mparts = ue_reg_methods.get(i)
            if mparts == method {
                return 1
            }
        }
        i = i + 1
    }
    0
}

pub fn get_fn_ret(name: Str) -> Int {
    let mut i = 0
    while i < fn_reg_names.len() {
        if fn_reg_names.get(i) == name {
            return fn_reg_ret.get(i)
        }
        i = i + 1
    }
    CT_VOID
}

pub fn set_list_elem_type(name: Str, elem_type: Int) {
    var_list_elem_names.push(name)
    var_list_elem_types.push(elem_type)
}

pub fn get_list_elem_type(name: Str) -> Int {
    let mut i = 0
    while i < var_list_elem_names.len() {
        if var_list_elem_names.get(i) == name {
            return var_list_elem_types.get(i)
        }
        i = i + 1
    }
    CT_INT
}

pub fn is_struct_type(name: Str) -> Int {
    let mut i = 0
    while i < struct_reg_names.len() {
        if struct_reg_names.get(i) == name {
            return 1
        }
        i = i + 1
    }
    0
}

pub fn is_enum_type(name: Str) -> Int {
    let mut i = 0
    while i < enum_reg_names.len() {
        if enum_reg_names.get(i) == name {
            return 1
        }
        i = i + 1
    }
    0
}

pub fn resolve_variant(name: Str) -> Str {
    let mut i = 0
    while i < enum_reg_variant_names.len() {
        if enum_reg_variant_names.get(i) == name {
            return enum_reg_names.get(enum_reg_variant_enum_idx.get(i))
        }
        i = i + 1
    }
    ""
}

pub fn get_var_enum(name: Str) -> Str {
    let mut i = 0
    while i < var_enum_names.len() {
        if var_enum_names.get(i) == name {
            return var_enum_types.get(i)
        }
        i = i + 1
    }
    ""
}

pub fn get_fn_enum_ret(name: Str) -> Str {
    let mut i = 0
    while i < fn_enum_ret_names.len() {
        if fn_enum_ret_names.get(i) == name {
            return fn_enum_ret_types.get(i)
        }
        i = i + 1
    }
    ""
}

pub fn set_var_struct(name: Str, type_name: Str) {
    var_struct_names.push(name)
    var_struct_types.push(type_name)
}

pub fn get_var_struct(name: Str) -> Str {
    let mut i = 0
    while i < var_struct_names.len() {
        if var_struct_names.get(i) == name {
            return var_struct_types.get(i)
        }
        i = i + 1
    }
    ""
}

pub fn get_struct_field_type(sname: Str, fname: Str) -> Int {
    let mut i = 0
    while i < sf_reg_struct.len() {
        if sf_reg_struct.get(i) == sname && sf_reg_field.get(i) == fname {
            return sf_reg_type.get(i)
        }
        i = i + 1
    }
    CT_VOID
}

pub fn get_struct_field_stype(sname: Str, fname: Str) -> Str {
    let mut i = 0
    while i < sf_reg_struct.len() {
        if sf_reg_struct.get(i) == sname && sf_reg_field.get(i) == fname {
            return sf_reg_stype.get(i)
        }
        i = i + 1
    }
    ""
}

pub fn set_var_closure(name: Str, sig: Str) {
    var_closure_names.push(name)
    var_closure_sigs.push(sig)
}

pub fn get_var_closure_sig(name: Str) -> Str {
    let mut i = 0
    while i < var_closure_names.len() {
        if var_closure_names.get(i) == name {
            return var_closure_sigs.get(i)
        }
        i = i + 1
    }
    ""
}

pub fn build_closure_sig_from_type_ann(ta: Int) -> Str {
    let ret_name = np_return_type.get(ta)
    let ret_type = type_from_name(ret_name)
    let elems_sl = np_elements.get(ta)
    let mut sig_params = "pact_closure*"
    if elems_sl != -1 && sublist_length(elems_sl) > 0 {
        let mut i = 0
        while i < sublist_length(elems_sl) {
            let elem = sublist_get(elems_sl, i)
            let ename = np_name.get(elem)
            sig_params = sig_params.concat(", ")
            if is_enum_type(ename) != 0 {
                sig_params = sig_params.concat("pact_{ename}")
            } else if is_struct_type(ename) != 0 {
                sig_params = sig_params.concat("pact_{ename}")
            } else {
                sig_params = sig_params.concat(c_type_str(type_from_name(ename)))
            }
            i = i + 1
        }
    }
    "{c_type_str(ret_type)}(*)({sig_params})"
}

pub fn is_generic_fn(name: Str) -> Int {
    let mut i = 0
    while i < generic_fn_names.len() {
        if generic_fn_names.get(i) == name {
            return 1
        }
        i = i + 1
    }
    0
}

pub fn get_generic_fn_node(name: Str) -> Int {
    let mut i = 0
    while i < generic_fn_names.len() {
        if generic_fn_names.get(i) == name {
            return generic_fn_nodes.get(i)
        }
        i = i + 1
    }
    -1
}

pub fn register_mono_fn(base: Str, args: Str) {
    let mut i = 0
    while i < mono_fn_bases.len() {
        if mono_fn_bases.get(i) == base && mono_fn_args.get(i) == args {
            return
        }
        i = i + 1
    }
    mono_fn_bases.push(base)
    mono_fn_args.push(args)
}

pub fn infer_fn_type_args_from_types(fn_node: Int, arg_types: List[Int]) -> Str {
    let tparams_sl = np_type_params.get(fn_node)
    if tparams_sl == -1 {
        return ""
    }
    let num_params = sublist_length(tparams_sl)
    if num_params == 0 {
        return ""
    }
    let fn_params_sl = np_params.get(fn_node)
    if fn_params_sl == -1 {
        return ""
    }
    let mut args = ""
    let mut pi = 0
    while pi < num_params {
        let param_name = np_name.get(sublist_get(tparams_sl, pi))
        let mut resolved = "Void"
        let mut fi = 0
        while fi < sublist_length(fn_params_sl) && fi < arg_types.len() {
            let p = sublist_get(fn_params_sl, fi)
            let ptype = np_type_name.get(p)
            if ptype == param_name {
                resolved = type_name_from_ct(arg_types.get(fi))
            }
            fi = fi + 1
        }
        if pi > 0 {
            args = args.concat(",")
        }
        args = args.concat(resolved)
        pi = pi + 1
    }
    args
}

pub fn type_name_from_ct(ct: Int) -> Str {
    if ct == CT_INT { "Int" }
    else if ct == CT_FLOAT { "Float" }
    else if ct == CT_BOOL { "Bool" }
    else if ct == CT_STRING { "Str" }
    else if ct == CT_LIST { "List" }
    else { "Void" }
}

pub fn mangle_generic_name(base: Str, args: Str) -> Str {
    let mut result = base
    let mut i = 0
    let mut seg_start = 0
    while i <= args.len() {
        if i == args.len() || args.char_at(i) == 44 {
            let seg = args.substr(seg_start, i - seg_start)
            result = result.concat("_").concat(seg)
            seg_start = i + 1
        }
        i = i + 1
    }
    result
}

pub fn register_mono_instance(base: Str, args: Str) -> Str {
    let existing = lookup_mono_instance(base, args)
    if existing != "" {
        return existing
    }
    let c_name = mangle_generic_name(base, args)
    mono_base_names.push(base)
    mono_concrete_args.push(args)
    mono_c_names.push(c_name)
    c_name
}

pub fn lookup_mono_instance(base: Str, args: Str) -> Str {
    let mut i = 0
    while i < mono_base_names.len() {
        if mono_base_names.get(i) == base && mono_concrete_args.get(i) == args {
            return mono_c_names.get(i)
        }
        i = i + 1
    }
    ""
}

pub fn is_trait_type(name: Str) -> Int {
    let mut i = 0
    while i < trait_reg_names.len() {
        if trait_reg_names.get(i) == name {
            return 1
        }
        i = i + 1
    }
    0
}

pub fn lookup_impl_method(type_name: Str, method: Str) -> Int {
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

pub fn lookup_impl_type_for_trait(trait_name: Str, type_name: Str) -> Int {
    let mut i = 0
    while i < impl_reg_trait.len() {
        if impl_reg_trait.get(i) == trait_name && impl_reg_type.get(i) == type_name {
            return 1
        }
        i = i + 1
    }
    0
}

pub fn get_impl_method_ret(type_name: Str, method: Str) -> Int {
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

pub fn find_from_impl(source: Str, target: Str) -> Int {
    let mut i = 0
    while i < from_reg_source.len() {
        if from_reg_source.get(i) == source && from_reg_target.get(i) == target {
            return from_reg_method_sl.get(i)
        }
        i = i + 1
    }
    -1
}

pub fn find_tryfrom_impl(source: Str, target: Str) -> Int {
    let mut i = 0
    while i < tryfrom_reg_source.len() {
        if tryfrom_reg_source.get(i) == source && tryfrom_reg_target.get(i) == target {
            return tryfrom_reg_method_sl.get(i)
        }
        i = i + 1
    }
    -1
}

pub fn impl_method_has_self(fn_node: Int) -> Int {
    let params_sl = np_params.get(fn_node)
    if params_sl != -1 {
        let mut i = 0
        while i < sublist_length(params_sl) {
            let p = sublist_get(params_sl, i)
            if np_name.get(p) == "self" {
                return 1
            }
            i = i + 1
        }
    }
    0
}

pub fn resolve_self_type(ret_str: Str, impl_type: Str) -> Str {
    if ret_str == "Self" {
        return impl_type
    }
    ret_str
}

pub fn is_emitted_let(name: Str) -> Int {
    let mut i = 0
    while i < emitted_let_names.len() {
        if emitted_let_names.get(i) == name {
            return 1
        }
        i = i + 1
    }
    0
}

pub fn is_emitted_fn(name: Str) -> Int {
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

pub fn c_type_str(ct: Int) -> Str {
    if ct == CT_INT { "int64_t" }
    else if ct == CT_FLOAT { "double" }
    else if ct == CT_BOOL { "int" }
    else if ct == CT_STRING { "const char*" }
    else if ct == CT_LIST { "pact_list*" }
    else if ct == CT_CLOSURE { "pact_closure*" }
    else { "void" }
}

pub fn type_from_name(name: Str) -> Int {
    match name {
        "Int" => CT_INT
        "Str" => CT_STRING
        "Float" => CT_FLOAT
        "Bool" => CT_BOOL
        "List" => CT_LIST
        "Option" => CT_OPTION
        "Result" => CT_RESULT
        _ => CT_VOID
    }
}

pub fn option_c_type(inner: Int) -> Str {
    "pact_Option_{c_type_tag(inner)}"
}

pub fn result_c_type(ok_t: Int, err_t: Int) -> Str {
    "pact_Result_{c_type_tag(ok_t)}_{c_type_tag(err_t)}"
}

pub fn c_type_tag(ct: Int) -> Str {
    if ct == CT_INT { "int" }
    else if ct == CT_FLOAT { "double" }
    else if ct == CT_BOOL { "bool" }
    else if ct == CT_STRING { "str" }
    else if ct == CT_LIST { "list" }
    else { "void" }
}

pub fn ensure_option_type(inner: Int) {
    let mut i = 0
    while i < emitted_option_types.len() {
        if emitted_option_types.get(i) == inner {
            return
        }
        i = i + 1
    }
    emitted_option_types.push(inner)
}

pub fn ensure_result_type(ok_t: Int, err_t: Int) {
    let key = "{ok_t}_{err_t}"
    let mut i = 0
    while i < emitted_result_types.len() {
        if emitted_result_types.get(i) == key {
            return
        }
        i = i + 1
    }
    emitted_result_types.push(key)
}

pub fn set_var_option(name: Str, inner: Int) {
    var_option_names.push(name)
    var_option_inner.push(inner)
}

pub fn get_var_option_inner(name: Str) -> Int {
    let mut i = var_option_names.len() - 1
    while i >= 0 {
        if var_option_names.get(i) == name {
            return var_option_inner.get(i)
        }
        i = i - 1
    }
    -1
}

pub fn set_var_result(name: Str, ok_t: Int, err_t: Int) {
    var_result_names.push(name)
    var_result_ok.push(ok_t)
    var_result_err.push(err_t)
}

pub fn get_var_result_ok(name: Str) -> Int {
    let mut i = var_result_names.len() - 1
    while i >= 0 {
        if var_result_names.get(i) == name {
            return var_result_ok.get(i)
        }
        i = i - 1
    }
    -1
}

pub fn get_var_result_err(name: Str) -> Int {
    let mut i = var_result_names.len() - 1
    while i >= 0 {
        if var_result_names.get(i) == name {
            return var_result_err.get(i)
        }
        i = i - 1
    }
    -1
}

pub fn emit_option_typedef(inner: Int) {
    let tag = c_type_tag(inner)
    let tname = "pact_Option_{tag}"
    let c_inner = c_type_str(inner)
    emit_line("typedef struct \{ int tag; {c_inner} value; } {tname};")
    emit_line("")
}

pub fn emit_result_typedef(ok_t: Int, err_t: Int) {
    let ok_tag = c_type_tag(ok_t)
    let err_tag = c_type_tag(err_t)
    let tname = "pact_Result_{ok_tag}_{err_tag}"
    let c_ok = c_type_str(ok_t)
    let c_err = c_type_str(err_t)
    emit_line("typedef struct \{ int tag; union \{ {c_ok} ok; {c_err} err; }; } {tname};")
    emit_line("")
}

pub fn emit_all_option_result_types() {
    let mut i = 0
    while i < emitted_option_types.len() {
        emit_option_typedef(emitted_option_types.get(i))
        i = i + 1
    }
    i = 0
    while i < emitted_result_types.len() {
        let key = emitted_result_types.get(i)
        let mut sep = 0
        let mut j = 0
        while j < key.len() {
            if key.char_at(j) == 95 {
                sep = j
            }
            j = j + 1
        }
        let ok_str = key.substring(0, sep)
        let err_str = key.substring(sep + 1, key.len() - sep - 1)
        let mut ok_t = CT_INT
        let mut err_t = CT_INT
        if ok_str == "0" { ok_t = CT_INT }
        else if ok_str == "1" { ok_t = CT_FLOAT }
        else if ok_str == "2" { ok_t = CT_BOOL }
        else if ok_str == "3" { ok_t = CT_STRING }
        else if ok_str == "4" { ok_t = CT_LIST }
        if err_str == "0" { err_t = CT_INT }
        else if err_str == "1" { err_t = CT_FLOAT }
        else if err_str == "2" { err_t = CT_BOOL }
        else if err_str == "3" { err_t = CT_STRING }
        else if err_str == "4" { err_t = CT_LIST }
        emit_result_typedef(ok_t, err_t)
        i = i + 1
    }
}

pub fn emit_option_result_types_from(opt_start: Int, res_start: Int) {
    let mut i = opt_start
    while i < emitted_option_types.len() {
        emit_option_typedef(emitted_option_types.get(i))
        i = i + 1
    }
    i = res_start
    while i < emitted_result_types.len() {
        let key = emitted_result_types.get(i)
        let mut sep = 0
        let mut j = 0
        while j < key.len() {
            if key.char_at(j) == 95 {
                sep = j
            }
            j = j + 1
        }
        let ok_str = key.substring(0, sep)
        let err_str = key.substring(sep + 1, key.len() - sep - 1)
        let mut ok_t = CT_INT
        let mut err_t = CT_INT
        if ok_str == "0" { ok_t = CT_INT }
        else if ok_str == "1" { ok_t = CT_FLOAT }
        else if ok_str == "2" { ok_t = CT_BOOL }
        else if ok_str == "3" { ok_t = CT_STRING }
        else if ok_str == "4" { ok_t = CT_LIST }
        if err_str == "0" { err_t = CT_INT }
        else if err_str == "1" { err_t = CT_FLOAT }
        else if err_str == "2" { err_t = CT_BOOL }
        else if err_str == "3" { err_t = CT_STRING }
        else if err_str == "4" { err_t = CT_LIST }
        emit_result_typedef(ok_t, err_t)
        i = i + 1
    }
}

pub fn fresh_temp(prefix: Str) -> Str {
    let n = cg_temp_counter
    cg_temp_counter = cg_temp_counter + 1
    "{prefix}{n}"
}

pub fn emit_line(line: Str) {
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

pub fn join_lines() -> Str {
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
