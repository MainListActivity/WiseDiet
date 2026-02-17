import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../l10n/app_localizations.dart';
import '../../../l10n/l10n.dart';

class StrategyReportScreen extends StatefulWidget {
  final Map<String, dynamic> strategy;

  const StrategyReportScreen({super.key, required this.strategy});

  @override
  State<StrategyReportScreen> createState() => _StrategyReportScreenState();
}

class _StrategyReportScreenState extends State<StrategyReportScreen> {
  late Map<String, String> _preferences;

  static Map<String, String> _preferenceLabels(AppLocalizations l10n) => {
    'daily_focus': l10n.prefDailyFocus,
    'meal_frequency': l10n.prefMealFrequency,
    'cooking_level': l10n.prefCookingLevel,
    'budget': l10n.prefBudget,
  };

  static Map<String, List<String>> _preferenceOptions(AppLocalizations l10n) => {
    'daily_focus': [l10n.optMentalClarity, l10n.optEnergy, l10n.optFatBurn],
    'meal_frequency': [l10n.opt2Meals, l10n.opt3Meals, l10n.opt3MealsSnack],
    'cooking_level': [l10n.optBeginnerFriendly, l10n.optBalanced, l10n.optAdvanced],
    'budget': [l10n.optBudgetLow, l10n.optBudgetMid, l10n.optBudgetHigh],
  };

  @override
  void initState() {
    super.initState();
    _preferences = Map<String, String>.from(
      widget.strategy['preferences'] ?? <String, String>{},
    );
  }

