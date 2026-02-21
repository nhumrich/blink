import std.json

fn check_int(actual: Int, expected: Int, label: Str) {
    if actual == expected {
        io.println("PASS: {label}")
    } else {
        io.println("FAIL: {label} — expected {expected}, got {actual}")
    }
}

fn check_str(actual: Str, expected: Str, label: Str) {
    if actual == expected {
        io.println("PASS: {label}")
    } else {
        io.println("FAIL: {label} — expected \"{expected}\", got \"{actual}\"")
    }
}

fn check_float(actual: Float, expected: Float, label: Str) {
    let diff = actual - expected
    let mut abs_diff = diff
    if diff < 0.0 {
        abs_diff = 0.0 - diff
    }
    if abs_diff < 0.001 {
        io.println("PASS: {label}")
    } else {
        io.println("FAIL: {label} — expected {expected}, got {actual}")
    }
}

fn test_parse_string() {
    json_clear()
    let idx = json_parse("\"hello world\"")
    check_int(json_type(idx), JSON_STRING, "parse string: type")
    check_str(json_as_str(idx), "hello world", "parse string: value")
}

fn test_parse_int() {
    json_clear()
    let idx = json_parse("42")
    check_int(json_type(idx), JSON_INT, "parse int: type")
    check_int(json_as_int(idx), 42, "parse int: value")
}

fn test_parse_negative_int() {
    json_clear()
    let idx = json_parse("-7")
    check_int(json_type(idx), JSON_INT, "parse neg int: type")
    check_int(json_as_int(idx), -7, "parse neg int: value")
}

fn test_parse_float() {
    json_clear()
    let idx = json_parse("3.14")
    check_int(json_type(idx), JSON_FLOAT, "parse float: type")
    check_float(json_as_float(idx), 3.14, "parse float: value")
}

fn test_parse_bool_true() {
    json_clear()
    let idx = json_parse("true")
    check_int(json_type(idx), JSON_BOOL, "parse true: type")
    check_int(json_as_bool(idx), 1, "parse true: value")
}

fn test_parse_bool_false() {
    json_clear()
    let idx = json_parse("false")
    check_int(json_type(idx), JSON_BOOL, "parse false: type")
    check_int(json_as_bool(idx), 0, "parse false: value")
}

fn test_parse_null() {
    json_clear()
    let idx = json_parse("null")
    check_int(json_type(idx), JSON_NULL, "parse null: type")
}

fn test_parse_empty_array() {
    json_clear()
    let idx = json_parse("[]")
    check_int(json_type(idx), JSON_ARRAY, "parse []: type")
    check_int(json_len(idx), 0, "parse []: length")
}

fn test_parse_int_array() {
    json_clear()
    let idx = json_parse("[1, 2, 3]")
    check_int(json_type(idx), JSON_ARRAY, "parse [1,2,3]: type")
    check_int(json_len(idx), 3, "parse [1,2,3]: length")

    let first = json_at(idx, 0)
    check_int(json_as_int(first), 1, "parse [1,2,3]: first")
    let second = json_at(idx, 1)
    check_int(json_as_int(second), 2, "parse [1,2,3]: second")
    let third = json_at(idx, 2)
    check_int(json_as_int(third), 3, "parse [1,2,3]: third")
}

fn test_parse_string_array() {
    json_clear()
    let idx = json_parse("[\"a\", \"b\", \"c\"]")
    check_int(json_len(idx), 3, "parse str array: length")
    check_str(json_as_str(json_at(idx, 0)), "a", "parse str array: first")
    check_str(json_as_str(json_at(idx, 2)), "c", "parse str array: third")
}

fn test_parse_empty_object() {
    json_clear()
    let idx = json_parse("\{}")
    check_int(json_type(idx), JSON_OBJECT, "parse empty obj: type")
    check_int(json_len(idx), 0, "parse empty obj: length")
}

fn test_parse_simple_object() {
    json_clear()
    let idx = json_parse("\{\"name\":\"Alice\",\"age\":30}")
    check_int(json_type(idx), JSON_OBJECT, "parse obj: type")
    check_int(json_len(idx), 2, "parse obj: length")

    let name_idx = json_get(idx, "name")
    check_int(json_type(name_idx), JSON_STRING, "parse obj: name type")
    check_str(json_as_str(name_idx), "Alice", "parse obj: name value")

    let age_idx = json_get(idx, "age")
    check_int(json_type(age_idx), JSON_INT, "parse obj: age type")
    check_int(json_as_int(age_idx), 30, "parse obj: age value")
}

