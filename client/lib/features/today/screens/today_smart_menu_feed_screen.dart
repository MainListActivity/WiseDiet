import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';

class TodaySmartMenuFeedScreen extends StatefulWidget {
  final int requiredSelections;

  const TodaySmartMenuFeedScreen({super.key, this.requiredSelections = 1});

  @override
  State<TodaySmartMenuFeedScreen> createState() =>
      _TodaySmartMenuFeedScreenState();
}

class _TodaySmartMenuFeedScreenState extends State<TodaySmartMenuFeedScreen> {
  final List<_DishOption> _dishes = const [
    _DishOption(
      name: 'Greek Yogurt Berry Bowl',
      reason: 'Steady morning energy with high protein',
      mealType: 'breakfast',
      calories: 310,
      nutrientTags: ['High Protein', 'Probiotics'],
      imageUrl:
          'https://images.unsplash.com/photo-1488477181946-6428a0291777?w=800',
      cookMinutes: 10,
    ),
    _DishOption(
      name: 'Spinach Egg Wrap',
      reason: 'Iron and protein for better morning focus',
      mealType: 'breakfast',
      calories: 340,
      nutrientTags: ['Iron', 'B Vitamins'],
      imageUrl:
          'https://images.unsplash.com/photo-1513442542250-854d436a73f2?w=800',
      cookMinutes: 14,
    ),
    _DishOption(
      name: 'Quinoa Avocado Salad',
      reason: 'Low-GI lunch to avoid the afternoon crash',
      mealType: 'lunch',
      calories: 420,
      nutrientTags: ['High Fiber', 'Low GI'],
      imageUrl:
          'https://images.unsplash.com/photo-1546069901-ba9599a7e63c?w=800',
      cookMinutes: 18,
    ),
    _DishOption(
      name: 'Miso Chicken Rice Bowl',
      reason: 'Balanced carbs and lean protein for work blocks',
      mealType: 'lunch',
      calories: 490,
      nutrientTags: ['Lean Protein', 'B Vitamins'],
      imageUrl:
          'https://images.unsplash.com/photo-1512621776951-a57141f2eefd?w=800',
      cookMinutes: 24,
    ),
    _DishOption(
      name: 'Apple Peanut Butter Cups',
      reason: 'Portable satiety snack between meetings',
      mealType: 'snack',
      calories: 220,
      nutrientTags: ['Healthy Fats', 'Fiber'],
      imageUrl:
          'https://images.unsplash.com/photo-1560807707-8cc77767d783?w=800',
      cookMinutes: 8,
    ),
    _DishOption(
      name: 'Edamame Citrus Mix',
      reason: 'Plant protein to bridge lunch and dinner',
      mealType: 'snack',
      calories: 180,
      nutrientTags: ['Plant Protein', 'Vitamin C'],
      imageUrl:
          'https://images.unsplash.com/photo-1615486363979-110f1dc7f9c3?w=800',
      cookMinutes: 7,
    ),
    _DishOption(
      name: 'Grilled Salmon & Asparagus',
      reason: 'Omega-3 rich dinner for recovery and focus',
      mealType: 'dinner',
      calories: 510,
      nutrientTags: ['Omega-3', 'High Protein'],
      imageUrl:
          'https://images.unsplash.com/photo-1467003909585-2f8a72700288?w=800',
      cookMinutes: 28,
    ),
    _DishOption(
      name: 'Zucchini Noodles Pesto',
      reason: 'Lower-carb option for lighter evenings',
      mealType: 'dinner',
      calories: 370,
      nutrientTags: ['Low Carb', 'Vitamins'],
      imageUrl:
          'https://images.unsplash.com/photo-1621996346565-e3dbc353d2e5?w=800',
      cookMinutes: 21,
    ),
  ];

  final List<_MealSection> _sections = const [
    _MealSection(type: 'breakfast', title: 'Breakfast', timelineLabel: '07:30'),
    _MealSection(type: 'lunch', title: 'Lunch', timelineLabel: '12:30'),
    _MealSection(type: 'snack', title: 'Snack', timelineLabel: '16:00'),
    _MealSection(type: 'dinner', title: 'Dinner', timelineLabel: '19:00'),
  ];

  final Set<int> _selectedIndexes = <int>{};

  int get _requiredCount =>
      widget.requiredSelections <= 0 ? 1 : widget.requiredSelections;

  int get _totalMinutes {
    return _selectedIndexes
        .map((index) => _dishes[index].cookMinutes)
        .fold(0, (sum, minutes) => sum + minutes);
  }

  int get _totalCalories {
    return _selectedIndexes
        .map((index) => _dishes[index].calories)
        .fold(0, (sum, calories) => sum + calories);
  }

  bool get _canConfirm => _selectedIndexes.length >= _requiredCount;

