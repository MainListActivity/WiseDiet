import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../l10n/l10n.dart';
import '../providers/onboarding_provider.dart';

class BasicInfoScreen extends ConsumerStatefulWidget {
  const BasicInfoScreen({super.key});

  @override
  ConsumerState<BasicInfoScreen> createState() => _BasicInfoScreenState();
}

class _BasicInfoScreenState extends ConsumerState<BasicInfoScreen> {
  String _gender = 'male';
  double _age = 28;
  double _height = 175;
  double _weight = 70;
  int _familyMembers = 1;

  double get _bmi => _weight / ((_height / 100) * (_height / 100));

  String get _bmiCategory {
    final l10n = context.l10n;
    if (_bmi < 18.5) {
      return l10n.bmiUnderweight;
    }
    if (_bmi < 25) {
      return l10n.bmiNormal;
    }
    if (_bmi < 30) {
      return l10n.bmiOverweight;
    }
    return l10n.bmiObesity;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      body: Stack(
        children: [
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: () {},
                        icon: const Icon(Icons.arrow_back),
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
                      const SizedBox(width: 48),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildStepIndicator(
                        true,
                        key: const Key('onboarding_step_1'),
                      ),
                      const SizedBox(width: 8),
                      _buildStepIndicator(false),
                      const SizedBox(width: 8),
                      _buildStepIndicator(false),
                      const SizedBox(width: 8),
                      _buildStepIndicator(false),
                    ],
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(24, 8, 24, 120),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
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
                              TextSpan(text: l10n.aboutYouPrefix),
                              TextSpan(
                                text: l10n.aboutYouHighlight,
                                style: const TextStyle(color: AppTheme.primary),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          l10n.basicInfoSubtitle,
                          style: TextStyle(
                            fontSize: 15,
                            color: Colors.grey[600],
                            height: 1.5,
                          ),
                        ),
                        const SizedBox(height: 24),
                        Text(
                          l10n.gender,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey[500],
                            letterSpacing: 0.8,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(
                              child: _buildGenderButton(
                                key: const Key('gender_male_button'),
                                genderKey: 'male',
                                label: l10n.genderMale,
                                icon: Icons.male,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildGenderButton(
                                key: const Key('gender_female_button'),
                                genderKey: 'female',
                                label: l10n.genderFemale,
                                icon: Icons.female,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildGenderButton(
                                key: const Key('gender_other_button'),
                                genderKey: 'other',
                                label: l10n.genderOther,
                                icon: Icons.person_outline,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        _buildSliderSection(
                          key: const Key('age_slider'),
                          label: l10n.age,
                          value: _age,
                          min: 16,
                          max: 80,
                          unit: l10n.unitYears,
                          onChanged: (val) => setState(() => _age = val),
                        ),
                        const SizedBox(height: 20),
                        _buildSliderSection(
                          key: const Key('height_slider'),
                          label: l10n.height,
                          value: _height,
                          min: 140,
                          max: 220,
                          unit: l10n.unitCm,
                          onChanged: (val) => setState(() => _height = val),
                        ),
                        const SizedBox(height: 20),
                        _buildSliderSection(
                          key: const Key('weight_slider'),
                          label: l10n.weight,
                          value: _weight,
                          min: 35,
                          max: 150,
                          unit: l10n.unitKg,
                          onChanged: (val) => setState(() => _weight = val),
                        ),
                        const SizedBox(height: 24),
                        Text(
                          l10n.householdDiners,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey[500],
                            letterSpacing: 0.8,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          l10n.householdDinersDescription,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[500],
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            IconButton.filledTonal(
                              key: const Key('household_minus_button'),
                              onPressed: _familyMembers > 1
                                  ? () => setState(() => _familyMembers--)
                                  : null,
                              icon: const Icon(Icons.remove),
                            ),
                            const SizedBox(width: 24),
                            Column(
                              children: [
                                Text(
                                  '$_familyMembers',
                                  key: const Key('household_value_text'),
                                  style: const TextStyle(
                                    fontSize: 44,
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.primary,
                                  ),
                                ),
                                Text(
                                  l10n.unitPersons,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[500],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(width: 24),
                            IconButton.filled(
                              key: const Key('household_plus_button'),
                              onPressed: () => setState(() => _familyMembers++),
                              icon: const Icon(Icons.add),
                            ),
                          ],
                        ),
                        const SizedBox(height: 18),
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            color: AppTheme.primary.withOpacity(0.08),
                            border: Border.all(
                              color: AppTheme.primary.withOpacity(0.15),
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: AppTheme.primary.withOpacity(0.14),
                                ),
                                child: const Icon(
                                  Icons.monitor_weight,
                                  color: AppTheme.primary,
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      l10n.estimatedBmi,
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text.rich(
                                      TextSpan(
                                        children: [
                                          TextSpan(
                                            text: _bmi.toStringAsFixed(1),
                                            style: const TextStyle(
                                              fontSize: 17,
                                              fontWeight: FontWeight.bold,
                                              color: AppTheme.primary,
                                            ),
                                          ),
                                          TextSpan(
                                            text: '  $_bmiCategory',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.grey[600],
                                            ),
                                          ),
                                        ],
                                      ),
                                      key: const Key('bmi_value_text'),
                                    ),
                                  ],
                                ),
                              ),
                              const Icon(
                                Icons.check_circle,
                                color: AppTheme.primary,
                              ),
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
        ],
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.fromLTRB(24, 10, 24, 24),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppTheme.backgroundLight.withOpacity(0),
              AppTheme.backgroundLight,
              AppTheme.backgroundLight,
            ],
          ),
        ),
        child: SafeArea(
          top: false,
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              key: const Key('basic_info_next_button'),
              onPressed: () {
                ref
                    .read(onboardingProvider.notifier)
                    .updateBasicInfo(
                      gender: _gender,
                      age: _age.round(),
                      height: _height,
                      weight: _weight,
                      familyMembers: _familyMembers,
                    );
                context.go('/onboarding/occupation');
              },
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    l10n.nextStep,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(width: 8),
                  const Icon(Icons.arrow_forward, size: 20),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStepIndicator(bool isActive, {Key? key}) {
    return Container(
      key: key,
      width: 32,
      height: 6,
      decoration: BoxDecoration(
        color: isActive ? AppTheme.primary : Colors.grey[300],
        borderRadius: BorderRadius.circular(999),
      ),
    );
  }

  Widget _buildGenderButton({
    required Key key,
    required String genderKey,
    required String label,
    required IconData icon,
  }) {
    final isSelected = _gender == genderKey;
    return OutlinedButton(
      key: key,
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(0, 88),
        side: BorderSide(
          color: isSelected ? AppTheme.primary : Colors.grey.shade300,
          width: 2,
        ),
        backgroundColor: isSelected ? AppTheme.primary : Colors.white,
        foregroundColor: isSelected ? Colors.white : Colors.grey.shade700,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      onPressed: () => setState(() => _gender = genderKey),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 28),
          const SizedBox(height: 6),
          Text(
            label,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  Widget _buildSliderSection({
    required Key key,
    required String label,
    required double value,
    required double min,
    required double max,
    required String unit,
    required ValueChanged<double> onChanged,
  }) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.grey[500],
                letterSpacing: 0.8,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                color: AppTheme.primary.withOpacity(0.1),
              ),
              child: Text(
                '${value.round()} $unit',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.primary,
                ),
              ),
            ),
          ],
        ),
        Slider(
          key: key,
          value: value,
          min: min,
          max: max,
          divisions: (max - min).round(),
          activeColor: AppTheme.primary,
          onChanged: onChanged,
        ),
      ],
    );
  }
}
