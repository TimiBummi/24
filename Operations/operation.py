from abc import ABC, abstractmethod


class Operation(ABC):
    @staticmethod
    @abstractmethod
    def calc(value1: float, value2: float) -> float:
        pass

    @staticmethod
    @abstractmethod
    def visualize(formula1: str, formula2: str) -> str:
        pass

    @classmethod
    @property
    @abstractmethod
    def is_commutative(cls) -> bool:
        pass

    @classmethod
    @property
    @abstractmethod
    def priority(cls) -> int:
        """
        Order of calculation respect the priority (brackets first)
        0 - Addition and Subtraction
        1 - Multiplication and Division
        2 - Log, Exp, Sqrt

        Different priority - brackets around higher prio can be removed
        (a * b) + c = a * b + c
        a * (b + c) != a * b + c

        Same priority
        (a * b) / c = a * b / c
        a * (b / c) = a * b / c
        """
        pass