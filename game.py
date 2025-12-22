from formula import Formula
from Operations.operation import Operation


class Game:
    def __init__(self, operations: [Operation], viable_results: [int], only_integer_solutions: bool=True):
        self.operations = operations
        self.viable_results = viable_results
        self.only_integer_solutions = only_integer_solutions

    def play(self, cards: [int]):
        formulas = self.__play_recursively(cards)

        if self.viable_results:
            formulas = [formula for formula in formulas if formula.get_result() in self.viable_results]

        # Feature: closest to result

        return formulas

    def __play_recursively(self, values: [int]) -> [Formula]:
        if len(values) == 1:
            result = values[0]
            formula = Formula(result)
            return [formula]

        formulas = []
        for first_ind in range (len(values)-1):
            for second_ind in range (first_ind+1, len(values)):
                # new values
                remaining_values = values.copy()
                remaining_values.pop(second_ind)

                for operation in self.operations:
                    formulas.extend(
                        self.__formulas_after_calc(values, remaining_values, operation, first_ind, second_ind)
                    )

                    if not operation.is_commutative:
                        formulas.extend(
                            self.__formulas_after_calc(values, remaining_values, operation, second_ind, first_ind)
                        )

        return formulas

    def __formulas_after_calc(self, values, new_values, operation, first_ind, second_ind):
        calculated_value = operation.calc(values[first_ind], values[second_ind])
        # if self.only_integer_solutions and not calculated_value.is_integer():
        #     return []

        # store the calculated value in first value
        new_values[first_ind] = calculated_value
        new_formulas = self.__play_recursively(new_values)

        # I did 'op' to 'ind1' and 'ind2'
        for formula in new_formulas:
            formula.add_step(operation, first_ind, second_ind)
        return new_formulas