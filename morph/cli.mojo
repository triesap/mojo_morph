"""CLI argument parsing from struct definitions via reflection.

Generates ``--flag`` style arguments from struct fields and parses
command-line argument lists into struct instances.

Usage::

    from morph.cli import parse_args

    @fieldwise_init
    struct Options(Defaultable, Movable):
        var host: String
        var port: Int
        var verbose: Bool
        def __init__(out self):
            self.host = "localhost"
            self.port = 8080
            self.verbose = False

    var args = List[String]()
    args.append("--host")
    args.append("0.0.0.0")
    var opts = parse_args[Options](args)
"""

from std.reflection import (
    struct_field_count,
    struct_field_names,
    struct_field_types,
    get_type_name,
)
from std.collections import List
from std.builtin.rebind import trait_downcast
from morph.reflect import (
    _Base,
    Morphable,
    INT_NAME,
    INT64_NAME,
    BOOL_NAME,
    STRING_NAME,
    FLOAT64_NAME,
    FLOAT32_NAME,
    OPT_INT_NAME,
    OPT_STRING_NAME,
    OPT_FLOAT64_NAME,
    OPT_BOOL_NAME,
    LIST_INT_NAME,
    LIST_STRING_NAME,
    LIST_FLOAT64_NAME,
    LIST_BOOL_NAME,
)


def parse_args[T: Morphable](args: List[String]) raises -> T:
    """Parse CLI arguments into a struct T.

    Arguments are ``--field_name value`` pairs. Bool fields are flags
    (``--verbose`` toggles to True, no value needed). Underscores in
    field names are converted to hyphens for CLI args (``my_field``
    becomes ``--my-field``).

    Parameters:
        T: The struct type to populate.

    Args:
        args: The argument list (without program name).

    Returns:
        A populated struct instance.
    """
    var result = T()

    comptime count = struct_field_count[T]()
    comptime names = struct_field_names[T]()
    comptime types = struct_field_types[T]()

    var i = 0
    while i < len(args):
        var arg = args[i]
        var is_long = arg.startswith("--")
        var is_short = not is_long and arg.startswith("-") and len(arg) == 2

        if not is_long and not is_short:
            raise Error("Expected --flag or -x, got: " + arg)

        var flag: String
        if is_long:
            flag = String(arg.removeprefix("--"))
        else:
            flag = String(arg.removeprefix("-"))

        var matched = False

        comptime
        for idx in range(count):
            comptime field_name = names[idx]
            comptime field_type = types[idx]
            comptime type_name = get_type_name[field_type]()

            var cli_name = String(field_name).replace("_", "-")
            var fn_str = String(field_name)
            var short_name = chr(Int(fn_str.as_bytes()[0]))
            if flag == cli_name or (is_short and flag == short_name):
                matched = True
                ref field = trait_downcast[_Base](__struct_field_ref(idx, result))
                var ptr = UnsafePointer(to=field)

                comptime
                if type_name == BOOL_NAME:
                    ptr.destroy_pointee()
                    ptr.bitcast[Bool]().init_pointee_move(True)
                elif type_name == OPT_BOOL_NAME:
                    ptr.destroy_pointee()
                    ptr.bitcast[Optional[Bool]]().init_pointee_move(True)
                elif type_name == INT_NAME:
                    i += 1
                    if i >= len(args):
                        raise Error("Missing value for --" + cli_name)
                    var val = atol(args[i])
                    ptr.destroy_pointee()
                    ptr.bitcast[Int]().init_pointee_move(val)
                elif type_name == OPT_INT_NAME:
                    i += 1
                    if i >= len(args):
                        raise Error("Missing value for --" + cli_name)
                    var val = atol(args[i])
                    ptr.destroy_pointee()
                    ptr.bitcast[Optional[Int]]().init_pointee_move(val)
                elif type_name == INT64_NAME:
                    i += 1
                    if i >= len(args):
                        raise Error("Missing value for --" + cli_name)
                    var val = atol(args[i])
                    ptr.destroy_pointee()
                    ptr.bitcast[Int64]().init_pointee_move(Int64(val))
                elif type_name == FLOAT64_NAME:
                    i += 1
                    if i >= len(args):
                        raise Error("Missing value for --" + cli_name)
                    var val = atof(args[i])
                    ptr.destroy_pointee()
                    ptr.bitcast[Float64]().init_pointee_move(val)
                elif type_name == OPT_FLOAT64_NAME:
                    i += 1
                    if i >= len(args):
                        raise Error("Missing value for --" + cli_name)
                    var val = atof(args[i])
                    ptr.destroy_pointee()
                    ptr.bitcast[Optional[Float64]]().init_pointee_move(val)
                elif type_name == STRING_NAME:
                    i += 1
                    if i >= len(args):
                        raise Error("Missing value for --" + cli_name)
                    var val = args[i]
                    ptr.destroy_pointee()
                    ptr.bitcast[String]().init_pointee_move(val)
                elif type_name == OPT_STRING_NAME:
                    i += 1
                    if i >= len(args):
                        raise Error("Missing value for --" + cli_name)
                    var val = args[i]
                    ptr.destroy_pointee()
                    ptr.bitcast[Optional[String]]().init_pointee_move(val)
                elif type_name == LIST_STRING_NAME:
                    i += 1
                    if i >= len(args):
                        raise Error("Missing value for --" + cli_name)
                    var parts = _split_comma(args[i])
                    ptr.destroy_pointee()
                    ptr.bitcast[List[String]]().init_pointee_move(parts^)
                elif type_name == LIST_INT_NAME:
                    i += 1
                    if i >= len(args):
                        raise Error("Missing value for --" + cli_name)
                    var parts = _split_comma(args[i])
                    var int_list = List[Int]()
                    for pi in range(len(parts)):
                        int_list.append(atol(parts[pi]))
                    ptr.destroy_pointee()
                    ptr.bitcast[List[Int]]().init_pointee_move(int_list^)

        if not matched:
            raise Error("Unknown flag: --" + flag)

        i += 1

    return result^


