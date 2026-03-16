@module("")

@ffi("pact_map_new")
@trusted
fn map_new() -> Map[Str, Int] ! FFI {}

@ffi("pact_map_set")
@trusted
fn map_set(m: Map[Str, Int], key: Str, val: Ptr[Int]) ! FFI {}

@ffi("pact_map_get")
@trusted
fn map_get(m: Map[Str, Int], key: Str) -> Ptr[Int] ! FFI {}

@ffi("pact_map_has")
@trusted
fn map_has(m: Map[Str, Int], key: Str) -> Int ! FFI {}

@ffi("pact_map_remove")
@trusted
fn map_remove(m: Map[Str, Int], key: Str) -> Int ! FFI {}

@ffi("pact_map_len")
@trusted
fn map_len(m: Map[Str, Int]) -> Int ! FFI {}

@ffi("pact_map_keys")
@trusted
fn map_keys(m: Map[Str, Int]) -> List[Str] ! FFI {}

@ffi("pact_map_values")
@trusted
fn map_values(m: Map[Str, Int]) -> List[Int] ! FFI {}

@ffi("pact_map_free")
@trusted
fn map_free(m: Map[Str, Int]) ! FFI {}
