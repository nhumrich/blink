@module("")

@ffi("pact_str_len")
@trusted
fn str_len(s: Str) -> Int ! FFI {}

@ffi("pact_str_char_at")
@trusted
fn str_char_at(s: Str, i: Int) -> Int ! FFI {}

@ffi("pact_str_substr")
@trusted
fn str_substr(s: Str, start: Int, length: Int) -> Str ! FFI {}

@ffi("pact_str_from_char_code")
@trusted
fn str_from_char_code(code: Int) -> Str ! FFI {}

@ffi("pact_str_concat")
@trusted
fn str_concat(a: Str, b: Str) -> Str ! FFI {}

@ffi("pact_str_eq")
@trusted
fn str_eq(a: Str, b: Str) -> Int ! FFI {}

@ffi("pact_str_contains")
@trusted
fn str_contains(s: Str, needle: Str) -> Int ! FFI {}

@ffi("pact_str_starts_with")
@trusted
fn str_starts_with(s: Str, prefix: Str) -> Int ! FFI {}

@ffi("pact_str_ends_with")
@trusted
fn str_ends_with(s: Str, suffix: Str) -> Int ! FFI {}

@ffi("pact_str_slice")
@trusted
fn str_slice(s: Str, start: Int, end: Int) -> Str ! FFI {}

@ffi("pact_str_split")
@trusted
fn str_split(s: Str, delim: Str) -> List[Str] ! FFI {}

@ffi("pact_str_join")
@trusted
fn str_join(parts: List[Str], delim: Str) -> Str ! FFI {}

@ffi("pact_str_trim")
@trusted
fn str_trim(s: Str) -> Str ! FFI {}

@ffi("pact_str_to_upper")
@trusted
fn str_to_upper(s: Str) -> Str ! FFI {}

@ffi("pact_str_to_lower")
@trusted
fn str_to_lower(s: Str) -> Str ! FFI {}

@ffi("pact_str_replace")
@trusted
fn str_replace(s: Str, needle: Str, repl: Str) -> Str ! FFI {}

@ffi("pact_str_index_of")
@trusted
fn str_index_of(s: Str, needle: Str) -> Int ! FFI {}

@ffi("pact_str_lines")
@trusted
fn str_lines(s: Str) -> List[Str] ! FFI {}
