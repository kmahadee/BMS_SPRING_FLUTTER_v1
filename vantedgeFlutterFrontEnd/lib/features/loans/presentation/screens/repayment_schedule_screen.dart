import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';

import 'package:vantedge/features/loans/data/models/loan_enums.dart';
import 'package:vantedge/features/loans/data/models/loan_statement.dart';
import 'package:vantedge/features/loans/data/models/repayment_schedule.dart';
import 'package:vantedge/features/loans/presentation/providers/loan_provider.dart';
import 'package:vantedge/shared/widgets/custom_app_bar.dart';

// ─── Screen ───────────────────────────────────────────────────────────────────

class RepaymentScheduleScreen extends StatefulWidget {
  final String loanId;

  const RepaymentScheduleScreen({super.key, required this.loanId});

  @override
  State<RepaymentScheduleScreen> createState() =>
      _RepaymentScheduleScreenState();
}

class _RepaymentScheduleScreenState extends State<RepaymentScheduleScreen> {
  static final _currFmt = NumberFormat.currency(
    symbol: '৳',
    decimalDigits: 2,
    locale: 'en_IN',
  );
  static final _compactFmt = NumberFormat.compactCurrency(
    symbol: '৳',
    decimalDigits: 0,
    locale: 'en_IN',
  );
  static final _dateFmt = DateFormat('dd MMM yyyy');

