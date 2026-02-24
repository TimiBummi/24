import 'package:flutter/material.dart';

import '../recognition/card_parser.dart';
import '../solver/game.dart';

class ResultsScreen extends StatelessWidget {
  final List<int> cards;

  const ResultsScreen({super.key, required this.cards});

  @override
  Widget build(BuildContext context) {
    final game = const Game();
    final results = game.solve(cards);

    final cardLabels = cards
        .map((c) => CardParser.valueToLabel[c] ?? c.toString())
        .join(', ');

    return Scaffold(
      appBar: AppBar(
        title: Text('Cards: $cardLabels'),
      ),
      body: results.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.sentiment_dissatisfied,
                        size: 64,
                        color: Theme.of(context).colorScheme.outline),
                    const SizedBox(height: 16),
                    Text(
                      'No solution exists for these cards.',
                      style: Theme.of(context).textTheme.titleMedium,
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: results.length,
              itemBuilder: (ctx, i) => Card(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 12),
                  child: Text(
                    results[i].toDisplayString(cards),
                    style: const TextStyle(
                      fontSize: 18,
                      fontFamily: 'monospace',
                    ),
                  ),
                ),
              ),
              separatorBuilder: (_, _) => const SizedBox(height: 4),
            ),
    );
  }
}
