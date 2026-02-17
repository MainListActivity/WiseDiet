import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../l10n/l10n.dart';
import '../providers/onboarding_provider.dart';

class FamilyParamsScreen extends ConsumerStatefulWidget {
  const FamilyParamsScreen({super.key});

  @override
  ConsumerState<FamilyParamsScreen> createState() => _FamilyParamsScreenState();
}

class _FamilyParamsScreenState extends ConsumerState<FamilyParamsScreen> {
  int _members = 1;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.familyParameters)),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              l10n.howManyPeopleEating,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  onPressed: _members > 1 ? () => setState(() => _members--) : null,
                  icon: const Icon(Icons.remove_circle_outline, size: 40),
                ),
                const SizedBox(width: 24),
                Text(
                  '$_members',
                  style: const TextStyle(fontSize: 48, fontWeight: FontWeight.bold),
                ),
                const SizedBox(width: 24),
                IconButton(
                  onPressed: () => setState(() => _members++),
                  icon: const Icon(Icons.add_circle_outline, size: 40),
                ),
              ],
            ),
            const SizedBox(height: 48),
            ElevatedButton(
              onPressed: () {
                ref.read(onboardingProvider.notifier).updateFamilyMembers(_members);
                context.go('/onboarding/loading');
              },
              child: Text(l10n.generateStrategy),
            ),
          ],
        ),
      ),
    );
  }
}
