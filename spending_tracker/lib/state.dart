import 'package:flutter/material.dart';

import 'db.dart';
import 'models.dart';
import 'utils.dart';

final AppState appState = AppState();

class AppState extends ChangeNotifier {
  final AppDb _db = AppDb.instance;

  ThemeMode themeMode = ThemeMode.system;
  String viewMonth = Fmt.monthKey(DateTime.now());
  String budgetMonth = Fmt.monthKey(DateTime.now());
  String query = '';
  String? filterCategory;

  List<TxItem> txs = [];
  Map<String, int> budgets = {};
  Map<String, int> spent = {};

  String get currentMonth => Fmt.monthKey(DateTime.now());
  String get nextMonth => Fmt.shiftMonth(currentMonth, 1);

  Future<void> init() async {
    final t = await _db.getSetting('theme');
    themeMode = ThemeMode.values
        .firstWhere((m) => m.name == t, orElse: () => ThemeMode.system);
    await reload();
  }

  Future<void> reload() async {
    await _db.ensureBudgetMonth(currentMonth);
    final vs = Fmt.monthStart(viewMonth);
    txs = await _db.txInRange(vs, DateTime(vs.year, vs.month + 1, 1));
    budgets = await _db.budgets(budgetMonth);
    final bs = Fmt.monthStart(budgetMonth);
    spent = await _db.expenseByCategory(bs, DateTime(bs.year, bs.month + 1, 1));
    notifyListeners();
  }

  // ---- Truy vấn dẫn xuất ----
  List<TxItem> get filtered {
    final q = query.trim().toLowerCase();
    return txs.where((t) {
      if (filterCategory != null && t.category != filterCategory) return false;
      if (q.isEmpty) return true;
      return t.note.toLowerCase().contains(q) ||
          Categories.byId(t.category).name.toLowerCase().contains(q) ||
          t.amount.toString().contains(q.replaceAll('.', ''));
    }).toList();
  }

  int get totalIncome =>
      txs.where((t) => !t.isExpense).fold(0, (s, t) => s + t.amount);
  int get totalExpense =>
      txs.where((t) => t.isExpense).fold(0, (s, t) => s + t.amount);
  int get totalBudget => budgets.values.fold(0, (s, v) => s + v);
  int get totalSpent => spent.values.fold(0, (s, v) => s + v);

  // ---- Thao tác ----
  Future<void> shiftViewMonth(int delta) async {
    viewMonth = Fmt.shiftMonth(viewMonth, delta);
    await reload();
  }

  void setQuery(String v) {
    query = v;
    notifyListeners();
  }

  void setFilter(String? id) {
    filterCategory = id;
    notifyListeners();
  }

  Future<void> saveTx(TxItem t) async {
    if (t.id == null) {
      await _db.insertTx(t);
    } else {
      await _db.updateTx(t);
    }
    await reload();
  }

  Future<void> deleteTx(int id) async {
    await _db.deleteTx(id);
    await reload();
  }

  Future<void> restoreTx(TxItem t) async {
    await _db.insertTx(t);
    await reload();
  }

  Future<void> setBudgetMonth(String month) async {
    budgetMonth = month;
    await reload();
  }

  Future<void> setBudget(String category, int amount) async {
    await _db.setBudget(budgetMonth, category, amount);
    await reload();
  }

  Future<void> copyCurrentBudgetToNext() async {
    await _db.copyBudgets(currentMonth, nextMonth);
    budgetMonth = nextMonth;
    await reload();
  }

  Future<void> setTheme(ThemeMode m) async {
    themeMode = m;
    notifyListeners();
    await _db.setSetting('theme', m.name);
  }

  // ---- Sao lưu ----
  Future<Map<String, dynamic>> exportJson() => _db.exportAll();

  Future<String> exportCsv() async {
    String esc(String s) => '"${s.replaceAll('"', '""')}"';
    final b = StringBuffer('\uFEFFngay,loai,danh_muc,so_tien,ghi_chu\n');
    for (final t in await _db.allTx()) {
      b.writeln([
        t.date.toIso8601String(),
        t.isExpense ? 'Chi' : 'Thu',
        esc(Categories.byId(t.category).name),
        t.amount,
        esc(t.note),
      ].join(','));
    }
    return b.toString();
  }

  Future<void> importJson(Map<String, dynamic> data) async {
    await _db.importAll(data);
    await reload();
  }
}
