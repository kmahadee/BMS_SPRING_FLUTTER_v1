import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:vantedge/features/accounts/presentation/providers/account_provider.dart';
import '../../../data/models/account_statement_dto.dart';
import '../../../data/models/transaction_dto.dart';

class AccountStatementScreen extends StatefulWidget {
  final String accountNumber;

  const AccountStatementScreen({
    super.key,
    required this.accountNumber,
  });

  @override
  State<AccountStatementScreen> createState() => _AccountStatementScreenState();
}

class _AccountStatementScreenState extends State<AccountStatementScreen> {
  DateTime _fromDate = DateTime.now().subtract(const Duration(days: 30));
  DateTime _toDate = DateTime.now();
  
  final TextEditingController _searchController = TextEditingController();
  final String _searchQuery = '';
  
  _TransactionFilter _filter = _TransactionFilter.all;
  double? _minAmount;
  double? _maxAmount;
  
  final int _itemsPerPage = 20;
  int _currentPage = 1;

  @override
  void initState() {
    super.initState();
    _generateStatement();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _generateStatement() {
    context.read<AccountProvider>().generateStatement(
      widget.accountNumber,
      _fromDate,
      _toDate,
    );
  }

  Future<void> _selectDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime.now().subtract(const Duration(days: 365 * 5)),
      lastDate: DateTime.now(),
      initialDateRange: DateTimeRange(start: _fromDate, end: _toDate),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme,
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _fromDate = picked.start;
        _toDate = picked.end;
        _currentPage = 1;
      });
      _generateStatement();
    }
  }

  void _setDatePreset(_DatePreset preset) {
    setState(() {
      _toDate = DateTime.now();
      switch (preset) {
        case _DatePreset.last7Days:
          _fromDate = _toDate.subtract(const Duration(days: 7));
          break;
        case _DatePreset.last30Days:
          _fromDate = _toDate.subtract(const Duration(days: 30));
          break;
        case _DatePreset.last3Months:
          _fromDate = DateTime(_toDate.year, _toDate.month - 3, _toDate.day);
          break;
        case _DatePreset.last6Months:
          _fromDate = DateTime(_toDate.year, _toDate.month - 6, _toDate.day);
          break;
      }
      _currentPage = 1;
    });
    _generateStatement();
  }

  List<TransactionDTO> _getFilteredTransactions(AccountStatementDTO statement) {
    var transactions = statement.sortedTransactions;

    if (_searchQuery.isNotEmpty) {
      transactions = transactions.where((txn) {
        return txn.transactionReference?.toLowerCase().contains(_searchQuery.toLowerCase()) ??
            false ||
            txn.description!.toLowerCase().contains(_searchQuery.toLowerCase()) ?? false;
      }).toList();
    }

    switch (_filter) {
      case _TransactionFilter.credit:
        transactions = transactions.where((t) => t.isCredit).toList();
        break;
      case _TransactionFilter.debit:
        transactions = transactions.where((t) => t.isDebit).toList();
        break;
      case _TransactionFilter.all:
        break;
    }

    if (_minAmount != null) {
      transactions = transactions.where((t) => t.amount >= _minAmount!).toList();
    }
    if (_maxAmount != null) {
      transactions = transactions.where((t) => t.amount <= _maxAmount!).toList();
    }

    return transactions;
  }

  List<TransactionDTO> _getPaginatedTransactions(List<TransactionDTO> transactions) {
    final startIndex = (_currentPage - 1) * _itemsPerPage;
    final endIndex = startIndex + _itemsPerPage;
    
    if (startIndex >= transactions.length) return [];
    
    return transactions.sublist(
      startIndex,
      endIndex > transactions.length ? transactions.length : endIndex,
    );
  }

  void _showExportOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => _ExportBottomSheet(
        onExport: (option) {
          Navigator.pop(context);
          _handleExport(option);
        },
      ),
    );
  }

  void _handleExport(_ExportOption option) {
    String message;
    switch (option) {
      case _ExportOption.pdf:
        message = 'Generating PDF...';
        break;
      case _ExportOption.email:
        message = 'Sending via email...';
        break;
      case _ExportOption.print:
        message = 'Preparing to print...';
        break;
    }
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$message Feature coming soon')),
    );
  }

  void _showFilterOptions() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => _FilterBottomSheet(
        currentFilter: _filter,
        minAmount: _minAmount,
        maxAmount: _maxAmount,
        onApply: (filter, min, max) {
          setState(() {
            _filter = filter;
            _minAmount = min;
            _maxAmount = max;
            _currentPage = 1;
          });
          Navigator.pop(context);
        },
      ),
    );
  }

  String _formatCurrency(double amount) {
    return NumberFormat.currency(symbol: 'BDT', decimalDigits: 2).format(amount);
  }

  String _formatDate(DateTime date) {
    return DateFormat('MMM dd, yyyy').format(date);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Account Statement'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              showSearch(
                context: context,
                delegate: _TransactionSearchDelegate(
                  transactions: context.read<AccountProvider>().currentStatement?.transactions ?? [],
                ),
              );
            },
            tooltip: 'Search',
          ),
          IconButton(
            icon: Badge(
              isLabelVisible: _filter != _TransactionFilter.all || _minAmount != null || _maxAmount != null,
              child: const Icon(Icons.filter_list),
            ),
            onPressed: _showFilterOptions,
            tooltip: 'Filter',
          ),
          IconButton(
            icon: const Icon(Icons.file_download),
            onPressed: _showExportOptions,
            tooltip: 'Export',
          ),
        ],
      ),
      body: Consumer<AccountProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading && provider.currentStatement == null) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.hasError && provider.currentStatement == null) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error_outline, size: 80, color: colorScheme.error),
                    const SizedBox(height: 24),
                    Text(
                      provider.errorMessage ?? 'Failed to generate statement',
                      style: theme.textTheme.bodyLarge,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    FilledButton.icon(
                      onPressed: _generateStatement,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Try Again'),
                    ),
                  ],
                ),
              ),
            );
          }

          final statement = provider.currentStatement;
          if (statement == null) {
            return const Center(child: Text('No statement available'));
          }

          final filteredTransactions = _getFilteredTransactions(statement);
          final paginatedTransactions = _getPaginatedTransactions(filteredTransactions);
          final totalPages = (filteredTransactions.length / _itemsPerPage).ceil();

          return Column(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                color: colorScheme.surfaceContainerHighest.withOpacity(0.5),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _selectDateRange,
                            icon: const Icon(Icons.calendar_today, size: 18),
                            label: Text(
                              '${_formatDate(_fromDate)} - ${_formatDate(_toDate)}',
                              style: theme.textTheme.bodyMedium,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _DatePresetChip(
                          label: 'Last 7 Days',
                          onPressed: () => _setDatePreset(_DatePreset.last7Days),
                        ),
                        _DatePresetChip(
                          label: 'Last 30 Days',
                          onPressed: () => _setDatePreset(_DatePreset.last30Days),
                        ),
                        _DatePresetChip(
                          label: 'Last 3 Months',
                          onPressed: () => _setDatePreset(_DatePreset.last3Months),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              Container(
                padding: const EdgeInsets.all(16),
                child: Card(
                  elevation: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            _BalanceItem(
                              label: 'Opening',
                              amount: statement.openingBalance,
                              color: colorScheme.primary,
                            ),
                            _BalanceItem(
                              label: 'Closing',
                              amount: statement.closingBalance,
                              color: colorScheme.secondary,
                            ),
                          ],
                        ),
                        const Divider(height: 24),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            _BalanceItem(
                              label: 'Credits',
                              amount: statement.totalCredits,
                              color: Colors.green,
                              count: statement.creditTransactionCount,
                            ),
                            _BalanceItem(
                              label: 'Debits',
                              amount: statement.totalDebits,
                              color: Colors.red,
                              count: statement.debitTransactionCount,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Transactions (${filteredTransactions.length})',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (totalPages > 1)
                      Text(
                        'Page $_currentPage of $totalPages',
                        style: theme.textTheme.bodySmall,
                      ),
                  ],
                ),
              ),

              Expanded(
                child: paginatedTransactions.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.receipt_long,
                              size: 80,
                              color: colorScheme.primary.withOpacity(0.3),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No transactions found',
                              style: theme.textTheme.bodyLarge,
                            ),
                          ],
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: paginatedTransactions.length,
                        separatorBuilder: (context, index) => const Divider(height: 1),
                        itemBuilder: (context, index) {
                          final transaction = paginatedTransactions[index];
                          return _TransactionTile(transaction: transaction);
                        },
                      ),
              ),

              if (totalPages > 1)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: colorScheme.surface,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 4,
                        offset: const Offset(0, -2),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      FilledButton.tonal(
                        onPressed: _currentPage > 1
                            ? () => setState(() => _currentPage--)
                            : null,
                        child: const Text('Previous'),
                      ),
                      Text(
                        'Page $_currentPage of $totalPages',
                        style: theme.textTheme.bodyMedium,
                      ),
                      FilledButton.tonal(
                        onPressed: _currentPage < totalPages
                            ? () => setState(() => _currentPage++)
                            : null,
                        child: const Text('Next'),
                      ),
                    ],
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

