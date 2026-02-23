import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:vantedge/features/loans/data/models/loan_model.dart';
import 'loan_enum_display_helpers.dart';
import 'loan_status_badge.dart';

/// Tappable card that surfaces the key fields of a [LoanListItemModel].
///
/// Design mirrors [AccountCard] and [TransactionCard]:
/// - Elevated card with rounded corners
/// - Loan-type colour accent for the icon container
/// - Press-scale tap feedback animation
/// - Chevron affordance when [onTap] is provided
class LoanCard extends StatefulWidget {
  final LoanListItemModel loan;
  final VoidCallback? onTap;

  /// When true the card renders in a more compact single-line layout
  /// suitable for a dense list. Defaults to false (full layout).
  final bool compact;

  const LoanCard({
    super.key,
    required this.loan,
    this.onTap,
    this.compact = false,
  });

  @override
  State<LoanCard> createState() => _LoanCardState();
}

class _LoanCardState extends State<LoanCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _scaleController;
  late final Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _scaleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.97).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _scaleController.dispose();
    super.dispose();
  }

  // ─── Formatting helpers ──────────────────────────────────────────────────

  static final _currencyFmt = NumberFormat.currency(
    symbol: '৳',
    decimalDigits: 2,
    locale: 'en_IN',
  );

  static final _dateFmt = DateFormat('dd MMM yyyy');

  String _fmt(double? amount) =>
      amount != null ? _currencyFmt.format(amount) : '—';

  String _fmtDate(DateTime? dt) => dt != null ? _dateFmt.format(dt) : '—';

  // ─── Tap feedback ─────────────────────────────────────────────────────────

  void _onTapDown(TapDownDetails _) => _scaleController.forward();
  void _onTapUp(TapUpDetails _) => _scaleController.reverse();
  void _onTapCancel() => _scaleController.reverse();

  // ─── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final loan = widget.loan;
    final typeColor = loan.loanType.color;
    final typeIcon = loan.loanType.icon;

    return Semantics(
      label: '${loan.loanType.displayName}, ID ${loan.loanId}, '
          'principal ${_fmt(loan.principal)}, '
          'status ${loan.loanStatus.displayName}.',
      button: widget.onTap != null,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Card(
          elevation: 0,
          margin: const EdgeInsets.symmetric(vertical: 4),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: cs.outlineVariant.withOpacity(0.6)),
          ),
          color: cs.surface,
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: widget.onTap,
            onTapDown: _onTapDown,
            onTapUp: _onTapUp,
            onTapCancel: _onTapCancel,
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: widget.compact
                  ? _CompactLayout(
                      loan: loan,
                      typeColor: typeColor,
                      typeIcon: typeIcon,
                      fmt: _fmt,
                      onTap: widget.onTap,
                      theme: theme,
                      cs: cs,
                    )
                  : _FullLayout(
                      loan: loan,
                      typeColor: typeColor,
                      typeIcon: typeIcon,
                      fmt: _fmt,
                      fmtDate: _fmtDate,
                      onTap: widget.onTap,
                      theme: theme,
                      cs: cs,
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Full layout (default) ───────────────────────────────────────────────────

class _FullLayout extends StatelessWidget {
  final LoanListItemModel loan;
  final Color typeColor;
  final IconData typeIcon;
  final String Function(double?) fmt;
  final String Function(DateTime?) fmtDate;
  final VoidCallback? onTap;
  final ThemeData theme;
  final ColorScheme cs;

  const _FullLayout({
    required this.loan,
    required this.typeColor,
    required this.typeIcon,
    required this.fmt,
    required this.fmtDate,
    required this.onTap,
    required this.theme,
    required this.cs,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Header row ──────────────────────────────────────────────────────
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Icon container
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: typeColor.withOpacity(0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(typeIcon, color: typeColor, size: 24),
            ),
            const SizedBox(width: 12),

            // Loan type + ID
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    loan.loanType.displayName,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: cs.onSurface,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    loan.loanId,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: cs.onSurfaceVariant,
                      fontFamily: 'monospace',
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),

            // Status badge
            LoanStatusBadge(status: loan.loanStatus, compact: true),
          ],
        ),

        const SizedBox(height: 12),
        Divider(height: 1, color: cs.outlineVariant.withOpacity(0.5)),
        const SizedBox(height: 12),

        // ── Amount row ──────────────────────────────────────────────────────
        Row(
          children: [
            _AmountColumn(
              label: 'Principal',
              value: fmt(loan.principal),
              theme: theme,
              cs: cs,
            ),
            const SizedBox(width: 16),
            _AmountColumn(
              label: 'Outstanding',
              value: fmt(loan.outstandingBalance),
              theme: theme,
              cs: cs,
              valueColor: loan.outstandingBalance != null &&
                      loan.outstandingBalance! > 0
                  ? const Color(0xFFC62828)
                  : null,
            ),
            const Spacer(),
            if (loan.monthlyEMI != null)
              _AmountColumn(
                label: 'Next EMI',
                value: fmt(loan.monthlyEMI),
                theme: theme,
                cs: cs,
                align: CrossAxisAlignment.end,
                valueColor: typeColor,
              ),
          ],
        ),

        // ── Application date footer ─────────────────────────────────────────
        if (loan.applicationDate != null) ...[
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Applied: ${fmtDate(loan.applicationDate)}',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: cs.onSurfaceVariant.withOpacity(0.7),
                ),
              ),
              if (onTap != null)
                Icon(
                  Icons.chevron_right_rounded,
                  size: 18,
                  color: cs.onSurfaceVariant.withOpacity(0.5),
                ),
            ],
          ),
        ] else if (onTap != null) ...[
          const SizedBox(height: 4),
          Align(
            alignment: Alignment.centerRight,
            child: Icon(
              Icons.chevron_right_rounded,
              size: 18,
              color: cs.onSurfaceVariant.withOpacity(0.5),
            ),
          ),
        ],
      ],
    );
  }
}

