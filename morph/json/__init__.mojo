"""JSON serialization and deserialization for morph.

Uses mojson as the underlying JSON parsing/serialization engine and
adds reflection-based struct mapping on top.

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

from .writer import write
from .reader import read
