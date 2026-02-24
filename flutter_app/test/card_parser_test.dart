import 'package:flutter_test/flutter_test.dart';
import 'package:twenty_four_solver/recognition/card_parser.dart';

void main() {
  group('CardParser', () {
    test('parses basic German card labels', () {
      expect(CardParser.extractCards('A 6 B K'), [1, 6, 11, 13]);
    });

    test('parses number cards', () {
      expect(CardParser.extractCards('10 2 D 9'), [10, 2, 12, 9]);
    });

    test('handles mixed case', () {
      expect(CardParser.extractCards('a k b d'), [1, 13, 11, 12]);
    });

    test('handles newlines in OCR output', () {
      expect(CardParser.extractCards('A\n6\nB\nK'), [1, 6, 11, 13]);
    });

    test('filters garbage tokens', () {
      expect(
        CardParser.extractCards('garbage A text 5 more K stuff 3'),
        [1, 5, 13, 3],
      );
    });

    test('stops at 4 cards', () {
      expect(
        CardParser.extractCards('A 2 3 4 5 6 7'),
        [1, 2, 3, 4],
      );
    });

    test('returns empty for no valid tokens', () {
      expect(CardParser.extractCards('no cards here'), isEmpty);
    });

    test('handles international fallbacks J and Q', () {
      expect(CardParser.extractCards('J Q 5 A'), [11, 12, 5, 1]);
    });

    test('valueToLabel mapping is correct', () {
      expect(CardParser.valueToLabel[1], 'A');
      expect(CardParser.valueToLabel[11], 'B');
      expect(CardParser.valueToLabel[12], 'D');
      expect(CardParser.valueToLabel[13], 'K');
      expect(CardParser.valueToLabel[10], '10');
    });
  });
}
