import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:vantedge/features/transactions/data/models/transaction_history_model.dart';
import 'package:vantedge/features/transactions/data/models/transaction_model.dart';


class TransactionReceiptWidget extends StatelessWidget {
  final TransactionHistoryModel transaction;
  final TransactionModel? fullTransaction;

  final ScrollController? scrollController;

  const TransactionReceiptWidget({
    super.key,
    required this.transaction,
    this.fullTransaction,
    this.scrollController,
  });

  static const _symbol = '৳';
  static final _amtFmt = NumberFormat('#,##0.00');
  static final _dtFmt = DateFormat('dd MMM yyyy, hh:mm a');
  static final _shortDt = DateFormat('dd MMM yyyy');

  String _fmt(double? v) =>
      v == null ? '—' : '$_symbol${_amtFmt.format(v)}';

  String _fmtDate(DateTime? dt) => dt == null ? '—' : _dtFmt.format(dt);

  bool get _isCredit => transaction.isCredit;

  Color get _dirColor =>
      _isCredit ? const Color(0xFF2E7D32) : const Color(0xFFC62828);

  String _maskAcct(String? v) {
    if (v == null || v.isEmpty) return '—';
    if (v.length <= 4) return v;
    return '•••• ${v.substring(v.length - 4)}';
  }

