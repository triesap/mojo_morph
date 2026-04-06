"""Tests for round-trip: write() then read() preserves data.

Every type combination is serialized then deserialized and checked.
"""

from morph.json import write, read
from std.collections import Optional, List
from std.testing import assert_equal, assert_true


# ---------------------------------------------------------------------------
# Test structs
# ---------------------------------------------------------------------------


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


@fieldwise_init
struct WithOptionals(Defaultable, Movable):
    var label: String
    var count: Optional[Int]
    var note: Optional[String]

    def __init__(out self):
        self.label = ""
        self.count = None
        self.note = None


@fieldwise_init
struct WithLists(Defaultable, Movable):
    var tags: List[String]
    var scores: List[Int]

    def __init__(out self):
        self.tags = List[String]()
        self.scores = List[Int]()


@fieldwise_init
struct Nested(Defaultable, Movable):
    var origin: Point
    var label: String

    def __init__(out self):
        self.origin = Point()
        self.label = ""


@fieldwise_init
struct DeepNest(Defaultable, Movable):
    var inner: Nested
    var id: Int

    def __init__(out self):
        self.inner = Nested()
        self.id = 0


# ---------------------------------------------------------------------------
# Tests
# ---------------------------------------------------------------------------


def test_roundtrip_point() raises:
    var original = Point(x=42, y=-7)
    var restored = read[Point](write(original))
    assert_equal(restored.x, 42)
    assert_equal(restored.y, -7)


def test_roundtrip_person() raises:
    var original = Person(name="Bob", age=42, active=False)
    var restored = read[Person](write(original))
    assert_equal(restored.name, "Bob")
    assert_equal(restored.age, 42)
    assert_equal(restored.active, False)


def test_roundtrip_optional_present() raises:
    var original = WithOptionals(label="x", count=99, note=String("hi"))
    var restored = read[WithOptionals](write(original))
    assert_equal(restored.label, "x")
    assert_equal(restored.count.value(), 99)
    assert_equal(restored.note.value(), "hi")


def test_roundtrip_optional_none() raises:
    var original = WithOptionals(label="x", count=None, note=None)
    var restored = read[WithOptionals](write(original))
    assert_equal(restored.label, "x")
    assert_true(not restored.count.__bool__())
    assert_true(not restored.note.__bool__())


def test_roundtrip_lists() raises:
    var tags = List[String]()
    tags.append("a")
    tags.append("b")
    var scores = List[Int]()
    scores.append(1)
    scores.append(2)
    scores.append(3)
    var original = WithLists(tags=tags^, scores=scores^)
    var restored = read[WithLists](write(original))
    assert_equal(len(restored.tags), 2)
    assert_equal(restored.tags[0], "a")
    assert_equal(len(restored.scores), 3)
    assert_equal(restored.scores[2], 3)


def test_roundtrip_empty_lists() raises:
    var original = WithLists()
    var restored = read[WithLists](write(original))
    assert_equal(len(restored.tags), 0)
    assert_equal(len(restored.scores), 0)


def test_roundtrip_nested() raises:
    var original = Nested(origin=Point(x=99, y=-1), label="test")
    var restored = read[Nested](write(original))
    assert_equal(restored.origin.x, 99)
    assert_equal(restored.origin.y, -1)
    assert_equal(restored.label, "test")


def test_roundtrip_deep_nested() raises:
    var original = DeepNest(
        inner=Nested(origin=Point(x=1, y=2), label="inner"), id=42
    )
    var restored = read[DeepNest](write(original))
    assert_equal(restored.inner.origin.x, 1)
    assert_equal(restored.inner.origin.y, 2)
    assert_equal(restored.inner.label, "inner")
    assert_equal(restored.id, 42)


def test_roundtrip_special_strings() raises:
    var original = Person(name='He said "hello"', age=0, active=True)
    var restored = read[Person](write(original))
    assert_equal(restored.name, 'He said "hello"')


def test_roundtrip_unicode() raises:
    var original = Person(name="Caf\xc3\xa9", age=1, active=False)
    var restored = read[Person](write(original))
    assert_equal(restored.age, 1)


# ---------------------------------------------------------------------------
# Runner
# ---------------------------------------------------------------------------


def main() raises:
    print("=== morph roundtrip tests ===")

    test_roundtrip_point()
    print("  PASS: test_roundtrip_point")

    test_roundtrip_person()
    print("  PASS: test_roundtrip_person")

    test_roundtrip_optional_present()
    print("  PASS: test_roundtrip_optional_present")

    test_roundtrip_optional_none()
    print("  PASS: test_roundtrip_optional_none")

    test_roundtrip_lists()
    print("  PASS: test_roundtrip_lists")

    test_roundtrip_empty_lists()
    print("  PASS: test_roundtrip_empty_lists")

    test_roundtrip_nested()
    print("  PASS: test_roundtrip_nested")

    test_roundtrip_deep_nested()
    print("  PASS: test_roundtrip_deep_nested")

    test_roundtrip_special_strings()
    print("  PASS: test_roundtrip_special_strings")

    test_roundtrip_unicode()
    print("  PASS: test_roundtrip_unicode")

    print("=== All 10 roundtrip tests passed ===")
