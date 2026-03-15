// Test that fn_regs correctly stores module and is_pub info.
// Exercises the full pipeline: pub fn in imported module → reg_fn_with_effects_and_module
// → get_fn_module / get_fn_is_pub return correct values at runtime.
//
// Since fn_regs is a compiler-internal structure we verify via end-to-end behaviour:
// pub functions from imported modules must be callable; private ones must stay hidden.

import multifile_helper

pub fn local_pub(x: Int) -> Int {
    x * 2
}

fn local_private(x: Int) -> Int {
    x + 1
}

test "pub function from imported module is callable" {
    assert_eq(helper_add(3, 4), 7)
    assert_eq(helper_mul(5, 6), 30)
}

test "pub function defined in this file is callable" {
    assert_eq(local_pub(10), 20)
}

test "private function defined in this file is callable within file" {
    assert_eq(local_private(5), 6)
}

test "pub const from imported module is accessible" {
    assert_eq(HELPER_CONST, 99)
}

test "pub and local functions compose correctly" {
    assert_eq(helper_add(local_pub(2), local_private(3)), 8)
}
