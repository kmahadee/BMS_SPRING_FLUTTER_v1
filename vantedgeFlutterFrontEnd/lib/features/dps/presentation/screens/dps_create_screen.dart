import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import 'package:vantedge/features/auth/presentation/providers/auth_provider.dart';
import 'package:vantedge/features/branches/data/models/branch_response_dto.dart';
import 'package:vantedge/features/branches/presentation/providers/branch_provider.dart';
import 'package:vantedge/features/dps/data/models/maturity_calculation_model.dart';
import 'package:vantedge/features/dps/presentation/providers/dps_provider.dart';
import 'package:vantedge/shared/widgets/main_scaffold.dart';

class DpsCreateScreen extends StatefulWidget {
  /// Optional pre-filled values from the maturity calculator screen.
  final double? initialInstallment;
  final int? initialTenure;
  final double? initialRate;

  const DpsCreateScreen({
    super.key,
    this.initialInstallment,
    this.initialTenure,
    this.initialRate,
  });

  @override
  State<DpsCreateScreen> createState() => _DpsCreateScreenState();
}

class _DpsCreateScreenState extends State<DpsCreateScreen>
    with SingleTickerProviderStateMixin {
  // ─── Form ───────────────────────────────────────────────────────────────────
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _installmentCtrl;
  late final TextEditingController _tenureCtrl;
  late final TextEditingController _rateCtrl;
  // final TextEditingController _branchCodeCtrl = TextEditingController();
  BranchResponseDTO? _selectedBranch;
  final TextEditingController _linkedAccountCtrl = TextEditingController();
  final TextEditingController _nomineeFirstCtrl = TextEditingController();
  final TextEditingController _nomineeLastCtrl = TextEditingController();
  final TextEditingController _nomineeRelationCtrl = TextEditingController();
  final TextEditingController _nomineePhoneCtrl = TextEditingController();

  // ─── State ───────────────────────────────────────────────────────────────────
  bool _autoDebitEnabled = false;
  bool _termsAccepted = false;
  bool _isSubmitting = false;
  double _tenureSliderValue = 24;

  // ─── Debounce ────────────────────────────────────────────────────────────────
  Timer? _debounce;

  // ─── Animation ───────────────────────────────────────────────────────────────
  late AnimationController _previewAnimCtrl;
  late Animation<double> _previewFade;

  // ─── Currency formatter ───────────────────────────────────────────────────────
  final _currencyFmt = NumberFormat.currency(symbol: '৳ ', decimalDigits: 2);
  final _dateFmt = DateFormat('dd MMM yyyy');

  @override
  void initState() {
    super.initState();

    // Pre-fill from calculator if provided
    _installmentCtrl = TextEditingController(
      text: widget.initialInstallment != null
          ? widget.initialInstallment!.toStringAsFixed(2)
          : '',
    );
    _tenureCtrl = TextEditingController(
      text: widget.initialTenure?.toString() ?? '24',
    );
    _rateCtrl = TextEditingController(
      text: widget.initialRate != null
          ? widget.initialRate!.toStringAsFixed(1)
          : '8.0',
    );

    _tenureSliderValue =
        (widget.initialTenure ?? 24).clamp(6, 120).toDouble();

    // Animation for preview card
    _previewAnimCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _previewFade = CurvedAnimation(
      parent: _previewAnimCtrl,
      curve: Curves.easeInOut,
    );

    // Listen to field changes to trigger debounced calculation
    _installmentCtrl.addListener(_onFieldChanged);
    _tenureCtrl.addListener(_onFieldChanged);
    _rateCtrl.addListener(_onFieldChanged);

    // If pre-filled, fire calculation on first frame
    // 
    // Fetch branches and optionally trigger calculation on first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<BranchProvider>().fetchAllBranches();
      if (widget.initialInstallment != null) _triggerCalculation();
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _previewAnimCtrl.dispose();
    _installmentCtrl.dispose();
    _tenureCtrl.dispose();
    _rateCtrl.dispose();
    // _branchCodeCtrl.dispose();
    _linkedAccountCtrl.dispose();
    _nomineeFirstCtrl.dispose();
    _nomineeLastCtrl.dispose();
    _nomineeRelationCtrl.dispose();
    _nomineePhoneCtrl.dispose();
    super.dispose();
  }

  // ─── Debounced maturity calculation ──────────────────────────────────────────
  void _onFieldChanged() {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 800), _triggerCalculation);
  }

  void _triggerCalculation() {
    final monthly = double.tryParse(_installmentCtrl.text.trim());
    final tenure = int.tryParse(_tenureCtrl.text.trim());
    final rate = double.tryParse(_rateCtrl.text.trim());

    if (monthly == null || monthly < 100) return;
    if (tenure == null || tenure < 6 || tenure > 120) return;
    if (rate == null || rate <= 0) return;

    final provider = context.read<DpsProvider>();
    provider.calculateMaturity(
      monthly: monthly,
      tenure: tenure,
      rate: rate,
    );
    _previewAnimCtrl.forward(from: 0);
  }

  // ─── Submission ───────────────────────────────────────────────────────────────
  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_termsAccepted) {
      _showSnackBar('Please accept the terms and conditions.', isError: true);
      return;
    }

    final confirmed = await _showConfirmationDialog();
    if (!confirmed) return;

    setState(() => _isSubmitting = true);

    final authProvider = context.read<AuthProvider>();
    final dpsProvider = context.read<DpsProvider>();
    final customerId = authProvider.user?.customerId ?? '';

    final body = <String, dynamic>{
      'customerId': customerId,
      // 'branchCode': _branchCodeCtrl.text.trim(),
      'branchCode': _selectedBranch!.branchCode,
      'monthlyInstallment':
          double.tryParse(_installmentCtrl.text.trim()) ?? 0,
      'tenureMonths': int.tryParse(_tenureCtrl.text.trim()) ?? 24,
      'interestRate': double.tryParse(_rateCtrl.text.trim()) ?? 8.0,
      'autoDebitEnabled': _autoDebitEnabled,
      if (_autoDebitEnabled &&
          _linkedAccountCtrl.text.trim().isNotEmpty)
        'linkedAccountNumber': _linkedAccountCtrl.text.trim(),
      if (_nomineeFirstCtrl.text.trim().isNotEmpty)
        'nomineeFirstName': _nomineeFirstCtrl.text.trim(),
      if (_nomineeLastCtrl.text.trim().isNotEmpty)
        'nomineeLastName': _nomineeLastCtrl.text.trim(),
      if (_nomineeRelationCtrl.text.trim().isNotEmpty)
        'nomineeRelationship': _nomineeRelationCtrl.text.trim(),
      if (_nomineePhoneCtrl.text.trim().isNotEmpty)
        'nomineePhone': _nomineePhoneCtrl.text.trim(),
    };

    final success = await dpsProvider.createDps(body);

    if (!mounted) return;
    setState(() => _isSubmitting = false);

    if (success) {
      _showSnackBar('DPS account created successfully!');
      // Allow parent DPS list screen to refresh
      Navigator.pop(context, true);
    } else {
      _showSnackBar(
        dpsProvider.errorMessage ?? 'Failed to create DPS. Please try again.',
        isError: true,
      );
      dpsProvider.clearMessages();
    }
  }

  Future<bool> _showConfirmationDialog() async {
    final monthly = double.tryParse(_installmentCtrl.text.trim()) ?? 0;
    final tenure = int.tryParse(_tenureCtrl.text.trim()) ?? 0;
    final rate = double.tryParse(_rateCtrl.text.trim()) ?? 0;

    return await showDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder: (ctx) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Theme.of(ctx).colorScheme.primaryContainer,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.savings_outlined,
                    color: Theme.of(ctx).colorScheme.primary,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                const Text('Confirm DPS Creation'),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'You are about to open a new Deposit Pension Scheme:',
                  style: TextStyle(fontSize: 13),
                ),
                const SizedBox(height: 16),
                _confirmRow('Monthly Installment',
                    _currencyFmt.format(monthly)),
                _confirmRow('Tenure', '$tenure months'),
                _confirmRow('Interest Rate', '${rate.toStringAsFixed(1)}%'),
                // _confirmRow('Branch Code', _branchCodeCtrl.text.trim()),
                _confirmRow('Branch', _selectedBranch?.branchName ?? ''),
                _confirmRow('Branch Code', _selectedBranch?.branchCode ?? ''),
                if (_autoDebitEnabled)
                  _confirmRow('Auto Debit', 'Enabled'),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Theme.of(ctx)
                        .colorScheme
                        .tertiaryContainer
                        .withOpacity(0.5),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.info_outline, size: 16),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Premature closure will incur a penalty charge.',
                          style: TextStyle(fontSize: 12),
                        ),
                      ),
                    ],
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
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Confirm & Create'),
              ),
            ],
          ),
        ) ??
        false;
  }

  Widget _confirmRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: const TextStyle(fontSize: 13, color: Colors.black54)),
          Text(value,
              style: const TextStyle(
                  fontSize: 13, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  void _showSnackBar(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor:
            isError ? Theme.of(context).colorScheme.error : Colors.green[700],
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  // ─── Build ────────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return SimpleScaffold(
      title: 'Open New DPS',
      actions: [
        IconButton(
          icon: const Icon(Icons.help_outline),
          tooltip: 'DPS Information',
          onPressed: _showInfoSheet,
        ),
      ],
      child: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 120),
          children: [
            // ── Hero banner ──────────────────────────────────────────────────
            _HeroBanner(colorScheme: colorScheme),
            const SizedBox(height: 24),

            // ── Section 1: Basic Details ─────────────────────────────────────
            _SectionHeader(
              icon: Icons.tune_rounded,
              label: 'Basic Details',
              colorScheme: colorScheme,
            ),
            const SizedBox(height: 12),
            _buildInstallmentField(colorScheme),
            const SizedBox(height: 16),
            _buildTenureSection(colorScheme),
            const SizedBox(height: 16),
            _buildRateField(colorScheme),
            const SizedBox(height: 16),
            _buildBranchCodeField(colorScheme),
            const SizedBox(height: 24),

            // ── Section 2: Live Maturity Preview ─────────────────────────────
            _SectionHeader(
              icon: Icons.trending_up_rounded,
              label: 'Maturity Preview',
              colorScheme: colorScheme,
            ),
            const SizedBox(height: 12),
            _MaturityPreviewCard(
              fadeAnimation: _previewFade,
              currencyFmt: _currencyFmt,
              dateFmt: _dateFmt,
              tenureMonths: int.tryParse(_tenureCtrl.text.trim()) ?? 24,
            ),
            const SizedBox(height: 24),

            // ── Section 3: Auto Debit ─────────────────────────────────────────
            _SectionHeader(
              icon: Icons.autorenew_rounded,
              label: 'Auto Debit',
              colorScheme: colorScheme,
            ),
            const SizedBox(height: 8),
            _buildAutoDebitSection(colorScheme),
            const SizedBox(height: 24),

            // ── Section 4: Nominee Details ────────────────────────────────────
            _SectionHeader(
              icon: Icons.person_outline_rounded,
              label: 'Nominee Details',
              subtitle: 'Optional',
              colorScheme: colorScheme,
            ),
            const SizedBox(height: 12),
            _buildNomineeSection(colorScheme),
            const SizedBox(height: 24),

            // ── Section 5: Terms ───────────────────────────────────────────────
            _SectionHeader(
              icon: Icons.gavel_rounded,
              label: 'Terms & Conditions',
              colorScheme: colorScheme,
            ),
            const SizedBox(height: 8),
            _buildTermsSection(colorScheme),
            const SizedBox(height: 32),

            // ── Submit button ──────────────────────────────────────────────────
            _buildSubmitButton(colorScheme),
          ],
        ),
      ),
    );
  }

  // ─── Field builders ────────────────────────────────────────────────────────

  Widget _buildInstallmentField(ColorScheme cs) {
    return TextFormField(
      controller: _installmentCtrl,
      keyboardType:
          const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
      ],
      decoration: _inputDeco(
        label: 'Monthly Installment',
        hint: 'e.g. 500.00',
        prefix: '৳',
        icon: Icons.payments_outlined,
      ),
      validator: (v) {
        if (v == null || v.trim().isEmpty) {
          return 'Monthly installment is required';
        }
        final val = double.tryParse(v.trim());
        if (val == null || val < 100) {
          return 'Minimum installment is ৳100.00';
        }
        return null;
      },
    );
  }

  Widget _buildTenureSection(ColorScheme cs) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          controller: _tenureCtrl,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          decoration: _inputDeco(
            label: 'Tenure (Months)',
            hint: '6 – 120',
            suffix: 'months',
            icon: Icons.calendar_month_outlined,
          ),
          onChanged: (v) {
            final parsed = int.tryParse(v);
            if (parsed != null && parsed >= 6 && parsed <= 120) {
              setState(() => _tenureSliderValue = parsed.toDouble());
            }
          },
          validator: (v) {
            if (v == null || v.trim().isEmpty) return 'Tenure is required';
            final val = int.tryParse(v.trim());
            if (val == null || val < 6 || val > 120) {
              return 'Tenure must be between 6 and 120 months';
            }
            return null;
          },
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            const Text('6m', style: TextStyle(fontSize: 11, color: Colors.grey)),
            Expanded(
              child: Slider(
                value: _tenureSliderValue,
                min: 6,
                max: 120,
                divisions: 114,
                label: '${_tenureSliderValue.toInt()} months',
                activeColor: cs.primary,
                onChanged: (v) {
                  setState(() {
                    _tenureSliderValue = v;
                    _tenureCtrl.text = v.toInt().toString();
                  });
                },
              ),
            ),
            const Text('120m',
                style: TextStyle(fontSize: 11, color: Colors.grey)),
          ],
        ),
      ],
    );
  }

  Widget _buildRateField(ColorScheme cs) {
    return TextFormField(
      controller: _rateCtrl,
      keyboardType:
          const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
      ],
      decoration: _inputDeco(
        label: 'Interest Rate',
        hint: '8.0',
        suffix: '% p.a.',
        icon: Icons.percent_rounded,
      ),
      validator: (v) {
        if (v == null || v.trim().isEmpty) return 'Interest rate is required';
        final val = double.tryParse(v.trim());
        if (val == null || val <= 0 || val > 30) {
          return 'Enter a valid rate (0 – 30%)';
        }
        return null;
      },
    );
  }


  // Widget _buildBranchCodeField(ColorScheme cs) {
  //   return TextFormField(
  //     controller: _branchCodeCtrl,
  //     textCapitalization: TextCapitalization.characters,
  //     decoration: _inputDeco(
  //       label: 'Branch Code',
  //       hint: 'e.g. BR001',
  //       icon: Icons.account_balance_outlined,
  //     ),
  //     validator: (v) {
  //       if (v == null || v.trim().isEmpty) return 'Branch code is required';
  //       return null;
  //     },
  //   );
  // }

