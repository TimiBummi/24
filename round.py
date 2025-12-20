from Operations import operation
from formula import Formula
from formula_creator import FormulaCreator


class Round:
    def __init__(self, cards: [int], outcomes: [int], valid_operations: [operation]):
        self.cards = cards
        self.outcomes = outcomes
        self.valid_operations = valid_operations

        # Defaults
        self.solutions = []

    def calculate_integer_solutions(self):
        self.__calculate_solutions(True)

    def calculate_all_solutions(self):
        self.__calculate_solutions(False)

    def __calculate_solutions(self, only_integer_outcomes: bool):
        # Create all formulas
        formula_creator = FormulaCreator(self.cards, self.valid_operations)
        formulas = formula_creator.create_all_unique_formulas()

        # Calculate outcomes
        for formula in formulas:
            is_integer = formula.calc_outcome(only_integer_outcomes)
            if is_integer:
                formula = None

        # Remove all None values
        formulas = list(set(formulas))

    def find_closest_integer_match(self):
        pass

    def cleanse_list_of_formulas(self, formulas: [Formula]):
        pass