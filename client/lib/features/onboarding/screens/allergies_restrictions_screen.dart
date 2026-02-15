import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../providers/tag_provider.dart';
import '../providers/onboarding_provider.dart';
import 'family_params_screen.dart';

class AllergiesRestrictionsScreen extends ConsumerStatefulWidget {
  const AllergiesRestrictionsScreen({super.key});

  @override
  ConsumerState<AllergiesRestrictionsScreen> createState() =>
      _AllergiesRestrictionsScreenState();
}

class _AllergiesRestrictionsScreenState
    extends ConsumerState<AllergiesRestrictionsScreen> {
  final _ingredientController = TextEditingController();

  @override
  void dispose() {
    _ingredientController.dispose();
    super.dispose();
  }

  void _navigateToNext() {
    final selectedAllergens = ref.read(selectedAllergenTagsProvider);
    final selectedDietary = ref.read(selectedDietaryPreferenceTagsProvider);
    final customIngredients = ref.read(customAvoidedIngredientsProvider);

    ref.read(onboardingProvider.notifier).updateAllergens(selectedAllergens);
    ref.read(onboardingProvider.notifier).updateDietaryPreferences(selectedDietary);
    ref.read(onboardingProvider.notifier).updateCustomAvoidedIngredients(customIngredients);

    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const FamilyParamsScreen()),
    );
  }

  void _skipToNext() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const FamilyParamsScreen()),
    );
  }

  void _addCustomIngredient() {
    final text = _ingredientController.text.trim();
    if (text.isNotEmpty) {
      final current = ref.read(customAvoidedIngredientsProvider);
      ref.read(customAvoidedIngredientsProvider.notifier).state = [...current, text];
      _ingredientController.clear();
    }
  }

  void _removeCustomIngredient(String ingredient) {
    final current = ref.read(customAvoidedIngredientsProvider);
    ref.read(customAvoidedIngredientsProvider.notifier).state =
        current.where((i) => i != ingredient).toList();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final allergenTagsAsync = ref.watch(allergenTagsProvider);
    final dietaryTagsAsync = ref.watch(dietaryPreferenceTagsProvider);
    final selectedAllergens = ref.watch(selectedAllergenTagsProvider);
    final selectedDietary = ref.watch(selectedDietaryPreferenceTagsProvider);
    final customIngredients = ref.watch(customAvoidedIngredientsProvider);

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Back button header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  const Expanded(
                    child: Text(
                      'Allergies & Restrictions',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(width: 48),
                ],
              ),
            ),

            // Scrollable content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 16),

                    // Warning banner
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.red.withOpacity(0.3)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.warning, color: Colors.red, size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'WARNING: Always verify ingredients independently. AI suggestions do not replace medical advice.',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.red[700],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // "Safety First" title
                    RichText(
                      text: TextSpan(
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : AppTheme.secondary,
                          height: 1.2,
                        ),
                        children: const [
                          TextSpan(
                            text: 'Safety ',
                            style: TextStyle(color: Colors.red),
                          ),
                          TextSpan(text: 'First'),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // "Common Allergens" section
                    Text(
                      'Common Allergens',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white : AppTheme.secondary,
                      ),
                    ),

                    const SizedBox(height: 12),

                    // Allergen grid
                    allergenTagsAsync.when(
                      data: (tags) => GridView.count(
                        crossAxisCount: 3,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        mainAxisSpacing: 12,
                        crossAxisSpacing: 12,
                        childAspectRatio: 0.85,
                        children: tags.map((tag) {
                          final isSelected = selectedAllergens.contains(tag.id);
                          return GestureDetector(
                            onTap: () {
                              final current = ref.read(selectedAllergenTagsProvider);
                              if (isSelected) {
                                ref.read(selectedAllergenTagsProvider.notifier).state =
                                    {...current}..remove(tag.id);
                              } else {
                                ref.read(selectedAllergenTagsProvider.notifier).state =
                                    {...current, tag.id};
                              }
                            },
                            child: Container(
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? Colors.red.withOpacity(0.1)
                                    : (isDark ? AppTheme.surfaceDark : Colors.white),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: isSelected
                                      ? Colors.red
                                      : (isDark ? Colors.grey[700]! : Colors.grey[300]!),
                                  width: isSelected ? 2 : 1,
                                ),
                              ),
                              child: Stack(
                                children: [
                                  Center(
                                    child: Padding(
                                      padding: const EdgeInsets.all(8),
                                      child: Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Text(
                                            tag.emoji ?? '',
                                            style: const TextStyle(fontSize: 28),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            tag.label,
                                            textAlign: TextAlign.center,
                                            style: TextStyle(
                                              fontSize: 13,
                                              fontWeight: FontWeight.w600,
                                              color: isDark ? Colors.white : AppTheme.secondary,
                                            ),
                                          ),
                                          if (tag.description != null) ...[
                                            const SizedBox(height: 2),
                                            Text(
                                              tag.description!,
                                              textAlign: TextAlign.center,
                                              style: TextStyle(
                                                fontSize: 10,
                                                color: isDark ? Colors.grey[400] : Colors.grey[600],
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ],
                                        ],
                                      ),
                                    ),
                                  ),
                                  if (isSelected)
                                    const Positioned(
                                      top: 4,
                                      right: 4,
                                      child: Icon(
                                        Icons.check_circle,
                                        color: Colors.red,
                                        size: 20,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                      loading: () => const Center(child: CircularProgressIndicator()),
                      error: (err, stack) => Center(child: Text('Error: $err')),
                    ),

                    const SizedBox(height: 24),

                    // "Dietary Preferences" section
                    Text(
                      'Dietary Preferences',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white : AppTheme.secondary,
                      ),
                    ),

                    const SizedBox(height: 12),

                    // Dietary preference pills
                    dietaryTagsAsync.when(
                      data: (tags) => Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: tags.map((tag) {
                          final isSelected = selectedDietary.contains(tag.id);
                          return GestureDetector(
                            onTap: () {
                              final current = ref.read(selectedDietaryPreferenceTagsProvider);
                              if (isSelected) {
                                ref.read(selectedDietaryPreferenceTagsProvider.notifier).state =
                                    {...current}..remove(tag.id);
                              } else {
                                ref.read(selectedDietaryPreferenceTagsProvider.notifier).state =
                                    {...current, tag.id};
                              }
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? AppTheme.primary.withOpacity(0.15)
                                    : (isDark ? AppTheme.surfaceDark : Colors.white),
                                borderRadius: BorderRadius.circular(24),
                                border: Border.all(
                                  color: isSelected
                                      ? AppTheme.primary
                                      : (isDark ? Colors.grey[700]! : Colors.grey[300]!),
                                  width: isSelected ? 2 : 1,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(tag.emoji ?? '', style: const TextStyle(fontSize: 16)),
                                  const SizedBox(width: 6),
                                  Text(
                                    tag.label,
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                      color: isSelected
                                          ? AppTheme.primary
                                          : (isDark ? Colors.white : AppTheme.secondary),
                                    ),
                                  ),
                                  if (isSelected) ...[
                                    const SizedBox(width: 4),
                                    const Icon(Icons.check, color: AppTheme.primary, size: 16),
                                  ],
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                      loading: () => const Center(child: CircularProgressIndicator()),
                      error: (err, stack) => Center(child: Text('Error: $err')),
                    ),

                    const SizedBox(height: 24),

                    // "Other Ingredients to Avoid"
                    Text(
                      'Other Ingredients to Avoid',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white : AppTheme.secondary,
                      ),
                    ),

                    const SizedBox(height: 12),

                    // TextField + add button row
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _ingredientController,
                            decoration: InputDecoration(
                              hintText: 'e.g. Cilantro, MSG...',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          onPressed: _addCustomIngredient,
                          icon: const Icon(
                            Icons.add_circle,
                            color: AppTheme.primary,
                            size: 32,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),

                    // Custom ingredient chips
                    if (customIngredients.isNotEmpty)
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: customIngredients.map((ingredient) {
                          return Chip(
                            label: Text(
                              ingredient,
                              style: const TextStyle(color: Colors.white),
                            ),
                            backgroundColor: Colors.orange,
                            deleteIcon: const Icon(Icons.close, size: 18, color: Colors.white),
                            onDeleted: () => _removeCustomIngredient(ingredient),
                          );
                        }).toList(),
                      ),

                    const SizedBox(height: 32),

                    // Footer section
                    Center(
                      child: Text(
                        'Step 3/4',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: isDark ? Colors.grey[400] : Colors.grey[600],
                        ),
                      ),
                    ),

                    const SizedBox(height: 8),

                    // Progress bar
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildProgressStep(true),
                        const SizedBox(width: 4),
                        _buildProgressStep(true),
                        const SizedBox(width: 4),
                        _buildProgressStep(true),
                        const SizedBox(width: 4),
                        _buildProgressStep(false),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // Next Step button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _navigateToNext,
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

                    // Skip for now
                    Center(
                      child: TextButton(
                        onPressed: _skipToNext,
                        child: Text(
                          'Skip for now',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[400],
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
          ],
        ),
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
