import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../l10n/l10n.dart';
import '../providers/tag_provider.dart';
import '../providers/onboarding_provider.dart';
import '../widgets/neural_background.dart';
import '../widgets/tag_item.dart';

class OccupationProfileScreen extends ConsumerWidget {
  const OccupationProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final tagsAsync = ref.watch(occupationTagsProvider);
    final selectedTags = ref.watch(selectedTagsProvider);

    return Scaffold(
      body: Stack(
        children: [
          // Background
          const NeuralBackground(),

          SafeArea(
            child: Column(
              children: [
                // Header
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                      Expanded(
                        child: Text(
                          l10n.profileSetup,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(width: 48), // Balance spacing
                    ],
                  ),
                ),

                // Progress Bar
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildProgressStep(true),
                    const SizedBox(width: 4),
                    _buildProgressStep(true),
                    const SizedBox(width: 4),
                    _buildProgressStep(false),
                    const SizedBox(width: 4),
                    _buildProgressStep(false),
                  ],
                ),

                const SizedBox(height: 24),

                // Title Section
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    children: [
                      RichText(
                        text: TextSpan(
                          style: const TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.secondary,
                            height: 1.2,
                          ),
                          children: [
                            TextSpan(text: l10n.defineYourPrefix),
                            TextSpan(
                              text: l10n.defineYourHighlight,
                              style: const TextStyle(color: AppTheme.primary),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        l10n.occupationSubtitle,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey[600],
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),

                // Tag Cloud
                Expanded(
                  child: Center(
                    child: tagsAsync.when(
                      data: (tags) => Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Wrap(
                          spacing: 12,
                          runSpacing: 16,
                          alignment: WrapAlignment.center,
                          children: tags.map((tag) {
                            final isSelected = selectedTags.contains(tag.id);
                            return TagItem(
                              tag: tag,
                              isSelected: isSelected,
                              onTap: () {
                                final current = ref.read(selectedTagsProvider);
                                if (isSelected) {
                                  ref.read(selectedTagsProvider.notifier).state = {...current}..remove(tag.id);
                                } else {
                                  ref.read(selectedTagsProvider.notifier).state = {...current}..add(tag.id);
                                }
                              },
                            );
                          }).toList(),
                        ),
                      ),
                      loading: () => const Center(child: CircularProgressIndicator()),
                      error: (err, stack) => Center(child: Text(l10n.errorPrefix(err.toString()))),
                    ),
                  ),
                ),

                // AI Analyzing Indicator
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.psychology, color: AppTheme.primary, size: 20),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          l10n.aiAnalyzingMetabolicNeeds,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primary.withOpacity(0.8),
                            letterSpacing: 1.0,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 32),

                // Footer Button
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: selectedTags.isNotEmpty
                              ? () {
                                  // Update global profile state
                                  ref.read(onboardingProvider.notifier).updateTags(selectedTags);

                                  // Navigate to next step
                                  context.go('/onboarding/allergies');
                                }
                              : null,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                l10n.nextStep,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(width: 8),
                              const Icon(Icons.arrow_forward, size: 20),
                            ],
                          ),
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          context.go('/onboarding/allergies');
                        },
                        child: Text(
                          l10n.skipForNow,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[400],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressStep(bool isActive) {
    return Container(
      width: 32,
      height: 6,
      decoration: BoxDecoration(
        color: isActive ? AppTheme.primary : Colors.grey[300],
        borderRadius: BorderRadius.circular(3),
      ),
    );
  }
}
