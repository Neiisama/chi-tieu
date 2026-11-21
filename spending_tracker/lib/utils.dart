import 'package:flutter/services.dart';

class Fmt {
  static String money(int v) {
    final s = v.abs().toString();
    final b = StringBuffer();
    for (var i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) b.write('.');
      b.write(s[i]);
    }
    return '${v < 0 ? '-' : ''}${b.toString()}đ';
  }

  static String two(int n) => n.toString().padLeft(2, '0');
  static String date(DateTime d) => '${two(d.day)}/${two(d.month)}/${d.year}';
  static String time(DateTime d) => '${two(d.hour)}:${two(d.minute)}';
  static String monthKey(DateTime d) => '${d.year}-${two(d.month)}';

  static String monthLabel(String key) {
    final p = key.split('-');
    return 'Tháng ${int.parse(p[1])}/${p[0]}';
  }

  static DateTime monthStart(String key) {
    final p = key.split('-');
    return DateTime(int.parse(p[0]), int.parse(p[1]), 1);
  }

  static String shiftMonth(String key, int delta) {
    final s = monthStart(key);
    return monthKey(DateTime(s.year, s.month + delta, 1));
  }

  static const _weekdays = [
    'Thứ hai', 'Thứ ba', 'Thứ tư', 'Thứ năm', 'Thứ sáu', 'Thứ bảy', 'Chủ nhật'
  ];
  static String dayHeader(DateTime d) =>
      '${_weekdays[d.weekday - 1]}, ${two(d.day)}/${two(d.month)}';
}

int parseAmount(String s) => int.tryParse(s.replaceAll('.', '')) ?? 0;

/// Tự động thêm dấu chấm ngăn cách hàng nghìn khi nhập số tiền.
class ThousandsFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    final digits = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.isEmpty) return const TextEditingValue();
    final trimmed = digits.length > 12 ? digits.substring(0, 12) : digits;
    final text = Fmt.money(int.parse(trimmed)).replaceAll('đ', '');
    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }
}
