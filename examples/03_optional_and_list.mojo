"""Example 03: Optional and List fields.

Demonstrates: Optional[T] fields (null/missing) and List[T] fields.
"""

from morph.json import write, read
from std.collections import Optional, List


@fieldwise_init
struct Profile(Defaultable, Movable):
    var username: String
    var bio: Optional[String]
    var score: Optional[Int]

    def __init__(out self):
        self.username = ""
        self.bio = None
        self.score = None


@fieldwise_init
struct Config(Defaultable, Movable):
    var tags: List[String]
    var scores: List[Int]
    var weights: List[Float64]

    def __init__(out self):
        self.tags = List[String]()
        self.scores = List[Int]()
        self.weights = List[Float64]()


def main() raises:
    print("=== Optional Fields ===\n")

    var full = Profile(username="dev42", bio=String("Mojo fan"), score=100)
    print("With values:", write(full))

    var minimal = Profile(username="anon", bio=None, score=None)
    print("With nulls:", write(minimal))

    # Missing optional keys default to None on read
    var parsed = read[Profile]('{"username":"ghost"}')
    print(
        "Missing keys: bio="
        + ("None" if not parsed.bio else parsed.bio.value())
    )

    print("\n=== List Fields ===\n")

    var tags = List[String]()
    tags.append("mojo")
    tags.append("json")
    var scores = List[Int]()
    scores.append(95)
    scores.append(87)
    var weights = List[Float64]()
    weights.append(0.5)
    weights.append(1.5)

    var cfg = Config(tags=tags^, scores=scores^, weights=weights^)
    print("Config:", write(cfg))

    var restored = read[Config](
        '{"tags":["a","b","c"],"scores":[1,2],"weights":[0.1]}'
    )
    print("Restored tags count:", len(restored.tags))
    print("Restored scores count:", len(restored.scores))
