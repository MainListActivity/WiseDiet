import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../providers/tag_provider.dart';
import '../providers/onboarding_provider.dart';
import '../widgets/neural_background.dart';
import '../widgets/tag_item.dart';
import 'loading_analysis_screen.dart';

class OccupationProfileScreen extends ConsumerWidget {
  const OccupationProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 24,
                  ),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                      const Expanded(
                        child: Text(
                          'Profile Setup',
                          textAlign: TextAlign.center,
                          style: TextStyle(
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
                        text: const TextSpan(
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.secondary,
                            height: 1.2,
                          ),
                          children: [
                            TextSpan(text: 'Define Your '),
                            TextSpan(
                              text: 'Rhythm',
                              style: TextStyle(color: AppTheme.primary),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Select your occupation and any specific health stages to help our AI tailor nutrition to your activity levels.',
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

                const Spacer(),

                // Tag Cloud
                tagsAsync.when(
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
                              ref.read(selectedTagsProvider.notifier).state = {
                                ...current,
                              }..remove(tag.id);
                            } else {
                              ref.read(selectedTagsProvider.notifier).state = {
                                ...current,
                              }..add(tag.id);
                            }
                          },
                        );
                      }).toList(),
                    ),
                  ),
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (err, stack) => Center(child: Text('Error: $err')),
                ),

                const Spacer(),

                // AI Analyzing Indicator
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.psychology,
                      color: AppTheme.primary,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'AI ANALYZING METABOLIC NEEDS...',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primary.withOpacity(0.8),
                        letterSpacing: 1.0,
                      ),
                    ),
                  ],
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
                                  ref
                                      .read(onboardingProvider.notifier)
                                      .updateTags(selectedTags);

                                  // Navigate to next step
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          const LoadingAnalysisScreen(),
                                    ),
                                  );
                                }
                              : null,
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'Next Step',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(width: 8),
                              Icon(Icons.arrow_forward, size: 20),
                            ],
                          ),
                        ),
                      ),
                      TextButton(
                        onPressed: () {},
                        child: Text(
                          'Skip for now',
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
