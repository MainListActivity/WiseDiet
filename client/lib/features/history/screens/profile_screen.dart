import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../l10n/l10n.dart';
import '../../auth/auth_controller.dart';
import '../../onboarding/models/user_profile.dart';
import '../../onboarding/providers/tag_provider.dart';
import '../providers/profile_provider.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  // Which field is currently being edited (null = none)
  String? _editingField;

  // Text controllers for inline editing
  final _textControllers = <String, TextEditingController>{};

  @override
  void dispose() {
    for (final c in _textControllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  TextEditingController _controllerFor(String field, String initialValue) {
    return _textControllers.putIfAbsent(
        field, () => TextEditingController(text: initialValue));
  }

  void _startEditing(String field, String initialValue) {
    // Reset the controller to current value when starting editing
    if (_textControllers.containsKey(field)) {
      _textControllers[field]!.text = initialValue;
    }
    setState(() {
      _editingField = field;
      _controllerFor(field, initialValue);
    });
  }

  void _cancelEditing() {
    setState(() {
      _editingField = null;
    });
  }

  Future<void> _confirmEdit(String field, UserProfile profile) async {
    final controller = _textControllers[field];
    if (controller == null) return;
    final text = controller.text.trim();

    Map<String, dynamic> patch = {};
    switch (field) {
      case 'age':
        final val = int.tryParse(text);
        if (val != null) patch = {'age': val};
      case 'height':
        final val = double.tryParse(text);
        if (val != null) patch = {'height': val};
      case 'weight':
        final val = double.tryParse(text);
        if (val != null) patch = {'weight': val};
      case 'familyMembers':
        final val = int.tryParse(text);
        if (val != null) patch = {'familyMembers': val};
    }

    if (patch.isNotEmpty) {
      await ref.read(profileProvider.notifier).updateField(patch);
    }
    setState(() {
      _editingField = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final profileAsync = ref.watch(profileProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.profileTitle)),
      body: profileAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('Error: $e'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => ref.refresh(profileProvider),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
        data: (profile) => _buildBody(context, l10n, profile),
      ),
    );
  }

  Widget _buildBody(
      BuildContext context, dynamic l10n, UserProfile profile) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
        // Basic Info section
        _SectionCard(
          sectionKey: const Key('profile-section-basic-info'),
          title: l10n.profileSectionBasicInfo,
          children: [
            _buildGenderRow(context, l10n, profile),
            _buildNumericRow(
              context: context,
              l10n: l10n,
              label: l10n.profileFieldAge,
              field: 'age',
              value: profile.age?.toString() ?? '',
              unit: l10n.unitYears,
              profile: profile,
            ),
            _buildNumericRow(
              context: context,
              l10n: l10n,
              label: l10n.profileFieldHeight,
              field: 'height',
              value: profile.height?.toString() ?? '',
              unit: l10n.unitCm,
              profile: profile,
            ),
            _buildNumericRow(
              context: context,
              l10n: l10n,
              label: l10n.profileFieldWeight,
              field: 'weight',
              value: profile.weight?.toString() ?? '',
              unit: l10n.unitKg,
              profile: profile,
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Household section
        _SectionCard(
          sectionKey: const Key('profile-section-household'),
          title: l10n.profileSectionHousehold,
          children: [
            _buildNumericRow(
              context: context,
              l10n: l10n,
              label: l10n.profileFieldFamilyMembers,
              field: 'familyMembers',
              value: profile.familyMembers.toString(),
              unit: l10n.unitPersons,
              profile: profile,
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Occupation section
        _SectionCard(
          sectionKey: const Key('profile-section-occupation'),
          title: l10n.profileSectionOccupation,
          children: [
            _buildTagRow(
              context: context,
              l10n: l10n,
              label: l10n.profileFieldOccupationTags,
              field: 'occupation',
              tagIds: profile.occupationTags,
              profile: profile,
              tagType: _TagType.occupation,
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Diet section
        _SectionCard(
          sectionKey: const Key('profile-section-diet'),
          title: l10n.profileSectionDiet,
          children: [
            _buildTagRow(
              context: context,
              l10n: l10n,
              label: l10n.profileFieldAllergens,
              field: 'allergens',
              tagIds: profile.allergenTagIds,
              profile: profile,
              tagType: _TagType.allergen,
            ),
            _buildTagRow(
              context: context,
              l10n: l10n,
              label: l10n.profileFieldDietaryPreferences,
              field: 'dietary',
              tagIds: profile.dietaryPreferenceTagIds,
              profile: profile,
              tagType: _TagType.dietary,
            ),
            _buildCustomAvoidRow(context, l10n, profile),
          ],
        ),
        const SizedBox(height: 24),

        // Logout button
        OutlinedButton.icon(
          key: const Key('logout-button'),
          onPressed: () => _showLogoutDialog(context),
          icon: const Icon(Icons.logout),
          label: Text(l10n.profileLogout),
          style: OutlinedButton.styleFrom(
            foregroundColor: Theme.of(context).colorScheme.error,
            side: BorderSide(color: Theme.of(context).colorScheme.error),
          ),
        ),
        const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildGenderRow(BuildContext context, dynamic l10n, UserProfile profile) {
    final field = 'gender';
    final value = profile.gender ?? '';
    final isEditing = _editingField == field;

    if (isEditing) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.profileFieldGender,
                style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: 8),
            RadioGroup<String>(
              groupValue: _controllerFor(field, value).text.isEmpty
                  ? null
                  : _controllerFor(field, value).text,
              onChanged: (v) {
                setState(() {
                  _controllerFor(field, value).text = v ?? '';
                });
              },
              child: Column(
                children: [
                  for (final option in ['Male', 'Female', 'Other'])
                    RadioListTile<String>(
                      title: Text(option),
                      value: option,
                      contentPadding: EdgeInsets.zero,
                      dense: true,
                    ),
                ],
              ),
            ),
            Row(
              children: [
                IconButton(
                  key: Key('profile-confirm-$field'),
                  icon: const Icon(Icons.check, color: AppTheme.primary),
                  onPressed: () async {
                    final v = _controllerFor(field, value).text;
                    if (v.isNotEmpty) {
                      await ref
                          .read(profileProvider.notifier)
                          .updateField({'gender': v});
                    }
                    setState(() => _editingField = null);
                  },
                ),
                IconButton(
                  key: Key('profile-cancel-$field'),
                  icon: const Icon(Icons.close),
                  onPressed: _cancelEditing,
                ),
              ],
            ),
          ],
        ),
      );
    }

    return _FieldRow(
      label: l10n.profileFieldGender,
      valueWidget: Text(value.isEmpty ? '—' : value),
      editKey: Key('profile-edit-$field'),
      onEdit: () => _startEditing(field, value),
    );
  }

  Widget _buildNumericRow({
    required BuildContext context,
    required dynamic l10n,
    required String label,
    required String field,
    required String value,
    required String unit,
    required UserProfile profile,
  }) {
    final isEditing = _editingField == field;

    if (isEditing) {
      final controller = _controllerFor(field, value);
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: 4),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    key: Key('profile-input-$field'),
                    controller: controller,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(
                      suffixText: unit,
                      border: const OutlineInputBorder(),
                      isDense: true,
                    ),
                  ),
                ),
                IconButton(
                  key: Key('profile-confirm-$field'),
                  icon: const Icon(Icons.check, color: AppTheme.primary),
                  onPressed: () => _confirmEdit(field, profile),
                ),
                IconButton(
                  key: Key('profile-cancel-$field'),
                  icon: const Icon(Icons.close),
                  onPressed: _cancelEditing,
                ),
              ],
            ),
          ],
        ),
      );
    }

    return _FieldRow(
      label: label,
      valueWidget: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(value.isEmpty ? '—' : value),
          if (value.isNotEmpty) ...[
            const SizedBox(width: 4),
            Text(unit,
                style: Theme.of(context).textTheme.bodySmall),
          ],
        ],
      ),
      editKey: Key('profile-edit-$field'),
      onEdit: () => _startEditing(field, value),
    );
  }

  Widget _buildTagRow({
    required BuildContext context,
    required dynamic l10n,
    required String label,
    required String field,
    required Set<int> tagIds,
    required UserProfile profile,
    required _TagType tagType,
  }) {
    final countText = tagIds.isEmpty
        ? l10n.profileNoTags
        : '${tagIds.length} selected';

    return _FieldRow(
      label: label,
      valueWidget: Text(countText),
      editKey: Key('profile-edit-$field'),
      onEdit: () => _openTagBottomSheet(context, field, tagIds, profile, tagType),
    );
  }

  Widget _buildCustomAvoidRow(
      BuildContext context, dynamic l10n, UserProfile profile) {
    final value = profile.customAvoidedIngredients.isEmpty
        ? l10n.profileNoCustomAvoid
        : profile.customAvoidedIngredients.join(', ');

    return _FieldRow(
      label: l10n.profileFieldCustomAvoid,
      valueWidget: Text(value),
      editKey: const Key('profile-edit-customAvoid'),
      onEdit: () => _openCustomAvoidEditor(context, profile),
    );
  }

  void _openCustomAvoidEditor(BuildContext context, UserProfile profile) {
    final controller = TextEditingController(
      text: profile.customAvoidedIngredients.join(', '),
    );
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) => Padding(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: 16,
          bottom: MediaQuery.of(sheetContext).viewInsets.bottom + 16,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              context.l10n.profileFieldCustomAvoid,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              autofocus: true,
              decoration: InputDecoration(
                hintText: '香菜, 榴莲',
                border: const OutlineInputBorder(),
                helperText: context.l10n.profileNoCustomAvoid,
              ),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () async {
                final items = controller.text
                    .split(',')
                    .map((s) => s.trim())
                    .where((s) => s.isNotEmpty)
                    .toList();
                await ref.read(profileProvider.notifier).updateField({
                  'customAvoidedIngredients':
                      items.isEmpty ? '' : items.join(','),
                });
                if (sheetContext.mounted) Navigator.of(sheetContext).pop();
              },
              child: const Text('确认'),
            ),
          ],
        ),
      ),
    ).whenComplete(controller.dispose);
  }

  void _openTagBottomSheet(
    BuildContext context,
    String field,
    Set<int> selectedIds,
    UserProfile profile,
    _TagType tagType,
  ) {
    final l10n = context.l10n;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) {
        return _TagBottomSheet(
          field: field,
          tagType: tagType,
          initialSelectedIds: Set.from(selectedIds),
          onSave: (newIds) async {
            Map<String, dynamic> patch = {};
            switch (tagType) {
              case _TagType.occupation:
                patch = {'occupationTagIds': newIds.join(',')};
              case _TagType.allergen:
                patch = {'allergenTagIds': newIds.join(',')};
              case _TagType.dietary:
                patch = {'dietaryPreferenceTagIds': newIds.join(',')};
            }
            await ref.read(profileProvider.notifier).updateField(patch);
            if (sheetContext.mounted) Navigator.of(sheetContext).pop();
          },
          l10n: l10n,
        );
      },
    );
  }

  void _showLogoutDialog(BuildContext context) {
    final l10n = context.l10n;
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.profileLogoutConfirmTitle),
        content: Text(l10n.profileLogoutConfirmBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(l10n.profileLogoutConfirmCancel),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              ref.read(authControllerProvider.notifier).logout();
            },
            child: Text(l10n.profileLogoutConfirmAction),
          ),
        ],
      ),
    );
  }
}