  ScheduleStatus? _statusFilter;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<LoanProvider>();
      if (provider.loanStatement?.loanId != widget.loanId) {
        provider.fetchLoanStatement(widget.loanId);
      }
    });
  }

  Future<void> _refresh() =>
      context.read<LoanProvider>().fetchLoanStatement(widget.loanId);

  String _fmt(double? v)    => v != null ? _currFmt.format(v) : '—';
  String _compact(double v) => _compactFmt.format(v);

  List<RepaymentScheduleModel> _filtered(List<RepaymentScheduleModel> src) {
    if (_statusFilter == null) return src;
    return src.where((s) => s.status == _statusFilter).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<LoanProvider>(
      builder: (context, provider, _) {
        if (provider.isLoading && !provider.hasStatement) {
          return _LoadingScaffold();
        }
        if (provider.hasError && !provider.hasStatement) {
          return _ErrorScaffold(
            message: provider.errorMessage!,
            onRetry: () { provider.clearError(); _refresh(); },
          );
        }

        final statement = provider.loanStatement;
        if (statement == null) {
          return _ErrorScaffold(message: 'Statement not available.', onRetry: _refresh);
        }

        final schedule = _filtered(statement.repaymentSchedule);

        return Scaffold(
          backgroundColor: Theme.of(context).colorScheme.surfaceContainerLowest,
          appBar: CustomAppBar(
            title: 'Repayment Schedule',
            showNotifications: false,
            actions: [
              IconButton(
                icon: const Icon(Icons.refresh_rounded),
                onPressed: _refresh,
                tooltip: 'Refresh',
              ),
            ],
          ),
          body: RefreshIndicator(
            onRefresh: _refresh,
            child: Column(
              children: [
                _SummaryHeader(statement: statement, compact: _compact),
                if (statement.nextEMIDate != null && statement.nextEMIAmount != null)
                  _NextEMIBanner(
                    date: statement.nextEMIDate!,
                    amount: statement.nextEMIAmount!,
                    dateFmt: _dateFmt,
                    fmt: _fmt,
                  ),
                _FilterBar(
                  selected: _statusFilter,
                  onSelected: (s) => setState(() => _statusFilter = s),
                ),
                Expanded(
                  child: _ScheduleTable(
                    rows: schedule,
                    allRows: statement.repaymentSchedule,
                    fmt: _fmt,
                    compact: _compact,
                    dateFmt: _dateFmt,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ─── Summary Header ───────────────────────────────────────────────────────────

class _SummaryHeader extends StatelessWidget {
  final LoanStatementModel statement;
  final String Function(double) compact;

  const _SummaryHeader({required this.statement, required this.compact});

  @override
  Widget build(BuildContext context) {
    final theme   = Theme.of(context);
    final cs      = theme.colorScheme;
    final paid    = statement.installmentsPaid ?? 0;
    final pending = statement.installmentsPending ?? 0;
    final overdue = statement.overdueInstallments.length;
    final total   = statement.totalInstallments;
    final progress = total > 0 ? paid / total : 0.0;

    return Container(
      color: cs.surface,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Stat row ──────────────────────────────────────────────────────
          IntrinsicHeight(
            child: Row(
              children: [
                _StatCell('$total', 'Total EMIs', cs.primary, theme),
                _VSep(cs),
                _StatCell('$paid', 'Paid', const Color(0xFF2E7D32), theme),
                _VSep(cs),
                _StatCell('$pending', 'Pending', cs.onSurfaceVariant, theme),
                _VSep(cs),
                _StatCell('$overdue', 'Overdue', cs.error, theme),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // ── Progress bar ──────────────────────────────────────────────────
          Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 8,
                    backgroundColor: cs.surfaceContainerHighest,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      overdue > 0 ? cs.error : const Color(0xFF2E7D32),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                '${(progress * 100).toStringAsFixed(1)}%',
                style: theme.textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: cs.primary,
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // ── Financial strip ───────────────────────────────────────────────
          Row(
            children: [
              Expanded(child: _AmtCell('Total Paid',
                  compact(statement.totalPaid ?? 0),
                  const Color(0xFF2E7D32), theme)),
              Expanded(child: _AmtCell('Outstanding',
                  compact(statement.outstandingBalance ?? 0),
                  cs.error, theme)),
              Expanded(child: _AmtCell('Monthly EMI',
                  compact(statement.monthlyEMI ?? 0),
                  cs.primary, theme)),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatCell extends StatelessWidget {
  final String value;
  final String label;
  final Color color;
  final ThemeData theme;

  const _StatCell(this.value, this.label, this.color, this.theme);

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(value,
              style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800, color: color)),
          Text(label,
              textAlign: TextAlign.center,
              style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant)),
        ],
      ),
    );
  }
}

class _VSep extends StatelessWidget {
  final ColorScheme cs;
  const _VSep(this.cs);
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1, margin: const EdgeInsets.symmetric(vertical: 4),
      color: cs.outlineVariant.withOpacity(0.6),
    );
  }
}

class _AmtCell extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final ThemeData theme;
  const _AmtCell(this.label, this.value, this.color, this.theme);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(label,
            style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant)),
        const SizedBox(height: 2),
        Text(value,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w700, color: color)),
      ],
    );
  }
}

// ─── Next EMI Banner ──────────────────────────────────────────────────────────

class _NextEMIBanner extends StatelessWidget {
  final DateTime date;
  final double amount;
  final DateFormat dateFmt;
  final String Function(double?) fmt;

  const _NextEMIBanner({
    required this.date,
    required this.amount,
    required this.dateFmt,
    required this.fmt,
  });

  @override
  Widget build(BuildContext context) {
    final theme    = Theme.of(context);
    final cs       = theme.colorScheme;
    final isOverdue = date.isBefore(DateTime.now());
    final days      = date.difference(DateTime.now()).inDays.abs();

    return Container(
      margin: const EdgeInsets.fromLTRB(12, 8, 12, 0),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: isOverdue
            ? cs.errorContainer.withOpacity(0.45)
            : cs.primaryContainer.withOpacity(0.4),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isOverdue
              ? cs.error.withOpacity(0.4)
              : cs.primary.withOpacity(0.3),
        ),
      ),
      child: Row(
        children: [
          Icon(
            isOverdue ? Icons.warning_amber_rounded : Icons.upcoming_rounded,
            color: isOverdue ? cs.error : cs.primary,
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isOverdue ? 'EMI Overdue!' : 'Next EMI Due',
                  style: theme.textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: isOverdue ? cs.error : cs.primary,
                  ),
                ),
                Text(
                  isOverdue
                      ? '$days day${days == 1 ? "" : "s"} ago — ${dateFmt.format(date)}'
                      : 'In $days day${days == 1 ? "" : "s"} — ${dateFmt.format(date)}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: cs.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          Text(
            fmt(amount),
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w800,
              color: isOverdue ? cs.error : cs.primary,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Filter Bar ───────────────────────────────────────────────────────────────

class _FilterBar extends StatelessWidget {
  final ScheduleStatus? selected;
  final ValueChanged<ScheduleStatus?> onSelected;

  const _FilterBar({required this.selected, required this.onSelected});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      color: cs.surfaceContainerHighest.withOpacity(0.4),
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Row(
          children: [
            _FChip('All', selected == null, cs.primary,
                () => onSelected(null)),
            const SizedBox(width: 8),
            _FChip('Paid', selected == ScheduleStatus.paid,
                const Color(0xFF2E7D32),
                () => onSelected(
                    selected == ScheduleStatus.paid ? null : ScheduleStatus.paid)),
            const SizedBox(width: 8),
            _FChip('Pending', selected == ScheduleStatus.pending,
                cs.onSurfaceVariant,
                () => onSelected(
                    selected == ScheduleStatus.pending ? null : ScheduleStatus.pending)),
            const SizedBox(width: 8),
            _FChip('Overdue', selected == ScheduleStatus.overdue,
                cs.error,
                () => onSelected(
                    selected == ScheduleStatus.overdue ? null : ScheduleStatus.overdue)),
          ],
        ),
      ),
    );
  }
}

class _FChip extends StatelessWidget {
  final String label;
  final bool selected;
  final Color color;
  final VoidCallback onTap;

  const _FChip(this.label, this.selected, this.color, this.onTap);

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: selected ? color.withOpacity(0.14) : Colors.transparent,
          border: Border.all(
            color: selected ? color : cs.outlineVariant,
          ),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: selected ? color : cs.onSurfaceVariant,
                fontWeight: selected ? FontWeight.w700 : FontWeight.normal,
              ),
        ),
      ),
    );
  }
}

