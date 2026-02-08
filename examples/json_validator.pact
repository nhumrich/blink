// json_validator.pact — Recursive types, modules, doc-tests
//
// Demonstrates: recursive types (JsonValue), mod { } blocks,
//               imports, doc-tests (/// with code), @deprecated,
//               struct construction shorthand, Closeable trait,
//               operator semantics, Display impl

import pact.core.{ConversionError}

/// A recursive JSON value type.
/// Covers all JSON data types as an algebraic data type.
///
/// ```
/// let val = JsonValue.Number(42.0)
/// assert_eq(val.is_number(), true)
/// ```
type JsonValue {
    Null
    Boolean(Bool)
    Number(Float)
    Str(Str)
    Array(List[JsonValue])
    Object(Map[Str, JsonValue])
}

impl Display for JsonValue {
    /// Render a JsonValue as a string.
    ///
    /// ```
    /// assert_eq(JsonValue.Null.display(), "null")
    /// assert_eq(JsonValue.Boolean(true).display(), "true")
    /// assert_eq(JsonValue.Number(3.14).display(), "3.14")
    /// ```
    fn display(self) -> Str {
        match self {
            Null => "null"
            Boolean(b) => if b { "true" } else { "false" }
            Number(n) => "{n}"
            Str(s) => "\"{s}\""
            Array(items) => {
                let parts = items.into_iter()
                    .map(fn(v) { v.display() })
                    .collect()
                "[{parts.join(", ")}]"
            }
            Object(entries) => {
                let parts = entries.into_iter()
                    .map(fn(kv) {
                        let (k, v) = kv
                        "\"{k}\": {v.display()}"
                    })
                    .collect()
                "\{{parts.join(", ")}\}"
            }
        }
    }
}

/// Check if a JsonValue is a number.
fn is_number(val: JsonValue) -> Bool {
    match val {
        Number(_) => true
        _ => false
    }
}

/// Check if a JsonValue is null.
fn is_null(val: JsonValue) -> Bool {
    match val {
        Null => true
        _ => false
    }
}

// -- Schema validation module --

mod schema {
    @derive(Eq, Display)
    type SchemaType {
        StringType
        NumberType
        BooleanType
        ArrayType
        ObjectType
        NullType
    }

    type SchemaRule {
        field: Str
        expected: SchemaType
        required: Bool = true
    }

    type ValidationError {
        path: Str
        message: Str
    }

    fn type_of(val: JsonValue) -> SchemaType {
        match val {
            Null => NullType
            Boolean(_) => BooleanType
            Number(_) => NumberType
            Str(_) => StringType
            Array(_) => ArrayType
            Object(_) => ObjectType
        }
    }

    pub fn validate_field(obj: Map[Str, JsonValue], rule: SchemaRule) -> Result[(), ValidationError] {
        match obj.get(rule.field) {
            None => {
                if rule.required {
                    Err(ValidationError {
                        path: rule.field
                        message: "required field missing"
                    })
                } else {
                    Ok(())
                }
            }
            Some(val) => {
                let actual = type_of(val)
                if actual == rule.expected {
                    Ok(())
                } else {
                    Err(ValidationError {
                        path: rule.field
                        message: "expected {rule.expected}, got {actual}"
                    })
                }
            }
        }
    }

    test "validate_field catches missing required field" {
        let obj = Map.new()
        let rule = SchemaRule { field: "name", expected: StringType }
        let result = validate_field(obj, rule)
        assert(result.is_err())
    }

    test "validate_field allows missing optional field" {
        let obj = Map.new()
        let rule = SchemaRule { field: "nickname", expected: StringType, required: false }
        let result = validate_field(obj, rule)
        assert(result.is_ok())
    }

    test "validate_field checks type mismatch" {
        let mut obj = Map.new()
        obj.insert("age", JsonValue.Str("not a number"))
        let rule = SchemaRule { field: "age", expected: NumberType }
        let result = validate_field(obj, rule)
        assert(result.is_err())
    }
}

// -- ValidationContext with Closeable --

type ValidationContext {
    errors: [schema.ValidationError]
    strict: Bool = false
}

impl Closeable for ValidationContext {
    fn close(self) {
        // Flush collected errors to log
    }
}

