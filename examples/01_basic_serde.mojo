"""Example 01: Basic struct serialization and deserialization.

Demonstrates: write() and read() for struct <-> JSON with zero boilerplate.
"""

from morph.json import write, read


@fieldwise_init
struct Point(Defaultable, Movable):
    var x: Int
    var y: Int

    def __init__(out self):
        self.x = 0
        self.y = 0


@fieldwise_init
struct Person(Defaultable, Movable):
    var name: String
    var age: Int
    var active: Bool

    def __init__(out self):
        self.name = ""
        self.age = 0
        self.active = False


def main() raises:
    print("=== Basic Serialization ===\n")

    var p = Point(x=10, y=20)
    print("Point:", write(p))

    var person = Person(name="Alice", age=30, active=True)
    print("Person:", write(person))

    # Pretty-print with 2-space indent
    print("Pretty:\n" + write[pretty=True](person))

    print("=== Basic Deserialization ===\n")

    var pt = read[Point]('{"x":42,"y":7}')
    print("Point: x=" + String(pt.x) + " y=" + String(pt.y))

    var bob = read[Person]('{"name":"Bob","age":25,"active":false}')
    print("Person: " + bob.name + " age=" + String(bob.age))

    print("\n=== Round-Trip ===\n")

    var original = Person(name="Dave", age=40, active=True)
    var json = write(original)
    var restored = read[Person](json)
    print("Original: " + original.name + " age=" + String(original.age))
    print("JSON:     " + json)
    print("Restored: " + restored.name + " age=" + String(restored.age))
    print(
        "Match:    "
        + String(
            original.name == restored.name and original.age == restored.age
        )
    )