// ─── Column widths ─────────────────────────────────────────────────────────────

const double _wNo     = 36.0;
const double _wDate   = 84.0;
const double _wAmount = 78.0;
const double _wStatus = 68.0;

// ─── Schedule Table ───────────────────────────────────────────────────────────

class _ScheduleTable extends StatelessWidget {
  final List<RepaymentScheduleModel> rows;
  final List<RepaymentScheduleModel> allRows;
  final String Function(double?) fmt;
  final String Function(double) compact;
  final DateFormat dateFmt;

  const _ScheduleTable({
    required this.rows,
    required this.allRows,
    required this.fmt,
    required this.compact,
    required this.dateFmt,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs    = theme.colorScheme;

    if (rows.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.inbox_rounded, size: 64, color: cs.outlineVariant),
            const SizedBox(height: 12),
            Text('No installments match this filter.',
                style: theme.textTheme.bodyMedium?.copyWith(
                    color: cs.onSurfaceVariant)),
          ],
        ),
      );
    }

    // Footer totals (from allRows to show schedule-wide sums)
    double totPrincipal = 0, totInterest = 0, totEMI = 0;
    for (final r in allRows) {
      totPrincipal += r.principalAmount;
      totInterest  += r.interestAmount;
      totEMI       += r.totalAmount;
    }

    return Column(
      children: [
        // Sticky header
        Material(
          elevation: 1,
          shadowColor: cs.shadow.withOpacity(0.15),
          color: cs.surfaceContainer,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 9),
            child: Row(
              children: [
                _HCell('#',          _wNo,     theme, cs),
                _HCell('Due Date',   _wDate,   theme, cs),
                _HCell('Principal',  _wAmount, theme, cs, align: TextAlign.end),
                _HCell('Interest',   _wAmount, theme, cs, align: TextAlign.end),
                _HCell('EMI',        _wAmount, theme, cs, align: TextAlign.end),
                _HCell('Status',     _wStatus, theme, cs, align: TextAlign.center),
              ],
            ),
          ),
        ),

        // Rows
        Expanded(
          child: ListView.builder(
            padding: EdgeInsets.zero,
            itemCount: rows.length,
            itemBuilder: (context, i) => _DataRow(
              row: rows[i],
              fmt: fmt,
              compact: compact,
              dateFmt: dateFmt,
              theme: theme,
              cs: cs,
              isAlternate: i.isOdd,
            ),
          ),
        ),

        // Footer
        Material(
          elevation: 2,
          shadowColor: cs.shadow.withOpacity(0.15),
          color: cs.primaryContainer.withOpacity(0.25),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
            child: Row(
              children: [
                SizedBox(
                  width: _wNo + _wDate,
                  child: Text('Total',
                      style: theme.textTheme.labelMedium?.copyWith(
                          fontWeight: FontWeight.w800, color: cs.primary)),
                ),
                SizedBox(
                  width: _wAmount,
                  child: Text(compact(totPrincipal),
                      textAlign: TextAlign.end,
                      style: theme.textTheme.labelMedium?.copyWith(
                          fontWeight: FontWeight.w800)),
                ),
                SizedBox(
                  width: _wAmount,
                  child: Text(compact(totInterest),
                      textAlign: TextAlign.end,
                      style: theme.textTheme.labelMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: cs.onSurfaceVariant)),
                ),
                SizedBox(
                  width: _wAmount,
                  child: Text(compact(totEMI),
                      textAlign: TextAlign.end,
                      style: theme.textTheme.labelMedium?.copyWith(
                          fontWeight: FontWeight.w800, color: cs.primary)),
                ),
                const SizedBox(width: _wStatus),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _HCell extends StatelessWidget {
  final String label;
  final double width;
  final ThemeData theme;
  final ColorScheme cs;
  final TextAlign align;

  const _HCell(this.label, this.width, this.theme, this.cs,
      {this.align = TextAlign.start});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: Text(label,
          textAlign: align,
          style: theme.textTheme.labelSmall?.copyWith(
              fontWeight: FontWeight.w700,
              color: cs.onSurface,
              letterSpacing: 0.3)),
    );
  }
}

