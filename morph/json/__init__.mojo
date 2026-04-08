"""JSON serialization and deserialization for morph.

Adds reflection-based struct mapping on top of a self-contained
JSON parser (no external dependencies).

Example:

    from morph.json import write, read

    @fieldwise_init
    struct Person(Defaultable, Movable):
        var name: String
        var age: Int
        def __init__(out self):
            self.name = ""
            self.age = 0

    var json = write(Person(name="Alice", age=30))
    var bob = read[Person]('{"name":"Bob","age":25}')
"""

from .writer import write, write_flat
from .reader import read, read_flat
