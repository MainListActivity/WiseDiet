import 'package:flutter/material.dart';

import '../../../l10n/l10n.dart';
import '../widgets/profile_card.dart';

class HistoryPlaceholderScreen extends StatelessWidget {
  final VoidCallback? onProfileTap;

  const HistoryPlaceholderScreen({super.key, this.onProfileTap});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.historyPlaceholderTitle)),
      body: Column(
        children: [
          ProfileCard(onTap: onProfileTap),
          Expanded(
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.history,
                    size: 64,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    l10n.historyPlaceholderBody,
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
