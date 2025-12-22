from Operations.operation import Operation


class Multiplication(Operation):

    @staticmethod
    def calc(value1, value2):
        return value1 * value2

    @classmethod
    @property
    def is_commutative(cls):
        return True

    @classmethod
    @property
    def priority(cls):
        return 0

    @staticmethod
    def to_string(value1, value2):
        return value1 + "*" + value2