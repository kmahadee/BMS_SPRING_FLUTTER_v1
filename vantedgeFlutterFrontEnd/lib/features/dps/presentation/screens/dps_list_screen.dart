import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';

import 'package:vantedge/core/routes/app_routes.dart';
import 'package:vantedge/core/widgets/empty_state.dart';
import 'package:vantedge/features/auth/presentation/providers/auth_provider.dart';
import 'package:vantedge/features/dps/presentation/providers/dps_provider.dart';
import 'package:vantedge/features/dps/presentation/widgets/dps_card.dart';
import 'package:vantedge/shared/widgets/main_scaffold.dart';

class DpsListScreen extends StatefulWidget {
  const DpsListScreen({super.key});

  @override
  State<DpsListScreen> createState() => _DpsListScreenState();
}

class _DpsListScreenState extends State<DpsListScreen> {
  // ── Lifecycle ──────────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authProvider = context.read<AuthProvider>();
      final customerId = authProvider.user?.customerId;
      if (customerId == null) return;

      final dpsProvider = context.read<DpsProvider>();
      if (!dpsProvider.hasDps && !dpsProvider.isLoading) {
        dpsProvider.fetchMyDps(customerId);
      }
    });
  }

  // ── Handlers ───────────────────────────────────────────────────────────────

  Future<void> _handleRefresh() async {
    final customerId = context.read<AuthProvider>().user?.customerId;
    if (customerId != null) {
      await context.read<DpsProvider>().fetchMyDps(customerId);
    }
  }

  void _openDetails(String dpsNumber) {
    Navigator.pushNamed(
      context,
      AppRoutes.dpsDetails,
      arguments: dpsNumber,
    );
  }

  void _openCreate() {
    Navigator.pushNamed(context, '${AppRoutes.dps}/create');
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Consumer<DpsProvider>(
      builder: (context, provider, _) {
        // Loading — show shimmer skeleton
        if (provider.isLoading && !provider.hasDps) {
          return MainScaffold(
            currentRoute: AppRoutes.dps,
            title: 'My DPS Accounts',
            showDrawer: true,
            showBottomNav: true,
            child: const _DpsShimmerList(),
          );
        }

        // Error — show retry panel
        if (provider.hasError && !provider.hasDps) {
          return MainScaffold(
            currentRoute: AppRoutes.dps,
            title: 'My DPS Accounts',
            showDrawer: true,
            showBottomNav: true,
            child: _ErrorBody(
              message: provider.errorMessage!,
              onRetry: () {
                provider.clearMessages();
                _handleRefresh();
              },
            ),
          );
        }

        // Empty — no DPS accounts yet
        if (!provider.hasDps) {
          return MainScaffold(
            currentRoute: AppRoutes.dps,
            title: 'My DPS Accounts',
            showDrawer: true,
            showBottomNav: true,
            appBarActions: [_AddButton(onTap: _openCreate)],
            child: EmptyState.noDPS(onOpenDPS: _openCreate),
          );
        }

        // ── Main content ────────────────────────────────────────────────────
        final dpsList = provider.dpsList;
        final totalDeposited = dpsList.fold<double>(
          0.0,
          (sum, d) => sum + (d.totalDeposited ?? 0),
        );
        final active = dpsList.where((d) => d.status?.toUpperCase() == 'ACTIVE').length;

        return MainScaffold(
          currentRoute: AppRoutes.dps,
          title: 'My DPS Accounts',
          showDrawer: true,
          showBottomNav: true,
          appBarActions: [_AddButton(onTap: _openCreate)],
          child: Column(
            children: [
              // Summary strip
              _SummaryStrip(
                totalDeposited: totalDeposited,
                activeCount: active,
                totalCount: dpsList.length,
              ),

              // DPS list
              Expanded(
                child: RefreshIndicator(
                  onRefresh: _handleRefresh,
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                    itemCount: dpsList.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, i) {
                      final dps = dpsList[i];
                      return DpsCard(
                        dps: dps,
                        onTap: () => _openDetails(dps.dpsNumber ?? ''),
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ── Summary strip ───────────────────────────────────────────────────────────

class _SummaryStrip extends StatelessWidget {
  final double totalDeposited;
  final int activeCount;
  final int totalCount;

  const _SummaryStrip({
    required this.totalDeposited,
    required this.activeCount,
    required this.totalCount,
  });

  static final _fmt = NumberFormat.compactCurrency(
    symbol: '৳',
    decimalDigits: 1,
    locale: 'en_IN',
  );

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Container(
      color: cs.surface,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: Row(
        children: [
          _StripCell(
            label: 'Total Deposited',
            value: _fmt.format(totalDeposited),
            theme: theme,
            cs: cs,
            valueColor: cs.primary,
          ),
          const SizedBox(width: 24),
          _StripCell(
            label: 'Active',
            value: '$activeCount',
            theme: theme,
            cs: cs,
            valueColor: Colors.green.shade600,
          ),
          const SizedBox(width: 24),
          _StripCell(
            label: 'Total',
            value: '$totalCount',
            theme: theme,
            cs: cs,
          ),
        ],
      ),
    );
  }
}

class _StripCell extends StatelessWidget {
  final String label;
  final String value;
  final ThemeData theme;
  final ColorScheme cs;
  final Color? valueColor;

  const _StripCell({
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
          style: theme.textTheme.labelSmall?.copyWith(color: cs.onSurfaceVariant),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w700,
            color: valueColor ?? cs.onSurface,
          ),
        ),
      ],
    );
  }
}

// ── App bar add button ──────────────────────────────────────────────────────

class _AddButton extends StatelessWidget {
  final VoidCallback onTap;

  const _AddButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.add_rounded),
      tooltip: 'Open DPS',
      onPressed: onTap,
    );
  }
}

// ── Error body ──────────────────────────────────────────────────────────────

class _ErrorBody extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorBody({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline_rounded, size: 72, color: cs.error),
            const SizedBox(height: 20),
            Text(
              'Something went wrong',
              style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: theme.textTheme.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
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
    );
  }
}

// ── Shimmer list ────────────────────────────────────────────────────────────

class _DpsShimmerList extends StatelessWidget {
  final int itemCount;

  // const _DpsShimmerList();
  const _DpsShimmerList({this.itemCount = 5});

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: itemCount,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (_, __) => const _DpsShimmerCard(),
    );
  }
}

class _DpsShimmerCard extends StatelessWidget {
  const _DpsShimmerCard();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Shimmer.fromColors(
      baseColor: isDark ? Colors.grey[800]! : Colors.grey[300]!,
      highlightColor: isDark ? Colors.grey[700]! : Colors.grey[100]!,
      child: Card(
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header row
              Row(
                children: [
                  _ShimmerBox(width: 46, height: 46, radius: 12),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _ShimmerBox(width: double.infinity, height: 14),
                        const SizedBox(height: 6),
                        _ShimmerBox(width: 100, height: 12),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  _ShimmerBox(width: 64, height: 24, radius: 20),
                ],
              ),
              const SizedBox(height: 12),
              const Divider(height: 1),
              const SizedBox(height: 12),
              // Amount row
              Row(
                children: [
                  _ShimmerBox(width: 80, height: 32),
                  const SizedBox(width: 20),
                  _ShimmerBox(width: 100, height: 32),
                  const Spacer(),
                  _ShimmerBox(width: 80, height: 32),
                ],
              ),
              const SizedBox(height: 12),
              // Progress bar
              _ShimmerBox(width: double.infinity, height: 6, radius: 4),
            ],
          ),
        ),
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
