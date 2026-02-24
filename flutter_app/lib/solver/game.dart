import 'operation.dart';
import 'formula.dart';
import 'addition.dart';
import 'subtraction.dart';
import 'multiplication.dart';
import 'division.dart';

class Game {
  static const List<Operation> defaultOperations = [
    Addition(),
    Subtraction(),
    Multiplication(),
    Division(),
  ];

  final List<Operation> operations;
  final List<int> viableResults;

  const Game({
    this.operations = defaultOperations,
    this.viableResults = const [24],
  });

  List<Formula> solve(List<int> cards) {
    final doubleCards = cards.map((c) => c.toDouble()).toList();
    final allFormulas = _solveRecursively(doubleCards);

    final filtered = viableResults.isEmpty
        ? allFormulas
        : allFormulas
            .where((f) =>
                viableResults.any((r) => (f.result - r).abs() < 0.0001))
            .toList();

    // Deduplicate by string representation
    final seen = <String>{};
    final unique = <Formula>[];
    for (final formula in filtered) {
      final str = formula.toDisplayString(cards);
      if (seen.add(str)) unique.add(formula);
    }
    return unique;
  }

  List<Formula> _solveRecursively(List<double> values) {
    if (values.length == 1) {
      return [Formula(values[0])];
    }

    final formulas = <Formula>[];
    for (int i = 0; i < values.length - 1; i++) {
      for (int j = i + 1; j < values.length; j++) {
        final remaining = List<double>.of(values)..removeAt(j);

        for (final op in operations) {
          _tryOperation(values, remaining, op, i, j, formulas);
          if (!op.isCommutative) {
            _tryOperation(values, remaining, op, j, i, formulas);
          }
        }
      }
    }
    return formulas;
  }

  void _tryOperation(
    List<double> values,
    List<double> remaining,
    Operation op,
    int firstInd,
    int secondInd,
    List<Formula> out,
  ) {
    final calculated = op.calc(values[firstInd], values[secondInd]);
    if (calculated.isNaN || calculated.isInfinite) return;

    final next = List<double>.of(remaining)..[firstInd] = calculated;
    final subFormulas = _solveRecursively(next);
    for (final f in subFormulas) {
      out.add(f.withStep(op, firstInd, secondInd));
    }
  }
}
