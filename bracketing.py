from typing import Type, List, Tuple

from Operations.operation import Operation


class Bracketing:
    def __init__(self, max_length, positions=None):
        self.length = max_length
        # Tuple of positions (e.g. [(0,1), (0,2)])
        self.positions = positions or []

    def list_of_valid_extensions_of_outer_brackets(self):
        """
        List of all possible positions with one more bracket
        """
        list_of_valid_extensions = []

        # Go through all possibilities, starting at the furthest set opening bracket to create only unique solutions
        minimum_position = max(position[0] for position in self.positions)
        if minimum_position > self.length-2:
            return

        for opening_bracket in [minimum_position, ..., self.length-2]:
            # Opening bracket too far right to be closed
            if opening_bracket >= self.length:
                break

            for closing_bracket in [opening_bracket+1, ..., self.length-1]:
                if self.__valid_closing_bracket(opening_bracket, closing_bracket):
                    # Append to list
                    former_position = self.positions.copy()
                    list_of_valid_extensions.append(
                        Bracketing(self.length, former_position + [(opening_bracket, closing_bracket)])
                    )

        return list_of_valid_extensions

    def __valid_closing_bracket(self, opening_bracket, closing_bracket) -> bool:
        """
        Check that:
         - closing bracket is not inside another bracket
         - this exact bracket does not already exist
         - it is not the outer-most bracket
        """
        amount_opening_brackets = sum(
            opening_bracket <= position[0] <= closing_bracket for position in self.positions)
        amount_closing_brackets = sum(
            opening_bracket <= position[1] <= closing_bracket for position in self.positions)

        return (amount_opening_brackets == amount_closing_brackets
        and (opening_bracket, closing_bracket) not in self.positions
        and closing_bracket - opening_bracket != self.length-1)

    def remove_superfluous_brackets(self, operations: [Type[Operation]]):
        """
        ((13*11)+1)/6 -> (13*11+1)/6
        """
        removable_brackets = []
        for position in self.positions:
            operation_priority_inside_bracket = self.__get_priority_in_interval(position, operations)
            operation_priority_before_bracket = operations[position[0]-1].priority() if position[0]-1 in range(len(operations)) else 0
            operation_priority_after_bracket = operations[position[1]].priority() if position[1] in range(len(operations)) else 0
            operation_priority_outside_bracket = max(operation_priority_before_bracket, operation_priority_after_bracket)
            if operation_priority_inside_bracket > operation_priority_outside_bracket:
                removable_brackets.append(position)

        for position in removable_brackets:
            self.positions.remove(position)

    def __get_priority_in_interval(self, position, operations: [Type[Operation]]):
        all_operation_positions = [position[0], ..., position[1]-1]
        relevenat_operation_positions = all_operation_positions

        # Get other brackets
        other_brackets = self.positions.copy()
        other_brackets.remove(position)

        for idx in all_operation_positions:
            if Bracketing.__is_index_in_bracket(idx, other_brackets):
                relevenat_operation_positions.remove(idx)

        return min([operations[pos].priority() for pos in relevenat_operation_positions])

    @staticmethod
    def __is_index_in_bracket(idx: int, positions: List[Tuple[int, int]]):
        for position in positions:
            if position[0] <= idx < position[1]:
                return True

        return False

    def __len__(self):
        return len(self.positions)

    def __str__(self):
        for pos in [0, ..., self.length-1]:
            amount_opening_bracket = sum(pos == position[0] for position in self.positions)
            amount_closing_bracket = sum(pos == position[1] for position in self.positions)
            print("(" * amount_opening_bracket)
            print("_")
            print(")" * amount_closing_bracket)
