"""Format-agnostic serialization and deserialization traits.

Defines `Serializable` and `Deserializable` traits that types can implement
for custom serde behavior. When a type does not implement these traits,
morph falls back to reflection-based serde.

Example:

    @fieldwise_init
    struct Color(Serializable, Deserializable, Defaultable, Movable):
        var r: Int
        var g: Int
        var b: Int

        def __init__(out self):
            self.r = self.g = self.b = 0

        def serialize(self) raises -> String:
            return '"rgb(' + String(self.r) + "," + String(self.g) + "," + String(self.b) + ')"'

        @staticmethod
        def deserialize(data: String) raises -> Self:
            # parse "rgb(r,g,b)" ...
            return Self()
"""


trait Serializable:
    """Override reflection serialization.

    Implement this trait to control how a struct serializes to a string
    representation. The format backend (JSON, TOML, etc.) will call
    ``serialize()`` instead of walking fields via reflection.
    """

    def serialize(self) raises -> String:
        ...


trait Deserializable:
    """Override reflection deserialization.

    Implement this trait to control how a struct deserializes from a
    string representation. The format backend will call
    ``deserialize()`` instead of walking fields via reflection.
    """

    @staticmethod
    def deserialize(data: String) raises -> Self:
        ...