class _DataRow extends StatelessWidget {
  final RepaymentScheduleModel row;
  final String Function(double?) fmt;
  final String Function(double) compact;
  final DateFormat dateFmt;
  final ThemeData theme;
  final ColorScheme cs;
  final bool isAlternate;

  const _DataRow({
    required this.row,
    required this.fmt,
    required this.compact,
    required this.dateFmt,
    required this.theme,
    required this.cs,
    required this.isAlternate,
  });

  @override
  Widget build(BuildContext context) {
    Color rowBg;
    switch (row.status) {
      case ScheduleStatus.paid:
        rowBg = const Color(0xFF2E7D32).withOpacity(0.05);
        break;
      case ScheduleStatus.overdue:
        rowBg = cs.error.withOpacity(0.06);
        break;
      default:
        rowBg = isAlternate
            ? cs.surfaceContainerHighest.withOpacity(0.3)
            : Colors.transparent;
    }

    return InkWell(
      onTap: () => _showDetail(context),
      child: Container(
        color: rowBg,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
        child: Row(
          children: [
            // #
            SizedBox(
              width: _wNo,
              child: Text('${row.installmentNumber}',
                  style: theme.textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: cs.onSurfaceVariant)),
            ),
            // Date
            SizedBox(
              width: _wDate,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(dateFmt.format(row.dueDate),
                      style: theme.textTheme.labelSmall?.copyWith(
                          fontWeight: FontWeight.w600)),
                  if (row.paymentDate != null)
                    Text('Paid ${dateFmt.format(row.paymentDate!)}',
                        style: theme.textTheme.labelSmall?.copyWith(
                            color: const Color(0xFF2E7D32), fontSize: 9)),
                ],
              ),
            ),
            // Principal
            SizedBox(
              width: _wAmount,
              child: Text(compact(row.principalAmount),
                  textAlign: TextAlign.end,
                  style: theme.textTheme.bodySmall),
            ),
            // Interest
            SizedBox(
              width: _wAmount,
              child: Text(compact(row.interestAmount),
                  textAlign: TextAlign.end,
                  style: theme.textTheme.bodySmall?.copyWith(
                      color: cs.onSurfaceVariant)),
            ),
            // Total EMI
            SizedBox(
              width: _wAmount,
              child: Text(compact(row.totalAmount),
                  textAlign: TextAlign.end,
                  style: theme.textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w700)),
            ),
            // Status
            SizedBox(
              width: _wStatus,
              child: _StatusBadge(status: row.status, cs: cs, theme: theme),
            ),
          ],
        ),
      ),
    );
  }

  void _showDetail(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => _DetailSheet(row: row, fmt: fmt, dateFmt: dateFmt),
    );
  }
}

// ─── Status Badge ─────────────────────────────────────────────────────────────

class _StatusBadge extends StatelessWidget {
  final ScheduleStatus status;
  final ColorScheme cs;
  final ThemeData theme;

  const _StatusBadge({
    required this.status,
    required this.cs,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    late final Color bg, fg;
    late final String label;
    late final IconData icon;

    switch (status) {
      case ScheduleStatus.paid:
        bg = const Color(0xFF2E7D32).withOpacity(0.12);
        fg = const Color(0xFF2E7D32);
        label = 'Paid';
        icon = Icons.check_circle_rounded;
        break;
      case ScheduleStatus.overdue:
        bg = cs.error.withOpacity(0.12);
        fg = cs.error;
        label = 'Overdue';
        icon = Icons.warning_rounded;
        break;
      case ScheduleStatus.partial:
        bg = const Color(0xFFF57F17).withOpacity(0.12);
        fg = const Color(0xFFF57F17);
        label = 'Partial';
        icon = Icons.timelapse_rounded;
        break;
      default:
        bg = cs.surfaceContainerHighest;
        fg = cs.onSurfaceVariant;
        label = 'Pending';
        icon = Icons.schedule_rounded;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 10, color: fg),
          const SizedBox(width: 2),
          Flexible(
            child: Text(label,
                style: theme.textTheme.labelSmall?.copyWith(
                    color: fg, fontWeight: FontWeight.w700, fontSize: 10)),
          ),
        ],
      ),
    );
  }
}