/// Old validation function, superseded by validate_v2.
@deprecated("Use validate_v2 instead")
fn validate(val: JsonValue, rules: [schema.SchemaRule]) -> [schema.ValidationError] {
    match val {
        Object(obj) => {
            rules.into_iter()
                .filter_map(fn(rule) {
                    match schema.validate_field(obj, rule) {
                        Err(e) => Some(e)
                        Ok(_) => None
                    }
                })
                .collect()
        }
        _ => [schema.ValidationError { path: "", message: "expected object" }]
    }
}

/// Validate a JSON value against schema rules.
/// Uses Closeable context + struct construction shorthand.
fn validate_v2(val: JsonValue, rules: [schema.SchemaRule], -- strict: Bool = false) -> Result[(), [schema.ValidationError]] {
    // Struct construction shorthand: compiler infers ValidationContext
    with ValidationContext { strict: strict } as ctx {
        let errors = match val {
            Object(obj) => {
                rules.into_iter()
                    .filter_map(fn(rule) {
                        match schema.validate_field(obj, rule) {
                            Err(e) => Some(e)
                            Ok(_) => None
                        }
                    })
                    .collect()
            }
            _ => [schema.ValidationError { path: "", message: "expected object" }]
        }

        if errors.len() > 0 {
            Err(errors)
        } else {
            Ok(())
        }
    }
}

fn main() {
    let user_json = JsonValue.Object(Map.from([
        ("name", JsonValue.Str("Alice"))
        ("age", JsonValue.Number(30.0))
        ("active", JsonValue.Boolean(true))
    ]))

    io.println("User JSON: {user_json}")

    let rules = [
        schema.SchemaRule { field: "name", expected: schema.StringType }
        schema.SchemaRule { field: "age", expected: schema.NumberType }
        schema.SchemaRule { field: "email", expected: schema.StringType }
    ]

    match validate_v2(user_json, rules) {
        Ok(_) => io.println("Validation passed")
        Err(errors) => {
            for e in errors {
                io.println("Validation error at '{e.path}': {e.message}")
            }
        }
    }

    // Recursive structure: nested JSON
    let nested = JsonValue.Object(Map.from([
        ("users", JsonValue.Array([
            JsonValue.Object(Map.from([
                ("name", JsonValue.Str("Bob"))
            ]))
            JsonValue.Null
        ]))
    ]))
    io.println("Nested: {nested}")
}

// -- Tests --

test "JsonValue Display for primitives" {
    assert_eq(JsonValue.Null.display(), "null")
    assert_eq(JsonValue.Boolean(true).display(), "true")
    assert_eq(JsonValue.Boolean(false).display(), "false")
    assert_eq(JsonValue.Str("hello").display(), "\"hello\"")
}

test "JsonValue Display for array" {
    let arr = JsonValue.Array([JsonValue.Number(1.0), JsonValue.Number(2.0)])
    assert_eq(arr.display(), "[1.0, 2.0]")
}

test "recursive JsonValue construction" {
    let val = JsonValue.Object(Map.from([
        ("nested", JsonValue.Array([JsonValue.Null, JsonValue.Boolean(true)]))
    ]))
    let s = val.display()
    assert(s.len() > 0)
}

test "validate_v2 catches missing fields" {
    let val = JsonValue.Object(Map.from([
        ("name", JsonValue.Str("Alice"))
    ]))
    let rules = [
        schema.SchemaRule { field: "name", expected: schema.StringType }
        schema.SchemaRule { field: "email", expected: schema.StringType }
    ]
    let result = validate_v2(val, rules)
    assert(result.is_err())
    assert_eq(result.unwrap_err().len(), 1)
}

test "validate_v2 passes for valid object" {
    let val = JsonValue.Object(Map.from([
        ("name", JsonValue.Str("Alice"))
        ("age", JsonValue.Number(30.0))
    ]))
    let rules = [
        schema.SchemaRule { field: "name", expected: schema.StringType }
        schema.SchemaRule { field: "age", expected: schema.NumberType }
    ]
    let result = validate_v2(val, rules)
    assert(result.is_ok())
}

test "validate_v2 rejects non-object" {
    let val = JsonValue.Number(42.0)
    let rules = [schema.SchemaRule { field: "x", expected: schema.NumberType }]
    let result = validate_v2(val, rules)
    assert(result.is_err())
}

test "is_number and is_null helpers" {
    assert(is_number(JsonValue.Number(3.14)))
    assert(!is_number(JsonValue.Str("hello")))
    assert(is_null(JsonValue.Null))
    assert(!is_null(JsonValue.Boolean(false)))
}
