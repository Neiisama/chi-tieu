import 'package:flutter/material.dart';

class Category {
  final String id;
  final String name;
  final IconData icon;
  const Category(this.id, this.name, this.icon);
}

class Categories {
  static const expense = [
    Category('food', 'Ăn uống', Icons.restaurant),
    Category('transport', 'Di chuyển', Icons.directions_bus),
    Category('living', 'Sinh hoạt', Icons.home),
    Category('shopping', 'Mua sắm', Icons.shopping_bag),
    Category('fun', 'Giải trí', Icons.movie),
    Category('health', 'Sức khỏe', Icons.favorite),
    Category('other', 'Khác', Icons.more_horiz),
  ];
  static const income = [
    Category('salary', 'Lương', Icons.payments),
    Category('bonus', 'Thưởng', Icons.card_giftcard),
    Category('other_in', 'Thu khác', Icons.savings),
  ];
  static const all = [...expense, ...income];

  static Category byId(String id) =>
      all.firstWhere((c) => c.id == id, orElse: () => expense.last);
}

class TxItem {
  int? id;
  int amount;
  bool isExpense;
  String category;
  String note;
  DateTime date;

  TxItem({
    this.id,
    required this.amount,
    required this.isExpense,
    required this.category,
    this.note = '',
    required this.date,
  });

  Map<String, Object?> toMap() => {
        if (id != null) 'id': id,
        'amount': amount,
        'is_expense': isExpense ? 1 : 0,
        'category': category,
        'note': note,
        'date': date.millisecondsSinceEpoch,
      };

  factory TxItem.fromMap(Map<String, Object?> m) => TxItem(
        id: m['id'] as int?,
        amount: m['amount'] as int,
        isExpense: (m['is_expense'] as int) == 1,
        category: m['category'] as String,
        note: (m['note'] as String?) ?? '',
        date: DateTime.fromMillisecondsSinceEpoch(m['date'] as int),
      );

  Map<String, dynamic> toJson() => {
        'amount': amount,
        'isExpense': isExpense,
        'category': category,
        'note': note,
        'date': date.toIso8601String(),
      };

  factory TxItem.fromJson(Map<String, dynamic> j) => TxItem(
        amount: (j['amount'] as num).toInt(),
        isExpense: j['isExpense'] as bool,
        category: j['category'] as String,
        note: (j['note'] as String?) ?? '',
        date: DateTime.parse(j['date'] as String),
      );
}
