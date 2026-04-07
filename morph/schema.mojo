"""JSON Schema generation from Mojo struct types via reflection.

Generates Draft 2020-12 compatible JSON Schema objects as strings.

Usage::

    from morph.schema import json_schema

    @fieldwise_init
    struct Person(Defaultable, Movable):
        var name: String
        var age: Int
        def __init__(out self):
            self.name = ""
            self.age = 0

    print(json_schema[Person]())
    # {"type":"object","properties":{"name":{"type":"string"},"age":{"type":"integer"}},"required":["name","age"]}
"""

from std.reflection import (
    struct_field_count,
    struct_field_names,
    struct_field_types,
    get_type_name,
    get_base_type_name,
)

from morph.reflect import (
    INT_NAME,
    INT64_NAME,
    BOOL_NAME,
    STRING_NAME,
    FLOAT64_NAME,
    FLOAT32_NAME,
    OPT_INT_NAME,
    OPT_STRING_NAME,
    OPT_FLOAT64_NAME,
    OPT_BOOL_NAME,
    LIST_INT_NAME,
    LIST_STRING_NAME,
    LIST_FLOAT64_NAME,
    LIST_BOOL_NAME,
)


# ---------------------------------------------------------------------------
# Public API
# ---------------------------------------------------------------------------


def json_schema[
    T: AnyType,
    rename: StaticString = "none",
    title: StaticString = "",
]() -> String:
    """Generate a JSON Schema string for struct type T.

    Parameters:
        T: The struct type to generate schema for.
        rename: Naming convention for property keys.
        title: Optional title for the root schema.

    Returns:
        A JSON Schema string (Draft 2020-12).
    """
    var schema = String('{"type":"object"')

    comptime
    if title != "":
        schema += ',"title":"' + String(title) + '"'

    schema += ',"properties":{'
    schema += _properties[T, rename]()
    schema += "}"

    var req = _required[T, rename]()
    if len(req) > 0:
        schema += ',"required":[' + req + "]"

    schema += "}"
    return schema^


# ---------------------------------------------------------------------------
# Internal helpers
# ---------------------------------------------------------------------------


def _properties[T: AnyType, rename: StaticString = "none"]() -> String:
    """Build the "properties" object contents."""
    comptime count = struct_field_count[T]()
    comptime names = struct_field_names[T]()
    comptime types = struct_field_types[T]()

    var out = String("")
    var first = True

    comptime
    for idx in range(count):
        comptime field_name = names[idx]
        comptime field_type = types[idx]
        comptime type_name = get_type_name[field_type]()

        if not first:
            out += ","
        first = False

        var key = String(field_name)

        comptime
        if rename == "camelCase":
            from morph.rename import snake_to_camel

            key = snake_to_camel(key)
        elif rename == "PascalCase":
            from morph.rename import snake_to_pascal

            key = snake_to_pascal(key)
        elif rename == "SCREAMING_SNAKE_CASE":
            from morph.rename import snake_to_screaming

            key = snake_to_screaming(key)

        out += '"' + key + '":'
        out += _type_schema[field_type, type_name]()

    return out^


def _required[T: AnyType, rename: StaticString = "none"]() -> String:
    """Build the "required" array contents (non-Optional fields)."""
    comptime count = struct_field_count[T]()
    comptime names = struct_field_names[T]()
    comptime types = struct_field_types[T]()

    var out = String("")
    var first = True

    comptime
    for idx in range(count):
        comptime field_type = types[idx]
        comptime type_name = get_type_name[field_type]()

        comptime
        if not (type_name == OPT_INT_NAME or type_name == OPT_STRING_NAME or type_name == OPT_FLOAT64_NAME or type_name == OPT_BOOL_NAME):
            if not first:
                out += ","
            first = False

            var key = String(names[idx])

            comptime
            if rename == "camelCase":
                from morph.rename import snake_to_camel

                key = snake_to_camel(key)
            elif rename == "PascalCase":
                from morph.rename import snake_to_pascal

                key = snake_to_pascal(key)
            elif rename == "SCREAMING_SNAKE_CASE":
                from morph.rename import snake_to_screaming

                key = snake_to_screaming(key)

            out += '"' + key + '"'

    return out^


def _type_schema[T: AnyType, type_name: StaticString]() -> String:
    """Return JSON Schema for a single type."""
    comptime
    if type_name == INT_NAME or type_name == INT64_NAME:
        return '{"type":"integer"}'
    elif type_name == BOOL_NAME:
        return '{"type":"boolean"}'
    elif type_name == STRING_NAME:
        return '{"type":"string"}'
    elif type_name == FLOAT64_NAME or type_name == FLOAT32_NAME:
        return '{"type":"number"}'
    elif type_name == OPT_INT_NAME:
        return '{"type":["integer","null"]}'
    elif type_name == OPT_STRING_NAME:
        return '{"type":["string","null"]}'
    elif type_name == OPT_FLOAT64_NAME:
        return '{"type":["number","null"]}'
    elif type_name == OPT_BOOL_NAME:
        return '{"type":["boolean","null"]}'
    elif type_name == LIST_INT_NAME:
        return '{"type":"array","items":{"type":"integer"}}'
    elif type_name == LIST_STRING_NAME:
        return '{"type":"array","items":{"type":"string"}}'
    elif type_name == LIST_FLOAT64_NAME:
        return '{"type":"array","items":{"type":"number"}}'
    elif type_name == LIST_BOOL_NAME:
        return '{"type":"array","items":{"type":"boolean"}}'
    else:
        var schema = String('{"type":"object","properties":{')
        schema += _properties[T]()
        schema += "}"
        var req = _required[T]()
        if len(req) > 0:
            schema += ',"required":[' + req + "]"
        schema += "}"
        return schema^
