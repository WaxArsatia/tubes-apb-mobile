import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tubes_apb_mobile/src/core/formatters.dart';

void main() {
  test('formats nominal input with Indonesian thousands separators', () {
    final formatter = ThousandsSeparatorInputFormatter();

    final formatted = formatter.formatEditUpdate(
      TextEditingValue.empty,
      const TextEditingValue(
        text: '1200000',
        selection: TextSelection.collapsed(offset: 7),
      ),
    );

    expect(formatted.text, '1.200.000');
    expect(formatted.selection.baseOffset, '1.200.000'.length);
    expect(parseNominalInput(formatted.text), 1200000);
  });
}
