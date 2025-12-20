from Operations.operation import Operation


class Addition(Operation):

    @staticmethod
    def calc(value1, value2):
        return value1 + value2

    @staticmethod
    def visualize(formula1: str, formula2: str):
        return f"{formula1} + {formula2}"

    @classmethod
    @property
    def is_commutative(cls):
        return True

    @classmethod
    @property
    def priority(cls):
        return 0