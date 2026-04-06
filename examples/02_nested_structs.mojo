"""Example 02: Nested struct serialization.

Demonstrates: recursive struct handling -- structs within structs.
"""

from morph.json import write, read


@fieldwise_init
struct Address(Defaultable, Movable):
    var city: String
    var zip_code: String

    def __init__(out self):
        self.city = ""
        self.zip_code = ""


@fieldwise_init
struct Employee(Defaultable, Movable):
    var name: String
    var role: String
    var address: Address

    def __init__(out self):
        self.name = ""
        self.role = ""
        self.address = Address()


@fieldwise_init
struct Company(Defaultable, Movable):
    var name: String
    var ceo: Employee

    def __init__(out self):
        self.name = ""
        self.ceo = Employee()


def main() raises:
    print("=== Nested Structs ===\n")

    var emp = Employee(
        name="Carol",
        role="Engineer",
        address=Address(city="San Francisco", zip_code="94105"),
    )
    var json = write(emp)
    print("Serialized:", json)

    var restored = read[Employee](json)
    print("Restored: " + restored.name + " in " + restored.address.city)

    print("\n=== Deeply Nested ===\n")

    var company = Company(
        name="Modular",
        ceo=Employee(
            name="Chris",
            role="CEO",
            address=Address(city="Seattle", zip_code="98101"),
        ),
    )
    print("Company:", write(company))
    print("Pretty:\n" + write[pretty=True](company))
