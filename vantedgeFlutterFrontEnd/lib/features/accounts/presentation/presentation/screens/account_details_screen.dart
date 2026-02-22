import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:vantedge/features/branches/presentation/widgets/account_shimmer_loader.dart';
import 'package:vantedge/features/branches/presentation/widgets/account_status_badge.dart';
import 'package:vantedge/features/branches/presentation/widgets/balance_widget.dart';
import '../../../data/models/account_response_dto.dart';
import '../../providers/account_provider.dart';
import 'account_statement_screen.dart';


class AccountDetailsScreen extends StatefulWidget {
  final String accountNumber;

  const AccountDetailsScreen({
    super.key,
    required this.accountNumber,
  });

  @override
  State<AccountDetailsScreen> createState() => _AccountDetailsScreenState();
}

class _AccountDetailsScreenState extends State<AccountDetailsScreen> {
  @override
  void initState() {
    super.initState();
    // Fetch account details and enable auto-refresh
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<AccountProvider>();
      provider.fetchAccountDetails(widget.accountNumber);
      provider.enableAutoRefresh();
    });
  }

  @override
  void dispose() {
    // Disable auto-refresh when leaving screen
    context.read<AccountProvider>().disableAutoRefresh();
    super.dispose();
  }

  void _copyToClipboard(String text, String label) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$label copied to clipboard'),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _generateStatement(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AccountStatementScreen(
          accountNumber: widget.accountNumber,
        ),
      ),
    );
  }

  void _initiateTransfer(BuildContext context) {
    // TODO: Navigate to transfer screen
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Transfer feature coming soon')),
    );
  }

  void _showFreezeDialog(BuildContext context, AccountResponseDTO account) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Freeze Account'),
        content: Text(
          'Are you sure you want to freeze account ${account.accountNumber}? '
          'You will not be able to perform transactions until it is unfrozen.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              // TODO: Implement freeze account
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Freeze feature coming soon')),
              );
            },
            child: const Text('Freeze'),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'N/A';
    return DateFormat('MMM dd, yyyy').format(date);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      body: Consumer<AccountProvider>(
        builder: (context, provider, child) {
          // Loading state
          if (provider.isLoading && provider.selectedAccount == null) {
            return const CustomScrollView(
              slivers: [
                SliverAppBar(title: Text('Account Details')),
                SliverToBoxAdapter(child: AccountDetailsShimmer()),
              ],
            );
          }

          // Error state
          if (provider.hasError && provider.selectedAccount == null) {
            return CustomScrollView(
              slivers: [
                const SliverAppBar(title: Text('Account Details')),
                SliverFillRemaining(
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.error_outline,
                            size: 80,
                            color: colorScheme.error,
                          ),
                          const SizedBox(height: 24),
                          Text(
                            provider.errorMessage ?? 'Failed to load account',
                            style: theme.textTheme.bodyLarge,
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 24),
                          FilledButton.icon(
                            onPressed: () {
                              provider.clearError();
                              provider.fetchAccountDetails(widget.accountNumber);
                            },
                            icon: const Icon(Icons.refresh),
                            label: const Text('Try Again'),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            );
          }

          final account = provider.selectedAccount;
          final balance = provider.currentBalance;

          if (account == null) {
            return const CustomScrollView(
              slivers: [
                SliverAppBar(title: Text('Account Details')),
                SliverFillRemaining(
                  child: Center(child: Text('Account not found')),
                ),
              ],
            );
          }

          return CustomScrollView(
            slivers: [
              // Hero AppBar
              SliverAppBar(
                expandedHeight: 200,
                pinned: true,
                flexibleSpace: FlexibleSpaceBar(
                  title: Text(
                    account.accountName.isNotEmpty
                        ? account.accountName
                        : account.accountType.displayName,
                  ),
                  background: Hero(
                    tag: 'account_${account.accountNumber}',
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            colorScheme.primaryContainer,
                            colorScheme.primaryContainer.withOpacity(0.7),
                          ],
                        ),
                      ),
                      child: Center(
                        child: Icon(
                          _getAccountIcon(account),
                          size: 80,
                          color: colorScheme.onPrimaryContainer,
                        ),
                      ),
                    ),
                  ),
                ),
                actions: [
                  IconButton(
                    icon: const Icon(Icons.refresh),
                    onPressed: () {
                      provider.refreshBalance(account.accountNumber);
                    },
                    tooltip: 'Refresh Balance',
                  ),
                ],
              ),

              // Content
              SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 16),

                    // Balance Card
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: balance != null
                          ? BalanceWidget(
                              currentBalance: balance.currentBalance,
                              availableBalance: balance.availableBalance,
                              showAvailableBalance: true,
                            )
                          : BalanceWidget(
                              currentBalance: account.currentBalance,
                              availableBalance: account.availableBalance,
                              showAvailableBalance: true,
                            ),
                    ),

                    const SizedBox(height: 24),

                    // Quick Actions
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        children: [
                          Expanded(
                            child: FilledButton.icon(
                              onPressed: () => _generateStatement(context),
                              icon: const Icon(Icons.description),
                              label: const Text('Statement'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: FilledButton.tonalIcon(
                              onPressed: () => _initiateTransfer(context),
                              icon: const Icon(Icons.send),
                              label: const Text('Transfer'),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Account Information Section
                    _SectionHeader(title: 'Account Information'),
                    _InfoCard(
                      children: [
                        _InfoRow(
                          label: 'Account Number',
                          value: account.accountNumber,
                          trailing: IconButton(
                            icon: const Icon(Icons.copy, size: 18),
                            onPressed: () => _copyToClipboard(
                              account.accountNumber,
                              'Account number',
                            ),
                            tooltip: 'Copy',
                          ),
                        ),
                        const Divider(height: 1),
                        _InfoRow(
                          label: 'Account Type',
                          value: account.accountType.displayName,
                        ),
                        const Divider(height: 1),
                        _InfoRow(
                          label: 'Status',
                          valueWidget: AccountStatusBadge(
                            status: account.status,
                            compact: true,
                          ),
                        ),
                        const Divider(height: 1),
                        _InfoRow(
                          label: 'Opened On',
                          value: _formatDate(account.openDate),
                        ),
                        const Divider(height: 1),
                        _InfoRow(
                          label: 'Last Transaction',
                          value: _formatDate(account.lastTransactionDate),
                        ),
                      ],
                    ),

                    // Branch Information Section
                    _SectionHeader(title: 'Branch Information'),
                    _InfoCard(
                      children: [
                        _InfoRow(
                          label: 'Branch Name',
                          value: account.branchName ?? 'N/A',
                        ),
                        const Divider(height: 1),
                        _InfoRow(
                          label: 'Branch Code',
                          value: account.branchCode,
                        ),
                        const Divider(height: 1),
                        _InfoRow(
                          label: 'IFSC Code',
                          value: account.branchCode, // TODO: Use actual IFSC
                          trailing: IconButton(
                            icon: const Icon(Icons.copy, size: 18),
                            onPressed: () => _copyToClipboard(
                              account.branchCode,
                              'IFSC code',
                            ),
                            tooltip: 'Copy',
                          ),
                        ),
                        if (account.branchCity != null) ...[
                          const Divider(height: 1),
                          _InfoRow(
                            label: 'City',
                            value: account.branchCity!,
                          ),
                        ],
                      ],
                    ),

                    // Account Details Section
                    _SectionHeader(title: 'Account Details'),
                    _InfoCard(
                      children: [
                        _InfoRow(
                          label: 'Interest Rate',
                          value: '${account.interestRate.toStringAsFixed(2)}%',
                        ),
                        const Divider(height: 1),
                        _InfoRow(
                          label: 'Minimum Balance',
                          value: NumberFormat.currency(
                            symbol: account.currency ?? 'BDT',
                            decimalDigits: 2,
                          ).format(account.minimumBalance),
                        ),
                        const Divider(height: 1),
                        _InfoRow(
                          label: 'Currency',
                          value: account.currency ?? 'BDT',
                        ),
                      ],
                    ),

                    // Nominee Information (if available)
                    if (account.hasNominee) ...[
                      _SectionHeader(title: 'Nominee Information'),
                      _InfoCard(
                        children: [
                          _InfoRow(
                            label: 'Nominee Name',
                            value: account.fullNomineeName ?? 'N/A',
                          ),
                          if (account.nomineeRelationship != null) ...[
                            const Divider(height: 1),
                            _InfoRow(
                              label: 'Relationship',
                              value: account.nomineeRelationship!,
                            ),
                          ],
                          if (account.nomineePhone != null) ...[
                            const Divider(height: 1),
                            _InfoRow(
                              label: 'Phone',
                              value: account.nomineePhone!,
                            ),
                          ],
                        ],
                      ),
                    ],

                    // Danger Zone
                    if (account.status.canTransact) ...[
                      _SectionHeader(
                        title: 'Account Actions',
                        color: colorScheme.error,
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: OutlinedButton.icon(
                          onPressed: () => _showFreezeDialog(context, account),
                          icon: const Icon(Icons.block),
                          label: const Text('Freeze Account'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: colorScheme.error,
                            side: BorderSide(color: colorScheme.error),
                          ),
                        ),
                      ),
                    ],

                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  IconData _getAccountIcon(AccountResponseDTO account) {
    switch (account.accountType.value) {
      case 'SAVINGS':
        return Icons.savings;
      case 'CURRENT':
        return Icons.account_balance;
      case 'SALARY':
        return Icons.work;
      case 'FD':
        return Icons.trending_up;
      default:
        return Icons.account_balance_wallet;
    }
  }
}

// Section Header Widget
class _SectionHeader extends StatelessWidget {
  final String title;
  final Color? color;

  const _SectionHeader({
    required this.title,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      child: Text(
        title,
        style: theme.textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.bold,
          color: color ?? theme.colorScheme.primary,
        ),
      ),
    );
  }
}

// Info Card Widget
class _InfoCard extends StatelessWidget {
  final List<Widget> children;

  const _InfoCard({required this.children});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Card(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: Theme.of(context).colorScheme.outlineVariant,
          ),
        ),
        child: Column(children: children),
      ),
    );
  }
}

// Info Row Widget
class _InfoRow extends StatelessWidget {
  final String label;
  final String? value;
  final Widget? valueWidget;
  final Widget? trailing;

  const _InfoRow({
    required this.label,
    this.value,
    this.valueWidget,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (valueWidget != null)
                  valueWidget!
                else
                  Flexible(
                    child: Text(
                      value ?? 'N/A',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                      textAlign: TextAlign.end,
                    ),
                  ),
                ?trailing,
              ],
            ),
          ),
        ],
      ),
    );
  }
}
