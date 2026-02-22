import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

class AmountInputWidget extends StatefulWidget {
  final TextEditingController? controller;

  final String currencySymbol;

  final double? maxAmount;

  final void Function(double amount)? onChanged;

  final String label;

  final String? hint;

  final bool enabled;

  final FocusNode? focusNode;

  const AmountInputWidget({
    super.key,
    this.controller,
    this.currencySymbol = '\$',
    this.maxAmount,
    this.onChanged,
    this.label = 'Amount',
    this.hint,
    this.enabled = true,
    this.focusNode,
  });

  @override
  State<AmountInputWidget> createState() => _AmountInputWidgetState();
}

class _AmountInputWidgetState extends State<AmountInputWidget> {
  late final TextEditingController _controller;
  bool _ownsController = false;

  double _parsedValue = 0.0;

  bool get _exceedsMax =>
      widget.maxAmount != null && _parsedValue > widget.maxAmount!;


  static double _parse(String raw) {
    final cleaned = raw.replaceAll(',', '');
    return double.tryParse(cleaned) ?? 0.0;
  }

  static String _format(String raw) {
    if (raw.isEmpty) return raw;

    final parts = raw.split('.');
    final integerPart = parts[0];
    final hasDecimal = parts.length > 1;
    final decimalPart = hasDecimal ? parts[1] : '';

    final formatted = integerPart.isEmpty
        ? ''
        : NumberFormat('#,##0').format(int.tryParse(integerPart) ?? 0);

    if (hasDecimal) return '$formatted.$decimalPart';
    return formatted;
  }


  @override
  void initState() {
    super.initState();
    if (widget.controller != null) {
      _controller = widget.controller!;
    } else {
      _controller = TextEditingController();
      _ownsController = true;
    }
  }

  @override
  void dispose() {
    if (_ownsController) _controller.dispose();
    super.dispose();
  }


  void _onChanged(String raw) {
    final cleaned = raw.replaceAll(',', '');
    final newValue = _parse(cleaned);

    setState(() => _parsedValue = newValue);
    widget.onChanged?.call(newValue);

    final formatted = _format(cleaned);
    if (formatted != raw) {
      _controller.value = TextEditingValue(
        text: formatted,
        selection: TextSelection.collapsed(offset: formatted.length),
      );
    }
  }


  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final bool showInsufficientHint = _exceedsMax;
    final String? helperText = showInsufficientHint
        ? 'Insufficient balance '
            '(max: ${widget.currencySymbol}'
            '${NumberFormat('#,##0.00').format(widget.maxAmount)})'
        : null;

    return TextFormField(
      controller: _controller,
      focusNode: widget.focusNode,
      enabled: widget.enabled,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      textInputAction: TextInputAction.next,
      inputFormatters: [
        _AmountInputFormatter(),
      ],
      onChanged: _onChanged,
      style: theme.textTheme.titleMedium?.copyWith(
        fontWeight: FontWeight.w600,
        color: showInsufficientHint ? colorScheme.error : null,
      ),
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'Please enter an amount.';
        }
        final v = _parse(value);
        if (v <= 0) return 'Amount must be greater than zero.';
        if (widget.maxAmount != null && v > widget.maxAmount!) {
          return 'Amount exceeds available balance.';
        }
        return null;
      },
      decoration: InputDecoration(
        labelText: widget.label,
        hintText: widget.hint ?? '0.00',
        helperText: helperText,
        helperStyle: theme.textTheme.bodySmall?.copyWith(
          color: colorScheme.error,
        ),
        prefixIcon: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            widget.currencySymbol,
            style: theme.textTheme.titleMedium?.copyWith(
              color: showInsufficientHint
                  ? colorScheme.error
                  : colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
        suffixIcon: _controller.text.isNotEmpty
            ? IconButton(
                icon: const Icon(Icons.close, size: 18),
                tooltip: 'Clear amount',
                onPressed: () {
                  _controller.clear();
                  setState(() => _parsedValue = 0.0);
                  widget.onChanged?.call(0.0);
                },
              )
            : null,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colorScheme.outline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: showInsufficientHint
                ? colorScheme.error
                : colorScheme.outline,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: showInsufficientHint
                ? colorScheme.error
                : colorScheme.primary,
            width: 2,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colorScheme.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colorScheme.error, width: 2),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide:
              BorderSide(color: colorScheme.outline.withOpacity(0.5)),
        ),
        filled: true,
        fillColor: widget.enabled
            ? (showInsufficientHint
                ? colorScheme.errorContainer.withOpacity(0.08)
                : colorScheme.surface)
            : colorScheme.surfaceContainerHighest.withOpacity(0.3),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        counterText: '',
      ),
    );
  }
}


class _AmountInputFormatter extends TextInputFormatter {
  static final _validPattern = RegExp(r'^\d{0,13}(\.\d{0,2})?$');

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final stripped = newValue.text.replaceAll(',', '');

    if (stripped.isEmpty) return newValue;

    if (_validPattern.hasMatch(stripped)) {
      return newValue;
    }

    return oldValue;
  }
}