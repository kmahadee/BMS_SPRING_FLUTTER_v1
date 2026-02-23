import 'package:flutter/material.dart';
import 'package:vantedge/features/loans/data/models/loan_enums.dart';
import 'loan_enum_display_helpers.dart';

/// Horizontally scrollable row of selectable cards for each [LoanType].
///
/// Pure presentation widget — zero business logic.
/// Selection state is managed externally via [selectedType] + [onTypeSelected].
///
/// Example usage:
/// ```dart
/// LoanTypeSelectorWidget(
///   selectedType: _selectedType,
///   onTypeSelected: (type) => setState(() => _selectedType = type),
/// )
/// ```
class LoanTypeSelectorWidget extends StatelessWidget {
  final LoanType? selectedType;
  final ValueChanged<LoanType> onTypeSelected;

  /// Padding applied to each card. Defaults to 12 × 10.
  final EdgeInsetsGeometry cardPadding;

  /// Whether to allow deselection by tapping the current selection again.
  final bool allowDeselect;

  const LoanTypeSelectorWidget({
    super.key,
    required this.selectedType,
    required this.onTypeSelected,
    this.cardPadding = const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
    this.allowDeselect = false,
  });

  @override
  Widget build(BuildContext context) {
    final types = LoanType.values;

    return SizedBox(
      height: 96,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 2),
        itemCount: types.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final type = types[index];
          return _LoanTypeCard(
            type: type,
            isSelected: selectedType == type,
            onTap: () {
              if (allowDeselect && selectedType == type) return;
              onTypeSelected(type);
            },
            padding: cardPadding,
          );
        },
      ),
    );
  }
}

// ─── Individual type card ────────────────────────────────────────────────────

class _LoanTypeCard extends StatelessWidget {
  final LoanType type;
  final bool isSelected;
  final VoidCallback onTap;
  final EdgeInsetsGeometry padding;

  const _LoanTypeCard({
    required this.type,
    required this.isSelected,
    required this.onTap,
    required this.padding,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final color = type.color;

    final Color bgColor = isSelected ? color : cs.surfaceContainerHighest;
    final Color iconColor = isSelected ? Colors.white : color;
    final Color labelColor =
        isSelected ? Colors.white : cs.onSurfaceVariant;

    return Semantics(
      label: '${type.displayName} loan type${isSelected ? ', selected' : ''}',
      button: true,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeInOut,
        width: 84,
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? color : cs.outlineVariant.withOpacity(0.5),
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: color.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  )
                ]
              : null,
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(14),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(14),
            child: Padding(
              padding: padding,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(type.icon, color: iconColor, size: 26),
                  const SizedBox(height: 6),
                  Text(
                    type.displayName,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: labelColor,
                      fontWeight:
                          isSelected ? FontWeight.w700 : FontWeight.w500,
                      fontSize: 10,
                      height: 1.2,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
