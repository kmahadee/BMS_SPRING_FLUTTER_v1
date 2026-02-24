import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import 'package:vantedge/core/routes/app_routes.dart';
import 'package:vantedge/features/accounts/presentation/providers/account_provider.dart';
import 'package:vantedge/features/auth/presentation/providers/auth_provider.dart';
import 'package:vantedge/features/transactions/data/models/account_balance_model.dart';
import 'package:vantedge/features/transactions/presentation/providers/transaction_provider.dart';
import 'package:vantedge/shared/widgets/custom_app_bar.dart';

class TransactionHomeScreen extends StatefulWidget {
  const TransactionHomeScreen({super.key});

  @override
  State<TransactionHomeScreen> createState() => _TransactionHomeScreenState();
}

class _TransactionHomeScreenState extends State<TransactionHomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _init());
  }

  // Future<void> _init() async {
  //   final ap = context.read<AccountProvider>();

  //   if (ap.accounts.isEmpty) {
  //     await ap.fetchMyAccounts();
  //   }

  //   if (!mounted) return;

  //   final accounts = context.read<AccountProvider>().accounts;
  //   if (accounts.isEmpty) return;

  //   final primaryNumber = accounts.first.accountNumber;
  //   await context.read<TransactionProvider>().loadBalance(primaryNumber);
  // }

  Future<void> _init() async {
    final ap = context.read<AccountProvider>();

    if (ap.accounts.isEmpty) {
      final customerId = context.read<AuthProvider>().user?.customerId;
      if (customerId != null) {
        await ap.fetchMyAccounts(customerId);
      }
    }

    if (!mounted) return;

    final accounts = context.read<AccountProvider>().accounts;
    if (accounts.isEmpty) return;

    final primaryNumber = accounts.first.accountNumber;
    await context.read<TransactionProvider>().loadBalance(primaryNumber);
  }

  void _go(String route, {Object? arguments}) =>
      Navigator.of(context).pushNamed(route, arguments: arguments);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Scaffold(
      backgroundColor: cs.surfaceContainerLowest,
      appBar: const CustomAppBar(
        title: 'Transactions',
        showNotifications: false,
      ),
      body: RefreshIndicator(
        onRefresh: _init,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _BalanceCard(onViewAccounts: () => _go(AppRoutes.accounts)),

              const SizedBox(height: 24),

              Text(
                'Quick Actions',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: cs.onSurface,
                ),
              ),
              const SizedBox(height: 12),

              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1.19,
                children: [
                  _ActionCard(
                    icon: Icons.swap_horiz_rounded,
                    label: 'Transfer',
                    description: 'Send money to any account',
                    gradient: const [Color(0xFF1A237E), Color(0xFF283593)],
                    onTap: () => _go(AppRoutes.transfer),
                  ),
                  _ActionCard(
                    icon: Icons.add_circle_outline_rounded,
                    label: 'Deposit',
                    description: 'Add funds to your account',
                    gradient: const [Color(0xFF00695C), Color(0xFF00897B)],
                    onTap: () => _go(AppRoutes.deposit),
                  ),
                  _ActionCard(
                    icon: Icons.remove_circle_outline_rounded,
                    label: 'Withdraw',
                    description: 'Withdraw from your account',
                    gradient: const [Color(0xFF6A1B9A), Color(0xFF8E24AA)],
                    onTap: () => _go(AppRoutes.withdrawal),
                  ),
                  _ActionCard(
                    icon: Icons.history_rounded,
                    label: 'History',
                    description: 'View all transactions',
                    gradient: const [Color(0xFFBF360C), Color(0xFFE64A19)],
                    onTap: () => _go('${AppRoutes.transactions}/history'),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              _RecentSection(
                onViewAll: () => _go('${AppRoutes.transactions}/history'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BalanceCard extends StatefulWidget {
  final VoidCallback onViewAccounts;

  const _BalanceCard({required this.onViewAccounts});

  @override
  State<_BalanceCard> createState() => _BalanceCardState();
}

class _BalanceCardState extends State<_BalanceCard> {
  bool _balanceVisible = true;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Consumer<TransactionProvider>(
      builder: (context, txnProvider, _) {
        final balance = txnProvider.currentBalance;
        final isLoading = txnProvider.isLoading && balance == null;

        return Container(
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF1A237E), Color(0xFF3949AB)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF1A237E).withOpacity(0.35),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Primary Account Balance',
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: Colors.white70,
                          letterSpacing: 0.3,
                        ),
                      ),
                      if (balance != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          balance.accountType,
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: Colors.white38,
                          ),
                        ),
                      ],
                    ],
                  ),
                  Row(
                    children: [
                      GestureDetector(
                        onTap: () =>
                            setState(() => _balanceVisible = !_balanceVisible),
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.12),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            _balanceVisible
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                            color: Colors.white70,
                            size: 18,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.12),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.account_balance_wallet_outlined,
                          color: Colors.white70,
                          size: 18,
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 16),

              if (isLoading)
                const SizedBox(
                  height: 36,
                  width: 36,
                  child: CircularProgressIndicator(
                    color: Colors.white54,
                    strokeWidth: 2.5,
                  ),
                )
              else
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 250),
                  child: _balanceVisible
                      ? Text(
                          key: const ValueKey('visible'),
                          _formatBalance(balance),
                          style: theme.textTheme.headlineMedium?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.5,
                          ),
                        )
                      : Text(
                          key: const ValueKey('hidden'),
                          '•••• ••••',
                          style: theme.textTheme.headlineMedium?.copyWith(
                            color: Colors.white54,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 4,
                          ),
                        ),
                ),

              const SizedBox(height: 16),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (balance != null) ...[
                    Text(
                      _maskAccountNumber(balance.accountNumber),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.white60,
                        letterSpacing: 1.5,
                      ),
                    ),
                    _StatusPill(status: balance.status),
                  ] else
                    const SizedBox.shrink(),

                  GestureDetector(
                    onTap: widget.onViewAccounts,
                    child: Row(
                      children: [
                        Text(
                          'My Accounts',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: Colors.white70,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Icon(
                          Icons.arrow_forward_rounded,
                          size: 14,
                          color: Colors.white70,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  String _formatBalance(AccountBalanceModel? balance) {
    if (balance == null) return '৳0.00';
    final symbol = balance.currency ?? '৳';
    return '$symbol${NumberFormat('#,##0.00').format(balance.balance)}';
  }

  String _maskAccountNumber(String acct) {
    if (acct.length <= 4) return acct;
    return '•••• •••• ${acct.substring(acct.length - 4)}';
  }
}

class _StatusPill extends StatelessWidget {
  final String status;

  const _StatusPill({required this.status});

  @override
  Widget build(BuildContext context) {
    final isActive = status.toUpperCase() == 'ACTIVE';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: isActive
            ? Colors.green.withOpacity(0.25)
            : Colors.orange.withOpacity(0.25),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isActive
              ? Colors.green.withOpacity(0.5)
              : Colors.orange.withOpacity(0.5),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isActive ? Colors.greenAccent : Colors.orange,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            status,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: isActive ? Colors.greenAccent : Colors.orange,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String description;
  final List<Color> gradient;
  final VoidCallback onTap;

  const _ActionCard({
    required this.icon,
    required this.label,
    required this.description,
    required this.gradient,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Ink(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: gradient,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: gradient.first.withOpacity(0.30),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.18),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: Colors.white, size: 20),
              ),

              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    description,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: Colors.white70,
                      height: 1.3,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RecentSection extends StatelessWidget {
  final VoidCallback onViewAll;

  const _RecentSection({required this.onViewAll});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Transaction History',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: cs.onSurface,
              ),
            ),
            TextButton(
              onPressed: onViewAll,
              style: TextButton.styleFrom(
                padding: EdgeInsets.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Row(
                children: [
                  Text(
                    'View All',
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: cs.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 2),
                  Icon(
                    Icons.arrow_forward_rounded,
                    size: 14,
                    color: cs.primary,
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),

        InkWell(
          onTap: onViewAll,
          borderRadius: BorderRadius.circular(14),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 20),
            decoration: BoxDecoration(
              color: cs.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: cs.outlineVariant.withOpacity(0.5)),
            ),
            child: Column(
              children: [
                Icon(
                  Icons.receipt_long_outlined,
                  size: 40,
                  color: cs.primary.withOpacity(0.4),
                ),
                const SizedBox(height: 10),
                Text(
                  'View your complete transaction history',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: cs.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                FilledButton.tonalIcon(
                  onPressed: onViewAll,
                  icon: const Icon(Icons.history_rounded, size: 16),
                  label: const Text('Open History'),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 10,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