  @override
  Widget build(BuildContext context) {
    final progress = (_selectedIndexes.length / _requiredCount).clamp(0.0, 1.0);

    return Scaffold(
      appBar: AppBar(title: const Text("Today's Smart Menu")),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
        children: [
          _buildGuideCard(),
          const SizedBox(height: 12),
          _buildDailyInsightCard(),
          const SizedBox(height: 16),
          ..._sections.map((section) => _buildMealTimelineSection(section)),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: Container(
            key: const Key('floating-progress-bar'),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(18),
              boxShadow: const [
                BoxShadow(
                  blurRadius: 16,
                  offset: Offset(0, 5),
                  color: Color(0x14000000),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Text(
                      '${_selectedIndexes.length} / $_requiredCount selected',
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    const Spacer(),
                    Text(
                      '$_totalCalories kcal • $_totalMinutes mins',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 8,
                    backgroundColor: Theme.of(context)
                        .colorScheme
                        .primary
                        .withOpacity(0.14),
                  ),
                ),
                const SizedBox(height: 12),
                ElevatedButton(
                  key: const Key('confirm-menu-button'),
                  onPressed: _canConfirm
                      ? () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'Menu confirmed (${_selectedIndexes.length}/$_requiredCount)',
                              ),
                            ),
                          );
                        }
                      : null,
                  child: Text('Confirm Today\'s Menu ($_requiredCount)'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGuideCard() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.primary.withOpacity(0.07),
        borderRadius: BorderRadius.circular(14),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'N+1 Selection Guide',
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
          SizedBox(height: 6),
          Text(
            'Choose at least N dishes for your household. We prepared one extra option per meal slot for flexibility.',
          ),
        ],
      ),
    );
  }

  Widget _buildDailyInsightCard() {
    return Container(
      key: const Key('daily-insight-card'),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFEEF7FF), Color(0xFFF7FAFF)],
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFDBEAFE)),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Daily Insight',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          ),
          SizedBox(height: 6),
          Text(
            'Higher protein in breakfast and lunch can reduce evening cravings and improve concentration stability.',
          ),
        ],
      ),
    );
  }

  Widget _buildMealTimelineSection(_MealSection section) {
    final color = _mealColor(section.type);
    final dishes = _dishes
        .asMap()
        .entries
        .where((entry) => entry.value.mealType == section.type)
        .toList();

    return Container(
      key: Key('timeline-${section.type}'),
      margin: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 72,
            child: Column(
              children: [
                Text(
                  section.timelineLabel,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  key: Key('meal-color-${section.type}'),
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                ),
                Container(width: 2, height: 88, color: color.withOpacity(0.35)),
              ],
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  section.title,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: color,
                  ),
                ),
                const SizedBox(height: 8),
                ...dishes.map((entry) => _buildDishCard(entry.key, entry.value, color)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDishCard(int index, _DishOption dish, Color mealColor) {
    final selected = _selectedIndexes.contains(index);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        key: Key('dish-card-$index'),
        borderRadius: BorderRadius.circular(14),
        onTap: () {
          setState(() {
            if (selected) {
              _selectedIndexes.remove(index);
            } else {
              _selectedIndexes.add(index);
            }
          });
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: selected ? mealColor.withOpacity(0.10) : Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: selected ? mealColor : const Color(0xFFE5E7EB),
              width: selected ? 2 : 1,
            ),
          ),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.network(
                  dish.imageUrl,
                  width: 72,
                  height: 72,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    width: 72,
                    height: 72,
                    color: const Color(0xFFE5E7EB),
                    alignment: Alignment.center,
                    child: const Icon(Icons.image_not_supported),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            dish.name,
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                        ),
                        if (selected)
                          Container(
                            key: Key('dish-selected-$index'),
                            width: 20,
                            height: 20,
                            decoration: BoxDecoration(
                              color: mealColor,
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: const Icon(
                              Icons.check,
                              size: 14,
                              color: Colors.white,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        _metaPill('${dish.calories} kcal'),
                        ...dish.nutrientTags.map(_metaPill),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF3F4F6),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        'AI reason: ${dish.reason}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _metaPill(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Text(text, style: const TextStyle(fontSize: 12)),
    );
  }

  Color _mealColor(String mealType) {
    switch (mealType) {
      case 'breakfast':
        return const Color(0xFFF59E0B);
      case 'lunch':
        return const Color(0xFF22C55E);
      case 'dinner':
        return const Color(0xFF3B82F6);
      case 'snack':
        return const Color(0xFF8B5CF6);
      default:
        return AppTheme.secondary;
    }
  }
}

class _MealSection {
  final String type;
  final String title;
  final String timelineLabel;

  const _MealSection({
    required this.type,
    required this.title,
    required this.timelineLabel,
  });
}

class _DishOption {
  final String name;
  final String reason;
  final String mealType;
  final int calories;
  final List<String> nutrientTags;
  final String imageUrl;
  final int cookMinutes;

  const _DishOption({
    required this.name,
    required this.reason,
    required this.mealType,
    required this.calories,
    required this.nutrientTags,
    required this.imageUrl,
    required this.cookMinutes,
  });
}
