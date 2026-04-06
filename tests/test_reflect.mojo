"""Tests for morph.reflect: type classification helpers."""

from morph.reflect import (
    is_int_type,
    is_int64_type,
    is_bool_type,
    is_string_type,
    is_float64_type,
    is_float32_type,
    is_scalar_type,
    is_optional_type,
    is_list_type,
    is_container_type,
)
from std.collections import Optional, List
from std.testing import assert_true, assert_false


@fieldwise_init
struct Point(Defaultable, Movable):
    var x: Int
    var y: Int

    def __init__(out self):
        self.x = 0
        self.y = 0


def test_is_int_type() raises:
    assert_true(is_int_type[Int](), "Int should be int type")
    assert_false(is_int_type[String](), "String should not be int type")
    assert_false(is_int_type[Bool](), "Bool should not be int type")


def test_is_int64_type() raises:
    assert_true(is_int64_type[Int64](), "Int64 should be int64 type")
    assert_false(is_int64_type[Int](), "Int should not be int64 type")


def test_is_bool_type() raises:
    assert_true(is_bool_type[Bool](), "Bool should be bool type")
    assert_false(is_bool_type[Int](), "Int should not be bool type")


def test_is_string_type() raises:
    assert_true(is_string_type[String](), "String should be string type")
    assert_false(is_string_type[Int](), "Int should not be string type")


def test_is_float64_type() raises:
    assert_true(is_float64_type[Float64](), "Float64 should be float64 type")
    assert_false(is_float64_type[Int](), "Int should not be float64 type")


def test_is_float32_type() raises:
    assert_true(is_float32_type[Float32](), "Float32 should be float32 type")
    assert_false(is_float32_type[Int](), "Int should not be float32 type")


def test_is_scalar_type() raises:
    assert_true(is_scalar_type[Int](), "Int is scalar")
    assert_true(is_scalar_type[Int64](), "Int64 is scalar")
    assert_true(is_scalar_type[Bool](), "Bool is scalar")
    assert_true(is_scalar_type[String](), "String is scalar")
    assert_true(is_scalar_type[Float64](), "Float64 is scalar")
    assert_true(is_scalar_type[Float32](), "Float32 is scalar")
    assert_false(is_scalar_type[Point](), "Point is not scalar")


def test_is_optional_type() raises:
    assert_true(is_optional_type[Optional[Int]](), "Optional[Int] is optional")
    assert_true(
        is_optional_type[Optional[String]](), "Optional[String] is optional"
    )
    assert_false(is_optional_type[Int](), "Int is not optional")
    assert_false(is_optional_type[List[Int]](), "List[Int] is not optional")


def test_is_list_type() raises:
    assert_true(is_list_type[List[Int]](), "List[Int] is list")
    assert_true(is_list_type[List[String]](), "List[String] is list")
    assert_false(is_list_type[Int](), "Int is not list")
    assert_false(is_list_type[Optional[Int]](), "Optional[Int] is not list")


def test_is_container_type() raises:
    assert_true(is_container_type[Optional[Int]](), "Optional is container")
    assert_true(is_container_type[List[Int]](), "List is container")
    assert_false(is_container_type[Int](), "Int is not container")
    assert_false(is_container_type[Point](), "Point is not container")


def main() raises:
    print("=== morph.reflect tests ===")

    test_is_int_type()
    print("  PASS: test_is_int_type")

    test_is_int64_type()
    print("  PASS: test_is_int64_type")

    test_is_bool_type()
    print("  PASS: test_is_bool_type")

    test_is_string_type()
    print("  PASS: test_is_string_type")

    test_is_float64_type()
    print("  PASS: test_is_float64_type")

    test_is_float32_type()
    print("  PASS: test_is_float32_type")

    test_is_scalar_type()
    print("  PASS: test_is_scalar_type")

    test_is_optional_type()
    print("  PASS: test_is_optional_type")

    test_is_list_type()
    print("  PASS: test_is_list_type")

    test_is_container_type()
    print("  PASS: test_is_container_type")

    print("=== All 10 reflect tests passed ===")
