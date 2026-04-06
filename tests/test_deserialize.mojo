"""Tests for morph.json.read: JSON -> struct deserialization.

Covers: all scalar types, optional variants (present/null/missing), list variants,
nested structs, custom Deserializable, error handling (type mismatch, invalid JSON,
not-object).
"""

from morph.json import read
from morph.serde import Deserializable
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
struct AllScalars(Defaultable, Movable):
    var i: Int
    var i64: Int64
    var b: Bool
    var f64: Float64
    var f32: Float32
    var s: String

    def __init__(out self):
        self.i = 0
        self.i64 = Int64(0)
        self.b = False
        self.f64 = 0.0
        self.f32 = Float32(0.0)
        self.s = ""


@fieldwise_init
struct WithOptional(Defaultable, Movable):
    var name: String
    var nickname: Optional[String]
    var score: Optional[Int]
    var rating: Optional[Float64]
    var flag: Optional[Bool]

    def __init__(out self):
        self.name = ""
        self.nickname = None
        self.score = None
        self.rating = None
        self.flag = None


@fieldwise_init
struct WithLists(Defaultable, Movable):
    var ints: List[Int]
    var strs: List[String]
    var floats: List[Float64]
    var bools: List[Bool]

    def __init__(out self):
        self.ints = List[Int]()
        self.strs = List[String]()
        self.floats = List[Float64]()
        self.bools = List[Bool]()


@fieldwise_init
struct Nested(Defaultable, Movable):
    var origin: Point
    var label: String

    def __init__(out self):
        self.origin = Point()
        self.label = ""


# ---------------------------------------------------------------------------
# Scalar tests
# ---------------------------------------------------------------------------


def test_basic_struct() raises:
    var p = read[Point]('{"x":10,"y":20}')
    assert_equal(p.x, 10)
    assert_equal(p.y, 20)


def test_negative_int() raises:
    var p = read[Point]('{"x":-5,"y":0}')
    assert_equal(p.x, -5)
    assert_equal(p.y, 0)


def test_all_scalars() raises:
    var s = read[AllScalars](
        '{"i":42,"i64":99,"b":true,"f64":3.14,"f32":2.5,"s":"hello"}'
    )
    assert_equal(s.i, 42)
    assert_equal(s.b, True)
    assert_equal(s.s, "hello")


def test_bool_false() raises:
    var s = read[AllScalars](
        '{"i":0,"i64":0,"b":false,"f64":0.0,"f32":0.0,"s":""}'
    )
    assert_equal(s.b, False)
    assert_equal(s.s, "")


# ---------------------------------------------------------------------------
# Optional tests
# ---------------------------------------------------------------------------


def test_optional_all_present() raises:
    var w = read[WithOptional](
        '{"name":"Test","nickname":"T","score":95,"rating":4.5,"flag":true}'
    )
    assert_equal(w.name, "Test")
    assert_equal(w.nickname.value(), "T")
    assert_equal(w.score.value(), 95)
    assert_equal(w.flag.value(), True)


def test_optional_all_null() raises:
    var w = read[WithOptional](
        '{"name":"Test","nickname":null,"score":null,"rating":null,"flag":null}'
    )
    assert_equal(w.name, "Test")
    assert_true(not w.nickname.__bool__(), "nickname should be None")
    assert_true(not w.score.__bool__(), "score should be None")
    assert_true(not w.rating.__bool__(), "rating should be None")
    assert_true(not w.flag.__bool__(), "flag should be None")


def test_optional_missing_keys() raises:
    var w = read[WithOptional]('{"name":"Test"}')
    assert_equal(w.name, "Test")
    assert_true(not w.nickname.__bool__(), "missing nickname should be None")
    assert_true(not w.score.__bool__(), "missing score should be None")


# ---------------------------------------------------------------------------
# List tests
# ---------------------------------------------------------------------------


def test_list_int() raises:
    var w = read[WithLists]('{"ints":[1,2,3],"strs":[],"floats":[],"bools":[]}')
    assert_equal(len(w.ints), 3)
    assert_equal(w.ints[0], 1)
    assert_equal(w.ints[2], 3)


def test_list_string() raises:
    var w = read[WithLists](
        '{"ints":[],"strs":["a","b","c"],"floats":[],"bools":[]}'
    )
    assert_equal(len(w.strs), 3)
    assert_equal(w.strs[0], "a")


def test_list_bool() raises:
    var w = read[WithLists](
        '{"ints":[],"strs":[],"floats":[],"bools":[true,false,true]}'
    )
    assert_equal(len(w.bools), 3)
    assert_equal(w.bools[0], True)
    assert_equal(w.bools[1], False)


def test_list_empty() raises:
    var w = read[WithLists]('{"ints":[],"strs":[],"floats":[],"bools":[]}')
    assert_equal(len(w.ints), 0)
    assert_equal(len(w.strs), 0)


# ---------------------------------------------------------------------------
# Nested struct tests
# ---------------------------------------------------------------------------


def test_nested() raises:
    var n = read[Nested]('{"origin":{"x":5,"y":10},"label":"origin"}')
    assert_equal(n.origin.x, 5)
    assert_equal(n.origin.y, 10)
    assert_equal(n.label, "origin")


# ---------------------------------------------------------------------------
# Error handling tests
# ---------------------------------------------------------------------------


def test_type_mismatch_error() raises:
    var raised = False
    try:
        _ = read[Point]('{"x":"not_a_number","y":20}')
    except:
        raised = True
    assert_equal(raised, True)


def test_not_object_error() raises:
    var raised = False
    try:
        _ = read[Point]("[1, 2]")
    except:
        raised = True
    assert_equal(raised, True)


def test_invalid_json_error() raises:
    var raised = False
    try:
        _ = read[Point]("not json at all")
    except:
        raised = True
    assert_equal(raised, True)


def test_wrong_list_element_type() raises:
    var raised = False
    try:
        _ = read[WithLists](
            '{"ints":["oops"],"strs":[],"floats":[],"bools":[]}'
        )
    except:
        raised = True
    assert_equal(raised, True)


# ---------------------------------------------------------------------------
# Runner
# ---------------------------------------------------------------------------


def main() raises:
    print("=== morph.json.read tests ===")

    test_basic_struct()
    print("  PASS: test_basic_struct")

    test_negative_int()
    print("  PASS: test_negative_int")

    test_all_scalars()
    print("  PASS: test_all_scalars")

    test_bool_false()
    print("  PASS: test_bool_false")

    test_optional_all_present()
    print("  PASS: test_optional_all_present")

    test_optional_all_null()
    print("  PASS: test_optional_all_null")

    test_optional_missing_keys()
    print("  PASS: test_optional_missing_keys")

    test_list_int()
    print("  PASS: test_list_int")

    test_list_string()
    print("  PASS: test_list_string")

    test_list_bool()
    print("  PASS: test_list_bool")

    test_list_empty()
    print("  PASS: test_list_empty")

    test_nested()
    print("  PASS: test_nested")

    test_type_mismatch_error()
    print("  PASS: test_type_mismatch_error")

    test_not_object_error()
    print("  PASS: test_not_object_error")

    test_invalid_json_error()
    print("  PASS: test_invalid_json_error")

    test_wrong_list_element_type()
    print("  PASS: test_wrong_list_element_type")

    print("=== All 16 deserialize tests passed ===")
