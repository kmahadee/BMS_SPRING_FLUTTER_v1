// lib/features/branches/presentation/screens/branch_details_screen.dart
//
// PLACEMENT: lib/features/branches/presentation/screens/branch_details_screen.dart
// (Replaces the existing file at this exact path)
//
// CHANGES vs. original:
//  ✅ SWIFT code display (from OpenAPI: swiftCode field)
//  ✅ Working hours section (was fully commented-out; now rendered)
//  ✅ Manager info — name, phone, email (managerName, managerPhone, managerEmail
//       are all returned by the backend BranchResponseDTO per the OpenAPI spec)
//  ✅ Status badge in the hero card (ACTIVE / INACTIVE / CLOSED etc.)
//  ✅ Staff count (totalEmployees) and DPS count (totalDPS) added to statistics
//  ✅ BranchResponseDTO model fields used: swiftCode, managerPhone, managerEmail
//       NOTE: Because the current BranchResponseDTO model does NOT yet include
//       swiftCode, managerPhone, managerEmail, isMainBranch, totalDPS, or
//       totalEmployees, this file also provides an updated fromJson fragment as
//       inline comments showing what to add to the model.  The screen guards all
//       new fields with null-checks so it compiles against the existing model
//       while immediately benefiting once the model is updated.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:vantedge/features/branches/presentation/providers/branch_provider.dart';

// ─────────────────────────────────────────────────────────────────────────────
// MODEL UPDATE REQUIRED (branch_response_dto.dart)
// Add these fields to BranchResponseDTO to unlock all new sections:
//
//   final String? swiftCode;
//   final String? managerPhone;
//   final String? managerEmail;
//   final bool? isMainBranch;
//   final int? totalEmployees;
//   final int? totalDPS;
//
// And add to fromJson:
//   swiftCode: json['swiftCode'] as String?,
//   managerPhone: json['managerPhone'] as String?,
//   managerEmail: json['managerEmail'] as String?,
//   isMainBranch: json['isMainBranch'] as bool?,
//   totalEmployees: json['totalEmployees'] as int?,
//   totalDPS: json['totalDPS'] as int?,
// ─────────────────────────────────────────────────────────────────────────────

class BranchDetailsScreen extends StatefulWidget {
  final int branchId;

  const BranchDetailsScreen({super.key, required this.branchId});

  @override
  State<BranchDetailsScreen> createState() => _BranchDetailsScreenState();
}

