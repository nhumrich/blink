import std.json

test "object builder" {
    let obj = json_new_object()
    json_set(obj, "name", json_new_str("Alice"))
    json_set(obj, "age", json_new_int(30))
    json_set(obj, "score", json_new_float(9.5))
    json_set(obj, "active", json_new_bool(1))
    let result = json_encode(obj)
    assert_eq(result, "\{\"name\":\"Alice\",\"age\":30,\"score\":9.5,\"active\":true}")
}

test "array builder" {
    json_clear()
    let arr = json_new_array()
    json_push(arr, json_new_int(1))
    json_push(arr, json_new_int(2))
    json_push(arr, json_new_int(3))
    assert_eq(json_encode(arr), "[1,2,3]")
}

test "nested object" {
    json_clear()
    let outer = json_new_object()
    let inner = json_new_object()
    json_set(inner, "x", json_new_int(10))
    json_set(outer, "point", inner)
    json_set(outer, "label", json_new_str("origin"))
    assert_eq(json_encode(outer), "\{\"point\":\{\"x\":10},\"label\":\"origin\"}")
}

test "null builder" {
    json_clear()
    let n = json_new_null()
    assert_eq(json_encode(n), "null")
}
