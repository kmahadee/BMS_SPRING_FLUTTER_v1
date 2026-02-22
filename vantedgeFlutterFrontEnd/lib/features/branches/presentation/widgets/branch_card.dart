import 'package:flutter/material.dart';
import 'package:vantedge/features/branches/data/models/branch_response_dto.dart';

class BranchCard extends StatelessWidget {
  final BranchResponseDTO branch;
  final VoidCallback? onTap;

  const BranchCard({
    super.key,
    required this.branch,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      elevation: 1,
      margin: const EdgeInsets.symmetric(vertical: 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Branch icon container
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.account_balance,
                  color: colorScheme.onPrimaryContainer,
                  size: 24,
                ),
              ),
              const SizedBox(width: 14),

              // Main info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Top row: branch name + status badge
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            branch.branchName,
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (branch.status != null)
                          _BranchStatusBadge(status: branch.status!),
                      ],
                    ),
                    const SizedBox(height: 4),

                    // City • Branch code
                    Text(
                      '${branch.city}  •  ${branch.branchCode}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 4),

                    // IFSC code
                    Row(
                      children: [
                        Icon(
                          Icons.tag,
                          size: 13,
                          color: colorScheme.onSurfaceVariant.withOpacity(0.7),
                        ),
                        const SizedBox(width: 3),
                        Text(
                          branch.ifscCode,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                            fontFamily: 'monospace',
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),

                    // Phone (if available)
                    if (branch.phone.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.phone_outlined,
                            size: 13,
                            color: colorScheme.onSurfaceVariant.withOpacity(0.7),
                          ),
                          const SizedBox(width: 3),
                          Text(
                            branch.phone,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),

              // Chevron
              const SizedBox(width: 8),
              Icon(
                Icons.chevron_right,
                color: colorScheme.onSurfaceVariant.withOpacity(0.6),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Status badge displayed in the top-right corner of a BranchCard.
class _BranchStatusBadge extends StatelessWidget {
  final String status;

  const _BranchStatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final upper = status.toUpperCase();
    final Color color;
    final IconData icon;

    switch (upper) {
      case 'ACTIVE':
        color = Colors.green;
        icon = Icons.check_circle_outline;
        break;
      case 'INACTIVE':
        color = Colors.grey;
        icon = Icons.pause_circle_outline;
        break;
      case 'CLOSED':
        color = Colors.red;
        icon = Icons.cancel_outlined;
        break;
      case 'UNDER_MAINTENANCE':
        color = Colors.orange;
        icon = Icons.construction_outlined;
        break;
      default:
        color = Colors.blueGrey;
        icon = Icons.info_outline;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            _formatStatus(upper),
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  String _formatStatus(String upper) {
    switch (upper) {
      case 'ACTIVE':
        return 'Active';
      case 'INACTIVE':
        return 'Inactive';
      case 'CLOSED':
        return 'Closed';
      case 'UNDER_MAINTENANCE':
        return 'Maintenance';
      default:
        // Title-case fallback
        return upper[0] + upper.substring(1).toLowerCase();
    }
  }
}