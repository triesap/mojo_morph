"""Tests for morph.json.write: struct -> JSON serialization.

Covers: all scalar types, optional variants, list variants, nested structs,
empty structs, custom Serializable, string escaping, pretty mode.
"""

from morph.json import write
from morph.serde import Serializable
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
    var opt_int: Optional[Int]
    var opt_str: Optional[String]
    var opt_f64: Optional[Float64]
    var opt_bool: Optional[Bool]

    def __init__(out self):
        self.opt_int = None
        self.opt_str = None
        self.opt_f64 = None
        self.opt_bool = None


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


struct Empty(Defaultable, Movable):
    def __init__(out self):
        pass


@fieldwise_init
struct CustomColor(Defaultable, Movable, Serializable):
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
struct StringHolder(Defaultable, Movable):
    var v: String

    def __init__(out self):
        self.v = ""


# ---------------------------------------------------------------------------
# Scalar tests
# ---------------------------------------------------------------------------


def test_int() raises:
    assert_equal(write(Point(x=10, y=20)), '{"x":10,"y":20}')


def test_int_negative() raises:
    assert_equal(write(Point(x=-5, y=0)), '{"x":-5,"y":0}')


def test_all_scalars() raises:
    var s = AllScalars(
        i=42,
        i64=Int64(99),
        b=True,
        f64=3.14,
        f32=Float32(2.5),
        s="hello",
    )
    var json = write(s)
    assert_true("42" in json, "should contain int value")
    assert_true("99" in json, "should contain int64 value")
    assert_true("true" in json, "should contain bool value")
    assert_true('"hello"' in json, "should contain string value")


def test_bool_false() raises:
    var s = AllScalars(
        i=0,
        i64=Int64(0),
        b=False,
        f64=0.0,
        f32=Float32(0.0),
        s="",
    )
    var json = write(s)
    assert_true('"b":false' in json, "should contain false")
    assert_true('"s":""' in json, "should contain empty string")


# ---------------------------------------------------------------------------
# Optional tests
# ---------------------------------------------------------------------------


def test_optional_all_present() raises:
    var w = WithOptional(
        opt_int=42, opt_str=String("hi"), opt_f64=1.5, opt_bool=True
    )
    var json = write(w)
    assert_true('"opt_int":42' in json)
    assert_true('"opt_str":"hi"' in json)
    assert_true('"opt_bool":true' in json)


def test_optional_all_none() raises:
    var w = WithOptional()
    var json = write(w)
    assert_true('"opt_int":null' in json)
    assert_true('"opt_str":null' in json)
    assert_true('"opt_f64":null' in json)
    assert_true('"opt_bool":null' in json)


# ---------------------------------------------------------------------------
# List tests
# ---------------------------------------------------------------------------


def test_list_int() raises:
    var ints = List[Int]()
    ints.append(1)
    ints.append(2)
    ints.append(3)
    var w = WithLists(
        ints=ints^,
        strs=List[String](),
        floats=List[Float64](),
        bools=List[Bool](),
    )
    var json = write(w)
    assert_true('"ints":[1,2,3]' in json)


def test_list_string() raises:
    var strs = List[String]()
    strs.append("a")
    strs.append("b")
    var w = WithLists(
        ints=List[Int](),
        strs=strs^,
        floats=List[Float64](),
        bools=List[Bool](),
    )
    var json = write(w)
    assert_true('"strs":["a","b"]' in json)


def test_list_bool() raises:
    var bools = List[Bool]()
    bools.append(True)
    bools.append(False)
    var w = WithLists(
        ints=List[Int](),
        strs=List[String](),
        floats=List[Float64](),
        bools=bools^,
    )
    var json = write(w)
    assert_true('"bools":[true,false]' in json)


def test_list_empty() raises:
    var w = WithLists()
    var json = write(w)
    assert_true('"ints":[]' in json)
    assert_true('"strs":[]' in json)


# ---------------------------------------------------------------------------
# Struct tests
# ---------------------------------------------------------------------------


def test_nested() raises:
    var n = Nested(origin=Point(x=5, y=10), label="origin")
    assert_equal(write(n), '{"origin":{"x":5,"y":10},"label":"origin"}')


def test_empty() raises:
    assert_equal(write(Empty()), "{}")


def test_custom_serializable() raises:
    var c = CustomColor(r=255, g=128, b=0)
    assert_equal(write(c), '"rgb(255,128,0)"')


# ---------------------------------------------------------------------------
# String escaping
# ---------------------------------------------------------------------------


def test_string_escaping_quotes() raises:
    var s = StringHolder(v='He said "hi"')
    var json = write(s)
    assert_true('\\"hi\\"' in json, "quotes should be escaped")


def test_string_escaping_backslash() raises:
    var s = StringHolder(v="path\\to\\file")
    var json = write(s)
    assert_true("\\\\" in json, "backslash should be escaped")


# ---------------------------------------------------------------------------
# Pretty mode
# ---------------------------------------------------------------------------


def test_pretty_mode() raises:
    var p = Point(x=1, y=2)
    var json = write[pretty=True](p)
    assert_true("\n" in json, "pretty mode should have newlines")
    assert_true("  " in json, "pretty mode should have indentation")


# ---------------------------------------------------------------------------
# Runner
# ---------------------------------------------------------------------------


def main() raises:
    print("=== morph.json.write tests ===")

    test_int()
    print("  PASS: test_int")

    test_int_negative()
    print("  PASS: test_int_negative")

    test_all_scalars()
    print("  PASS: test_all_scalars")

    test_bool_false()
    print("  PASS: test_bool_false")

    test_optional_all_present()
    print("  PASS: test_optional_all_present")

    test_optional_all_none()
    print("  PASS: test_optional_all_none")

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

    test_empty()
    print("  PASS: test_empty")

    test_custom_serializable()
    print("  PASS: test_custom_serializable")

    test_string_escaping_quotes()
    print("  PASS: test_string_escaping_quotes")

    test_string_escaping_backslash()
    print("  PASS: test_string_escaping_backslash")

    test_pretty_mode()
    print("  PASS: test_pretty_mode")

    print("=== All 16 serialize tests passed ===")
