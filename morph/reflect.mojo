"""Core reflection utilities for morph.

Compile-time type matching, field iteration helpers, and type name constants
extracted from mojson and pprint patterns. These utilities form the foundation
for format-agnostic serialization and deserialization.

Supported scalar types:
    Int, Int64, Bool, Float64, Float32, String

Supported container types (hardcoded until GAP-3 is resolved):
    Optional[Int], Optional[String], Optional[Float64], Optional[Bool]
    List[Int], List[String], List[Float64], List[Bool]
"""

from std.reflection import (
    struct_field_count,
    struct_field_names,
    struct_field_types,
    get_type_name,
    get_base_type_name,
    is_struct_type,
)
from std.builtin.rebind import trait_downcast, downcast
from std.collections import Optional, List


# ---------------------------------------------------------------------------
# Compile-time type name constants
# ---------------------------------------------------------------------------

comptime INT_NAME = get_type_name[Int]()
comptime INT64_NAME = get_type_name[Int64]()
comptime BOOL_NAME = get_type_name[Bool]()
comptime STRING_NAME = get_type_name[String]()
comptime FLOAT64_NAME = get_type_name[Float64]()
comptime FLOAT32_NAME = get_type_name[Float32]()

comptime OPT_INT_NAME = get_type_name[Optional[Int]]()
comptime OPT_STRING_NAME = get_type_name[Optional[String]]()
comptime OPT_FLOAT64_NAME = get_type_name[Optional[Float64]]()
comptime OPT_BOOL_NAME = get_type_name[Optional[Bool]]()

comptime LIST_INT_NAME = get_type_name[List[Int]]()
comptime LIST_STRING_NAME = get_type_name[List[String]]()
comptime LIST_FLOAT64_NAME = get_type_name[List[Float64]]()
comptime LIST_BOOL_NAME = get_type_name[List[Bool]]()

comptime _FLOAT64_SIMD_PREFIX = "SIMD[DType.float64"
comptime _FLOAT32_SIMD_PREFIX = "SIMD[DType.float32"


# ---------------------------------------------------------------------------
# Trait bound aliases
# ---------------------------------------------------------------------------

comptime _Base = ImplicitlyDestructible & Movable
comptime Morphable = Defaultable & Movable


# ---------------------------------------------------------------------------
# Compile-time type classification
# ---------------------------------------------------------------------------


@always_inline
def is_int_type[T: AnyType]() -> Bool:
    comptime tname = get_type_name[T]()
    return tname == INT_NAME


@always_inline
def is_int64_type[T: AnyType]() -> Bool:
    comptime tname = get_type_name[T]()
    return tname == INT64_NAME


@always_inline
def is_bool_type[T: AnyType]() -> Bool:
    comptime tname = get_type_name[T]()
    return tname == BOOL_NAME


@always_inline
def is_string_type[T: AnyType]() -> Bool:
    comptime tname = get_type_name[T]()
    return tname == STRING_NAME


@always_inline
def is_float64_type[T: AnyType]() -> Bool:
    comptime tname = get_type_name[T]()
    return tname == FLOAT64_NAME or _FLOAT64_SIMD_PREFIX in tname


@always_inline
def is_float32_type[T: AnyType]() -> Bool:
    comptime tname = get_type_name[T]()
    return tname == FLOAT32_NAME or _FLOAT32_SIMD_PREFIX in tname


@always_inline
def is_scalar_type[T: AnyType]() -> Bool:
    """True if T is a primitive scalar: Int, Int64, Bool, Float64, Float32, String.
    """
    comptime tname = get_type_name[T]()
    return (
        tname == INT_NAME
        or tname == INT64_NAME
        or tname == BOOL_NAME
        or tname == STRING_NAME
        or tname == FLOAT64_NAME
        or tname == FLOAT32_NAME
        or _FLOAT64_SIMD_PREFIX in tname
        or _FLOAT32_SIMD_PREFIX in tname
    )


@always_inline
def is_optional_type[T: AnyType]() -> Bool:
    """True if T is one of the supported Optional[Scalar] types."""
    comptime base = get_base_type_name[T]()
    return base == "Optional"


@always_inline
def is_list_type[T: AnyType]() -> Bool:
    """True if T is one of the supported List[Scalar] types."""
    comptime base = get_base_type_name[T]()
    return base == "List"


@always_inline
def is_container_type[T: AnyType]() -> Bool:
    """True if T is a recognized container (Optional or List)."""
    return is_optional_type[T]() or is_list_type[T]()


# ---------------------------------------------------------------------------
# Field write helper
# ---------------------------------------------------------------------------


@always_inline
def set_field[T: AnyType, idx: Int](mut target: T, ownedvalue: _Base):
    """Write a value into a reflected struct field.

    Uses trait_downcast + UnsafePointer to safely destroy the old value
    and move the new one into place.

    Parameters:
        T: The struct type.
        idx: The field index.

    Args:
        target: The struct instance to modify.
        value: The new field value (moved in).
    """
    ref field = trait_downcast[_Base](__struct_field_ref(idx, target))
    var ptr = UnsafePointer(to=field)
    ptr.destroy_pointee()
    ptr.init_pointee_move(value^)
