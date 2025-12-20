from Operations.operation import Operation
from typing import List, Tuple

from bracketing import Bracketing


class Formula:
    def __init__(self, position: List[int], brackets: Bracketing, operations: List[Operation]):

        """
        Example:
            ((13*13)-1)/7 is Formula([13,13,1,7], [(1,2),(1,3)], [*,-,/])
        """
        if len(position) != len(brackets)-2 or len(position) != len(operations)-1:
            raise ValueError("Not a valid formula.")

        self.position = position # List of position of values (i.e. in a term like a+b, (2,1) stands for 'the first value goes into the second slot')
        self.brackets = brackets # List of position of brackets
        self.operations = operations # List of operations

        self.outcome = None

    def format_formula(self):
        self.brackets.remove_superfluous_brackets(self.operations)
        self.__sort_by_ascending_numbers()

    def __sort_by_ascending_numbers(self):
        """
        (13*11+1)/6 -> (1+11*13)/6
        """
        pass

    def calc_outcome(self, only_integer_outcomes: bool) -> bool:
        """
        Calculates outcome.
        """
        pass

    def __str__(self):
        pass