class CardParser {
  static const Map<String, int> _rankMap = {
    'A': 1,
    '2': 2,
    '3': 3,
    '4': 4,
    '5': 5,
    '6': 6,
    '7': 7,
    '8': 8,
    '9': 9,
    '10': 10,
    'B': 11, // Bube (Jack)
    'D': 12, // Dame (Queen)
    'K': 13, // König (King)
    // Fallbacks for international decks / OCR misreads
    'J': 11,
    'Q': 12,
  };

  static const Map<int, String> valueToLabel = {
    1: 'A',
    2: '2',
    3: '3',
    4: '4',
    5: '5',
    6: '6',
    7: '7',
    8: '8',
    9: '9',
    10: '10',
    11: 'B',
    12: 'D',
    13: 'K',
  };

  /// Extracts card values from raw OCR text.
  /// Returns a list of recognized card values (may have fewer than 4).
  static List<int> extractCards(String rawText) {
    final tokens = rawText
        .toUpperCase()
        .replaceAll('\n', ' ')
        .split(RegExp(r'\s+'))
        .where((t) => t.isNotEmpty)
        .toList();

    final values = <int>[];
    for (final token in tokens) {
      final val = _rankMap[token];
      if (val != null && val > 0) {
        values.add(val);
        if (values.length >= 4) break;
      }
    }
    return values;
  }
}
