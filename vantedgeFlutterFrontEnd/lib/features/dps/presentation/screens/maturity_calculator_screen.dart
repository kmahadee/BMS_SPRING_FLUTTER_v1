import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import 'package:vantedge/core/routes/app_routes.dart';
import 'package:vantedge/features/dps/utils/dps_calculator.dart';
import 'package:vantedge/shared/widgets/custom_app_bar.dart';

// ── Screen ───────────────────────────────────────────────────────────────────

class MaturityCalculatorScreen extends StatefulWidget {
  const MaturityCalculatorScreen({super.key});

  @override
  State<MaturityCalculatorScreen> createState() =>
      _MaturityCalculatorScreenState();
}

class _MaturityCalculatorScreenState extends State<MaturityCalculatorScreen>
    with SingleTickerProviderStateMixin {
  // ── Slider bounds ──────────────────────────────────────────────────────────

  static const double _minInstallment  = 100.0;
  static const double _maxInstallment  = 100000.0;
  static const int    _minTenure       = 6;
  static const int    _maxTenure       = 120;
  static const double _minRate         = 1.0;
  static const double _maxRate         = 20.0;

  // ── Controller state ───────────────────────────────────────────────────────

  final _formKey        = GlobalKey<FormState>();
  late TextEditingController _installmentCtrl;
  late TextEditingController _tenureCtrl;
  late TextEditingController _rateCtrl;

  double _installmentSlider = 5000.0;
  double _tenureSlider      = 24.0;
  double _rateSlider        = 8.0;

  // ── Calculation result ─────────────────────────────────────────────────────

  DpsCalculationResult? _result;

  // ── Animation ──────────────────────────────────────────────────────────────

  late AnimationController _animCtrl;
  late Animation<double>   _fadeAnim;
  late Animation<Offset>   _slideAnim;

  // ── Formatters ─────────────────────────────────────────────────────────────

  static final _currFmt = NumberFormat.currency(
    symbol: '৳ ',
    decimalDigits: 2,
    locale: 'en_IN',
  );
  static final _compactFmt = NumberFormat.compactCurrency(
    symbol: '৳',
    decimalDigits: 1,
    locale: 'en_IN',
  );
  static final _dateFmt = DateFormat('dd MMM yyyy');

  String _fmt(double v)      => _currFmt.format(v);
  String _compact(double v)  => _compactFmt.format(v);
  String _fmtDate(DateTime d) => _dateFmt.format(d);

  // ── Lifecycle ──────────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    _installmentCtrl = TextEditingController(
        text: _installmentSlider.toStringAsFixed(0));
    _tenureCtrl = TextEditingController(
        text: _tenureSlider.toStringAsFixed(0));
    _rateCtrl   = TextEditingController(
        text: _rateSlider.toStringAsFixed(2));

    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 420),
    );
    _fadeAnim  = CurvedAnimation(parent: _animCtrl, curve: Curves.easeIn);
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.08),
      end:   Offset.zero,
    ).animate(CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut));

    // Auto-calculate on first build
    WidgetsBinding.instance
        .addPostFrameCallback((_) => _calculate());
  }

  @override
  void dispose() {
    _installmentCtrl.dispose();
    _tenureCtrl.dispose();
    _rateCtrl.dispose();
    _animCtrl.dispose();
    super.dispose();
  }

  // ── Calculation ────────────────────────────────────────────────────────────

  void _calculate() {
    final installment = double.tryParse(_installmentCtrl.text);
    final tenure      = int.tryParse(_tenureCtrl.text);
    final rate        = double.tryParse(_rateCtrl.text);

    if (installment == null || tenure == null || rate == null ||
        installment < _minInstallment || tenure < _minTenure || rate <= 0) {
      setState(() => _result = null);
      return;
    }

    final result = DpsCalculator.calculate(
      monthlyInstallment: installment,
      tenureMonths:       tenure,
      annualInterestRate: rate,
    );

    setState(() => _result = result);
    _animCtrl
      ..reset()
      ..forward();
  }

  void _reset() {
    setState(() {
      _installmentSlider = 5000.0;
      _tenureSlider      = 24.0;
      _rateSlider        = 8.0;
      _installmentCtrl.text = '5000';
      _tenureCtrl.text      = '24';
      _rateCtrl.text        = '8.00';
      _result = null;
    });
    _animCtrl.reset();
  }

  void _navigateToCreate() {
    if (_result == null) return;
    Navigator.pushNamed(
      context,
      AppRoutes.dpsCreate,
      arguments: {
        'initialInstallment': _result!.monthlyInstallment,
        'initialTenure':      _result!.tenureMonths,
        'initialRate':        _result!.annualInterestRate,
      },
    );
  }

  // ── Slider sync helpers ────────────────────────────────────────────────────

  void _onInstallmentSlider(double v) {
    _installmentSlider = v;
    _installmentCtrl.text = v.toStringAsFixed(0);
    _calculate();
  }

  void _onTenureSlider(double v) {
    _tenureSlider = v;
    _tenureCtrl.text = v.round().toString();
    _calculate();
  }

  void _onRateSlider(double v) {
    _rateSlider = v;
    _rateCtrl.text = v.toStringAsFixed(2);
    _calculate();
  }

  void _onInstallmentText(String v) {
    final p = double.tryParse(v);
    if (p != null) _installmentSlider = p.clamp(_minInstallment, _maxInstallment);
    _calculate();
  }

  void _onTenureText(String v) {
    final p = int.tryParse(v);
    if (p != null) _tenureSlider = p.clamp(_minTenure, _maxTenure).toDouble();
    _calculate();
  }

  void _onRateText(String v) {
    final p = double.tryParse(v);
    if (p != null) _rateSlider = p.clamp(_minRate, _maxRate);
    _calculate();
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs    = theme.colorScheme;

    return Scaffold(
      backgroundColor: cs.surfaceContainerLowest,
      appBar: CustomAppBar(
        title: 'DPS Maturity Calculator',
        showNotifications: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Reset',
            onPressed: _reset,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 48),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── Intro banner ─────────────────────────────────────────────
              _IntroBanner(cs: cs, theme: theme),
              const SizedBox(height: 24),

              // ── Input sliders ────────────────────────────────────────────
              _SectionLabel('Inputs', cs.primary, theme),
              const SizedBox(height: 14),

              _InputSlider(
                label:    'Monthly Installment',
                suffix:   '৳',
                ctrl:     _installmentCtrl,
                sliderValue: _installmentSlider,
                min:      _minInstallment,
                max:      _maxInstallment,
                divisions: 998,
                onSlider: _onInstallmentSlider,
                onText:   _onInstallmentText,
                fmtMin:   _compact,
                fmtMax:   _compact,
                formatters: [FilteringTextInputFormatter.digitsOnly],
                cs: cs, theme: theme,
              ),
              const SizedBox(height: 20),

              _InputSlider(
                label:    'Tenure',
                suffix:   'months',
                ctrl:     _tenureCtrl,
                sliderValue: _tenureSlider,
                min:      _minTenure.toDouble(),
                max:      _maxTenure.toDouble(),
                divisions: _maxTenure - _minTenure,
                onSlider: _onTenureSlider,
                onText:   _onTenureText,
                fmtMin:   (v) => '${v.round()} mo',
                fmtMax:   (v) => '${v.round()} mo',
                formatters: [FilteringTextInputFormatter.digitsOnly],
                cs: cs, theme: theme,
              ),
              const SizedBox(height: 20),

              _InputSlider(
                label:    'Annual Interest Rate',
                suffix:   '%',
                ctrl:     _rateCtrl,
                sliderValue: _rateSlider,
                min:      _minRate,
                max:      _maxRate,
                divisions: 190,
                onSlider: _onRateSlider,
                onText:   _onRateText,
                fmtMin:   (v) => '${v.toStringAsFixed(1)}%',
                fmtMax:   (v) => '${v.toStringAsFixed(1)}%',
                formatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
                ],
                cs: cs, theme: theme,
              ),

              const SizedBox(height: 28),

              // ── Results (animated) ────────────────────────────────────────
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 350),
                switchInCurve:  Curves.easeOutCubic,
                switchOutCurve: Curves.easeIn,
                transitionBuilder: (child, animation) => FadeTransition(
                  opacity: animation,
                  child: SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(0, 0.06),
                      end:   Offset.zero,
                    ).animate(animation),
                    child: child,
                  ),
                ),
                child: _result != null
                    ? _ResultCard(
                        key: ValueKey(_result!.maturityAmount),
                        result: _result!,
                        fmt:     _fmt,
                        compact: _compact,
                        fmtDate: _fmtDate,
                        cs: cs,
                        theme: theme,
                      )
                    : const SizedBox.shrink(),
              ),

              // ── CTA buttons (only when result available) ─────────────────
              if (_result != null) ...[
                const SizedBox(height: 20),
                FilledButton.icon(
                  onPressed: _navigateToCreate,
                  icon:  const Icon(Icons.savings_rounded),
                  label: const Text('Open a DPS with These Values'),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                    textStyle: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700),
                  ),
                ),
                const SizedBox(height: 10),
                OutlinedButton.icon(
                  onPressed: _reset,
                  icon:  const Icon(Icons.refresh_rounded),
                  label: const Text('Reset Calculator'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// ── Intro banner ─────────────────────────────────────────────────────────────

class _IntroBanner extends StatelessWidget {
  final ColorScheme cs;
  final ThemeData theme;

  const _IntroBanner({required this.cs, required this.theme});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: cs.primaryContainer.withOpacity(0.45),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: cs.primary.withOpacity(0.25)),
      ),
      child: Row(
        children: [
          Icon(Icons.calculate_rounded, color: cs.primary, size: 32),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'How much will you earn?',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: cs.primary,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  'Adjust the sliders below to instantly see your projected '
                  'DPS maturity amount.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: cs.onSurfaceVariant,
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

// ── Section label ─────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final String label;
  final Color  color;
  final ThemeData theme;

  const _SectionLabel(this.label, this.color, this.theme);

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: theme.textTheme.titleMedium?.copyWith(
        fontWeight: FontWeight.w700,
        color: color,
      ),
    );
  }
}