enum _DatePreset { last7Days, last30Days, last3Months, last6Months }

enum _TransactionFilter { all, credit, debit }

enum _ExportOption { pdf, email, print }

class _DatePresetChip extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;

  const _DatePresetChip({
    required this.label,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return ActionChip(
      label: Text(label),
      onPressed: onPressed,
    );
  }
}

class _BalanceItem extends StatelessWidget {
  final String label;
  final double amount;
  final Color color;
  final int? count;

  const _BalanceItem({
    required this.label,
    required this.amount,
    required this.color,
    this.count,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(color: color),
            ),
            if (count != null) ...[
              const SizedBox(width: 4),
              Text(
                '($count)',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: color.withOpacity(0.7),
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 4),
        Text(
          NumberFormat.currency(symbol: 'BDT', decimalDigits: 2).format(amount),
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }
}

class _TransactionTile extends StatelessWidget {
  final TransactionDTO transaction;

  const _TransactionTile({required this.transaction});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isCredit = transaction.isCredit;
    final color = isCredit ? Colors.green : Colors.red;

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 0),
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          isCredit ? Icons.arrow_downward : Icons.arrow_upward,
          color: color,
          size: 20,
        ),
      ),
      title: Text(
        transaction.displayType,
        style: theme.textTheme.bodyMedium?.copyWith(
          fontWeight: FontWeight.w600,
        ),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (transaction.description != null)
            Text(
              transaction.description!,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          const SizedBox(height: 2),
          Text(
            DateFormat('MMM dd, yyyy • hh:mm a').format(transaction.transactionDate),
            style: theme.textTheme.bodySmall,
          ),
          if (transaction.transactionReference != null)
            Text(
              'Ref: ${transaction.transactionReference}',
              style: theme.textTheme.bodySmall?.copyWith(
                fontFamily: 'monospace',
              ),
            ),
        ],
      ),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            '${isCredit ? '+' : '-'}${NumberFormat.currency(symbol: 'BDT', decimalDigits: 2).format(transaction.amount)}',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          if (transaction.balanceAfter != null)
            Text(
              'Bal: ${NumberFormat.currency(symbol: 'BDT', decimalDigits: 2).format(transaction.balanceAfter!)}',
              style: theme.textTheme.bodySmall,
            ),
        ],
      ),
    );
  }
}

