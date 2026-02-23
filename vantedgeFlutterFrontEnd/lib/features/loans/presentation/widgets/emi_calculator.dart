import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:vantedge/features/loans/utils/loan_calculator.dart';

/// Self-contained EMI calculator widget.
///
/// Accepts principal, annual interest rate, and tenure (months) as
/// text inputs and displays the computed EMI, total repayment, and
/// total interest in real-time.
///
/// All calculations are delegated to [LoanCalculator] — zero business
/// logic lives inside this widget.
///
/// Optionally pre-populated via [initialPrincipal], [initialAnnualRate],
/// [initialTenureMonths]. Use [onResultChanged] to be notified whenever
/// the calculated result changes (e.g., to pass it up to a form parent).
class EmiCalculatorWidget extends StatefulWidget {
  final double? initialPrincipal;
  final double? initialAnnualRate;
  final int? initialTenureMonths;

  /// Called whenever any input changes and a valid result is computed.
  /// Passes `null` when inputs are incomplete or invalid.
  final ValueChanged<LoanCalculationResult?>? onResultChanged;

  /// Colour accent used for highlights. Defaults to the theme primary.
  final Color? accentColor;

  const EmiCalculatorWidget({
    super.key,
    this.initialPrincipal,
    this.initialAnnualRate,
    this.initialTenureMonths,
    this.onResultChanged,
    this.accentColor,
  });

  @override
  State<EmiCalculatorWidget> createState() => _EmiCalculatorWidgetState();
}

class _EmiCalculatorWidgetState extends State<EmiCalculatorWidget>
    with SingleTickerProviderStateMixin {
  late final TextEditingController _principalCtrl;
  late final TextEditingController _rateCtrl;
  late final TextEditingController _tenureCtrl;

  LoanCalculationResult? _result;

  // ─── Slider ranges ────────────────────────────────────────────────────────
  double _principalSlider = 100000;
  double _rateSlider = 10.0;
  double _tenureSlider = 12;

  static const double _minPrincipal = 10000;
  static const double _maxPrincipal = 10000000;
  static const double _minRate = 1;
  static const double _maxRate = 30;
  static const double _minTenure = 1;
  static const double _maxTenure = 360;

  late AnimationController _resultAnimController;
  late Animation<double> _resultFadeAnim;

  static final _currencyFmt = NumberFormat.currency(
    symbol: '৳',
    decimalDigits: 2,
    locale: 'en_IN',
  );

  @override
  void initState() {
    super.initState();

    _principalSlider = widget.initialPrincipal?.clamp(
            _minPrincipal, _maxPrincipal) ??
        100000;
    _rateSlider =
        widget.initialAnnualRate?.clamp(_minRate, _maxRate) ?? 10.0;
    _tenureSlider = (widget.initialTenureMonths?.toDouble() ?? 12)
        .clamp(_minTenure, _maxTenure);

    _principalCtrl =
        TextEditingController(text: _principalSlider.toStringAsFixed(0));
    _rateCtrl =
        TextEditingController(text: _rateSlider.toStringAsFixed(2));
    _tenureCtrl =
        TextEditingController(text: _tenureSlider.toStringAsFixed(0));

    _resultAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    _resultFadeAnim = CurvedAnimation(
      parent: _resultAnimController,
      curve: Curves.easeIn,
    );

    _recalculate();
  }

  @override
  void dispose() {
    _principalCtrl.dispose();
    _rateCtrl.dispose();
    _tenureCtrl.dispose();
    _resultAnimController.dispose();
    super.dispose();
  }

  // ─── Calculation ─────────────────────────────────────────────────────────

  void _recalculate() {
    final principal = double.tryParse(_principalCtrl.text);
    final rate = double.tryParse(_rateCtrl.text);
    final tenure = int.tryParse(_tenureCtrl.text);

    if (principal == null ||
        rate == null ||
        tenure == null ||
        principal <= 0 ||
        rate <= 0 ||
        tenure <= 0) {
      setState(() => _result = null);
      widget.onResultChanged?.call(null);
      return;
    }

    final result = LoanCalculator.calculate(
      principal: principal,
      annualRate: rate,
      tenureMonths: tenure,
    );

    setState(() => _result = result);
    widget.onResultChanged?.call(result);

    _resultAnimController
      ..reset()
      ..forward();
  }

  // ─── Sync slider → text field ─────────────────────────────────────────────

  void _onPrincipalSlider(double v) {
    _principalSlider = v;
    _principalCtrl.text = v.toStringAsFixed(0);
    _recalculate();
  }

  void _onRateSlider(double v) {
    _rateSlider = v;
    _rateCtrl.text = v.toStringAsFixed(2);
    _recalculate();
  }

  void _onTenureSlider(double v) {
    _tenureSlider = v;
    _tenureCtrl.text = v.toStringAsFixed(0);
    _recalculate();
  }

  // ─── Sync text field → slider ─────────────────────────────────────────────

  void _onPrincipalText(String v) {
    final parsed = double.tryParse(v);
    if (parsed != null) {
      _principalSlider = parsed.clamp(_minPrincipal, _maxPrincipal);
    }
    _recalculate();
  }

  void _onRateText(String v) {
    final parsed = double.tryParse(v);
    if (parsed != null) {
      _rateSlider = parsed.clamp(_minRate, _maxRate);
    }
    _recalculate();
  }

  void _onTenureText(String v) {
    final parsed = double.tryParse(v);
    if (parsed != null) {
      _tenureSlider = parsed.clamp(_minTenure, _maxTenure);
    }
    _recalculate();
  }

  // ─── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final accent = widget.accentColor ?? cs.primary;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // ── Inputs ──────────────────────────────────────────────────────────
        _InputSliderRow(
          label: 'Principal Amount',
          suffix: '৳',
          controller: _principalCtrl,
          sliderValue: _principalSlider,
          min: _minPrincipal,
          max: _maxPrincipal,
          divisions: 990,
          onSliderChanged: _onPrincipalSlider,
          onTextChanged: _onPrincipalText,
          accentColor: accent,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
          ],
        ),
        const SizedBox(height: 16),
        _InputSliderRow(
          label: 'Annual Interest Rate',
          suffix: '%',
          controller: _rateCtrl,
          sliderValue: _rateSlider,
          min: _minRate,
          max: _maxRate,
          divisions: 290,
          onSliderChanged: _onRateSlider,
          onTextChanged: _onRateText,
          accentColor: accent,
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
          ],
        ),
        const SizedBox(height: 16),
        _InputSliderRow(
          label: 'Tenure (Months)',
          suffix: 'mo',
          controller: _tenureCtrl,
          sliderValue: _tenureSlider,
          min: _minTenure,
          max: _maxTenure,
          divisions: 359,
          onSliderChanged: _onTenureSlider,
          onTextChanged: _onTenureText,
          accentColor: accent,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
          ],
        ),

        const SizedBox(height: 24),

        // ── Result panel ────────────────────────────────────────────────────
        FadeTransition(
          opacity: _resultFadeAnim,
          child: _result != null
              ? _ResultPanel(
                  result: _result!,
                  accentColor: accent,
                  currencyFmt: _currencyFmt,
                  theme: theme,
                  cs: cs,
                )
              : _EmptyResult(theme: theme, cs: cs),
        ),
      ],
    );
  }
}

