/// Maps card values to display labels and vice versa.
class CardParser {
  static const Map<String, int> rankMap = {
    'A': 1, '1': 1,
    '2': 2, '3': 3, '4': 4, '5': 5, '6': 6,
    '7': 7, '8': 8, '9': 9, '10': 10,
    'B': 11, 'J': 11, // Bube / Jack
    'D': 12, 'Q': 12, // Dame / Queen
    'K': 13,           // König / King
  };

  static const Map<int, String> valueToLabel = {
    1: 'A', 2: '2', 3: '3', 4: '4', 5: '5',
    6: '6', 7: '7', 8: '8', 9: '9', 10: '10',
    11: 'B', 12: 'D', 13: 'K',
  };
}