class _ExportBottomSheet extends StatelessWidget {
  final Function(_ExportOption) onExport;

  const _ExportBottomSheet({required this.onExport});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.picture_as_pdf),
            title: const Text('Export as PDF'),
            onTap: () => onExport(_ExportOption.pdf),
          ),
          ListTile(
            leading: const Icon(Icons.email),
            title: const Text('Send via Email'),
            onTap: () => onExport(_ExportOption.email),
          ),
          ListTile(
            leading: const Icon(Icons.print),
            title: const Text('Print Statement'),
            onTap: () => onExport(_ExportOption.print),
          ),
        ],
      ),
    );
  }
}

class _FilterBottomSheet extends StatefulWidget {
  final _TransactionFilter currentFilter;
  final double? minAmount;
  final double? maxAmount;
  final Function(_TransactionFilter, double?, double?) onApply;

  const _FilterBottomSheet({
    required this.currentFilter,
    required this.minAmount,
    required this.maxAmount,
    required this.onApply,
  });

  @override
  State<_FilterBottomSheet> createState() => _FilterBottomSheetState();
}

class _FilterBottomSheetState extends State<_FilterBottomSheet> {
  late _TransactionFilter _filter;
  final _minController = TextEditingController();
  final _maxController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _filter = widget.currentFilter;
    if (widget.minAmount != null) {
      _minController.text = widget.minAmount!.toString();
    }
    if (widget.maxAmount != null) {
      _maxController.text = widget.maxAmount!.toString();
    }
  }

  @override
  void dispose() {
    _minController.dispose();
    _maxController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Filter Transactions',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            Text('Transaction Type', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                ChoiceChip(
                  label: const Text('All'),
                  selected: _filter == _TransactionFilter.all,
                  onSelected: (selected) {
                    setState(() => _filter = _TransactionFilter.all);
                  },
                ),
                ChoiceChip(
                  label: const Text('Credits'),
                  selected: _filter == _TransactionFilter.credit,
                  onSelected: (selected) {
                    setState(() => _filter = _TransactionFilter.credit);
                  },
                ),
                ChoiceChip(
                  label: const Text('Debits'),
                  selected: _filter == _TransactionFilter.debit,
                  onSelected: (selected) {
                    setState(() => _filter = _TransactionFilter.debit);
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text('Amount Range', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _minController,
                    decoration: const InputDecoration(
                      labelText: 'Min Amount',
                      border: OutlineInputBorder(),
                      prefixText: 'BDT ',
                    ),
                    keyboardType: TextInputType.number,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _maxController,
                    decoration: const InputDecoration(
                      labelText: 'Max Amount',
                      border: OutlineInputBorder(),
                      prefixText: 'BDT ',
                    ),
                    keyboardType: TextInputType.number,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      widget.onApply(_TransactionFilter.all, null, null);
                    },
                    child: const Text('Reset'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: () {
                      final min = double.tryParse(_minController.text);
                      final max = double.tryParse(_maxController.text);
                      widget.onApply(_filter, min, max);
                    },
                    child: const Text('Apply'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _TransactionSearchDelegate extends SearchDelegate<TransactionDTO?> {
  final List<TransactionDTO> transactions;

  _TransactionSearchDelegate({required this.transactions});

  @override
  List<Widget> buildActions(BuildContext context) {
    return [
      IconButton(
        icon: const Icon(Icons.clear),
        onPressed: () => query = '',
      ),
    ];
  }

  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () => close(context, null),
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    return _buildSearchResults();
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    return _buildSearchResults();
  }

  Widget _buildSearchResults() {
    final results = transactions.where((txn) {
      return txn.transactionReference?.toLowerCase().contains(query.toLowerCase()) ?? false ||
          txn.description!.toLowerCase().contains(query.toLowerCase()) ?? false ||
          txn.displayType.toLowerCase().contains(query.toLowerCase());
    }).toList();

    if (results.isEmpty) {
      return const Center(child: Text('No transactions found'));
    }

    return ListView.separated(
      itemCount: results.length,
      separatorBuilder: (context, index) => const Divider(height: 1),
      itemBuilder: (context, index) {
        return _TransactionTile(transaction: results[index]);
      },
    );
  }
}