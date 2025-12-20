from typing import List, Tuple

from bracketing import Bracketing
from formula import Formula


class FormulaCreator:
    def __init__(self, values: [int], valid_operations):
        self.values = values
        self.valid_operations = valid_operations
        self.formulas = []

    def create_all_unique_formulas(self) -> [Formula]:
        """
        Create all possible formulas, format them and remove duplicates.
        """
        for formula in self.formulas:
            formula.format_formula()

        # Remove duplicates
        self.formulas = list(set(self.formulas))

    def __create_all_formulas(self):
        self.__create_all_formulas()
        list_of_all_value_combinations = FormulaCreator.__create_list_of_all_combinations(
            self.values,
            len(self.values)-2,
            False
        )
        list_of_all_operation_combinations = FormulaCreator.__create_list_of_all_combinations(
            self.valid_operations,
            len(self.values)-2,
            True
        )
        list_of_all_brackets = FormulaCreator.__create_list_of_all_brackets(len(self.values))

        for values in list_of_all_value_combinations:
            for brackets in list_of_all_brackets:
                for operations in list_of_all_operation_combinations:
                    self.formulas.append(Formula(values, brackets, operations))


    @staticmethod
    def __create_list_of_all_combinations(elements: list, length: int, use_element_multiple_times: bool) -> list:
        if length == 0:
            return [[]]

        list_of_all_combinations = []

        for element in elements:
            # Recursion: One less element
            if use_element_multiple_times:
                updated_elements = elements
            else:
                updated_elements = elements.copy()
                updated_elements.remove(element)

            list_of_all_combinations_with_one_less_element = FormulaCreator.__create_list_of_all_combinations(
                updated_elements,
                length-1,
                use_element_multiple_times
            )

            for combinations_with_one_less_element in list_of_all_combinations_with_one_less_element:
                list_of_all_combinations.append(
                    combinations_with_one_less_element + [element]
                )

        return list_of_all_combinations

    @staticmethod
    def __create_list_of_all_brackets(length, brackets=None) -> List[Bracketing]:
        if length < 2:
            raise ValueError("Too short.")

        list_of_brackets = []

        # Starting bracket
        brackets = brackets or Bracketing(length, [(0,1)])

        list_of_brackets_extended_by_one = brackets.list_of_valid_extensions_of_outer_brackets()

        if list_of_brackets_extended_by_one:
            # New bracket placed, recursively call this method again
            for new_brackets in list_of_brackets_extended_by_one:
                list_of_brackets.extend(FormulaCreator.__create_list_of_all_brackets(length, new_brackets))

            return list_of_brackets

        else:
            # No more positions to add
            return [brackets]