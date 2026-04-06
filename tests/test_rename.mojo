"""Tests for morph.rename: field renaming strategies."""

from morph.rename import (
    snake_to_camel,
    camel_to_snake,
    snake_to_pascal,
    snake_to_screaming,
    apply_rename,
)
from std.testing import assert_equal


def test_snake_to_camel() raises:
    assert_equal(snake_to_camel("first_name"), "firstName")
    assert_equal(snake_to_camel("last_name"), "lastName")
    assert_equal(snake_to_camel("name"), "name")
    assert_equal(snake_to_camel("http_status_code"), "httpStatusCode")
    assert_equal(snake_to_camel("a_b_c"), "aBC")
    assert_equal(snake_to_camel(""), "")


def test_camel_to_snake() raises:
    assert_equal(camel_to_snake("firstName"), "first_name")
    assert_equal(camel_to_snake("lastName"), "last_name")
    assert_equal(camel_to_snake("name"), "name")
    assert_equal(camel_to_snake("httpStatusCode"), "http_status_code")
    assert_equal(camel_to_snake(""), "")


def test_snake_to_pascal() raises:
    assert_equal(snake_to_pascal("first_name"), "FirstName")
    assert_equal(snake_to_pascal("last_name"), "LastName")
    assert_equal(snake_to_pascal("name"), "Name")
    assert_equal(snake_to_pascal("http_status_code"), "HttpStatusCode")
    assert_equal(snake_to_pascal(""), "")


def test_snake_to_screaming() raises:
    assert_equal(snake_to_screaming("first_name"), "FIRST_NAME")
    assert_equal(snake_to_screaming("http_status_code"), "HTTP_STATUS_CODE")
    assert_equal(snake_to_screaming("name"), "NAME")
    assert_equal(snake_to_screaming(""), "")


def test_apply_rename() raises:
    assert_equal(apply_rename("first_name", "camelCase"), "firstName")
    assert_equal(apply_rename("first_name", "PascalCase"), "FirstName")
    assert_equal(
        apply_rename("first_name", "SCREAMING_SNAKE_CASE"), "FIRST_NAME"
    )
    assert_equal(apply_rename("first_name", "snake_case"), "first_name")
    assert_equal(apply_rename("first_name", "none"), "first_name")


def test_apply_rename_unknown_strategy() raises:
    var raised = False
    try:
        _ = apply_rename("name", "kebab-case")
    except:
        raised = True
    assert_equal(raised, True)


def test_roundtrip() raises:
    assert_equal(camel_to_snake(snake_to_camel("first_name")), "first_name")
    assert_equal(
        camel_to_snake(snake_to_camel("http_status_code")), "http_status_code"
    )


def main() raises:
    print("=== morph.rename tests ===")

    test_snake_to_camel()
    print("  PASS: test_snake_to_camel")

    test_camel_to_snake()
    print("  PASS: test_camel_to_snake")

    test_snake_to_pascal()
    print("  PASS: test_snake_to_pascal")

    test_snake_to_screaming()
    print("  PASS: test_snake_to_screaming")

    test_apply_rename()
    print("  PASS: test_apply_rename")

    test_apply_rename_unknown_strategy()
    print("  PASS: test_apply_rename_unknown_strategy")

    test_roundtrip()
    print("  PASS: test_roundtrip")

    print("=== All 7 rename tests passed ===")
