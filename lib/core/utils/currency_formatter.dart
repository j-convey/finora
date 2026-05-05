/// Formats [amount] as a USD currency string, e.g. $1,234.56
String formatCurrency(double amount, {bool showSign = false}) {
  final isNegative = amount < 0;
  final cents = (amount.abs() * 100).round();
  final dollars = cents ~/ 100;
  final centsPart = (cents % 100).toString().padLeft(2, '0');

  final dollarsStr = dollars.toString();
  final buffer = StringBuffer();
  for (int i = 0; i < dollarsStr.length; i++) {
    if (i > 0 && (dollarsStr.length - i) % 3 == 0) buffer.write(',');
    buffer.write(dollarsStr[i]);
  }

  final result = '\$${buffer.toString()}.$centsPart';
  if (isNegative) return '-$result';
  if (showSign) return '+$result';
  return result;
}
