import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import 'package:vantedge/core/routes/app_routes.dart';
import 'package:vantedge/features/accounts/data/models/account_list_item_dto.dart';
import 'package:vantedge/features/accounts/presentation/providers/account_provider.dart';
import 'package:vantedge/features/transactions/data/models/account_statement_model.dart';
import 'package:vantedge/features/transactions/data/models/transaction_history_model.dart';
import 'package:vantedge/features/transactions/presentation/providers/transaction_provider.dart';
import 'package:vantedge/features/transactions/presentation/widgets/account_selector.dart';
import 'package:vantedge/features/transactions/presentation/widgets/transaction_card.dart';
import 'package:vantedge/shared/widgets/custom_app_bar.dart';


enum _DatePreset {
  today('Today'),
  last7('Last 7 Days'),
  last30('Last 30 Days'),
  last3Months('Last 3 Months'),
  custom('Custom Range');

  const _DatePreset(this.label);
  final String label;

  DateTimeRange resolve() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    switch (this) {
      case _DatePreset.today:
        return DateTimeRange(start: today, end: now);
      case _DatePreset.last7:
        return DateTimeRange(start: today.subtract(const Duration(days: 6)), end: now);
      case _DatePreset.last30:
        return DateTimeRange(start: today.subtract(const Duration(days: 29)), end: now);
      case _DatePreset.last3Months:
        return DateTimeRange(start: today.subtract(const Duration(days: 89)), end: now);
      case _DatePreset.custom:
        return DateTimeRange(start: today.subtract(const Duration(days: 29)), end: now);
    }
  }
}


class TransactionHistoryScreen extends StatefulWidget {
  final String? accountNumber;

  const TransactionHistoryScreen({super.key, this.accountNumber});

  @override
  State<TransactionHistoryScreen> createState() =>
      _TransactionHistoryScreenState();
}

