import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';

import 'package:vantedge/core/routes/app_routes.dart';
import 'package:vantedge/features/dps/data/models/dps_model.dart';
import 'package:vantedge/features/dps/presentation/providers/dps_provider.dart';
import 'package:vantedge/features/dps/presentation/widgets/maturity_progress.dart';
import 'package:vantedge/features/dps/utils/dps_statement_pdf.dart';
import 'package:vantedge/shared/widgets/custom_app_bar.dart';

class DpsDetailsScreen extends StatefulWidget {
  final String dpsNumber;

  const DpsDetailsScreen({super.key, required this.dpsNumber});

  @override
  State<DpsDetailsScreen> createState() => _DpsDetailsScreenState();
}

class _DpsDetailsScreenState extends State<DpsDetailsScreen> {
  static final _dateFmt = DateFormat('dd MMM yyyy');
  static final _dtFmt   = DateFormat('dd MMM yyyy, hh:mm a');

  String _fmt(double? v, String symbol) {
    if (v == null) return '—';
    return NumberFormat.currency(
      symbol: '$symbol ',
      decimalDigits: 2,
      locale: 'en_IN',
    ).format(v);
  }

  String _date(DateTime? d) => d != null ? _dateFmt.format(d) : '—';
  String _dt(DateTime? d)   => d != null ? _dtFmt.format(d) : '—';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DpsProvider>().fetchDpsByNumber(widget.dpsNumber);
    });
  }

  String _currencySymbol(String? currency) {
    switch ((currency ?? 'BDT').toUpperCase()) {
      case 'USD': return '\$';
      case 'EUR': return '€';
      case 'GBP': return '£';
      case 'BDT':
      default:    return '৳';
    }
  }

  void _copy(String text, String label) {
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

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError
            ? Theme.of(context).colorScheme.error
            : Colors.green.shade600,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  void _navPayInstallment() {
    Navigator.pushNamed(
      context,
      '${AppRoutes.dps}/pay',
      arguments: widget.dpsNumber,
    );
  }

  void _navInstallmentHistory() {
    Navigator.pushNamed(
      context,
      '${AppRoutes.dps}/installments',
      arguments: widget.dpsNumber,
    );
  }

  Future<void> _printStatement(DpsProvider provider) async {
    // Show loading indicator
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Row(
          children: [
            SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
            ),
            SizedBox(width: 12),
            Text('Generating statement…'),
          ],
        ),
        duration: Duration(seconds: 10),
        behavior: SnackBarBehavior.floating,
      ),
    );

    try {
      // Fetch statement if not already loaded
      if (provider.statement == null) {
        await provider.fetchStatement(widget.dpsNumber);
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).hideCurrentSnackBar();

      final statement = provider.statement;
      if (statement == null) {
        _showSnackBar('Could not load statement data.', isError: true);
        return;
      }

      await DpsStatementPdf.generate(statement, share: true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      _showSnackBar('Failed to generate PDF. Please try again.', isError: true);
    }
  }

  Future<void> _showCloseDialog() async {
    final reasonController = TextEditingController();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.orange),
            SizedBox(width: 8),
            Text('Close DPS Account'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Are you sure you want to close DPS account '
              '${widget.dpsNumber}? This action cannot be undone.',
              style: Theme.of(ctx).textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: reasonController,
              maxLines: 2,
              decoration: InputDecoration(
                labelText: 'Reason (optional)',
                hintText: 'Enter closure reason…',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(ctx).colorScheme.error,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Close DPS'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    final reason = reasonController.text.trim().isEmpty
        ? null
        : reasonController.text.trim();

    final provider = context.read<DpsProvider>();
    final success = await provider.closeDps(widget.dpsNumber, reason: reason);

    if (!mounted) return;

    if (success) {
      _showSnackBar('DPS account closed successfully.');
    } else if (provider.errorMessage != null) {
      _showSnackBar(provider.errorMessage!, isError: true);
    }
    provider.clearMessages();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<DpsProvider>(
      builder: (context, provider, _) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          if (provider.successMessage != null) {
            _showSnackBar(provider.successMessage!);
            provider.clearMessages();
          } else if (provider.hasError && provider.selectedDps != null) {
            _showSnackBar(provider.errorMessage!, isError: true);
            provider.clearMessages();
          }
        });

        if (provider.isLoading && provider.selectedDps == null) {
          return _LoadingScaffold(dpsNumber: widget.dpsNumber);
        }

        if (provider.hasError && provider.selectedDps == null) {
          return _ErrorScaffold(
            message: provider.errorMessage ?? 'Could not load DPS details.',
            onRetry: () {
              provider.clearMessages();
              provider.fetchDpsByNumber(widget.dpsNumber);
            },
          );
        }

        final dps = provider.selectedDps;

        if (dps == null) {
          return _ErrorScaffold(
            message: 'DPS account not found.',
            onRetry: () => provider.fetchDpsByNumber(widget.dpsNumber),
          );
        }

        return _buildContent(context, dps, provider);
      },
    );
  }

  Widget _buildContent(
    BuildContext context,
    DpsModel dps,
    DpsProvider provider,
  ) {
    final theme      = Theme.of(context);
    final cs         = theme.colorScheme;
    final symbol     = _currencySymbol(dps.currency);
    final isActive   = dps.status?.toUpperCase() == 'ACTIVE';
    final hasNominee = (dps.nomineeFirstName != null || dps.nomineeLastName != null);
    final hasPenalty = (dps.penaltyAmount ?? 0) > 0;
    final hasMissed  = (dps.missedInstallments ?? 0) > 0;

    return Scaffold(
      backgroundColor: cs.surfaceContainerLowest,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 180,
            pinned: true,
            backgroundColor: cs.primary,
            foregroundColor: Colors.white,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_rounded),
              onPressed: () => Navigator.of(context).pop(),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.picture_as_pdf_rounded),
                tooltip: 'Download Statement',
                onPressed: provider.isLoading
                    ? null
                    : () => _printStatement(provider),
              ),
              IconButton(
                icon: const Icon(Icons.refresh_rounded),
                tooltip: 'Refresh',
                onPressed: () => provider.fetchDpsByNumber(widget.dpsNumber),
              ),
            ],
            title: Text(
              dps.dpsNumber ?? widget.dpsNumber,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w700,
                fontFamily: 'monospace',
                letterSpacing: 0.5,
              ),
            ),
            flexibleSpace: FlexibleSpaceBar(
              collapseMode: CollapseMode.parallax,
              background: _HeroBackground(dps: dps, symbol: symbol),
            ),
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  MaturityProgress(dps: dps),
                  const SizedBox(height: 20),

                  _SectionLabel(label: 'Account Information'),
                  const SizedBox(height: 10),
                  _InfoCard(children: [
                    _InfoRow(
                      icon: Icons.tag_rounded,
                      label: 'DPS Number',
                      value: dps.dpsNumber ?? '—',
                      trailing: dps.dpsNumber != null
                          ? IconButton(
                              icon: const Icon(Icons.copy_rounded, size: 15),
                              tooltip: 'Copy',
                              onPressed: () => _copy(dps.dpsNumber!, 'DPS number'),
                            )
                          : null,
                    ),
                    _divider(),
                    _InfoRow(
                      icon: Icons.business_outlined,
                      label: 'Branch',
                      value: dps.branchName ?? '—',
                    ),
                    _divider(),
                    _InfoRow(
                      icon: Icons.verified_outlined,
                      label: 'Status',
                      value: _statusLabel(dps.status),
                      valueColor: _statusColor(dps.status, cs),
                    ),
                    _divider(),
                    _InfoRow(
                      icon: Icons.calendar_today_outlined,
                      label: 'Start Date',
                      value: _date(dps.startDate),
                    ),
                    _divider(),
                    _InfoRow(
                      icon: Icons.event_available_outlined,
                      label: 'Maturity Date',
                      value: _date(dps.maturityDate),
                    ),
                    _divider(),
                    _InfoRow(
                      icon: Icons.currency_exchange_rounded,
                      label: 'Currency',
                      value: dps.currency ?? 'BDT',
                    ),
                    _divider(),
                    _InfoRow(
                      icon: Icons.schedule_rounded,
                      label: 'Created On',
                      value: _dt(dps.createdDate),
                    ),
                  ]),
                  const SizedBox(height: 20),

                  _SectionLabel(label: 'Financial Details'),
                  const SizedBox(height: 10),
                  _InfoCard(children: [
                    _InfoRow(
                      icon: Icons.calendar_month_rounded,
                      label: 'Monthly Installment',
                      value: _fmt(dps.monthlyInstallment, symbol),
                      valueColor: cs.primary,
                    ),
                    _divider(),
                    _InfoRow(
                      icon: Icons.percent_rounded,
                      label: 'Interest Rate',
                      value: dps.interestRate != null
                          ? '${dps.interestRate!.toStringAsFixed(2)}% p.a.'
                          : '—',
                    ),
                    _divider(),
                    _InfoRow(
                      icon: Icons.account_balance_rounded,
                      label: 'Maturity Amount',
                      value: _fmt(dps.maturityAmount, symbol),
                      valueColor: Colors.green.shade700,
                    ),
                    _divider(),
                    _InfoRow(
                      icon: Icons.savings_outlined,
                      label: 'Total Deposited',
                      value: _fmt(dps.totalDeposited, symbol),
                    ),
                    if (hasPenalty) ...[
                      _divider(),
                      _InfoRow(
                        icon: Icons.warning_amber_rounded,
                        label: 'Penalty Amount',
                        value: _fmt(dps.penaltyAmount, symbol),
                        valueColor: cs.error,
                      ),
                    ],
                    if (hasMissed) ...[
                      _divider(),
                      _InfoRow(
                        icon: Icons.event_busy_outlined,
                        label: 'Missed Installments',
                        value: '${dps.missedInstallments}',
                        valueColor: cs.error,
                      ),
                    ],
                  ]),
                  const SizedBox(height: 20),

                  _SectionLabel(label: 'Payment Info'),
                  const SizedBox(height: 10),
                  _InfoCard(children: [
                    _InfoRow(
                      icon: Icons.autorenew_rounded,
                      label: 'Auto Debit',
                      value: (dps.autoDebitEnabled ?? false) ? 'Enabled' : 'Disabled',
                      valueColor: (dps.autoDebitEnabled ?? false)
                          ? Colors.green.shade600
                          : cs.onSurfaceVariant,
                    ),
                    _divider(),
                    _InfoRow(
                      icon: Icons.upcoming_rounded,
                      label: 'Next Payment',
                      value: _date(dps.nextPaymentDate),
                    ),
                    if (dps.linkedAccountNumber != null) ...[
                      _divider(),
                      _InfoRow(
                        icon: Icons.account_balance_wallet_outlined,
                        label: 'Linked Account',
                        value: '•••• ${_lastFour(dps.linkedAccountNumber!)}',
                        trailing: IconButton(
                          icon: const Icon(Icons.copy_rounded, size: 15),
                          tooltip: 'Copy',
                          onPressed: () =>
                              _copy(dps.linkedAccountNumber!, 'Account number'),
                        ),
                      ),
                    ],
                  ]),
                  const SizedBox(height: 20),

                  if (hasNominee) ...[
                    _SectionLabel(label: 'Nominee Details'),
                    const SizedBox(height: 10),
                    _InfoCard(children: [
                      _InfoRow(
                        icon: Icons.person_outline_rounded,
                        label: 'Nominee Name',
                        value: [
                          dps.nomineeFirstName ?? '',
                          dps.nomineeLastName ?? '',
                        ].where((s) => s.isNotEmpty).join(' '),
                      ),
                    ]),
                    const SizedBox(height: 20),
                  ],

                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),
        ],
      ),

      bottomNavigationBar: _ActionBar(
        isActive: isActive,
        isLoading: provider.isLoading,
        onPayInstallment: _navPayInstallment,
        onViewHistory: _navInstallmentHistory,
        onCloseDps: _showCloseDialog,
        onPrintStatement: () => _printStatement(provider),
      ),
    );
  }

  String _lastFour(String account) =>
      account.length > 4 ? account.substring(account.length - 4) : account;

  String _statusLabel(String? status) {
    if (status == null) return 'Unknown';
    return status[0].toUpperCase() + status.substring(1).toLowerCase();
  }

  Color _statusColor(String? status, ColorScheme cs) {
    switch (status?.toUpperCase()) {
      case 'ACTIVE':    return Colors.green.shade600;
      case 'MATURED':   return cs.primary;
      case 'CLOSED':    return cs.onSurfaceVariant;
      case 'DEFAULTED': return cs.error;
      case 'SUSPENDED': return Colors.orange.shade700;
      default:          return cs.onSurfaceVariant;
    }
  }

  Divider _divider() => const Divider(height: 1, indent: 16, endIndent: 16);
}