// ---- Supporting widgets ----

enum _TagType { occupation, allergen, dietary }

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.sectionKey,
    required this.title,
    required this.children,
  });

  final Key sectionKey;
  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Card(
      key: sectionKey,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(context)
                  .textTheme
                  .titleSmall
                  ?.copyWith(color: AppTheme.primary, fontWeight: FontWeight.bold),
            ),
            const Divider(),
            ...children,
          ],
        ),
      ),
    );
  }
}

class _FieldRow extends StatelessWidget {
  const _FieldRow({
    required this.label,
    required this.valueWidget,
    required this.editKey,
    required this.onEdit,
  });

  final String label;
  final Widget valueWidget;
  final Key editKey;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(label,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withValues(alpha: 0.6),
                    )),
          ),
          Expanded(
            flex: 3,
            child: valueWidget,
          ),
          IconButton(
            key: editKey,
            icon: const Icon(Icons.edit_outlined, size: 18),
            onPressed: onEdit,
            tooltip: 'Edit',
          ),
        ],
      ),
    );
  }
}

class _TagBottomSheet extends ConsumerStatefulWidget {
  const _TagBottomSheet({
    required this.field,
    required this.tagType,
    required this.initialSelectedIds,
    required this.onSave,
    required this.l10n,
  });

  final String field;
  final _TagType tagType;
  final Set<int> initialSelectedIds;
  final Future<void> Function(Set<int>) onSave;
  final dynamic l10n;

