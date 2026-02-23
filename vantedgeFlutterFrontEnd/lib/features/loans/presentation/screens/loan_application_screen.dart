import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import 'package:vantedge/core/routes/app_routes.dart';
import 'package:vantedge/features/accounts/data/models/account_list_item_dto.dart';
import 'package:vantedge/features/accounts/presentation/providers/account_provider.dart';
import 'package:vantedge/features/auth/presentation/providers/auth_provider.dart';
import 'package:vantedge/features/loans/data/models/loan_enums.dart';
import 'package:vantedge/features/loans/data/models/loan_application.dart';
import 'package:vantedge/features/loans/presentation/providers/loan_provider.dart';
import 'package:vantedge/features/loans/presentation/widgets/loan_enum_display_helpers.dart';
import 'package:vantedge/features/loans/presentation/widgets/loan_type_selector.dart';
import 'package:vantedge/features/loans/utils/loan_calculator.dart';
import 'package:vantedge/features/transactions/presentation/widgets/account_selector.dart';
import 'package:vantedge/shared/widgets/custom_app_bar.dart';
import 'package:vantedge/shared/widgets/custom_button.dart';

// ─── Constants ────────────────────────────────────────────────────────────────

const double _kMinAmount = 50000;
const double _kMaxAmount = 10000000;
const int _kMinTenure = 6;
const int _kMaxTenure = 360;
const int _kMinAge = 21;
const int _kMaxAge = 65;
const double _kMinRate = 5.0;
const double _kMaxRate = 25.0;
const double _kMinIncome = 1000;

// Suggested annual interest rate per loan type
const Map<LoanType, double> _kSuggestedRates = {
  LoanType.homeLoan: 8.5,
  LoanType.carLoan: 9.5,
  LoanType.personalLoan: 12.0,
  LoanType.educationLoan: 7.5,
  LoanType.businessLoan: 11.0,
  LoanType.goldLoan: 10.0,
  LoanType.industrialLoan: 10.5,
  LoanType.importLcLoan: 9.0,
  LoanType.workingCapitalLoan: 11.5,
};

// Loan types that require collateral (Step 3)
const Set<LoanType> _kSecuredTypes = {
  LoanType.homeLoan,
  LoanType.carLoan,
  LoanType.goldLoan,
  LoanType.industrialLoan,
  LoanType.importLcLoan,
};

// Loan types that show corporate / LC details (Step 4)
const Set<LoanType> _kCorporateTypes = {
  LoanType.businessLoan,
  LoanType.workingCapitalLoan,
  LoanType.importLcLoan,
};

const List<String> _kDocumentTypes = [
  'National ID / Passport',
  'Proof of Income (Payslip)',
  'Bank Statements (6 months)',
  'Tax Returns (last 2 years)',
  'Property Documents',
  'Vehicle Registration',
  'Business Registration Certificate',
  'Audited Financial Statements',
  'Collateral Valuation Report',
  'Trade Licence',
  'Letter of Credit (LC)',
  'Insurance Documents',
];

// ─── Screen ───────────────────────────────────────────────────────────────────

class LoanApplicationScreen extends StatefulWidget {
  const LoanApplicationScreen({super.key});

  @override
  State<LoanApplicationScreen> createState() => _LoanApplicationScreenState();
}

class _LoanApplicationScreenState extends State<LoanApplicationScreen> {
  final PageController _pageCtrl = PageController();

  // Form keys — one per visible step (indexes shift when steps are skipped)
  final _formKeys = List.generate(6, (_) => GlobalKey<FormState>());

  // ── Step 1: Loan Type & Amount ─────────────────────────────────────────────
  LoanType _loanType = LoanType.personalLoan;
  final _amountCtrl = TextEditingController();
  final _rateCtrl = TextEditingController();
  final _tenureCtrl = TextEditingController();
  final _purposeCtrl = TextEditingController();
  AccountListItemDTO? _selectedAccount;

  // ── Step 2: Personal Info ──────────────────────────────────────────────────
  final _ageCtrl = TextEditingController();
  EmploymentType _empType = EmploymentType.salaried;
  final _incomeCtrl = TextEditingController();
  final _existingEmiCtrl = TextEditingController(text: '0');

  // ── Step 3: Collateral ─────────────────────────────────────────────────────
  final _collateralTypeCtrl = TextEditingController();
  final _collateralValueCtrl = TextEditingController();
  final _collateralDescCtrl = TextEditingController();

  // ── Step 4: Corporate / LC ─────────────────────────────────────────────────
  ApplicantType _applicantType = ApplicantType.individual;
  final _industryCtrl = TextEditingController();
  final _bizRegCtrl = TextEditingController();
  final _bizTurnoverCtrl = TextEditingController();
  final _lcNumberCtrl = TextEditingController();
  final _beneficiaryNameCtrl = TextEditingController();
  final _beneficiaryBankCtrl = TextEditingController();
  final _lcAmountCtrl = TextEditingController();
  final _purposeOfLcCtrl = TextEditingController();
  final _paymentTermsCtrl = TextEditingController();
  DateTime? _lcExpiryDate;

  // ── Step 5: Documents ──────────────────────────────────────────────────────
  final Set<String> _selectedDocs = {};

  // ── Navigation state ───────────────────────────────────────────────────────
  int _currentStep = 0; // 0-based logical step index
  bool _isSubmitting = false;
  bool _isSuccess = false;

  // ── Computed properties ─────────────────────────────────────────────────────

  bool get _needsCollateral => _kSecuredTypes.contains(_loanType);
  bool get _needsCorporate => _kCorporateTypes.contains(_loanType);

  /// Builds the list of step indices that are actually shown for the
  /// current loan type.  Maximum 6, minimum 4.
  List<int> get _visibleStepSlots {
    // Slot 0=TypeAmount, 1=PersonalInfo, 2=Collateral, 3=Corporate, 4=Docs, 5=Review
    return [0, 1, if (_needsCollateral) 2, if (_needsCorporate) 3, 4, 5];
  }

  int get _totalVisibleSteps => _visibleStepSlots.length;

  /// Logical step → page index in the PageView (which always has 6 pages).
  int get _currentPageIndex => _visibleStepSlots[_currentStep];

  double get _parsedAmount =>
      double.tryParse(_amountCtrl.text.replaceAll(',', '')) ?? 0;
  double get _parsedRate => double.tryParse(_rateCtrl.text) ?? 0;
  int get _parsedTenure => int.tryParse(_tenureCtrl.text) ?? 0;

