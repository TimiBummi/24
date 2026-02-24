import 'package:flutter_test/flutter_test.dart';
import 'package:twenty_four_solver/solver/game.dart';

void main() {
  const game = Game();

  group('Game solver', () {
    test('finds solutions for [1, 6, 11, 13]', () {
      final results = game.solve([1, 6, 11, 13]);
      final strings = results.map((f) => f.toDisplayString([1, 6, 11, 13])).toList();
      expect(results, isNotEmpty);
      // At least one valid solution should exist
      expect(strings.any((s) => s.endsWith('= 24')), isTrue);
    });

    test('finds solutions for [6, 6, 6, 6]', () {
      final results = game.solve([6, 6, 6, 6]);
      final strings = results.map((f) => f.toDisplayString([6, 6, 6, 6])).toList();
      expect(results, isNotEmpty);
      // The solver wraps intermediate steps in brackets
      expect(strings.any((s) => s.endsWith('= 24')), isTrue);
    });

    test('finds solutions for [1, 2, 3, 4]', () {
      final results = game.solve([1, 2, 3, 4]);
      expect(results, isNotEmpty);
      expect(
        results.map((f) => f.toDisplayString([1, 2, 3, 4])).every((s) => s.endsWith('= 24')),
        isTrue,
      );
    });

    test('returns empty for [1, 1, 1, 1]', () {
      final results = game.solve([1, 1, 1, 1]);
      expect(results, isEmpty);
    });

    test('deduplicates results', () {
      final results = game.solve([6, 6, 6, 6]);
      final strings = results.map((f) => f.toDisplayString([6, 6, 6, 6])).toList();
      // No duplicates
      expect(strings.length, equals(strings.toSet().length));
    });

    test('handles division without crashing', () {
      // Should not throw on cards that could produce division by zero
      final results = game.solve([1, 1, 1, 1]);
      expect(results, isEmpty);
    });

    test('all results equal 24', () {
      final testCases = [
        [1, 2, 3, 4],
        [2, 3, 4, 5],
        [1, 5, 5, 5],
        [8, 3, 8, 3],
      ];
      for (final cards in testCases) {
        final results = game.solve(cards);
        for (final formula in results) {
          expect(
            (formula.result - 24).abs() < 0.0001,
            isTrue,
            reason: 'Formula result ${formula.result} != 24 for cards $cards',
          );
        }
      }
    });
  });
}