  String get _receiptNumber =>
      fullTransaction?.receiptNumber ??
      'RCP-${transaction.referenceNumber.substring(0, 8).toUpperCase()}';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      child: Scaffold(
        backgroundColor: const Color(0xFFF7F7F7),
        body: Column(
          children: [
            _DragHandle(),

            Expanded(
              child: SingleChildScrollView(
                controller: scrollController,
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                child: Column(
                  children: [
                    _ReceiptPaper(
                      transaction: transaction,
                      fullTransaction: fullTransaction,
                      isCredit: _isCredit,
                      dirColor: _dirColor,
                      receiptNumber: _receiptNumber,
                      fmt: _fmt,
                      fmtDate: _fmtDate,
                      maskAcct: _maskAcct,
                      shortDt: _shortDt,
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),

            Padding(
              padding: EdgeInsets.fromLTRB(
                  20, 8, 20, 16 + MediaQuery.of(context).padding.bottom),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: cs.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: const Text(
                    'Close',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}


class _DragHandle extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Center(
        child: Container(
          width: 40,
          height: 4,
          decoration: BoxDecoration(
            color: Colors.grey.shade300,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
      ),
    );
  }
}


class _ReceiptPaper extends StatelessWidget {
  final TransactionHistoryModel transaction;
  final TransactionModel? fullTransaction;
  final bool isCredit;
  final Color dirColor;
  final String receiptNumber;
  final String Function(double?) fmt;
  final String Function(DateTime?) fmtDate;
  final String Function(String?) maskAcct;
  final DateFormat shortDt;

  const _ReceiptPaper({
    required this.transaction,
    required this.fullTransaction,
    required this.isCredit,
    required this.dirColor,
    required this.receiptNumber,
    required this.fmt,
    required this.fmtDate,
    required this.maskAcct,
    required this.shortDt,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          _BankHeader(
            receiptNumber: receiptNumber,
            timestamp: transaction.timestamp,
            shortDt: shortDt,
          ),

          _JaggedEdge(isTop: false),

          Padding(
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
            child: Column(
              children: [
                Text(
                  isCredit ? 'CREDITED' : 'DEBITED',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 2,
                    color: dirColor,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '${isCredit ? '+' : '−'}৳${NumberFormat('#,##0.00').format(transaction.amount)}',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w800,
                    color: dirColor,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                  decoration: BoxDecoration(
                    color: _statusBg(transaction.status.value),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    transaction.status.displayName.toUpperCase(),
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.2,
                      color: _statusFg(transaction.status.value),
                    ),
                  ),
                ),
              ],
            ),
          ),

          _ReceiptDash(),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              children: [
                _ReceiptRow(
                  label: 'Transaction ID',
                  value: transaction.transactionId,
                  monospace: true,
                ),
                _ReceiptRow(
                  label: 'Reference No.',
                  value: transaction.referenceNumber,
                  monospace: true,
                ),
                _ReceiptRow(
                  label: 'Date & Time',
                  value: fmtDate(transaction.timestamp),
                ),
                _ReceiptRow(
                  label: 'Transfer Mode',
                  value: transaction.transferMode.displayName,
                ),
                _ReceiptRow(
                  label: 'Transaction Type',
                  value: _readableType(transaction.transactionType),
                ),
              ],
            ),
          ),

          _ReceiptDash(),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              children: [
                _ReceiptSectionHeader(label: 'ACCOUNT DETAILS'),
                const SizedBox(height: 10),
                _ReceiptRow(
                  label: 'From Account',
                  value: maskAcct(
                    fullTransaction?.fromAccountNumber ??
                        (transaction.isDebit ? transaction.accountNumber : null),
                  ),
                ),
                _ReceiptRow(
                  label: 'To Account',
                  value: maskAcct(
                    fullTransaction?.toAccountNumber ??
                        (transaction.isCredit
                            ? transaction.accountNumber
                            : transaction.otherAccountNumber),
                  ),
                ),
                if ((transaction.branchName ?? fullTransaction?.fromBranchName) != null)
                  _ReceiptRow(
                    label: 'From Branch',
                    value: transaction.branchName ??
                        fullTransaction?.fromBranchName ??
                        '—',
                  ),
                if ((transaction.otherBranchName ?? fullTransaction?.toBranchName) != null)
                  _ReceiptRow(
                    label: 'To Branch',
                    value: transaction.otherBranchName ??
                        fullTransaction?.toBranchName ??
                        '—',
                  ),
              ],
            ),
          ),

          if (fullTransaction != null &&
              (fullTransaction!.transferFee != null ||
                  fullTransaction!.serviceTax != null ||
                  fullTransaction!.totalAmount != null)) ...[
            _ReceiptDash(),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Column(
                children: [
                  _ReceiptSectionHeader(label: 'AMOUNT BREAKDOWN'),
                  const SizedBox(height: 10),
                  _ReceiptRow(
                    label: 'Amount',
                    value: fmt(transaction.amount),
                  ),
                  if (fullTransaction!.transferFee != null)
                    _ReceiptRow(
                      label: 'Transfer Fee',
                      value: fmt(fullTransaction!.transferFee),
                    ),
                  if (fullTransaction!.serviceTax != null)
                    _ReceiptRow(
                      label: 'Service Tax',
                      value: fmt(fullTransaction!.serviceTax),
                    ),
                  const SizedBox(height: 4),
                  _ReceiptDash(),
                  const SizedBox(height: 4),
                  _ReceiptRow(
                    label: 'Total Charged',
                    value: fmt(fullTransaction!.totalAmount ??
                        fullTransaction!.effectiveTotal),
                    valueBold: true,
                    valueColor: dirColor,
                  ),
                ],
              ),
            ),
          ],

          if (fullTransaction?.balanceBefore != null ||
              transaction.balanceAfter != null) ...[
            _ReceiptDash(),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Column(
                children: [
                  _ReceiptSectionHeader(label: 'BALANCE INFORMATION'),
                  const SizedBox(height: 10),
                  if (fullTransaction?.balanceBefore != null)
                    _ReceiptRow(
                      label: 'Balance Before',
                      value: fmt(fullTransaction!.balanceBefore),
                    ),
                  if (transaction.balanceAfter != null)
                    _ReceiptRow(
                      label: 'Balance After',
                      value: fmt(transaction.balanceAfter),
                      valueBold: true,
                    ),
                ],
              ),
            ),
          ],

          if (transaction.description?.isNotEmpty == true ||
              fullTransaction?.remarks?.isNotEmpty == true) ...[
            _ReceiptDash(),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _ReceiptSectionHeader(label: 'REMARKS'),
                  const SizedBox(height: 8),
                  if (transaction.description?.isNotEmpty == true)
                    Text(
                      transaction.description!,
                      style: const TextStyle(
                          fontSize: 12, color: Color(0xFF555555)),
                    ),
                  if (fullTransaction?.remarks?.isNotEmpty == true) ...[
                    const SizedBox(height: 4),
                    Text(
                      fullTransaction!.remarks!,
                      style: const TextStyle(
                          fontSize: 12, color: Color(0xFF555555)),
                    ),
                  ],
                ],
              ),
            ),
          ],

