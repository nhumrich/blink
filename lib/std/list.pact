@module("")

@ffi("pact_alloc")
@trusted
fn pact_alloc(size: Int) -> Ptr[Int] ! FFI {}

@ffi("pact_list_new")
@trusted
fn list_new() -> List[Int] ! FFI {}

@ffi("pact_list_push")
@trusted
fn list_push(l: List[Int], item: Ptr[Int]) ! FFI {}

@ffi("pact_list_get")
@trusted
fn list_get(l: List[Int], index: Int) -> Ptr[Int] ! FFI {}

@ffi("pact_list_set")
@trusted
fn list_set(l: List[Int], index: Int, item: Ptr[Int]) ! FFI {}

@ffi("pact_list_pop")
@trusted
fn list_pop(l: List[Int]) -> Ptr[Int] ! FFI {}

@ffi("pact_list_len")
@trusted
fn list_len(l: List[Int]) -> Int ! FFI {}

@ffi("pact_list_in_bounds")
@trusted
fn list_in_bounds(l: List[Int], index: Int) -> Int ! FFI {}

@ffi("pact_list_free")
@trusted
fn list_free(l: List[Int]) ! FFI {}