fn test_parse_nested_object() {
    json_clear()
    let idx = json_parse("\{\"user\":\{\"id\":1,\"name\":\"Bob\"},\"active\":true}")
    check_int(json_type(idx), JSON_OBJECT, "nested obj: type")

    let user_idx = json_get(idx, "user")
    check_int(json_type(user_idx), JSON_OBJECT, "nested obj: user type")

    let id_idx = json_get(user_idx, "id")
    check_int(json_as_int(id_idx), 1, "nested obj: user.id")

    let name_idx = json_get(user_idx, "name")
    check_str(json_as_str(name_idx), "Bob", "nested obj: user.name")

    let active_idx = json_get(idx, "active")
    check_int(json_as_bool(active_idx), 1, "nested obj: active")
}

fn test_parse_mixed_array() {
    json_clear()
    let idx = json_parse("[1, \"two\", true, null]")
    check_int(json_len(idx), 4, "mixed array: length")
    check_int(json_type(json_at(idx, 0)), JSON_INT, "mixed array: int")
    check_int(json_type(json_at(idx, 1)), JSON_STRING, "mixed array: string")
    check_int(json_type(json_at(idx, 2)), JSON_BOOL, "mixed array: bool")
    check_int(json_type(json_at(idx, 3)), JSON_NULL, "mixed array: null")
}

fn test_get_missing_key() {
    json_clear()
    let idx = json_parse("\{\"a\":1}")
    let missing = json_get(idx, "b")
    check_int(missing, -1, "missing key returns -1")
}

fn test_at_out_of_bounds() {
    json_clear()
    let idx = json_parse("[1, 2]")
    let oob = json_at(idx, 5)
    check_int(oob, -1, "array out of bounds returns -1")
}

fn test_parse_invalid() {
    json_clear()
    let idx = json_parse("invalid")
    check_int(idx, -1, "invalid input returns -1")
}

fn test_serialize_null() {
    json_clear()
    let idx = json_parse("null")
    check_str(json_serialize(idx), "null", "serialize null")
}

fn test_serialize_bool() {
    json_clear()
    let idx = json_parse("true")
    check_str(json_serialize(idx), "true", "serialize true")

    json_clear()
    let idx2 = json_parse("false")
    check_str(json_serialize(idx2), "false", "serialize false")
}

fn test_serialize_int() {
    json_clear()
    let idx = json_parse("42")
    check_str(json_serialize(idx), "42", "serialize int")
}

fn test_serialize_string() {
    json_clear()
    let idx = json_parse("\"hello\"")
    check_str(json_serialize(idx), "\"hello\"", "serialize string")
}

fn test_serialize_array() {
    json_clear()
    let idx = json_parse("[1,2,3]")
    check_str(json_serialize(idx), "[1,2,3]", "serialize array")
}

fn test_serialize_object() {
    json_clear()
    let idx = json_parse("\{\"a\":1,\"b\":\"two\"}")
    let result = json_serialize(idx)
    check_str(result, "\{\"a\":1,\"b\":\"two\"}", "serialize object")
}

fn test_parse_whitespace() {
    json_clear()
    let idx = json_parse("  \{  \"key\"  :  \"value\"  }  ")
    check_int(json_type(idx), JSON_OBJECT, "whitespace: type")
    check_str(json_as_str(json_get(idx, "key")), "value", "whitespace: value")
}

fn test_parse_escaped_string() {
    json_clear()
    let idx = json_parse("\"hello\\nworld\"")
    check_str(json_as_str(idx), "hello\nworld", "escaped string: newline")
}

fn test_clear() {
    json_clear()
    json_parse("\{\"a\":1}")
    check_int(json_types.len(), 2, "clear: 2 nodes before")
    json_clear()
    check_int(json_types.len(), 0, "clear: 0 nodes after")
    check_int(json_str_vals.len(), 0, "clear: str_vals empty")
    check_int(json_int_vals.len(), 0, "clear: int_vals empty")
    check_int(json_parents.len(), 0, "clear: parents empty")
}

fn main() {
    test_parse_string()
    test_parse_int()
    test_parse_negative_int()
    test_parse_float()
    test_parse_bool_true()
    test_parse_bool_false()
    test_parse_null()
    test_parse_empty_array()
    test_parse_int_array()
    test_parse_string_array()
    test_parse_empty_object()
    test_parse_simple_object()
    test_parse_nested_object()
    test_parse_mixed_array()
    test_get_missing_key()
    test_at_out_of_bounds()
    test_parse_invalid()
    test_serialize_null()
    test_serialize_bool()
    test_serialize_int()
    test_serialize_string()
    test_serialize_array()
    test_serialize_object()
    test_parse_whitespace()
    test_parse_escaped_string()
    test_clear()

    io.println("All json tests complete")
}
