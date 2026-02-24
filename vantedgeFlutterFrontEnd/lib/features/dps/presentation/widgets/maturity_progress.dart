import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../data/models/dps_model.dart';

/// Animated circular + linear progress widget showing DPS maturity status.
class MaturityProgress extends StatefulWidget {
  final DpsModel dps;

  const MaturityProgress({super.key, required this.dps});

  @override
  State<MaturityProgress> createState() => _MaturityProgressState();
}

class _MaturityProgressState extends State<MaturityProgress>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _progressAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _progressAnim = Tween<double>(begin: 0, end: _progress()).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );
    _controller.forward();
  }

  @override
  void didUpdateWidget(MaturityProgress oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.dps != widget.dps) {
      _progressAnim = Tween<double>(
        begin: _progressAnim.value,
        end: _progress(),
      ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
      _controller
        ..reset()
        ..forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  double _progress() {
    final paid = widget.dps.totalInstallmentsPaid ?? 0;
    final total = widget.dps.tenureMonths ?? 1;
    return (paid / total).clamp(0.0, 1.0);
  }

  String _currencySymbol() {
    switch ((widget.dps.currency ?? 'BDT').toUpperCase()) {
      case 'USD': return '\$';
      case 'EUR': return '€';
      case 'GBP': return '£';
      case 'BDT':
      default:    return '৳';
    }
  }

  Color _statusColor(ColorScheme cs) {
    switch (widget.dps.status?.toUpperCase()) {
      case 'ACTIVE':    return Colors.green.shade600;
      case 'MATURED':   return cs.primary;
      case 'CLOSED':    return cs.onSurfaceVariant;
      case 'DEFAULTED': return cs.error;
      case 'SUSPENDED': return Colors.orange.shade700;
      default:          return cs.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme   = Theme.of(context);
    final cs      = theme.colorScheme;
    final dps     = widget.dps;
    final symbol  = _currencySymbol();
    final color   = _statusColor(cs);
    final paid    = dps.totalInstallmentsPaid ?? 0;
    final total   = dps.tenureMonths ?? 0;
    final pending = dps.pendingInstallments ?? (total - paid);

    final currFmt = NumberFormat.currency(
      symbol: '$symbol ',
      decimalDigits: 2,
      locale: 'en_IN',
    );

    String fmtAmt(double? v) => v != null ? currFmt.format(v) : '—';

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: color.withOpacity(0.35)),
      ),
      color: color.withOpacity(0.05),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // ── Circular progress + central stats ──────────────────────────
            Row(
              children: [
                // Circular progress ring
                AnimatedBuilder(
                  animation: _progressAnim,
                  builder: (_, __) => SizedBox(
                    width: 110,
                    height: 110,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        SizedBox(
                          width: 110,
                          height: 110,
                          child: CircularProgressIndicator(
                            value: _progressAnim.value,
                            strokeWidth: 10,
                            backgroundColor: cs.surfaceContainerHighest,
                            valueColor: AlwaysStoppedAnimation<Color>(color),
                            strokeCap: StrokeCap.round,
                          ),
                        ),
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '${(_progressAnim.value * 100).toStringAsFixed(0)}%',
                              style: theme.textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.w800,
                                color: color,
                              ),
                            ),
                            Text(
                              'Complete',
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: cs.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(width: 20),

                // Stats beside ring
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _StatLine(
                        label: 'Installments Paid',
                        value: '$paid of $total',
                        valueColor: color,
                        theme: theme,
                        cs: cs,
                      ),
                      const SizedBox(height: 10),
                      _StatLine(
                        label: 'Pending',
                        value: '$pending installments',
                        theme: theme,
                        cs: cs,
                      ),
                      const SizedBox(height: 10),
                      _StatLine(
                        label: 'Tenure',
                        value: '$total months',
                        theme: theme,
                        cs: cs,
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 18),
            Divider(height: 1, color: cs.outlineVariant.withOpacity(0.5)),
            const SizedBox(height: 16),

            // ── Deposit vs maturity amounts ────────────────────────────────
            Row(
              children: [
                Expanded(
                  child: _AmountTile(
                    label: 'Deposited So Far',
                    amount: fmtAmt(dps.totalDeposited),
                    icon: Icons.savings_outlined,
                    color: Colors.green.shade600,
                    theme: theme,
                    cs: cs,
                  ),
                ),
                Container(
                  width: 1,
                  height: 48,
                  color: cs.outlineVariant.withOpacity(0.5),
                ),
                Expanded(
                  child: _AmountTile(
                    label: 'Maturity Amount',
                    amount: fmtAmt(dps.maturityAmount),
                    icon: Icons.account_balance_rounded,
                    color: cs.primary,
                    theme: theme,
                    cs: cs,
                    align: CrossAxisAlignment.end,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 14),

            // ── Linear bar (deposited vs maturity) ─────────────────────────
            if ((dps.maturityAmount ?? 0) > 0) ...[
              Builder(
                builder: (_) {
                  final deposited = dps.totalDeposited ?? 0;
                  final maturity  = dps.maturityAmount!;
                  final ratio = (deposited / maturity).clamp(0.0, 1.0);

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Savings progress',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: cs.onSurfaceVariant,
                            ),
                          ),
                          Text(
                            '${(ratio * 100).toStringAsFixed(1)}% of target',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: color,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      TweenAnimationBuilder<double>(
                        tween: Tween(begin: 0, end: ratio),
                        duration: const Duration(milliseconds: 1200),
                        curve: Curves.easeOutCubic,
                        builder: (_, val, __) => ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: val,
                            minHeight: 7,
                            backgroundColor: cs.surfaceContainerHighest,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.green.shade600,
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ── Private helpers ────────────────────────────────────────────────────────

class _StatLine extends StatelessWidget {
  final String label;
  final String value;
  final ThemeData theme;
  final ColorScheme cs;
  final Color? valueColor;

  const _StatLine({
    required this.label,
    required this.value,
    required this.theme,
    required this.cs,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
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
            fontWeight: FontWeight.w700,
            color: valueColor ?? cs.onSurface,
          ),
        ),
      ],
    );
  }
}

class _AmountTile extends StatelessWidget {
  final String label;
  final String amount;
  final IconData icon;
  final Color color;
  final ThemeData theme;
  final ColorScheme cs;
  final CrossAxisAlignment align;

  const _AmountTile({
    required this.label,
    required this.amount,
    required this.icon,
    required this.color,
    required this.theme,
    required this.cs,
    this.align = CrossAxisAlignment.start,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Column(
        crossAxisAlignment: align,
        children: [
          Row(
            mainAxisAlignment: align == CrossAxisAlignment.end
                ? MainAxisAlignment.end
                : MainAxisAlignment.start,
            children: [
              Icon(icon, size: 13, color: color),
              const SizedBox(width: 4),
              Text(
                label,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: cs.onSurfaceVariant,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            amount,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
