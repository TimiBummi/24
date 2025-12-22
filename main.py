from Operations.addition import Addition
from Operations.division import Division
from Operations.multiplication import Multiplication
from Operations.subtraction import Subtraction
from game import Game


def main():
    rounds = [
        # [1,5,8,10],
        [1,6,11,13]
    ]

    operations = [
        Addition,
        Subtraction,
        Division,
        Multiplication,
    ]

    game = Game(operations, [24])

    for round in rounds:
        formulas = game.play(round)
        if formulas:
            print("The cards " + round.__str__() + " have the following solutions:")
            for formula in formulas:
                print("\t" + formula.to_string(round))
        else:
            print("The cards " + round.__str__() + " have no solution.")


if __name__ == "__main__":
    main()
