import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

import 'models.dart';

class AppDb {
  AppDb._();
  static final AppDb instance = AppDb._();

  Database? _db;

  Future<Database> get db async => _db ??= await _open();

  Future<Database> _open() async {
    final path = p.join(await getDatabasesPath(), 'spending.db');
    return openDatabase(path, version: 1, onCreate: (d, v) async {
      await d.execute('CREATE TABLE transactions('
          'id INTEGER PRIMARY KEY AUTOINCREMENT,'
          'amount INTEGER NOT NULL,'
          'is_expense INTEGER NOT NULL,'
          'category TEXT NOT NULL,'
          'note TEXT NOT NULL,'
          'date INTEGER NOT NULL)');
      await d.execute('CREATE INDEX idx_tx_date ON transactions(date)');
      await d.execute('CREATE TABLE budgets('
          'month TEXT NOT NULL,'
          'category TEXT NOT NULL,'
          'amount INTEGER NOT NULL,'
          'PRIMARY KEY(month, category))');
      await d.execute(
          'CREATE TABLE settings(key TEXT PRIMARY KEY, value TEXT)');
    });
  }

  // ---- Giao dịch ----
  Future<List<TxItem>> txInRange(DateTime from, DateTime to) async {
    final d = await db;
    final rows = await d.query('transactions',
        where: 'date >= ? AND date < ?',
        whereArgs: [from.millisecondsSinceEpoch, to.millisecondsSinceEpoch],
        orderBy: 'date DESC, id DESC');
    return rows.map(TxItem.fromMap).toList();
  }

  Future<int> insertTx(TxItem t) async =>
      (await db).insert('transactions', t.toMap());

  Future<void> updateTx(TxItem t) async => (await db)
      .update('transactions', t.toMap(), where: 'id = ?', whereArgs: [t.id]);

  Future<void> deleteTx(int id) async =>
      (await db).delete('transactions', where: 'id = ?', whereArgs: [id]);

  Future<Map<String, int>> expenseByCategory(DateTime from, DateTime to) async {
    final rows = await (await db).rawQuery(
        'SELECT category, SUM(amount) AS s FROM transactions '
        'WHERE is_expense = 1 AND date >= ? AND date < ? GROUP BY category',
        [from.millisecondsSinceEpoch, to.millisecondsSinceEpoch]);
    return {for (final r in rows) r['category'] as String: (r['s'] as int)};
  }

  // ---- Ngân sách ----
  Future<Map<String, int>> budgets(String month) async {
    final rows =
        await (await db).query('budgets', where: 'month = ?', whereArgs: [month]);
    return {
      for (final r in rows) r['category'] as String: r['amount'] as int
    };
  }

  Future<void> setBudget(String month, String category, int amount) async {
    final d = await db;
    if (amount <= 0) {
      await d.delete('budgets',
          where: 'month = ? AND category = ?', whereArgs: [month, category]);
    } else {
      await d.insert(
          'budgets', {'month': month, 'category': category, 'amount': amount},
          conflictAlgorithm: ConflictAlgorithm.replace);
    }
  }

  Future<void> copyBudgets(String from, String to) async {
    final d = await db;
    await d.transaction((t) async {
      await t.delete('budgets', where: 'month = ?', whereArgs: [to]);
      await t.rawInsert(
          'INSERT INTO budgets(month, category, amount) '
          'SELECT ?, category, amount FROM budgets WHERE month = ?',
          [to, from]);
    });
  }

  /// Sang tháng mới mà chưa có ngân sách: tự động kế thừa tháng gần nhất trước đó.
  Future<void> ensureBudgetMonth(String month) async {
    final d = await db;
    final has = Sqflite.firstIntValue(await d.rawQuery(
            'SELECT COUNT(*) FROM budgets WHERE month = ?', [month])) ??
        0;
    if (has > 0) return;
    final prev = await d
        .rawQuery('SELECT MAX(month) AS m FROM budgets WHERE month < ?', [month]);
    final pm = prev.first['m'] as String?;
    if (pm != null) await copyBudgets(pm, month);
  }

  // ---- Cài đặt ----
  Future<String?> getSetting(String key) async {
    final rows = await (await db)
        .query('settings', where: 'key = ?', whereArgs: [key]);
    return rows.isEmpty ? null : rows.first['value'] as String?;
  }

  Future<void> setSetting(String key, String value) async =>
      (await db).insert('settings', {'key': key, 'value': value},
          conflictAlgorithm: ConflictAlgorithm.replace);

  // ---- Sao lưu / khôi phục ----
  Future<Map<String, dynamic>> exportAll() async {
    final d = await db;
    final txs = await d.query('transactions', orderBy: 'date ASC, id ASC');
    final bs = await d.query('budgets', orderBy: 'month ASC, category ASC');
    return {
      'app': 'spending_tracker',
      'version': 1,
      'exportedAt': DateTime.now().toIso8601String(),
      'transactions': txs.map((m) => TxItem.fromMap(m).toJson()).toList(),
      'budgets': bs
          .map((r) => {
                'month': r['month'],
                'category': r['category'],
                'amount': r['amount'],
              })
          .toList(),
    };
  }

  Future<List<TxItem>> allTx() async {
    final rows =
        await (await db).query('transactions', orderBy: 'date ASC, id ASC');
    return rows.map(TxItem.fromMap).toList();
  }

  /// Thay thế toàn bộ dữ liệu hiện tại bằng dữ liệu từ file sao lưu.
  Future<void> importAll(Map<String, dynamic> data) async {
    final txs = data['transactions'];
    final bs = data['budgets'];
    if (txs is! List || bs is! List) {
      throw const FormatException('File sao lưu không hợp lệ');
    }
    final items = txs
        .map((e) => TxItem.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
    final d = await db;
    await d.transaction((t) async {
      await t.delete('transactions');
      await t.delete('budgets');
      final batch = t.batch();
      for (final i in items) {
        batch.insert('transactions', i.toMap());
      }
      for (final e in bs) {
        final m = Map<String, dynamic>.from(e as Map);
        batch.insert(
            'budgets',
            {
              'month': m['month'] as String,
              'category': m['category'] as String,
              'amount': (m['amount'] as num).toInt(),
            },
            conflictAlgorithm: ConflictAlgorithm.replace);
      }
      await batch.commit(noResult: true);
    });
  }
}
