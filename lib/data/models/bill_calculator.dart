// lib/services/bill_calculator.dart
import 'bill_item.dart';

class BillCalculator {
  final List<BillItem> items;
  final double taxPercent;
  final double servicePercent;
  final double discountNominal;

  BillCalculator({
    required this.items,
    required this.taxPercent,
    required this.servicePercent,
    required this.discountNominal,
  });

  double get subtotal => items.fold<double>(0, (s, i) => s + i.price);

  double get tax => subtotal * (taxPercent / 100);
  double get service => subtotal * (servicePercent / 100);
  double get grandTotal => subtotal + tax + service - discountNominal;

  Map<String, double> get memberTotals {
    final totals = <String, double>{};
    if (items.isEmpty || subtotal == 0) return totals;

    final memberSub = <String, double>{};
    for (final it in items) {
      memberSub[it.member] = (memberSub[it.member] ?? 0) + it.price;
    }

    final totalTax = tax;
    final totalService = service;
    final totalDiscount = discountNominal;

    memberSub.forEach((member, sub) {
      final prop = sub / subtotal;
      final memberTax = totalTax * prop;
      final memberService = totalService * prop;
      final memberDiscount = totalDiscount * prop;
      totals[member] = sub + memberTax + memberService - memberDiscount;
    });

    return totals;
  }
}
