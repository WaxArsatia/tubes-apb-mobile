import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

final _idr = NumberFormat.currency(
  locale: 'id_ID',
  symbol: 'Rp',
  decimalDigits: 0,
);

String formatIdr(int value) => _idr.format(value);

String formatNominalInput(int value) =>
    NumberFormat.decimalPattern('id_ID').format(value);

int parseNominalInput(String value) {
  final digits = value.replaceAll(RegExp(r'[^0-9]'), '');
  if (digits.isEmpty) return 0;
  return int.parse(digits);
}

class ThousandsSeparatorInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digits = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.isEmpty) return TextEditingValue.empty;
    final formatted = formatNominalInput(int.parse(digits));
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}

String formatDate(DateTime value) =>
    DateFormat('d MMM yyyy', 'id_ID').format(value);

String formatMonth(DateTime value) =>
    DateFormat('MMMM yyyy', 'id_ID').format(value);

String greeting(DateTime now) {
  final hour = now.hour;
  if (hour >= 5 && hour < 12) return 'Pagi';
  if (hour >= 12 && hour < 15) return 'Siang';
  if (hour >= 15 && hour < 19) return 'Sore';
  return 'Malam';
}

String dateOnly(DateTime value) => value.toIso8601String().substring(0, 10);