// ─── Detail Sheet ─────────────────────────────────────────────────────────────

class _DetailSheet extends StatelessWidget {
  final RepaymentScheduleModel row;
  final String Function(double?) fmt;
  final DateFormat dateFmt;

  const _DetailSheet({required this.row, required this.fmt, required this.dateFmt});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs    = theme.colorScheme;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        20, 12, 20, MediaQuery.of(context).padding.bottom + 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 36, height: 4,
              decoration: BoxDecoration(
                color: cs.outlineVariant,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Text('Installment #${row.installmentNumber}',
                  style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700)),
              const Spacer(),
              _StatusBadge(status: row.status, cs: cs, theme: theme),
            ],
          ),
          const SizedBox(height: 16),
          _DRow('Due Date', dateFmt.format(row.dueDate), theme, cs),
          if (row.paymentDate != null)
            _DRow('Payment Date', dateFmt.format(row.paymentDate!), theme, cs,
                valueColor: const Color(0xFF2E7D32)),
          const Divider(height: 20),
          _DRow('Principal', fmt(row.principalAmount), theme, cs),
          _DRow('Interest', fmt(row.interestAmount), theme, cs),
          _DRow('Total EMI', fmt(row.totalAmount), theme, cs,
              bold: true, valueColor: cs.primary),
          if ((row.penaltyApplied ?? 0) > 0)
            _DRow('Penalty Applied', fmt(row.penaltyApplied), theme, cs,
                valueColor: cs.error),
          if (row.balanceAfterPayment != null) ...[
            const Divider(height: 20),
            _DRow('Balance After Payment', fmt(row.balanceAfterPayment), theme, cs,
                bold: true),
          ],
        ],
      ),
    );
  }
}

class _DRow extends StatelessWidget {
  final String label;
  final String value;
  final ThemeData theme;
  final ColorScheme cs;
  final bool bold;
  final Color? valueColor;

  const _DRow(this.label, this.value, this.theme, this.cs,
      {this.bold = false, this.valueColor});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: theme.textTheme.bodyMedium?.copyWith(
                  color: cs.onSurfaceVariant)),
          Text(value,
              style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: bold ? FontWeight.w700 : FontWeight.w600,
                  color: valueColor ?? cs.onSurface)),
        ],
      ),
    );
  }
}

// ─── Loading Scaffold ─────────────────────────────────────────────────────────

class _LoadingScaffold extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme  = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: const CustomAppBar(title: 'Repayment Schedule', showNotifications: false),
      body: Shimmer.fromColors(
        baseColor:      isDark ? Colors.grey[800]! : Colors.grey[300]!,
        highlightColor: isDark ? Colors.grey[700]! : Colors.grey[100]!,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              _ShimBox(120, double.infinity),
              const SizedBox(height: 12),
              _ShimBox(40, double.infinity),
              const SizedBox(height: 8),
              ...List.generate(9, (_) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _ShimBox(44, double.infinity),
              )),
            ],
          ),
        ),
      ),
    );
  }
}

class _ShimBox extends StatelessWidget {
  final double h; final double w;
  const _ShimBox(this.h, this.w);
  @override
  Widget build(BuildContext context) {
    return Container(
      width: w, height: h,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
      ),
    );
  }
}

// ─── Error Scaffold ───────────────────────────────────────────────────────────

class _ErrorScaffold extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorScaffold({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs    = theme.colorScheme;

    return Scaffold(
      appBar: const CustomAppBar(title: 'Repayment Schedule', showNotifications: false),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline_rounded, size: 72, color: cs.error),
              const SizedBox(height: 16),
              Text('Could not load schedule',
                  style: theme.textTheme.titleLarge,
                  textAlign: TextAlign.center),
              const SizedBox(height: 8),
              Text(message,
                  style: theme.textTheme.bodyMedium?.copyWith(
                      color: cs.onSurfaceVariant),
                  textAlign: TextAlign.center),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Try Again'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
