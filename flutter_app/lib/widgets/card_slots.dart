import 'package:flutter/material.dart';

import '../recognition/card_parser.dart';

class CardSlots extends StatelessWidget {
  final List<int?> cards;
  final void Function(int index) onSlotTapped;
  final VoidCallback onSolve;
  final VoidCallback onClear;

  const CardSlots({
    super.key,
    required this.cards,
    required this.onSlotTapped,
    required this.onSolve,
    required this.onClear,
  });

  bool get _allFilled => cards.every((c) => c != null);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: List.generate(4, (i) => _buildSlot(context, i)),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    onPressed: _allFilled ? onSolve : null,
                    icon: const Icon(Icons.calculate),
                    label: const Text('Solve'),
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      textStyle: const TextStyle(fontSize: 18),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                IconButton.outlined(
                  onPressed: onClear,
                  icon: const Icon(Icons.refresh),
                  tooltip: 'Clear all',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSlot(BuildContext context, int index) {
    final value = cards[index];
    final label = value != null
        ? (CardParser.valueToLabel[value] ?? value.toString())
        : '?';

    return GestureDetector(
      onTap: () => onSlotTapped(index),
      child: Container(
        width: 64,
        height: 80,
        decoration: BoxDecoration(
          color: value != null
              ? Theme.of(context).colorScheme.primaryContainer
              : Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: value != null
                ? Theme.of(context).colorScheme.primary
                : Theme.of(context).colorScheme.outline,
            width: 2,
          ),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: value != null
                ? Theme.of(context).colorScheme.onPrimaryContainer
                : Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}

/// Bottom sheet for manual card value selection.
void showCardPicker(BuildContext context, void Function(int value) onPicked) {
  showModalBottomSheet(
    context: context,
    builder: (ctx) {
      return Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Select card value',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: List.generate(13, (i) {
                final value = i + 1;
                final label =
                    CardParser.valueToLabel[value] ?? value.toString();
                return SizedBox(
                  width: 56,
                  height: 56,
                  child: FilledButton.tonal(
                    onPressed: () {
                      Navigator.pop(ctx);
                      onPicked(value);
                    },
                    style: FilledButton.styleFrom(
                      padding: EdgeInsets.zero,
                    ),
                    child: Text(
                      label,
                      style: const TextStyle(
                          fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                  ),
                );
              }),
            ),
            const SizedBox(height: 8),
          ],
        ),
      );
    },
  );
}