// ─── Compact layout ──────────────────────────────────────────────────────────

class _CompactLayout extends StatelessWidget {
  final LoanListItemModel loan;
  final Color typeColor;
  final IconData typeIcon;
  final String Function(double?) fmt;
  final VoidCallback? onTap;
  final ThemeData theme;
  final ColorScheme cs;

  const _CompactLayout({
    required this.loan,
    required this.typeColor,
    required this.typeIcon,
    required this.fmt,
    required this.onTap,
    required this.theme,
    required this.cs,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: typeColor.withOpacity(0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(typeIcon, color: typeColor, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                loan.loanType.displayName,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Text(
                fmt(loan.principal),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: cs.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            LoanStatusBadge(status: loan.loanStatus, compact: true),
            if (loan.monthlyEMI != null) ...[
              const SizedBox(height: 4),
              Text(
                fmt(loan.monthlyEMI),
                style: theme.textTheme.labelSmall?.copyWith(
                  color: typeColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ],
        ),
        if (onTap != null) ...[
          const SizedBox(width: 6),
          Icon(Icons.chevron_right_rounded,
              size: 18, color: cs.onSurfaceVariant.withOpacity(0.5)),
        ],
      ],
    );
  }
}

// ─── Shared sub-widget ───────────────────────────────────────────────────────

class _AmountColumn extends StatelessWidget {
  final String label;
  final String value;
  final ThemeData theme;
  final ColorScheme cs;
  final CrossAxisAlignment align;
  final Color? valueColor;

  const _AmountColumn({
    required this.label,
    required this.value,
    required this.theme,
    required this.cs,
    this.align = CrossAxisAlignment.start,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: align,
      children: [
        Text(
          label,
          style: theme.textTheme.labelSmall?.copyWith(
            color: cs.onSurfaceVariant.withOpacity(0.7),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: theme.textTheme.bodySmall?.copyWith(
            fontWeight: FontWeight.w700,
            color: valueColor ?? cs.onSurface,
          ),
        ),
      ],
    );
  }
}