// ── Input slider row ─────────────────────────────────────────────────────────

class _InputSlider extends StatelessWidget {
  final String label;
  final String suffix;
  final TextEditingController ctrl;
  final double sliderValue;
  final double min;
  final double max;
  final int    divisions;
  final ValueChanged<double> onSlider;
  final ValueChanged<String> onText;
  final String Function(double) fmtMin;
  final String Function(double) fmtMax;
  final List<TextInputFormatter>? formatters;
  final ColorScheme cs;
  final ThemeData  theme;

  const _InputSlider({
    required this.label,
    required this.suffix,
    required this.ctrl,
    required this.sliderValue,
    required this.min,
    required this.max,
    required this.divisions,
    required this.onSlider,
    required this.onText,
    required this.fmtMin,
    required this.fmtMax,
    required this.cs,
    required this.theme,
    this.formatters,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Label + input field
        Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: theme.textTheme.labelLarge?.copyWith(
                  color: cs.onSurface,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(width: 10),
            SizedBox(
              width: 120,
              child: TextField(
                controller: ctrl,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                textAlign: TextAlign.right,
                inputFormatters: formatters,
                onChanged: onText,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: cs.primary,
                ),
                decoration: InputDecoration(
                  suffixText: suffix,
                  suffixStyle: theme.textTheme.bodySmall?.copyWith(
                    color: cs.onSurfaceVariant,
                  ),
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 9),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: cs.outlineVariant)),
                  focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: cs.primary, width: 1.5)),
                  enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(
                          color: cs.outlineVariant.withOpacity(0.7))),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),

        // Slider
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor:   cs.primary,
            thumbColor:         cs.primary,
            overlayColor:       cs.primary.withOpacity(0.14),
            inactiveTrackColor: cs.primary.withOpacity(0.18),
            trackHeight:        3,
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
          ),
          child: Slider(
            value:     sliderValue.clamp(min, max),
            min:       min,
            max:       max,
            divisions: divisions,
            onChanged: onSlider,
          ),
        ),

        // Min / max labels
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(fmtMin(min),
                style: theme.textTheme.labelSmall
                    ?.copyWith(color: cs.onSurfaceVariant)),
            Text(fmtMax(max),
                style: theme.textTheme.labelSmall
                    ?.copyWith(color: cs.onSurfaceVariant)),
          ],
        ),
      ],
    );
  }
}

