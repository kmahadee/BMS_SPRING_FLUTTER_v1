import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../../data/models/dps_installment_model.dart';

/// Compact card for a single DPS installment. Tapping opens a full-detail
/// bottom sheet.
class InstallmentCard extends StatelessWidget {
  final DpsInstallmentModel installment;

  const InstallmentCard({super.key, required this.installment});

  // ── Formatters ─────────────────────────────────────────────────────────────

  static final _dateFmt   = DateFormat('dd MMM yyyy');
  static final _currFmt   = NumberFormat.currency(
    symbol: '৳ ',
    decimalDigits: 2,
    locale: 'en_IN',
  );

  String _fmtDate(DateTime? d) => d != null ? _dateFmt.format(d) : '—';
  String _fmtAmt(double? v)    => v != null ? _currFmt.format(v) : '—';

  // ── Status helpers ─────────────────────────────────────────────────────────

  _StatusStyle _style(String? status, ColorScheme cs) {
    switch (status?.toUpperCase()) {
      case 'PAID':
        return _StatusStyle(
          label: 'Paid',
          icon:  Icons.check_circle_rounded,
          fg:    const Color(0xFF2E7D32),
          bg:    const Color(0xFF2E7D32),
        );
      case 'OVERDUE':
        return _StatusStyle(
          label: 'Overdue',
          icon:  Icons.warning_rounded,
          fg:    cs.error,
          bg:    cs.error,
        );
      case 'WAIVED':
        return _StatusStyle(
          label: 'Waived',
          icon:  Icons.do_not_disturb_on_rounded,
          fg:    cs.onSurfaceVariant,
          bg:    cs.onSurfaceVariant,
        );
      case 'PENDING':
      default:
        return _StatusStyle(
          label: 'Pending',
          icon:  Icons.schedule_rounded,
          fg:    const Color(0xFFF57F17),   // orange
          bg:    const Color(0xFFF57F17),
        );
    }
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final theme  = Theme.of(context);
    final cs     = theme.colorScheme;
    final st     = _style(installment.status, cs);
    final hasPenalty = (installment.penaltyAmount ?? 0) > 0;

    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: cs.outlineVariant.withOpacity(0.6)),
      ),
      color: cs.surface,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => _showDetailSheet(context),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // ── Number bubble ──────────────────────────────────────────────
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: st.bg.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Center(
                  child: Text(
                    '#${installment.installmentNumber ?? '?'}',
                    style: theme.textTheme.labelMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: st.fg,
                    ),
                  ),
                ),
              ),

              const SizedBox(width: 12),

              // ── Date column ────────────────────────────────────────────────
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.calendar_today_outlined,
                            size: 12, color: cs.onSurfaceVariant),
                        const SizedBox(width: 4),
                        Text(
                          'Due: ${_fmtDate(installment.dueDate)}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: cs.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                    if (installment.paymentDate != null) ...[
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Icon(Icons.check_rounded,
                              size: 12, color: const Color(0xFF2E7D32)),
                          const SizedBox(width: 4),
                          Text(
                            'Paid: ${_fmtDate(installment.paymentDate)}',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: const Color(0xFF2E7D32),
                            ),
                          ),
                        ],
                      ),
                    ],
                    if (installment.transactionId != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        'TXN: ${installment.transactionId}',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: cs.onSurfaceVariant.withOpacity(0.7),
                          fontFamily: 'monospace',
                          fontSize: 10,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),

              const SizedBox(width: 12),

              // ── Amount + status ────────────────────────────────────────────
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _fmtAmt(installment.amount),
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: cs.onSurface,
                    ),
                  ),
                  const SizedBox(height: 4),
                  _StatusChip(st: st, theme: theme),
                  if (hasPenalty) ...[
                    const SizedBox(height: 4),
                    Text(
                      '+${_fmtAmt(installment.penaltyAmount)} penalty',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: cs.error,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ],
              ),

              const SizedBox(width: 6),
              Icon(
                Icons.chevron_right_rounded,
                size: 18,
                color: cs.onSurfaceVariant.withOpacity(0.5),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Bottom sheet ───────────────────────────────────────────────────────────

  void _showDetailSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _InstallmentDetailSheet(
        installment: installment,
        fmtDate: _fmtDate,
        fmtAmt: _fmtAmt,
      ),
    );
  }
}

// ── Status chip ─────────────────────────────────────────────────────────────

class _StatusStyle {
  final String label;
  final IconData icon;
  final Color fg;
  final Color bg;

  const _StatusStyle({
    required this.label,
    required this.icon,
    required this.fg,
    required this.bg,
  });
}

