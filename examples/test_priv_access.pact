import multifile_helper

test "pub functions from helper module are accessible" {
    assert_eq(helper_add(3, 4), 7)
}

test "pub let from helper module is accessible" {
    assert_eq(HELPER_CONST, 99)
}
