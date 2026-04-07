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
        if not arg.startswith("--"):
            raise Error("Expected --flag, got: " + arg)

        var flag = arg.removeprefix("--")

        var matched = False

        comptime
        for idx in range(count):
            comptime field_name = names[idx]
            comptime field_type = types[idx]
            comptime type_name = get_type_name[field_type]()

            var cli_name = String(field_name).replace("_", "-")
            if flag == cli_name:
                matched = True
                ref field = trait_downcast[_Base](__struct_field_ref(idx, result))
                var ptr = UnsafePointer(to=field)

                comptime
                if type_name == BOOL_NAME:
                    ptr.destroy_pointee()
                    ptr.bitcast[Bool]().init_pointee_move(True)
                elif type_name == INT_NAME:
                    i += 1
                    if i >= len(args):
                        raise Error("Missing value for --" + cli_name)
                    var val = atol(args[i])
                    ptr.destroy_pointee()
                    ptr.bitcast[Int]().init_pointee_move(val)
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
                elif type_name == STRING_NAME:
                    i += 1
                    if i >= len(args):
                        raise Error("Missing value for --" + cli_name)
                    var val = args[i]
                    ptr.destroy_pointee()
                    ptr.bitcast[String]().init_pointee_move(val)

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
        if type_name == BOOL_NAME:
            out += "  --" + cli_name + "\n"
        elif type_name == INT_NAME or type_name == INT64_NAME:
            out += "  --" + cli_name + " <int>\n"
        elif type_name == FLOAT64_NAME:
            out += "  --" + cli_name + " <float>\n"
        elif type_name == STRING_NAME:
            out += "  --" + cli_name + " <string>\n"
        else:
            out += "  --" + cli_name + " <value>\n"

    return out^
