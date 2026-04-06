# morph

Reflection-driven serialization, deserialization, and data transformation for Mojo.

Inspired by [reflect-cpp](https://github.com/getml/reflect-cpp) — zero-boilerplate struct serde using compile-time reflection.

## Why morph?

Mojo structs don't serialize out of the box. `morph` uses compile-time reflection to automatically map struct fields to/from JSON — no manual `to_json()` or `from_json()` methods needed.

```mojo
from morph.json import write, read

@fieldwise_init
struct Person(Defaultable, Movable):
    var name: String
    var age: Int
    var active: Bool

    def __init__(out self):
        self.name = ""
        self.age = 0
        self.active = False

fn main() raises:
    var p = Person(name="Alice", age=30, active=True)
    print(write(p))         # {"name":"Alice","age":30,"active":true}

    var q = read[Person]('{"name":"Bob","age":25,"active":false}')
    print(q.name)            # Bob
```

## Requirements

[pixi](https://pixi.sh) package manager

## Installation

Add morph to your project's `pixi.toml`:

```toml
[workspace]
channels = ["https://conda.modular.com/max-nightly", "conda-forge"]
preview = ["pixi-build"]

[dependencies]
morph = { git = "https://github.com/ehsanmok/morph.git" }
```

Then run:

```bash
pixi install
```

## Supported Types

| Type | Serialize | Deserialize |
|------|-----------|-------------|
| `Int`, `Int64` | yes | yes |
| `Bool` | yes | yes |
| `Float64`, `Float32` | yes | yes |
| `String` | yes | yes |
| `Optional[T]` | yes (null) | yes (null/missing) |
| `List[T]` | yes | yes |
| Nested structs | yes | yes |
| Custom traits | yes | yes |

Where `T` is one of `Int`, `String`, `Float64`, `Bool`.

## Features

- **Zero boilerplate**: works on any struct via compile-time reflection
- **Round-trip safe**: `read(write(x))` preserves data
- **Custom serde**: implement `Serializable`/`Deserializable` to override
- **Field renaming**: `snake_case` <-> `camelCase` / `PascalCase` / `SCREAMING_SNAKE`
- **Pretty print**: `write[pretty=True](value)` for formatted output
- **Rich errors**: type mismatch, missing field, invalid JSON

## API

```mojo
from morph.json import write, read

# Serialize struct -> JSON string
var json = write(value)
var pretty = write[pretty=True](value)

# Deserialize JSON string -> struct
var obj = read[MyStruct](json_string)
```

### Custom Traits

```mojo
from morph.serde import Serializable, Deserializable

struct Color(Serializable, Defaultable, Movable):
    var r: Int
    var g: Int
    var b: Int

    def serialize(self) raises -> String:
        return '"rgb(' + String(self.r) + "," + String(self.g) + "," + String(self.b) + ')"'
```

### Field Renaming

```mojo
from morph.rename import snake_to_camel, camel_to_snake, apply_rename

var camel = snake_to_camel("user_name")    # "userName"
var snake = camel_to_snake("userName")      # "user_name"
var result = apply_rename("user_name", "PascalCase")  # "UserName"
```

## Development

```bash
git clone https://github.com/ehsanmok/morph.git && cd morph
pixi install
pixi run tests
```

### Tasks

```bash
pixi run tests          # Run all tests + examples (72 tests)
pixi run test-serialize # Run serialize tests only
pixi run test-deserialize
pixi run test-roundtrip
pixi run test-edge-cases
pixi run test-reflect
pixi run test-rename
pixi run examples       # Run all examples
pixi run example-basic  # Run individual example
pixi run format         # Format code
pixi run docs           # Generate and open API docs
pixi run docs-build     # Generate docs to target/doc/
```

## License

[MIT](./LICENSE)
