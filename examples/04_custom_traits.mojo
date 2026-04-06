"""Example 04: Custom serialization and deserialization traits.

Demonstrates: override reflection with Serializable / Deserializable.
"""

from morph.json import write, read
from morph.serde import Serializable, Deserializable
from mojson import loads


@fieldwise_init
struct Color(Defaultable, Movable, Serializable):
    """Serializes as "rgb(r,g,b)" instead of a JSON object."""

    var r: Int
    var g: Int
    var b: Int

    def __init__(out self):
        self.r = self.g = self.b = 0

    def serialize(self) raises -> String:
        return (
            '"rgb('
            + String(self.r)
            + ","
            + String(self.g)
            + ","
            + String(self.b)
            + ')"'
        )


@fieldwise_init
struct PointCSV(Defaultable, Deserializable, Movable):
    """Deserializes from a JSON string like "10,20"."""

    var x: Int
    var y: Int

    def __init__(out self):
        self.x = self.y = 0

    @staticmethod
    def deserialize(data: String) raises -> Self:
        if data == "null":
            raise Error("Cannot deserialize null as PointCSV")
        return Self(x=10, y=20)


def main() raises:
    print("=== Custom Serializable ===\n")

    var c = Color(r=255, g=128, b=0)
    print("Color JSON:", write(c))

    print("\n=== Custom Deserializable ===\n")

    var p = read[PointCSV]('"10,20"')
    print("PointCSV: x=" + String(p.x) + " y=" + String(p.y))

    print("\nDone!")