  @override
  ConsumerState<_TagBottomSheet> createState() => _TagBottomSheetState();
}

class _TagBottomSheetState extends ConsumerState<_TagBottomSheet> {
  late Set<int> _selectedIds;

  @override
  void initState() {
    super.initState();
    _selectedIds = Set.from(widget.initialSelectedIds);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const Key('profile-tag-bottom-sheet'),
      height: MediaQuery.of(context).size.height * 0.7,
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                widget.field,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              ElevatedButton(
                onPressed: () => widget.onSave(_selectedIds),
                child: const Text('Save'),
              ),
            ],
          ),
          const Divider(),
          Expanded(
            child: _buildTagList(context),
          ),
        ],
      ),
    );
  }

  Widget _buildTagList(BuildContext context) {
    switch (widget.tagType) {
      case _TagType.occupation:
        final tagsAsync = ref.watch(occupationTagsProvider);
        return tagsAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('Error: $e')),
          data: (tags) => ListView(
            children: tags.map((tag) {
              final selected = _selectedIds.contains(tag.id);
              return CheckboxListTile(
                title: Text(tag.icon != null
                    ? '${tag.icon} ${tag.label}'
                    : tag.label),
                value: selected,
                onChanged: (v) {
                  setState(() {
                    if (v == true) {
                      _selectedIds.add(tag.id);
                    } else {
                      _selectedIds.remove(tag.id);
                    }
                  });
                },
              );
            }).toList(),
          ),
        );

      case _TagType.allergen:
        final tagsAsync = ref.watch(allergenTagsProvider);
        return tagsAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('Error: $e')),
          data: (tags) => ListView(
            children: tags.map((tag) {
              final selected = _selectedIds.contains(tag.id);
              return CheckboxListTile(
                title: Text(tag.emoji != null
                    ? '${tag.emoji} ${tag.label}'
                    : tag.label),
                value: selected,
                onChanged: (v) {
                  setState(() {
                    if (v == true) {
                      _selectedIds.add(tag.id);
                    } else {
                      _selectedIds.remove(tag.id);
                    }
                  });
                },
              );
            }).toList(),
          ),
        );

      case _TagType.dietary:
        final tagsAsync = ref.watch(dietaryPreferenceTagsProvider);
        return tagsAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('Error: $e')),
          data: (tags) => ListView(
            children: tags.map((tag) {
              final selected = _selectedIds.contains(tag.id);
              return CheckboxListTile(
                title: Text(tag.emoji != null
                    ? '${tag.emoji} ${tag.label}'
                    : tag.label),
                value: selected,
                onChanged: (v) {
                  setState(() {
                    if (v == true) {
                      _selectedIds.add(tag.id);
                    } else {
                      _selectedIds.remove(tag.id);
                    }
                  });
                },
              );
            }).toList(),
          ),
        );
    }
  }
}