class _StatusChip extends StatelessWidget {
  final _StatusStyle st;
  final ThemeData theme;

  const _StatusChip({required this.st, required this.theme});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: st.bg.withOpacity(0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: st.fg.withOpacity(0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(st.icon, size: 10, color: st.fg),
          const SizedBox(width: 3),
          Text(
            st.label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: st.fg,
              fontWeight: FontWeight.w700,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Detail bottom sheet ─────────────────────────────────────────────────────

class _InstallmentDetailSheet extends StatelessWidget {
  final DpsInstallmentModel installment;
  final String Function(DateTime?) fmtDate;
  final String Function(double?) fmtAmt;

  const _InstallmentDetailSheet({
    required this.installment,
    required this.fmtDate,
    required this.fmtAmt,
  });

  void _copy(BuildContext context, String text, String label) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$label copied'),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme  = Theme.of(context);
    final cs     = theme.colorScheme;
    final inst   = installment;
    final hasPenalty = (inst.penaltyAmount ?? 0) > 0;

    // Resolve status style inline for the header badge
    late final Color statusFg;
    late final String statusLabel;
    switch (inst.status?.toUpperCase()) {
      case 'PAID':
        statusFg    = const Color(0xFF2E7D32);
        statusLabel = 'Paid';
        break;
      case 'OVERDUE':
        statusFg    = cs.error;
        statusLabel = 'Overdue';
        break;
      case 'WAIVED':
        statusFg    = cs.onSurfaceVariant;
        statusLabel = 'Waived';
        break;
      default:
        statusFg    = const Color(0xFFF57F17);
        statusLabel = 'Pending';
    }

    return Padding(
      padding: EdgeInsets.fromLTRB(
        20, 12, 20,
        MediaQuery.of(context).padding.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: cs.outlineVariant,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Title + status
          Row(
            children: [
              Text(
                'Installment #${inst.installmentNumber ?? '?'}',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: statusFg.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: statusFg.withOpacity(0.4)),
                ),
                child: Text(
                  statusLabel,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: statusFg,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),

          // Dates section
          _SheetRow('Due Date',     fmtDate(inst.dueDate),     theme, cs),
          if (inst.paymentDate != null)
            _SheetRow(
              'Payment Date',
              fmtDate(inst.paymentDate),
              theme, cs,
              valueColor: const Color(0xFF2E7D32),
            ),

          const Divider(height: 24),

          // Amounts section
          _SheetRow('Amount',       fmtAmt(inst.amount),       theme, cs),
          if (hasPenalty)
            _SheetRow(
              'Penalty',
              fmtAmt(inst.penaltyAmount),
              theme, cs,
              valueColor: cs.error,
            ),
          if (hasPenalty)
            _SheetRow(
              'Total Charged',
              fmtAmt((inst.amount ?? 0) + (inst.penaltyAmount ?? 0)),
              theme, cs,
              bold: true,
              valueColor: cs.primary,
            ),

          // IDs section
          if (inst.transactionId != null || inst.receiptNumber != null) ...[
            const Divider(height: 24),
            if (inst.transactionId != null)
              _SheetRow(
                'Transaction ID',
                inst.transactionId!,
                theme, cs,
                mono: true,
                trailing: IconButton(
                  icon: const Icon(Icons.copy_rounded, size: 15),
                  tooltip: 'Copy',
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  onPressed: () =>
                      _copy(context, inst.transactionId!, 'Transaction ID'),
                ),
              ),
            if (inst.receiptNumber != null)
              _SheetRow(
                'Receipt No.',
                inst.receiptNumber!,
                theme, cs,
                mono: true,
                trailing: IconButton(
                  icon: const Icon(Icons.copy_rounded, size: 15),
                  tooltip: 'Copy',
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  onPressed: () =>
                      _copy(context, inst.receiptNumber!, 'Receipt number'),
                ),
              ),
          ],
        ],
      ),
    );
  }
}

class _SheetRow extends StatelessWidget {
  final String label;
  final String value;
  final ThemeData theme;
  final ColorScheme cs;
  final Color? valueColor;
  final bool bold;
  final bool mono;
  final Widget? trailing;

  const _SheetRow(
    this.label,
    this.value,
    this.theme,
    this.cs, {
    this.valueColor,
    this.bold = false,
    this.mono = false,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: cs.onSurfaceVariant,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
                color: valueColor ?? cs.onSurface,
                fontFamily: mono ? 'monospace' : null,
                fontSize: mono ? 12 : null,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (trailing != null) ...[
            const SizedBox(width: 4),
            trailing!,
          ],
        ],
      ),
    );
  }
}
