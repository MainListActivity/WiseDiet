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
      name: 'Grilled Salmon & Asparagus',
      reason: 'For overtime focus: rich in B vitamins',
      cookMinutes: 20,
    ),
    _DishOption(
      name: 'Quinoa Avocado Salad',
      reason: 'Light lunch for sustained concentration',
      cookMinutes: 10,
    ),
    _DishOption(
      name: 'Zucchini Noodles Pesto',
      reason: 'Lower carb option for evening',
      cookMinutes: 15,
    ),
  ];

  final Set<int> _selectedIndexes = <int>{};

  int get _totalMinutes {
    return _selectedIndexes
        .map((index) => _dishes[index].cookMinutes)
        .fold(0, (sum, minutes) => sum + minutes);
  }

  bool get _canConfirm => _selectedIndexes.length >= widget.requiredSelections;

  @override
  Widget build(BuildContext context) {
    final requiredCount = widget.requiredSelections <= 0
        ? 1
        : widget.requiredSelections;
    return Scaffold(
      appBar: AppBar(title: const Text("Today's Smart Menu")),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'Daily Insight',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppTheme.secondary,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.secondary.withOpacity(0.08),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Text(
              'Start your day with higher protein to improve focus and reduce evening cravings.',
            ),
          ),
          const SizedBox(height: 16),
          ..._dishes.asMap().entries.map((entry) {
            final index = entry.key;
            final dish = entry.value;
            final selected = _selectedIndexes.contains(index);
            return Card(
              child: CheckboxListTile(
                key: Key('dish-checkbox-$index'),
                value: selected,
                title: Text(dish.name),
                subtitle: Text('${dish.reason} • ${dish.cookMinutes} mins'),
                controlAffinity: ListTileControlAffinity.trailing,
                onChanged: (value) {
                  setState(() {
                    if (value == true) {
                      _selectedIndexes.add(index);
                    } else {
                      _selectedIndexes.remove(index);
                    }
                  });
                },
              ),
            );
          }),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(16),
              boxShadow: const [
                BoxShadow(
                  blurRadius: 14,
                  offset: Offset(0, 4),
                  color: Color(0x14000000),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  '${_selectedIndexes.length} selected • $_totalMinutes mins',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 10),
                ElevatedButton(
                  key: const Key('confirm-menu-button'),
                  onPressed: _canConfirm
                      ? () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'Menu confirmed (${_selectedIndexes.length}/$requiredCount)',
                              ),
                            ),
                          );
                        }
                      : null,
                  child: Text('Confirm Today\'s Menu ($requiredCount)'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DishOption {
  final String name;
  final String reason;
  final int cookMinutes;

  const _DishOption({
    required this.name,
    required this.reason,
    required this.cookMinutes,
  });
}
