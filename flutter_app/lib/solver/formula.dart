import 'operation.dart';

class FormulaStep {
  final Operation operation;
  final int firstIndex;
  final int secondIndex;

  const FormulaStep(this.operation, this.firstIndex, this.secondIndex);
}

class Formula {
  final double result;
  final List<FormulaStep> steps;

  Formula(this.result) : steps = [];

  Formula._withSteps(this.result, this.steps);

  Formula withStep(Operation op, int firstInd, int secondInd) {
    final newSteps = List<FormulaStep>.of(steps)
      ..add(FormulaStep(op, firstInd, secondInd));
    return Formula._withSteps(result, newSteps);
  }

  String toDisplayString(List<int> originalValues) {
    final parts = originalValues.map((v) => v.toString()).toList();
    final reversed = steps.reversed.toList();

    for (int i = 0; i < reversed.length; i++) {
      final step = reversed[i];
      final formatted = step.operation.format(
        parts[step.firstIndex],
        parts[step.secondIndex],
      );
      parts[step.firstIndex] =
          (i == reversed.length - 1) ? formatted : '($formatted)';
      parts.removeAt(step.secondIndex);
    }

    final resultStr = result == result.truncateToDouble()
        ? result.toInt().toString()
        : result.toStringAsFixed(4);
    return '${parts[0]} = $resultStr';
  }
}
