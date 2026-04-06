"""Example 05: Field renaming strategies.

Demonstrates: converting between naming conventions for JSON interop.
"""

from morph.rename import (
    snake_to_camel,
    camel_to_snake,
    snake_to_pascal,
    snake_to_screaming,
    apply_rename,
)


def main() raises:
    print("=== Naming Conversions ===\n")

    var fields = List[String]()
    fields.append("first_name")
    fields.append("last_name")
    fields.append("http_status_code")
    fields.append("created_at")

    for i in range(len(fields)):
        var f = fields[i]
        print(f + ":")
        print("  camelCase:       " + snake_to_camel(f))
        print("  PascalCase:      " + snake_to_pascal(f))
        print("  SCREAMING_SNAKE: " + snake_to_screaming(f))

    print("\n=== Round-Trip ===\n")

    var original = "http_status_code"
    var camel = snake_to_camel(original)
    var back = camel_to_snake(camel)
    print(original + " -> " + camel + " -> " + back)
    print("Match: " + String(original == back))

    print("\n=== apply_rename() ===\n")

    var strategies = List[String]()
    strategies.append("camelCase")
    strategies.append("PascalCase")
    strategies.append("SCREAMING_SNAKE_CASE")
    strategies.append("snake_case")
    strategies.append("none")

    for i in range(len(strategies)):
        var s = strategies[i]
        print(s + ": " + apply_rename("user_name", s))
