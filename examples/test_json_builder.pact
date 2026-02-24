import std.json

fn main() {
    let mut pass = true

    // Build object
    let obj = json_new_object()
    json_set(obj, "name", json_new_str("Alice"))
    json_set(obj, "age", json_new_int(30))
    json_set(obj, "score", json_new_float(9.5))
    json_set(obj, "active", json_new_bool(1))
    let result = json_encode(obj)
    let expected = "\{\"name\":\"Alice\",\"age\":30,\"score\":9.5,\"active\":true}"
    if result != expected {
        io.println("FAIL: object builder -- got {result}")
        pass = false
    }

    // Build array
    json_clear()
    let arr = json_new_array()
    json_push(arr, json_new_int(1))
    json_push(arr, json_new_int(2))
    json_push(arr, json_new_int(3))
    let arr_result = json_encode(arr)
    if arr_result != "[1,2,3]" {
        io.println("FAIL: array builder -- got {arr_result}")
        pass = false
    }

    // Nested object
    json_clear()
    let outer = json_new_object()
    let inner = json_new_object()
    json_set(inner, "x", json_new_int(10))
    json_set(outer, "point", inner)
    json_set(outer, "label", json_new_str("origin"))
    let nested_result = json_encode(outer)
    if nested_result != "\{\"point\":\{\"x\":10},\"label\":\"origin\"}" {
        io.println("FAIL: nested object -- got {nested_result}")
        pass = false
    }

    // Null
    json_clear()
    let n = json_new_null()
    if json_encode(n) != "null" {
        io.println("FAIL: null builder")
        pass = false
    }

    if pass {
        io.println("PASS")
    }
}
