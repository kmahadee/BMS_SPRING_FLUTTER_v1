import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../data/models/dps_model.dart';

class DpsCard extends StatelessWidget {
  final DpsModel dps;
  final VoidCallback onTap;

  const DpsCard({
    super.key,
    required this.dps,
    required this.onTap,
  });

  // ── Formatters ─────────────────────────────────────────────────────────────

  static final _dateFmt = DateFormat('dd MMM yyyy');

  String _fmtAmount(double? amount, String currencySymbol) {
    if (amount == null) return '—';
    final fmt = NumberFormat.currency(
      symbol: '$currencySymbol ',
      decimalDigits: 2,
      locale: 'en_IN',
    );
    return fmt.format(amount);
  }

  String _fmtDate(DateTime? dt) => dt != null ? _dateFmt.format(dt) : '—';

  // ── Status helpers ─────────────────────────────────────────────────────────

  Color _statusColor(String? status, ColorScheme cs) {
    switch (status?.toUpperCase()) {
      case 'ACTIVE':
        return Colors.green.shade600;
      case 'MATURED':
        return cs.primary;
      case 'CLOSED':
        return cs.onSurfaceVariant;
      case 'DEFAULTED':
        return cs.error;
      case 'SUSPENDED':
        return Colors.orange.shade700;
      default:
        return cs.onSurfaceVariant;
    }
  }

  String _statusLabel(String? status) {
    if (status == null) return 'Unknown';
    return status[0].toUpperCase() + status.substring(1).toLowerCase();
  }

  double _progress() {
    final paid = dps.totalInstallmentsPaid ?? 0;
    final total = dps.tenureMonths ?? 1;
    return (paid / total).clamp(0.0, 1.0);
  }

  String _currencySymbol() {
    switch ((dps.currency ?? 'BDT').toUpperCase()) {
      case 'USD':
        return '\$';
      case 'EUR':
        return '€';
      case 'GBP':
        return '£';
      case 'BDT':
      default:
        return '৳';
    }
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final symbol = _currencySymbol();
    final statusColor = _statusColor(dps.status, cs);
    final progress = _progress();
    final isActive = (dps.status?.toUpperCase() == 'ACTIVE');

    return Semantics(
      label: 'DPS ${dps.dpsNumber}, '
          'monthly installment ${_fmtAmount(dps.monthlyInstallment, symbol)}, '
          'status ${_statusLabel(dps.status)}.',
      button: true,
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
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Header row ───────────────────────────────────────────────
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Icon bubble
                    Container(
                      width: 46,
                      height: 46,
                      decoration: BoxDecoration(
                        color: cs.primary.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.savings_outlined,
                        color: cs.primary,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),

                    // DPS number + tenure
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            dps.dpsNumber ?? '—',
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: cs.onSurface,
                              fontFamily: 'monospace',
                              letterSpacing: 0.5,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${dps.tenureMonths ?? '—'}-Month DPS',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: cs.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Status chip
                    _StatusChip(label: _statusLabel(dps.status), color: statusColor),
                  ],
                ),

                const SizedBox(height: 12),
                Divider(height: 1, color: cs.outlineVariant.withOpacity(0.5)),
                const SizedBox(height: 12),

                // ── Amount row ───────────────────────────────────────────────
                Row(
                  children: [
                    _InfoColumn(
                      label: 'Monthly',
                      value: _fmtAmount(dps.monthlyInstallment, symbol),
                      theme: theme,
                      cs: cs,
                      bold: true,
                    ),
                    const SizedBox(width: 20),
                    _InfoColumn(
                      label: 'Maturity Amount',
                      value: _fmtAmount(dps.maturityAmount, symbol),
                      theme: theme,
                      cs: cs,
                      valueColor: cs.primary,
                    ),
                    const Spacer(),
                    _InfoColumn(
                      label: 'Matures On',
                      value: _fmtDate(dps.maturityDate),
                      theme: theme,
                      cs: cs,
                      align: CrossAxisAlignment.end,
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // ── Progress bar ─────────────────────────────────────────────
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '${dps.totalInstallmentsPaid ?? 0} / ${dps.tenureMonths ?? 0} installments',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: cs.onSurfaceVariant,
                          ),
                        ),
                        Text(
                          '${(progress * 100).toStringAsFixed(0)}%',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: statusColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: progress,
                        minHeight: 6,
                        backgroundColor: cs.surfaceContainerHighest,
                        valueColor: AlwaysStoppedAnimation<Color>(statusColor),
                      ),
                    ),
                  ],
                ),

                // ── Next payment date (ACTIVE only) ──────────────────────────
                if (isActive && dps.nextPaymentDate != null) ...[
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Icon(
                        Icons.calendar_today_outlined,
                        size: 13,
                        color: cs.onSurfaceVariant,
                      ),
                      const SizedBox(width: 5),
                      Text(
                        'Next payment: ${_fmtDate(dps.nextPaymentDate)}',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: cs.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ],

                // ── Penalty warning ──────────────────────────────────────────
                if ((dps.penaltyAmount ?? 0) > 0) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(
                        Icons.warning_amber_rounded,
                        size: 13,
                        color: cs.error,
                      ),
                      const SizedBox(width: 5),
                      Text(
                        'Penalty: ${_fmtAmount(dps.penaltyAmount, symbol)}',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: cs.error,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Private sub-widgets ────────────────────────────────────────────────────

class _StatusChip extends StatelessWidget {
  final String label;
  final Color color;

  const _StatusChip({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: color,
          letterSpacing: 0.3,
        ),
      ),
    );
  }
}

class _InfoColumn extends StatelessWidget {
  final String label;
  final String value;
  final ThemeData theme;
  final ColorScheme cs;
  final Color? valueColor;
  final bool bold;
  final CrossAxisAlignment align;

  const _InfoColumn({
    required this.label,
    required this.value,
    required this.theme,
    required this.cs,
    this.valueColor,
    this.bold = false,
    this.align = CrossAxisAlignment.start,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: align,
      children: [
        Text(
          label,
          style: theme.textTheme.labelSmall?.copyWith(
            color: cs.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
            color: valueColor ?? cs.onSurface,
          ),
        ),
      ],
    );
  }
}