          _JaggedEdge(isTop: true),

          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
            child: Column(
              children: [
                Container(
                  width: 96,
                  height: 96,
                  decoration: BoxDecoration(
                    color: const Color(0xFFEEEEEE),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.qr_code_2_rounded,
                      size: 64,
                      color: Color(0xFFBBBBBB),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'Scan to verify receipt',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey.shade500,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'VantEdge Bank',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Colors.grey.shade700,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'This is a computer-generated receipt and\ndoes not require a physical signature.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.grey.shade400,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _statusBg(String status) {
    switch (status.toUpperCase()) {
      case 'COMPLETED':
        return const Color(0xFFE8F5E9);
      case 'PENDING':
        return const Color(0xFFFFF8E1);
      case 'FAILED':
        return const Color(0xFFFFEBEE);
      case 'CANCELLED':
        return const Color(0xFFF5F5F5);
      case 'PROCESSING':
        return const Color(0xFFE3F2FD);
      default:
        return const Color(0xFFF5F5F5);
    }
  }

  Color _statusFg(String status) {
    switch (status.toUpperCase()) {
      case 'COMPLETED':
        return const Color(0xFF1B5E20);
      case 'PENDING':
        return const Color(0xFFE65100);
      case 'FAILED':
        return const Color(0xFFB71C1C);
      case 'CANCELLED':
        return const Color(0xFF424242);
      case 'PROCESSING':
        return const Color(0xFF0D47A1);
      default:
        return const Color(0xFF424242);
    }
  }

  String _readableType(String raw) {
    if (raw.isEmpty) return raw;
    return raw[0].toUpperCase() + raw.substring(1).toLowerCase();
  }
}


class _BankHeader extends StatelessWidget {
  final String receiptNumber;
  final DateTime? timestamp;
  final DateFormat shortDt;

  const _BankHeader({
    required this.receiptNumber,
    required this.timestamp,
    required this.shortDt,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF1A237E), Color(0xFF283593)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Column(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.account_balance_rounded,
              color: Colors.white,
              size: 26,
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'VantEdge Bank',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.3,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'OFFICIAL TRANSACTION RECEIPT',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 10,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Receipt: $receiptNumber',
                style: const TextStyle(
                  color: Colors.white60,
                  fontSize: 11,
                ),
              ),
              if (timestamp != null)
                Text(
                  shortDt.format(timestamp!),
                  style: const TextStyle(
                    color: Colors.white60,
                    fontSize: 11,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}


class _ReceiptRow extends StatelessWidget {
  final String label;
  final String value;
  final bool monospace;
  final bool valueBold;
  final Color? valueColor;

  const _ReceiptRow({
    required this.label,
    required this.value,
    this.monospace = false,
    this.valueBold = false,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 4,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF888888),
              ),
            ),
          ),
          Expanded(
            flex: 5,
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: TextStyle(
                fontSize: 12,
                fontWeight: valueBold ? FontWeight.w700 : FontWeight.w500,
                color: valueColor ?? const Color(0xFF222222),
                fontFamily: monospace ? 'monospace' : null,
              ),
            ),
          ),
        ],
      ),
    );
  }
}


class _ReceiptSectionHeader extends StatelessWidget {
  final String label;

  const _ReceiptSectionHeader({required this.label});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.4,
          color: Color(0xFF9E9E9E),
        ),
      ),
    );
  }
}


class _ReceiptDash extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (_, constraints) {
        const dashW = 5.0;
        const gap = 4.0;
        final count = (constraints.maxWidth / (dashW + gap)).floor();
        return Row(
          children: List.generate(count, (_) {
            return Padding(
              padding: const EdgeInsets.only(right: gap),
              child: Container(
                width: dashW,
                height: 1,
                color: const Color(0xFFDDDDDD),
              ),
            );
          }),
        );
      },
    );
  }
}


class _JaggedEdge extends StatelessWidget {
  final bool isTop;

  const _JaggedEdge({required this.isTop});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 16,
      child: CustomPaint(
        size: const Size(double.infinity, 16),
        painter: _JaggedPainter(isTop: isTop),
      ),
    );
  }
}

class _JaggedPainter extends CustomPainter {
  final bool isTop;

  const _JaggedPainter({required this.isTop});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = const Color(0xFFF7F7F7);
    const r = 8.0;
    final path = Path();

    if (!isTop) {
      path.moveTo(0, 0);
      path.lineTo(0, size.height);
      double x = 0;
      while (x < size.width) {
        path.arcToPoint(
          Offset(x + r * 2, size.height),
          radius: const Radius.circular(r),
          clockwise: false,
        );
        x += r * 2;
      }
      path.lineTo(size.width, 0);
      path.close();
    } else {
      path.moveTo(0, size.height);
      path.lineTo(0, 0);
      double x = 0;
      while (x < size.width) {
        path.arcToPoint(
          Offset(x + r * 2, 0),
          radius: const Radius.circular(r),
          clockwise: true,
        );
        x += r * 2;
      }
      path.lineTo(size.width, size.height);
      path.close();
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_JaggedPainter old) => old.isTop != isTop;
}