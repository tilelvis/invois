import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'app_design_system.dart';

/// A 3x4 grid of number keys (0-9, decimal point, backspace), styled to
/// match Invois's design system instead of relying on the OS keyboard.
/// Fires [onKeyTap] with '0'-'9', '.', or 'backspace' for each press.
class AppKeypad extends StatelessWidget {
  final void Function(String key) onKeyTap;
  const AppKeypad({super.key, required this.onKeyTap});

  static const _rows = [
    ['1', '2', '3'],
    ['4', '5', '6'],
    ['7', '8', '9'],
    ['.', '0', 'backspace'],
  ];

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: _rows.map((row) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Row(
            children: row.map((key) {
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  child: _KeypadButton(
                    keyValue: key,
                    brightness: brightness,
                    onTap: () {
                      HapticFeedback.selectionClick();
                      onKeyTap(key);
                    },
                  ),
                ),
              );
            }).toList(),
          ),
        );
      }).toList(),
    );
  }
}

class _KeypadButton extends StatelessWidget {
  final String keyValue;
  final Brightness brightness;
  final VoidCallback onTap;
  const _KeypadButton({required this.keyValue, required this.brightness, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isBackspace = keyValue == 'backspace';

    return AspectRatio(
      aspectRatio: 1.5,
      child: Material(
        color: AppColors.surfaceVariant(brightness),
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppRadius.md),
          onTap: onTap,
          child: Center(
            child: isBackspace
                ? Icon(Icons.backspace_outlined, size: 20, color: AppColors.textSecondary(brightness))
                : Text(
                    keyValue,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary(brightness),
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}

/// Full amount-entry experience: a big live-updating currency readout above
/// an [AppKeypad], replacing the OS keyboard entirely for price fields.
/// Returns the entered value via [Navigator.pop] when "Done" is pressed, or
/// null if dismissed without confirming.
///
/// Usage:
/// ```dart
/// final result = await showModalBottomSheet<double>(
///   context: context,
///   isScrollControlled: true,
///   builder: (_) => AmountEntrySheet(label: 'Unit Price', initialValue: _priceController.text),
/// );
/// if (result != null) { ... }
/// ```
class AmountEntrySheet extends StatefulWidget {
  final String label;
  final String initialValue;
  const AmountEntrySheet({super.key, required this.label, this.initialValue = ''});

  @override
  State<AmountEntrySheet> createState() => _AmountEntrySheetState();
}

class _AmountEntrySheetState extends State<AmountEntrySheet> {
  late String _digits;
  static final _currencyFormatter = NumberFormat.currency(locale: 'en_KE', symbol: 'KES ');

  @override
  void initState() {
    super.initState();
    // Strip to a bare digits+decimal string so it can be built back up the
    // same way typed input would be.
    _digits = widget.initialValue.replaceAll(RegExp(r'[^0-9.]'), '');
  }

  double get _value => double.tryParse(_digits) ?? 0.0;

  void _handleKey(String key) {
    setState(() {
      if (key == 'backspace') {
        if (_digits.isNotEmpty) _digits = _digits.substring(0, _digits.length - 1);
      } else if (key == '.') {
        if (!_digits.contains('.')) {
          _digits = _digits.isEmpty ? '0.' : '$_digits.';
        }
      } else {
        // Cap length so the readout never overflows the sheet.
        if (_digits.length < 12) _digits = '$_digits$key';
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.md, AppSpacing.lg, AppSpacing.lg),
        decoration: BoxDecoration(
          color: AppColors.surface(brightness),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: AppSpacing.md),
                decoration: BoxDecoration(
                  color: AppColors.slate400,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Text(
              widget.label,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: AppColors.textSecondary(brightness), fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: AppSpacing.sm),
            Center(
              child: Text(
                _currencyFormatter.format(_value),
                style: TextStyle(fontSize: 40, fontWeight: FontWeight.w900, color: AppColors.textPrimary(brightness)),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            AppKeypad(onKeyTap: _handleKey),
            const SizedBox(height: AppSpacing.md),
            ElevatedButton(
              onPressed: _value > 0 ? () => Navigator.pop(context, _value) : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
              ),
              child: const Text('Done', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }
}