  LoanCalculationResult? get _emiResult {
    if (_parsedAmount <= 0 || _parsedRate <= 0 || _parsedTenure <= 0)
      return null;
    return LoanCalculator.calculate(
      principal: _parsedAmount,
      annualRate: _parsedRate,
      tenureMonths: _parsedTenure,
    );
  }

  static final _currFmt = NumberFormat.currency(
    symbol: '৳',
    decimalDigits: 2,
    locale: 'en_IN',
  );
  String _fmt(double v) => _currFmt.format(v);

  // ─── Lifecycle ─────────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    _rateCtrl.text = _kSuggestedRates[_loanType]!.toStringAsFixed(2);
    WidgetsBinding.instance.addPostFrameCallback((_) => _init());
  }

  void _init() {
    final ap = context.read<AccountProvider>();
    if (ap.accounts.isEmpty) ap.fetchMyAccounts();
  }

  @override
  void dispose() {
    _pageCtrl.dispose();
    for (final c in [
      _amountCtrl,
      _rateCtrl,
      _tenureCtrl,
      _purposeCtrl,
      _ageCtrl,
      _incomeCtrl,
      _existingEmiCtrl,
      _collateralTypeCtrl,
      _collateralValueCtrl,
      _collateralDescCtrl,
      _industryCtrl,
      _bizRegCtrl,
      _bizTurnoverCtrl,
      _lcNumberCtrl,
      _beneficiaryNameCtrl,
      _beneficiaryBankCtrl,
      _lcAmountCtrl,
      _purposeOfLcCtrl,
      _paymentTermsCtrl,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  // ─── Navigation ────────────────────────────────────────────────────────────

  void _advance() {
    final formKey = _formKeys[_currentPageIndex];
    if (!(formKey.currentState?.validate() ?? false)) return;

    // Extra guards for step 1
    if (_currentPageIndex == 0) {
      if (_selectedAccount == null) {
        _showWarning('Please select a disbursement account.');
        return;
      }
    }

    if (_currentStep < _totalVisibleSteps - 1) {
      setState(() => _currentStep++);
      _pageCtrl.animateToPage(
        _currentPageIndex,
        duration: const Duration(milliseconds: 320),
        curve: Curves.easeInOut,
      );
    } else {
      _submit();
    }
  }

  void _retreat() {
    if (_currentStep > 0) {
      setState(() => _currentStep--);
      _pageCtrl.animateToPage(
        _currentPageIndex,
        duration: const Duration(milliseconds: 320),
        curve: Curves.easeInOut,
      );
    } else {
      Navigator.of(context).pop();
    }
  }

  void _jumpToStep(int logicalStep) {
    setState(() => _currentStep = logicalStep);
    _pageCtrl.animateToPage(
      _visibleStepSlots[logicalStep],
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeInOut,
    );
  }

  void _onLoanTypeChanged(LoanType type) {
    setState(() {
      _loanType = type;
      _rateCtrl.text = _kSuggestedRates[type]!.toStringAsFixed(2);
      // Reset optional steps' data when type changes
      _collateralTypeCtrl.clear();
      _collateralValueCtrl.clear();
      _collateralDescCtrl.clear();
      _lcNumberCtrl.clear();
      _beneficiaryNameCtrl.clear();
      _beneficiaryBankCtrl.clear();
      _lcAmountCtrl.clear();
      _purposeOfLcCtrl.clear();
      _paymentTermsCtrl.clear();
      _lcExpiryDate = null;
    });
  }

  // ─── Submission ────────────────────────────────────────────────────────────

  Future<void> _submit() async {
    setState(() => _isSubmitting = true);

    final authProvider = context.read<AuthProvider>();
    final loanProvider = context.read<LoanProvider>();
    final user = authProvider.user;

    final request = LoanApplicationModel(
      customerId: user?.customerId ?? '',
      applicantName: user?.fullName ?? '',
      accountNumber: _selectedAccount!.accountNumber,
      loanType: _loanType,
      loanAmount: _parsedAmount,
      tenureMonths: _parsedTenure,
      annualInterestRate: _parsedRate,
      age: int.tryParse(_ageCtrl.text) ?? 0,
      monthlyIncome: double.tryParse(_incomeCtrl.text) ?? 0,
      employmentType: _empType,
      applicantType: _needsCorporate ? _applicantType : null,
      purpose: _purposeCtrl.text.trim().isEmpty
          ? null
          : _purposeCtrl.text.trim(),
      // Collateral
      collateralType: _needsCollateral && _collateralTypeCtrl.text.isNotEmpty
          ? _collateralTypeCtrl.text.trim()
          : null,
      collateralValue: _needsCollateral
          ? double.tryParse(_collateralValueCtrl.text)
          : null,
      collateralDescription:
          _needsCollateral && _collateralDescCtrl.text.isNotEmpty
          ? _collateralDescCtrl.text.trim()
          : null,
      // Corporate / LC
      industryType: _needsCorporate && _industryCtrl.text.isNotEmpty
          ? _industryCtrl.text.trim()
          : null,
      businessRegistrationNumber: _needsCorporate && _bizRegCtrl.text.isNotEmpty
          ? _bizRegCtrl.text.trim()
          : null,
      businessTurnover: _needsCorporate
          ? double.tryParse(_bizTurnoverCtrl.text)
          : null,
      lcNumber:
          _loanType == LoanType.importLcLoan && _lcNumberCtrl.text.isNotEmpty
          ? _lcNumberCtrl.text.trim()
          : null,
      beneficiaryName:
          _loanType == LoanType.importLcLoan &&
              _beneficiaryNameCtrl.text.isNotEmpty
          ? _beneficiaryNameCtrl.text.trim()
          : null,
      beneficiaryBank:
          _loanType == LoanType.importLcLoan &&
              _beneficiaryBankCtrl.text.isNotEmpty
          ? _beneficiaryBankCtrl.text.trim()
          : null,
      lcAmount: _loanType == LoanType.importLcLoan
          ? double.tryParse(_lcAmountCtrl.text)
          : null,
      purposeOfLC:
          _loanType == LoanType.importLcLoan && _purposeOfLcCtrl.text.isNotEmpty
          ? _purposeOfLcCtrl.text.trim()
          : null,
      paymentTerms:
          _loanType == LoanType.importLcLoan &&
              _paymentTermsCtrl.text.isNotEmpty
          ? _paymentTermsCtrl.text.trim()
          : null,
      lcExpiryDate: _lcExpiryDate,
      documentTypes: _selectedDocs.isEmpty ? null : _selectedDocs.toList(),
    );

    final success = await loanProvider.submitApplication(request);
    if (!mounted) return;

    setState(() => _isSubmitting = false);

    if (success) {
      setState(() => _isSuccess = true);
    } else {
      _showError(
        loanProvider.errorMessage ?? 'Application failed. Please try again.',
      );
    }
  }

  // ─── Helpers ───────────────────────────────────────────────────────────────

  void _showWarning(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: Theme.of(context).colorScheme.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  void _showError(String msg) => _showWarning(msg);

  InputDecoration _dec(
    ColorScheme cs, {
    required String label,
    String? hint,
    Widget? prefix,
    String? suffixText,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: prefix,
      suffixText: suffixText,
      filled: true,
      fillColor: cs.surface,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: cs.outlineVariant),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: cs.primary, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: cs.error),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: cs.error, width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    );
  }

  // ─── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    if (_isSuccess) {
      return _SuccessScreen(
        loanType: _loanType,
        amount: _parsedAmount,
        fmt: _fmt,
        onDone: () {
          Navigator.of(context).pushNamedAndRemoveUntil(
            AppRoutes.loans,
            (r) =>
                r.settings.name == AppRoutes.customerHome ||
                r.settings.name == AppRoutes.loanOfficerHome,
          );
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Loan application submitted successfully!'),
              backgroundColor: const Color(0xFF2E7D32),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          );
        },
      );
    }

    // Step labels for the progress indicator
    final stepLabels = _buildStepLabels();

    return Scaffold(
      backgroundColor: cs.surfaceContainerLowest,
      appBar: CustomAppBar(
        title: 'Loan Application',
        showNotifications: false,
        showLeading: true,
      ),
      body: Stack(
        children: [
          Column(
            children: [
              // ── Progress indicator ────────────────────────────────────────
              _StepProgressBar(
                currentStep: _currentStep,
                totalSteps: _totalVisibleSteps,
                stepLabels: stepLabels,
                accentColor: cs.primary,
              ),

              // ── EMI preview banner (shown after step 1 is filled) ─────────
              if (_currentStep > 0 && _emiResult != null)
                _EmiBanner(
                  result: _emiResult!,
                  fmt: _fmt,
                  theme: theme,
                  cs: cs,
                ),

              // ── PageView ──────────────────────────────────────────────────
              Expanded(
                child: PageView(
                  controller: _pageCtrl,
                  physics: const NeverScrollableScrollPhysics(),
                  children: [
                    _StepTypeAmount(
                      formKey: _formKeys[0],
                      loanType: _loanType,
                      amountCtrl: _amountCtrl,
                      rateCtrl: _rateCtrl,
                      tenureCtrl: _tenureCtrl,
                      purposeCtrl: _purposeCtrl,
                      selectedAccount: _selectedAccount,
                      emiResult: _emiResult,
                      fmt: _fmt,
                      dec: _dec,
                      onTypeChanged: _onLoanTypeChanged,
                      onAccountSelected: (a) =>
                          setState(() => _selectedAccount = a),
                    ),
                    _StepPersonalInfo(
                      formKey: _formKeys[1],
                      ageCtrl: _ageCtrl,
                      incomeCtrl: _incomeCtrl,
                      existingEmiCtrl: _existingEmiCtrl,
                      empType: _empType,
                      dec: _dec,
                      onEmpTypeChanged: (t) => setState(() => _empType = t),
                    ),
                    _StepCollateral(
                      formKey: _formKeys[2],
                      loanType: _loanType,
                      typeCtrl: _collateralTypeCtrl,
                      valueCtrl: _collateralValueCtrl,
                      descCtrl: _collateralDescCtrl,
                      dec: _dec,
                    ),
                    _StepCorporate(
                      formKey: _formKeys[3],
                      loanType: _loanType,
                      applicantType: _applicantType,
                      industryCtrl: _industryCtrl,
                      bizRegCtrl: _bizRegCtrl,
                      bizTurnoverCtrl: _bizTurnoverCtrl,
                      lcNumberCtrl: _lcNumberCtrl,
                      beneficiaryNameCtrl: _beneficiaryNameCtrl,
                      beneficiaryBankCtrl: _beneficiaryBankCtrl,
                      lcAmountCtrl: _lcAmountCtrl,
                      purposeOfLcCtrl: _purposeOfLcCtrl,
                      paymentTermsCtrl: _paymentTermsCtrl,
                      lcExpiryDate: _lcExpiryDate,
                      dec: _dec,
                      onApplicantTypeChanged: (t) =>
                          setState(() => _applicantType = t),
                      onLcExpiryPicked: (d) =>
                          setState(() => _lcExpiryDate = d),
                    ),
                    _StepDocuments(
                      formKey: _formKeys[4],
                      selectedDocs: _selectedDocs,
                      onToggle: (doc) => setState(() {
                        if (_selectedDocs.contains(doc)) {
                          _selectedDocs.remove(doc);
                        } else {
                          _selectedDocs.add(doc);
                        }
                      }),
                    ),
                    _StepReview(
                      loanType: _loanType,
                      amount: _parsedAmount,
                      rate: _parsedRate,
                      tenure: _parsedTenure,
                      purpose: _purposeCtrl.text.trim(),
                      accountNumber: _selectedAccount?.accountNumber ?? '',
                      age: int.tryParse(_ageCtrl.text) ?? 0,
                      empType: _empType,
                      income: double.tryParse(_incomeCtrl.text) ?? 0,
                      existingEmi: double.tryParse(_existingEmiCtrl.text) ?? 0,
                      collateralType: _collateralTypeCtrl.text.trim(),
                      collateralValue: double.tryParse(
                        _collateralValueCtrl.text,
                      ),
                      industry: _industryCtrl.text.trim(),
                      lcNumber: _lcNumberCtrl.text.trim(),
                      selectedDocs: _selectedDocs,
                      needsCollateral: _needsCollateral,
                      needsCorporate: _needsCorporate,
                      emiResult: _emiResult,
                      fmt: _fmt,
                      onEditSection: _jumpToStep,
                    ),
                  ],
                ),
              ),

              // ── Nav buttons ───────────────────────────────────────────────
              _NavButtons(
                currentStep: _currentStep,
                totalSteps: _totalVisibleSteps,
                isLast: _currentStep == _totalVisibleSteps - 1,
                onBack: _retreat,
                onNext: _advance,
              ),
            ],
          ),

          // ── Loading overlay ───────────────────────────────────────────────
          if (_isSubmitting)
            Container(
              color: Colors.black45,
              alignment: Alignment.center,
              child: Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 40, vertical: 28),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 16),
                      Text(
                        'Submitting application…',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  List<String> _buildStepLabels() {
    final labels = <String>[];
    for (final slot in _visibleStepSlots) {
      switch (slot) {
        case 0:
          labels.add('Type & Amount');
          break;
        case 1:
          labels.add('Personal');
          break;
        case 2:
          labels.add('Collateral');
          break;
        case 3:
          labels.add('Corporate');
          break;
        case 4:
          labels.add('Documents');
          break;
        case 5:
          labels.add('Review');
          break;
      }
    }
    return labels;
  }
}

// ─── Step Progress Bar ────────────────────────────────────────────────────────

class _StepProgressBar extends StatelessWidget {
  final int currentStep;
  final int totalSteps;
  final List<String> stepLabels;
  final Color accentColor;

  const _StepProgressBar({
    required this.currentStep,
    required this.totalSteps,
    required this.stepLabels,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Container(
      color: cs.surface,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Step fraction label
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                stepLabels[currentStep],
                style: theme.textTheme.titleSmall?.copyWith(
                  color: accentColor,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                'Step ${currentStep + 1} of $totalSteps',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: cs.onSurfaceVariant,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Step dots row
          Row(
            children: List.generate(totalSteps, (i) {
              final isCompleted = i < currentStep;
              final isCurrent = i == currentStep;
              return Expanded(
                child: Padding(
                  padding: EdgeInsets.only(right: i < totalSteps - 1 ? 4 : 0),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    height: 4,
                    decoration: BoxDecoration(
                      color: isCompleted || isCurrent
                          ? accentColor
                          : cs.outlineVariant.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}

// ─── EMI Banner ───────────────────────────────────────────────────────────────

class _EmiBanner extends StatelessWidget {
  final LoanCalculationResult result;
  final String Function(double) fmt;
  final ThemeData theme;
  final ColorScheme cs;

  const _EmiBanner({
    required this.result,
    required this.fmt,
    required this.theme,
    required this.cs,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: cs.primaryContainer,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _BannerCell(
            label: 'Monthly EMI',
            value: fmt(result.emi),
            bold: true,
            color: cs.onPrimaryContainer,
            theme: theme,
          ),
          _BannerCell(
            label: 'Total Interest',
            value: fmt(result.totalInterest),
            color: cs.onPrimaryContainer,
            theme: theme,
          ),
          _BannerCell(
            label: 'Total Payable',
            value: fmt(result.totalAmount),
            color: cs.onPrimaryContainer,
            theme: theme,
          ),
        ],
      ),
    );
  }
}

class _BannerCell extends StatelessWidget {
  final String label;
  final String value;
  final bool bold;
  final Color color;
  final ThemeData theme;

  const _BannerCell({
    required this.label,
    required this.value,
    required this.color,
    required this.theme,
    this.bold = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          label,
          style: theme.textTheme.labelSmall?.copyWith(
            color: color.withOpacity(0.8),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: theme.textTheme.labelMedium?.copyWith(
            color: color,
            fontWeight: bold ? FontWeight.w800 : FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

// ─── Nav Buttons ─────────────────────────────────────────────────────────────

class _NavButtons extends StatelessWidget {
  final int currentStep;
  final int totalSteps;
  final bool isLast;
  final VoidCallback onBack;
  final VoidCallback onNext;

  const _NavButtons({
    required this.currentStep,
    required this.totalSteps,
    required this.isLast,
    required this.onBack,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      color: cs.surface,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      child: Row(
        children: [
          // Back button
          Expanded(
            child: CustomButton(
              text: currentStep == 0 ? 'Cancel' : 'Back',
              variant: ButtonVariant.outlined,
              icon: Icon(
                currentStep == 0
                    ? Icons.close_rounded
                    : Icons.arrow_back_rounded,
              ),
              onPressed: onBack,
            ),
          ),
          const SizedBox(width: 12),
          // Next / Submit button
          Expanded(
            flex: 2,
            child: CustomButton(
              text: isLast ? 'Submit Application' : 'Continue',
              icon: Icon(
                isLast
                    ? Icons.check_circle_rounded
                    : Icons.arrow_forward_rounded,
              ),
              onPressed: onNext,
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// STEP 1 — Loan Type & Amount
// ═══════════════════════════════════════════════════════════════════════════════

class _StepTypeAmount extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final LoanType loanType;
  final TextEditingController amountCtrl;
  final TextEditingController rateCtrl;
  final TextEditingController tenureCtrl;
  final TextEditingController purposeCtrl;
  final AccountListItemDTO? selectedAccount;
  final LoanCalculationResult? emiResult;
  final String Function(double) fmt;
  final InputDecoration Function(
    ColorScheme, {
    required String label,
    String? hint,
    Widget? prefix,
    String? suffixText,
  })
  dec;
  final ValueChanged<LoanType> onTypeChanged;
  final ValueChanged<AccountListItemDTO> onAccountSelected;

  const _StepTypeAmount({
    required this.formKey,
    required this.loanType,
    required this.amountCtrl,
    required this.rateCtrl,
    required this.tenureCtrl,
    required this.purposeCtrl,
    required this.selectedAccount,
    required this.emiResult,
    required this.fmt,
    required this.dec,
    required this.onTypeChanged,
    required this.onAccountSelected,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final accounts = context.watch<AccountProvider>().accounts;

    return Form(
      key: formKey,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        children: [
          // ── Loan Type ────────────────────────────────────────────────────
          _SectionHeader(icon: Icons.category_rounded, label: 'Loan Type'),
          const SizedBox(height: 10),
          LoanTypeSelectorWidget(
            selectedType: loanType,
            onTypeSelected: onTypeChanged,
          ),
          const SizedBox(height: 20),

          // ── Disbursement Account ─────────────────────────────────────────
          _SectionHeader(
            icon: Icons.account_balance_wallet_rounded,
            label: 'Disbursement Account',
          ),
          const SizedBox(height: 10),
          AccountSelectorWidget(
            label: 'Select Account',
            accounts: accounts,
            selectedAccount: selectedAccount,
            onSelected: onAccountSelected,
            validator: (v) =>
                v == null ? 'Please select a disbursement account.' : null,
          ),
          const SizedBox(height: 20),

          // ── Loan Amount ──────────────────────────────────────────────────
          _SectionHeader(icon: Icons.payments_rounded, label: 'Loan Details'),
          const SizedBox(height: 10),
          TextFormField(
            controller: amountCtrl,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
            ],
            textInputAction: TextInputAction.next,
            decoration: dec(
              cs,
              label: 'Loan Amount',
              hint: '50,000 – 10,000,000',
              prefix: const Icon(Icons.currency_exchange_rounded),
              suffixText: '৳',
            ),
            validator: (v) {
              final amount = double.tryParse(v ?? '');
              if (amount == null || amount <= 0)
                return 'Please enter a valid amount.';
              if (amount < _kMinAmount)
                return 'Minimum loan amount is ৳${_kMinAmount.toStringAsFixed(0)}.';
              if (amount > _kMaxAmount)
                return 'Maximum loan amount is ৳${_kMaxAmount.toStringAsFixed(0)}.';
              return null;
            },
          ),
          const SizedBox(height: 14),

          // Annual Rate
          TextFormField(
            controller: rateCtrl,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
            ],
            textInputAction: TextInputAction.next,
            decoration: dec(
              cs,
              label: 'Annual Interest Rate',
              hint:
                  '${_kMinRate.toStringAsFixed(1)} – ${_kMaxRate.toStringAsFixed(1)}',
              prefix: Icon(loanType.icon, color: loanType.color),
              suffixText: '%',
            ),
            validator: (v) {
              final rate = double.tryParse(v ?? '');
              if (rate == null) return 'Please enter a valid interest rate.';
              if (rate < _kMinRate)
                return 'Minimum rate is ${_kMinRate.toStringAsFixed(1)}%.';
              if (rate > _kMaxRate)
                return 'Maximum rate is ${_kMaxRate.toStringAsFixed(1)}%.';
              return null;
            },
          ),
          const SizedBox(height: 6),
          Text(
            'Suggested rate for ${loanType.displayName}: '
            '${_kSuggestedRates[loanType]!.toStringAsFixed(1)}% p.a. — editable within $_kMinRate–$_kMaxRate%.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: cs.onSurfaceVariant,
              fontStyle: FontStyle.italic,
            ),
          ),
          const SizedBox(height: 14),

          // Tenure
          TextFormField(
            controller: tenureCtrl,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            textInputAction: TextInputAction.next,
            decoration: dec(
              cs,
              label: 'Tenure',
              hint: '$_kMinTenure – $_kMaxTenure months',
              prefix: const Icon(Icons.calendar_month_rounded),
              suffixText: 'months',
            ),
            validator: (v) {
              final t = int.tryParse(v ?? '');
              if (t == null || t <= 0) return 'Please enter a valid tenure.';
              if (t < _kMinTenure)
                return 'Minimum tenure is $_kMinTenure months.';
              if (t > _kMaxTenure)
                return 'Maximum tenure is $_kMaxTenure months.';
              return null;
            },
          ),
          const SizedBox(height: 14),

          // Purpose
          TextFormField(
            controller: purposeCtrl,
            maxLines: 3,
            maxLength: 500,
            textCapitalization: TextCapitalization.sentences,
            decoration: dec(
              cs,
              label: 'Purpose (optional)',
              hint: 'Briefly describe the purpose of this loan…',
              prefix: const Icon(Icons.edit_note_rounded),
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// STEP 2 — Personal Info
// ═══════════════════════════════════════════════════════════════════════════════

class _StepPersonalInfo extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController ageCtrl;
  final TextEditingController incomeCtrl;
  final TextEditingController existingEmiCtrl;
  final EmploymentType empType;
  final InputDecoration Function(
    ColorScheme, {
    required String label,
    String? hint,
    Widget? prefix,
    String? suffixText,
  })
  dec;
  final ValueChanged<EmploymentType> onEmpTypeChanged;

  const _StepPersonalInfo({
    required this.formKey,
    required this.ageCtrl,
    required this.incomeCtrl,
    required this.existingEmiCtrl,
    required this.empType,
    required this.dec,
    required this.onEmpTypeChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Form(
      key: formKey,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        children: [
          _SectionHeader(
            icon: Icons.person_rounded,
            label: 'Personal Information',
          ),
          const SizedBox(height: 12),

          // Age
          TextFormField(
            controller: ageCtrl,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            textInputAction: TextInputAction.next,
            decoration: dec(
              cs,
              label: 'Age',
              hint: '$_kMinAge – $_kMaxAge years',
              prefix: const Icon(Icons.cake_rounded),
              suffixText: 'years',
            ),
            validator: (v) {
              final age = int.tryParse(v ?? '');
              if (age == null) return 'Please enter your age.';
              if (age < _kMinAge)
                return 'Minimum eligible age is $_kMinAge years.';
              if (age > _kMaxAge)
                return 'Maximum eligible age is $_kMaxAge years.';
              return null;
            },
          ),
          const SizedBox(height: 14),

          // Employment Type
          Text(
            'Employment Type',
            style: theme.textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.w600,
              color: cs.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          ...EmploymentType.values.map((type) {
            return RadioListTile<EmploymentType>(
              value: type,
              groupValue: empType,
              title: Text(type.displayName, style: theme.textTheme.bodyMedium),
              activeColor: cs.primary,
              contentPadding: EdgeInsets.zero,
              onChanged: (v) {
                if (v != null) onEmpTypeChanged(v);
              },
            );
          }),
          const SizedBox(height: 6),

          // Monthly Income
          TextFormField(
            controller: incomeCtrl,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
            ],
            textInputAction: TextInputAction.next,
            decoration: dec(
              cs,
              label: 'Monthly Income',
              hint: 'Minimum ৳${_kMinIncome.toStringAsFixed(0)}',
              prefix: const Icon(Icons.account_balance_wallet_rounded),
              suffixText: '৳/mo',
            ),
            validator: (v) {
              final income = double.tryParse(v ?? '');
              if (income == null || income <= 0)
                return 'Please enter your monthly income.';
              if (income < _kMinIncome)
                return 'Minimum monthly income is ৳${_kMinIncome.toStringAsFixed(0)}.';
              return null;
            },
          ),
          const SizedBox(height: 14),

          // Existing EMI
          TextFormField(
            controller: existingEmiCtrl,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
            ],
            textInputAction: TextInputAction.done,
            decoration: dec(
              cs,
              label: 'Existing Monthly EMI',
              hint: 'Enter 0 if none',
              prefix: const Icon(Icons.credit_score_rounded),
              suffixText: '৳/mo',
            ),
            validator: (v) {
              if (v == null || v.isEmpty) return null;
              final emi = double.tryParse(v);
              if (emi == null || emi < 0)
                return 'Please enter a valid EMI amount.';
              return null;
            },
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: cs.secondaryContainer,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline_rounded,
                  size: 16,
                  color: cs.onSecondaryContainer,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Debt-to-income ratio must be under 50%. Include all current loan EMIs.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: cs.onSecondaryContainer,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// STEP 3 — Collateral Details (secured loans only)
// ═══════════════════════════════════════════════════════════════════════════════

class _StepCollateral extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final LoanType loanType;
  final TextEditingController typeCtrl;
  final TextEditingController valueCtrl;
  final TextEditingController descCtrl;
  final InputDecoration Function(
    ColorScheme, {
    required String label,
    String? hint,
    Widget? prefix,
    String? suffixText,
  })
  dec;

  const _StepCollateral({
    required this.formKey,
    required this.loanType,
    required this.typeCtrl,
    required this.valueCtrl,
    required this.descCtrl,
    required this.dec,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Form(
      key: formKey,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        children: [
          _SectionHeader(
            icon: Icons.security_rounded,
            label: 'Collateral Details',
          ),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: cs.primaryContainer,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.shield_rounded,
                  size: 16,
                  color: cs.onPrimaryContainer,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '${loanType.displayName} is a secured loan. '
                    'Collateral must be at least 120% of the loan amount.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: cs.onPrimaryContainer,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Collateral Type
          TextFormField(
            controller: typeCtrl,
            textCapitalization: TextCapitalization.words,
            textInputAction: TextInputAction.next,
            decoration: dec(
              cs,
              label: 'Collateral Type',
              hint: 'e.g. Property, Vehicle, Gold Ornaments',
              prefix: const Icon(Icons.apartment_rounded),
            ),
            validator: (v) {
              if (v == null || v.trim().isEmpty)
                return 'Collateral type is required.';
              return null;
            },
          ),
          const SizedBox(height: 14),

          // Collateral Value
          TextFormField(
            controller: valueCtrl,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
            ],
            textInputAction: TextInputAction.next,
            decoration: dec(
              cs,
              label: 'Estimated Collateral Value',
              prefix: const Icon(Icons.price_check_rounded),
              suffixText: '৳',
            ),
            validator: (v) {
              final val = double.tryParse(v ?? '');
              if (val == null || val <= 0)
                return 'Please enter the estimated collateral value.';
              return null;
            },
          ),
          const SizedBox(height: 14),

          // Collateral Description
          TextFormField(
            controller: descCtrl,
            maxLines: 4,
            maxLength: 1000,
            textCapitalization: TextCapitalization.sentences,
            decoration: dec(
              cs,
              label: 'Collateral Description',
              hint:
                  'Provide details — location, registration number, purity, etc.',
              prefix: const Icon(Icons.description_rounded),
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// STEP 4 — Corporate / LC Details
// ═══════════════════════════════════════════════════════════════════════════════

class _StepCorporate extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final LoanType loanType;
  final ApplicantType applicantType;
  final TextEditingController industryCtrl;
  final TextEditingController bizRegCtrl;
  final TextEditingController bizTurnoverCtrl;
  final TextEditingController lcNumberCtrl;
  final TextEditingController beneficiaryNameCtrl;
  final TextEditingController beneficiaryBankCtrl;
  final TextEditingController lcAmountCtrl;
  final TextEditingController purposeOfLcCtrl;
  final TextEditingController paymentTermsCtrl;
  final DateTime? lcExpiryDate;
  final InputDecoration Function(
    ColorScheme, {
    required String label,
    String? hint,
    Widget? prefix,
    String? suffixText,
  })
  dec;
  final ValueChanged<ApplicantType> onApplicantTypeChanged;
  final ValueChanged<DateTime> onLcExpiryPicked;

  const _StepCorporate({
    required this.formKey,
    required this.loanType,
    required this.applicantType,
    required this.industryCtrl,
    required this.bizRegCtrl,
    required this.bizTurnoverCtrl,
    required this.lcNumberCtrl,
    required this.beneficiaryNameCtrl,
    required this.beneficiaryBankCtrl,
    required this.lcAmountCtrl,
    required this.purposeOfLcCtrl,
    required this.paymentTermsCtrl,
    required this.lcExpiryDate,
    required this.dec,
    required this.onApplicantTypeChanged,
    required this.onLcExpiryPicked,
  });

  bool get _isImportLc => loanType == LoanType.importLcLoan;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Form(
      key: formKey,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        children: [
          _SectionHeader(
            icon: Icons.business_center_rounded,
            label: 'Corporate Details',
          ),
          const SizedBox(height: 12),

          // Applicant Type
          Text(
            'Applicant Type',
            style: theme.textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          SegmentedButton<ApplicantType>(
            segments: const [
              ButtonSegment(
                value: ApplicantType.individual,
                icon: Icon(Icons.person_rounded),
                label: Text('Individual'),
              ),
              ButtonSegment(
                value: ApplicantType.corporate,
                icon: Icon(Icons.corporate_fare_rounded),
                label: Text('Corporate'),
              ),
            ],
            selected: {applicantType},
            onSelectionChanged: (s) => onApplicantTypeChanged(s.first),
          ),
          const SizedBox(height: 16),

          // Business fields
          TextFormField(
            controller: industryCtrl,
            textCapitalization: TextCapitalization.words,
            textInputAction: TextInputAction.next,
            decoration: dec(
              cs,
              label: 'Industry Type',
              hint: 'e.g. Manufacturing, Retail, IT',
              prefix: const Icon(Icons.factory_rounded),
            ),
            validator: (v) => (v == null || v.trim().isEmpty)
                ? 'Industry type is required.'
                : null,
          ),
          const SizedBox(height: 14),

          TextFormField(
            controller: bizRegCtrl,
            textCapitalization: TextCapitalization.characters,
            textInputAction: TextInputAction.next,
            decoration: dec(
              cs,
              label: 'Business Registration Number',
              prefix: const Icon(Icons.badge_rounded),
            ),
          ),
          const SizedBox(height: 14),

          TextFormField(
            controller: bizTurnoverCtrl,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
            ],
            textInputAction: TextInputAction.next,
            decoration: dec(
              cs,
              label: 'Annual Business Turnover',
              prefix: const Icon(Icons.trending_up_rounded),
              suffixText: '৳',
            ),
          ),

          // ── Import LC fields ─────────────────────────────────────────────
          if (_isImportLc) ...[
            const SizedBox(height: 20),
            _SectionHeader(
              icon: Icons.local_shipping_rounded,
              label: 'Letter of Credit Details',
            ),
            const SizedBox(height: 12),

            TextFormField(
              controller: lcNumberCtrl,
              textCapitalization: TextCapitalization.characters,
              textInputAction: TextInputAction.next,
              decoration: dec(
                cs,
                label: 'LC Number',
                prefix: const Icon(Icons.receipt_rounded),
              ),
              validator: (v) => _isImportLc && (v == null || v.trim().isEmpty)
                  ? 'LC number is required for Import LC loans.'
                  : null,
            ),
            const SizedBox(height: 14),

            TextFormField(
              controller: beneficiaryNameCtrl,
              textCapitalization: TextCapitalization.words,
              textInputAction: TextInputAction.next,
              decoration: dec(
                cs,
                label: 'Beneficiary Name',
                prefix: const Icon(Icons.person_outline_rounded),
              ),
            ),
            const SizedBox(height: 14),

            TextFormField(
              controller: beneficiaryBankCtrl,
              textCapitalization: TextCapitalization.words,
              textInputAction: TextInputAction.next,
              decoration: dec(
                cs,
                label: 'Beneficiary Bank',
                prefix: const Icon(Icons.account_balance_rounded),
              ),
            ),
            const SizedBox(height: 14),

            TextFormField(
              controller: lcAmountCtrl,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
              ],
              textInputAction: TextInputAction.next,
              decoration: dec(
                cs,
                label: 'LC Amount',
                prefix: const Icon(Icons.paid_rounded),
                suffixText: '৳',
              ),
            ),
            const SizedBox(height: 14),

            // LC Expiry Date
            InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate:
                      lcExpiryDate ??
                      DateTime.now().add(const Duration(days: 90)),
                  firstDate: DateTime.now(),
                  lastDate: DateTime.now().add(const Duration(days: 3650)),
                );
                if (picked != null) onLcExpiryPicked(picked);
              },
              child: InputDecorator(
                decoration: dec(
                  cs,
                  label: 'LC Expiry Date',
                  prefix: const Icon(Icons.event_rounded),
                ),
                child: Text(
                  lcExpiryDate != null
                      ? DateFormat('dd MMM yyyy').format(lcExpiryDate!)
                      : 'Tap to select date',
                  style: TextStyle(
                    color: lcExpiryDate != null
                        ? Theme.of(context).colorScheme.onSurface
                        : Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 14),

            TextFormField(
              controller: purposeOfLcCtrl,
              maxLines: 2,
              textCapitalization: TextCapitalization.sentences,
              decoration: dec(
                cs,
                label: 'Purpose of LC',
                hint: 'e.g. Import of raw materials',
                prefix: const Icon(Icons.notes_rounded),
              ),
            ),
            const SizedBox(height: 14),

            TextFormField(
              controller: paymentTermsCtrl,
              textCapitalization: TextCapitalization.sentences,
              decoration: dec(
                cs,
                label: 'Payment Terms',
                hint: 'e.g. Sight LC, 90 days Usance',
                prefix: const Icon(Icons.handshake_rounded),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// STEP 5 — Documents
// ═══════════════════════════════════════════════════════════════════════════════

class _StepDocuments extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final Set<String> selectedDocs;
  final ValueChanged<String> onToggle;

  const _StepDocuments({
    required this.formKey,
    required this.selectedDocs,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Form(
      key: formKey,
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _SectionHeader(
                    icon: Icons.folder_rounded,
                    label: 'Required Documents',
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Select all document types you will be providing with your application.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: cs.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (selectedDocs.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: cs.errorContainer,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.warning_amber_rounded,
                            size: 16,
                            color: cs.onErrorContainer,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Please select at least one document type.',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: cs.onErrorContainer,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),
          SliverList(
            delegate: SliverChildBuilderDelegate((context, index) {
              final doc = _kDocumentTypes[index];
              final isSelected = selectedDocs.contains(doc);
              return Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 2,
                ),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? cs.primaryContainer
                        : cs.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected
                          ? cs.primary
                          : cs.outlineVariant.withOpacity(0.4),
                    ),
                  ),
                  child: CheckboxListTile(
                    value: isSelected,
                    onChanged: (_) => onToggle(doc),
                    title: Text(
                      doc,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: isSelected
                            ? FontWeight.w600
                            : FontWeight.normal,
                        color: isSelected
                            ? cs.onPrimaryContainer
                            : cs.onSurface,
                      ),
                    ),
                    activeColor: cs.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                  ),
                ),
              );
            }, childCount: _kDocumentTypes.length),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 24)),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// STEP 6 — Review & Submit
// ═══════════════════════════════════════════════════════════════════════════════

class _StepReview extends StatelessWidget {
  final LoanType loanType;
  final double amount;
  final double rate;
  final int tenure;
  final String purpose;
  final String accountNumber;
  final int age;
  final EmploymentType empType;
  final double income;
  final double existingEmi;
  final String collateralType;
  final double? collateralValue;
  final String industry;
  final String lcNumber;
  final Set<String> selectedDocs;
  final bool needsCollateral;
  final bool needsCorporate;
  final LoanCalculationResult? emiResult;
  final String Function(double) fmt;
  final void Function(int logicalStep) onEditSection;

  const _StepReview({
    required this.loanType,
    required this.amount,
    required this.rate,
    required this.tenure,
    required this.purpose,
    required this.accountNumber,
    required this.age,
    required this.empType,
    required this.income,
    required this.existingEmi,
    required this.collateralType,
    required this.collateralValue,
    required this.industry,
    required this.lcNumber,
    required this.selectedDocs,
    required this.needsCollateral,
    required this.needsCorporate,
    required this.emiResult,
    required this.fmt,
    required this.onEditSection,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final color = loanType.color;

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Loan hero ───────────────────────────────────────────────
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [color, color.withOpacity(0.75)],
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          loanType.icon,
                          color: Colors.white,
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              loanType.displayName,
                              style: theme.textTheme.titleMedium?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            Text(
                              fmt(amount),
                              style: theme.textTheme.headlineSmall?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // ── EMI summary ──────────────────────────────────────────────
                if (emiResult != null) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: cs.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _ReviewStat(
                          label: 'Monthly EMI',
                          value: fmt(emiResult!.emi),
                          theme: theme,
                          cs: cs,
                          bold: true,
                        ),
                        _ReviewStat(
                          label: 'Total Interest',
                          value: fmt(emiResult!.totalInterest),
                          theme: theme,
                          cs: cs,
                        ),
                        _ReviewStat(
                          label: 'Total Payable',
                          value: fmt(emiResult!.totalAmount),
                          theme: theme,
                          cs: cs,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ],
            ),
          ),
        ),

        // ── Section cards ────────────────────────────────────────────────────
        SliverList(
          delegate: SliverChildListDelegate([
            _ReviewSection(
              title: 'Loan Type & Amount',
              icon: Icons.payments_rounded,
              onEdit: () => onEditSection(0),
              rows: [
                _ReviewRow('Loan Type', loanType.displayName),
                _ReviewRow('Principal Amount', fmt(amount)),
                _ReviewRow('Annual Rate', '${rate.toStringAsFixed(2)}%'),
                _ReviewRow('Tenure', '$tenure months'),
                _ReviewRow(
                  'Disbursement Account',
                  accountNumber.isNotEmpty
                      ? '•••• ${accountNumber.substring(accountNumber.length > 4 ? accountNumber.length - 4 : 0)}'
                      : '—',
                ),
                if (purpose.isNotEmpty) _ReviewRow('Purpose', purpose),
              ],
            ),
            _ReviewSection(
              title: 'Personal Information',
              icon: Icons.person_rounded,
              onEdit: () => onEditSection(1),
              rows: [
                _ReviewRow('Age', '$age years'),
                _ReviewRow('Employment Type', empType.displayName),
                _ReviewRow('Monthly Income', fmt(income)),
                _ReviewRow('Existing EMI', fmt(existingEmi)),
              ],
            ),
            if (needsCollateral)
              _ReviewSection(
                title: 'Collateral Details',
                icon: Icons.security_rounded,
                onEdit: () {
                  // Find the logical step index for collateral (slot 2)
                  onEditSection(2);
                },
                rows: [
                  _ReviewRow(
                    'Collateral Type',
                    collateralType.isNotEmpty ? collateralType : '—',
                  ),
                  _ReviewRow(
                    'Collateral Value',
                    collateralValue != null ? fmt(collateralValue!) : '—',
                  ),
                ],
              ),
            if (needsCorporate)
              _ReviewSection(
                title: 'Corporate / LC Details',
                icon: Icons.business_center_rounded,
                onEdit: () => onEditSection(needsCollateral ? 3 : 2),
                rows: [
                  _ReviewRow('Industry', industry.isNotEmpty ? industry : '—'),
                  if (lcNumber.isNotEmpty) _ReviewRow('LC Number', lcNumber),
                ],
              ),
            _ReviewSection(
              title: 'Documents Selected',
              icon: Icons.folder_rounded,
              onEdit: () {
                int docStep = 2;
                if (needsCollateral) docStep++;
                if (needsCorporate) docStep++;
                onEditSection(docStep);
              },
              rows: selectedDocs.isEmpty
                  ? [_ReviewRow('Documents', 'None selected')]
                  : selectedDocs.map((d) => _ReviewRow('', d)).toList(),
            ),
            const SizedBox(height: 8),
            // Terms note
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'By submitting, you confirm that all provided information '
                'is accurate and agree to the bank\'s terms and conditions.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  fontStyle: FontStyle.italic,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 24),
          ]),
        ),
      ],
    );
  }
}

class _ReviewSection extends StatelessWidget {
  final String title;
  final IconData icon;
  final VoidCallback onEdit;
  final List<_ReviewRow> rows;

  const _ReviewSection({
    required this.title,
    required this.icon,
    required this.onEdit,
    required this.rows,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Card(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(color: cs.outlineVariant.withOpacity(0.5)),
        ),
        child: Column(
          children: [
            // Header row
            ListTile(
              leading: Icon(icon, color: cs.primary, size: 20),
              title: Text(
                title,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              trailing: TextButton.icon(
                onPressed: onEdit,
                icon: const Icon(Icons.edit_rounded, size: 15),
                label: const Text('Edit'),
                style: TextButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                ),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 0,
              ),
            ),
            const Divider(height: 1, indent: 14, endIndent: 14),
            // Data rows
            ...rows.map(
              (row) => Padding(
                padding: const EdgeInsets.fromLTRB(14, 8, 14, 0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (row.label.isNotEmpty) ...[
                      SizedBox(
                        width: 130,
                        child: Text(
                          row.label,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: cs.onSurfaceVariant,
                          ),
                        ),
                      ),
                      Expanded(
                        child: Text(
                          row.value,
                          style: theme.textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: cs.onSurface,
                          ),
                        ),
                      ),
                    ] else
                      Expanded(
                        child: Row(
                          children: [
                            const Icon(
                              Icons.check_rounded,
                              size: 14,
                              color: Color(0xFF2E7D32),
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                row.value,
                                style: theme.textTheme.bodySmall,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }
}

class _ReviewRow {
  final String label;
  final String value;
  const _ReviewRow(this.label, this.value);
}

class _ReviewStat extends StatelessWidget {
  final String label;
  final String value;
  final bool bold;
  final ThemeData theme;
  final ColorScheme cs;

  const _ReviewStat({
    required this.label,
    required this.value,
    required this.theme,
    required this.cs,
    this.bold = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          label,
          style: theme.textTheme.labelSmall?.copyWith(
            color: cs.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: theme.textTheme.labelMedium?.copyWith(
            fontWeight: bold ? FontWeight.w800 : FontWeight.w600,
            color: cs.onSurface,
          ),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// SUCCESS SCREEN
// ═══════════════════════════════════════════════════════════════════════════════

class _SuccessScreen extends StatelessWidget {
  final LoanType loanType;
  final double amount;
  final String Function(double) fmt;
  final VoidCallback onDone;

  const _SuccessScreen({
    required this.loanType,
    required this.amount,
    required this.fmt,
    required this.onDone,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Scaffold(
      backgroundColor: cs.surfaceContainerLowest,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Success icon
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: const Color(0xFFC8E6C9),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check_circle_rounded,
                    color: Color(0xFF2E7D32),
                    size: 60,
                  ),
                ),
                const SizedBox(height: 24),

                Text(
                  'Application Submitted!',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: cs.onSurface,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),

                Text(
                  'Your ${loanType.displayName} application for ${fmt(amount)} '
                  'has been received and is pending review.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: cs.onSurfaceVariant,
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'You can track the status in your Loan Portfolio.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: cs.onSurfaceVariant,
                    fontStyle: FontStyle.italic,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 36),

                // Loan type tile
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: loanType.containerColor,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: loanType.color.withOpacity(0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(loanType.icon, color: loanType.color, size: 28),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            loanType.displayName,
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: loanType.color,
                            ),
                          ),
                          Text(
                            fmt(amount),
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: loanType.color,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 40),

                CustomButton(
                  text: 'Go to My Loans',
                  icon: const Icon(Icons.account_balance_rounded),
                  onPressed: onDone,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Shared sub-widgets ───────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final String label;

  const _SectionHeader({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Row(
      children: [
        Icon(icon, size: 18, color: cs.primary),
        const SizedBox(width: 8),
        Text(
          label,
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w700,
            color: cs.onSurface,
          ),
        ),
      ],
    );
  }
}