class _TransactionHistoryScreenState extends State<TransactionHistoryScreen> {
  AccountListItemDTO? _selectedAccount;
  _DatePreset _activePreset = _DatePreset.last30;
  DateTimeRange _dateRange = _DatePreset.last30.resolve();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _init());
  }

  Future<void> _init() async {
    final ap = context.read<AccountProvider>();
    if (ap.accounts.isEmpty) await ap.fetchMyAccounts();

    if (!mounted) return;

    final accounts = context.read<AccountProvider>().accounts;
    if (accounts.isEmpty) return;

    AccountListItemDTO? preselected;
    if (widget.accountNumber != null) {
      preselected = accounts.firstWhere(
        (a) => a.accountNumber == widget.accountNumber,
        orElse: () => accounts.first,
      );
    } else {
      preselected = accounts.first;
    }

    setState(() => _selectedAccount = preselected);
    _loadStatement();
  }

  Future<void> _loadStatement() async {
    final account = _selectedAccount;
    if (account == null) return;
    await context.read<TransactionProvider>().loadStatement(
          account.accountNumber,
          _dateRange.start,
          _dateRange.end,
        );
  }

  void _onAccountSelected(AccountListItemDTO account) {
    setState(() => _selectedAccount = account);
    _loadStatement();
  }

  Future<void> _onPresetSelected(_DatePreset preset) async {
    if (preset == _DatePreset.custom) {
      final now = DateTime.now();
      final picked = await showDateRangePicker(
        context: context,
        firstDate: DateTime(now.year - 5),
        lastDate: now,
        initialDateRange: _dateRange,
        builder: (ctx, child) => Theme(
          data: Theme.of(ctx).copyWith(
            colorScheme: Theme.of(ctx).colorScheme.copyWith(
                  primary: Theme.of(ctx).colorScheme.primary,
                ),
          ),
          child: child!,
        ),
      );
      if (picked == null) return; // user cancelled
      setState(() {
        _activePreset = _DatePreset.custom;
        _dateRange = picked;
      });
    } else {
      setState(() {
        _activePreset = preset;
        _dateRange = preset.resolve();
      });
    }
    _loadStatement();
  }

  void _openDetails(TransactionHistoryModel txn) {
    Navigator.of(context).pushNamed(
      AppRoutes.transactionDetails,
      arguments: txn,
    );
  }

  String _fmtDate(DateTime? dt) {
    if (dt == null) return '—';
    return DateFormat('dd MMM yyyy').format(dt);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surfaceContainerLowest,
      appBar: const CustomAppBar(title: 'Transaction History'),
      body: Column(
        children: [
          _TopControls(
            selectedAccount: _selectedAccount,
            accounts: context.watch<AccountProvider>().accounts,
            onAccountSelected: _onAccountSelected,
            activePreset: _activePreset,
            dateRange: _dateRange,
            onPresetSelected: _onPresetSelected,
          ),

          Expanded(
            child: Consumer<TransactionProvider>(
              builder: (context, provider, _) {
                if (provider.isLoading) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (provider.hasError) {
                  return _ErrorState(
                    message: provider.errorMessage ?? 'Something went wrong.',
                    onRetry: _loadStatement,
                  );
                }

                final statement = provider.currentStatement;

                if (statement == null) {
                  return const _EmptyState(
                    message: 'Select an account to view transactions.',
                  );
                }

                return RefreshIndicator(
                  onRefresh: _loadStatement,
                  child: CustomScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    slivers: [
                      SliverToBoxAdapter(
                        child: _SummarySection(
                          statement: statement,
                          startDate: _fmtDate(statement.statementStartDate),
                          endDate: _fmtDate(statement.statementEndDate),
                        ),
                      ),

                      if (statement.transactions.isEmpty)
                        const SliverFillRemaining(
                          hasScrollBody: false,
                          child: _EmptyState(
                            message: 'No transactions found for this period.',
                          ),
                        )
                      else
                        SliverPadding(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                          sliver: SliverList.builder(
                            itemCount: statement.transactions.length,
                            itemBuilder: (ctx, i) {
                              final txn = statement.transactions[i];
                              return TransactionCard(
                                transaction: txn,
                                onTap: () => _openDetails(txn),
                              );
                            },
                          ),
                        ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}


class _TopControls extends StatelessWidget {
  final AccountListItemDTO? selectedAccount;
  final List<AccountListItemDTO> accounts;
  final void Function(AccountListItemDTO) onAccountSelected;
  final _DatePreset activePreset;
  final DateTimeRange dateRange;
  final void Function(_DatePreset) onPresetSelected;

  const _TopControls({
    required this.selectedAccount,
    required this.accounts,
    required this.onAccountSelected,
    required this.activePreset,
    required this.dateRange,
    required this.onPresetSelected,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      color: colorScheme.surface,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: AccountSelectorWidget(
              accounts: accounts,
              selectedAccount: selectedAccount,
              onSelected: onAccountSelected,
              label: 'Select Account',
              validator: (_) => null, // no validation needed here
            ),
          ),

          const SizedBox(height: 12),

          SizedBox(
            height: 40,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: _DatePreset.values.map((preset) {
                final isActive = preset == activePreset;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(
                      preset == _DatePreset.custom && activePreset == _DatePreset.custom
                          ? _customLabel(dateRange)
                          : preset.label,
                    ),
                    selected: isActive,
                    onSelected: (_) => onPresetSelected(preset),
                    showCheckmark: false,
                    labelStyle: TextStyle(
                      fontSize: 12,
                      fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
                      color: isActive
                          ? colorScheme.onPrimary
                          : colorScheme.onSurfaceVariant,
                    ),
                    backgroundColor: colorScheme.surfaceContainerHighest,
                    selectedColor: colorScheme.primary,
                    side: BorderSide(
                      color: isActive
                          ? colorScheme.primary
                          : colorScheme.outlineVariant,
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                  ),
                );
              }).toList(),
            ),
          ),

          const SizedBox(height: 12),
          Divider(height: 1, color: colorScheme.outlineVariant),
        ],
      ),
    );
  }

  String _customLabel(DateTimeRange range) {
    final fmt = DateFormat('dd MMM');
    return '${fmt.format(range.start)} – ${fmt.format(range.end)}';
  }
}


class _SummarySection extends StatelessWidget {
  final AccountStatementModel statement;
  final String startDate;
  final String endDate;

  const _SummarySection({
    required this.statement,
    required this.startDate,
    required this.endDate,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.calendar_today_outlined,
                  size: 14, color: colorScheme.onSurfaceVariant),
              const SizedBox(width: 6),
              Text(
                '$startDate — $endDate',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              const Spacer(),
              _TxnCountBadge(count: statement.transactionCount),
            ],
          ),

          const SizedBox(height: 12),

          Row(
            children: [
              Expanded(
                child: _SummaryCard(
                  label: 'Opening Balance',
                  amount: statement.openingBalance,
                  icon: Icons.account_balance_wallet_outlined,
                  iconColor: colorScheme.primary,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _SummaryCard(
                  label: 'Closing Balance',
                  amount: statement.closingBalance,
                  icon: Icons.account_balance_outlined,
                  iconColor: colorScheme.primary,
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          Row(
            children: [
              Expanded(
                child: _SummaryCard(
                  label: 'Total Credits',
                  amount: statement.totalCredits,
                  icon: Icons.arrow_upward_rounded,
                  iconColor: const Color(0xFF2E7D32),
                  amountColor: const Color(0xFF2E7D32),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _SummaryCard(
                  label: 'Total Debits',
                  amount: statement.totalDebits,
                  icon: Icons.arrow_downward_rounded,
                  iconColor: const Color(0xFFC62828),
                  amountColor: const Color(0xFFC62828),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          Text(
            'Transactions',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
              color: colorScheme.onSurface,
            ),
          ),

          const SizedBox(height: 4),
        ],
      ),
    );
  }
}


class _SummaryCard extends StatelessWidget {
  final String label;
  final double amount;
  final IconData icon;
  final Color iconColor;
  final Color? amountColor;

  const _SummaryCard({
    required this.label,
    required this.amount,
    required this.icon,
    required this.iconColor,
    this.amountColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final fmtAmount = '৳${NumberFormat('#,##0.00').format(amount)}';

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colorScheme.outlineVariant.withOpacity(0.6)),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.10),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: iconColor, size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  fmtAmount,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: amountColor ?? colorScheme.onSurface,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}


class _TxnCountBadge extends StatelessWidget {
  final int count;

  const _TxnCountBadge({required this.count});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
        color: colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        '$count txn${count == 1 ? '' : 's'}',
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: colorScheme.onPrimaryContainer,
              fontWeight: FontWeight.w600,
            ),
      ),
    );
  }
}


class _EmptyState extends StatelessWidget {
  final String message;

  const _EmptyState({required this.message});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.receipt_long_outlined,
              size: 64,
              color: colorScheme.onSurfaceVariant.withOpacity(0.4),
            ),
            const SizedBox(height: 16),
            Text(
              'No transactions found',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant.withOpacity(0.7),
                  ),
            ),
          ],
        ),
      ),
    );
  }
}


class _ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorState({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline_rounded,
                size: 56, color: colorScheme.error),
            const SizedBox(height: 16),
            Text(
              'Something went wrong',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurface,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}