// ── Results card ─────────────────────────────────────────────────────────────

class _ResultCard extends StatelessWidget {
  final DpsCalculationResult result;
  final String Function(double)   fmt;
  final String Function(double)   compact;
  final String Function(DateTime) fmtDate;
  final ColorScheme cs;
  final ThemeData   theme;

  const _ResultCard({
    super.key,
    required this.result,
    required this.fmt,
    required this.compact,
    required this.fmtDate,
    required this.cs,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    final pct = result.interestPercent.toStringAsFixed(1);

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end:   Alignment.bottomRight,
          colors: [
            cs.primary.withOpacity(0.08),
            Colors.green.shade600.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: cs.primary.withOpacity(0.22)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Maturity amount hero ─────────────────────────────────────────
          Container(
            padding: const EdgeInsets.symmetric(vertical: 22, horizontal: 20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end:   Alignment.bottomRight,
                colors: [cs.primary, cs.primary.withOpacity(0.80)],
              ),
              borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(20)),
            ),
            child: Column(
              children: [
                Text(
                  'Maturity Amount',
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: Colors.white.withOpacity(0.82),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  fmt(result.maturityAmount),
                  style: theme.textTheme.headlineLarge?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 10),
                // Deposit + interest bar
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: result.maturityAmount > 0
                        ? result.totalDeposit / result.maturityAmount
                        : 0,
                    minHeight: 8,
                    backgroundColor:
                        Colors.white.withOpacity(0.25),
                    valueColor:
                        const AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _WhiteStat(
                        'Deposit', compact(result.totalDeposit), theme),
                    _WhiteStat(
                        'Interest', compact(result.interestEarned), theme),
                    _WhiteStat('Gain', '$pct%', theme),
                  ],
                ),
              ],
            ),
          ),

          // ── Detail rows ──────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              children: [
                _ResultRow(
                  icon:  Icons.calendar_today_outlined,
                  label: 'Monthly Installment',
                  value: fmt(result.monthlyInstallment),
                  theme: theme, cs: cs,
                ),
                _Div(cs),
                _ResultRow(
                  icon:  Icons.timelapse_rounded,
                  label: 'Tenure',
                  value: '${result.tenureMonths} months',
                  theme: theme, cs: cs,
                ),
                _Div(cs),
                _ResultRow(
                  icon:  Icons.percent_rounded,
                  label: 'Interest Rate',
                  value: '${result.annualInterestRate.toStringAsFixed(2)}% p.a.',
                  theme: theme, cs: cs,
                ),
                _Div(cs),
                _ResultRow(
                  icon:  Icons.savings_outlined,
                  label: 'Total Deposited',
                  value: fmt(result.totalDeposit),
                  theme: theme, cs: cs,
                ),
                _Div(cs),
                _ResultRow(
                  icon:  Icons.trending_up_rounded,
                  label: 'Interest Earned',
                  value: fmt(result.interestEarned),
                  valueColor: Colors.green.shade700,
                  theme: theme, cs: cs,
                ),
                _Div(cs),
                _ResultRow(
                  icon:  Icons.auto_graph_rounded,
                  label: 'Effective Annual Yield',
                  value:
                      '${result.effectiveAnnualYield.toStringAsFixed(2)}%',
                  valueColor: cs.primary,
                  bold:  true,
                  theme: theme, cs: cs,
                ),
                _Div(cs),
                _ResultRow(
                  icon:  Icons.event_available_rounded,
                  label: 'Projected Maturity',
                  value: fmtDate(result.projectedMaturityDate),
                  valueColor: cs.primary,
                  theme: theme, cs: cs,
                ),
              ],
            ),
          ),

          // ── Disclaimer ────────────────────────────────────────────────────
          Container(
            margin: const EdgeInsets.fromLTRB(18, 0, 18, 18),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: cs.surfaceContainerHighest.withOpacity(0.5),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline_rounded,
                    size: 14, color: cs.onSurfaceVariant),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'This is an indicative estimate. Actual maturity may vary '
                    'based on bank terms and compounding frequency.',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: cs.onSurfaceVariant,
                      fontStyle: FontStyle.italic,
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

