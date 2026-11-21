import 'package:flutter_test/flutter_test.dart';
import 'package:spending_tracker/utils.dart';

void main() {
  test('định dạng tiền VNĐ', () {
    expect(Fmt.money(50000), '50.000đ');
    expect(Fmt.money(1234567), '1.234.567đ');
    expect(Fmt.money(0), '0đ');
  });

  test('chuyển tháng', () {
    expect(Fmt.shiftMonth('2026-12', 1), '2027-01');
    expect(Fmt.shiftMonth('2026-01', -1), '2025-12');
  });

  test('parse số tiền', () {
    expect(parseAmount('1.250.000'), 1250000);
    expect(parseAmount(''), 0);
  });
}
