import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../models/occupation_tag.dart';

class TagItem extends StatelessWidget {
  final OccupationTag tag;
  final bool isSelected;
  final VoidCallback onTap;

  const TagItem({
    super.key,
    required this.tag,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        transform: Matrix4.identity()..scale(isSelected ? 1.05 : 1.0),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primary : (Theme.of(context).brightness == Brightness.dark ? AppTheme.surfaceLight.withOpacity(0.1) : AppTheme.surfaceLight),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? Colors.transparent : Colors.grey.withOpacity(0.3),
            width: 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppTheme.primary.withOpacity(0.4),
                    blurRadius: 15,
                    offset: const Offset(0, 0),
                    spreadRadius: -3,
                  )
                ]
              : [],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (tag.icon != null && isSelected) ...[
              Icon(
                _getIconData(tag.icon!),
                color: Colors.white,
                size: 18,
              ),
              const SizedBox(width: 8),
            ],
            Text(
              tag.label,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.grey[700],
                fontWeight: FontWeight.w500,
                fontSize: 14,
              ),
            ),
            if (isSelected) ...[
              const SizedBox(width: 8),
              const Icon(
                Icons.check,
                color: Colors.white,
                size: 16,
              ),
            ],
          ],
        ),
      ),
    );
  }

  IconData _getIconData(String iconName) {
    switch (iconName) {
      case 'terminal':
        return Icons.terminal;
      case 'monitor_heart':
        return Icons.monitor_heart;
      default:
        return Icons.circle;
    }
  }
}