def usage[T: AnyType]() -> String:
    """Generate a usage string showing available flags for struct T.

    Parameters:
        T: The struct type.

    Returns:
        A usage/help string.
    """
    comptime count = struct_field_count[T]()
    comptime names = struct_field_names[T]()
    comptime types = struct_field_types[T]()

    var out = String("Options:\n")

    comptime
    for idx in range(count):
        comptime field_name = names[idx]
        comptime field_type = types[idx]
        comptime type_name = get_type_name[field_type]()

        var cli_name = String(field_name).replace("_", "-")

        comptime
        if type_name == BOOL_NAME or type_name == OPT_BOOL_NAME:
            out += "  --" + cli_name + "  (flag)\n"
        elif type_name == INT_NAME or type_name == INT64_NAME or type_name == OPT_INT_NAME:
            out += "  --" + cli_name + " <int>\n"
        elif type_name == FLOAT64_NAME or type_name == OPT_FLOAT64_NAME:
            out += "  --" + cli_name + " <float>\n"
        elif type_name == STRING_NAME or type_name == OPT_STRING_NAME:
            out += "  --" + cli_name + " <string>\n"
        elif type_name == LIST_STRING_NAME:
            out += "  --" + cli_name + " <a,b,c>\n"
        elif type_name == LIST_INT_NAME:
            out += "  --" + cli_name + " <1,2,3>\n"
        else:
            out += "  --" + cli_name + " <value>\n"

    return out^


# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------


def _split_comma(s: String) -> List[String]:
    """Split a string by commas, returning a list of trimmed parts."""
    var result = List[String]()
    var current = String("")
    var data = s.as_bytes()
    for i in range(len(data)):
        if data[i] == UInt8(ord(",")):
            result.append(current^)
            current = String("")
        else:
            current += chr(Int(data[i]))
    if len(current) > 0:
        result.append(current^)
    return result^