class _HeroBackground extends StatelessWidget {
  final DpsModel dps;
  final String symbol;

  const _HeroBackground({required this.dps, required this.symbol});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    final currFmt = NumberFormat.currency(
      symbol: '$symbol ',
      decimalDigits: 2,
      locale: 'en_IN',
    );
    final maturityStr = dps.maturityAmount != null
        ? currFmt.format(dps.maturityAmount)
        : '—';

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [cs.primary, cs.primary.withOpacity(0.75)],
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 56, 20, 16),
          child: Row(
            children: [
              Container(
                width: 58,
                height: 58,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  Icons.savings_rounded,
                  color: Colors.white,
                  size: 30,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Maturity Amount',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.8),
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      maturityStr,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${dps.tenureMonths ?? '—'} months · '
                      '${dps.totalInstallmentsPaid ?? 0} paid',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.8),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Text(
      label,
      style: theme.textTheme.titleMedium?.copyWith(
        fontWeight: FontWeight.w700,
        color: theme.colorScheme.primary,
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final List<Widget> children;
  const _InfoCard({required this.children});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(
          color: Theme.of(context).colorScheme.outlineVariant.withOpacity(0.6),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: children,
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;
  final Widget? trailing;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs    = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
      child: Row(
        children: [
          Icon(icon, size: 16, color: cs.onSurfaceVariant),
          const SizedBox(width: 10),
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: valueColor ?? cs.onSurface,
              ),
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

class _ActionBar extends StatelessWidget {
  final bool isActive;
  final bool isLoading;
  final VoidCallback onPayInstallment;
  final VoidCallback onViewHistory;
  final VoidCallback onCloseDps;
  final VoidCallback onPrintStatement;

  const _ActionBar({
    required this.isActive,
    required this.isLoading,
    required this.onPayInstallment,
    required this.onViewHistory,
    required this.onCloseDps,
    required this.onPrintStatement,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs    = theme.colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: cs.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      padding: EdgeInsets.fromLTRB(
        16, 12, 16,
        MediaQuery.of(context).padding.bottom + 12,
      ),
      child: isActive
          ? _ActiveActions(
              isLoading: isLoading,
              onPay: onPayInstallment,
              onHistory: onViewHistory,
              onClose: onCloseDps,
              onPrint: onPrintStatement,
              theme: theme,
              cs: cs,
            )
          : _InactiveActions(
              isLoading: isLoading,
              onHistory: onViewHistory,
              onPrint: onPrintStatement,
              theme: theme,
              cs: cs,
            ),
    );
  }
}

class _ActiveActions extends StatelessWidget {
  final bool isLoading;
  final VoidCallback onPay;
  final VoidCallback onHistory;
  final VoidCallback onClose;
  final VoidCallback onPrint;
  final ThemeData theme;
  final ColorScheme cs;

  const _ActiveActions({
    required this.isLoading,
    required this.onPay,
    required this.onHistory,
    required this.onClose,
    required this.onPrint,
    required this.theme,
    required this.cs,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Row 1: History + Pay
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: isLoading ? null : onHistory,
                icon: const Icon(Icons.history_rounded),
                label: const Text('View History'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 2,
              child: FilledButton.icon(
                onPressed: isLoading ? null : onPay,
                icon: const Icon(Icons.payment_rounded),
                label: const Text('Pay Installment'),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),

        // Row 2: Download Statement + Close DPS
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: isLoading ? null : onPrint,
                icon: const Icon(Icons.picture_as_pdf_rounded),
                label: const Text('Statement'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: isLoading ? null : onClose,
                icon: Icon(Icons.close_rounded, color: cs.error),
                label: Text('Close DPS', style: TextStyle(color: cs.error)),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  side: BorderSide(color: cs.error.withOpacity(0.5)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _InactiveActions extends StatelessWidget {
  final bool isLoading;
  final VoidCallback onHistory;
  final VoidCallback onPrint;
  final ThemeData theme;
  final ColorScheme cs;

  const _InactiveActions({
    required this.isLoading,
    required this.onHistory,
    required this.onPrint,
    required this.theme,
    required this.cs,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: isLoading ? null : onHistory,
            icon: const Icon(Icons.history_rounded),
            label: const Text('View History'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: isLoading ? null : onPrint,
            icon: const Icon(Icons.picture_as_pdf_rounded),
            label: const Text('Statement'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _LoadingScaffold extends StatelessWidget {
  final String dpsNumber;
  const _LoadingScaffold({required this.dpsNumber});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            expandedHeight: 180,
            title: Text(dpsNumber),
          ),
          SliverToBoxAdapter(
            child: Shimmer.fromColors(
              baseColor:      isDark ? Colors.grey[800]! : Colors.grey[300]!,
              highlightColor: isDark ? Colors.grey[700]! : Colors.grey[100]!,
              child: const _DetailsShimmer(),
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailsShimmer extends StatelessWidget {
  const _DetailsShimmer();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _ShimmerBox(width: double.infinity, height: 200, radius: 20),
          const SizedBox(height: 20),
          _ShimmerBox(width: 140, height: 18),
          const SizedBox(height: 10),
          _ShimmerBox(width: double.infinity, height: 200, radius: 14),
          const SizedBox(height: 20),
          _ShimmerBox(width: 120, height: 18),
          const SizedBox(height: 10),
          _ShimmerBox(width: double.infinity, height: 160, radius: 14),
        ],
      ),
    );
  }
}

class _ShimmerBox extends StatelessWidget {
  final double width;
  final double height;
  final double radius;

  const _ShimmerBox({
    required this.width,
    required this.height,
    this.radius = 4,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }
}

class _ErrorScaffold extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorScaffold({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs    = theme.colorScheme;

    return Scaffold(
      appBar: CustomAppBar(title: 'DPS Details', showNotifications: false),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline_rounded, size: 72, color: cs.error),
              const SizedBox(height: 20),
              Text(
                'Could not load DPS details',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                message,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: cs.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}