class _WhiteStat extends StatelessWidget {
  final String label;
  final String value;
  final ThemeData theme;

  const _WhiteStat(this.label, this.value, this.theme);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(label,
            style: theme.textTheme.labelSmall?.copyWith(
                color: Colors.white.withOpacity(0.75))),
        const SizedBox(height: 2),
        Text(value,
            style: theme.textTheme.bodyMedium?.copyWith(
                color: Colors.white, fontWeight: FontWeight.w800)),
      ],
    );
  }
}

class _ResultRow extends StatelessWidget {
  final IconData icon;
  final String   label;
  final String   value;
  final Color?   valueColor;
  final bool     bold;
  final ThemeData theme;
  final ColorScheme cs;

  const _ResultRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.theme,
    required this.cs,
    this.valueColor,
    this.bold = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 9),
      child: Row(
        children: [
          Icon(icon, size: 16, color: cs.onSurfaceVariant),
          const SizedBox(width: 10),
          Expanded(
            flex: 3,
            child: Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: cs.onSurfaceVariant,
              ),
            ),
          ),
          Text(
            value,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: bold ? FontWeight.w800 : FontWeight.w600,
              color: valueColor ?? cs.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}

class _Div extends StatelessWidget {
  final ColorScheme cs;
  const _Div(this.cs);

  @override
  Widget build(BuildContext context) {
    return Divider(
      height: 1,
      color: cs.outlineVariant.withOpacity(0.5),
    );
  }
}