// ─── Input + slider row ───────────────────────────────────────────────────────

class _InputSliderRow extends StatelessWidget {
  final String label;
  final String suffix;
  final TextEditingController controller;
  final double sliderValue;
  final double min;
  final double max;
  final int divisions;
  final ValueChanged<double> onSliderChanged;
  final ValueChanged<String> onTextChanged;
  final Color accentColor;
  final List<TextInputFormatter>? inputFormatters;

  const _InputSliderRow({
    required this.label,
    required this.suffix,
    required this.controller,
    required this.sliderValue,
    required this.min,
    required this.max,
    required this.divisions,
    required this.onSliderChanged,
    required this.onTextChanged,
    required this.accentColor,
    this.inputFormatters,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Label + text field
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
            const SizedBox(width: 8),
            SizedBox(
              width: 110,
              child: TextField(
                controller: controller,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                textAlign: TextAlign.right,
                inputFormatters: inputFormatters,
                onChanged: onTextChanged,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: accentColor,
                ),
                decoration: InputDecoration(
                  suffixText: suffix,
                  suffixStyle: theme.textTheme.bodySmall?.copyWith(
                    color: cs.onSurfaceVariant,
                  ),
                  isDense: true,
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: cs.outlineVariant),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: accentColor, width: 1.5),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(
                        color: cs.outlineVariant.withOpacity(0.7)),
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: accentColor,
            thumbColor: accentColor,
            overlayColor: accentColor.withOpacity(0.15),
            inactiveTrackColor: accentColor.withOpacity(0.18),
            trackHeight: 3,
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
          ),
          child: Slider(
            value: sliderValue.clamp(min, max),
            min: min,
            max: max,
            divisions: divisions,
            onChanged: onSliderChanged,
          ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              _fmt(min),
              style: theme.textTheme.labelSmall
                  ?.copyWith(color: cs.onSurfaceVariant),
            ),
            Text(
              _fmt(max),
              style: theme.textTheme.labelSmall
                  ?.copyWith(color: cs.onSurfaceVariant),
            ),
          ],
        ),
      ],
    );
  }

  String _fmt(double v) {
    if (v >= 1000000) return '${(v / 1000000).toStringAsFixed(1)}M';
    if (v >= 1000) return '${(v / 1000).toStringAsFixed(0)}K';
    return v.toStringAsFixed(0);
  }
}