Widget _buildBranchCodeField(ColorScheme cs) {
    return Consumer<BranchProvider>(
      builder: (ctx, branchProvider, _) {
        final branches = branchProvider.branches;
        final isLoading = branchProvider.isLoading;
        final hasError = branchProvider.hasError;

        if (_selectedBranch != null &&
            branches.isNotEmpty &&
            !branches.any((b) => b.id == _selectedBranch!.id)) {
          _selectedBranch = null;
        }

        if (hasError) {
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              border: Border.all(color: cs.error),
              borderRadius: BorderRadius.circular(10),
              color: cs.errorContainer.withOpacity(0.2),
            ),
            child: Row(
              children: [
                Icon(Icons.warning_amber_rounded, color: cs.error, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    branchProvider.errorMessage ?? 'Failed to load branches',
                    style: TextStyle(color: cs.error, fontSize: 13),
                  ),
                ),
                TextButton(
                  onPressed: () =>
                      branchProvider.fetchAllBranches(forceRefresh: true),
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
        }

        return DropdownButtonFormField<BranchResponseDTO>(
          value: _selectedBranch,
          isExpanded: true,
          decoration: _inputDeco(
            label: 'Branch',
            hint: isLoading ? 'Loading branches…' : 'Select your branch',
            icon: Icons.account_balance_outlined,
          ),
          items: branches.map((branch) {
            return DropdownMenuItem<BranchResponseDTO>(
              value: branch,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    branch.branchName,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    branch.branchCode,
                    style: TextStyle(
                      fontSize: 11,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
          selectedItemBuilder: (context) {
            return branches.map((branch) {
              return Text(
                '${branch.branchName}  ·  ${branch.branchCode}',
                overflow: TextOverflow.ellipsis,
              );
            }).toList();
          },
          onChanged: isLoading
              ? null
              : (branch) => setState(() => _selectedBranch = branch),
          validator: (_) =>
              _selectedBranch == null ? 'Please select a branch' : null,
        );
      },
    );
  }


  Widget _buildAutoDebitSection(ColorScheme cs) {
    return Card(
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        children: [
          SwitchListTile.adaptive(
            value: _autoDebitEnabled,
            activeColor: cs.primary,
            title: const Text(
              'Enable Auto Debit',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            subtitle: const Text(
              'Installments will be automatically debited from your linked account.',
              style: TextStyle(fontSize: 12),
            ),
            secondary: Icon(
              _autoDebitEnabled
                  ? Icons.link_rounded
                  : Icons.link_off_rounded,
              color: _autoDebitEnabled ? cs.primary : Colors.grey,
            ),
            onChanged: (v) => setState(() => _autoDebitEnabled = v),
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            child: _autoDebitEnabled
                ? Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    child: TextFormField(
                      controller: _linkedAccountCtrl,
                      decoration: _inputDeco(
                        label: 'Linked Account Number',
                        hint: 'Account to debit from',
                        icon: Icons.account_balance_wallet_outlined,
                      ),
                      validator: (v) {
                        if (_autoDebitEnabled &&
                            (v == null || v.trim().isEmpty)) {
                          return 'Account number required for auto debit';
                        }
                        return null;
                      },
                    ),
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }

  Widget _buildNomineeSection(ColorScheme cs) {
    return Card(
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _nomineeFirstCtrl,
                    decoration: _inputDeco(
                        label: 'First Name', hint: 'Nominee first name'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _nomineeLastCtrl,
                    decoration: _inputDeco(
                        label: 'Last Name', hint: 'Nominee last name'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _nomineeRelationCtrl,
              decoration: _inputDeco(
                label: 'Relationship',
                hint: 'e.g. Spouse, Child, Parent',
                icon: Icons.family_restroom_outlined,
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _nomineePhoneCtrl,
              keyboardType: TextInputType.phone,
              decoration: _inputDeco(
                label: 'Phone Number',
                hint: '+880 1XXX-XXXXXX',
                icon: Icons.phone_outlined,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTermsSection(ColorScheme cs) {
    return Card(
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: _termsAccepted ? cs.primary : Colors.transparent,
          width: 1.5,
        ),
      ),
      child: CheckboxListTile(
        value: _termsAccepted,
        activeColor: cs.primary,
        controlAffinity: ListTileControlAffinity.leading,
        onChanged: (v) => setState(() => _termsAccepted = v ?? false),
        title: RichText(
          text: TextSpan(
            style: Theme.of(context).textTheme.bodyMedium,
            children: [
              const TextSpan(
                  text: 'I agree to the '),
              TextSpan(
                text: 'DPS Terms and Conditions',
                style: TextStyle(
                  color: cs.primary,
                  fontWeight: FontWeight.w600,
                  decoration: TextDecoration.underline,
                ),
              ),
              const TextSpan(
                  text:
                      ' and understand that premature closure will incur a penalty.'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSubmitButton(ColorScheme cs) {
    return Consumer<DpsProvider>(
      builder: (ctx, provider, _) {
        final loading = _isSubmitting || provider.isLoading;
        return SizedBox(
          height: 52,
          width: double.infinity,
          child: FilledButton.icon(
            onPressed: (!_termsAccepted || loading) ? null : _submit,
            icon: loading
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white),
                  )
                : const Icon(Icons.savings_rounded),
            label: Text(
              loading ? 'Creating...' : 'Create DPS Account',
              style: const TextStyle(
                  fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ),
        );
      },
    );
  }

  // ─── Input decoration helper ──────────────────────────────────────────────

  InputDecoration _inputDeco({
    required String label,
    String? hint,
    String? prefix,
    String? suffix,
    IconData? icon,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixText: prefix,
      suffixText: suffix,
      prefixIcon: icon != null ? Icon(icon) : null,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
      filled: true,
      fillColor: Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.4),
    );
  }

  // ─── Info bottom sheet ────────────────────────────────────────────────────

  void _showInfoSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.savings_outlined,
                    color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 8),
                const Text('About DPS',
                    style: TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 16),
            const _InfoRow(
                icon: Icons.calendar_month,
                text: 'Minimum tenure: 6 months. Maximum: 120 months.'),
            const _InfoRow(
                icon: Icons.payments_outlined,
                text: 'Minimum monthly installment: ৳100.'),
            const _InfoRow(
                icon: Icons.trending_up,
                text:
                    'Interest is compounded monthly and paid at maturity.'),
            const _InfoRow(
                icon: Icons.warning_amber_outlined,
                text:
                    'Premature closure before maturity incurs a penalty charge.'),
            const _InfoRow(
                icon: Icons.autorenew,
                text:
                    'Enable auto debit to avoid missing installments and penalty charges.'),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

// ─── Maturity Preview Card ─────────────────────────────────────────────────────

class _MaturityPreviewCard extends StatelessWidget {
  final Animation<double> fadeAnimation;
  final NumberFormat currencyFmt;
  final DateFormat dateFmt;
  final int tenureMonths;

  const _MaturityPreviewCard({
    required this.fadeAnimation,
    required this.currencyFmt,
    required this.dateFmt,
    required this.tenureMonths,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Consumer<DpsProvider>(
      builder: (ctx, provider, _) {
        final calc = provider.maturityCalculation;
        final loading = provider.isLoading;

        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [cs.primary, cs.tertiary],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: cs.primary.withOpacity(0.3),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          padding: const EdgeInsets.all(20),
          child: loading
              ? const Center(
                  child: Column(
                    children: [
                      CircularProgressIndicator(color: Colors.white),
                      SizedBox(height: 8),
                      Text('Calculating...',
                          style: TextStyle(color: Colors.white70)),
                    ],
                  ),
                )
              : calc == null
                  ? Column(
                      children: [
                        Icon(Icons.calculate_outlined,
                            size: 36, color: Colors.white.withOpacity(0.7)),
                        const SizedBox(height: 8),
                        Text(
                          'Fill in installment, tenure & rate\nto see your projected maturity value.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              color: Colors.white.withOpacity(0.8),
                              fontSize: 13),
                        ),
                      ],
                    )
                  : FadeTransition(
                      opacity: fadeAnimation,
                      child: _PreviewContent(
                        calc: calc,
                        currencyFmt: currencyFmt,
                        dateFmt: dateFmt,
                        tenureMonths: tenureMonths,
                      ),
                    ),
        );
      },
    );
  }
}

class _PreviewContent extends StatelessWidget {
  final MaturityCalculationModel calc;
  final NumberFormat currencyFmt;
  final DateFormat dateFmt;
  final int tenureMonths;

  const _PreviewContent({
    required this.calc,
    required this.currencyFmt,
    required this.dateFmt,
    required this.tenureMonths,
  });

  @override
  Widget build(BuildContext context) {
    final maturityDate = DateTime.now()
        .add(Duration(days: (tenureMonths * 30.44).round()));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Maturity amount — hero
        const Text('Maturity Amount',
            style: TextStyle(color: Colors.white70, fontSize: 12)),
        const SizedBox(height: 4),
        Text(
          currencyFmt.format(calc.maturityAmount ?? 0),
          style: const TextStyle(
            color: Colors.white,
            fontSize: 26,
            fontWeight: FontWeight.bold,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 16),
        const Divider(color: Colors.white24),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _PreviewStat(
                label: 'Total Invested',
                value: currencyFmt.format(calc.totalDeposit ?? 0),
              ),
            ),
            Expanded(
              child: _PreviewStat(
                label: 'Interest Earned',
                value: currencyFmt.format(calc.interestEarned ?? 0),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            const Icon(Icons.event_rounded,
                color: Colors.white60, size: 14),
            const SizedBox(width: 6),
            Text(
              'Matures on ${dateFmt.format(maturityDate)}',
              style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 12,
                  fontStyle: FontStyle.italic),
            ),
          ],
        ),
      ],
    );
  }
}

class _PreviewStat extends StatelessWidget {
  final String label;
  final String value;

  const _PreviewStat({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style:
                const TextStyle(color: Colors.white60, fontSize: 11)),
        const SizedBox(height: 2),
        Text(value,
            style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 13)),
      ],
    );
  }
}

// ─── Section Header ────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? subtitle;
  final ColorScheme colorScheme;

  const _SectionHeader({
    required this.icon,
    required this.label,
    required this.colorScheme,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: colorScheme.primaryContainer,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 16, color: colorScheme.primary),
        ),
        const SizedBox(width: 10),
        Text(
          label,
          style: const TextStyle(
              fontSize: 15, fontWeight: FontWeight.w700),
        ),
        if (subtitle != null) ...[
          const SizedBox(width: 8),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              subtitle!,
              style: TextStyle(
                  fontSize: 10,
                  color: colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ],
    );
  }
}

// ─── Hero Banner ───────────────────────────────────────────────────────────────

class _HeroBanner extends StatelessWidget {
  final ColorScheme colorScheme;
  const _HeroBanner({required this.colorScheme});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: colorScheme.secondaryContainer.withOpacity(0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Row(
        children: [
          Icon(Icons.savings_rounded,
              color: colorScheme.secondary, size: 32),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Deposit Pension Scheme',
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onSecondaryContainer),
                ),
                const SizedBox(height: 2),
                Text(
                  'Save monthly. Grow steadily. Secure your future.',
                  style: TextStyle(
                      fontSize: 12,
                      color: colorScheme.onSecondaryContainer
                          .withOpacity(0.7)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Info Row ─────────────────────────────────────────────────────────────────

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String text;
  const _InfoRow({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon,
              size: 18,
              color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 12),
          Expanded(
              child: Text(text, style: const TextStyle(fontSize: 13))),
        ],
      ),
    );
  }
}