class _BranchDetailsScreenState extends State<BranchDetailsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<BranchProvider>().fetchBranchDetails(widget.branchId);
    });
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  void _copy(String text, String label) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$label copied to clipboard'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open link')),
        );
      }
    }
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Branch Details')),
      body: Consumer<BranchProvider>(
        builder: (context, provider, _) {
          // Loading state
          if (provider.isLoading && provider.selectedBranch == null) {
            return const Center(child: CircularProgressIndicator());
          }

          final branch = provider.selectedBranch;
          if (branch == null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.search_off,
                      size: 64, color: colorScheme.onSurfaceVariant),
                  const SizedBox(height: 12),
                  const Text('Branch not found'),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () => context
                        .read<BranchProvider>()
                        .fetchBranchDetails(widget.branchId),
                    icon: const Icon(Icons.refresh),
                    label: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          // ── Helper to safely read extension fields ───────────────────────
          // These helpers use reflection-free dynamic access so the screen
          // compiles even before the model is updated.
          final dynamic branchDynamic = branch;

          String? swiftCode;
          String? managerPhone;
          String? managerEmail;
          bool? isMainBranch;
          int? totalEmployees;
          int? totalDPS;

          try { swiftCode = branchDynamic.swiftCode as String?; } catch (_) {}
          try { managerPhone = branchDynamic.managerPhone as String?; } catch (_) {}
          try { managerEmail = branchDynamic.managerEmail as String?; } catch (_) {}
          try { isMainBranch = branchDynamic.isMainBranch as bool?; } catch (_) {}
          try { totalEmployees = branchDynamic.totalEmployees as int?; } catch (_) {}
          try { totalDPS = branchDynamic.totalDPS as int?; } catch (_) {}

          final dateFormatter = DateFormat('dd MMM yyyy');

          return RefreshIndicator(
            onRefresh: () =>
                context.read<BranchProvider>().fetchBranchDetails(widget.branchId),
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Hero card ──────────────────────────────────────────────
                  _SectionCard(
                    child: Column(
                      children: [
                        // Icon + optional main-branch badge
                        Stack(
                          alignment: Alignment.topRight,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: colorScheme.primaryContainer,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.account_balance,
                                size: 48,
                                color: colorScheme.onPrimaryContainer,
                              ),
                            ),
                            if (isMainBranch == true)
                              Positioned(
                                bottom: 0,
                                right: 0,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: colorScheme.primary,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Text(
                                    'HQ',
                                    style: theme.textTheme.labelSmall?.copyWith(
                                      color: colorScheme.onPrimary,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          branch.branchName,
                          style: theme.textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          branch.branchCode,
                          style: theme.textTheme.bodyLarge?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 12),
                        // Status badge
                        if (branch.status != null)
                          _StatusBadge(status: branch.status!),
                        // Established date
                        if (branch.establishedDate != null) ...[
                          const SizedBox(height: 8),
                          Text(
                            'Est. ${dateFormatter.format(branch.establishedDate!)}',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // ── Contact information ────────────────────────────────────
                  _SectionHeader(title: 'Contact Information'),
                  const SizedBox(height: 8),
                  _SectionCard(
                    child: Column(
                      children: [
                        // Phone
                        _DetailTile(
                          icon: Icons.phone,
                          title: 'Phone',
                          subtitle: branch.phone,
                          trailingIcon: Icons.call,
                          onTrailingTap: () =>
                              _launchUrl('tel:${branch.phone}'),
                        ),
                        _Divider(),

                        // Email
                        _DetailTile(
                          icon: Icons.email,
                          title: 'Email',
                          subtitle: branch.email,
                          trailingIcon: Icons.send,
                          onTrailingTap: () =>
                              _launchUrl('mailto:${branch.email}'),
                        ),
                        _Divider(),

                        // IFSC code
                        _DetailTile(
                          icon: Icons.qr_code,
                          title: 'IFSC Code',
                          subtitle: branch.ifscCode,
                          trailingIcon: Icons.copy,
                          onTrailingTap: () =>
                              _copy(branch.ifscCode, 'IFSC Code'),
                        ),

                        // SWIFT code (only if present in model + returned by API)
                        if (swiftCode != null && swiftCode.isNotEmpty) ...[
                          _Divider(),
                          _DetailTile(
                            icon: Icons.language,
                            title: 'SWIFT Code',
                            subtitle: swiftCode,
                            trailingIcon: Icons.copy,
                            onTrailingTap: () =>
                                _copy(swiftCode!, 'SWIFT Code'),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // ── Address ────────────────────────────────────────────────
                  _SectionHeader(title: 'Address'),
                  const SizedBox(height: 8),
                  _SectionCard(
                    child: _DetailTile(
                      icon: Icons.location_on,
                      title: branch.fullAddress,
                      subtitle: '${branch.city}, ${branch.state} ${branch.zipCode}',
                      trailingIcon:
                          branch.hasLocation ? Icons.directions : null,
                      onTrailingTap: branch.hasLocation
                          ? () => _launchUrl(branch.googleMapsUrl!)
                          : null,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // ── Working hours ──────────────────────────────────────────
                  if (branch.workingHours != null &&
                      branch.workingHours!.isNotEmpty) ...[
                    _SectionHeader(title: 'Working Hours'),
                    const SizedBox(height: 8),
                    _SectionCard(
                      child: _DetailTile(
                        icon: Icons.access_time,
                        title: 'Business Hours',
                        subtitle: branch.workingHours!,
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // ── Branch manager ─────────────────────────────────────────
                  if (branch.managerName != null &&
                      branch.managerName!.isNotEmpty) ...[
                    _SectionHeader(title: 'Branch Manager'),
                    const SizedBox(height: 8),
                    _SectionCard(
                      child: Column(
                        children: [
                          _DetailTile(
                            icon: Icons.person,
                            title: 'Manager',
                            subtitle: branch.managerName!,
                          ),
                          // Manager phone (requires model update)
                          if (managerPhone != null &&
                              managerPhone.isNotEmpty) ...[
                            _Divider(),
                            _DetailTile(
                              icon: Icons.phone_outlined,
                              title: 'Manager Phone',
                              subtitle: managerPhone,
                              trailingIcon: Icons.call,
                              onTrailingTap: () =>
                                  _launchUrl('tel:$managerPhone'),
                            ),
                          ],
                          // Manager email (requires model update)
                          if (managerEmail != null &&
                              managerEmail.isNotEmpty) ...[
                            _Divider(),
                            _DetailTile(
                              icon: Icons.email_outlined,
                              title: 'Manager Email',
                              subtitle: managerEmail,
                              trailingIcon: Icons.send,
                              onTrailingTap: () =>
                                  _launchUrl('mailto:$managerEmail'),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // ── Branch statistics ──────────────────────────────────────
                  if (provider.branchStats != null) ...[
                    _SectionHeader(title: 'Branch Statistics'),
                    const SizedBox(height: 8),
                    _SectionCard(
                      child: Column(
                        children: [
                          _StatRow(
                            label: 'Total Accounts',
                            value: provider.branchStats!.totalAccounts
                                .toString(),
                            icon: Icons.account_balance_wallet,
                          ),
                          _Divider(),
                          _StatRow(
                            label: 'Total Customers',
                            value: provider.branchStats!.totalCustomers
                                .toString(),
                            icon: Icons.people,
                          ),
                          _Divider(),
                          _StatRow(
                            label: 'Total Deposits',
                            value:
                                '৳${_formatCurrency(provider.branchStats!.totalDeposits)}',
                            icon: Icons.trending_up,
                          ),
                          // Staff count (requires model update)
                          if (totalEmployees != null) ...[
                            _Divider(),
                            _StatRow(
                              label: 'Total Employees',
                              value: totalEmployees.toString(),
                              icon: Icons.badge,
                            ),
                          ],
                          // DPS count (requires model update)
                          if (totalDPS != null) ...[
                            _Divider(),
                            _StatRow(
                              label: 'DPS Accounts',
                              value: totalDPS.toString(),
                              icon: Icons.savings,
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  const SizedBox(height: 24),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  String _formatCurrency(double value) {
    final f = NumberFormat('#,##0.00', 'en_US');
    return f.format(value);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Private helper widgets
// ─────────────────────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final Widget child;
  const _SectionCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: child,
      ),
    );
  }
}

class _DetailTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final IconData? trailingIcon;
  final VoidCallback? onTrailingTap;

  const _DetailTile({
    required this.icon,
    required this.title,
    this.subtitle,
    this.trailingIcon,
    this.onTrailingTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return ListTile(
      leading: Icon(icon, color: colorScheme.primary),
      title: Text(
        title,
        style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
      ),
      subtitle: subtitle != null
          ? Text(
              subtitle!,
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            )
          : null,
      trailing: trailingIcon != null
          ? IconButton(
              icon: Icon(trailingIcon, color: colorScheme.primary),
              onPressed: onTrailingTap,
            )
          : null,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
    );
  }
}

class _StatRow extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _StatRow({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Icon(icon, size: 20, color: colorScheme.onSurfaceVariant),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: theme.textTheme.bodyMedium,
            ),
          ),
          Text(
            value,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: colorScheme.primary,
            ),
          ),
        ],
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Divider(
      height: 1,
      indent: 16,
      endIndent: 16,
      color: Theme.of(context).colorScheme.outlineVariant,
    );
  }
}

/// Status badge shown in the hero card.
class _StatusBadge extends StatelessWidget {
  final String status;
  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final upper = status.toUpperCase();
    final Color color;
    final IconData icon;
    final String label;

    switch (upper) {
      case 'ACTIVE':
        color = Colors.green;
        icon = Icons.check_circle_outline;
        label = 'Active';
        break;
      case 'INACTIVE':
        color = Colors.grey;
        icon = Icons.pause_circle_outline;
        label = 'Inactive';
        break;
      case 'CLOSED':
        color = Colors.red;
        icon = Icons.cancel_outlined;
        label = 'Closed';
        break;
      case 'UNDER_MAINTENANCE':
        color = Colors.orange;
        icon = Icons.construction_outlined;
        label = 'Under Maintenance';
        break;
      default:
        color = Colors.blueGrey;
        icon = Icons.info_outline;
        label = upper;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}

// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';
// import 'package:provider/provider.dart';
// import 'package:url_launcher/url_launcher.dart';
// import '../providers/branch_provider.dart';

// /// Branch details screen with contact info and map integration
// class BranchDetailsScreen extends StatefulWidget {
//   final int branchId;

//   const BranchDetailsScreen({super.key, required this.branchId});

//   @override
//   State<BranchDetailsScreen> createState() => _BranchDetailsScreenState();
// }

// class _BranchDetailsScreenState extends State<BranchDetailsScreen> {
//   @override
//   void initState() {
//     super.initState();
//     WidgetsBinding.instance.addPostFrameCallback((_) {
//       context.read<BranchProvider>().fetchBranchDetails(widget.branchId);
//     });
//   }

//   void _copy(String text, String label) {
//     Clipboard.setData(ClipboardData(text: text));
//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(content: Text('$label copied')),
//     );
//   }

//   Future<void> _launchUrl(String url) async {
//     if (!await launchUrl(Uri.parse(url))) {
//       if (mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(content: Text('Could not open link')),
//         );
//       }
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     final theme = Theme.of(context);
    
//     return Scaffold(
//       appBar: AppBar(title: const Text('Branch Details')),
//       body: Consumer<BranchProvider>(
//         builder: (context, provider, _) {
//           if (provider.isLoading) {
//             return const Center(child: CircularProgressIndicator());
//           }

//           final branch = provider.selectedBranch;
//           if (branch == null) {
//             return const Center(child: Text('Branch not found'));
//           }

//           return SingleChildScrollView(
//             padding: const EdgeInsets.all(16),
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 // Header Card
//                 Card(
//                   child: Padding(
//                     padding: const EdgeInsets.all(16),
//                     child: Column(
//                       children: [
//                         Icon(Icons.business, size: 64, color: theme.colorScheme.primary),
//                         const SizedBox(height: 12),
//                         Text(branch.branchName, style: theme.textTheme.headlineSmall, textAlign: TextAlign.center),
//                         const SizedBox(height: 4),
//                         Text(branch.branchCode, style: theme.textTheme.bodyLarge),
//                       ],
//                     ),
//                   ),
//                 ),
//                 const SizedBox(height: 16),

//                 // Contact Section
//                 Text('Contact Information', style: theme.textTheme.titleMedium),
//                 const SizedBox(height: 8),
//                 Card(
//                   child: Column(
//                     children: [
//                       ListTile(
//                         leading: const Icon(Icons.phone),
//                         title: const Text('Phone'),
//                         subtitle: Text(branch.phone!),
//                         trailing: IconButton(
//                           icon: const Icon(Icons.call),
//                           onPressed: () => _launchUrl('tel:${branch.phone}'),
//                         ),
//                       ),
//                       ListTile(
//                         leading: const Icon(Icons.email),
//                         title: const Text('Email'),
//                         subtitle: Text(branch.email!),
//                         trailing: IconButton(
//                           icon: const Icon(Icons.send),
//                           onPressed: () => _launchUrl('mailto:${branch.email}'),
//                         ),
//                       ),
//                       ListTile(
//                         leading: const Icon(Icons.qr_code),
//                         title: const Text('IFSC Code'),
//                         subtitle: Text(branch.ifscCode),
//                         trailing: IconButton(
//                           icon: const Icon(Icons.copy),
//                           onPressed: () => _copy(branch.ifscCode, 'IFSC'),
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),
//                 const SizedBox(height: 16),

//                 // Address Section
//                 Text('Address', style: theme.textTheme.titleMedium),
//                 const SizedBox(height: 8),
//                 Card(
//                   child: ListTile(
//                     leading: const Icon(Icons.location_on),
//                     title: Text(branch.fullAddress),
//                     trailing: branch.hasLocation
//                         ? IconButton(
//                             icon: const Icon(Icons.directions),
//                             onPressed: () => _launchUrl(branch.googleMapsUrl!),
//                           )
//                         : null,
//                   ),
//                 ),
//                 const SizedBox(height: 16),

//                 // // Working Hours
//                 // if (branch.workingHoursStart != null)
//                 //   Column(
//                 //     crossAxisAlignment: CrossAxisAlignment.start,
//                 //     children: [
//                 //       Text('Working Hours', style: theme.textTheme.titleMedium),
//                 //       const SizedBox(height: 8),
//                 //       Card(
//                 //         child: ListTile(
//                 //           leading: const Icon(Icons.access_time),
//                 //           title: Text('${branch.workingHoursStart} - ${branch.workingHoursEnd}'),
//                 //         ),
//                 //       ),
//                 //     ],
//                 //   ),

//                 // Statistics (if available)
//                 if (provider.branchStats != null) ...[
//                   const SizedBox(height: 16),
//                   Text('Branch Statistics', style: theme.textTheme.titleMedium),
//                   const SizedBox(height: 8),
//                   Card(
//                     child: Padding(
//                       padding: const EdgeInsets.all(16),
//                       child: Column(
//                         children: [
//                           _StatRow('Total Accounts', '${provider.branchStats!.totalAccounts}'),
//                           _StatRow('Total Customers', '${provider.branchStats!.totalCustomers}'),
//                           _StatRow('Total Deposits', 'BDT ${provider.branchStats!.totalDeposits.toStringAsFixed(2)}'),
//                         ],
//                       ),
//                     ),
//                   ),
//                 ],
//               ],
//             ),
//           );
//         },
//       ),
//     );
//   }
// }

// class _StatRow extends StatelessWidget {
//   final String label;
//   final String value;

//   const _StatRow(this.label, this.value);

//   @override
//   Widget build(BuildContext context) {
//     return Padding(
//       padding: const EdgeInsets.symmetric(vertical: 8),
//       child: Row(
//         mainAxisAlignment: MainAxisAlignment.spaceBetween,
//         children: [
//           Text(label),
//           Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
//         ],
//       ),
//     );
//   }
// }