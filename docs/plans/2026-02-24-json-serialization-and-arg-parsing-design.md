# JSON Serialization (#44) & Arg Parsing (#46) Design

## #44 JSON Serialization

### Two Layers

**Layer 1: Builder API** — additions to `lib/std/json.pact` for programmatic JSON construction using existing parallel-array storage.

```pact
pub fn json_new_object() -> Int
pub fn json_new_array() -> Int
pub fn json_new_str(val: Str) -> Int
pub fn json_new_int(val: Int) -> Int
pub fn json_new_float(val: Float) -> Int
pub fn json_new_bool(val: Int) -> Int
pub fn json_new_null() -> Int
pub fn json_set(obj: Int, key: Str, val: Int)
pub fn json_push(arr: Int, val: Int)
pub fn json_encode(idx: Int) -> Str   // alias for json_serialize
```

**Layer 2: @derive(Serialize, Deserialize)** — codegen auto-generates `to_json() -> Str` and `from_json(input: Str) -> Result[T, Str]`.

### Serialization Rules

**Structs** — named fields become JSON object keys:
```pact
@derive(Serialize)
type User { name: Str, age: Int }
// User { name: "Alice", age: 30 } → {"name":"Alice","age":30}
```

**Simple enums** (all unit variants) — serialize as strings:
```pact
type Color { Red, Green, Blue }
// Color.Red → "Red"
```

**Data enums** — internally tagged, OpenAPI-style discriminator on `"type"`:
```pact
type Shape {
    Circle(radius: Float)
    Rectangle(width: Float, height: Float)
    Point
}
// Circle(radius: 1.5) → {"type":"Circle","radius":1.5}
// Rectangle(width: 2.0, height: 3.0) → {"type":"Rectangle","width":2.0,"height":3.0}
// Point → {"type":"Point"}
```

**Unnamed single-field variants** — use `"value"` as key:
```pact
type Result[T, E] { Ok(T), Err(E) }
// Ok(42) → {"type":"Ok","value":42}
```

**Nested structs/collections** — recursive serialization:
- Nested struct → nested object
- `List[T]` → JSON array
- `Map[Str, V]` → JSON object

### Deserialization

`@derive(Deserialize)` generates `from_json(input: Str) -> Result[T, Str]`:
- Parse via `json_parse()`
- Read fields from root object
- Construct struct/enum literal
- Return error string on type mismatch or missing fields

### Codegen Approach

When processing a struct/enum with `@derive(Serialize)`:
1. Check `sf_entries` for struct fields and types
2. Emit a C function `pact_TypeName_to_json(pact_TypeName* val)` that:
   - Builds JSON string via snprintf for primitives
   - Recursively calls `_to_json()` for nested structs
   - Iterates list/map for collections
3. Register `to_json()` as a method on the type

---

## #46 Argument Parsing Library

### Architecture

Pure stdlib module `lib/std/args.pact`. No codegen changes. Uses `arg_count()`, `get_arg()`, string methods.

### API

```pact
import std.args

let parser = ArgParser.new("mytool", "A cool CLI tool")

// Top-level flags/options
parser.add_flag("--verbose", "-v", "Enable verbose output")
parser.add_option("--output", "-o", "Output file path")

// Subcommands
let build_cmd = parser.add_command("build", "Compile source files")
build_cmd.add_option("--target", "-t", "Target platform")
build_cmd.add_positional("source", "Source file to compile")

let run_cmd = parser.add_command("run", "Compile and run")
run_cmd.add_positional("source", "Source file to run")

let result = parser.parse()

result.has("verbose")           // -> Bool
result.get("output")            // -> Str ("" if unset)
result.command()                // -> Str
result.positional("source")    // -> Str
```

### MVP Features

- Named flags (`--verbose`, `-v`) — boolean
- Options with values (`--output path`)
- Positional arguments (named, ordered)
- Subcommands with own flags/options/positionals
- Auto `--help` generation
- Errors: unknown flags, missing required options, missing positionals

### Not in MVP

- `--flag=value` syntax
- Typed values (everything is Str)
- Env var fallback
- Shell completions
- Mutually exclusive groups
