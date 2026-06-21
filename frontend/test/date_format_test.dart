import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';

void main() {
  test('date formatting matches grid header expectations (d/M/yyyy)', () {
    final date = DateTime(2026, 6, 15);
    expect(DateFormat('d/M/yyyy').format(date), '15/6/2026');
  });

  test('day name formatting produces 3-letter abbreviation', () {
    final monday = DateTime(2026, 6, 15);
    expect(DateFormat('EEE').format(monday), 'Mon');
  });
}