// ─── Result panel ─────────────────────────────────────────────────────────────

class _ResultPanel extends StatelessWidget {
  final LoanCalculationResult result;
  final Color accentColor;
  final NumberFormat currencyFmt;
  final ThemeData theme;
  final ColorScheme cs;

  const _ResultPanel({
    required this.result,
    required this.accentColor,
    required this.currencyFmt,
    required this.theme,
    required this.cs,
  });

  String _fmt(double v) => currencyFmt.format(v);

  @override
  Widget build(BuildContext context) {
    final interestPct =
        result.interestPercentOfPrincipal.toStringAsFixed(1);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            accentColor.withOpacity(0.08),
            accentColor.withOpacity(0.04),
          ],
        ),
        border: Border.all(color: accentColor.withOpacity(0.25)),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Monthly EMI headline ─────────────────────────────────────────
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Monthly EMI',
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: cs.onSurfaceVariant,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _fmt(result.emi),
                      style: theme.textTheme.headlineSmall?.copyWith(
                        color: accentColor,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
              _PieIndicator(
                ratio: result.interestRatio,
                color: accentColor,
              ),
            ],
          ),

          const SizedBox(height: 16),
          Divider(height: 1, color: accentColor.withOpacity(0.2)),
          const SizedBox(height: 16),

          // ── Breakdown row ────────────────────────────────────────────────
          Row(
            children: [
              _StatCell(
                label: 'Principal',
                value: _fmt(result.principal),
                theme: theme,
                cs: cs,
              ),
              _Divider(color: accentColor),
              _StatCell(
                label: 'Total Interest',
                value: _fmt(result.totalInterest),
                subLabel: '+$interestPct%',
                theme: theme,
                cs: cs,
                valueColor: const Color(0xFFC62828),
              ),
              _Divider(color: accentColor),
              _StatCell(
                label: 'Total Payable',
                value: _fmt(result.totalAmount),
                theme: theme,
                cs: cs,
                valueColor: accentColor,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatCell extends StatelessWidget {
  final String label;
  final String value;
  final String? subLabel;
  final ThemeData theme;
  final ColorScheme cs;
  final Color? valueColor;

  const _StatCell({
    required this.label,
    required this.value,
    required this.theme,
    required this.cs,
    this.subLabel,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: cs.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: theme.textTheme.labelMedium?.copyWith(
              color: valueColor ?? cs.onSurface,
              fontWeight: FontWeight.w700,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          if (subLabel != null)
            Text(
              subLabel!,
              style: theme.textTheme.labelSmall?.copyWith(
                color: const Color(0xFFC62828),
                fontSize: 10,
              ),
              textAlign: TextAlign.center,
            ),
        ],
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  final Color color;
  const _Divider({required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 40,
      color: color.withOpacity(0.2),
    );
  }
}

/// A tiny donut-style visual showing the principal vs interest split.
class _PieIndicator extends StatelessWidget {
  final double ratio; // 0–1, fraction that is interest
  final Color color;

  const _PieIndicator({required this.ratio, required this.color});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 52,
      height: 52,
      child: CustomPaint(
        painter: _DonutPainter(
          interestRatio: ratio.clamp(0.0, 1.0),
          color: color,
        ),
        child: Center(
          child: Text(
            '${(ratio * 100).toStringAsFixed(0)}%',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ),
      ),
    );
  }
}

class _DonutPainter extends CustomPainter {
  final double interestRatio;
  final Color color;

  const _DonutPainter({required this.interestRatio, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final radius = (size.width / 2) - 4;
    const strokeW = 6.0;

    final bgPaint = Paint()
      ..color = color.withOpacity(0.15)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeW
      ..strokeCap = StrokeCap.round;

    final fgPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeW
      ..strokeCap = StrokeCap.round;

    final rect = Rect.fromCircle(center: Offset(cx, cy), radius: radius);
    const startAngle = -1.5707963; // -π/2 (top)

    // Background arc (full circle)
    canvas.drawArc(rect, 0, 6.2831853, false, bgPaint);
    // Foreground arc (interest portion)
    canvas.drawArc(
        rect, startAngle, interestRatio * 6.2831853, false, fgPaint);
  }

  @override
  bool shouldRepaint(_DonutPainter old) => old.interestRatio != interestRatio;
}

// ─── Empty state when inputs are invalid ─────────────────────────────────────

class _EmptyResult extends StatelessWidget {
  final ThemeData theme;
  final ColorScheme cs;
  const _EmptyResult({required this.theme, required this.cs});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 24),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Icon(Icons.calculate_outlined,
              size: 36, color: cs.onSurfaceVariant.withOpacity(0.4)),
          const SizedBox(height: 8),
          Text(
            'Enter valid values above to see your EMI',
            style: theme.textTheme.bodySmall
                ?.copyWith(color: cs.onSurfaceVariant),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
