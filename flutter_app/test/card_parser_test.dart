import 'package:flutter_test/flutter_test.dart';
import 'package:twenty_four_solver/recognition/card_parser.dart';

void main() {
  group('CardParser.valueToLabel', () {
    test('maps all 13 ranks correctly', () {
      expect(CardParser.valueToLabel[1], 'A');
      expect(CardParser.valueToLabel[2], '2');
      expect(CardParser.valueToLabel[3], '3');
      expect(CardParser.valueToLabel[4], '4');
      expect(CardParser.valueToLabel[5], '5');
      expect(CardParser.valueToLabel[6], '6');
      expect(CardParser.valueToLabel[7], '7');
      expect(CardParser.valueToLabel[8], '8');
      expect(CardParser.valueToLabel[9], '9');
      expect(CardParser.valueToLabel[10], '10');
      expect(CardParser.valueToLabel[11], 'B');
      expect(CardParser.valueToLabel[12], 'D');
      expect(CardParser.valueToLabel[13], 'K');
    });

    test('uses German labels for face cards', () {
      expect(CardParser.valueToLabel[11], 'B'); // Bube, not J
      expect(CardParser.valueToLabel[12], 'D'); // Dame, not Q
      expect(CardParser.valueToLabel[13], 'K'); // König
    });
  });

  group('CardParser.rankMap', () {
    test('maps German face card labels', () {
      expect(CardParser.rankMap['B'], 11);
      expect(CardParser.rankMap['D'], 12);
      expect(CardParser.rankMap['K'], 13);
    });

    test('maps international face card labels', () {
      expect(CardParser.rankMap['J'], 11);
      expect(CardParser.rankMap['Q'], 12);
    });

    test('maps number cards', () {
      expect(CardParser.rankMap['A'], 1);
      expect(CardParser.rankMap['1'], 1);
      expect(CardParser.rankMap['10'], 10);
      expect(CardParser.rankMap['5'], 5);
    });
  });
}