  Future<void> _editPreference(String key) async {
    final l10n = context.l10n;
    final options = _preferenceOptions(l10n)[key] ?? const <String>[];
    if (options.isEmpty) {
      return;
    }

    final labels = _preferenceLabels(l10n);

    final selected = await showModalBottomSheet<String>(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 8),
              Container(
                width: 42,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.black12,
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                l10n.selectPreference(labels[key] ?? key),
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 8),
              ...options.map(
                (option) => ListTile(
                  title: Text(option),
                  trailing: option == _preferences[key]
                      ? const Icon(Icons.check, color: AppTheme.primary)
                      : null,
                  onTap: () => Navigator.pop(context, option),
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );

    if (selected != null) {
      setState(() {
        _preferences[key] = selected;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final strategy = widget.strategy;
    final keyPoints = Map<String, String>.from(strategy['key_points'] ?? {});
    final projectedImpact = Map<String, String>.from(
      strategy['projected_impact'] ?? <String, String>{},
    );
    final ctaText = strategy['cta_text'] ?? l10n.startMyJourney;
    final infoHint = strategy['info_hint'] ?? l10n.preferencesInfoHint;
    final labels = _preferenceLabels(l10n);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.yourStrategy)),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 136),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: SizedBox(
                    key: const Key('strategy-progress-indicator'),
                    width: 72,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(4, (index) {
                        final isActive = index == 3;
                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 3),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 180),
                            width: isActive ? 24 : 6,
                            height: 6,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(10),
                              color: isActive
                                  ? AppTheme.primary
                                  : AppTheme.primary.withOpacity(0.35),
                            ),
                          ),
                        );
                      }),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 22,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(18, 18, 18, 14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  width: 36,
                                  height: 36,
                                  decoration: BoxDecoration(
                                    color: AppTheme.primary.withOpacity(0.12),
                                    borderRadius: BorderRadius.circular(18),
                                  ),
                                  child: const Icon(
                                    Icons.psychology,
                                    color: AppTheme.primary,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Text(
                                  l10n.yourPersonalizedStrategy,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 16,
                                    color: AppTheme.secondary,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Text(
                              strategy['title'] ?? l10n.healthStrategy,
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.secondary,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              strategy['summary'] ?? '',
                              style: const TextStyle(fontSize: 15, height: 1.5),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        height: 6,
                        decoration: const BoxDecoration(
                          borderRadius: BorderRadius.vertical(
                            bottom: Radius.circular(20),
                          ),
                          gradient: LinearGradient(
                            colors: [
                              Color(0x664B7C5A),
                              AppTheme.primary,
                              Color(0x664B7C5A),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  l10n.projectedImpact,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF6C7584),
                    letterSpacing: 0.8,
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: _ImpactCard(
                        title: l10n.focusBoost,
                        value: projectedImpact['focus_boost'] ?? '+15%',
                        icon: Icons.bolt,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _ImpactCard(
                        title: l10n.calorieTarget,
                        value: projectedImpact['calorie_target'] ?? '2050',
                        icon: Icons.local_fire_department,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      l10n.yourPreferences,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF6C7584),
                        letterSpacing: 0.8,
                      ),
                    ),
                    TextButton.icon(
                      onPressed: () => _editPreference('daily_focus'),
                      icon: const Icon(Icons.edit, size: 14),
                      label: Text(l10n.adjust),
                      style: TextButton.styleFrom(
                        foregroundColor: AppTheme.primary,
                        textStyle: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                  ],
                ),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: const Color(0xFFE6EBF1)),
                  ),
                  child: Column(
                    children: labels.entries
                        .toList()
                        .asMap()
                        .entries
                        .map((entry) {
                          final index = entry.key;
                          final item = entry.value;
                          final key = item.key;
                          final value = _preferences[key] ?? '-';
                          final isLast = index == labels.length - 1;
                          return Column(
                            children: [
                              _PreferenceItem(
                                key: Key('preference-item-$key'),
                                label: item.value,
                                value: value,
                                onTap: () => _editPreference(key),
                              ),
                              if (!isLast)
                                const Divider(
                                  height: 1,
                                  indent: 14,
                                  endIndent: 14,
                                ),
                            ],
                          );
                        })
                        .toList(),
                  ),
                ),
                const SizedBox(height: 18),
                Container(
                  key: const Key('strategy-info-card'),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withOpacity(0.06),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: AppTheme.primary.withOpacity(0.18),
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Padding(
                        padding: EdgeInsets.only(top: 2),
                        child: Icon(
                          Icons.info,
                          color: AppTheme.primary,
                          size: 18,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          infoHint,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF5C6675),
                            height: 1.45,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  l10n.keyFocusAreas,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.secondary,
                  ),
                ),
                const SizedBox(height: 16),
                ...keyPoints.entries.map(
                  (entry) => Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.check_circle, color: AppTheme.primary),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                entry.key,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              Text(entry.value),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              padding: const EdgeInsets.fromLTRB(24, 28, 24, 22),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0x00F6F7F7), AppTheme.backgroundLight],
                ),
              ),
              child: SafeArea(
                top: false,
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    key: const Key('strategy-fixed-cta'),
                    style: ElevatedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(999),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      elevation: 6,
                      shadowColor: AppTheme.primary.withOpacity(0.32),
                    ),
                    onPressed: () {
                      context.go('/home');
                    },
                    icon: const Icon(Icons.arrow_forward),
                    label: Text(ctaText),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ImpactCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;

  const _ImpactCard({
    required this.title,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE6EBF1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 13,
                  color: Color(0xFF6C7584),
                  fontWeight: FontWeight.w600,
                ),
              ),
              Icon(icon, color: AppTheme.primary, size: 18),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(
              fontSize: 30,
              fontWeight: FontWeight.w800,
              color: AppTheme.secondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _PreferenceItem extends StatelessWidget {
  final String label;
  final String value;
  final VoidCallback onTap;

  const _PreferenceItem({
    super.key,
    required this.label,
    required this.value,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF738095),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    value,
                    style: const TextStyle(
                      fontSize: 15,
                      color: AppTheme.secondary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Color(0xFF9AA5B5)),
          ],
        ),
      ),
    );
  }
}
