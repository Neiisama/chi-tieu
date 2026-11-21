import 'package:flutter/material.dart';

import '../models.dart';
import '../state.dart';
import '../utils.dart';
import 'transaction_form.dart';

final Color incomeColor = Colors.green.shade500;
final Color expenseColor = Colors.red.shade400;

class TransactionsPage extends StatefulWidget {
  const TransactionsPage({super.key});

  @override
  State<TransactionsPage> createState() => _TransactionsPageState();
}

class _TransactionsPageState extends State<TransactionsPage> {
  final _search = TextEditingController();

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  void _edit(TxItem t) => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => TransactionForm(tx: t)),
      );

  void _onDismissed(TxItem t) {
    appState.deleteTx(t.id!);
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(SnackBar(
        content: const Text('Đã xóa giao dịch'),
        action: SnackBarAction(
          label: 'Hoàn tác',
          onPressed: () => appState.restoreTx(t),
        ),
      ));
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: appState,
      builder: (context, _) {
        final list = appState.filtered;
        final scheme = Theme.of(context).colorScheme;
        return Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                    onPressed: () => appState.shiftViewMonth(-1),
                    icon: const Icon(Icons.chevron_left)),
                Text(Fmt.monthLabel(appState.viewMonth),
                    style: Theme.of(context).textTheme.titleMedium),
                IconButton(
                    onPressed: () => appState.shiftViewMonth(1),
                    icon: const Icon(Icons.chevron_right)),
              ],
            ),
            Card(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    _stat('Thu', appState.totalIncome, incomeColor),
                    _stat('Chi', appState.totalExpense, expenseColor),
                    _stat('Còn lại',
                        appState.totalIncome - appState.totalExpense, scheme.primary),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
              child: TextField(
                controller: _search,
                onChanged: appState.setQuery,
                decoration: InputDecoration(
                  hintText: 'Tìm theo ghi chú, danh mục, số tiền...',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: appState.query.isEmpty
                      ? null
                      : IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _search.clear();
                            appState.setQuery('');
                          }),
                  isDense: true,
                  border: const OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(24))),
                ),
              ),
            ),
            SizedBox(
              height: 48,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                children: [
                  _chip('Tất cả', null),
                  for (final c in Categories.all) _chip(c.name, c.id),
                ],
              ),
            ),
            Expanded(
              child: list.isEmpty
                  ? const Center(child: Text('Chưa có giao dịch nào'))
                  : ListView(
                      padding: const EdgeInsets.only(bottom: 88),
                      children: _buildItems(list),
                    ),
            ),
          ],
        );
      },
    );
  }

  Widget _stat(String label, int v, Color color) => Expanded(
        child: Column(
          children: [
            Text(label, style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: 4),
            FittedBox(
              child: Text(Fmt.money(v),
                  style: TextStyle(
                      color: color, fontWeight: FontWeight.bold, fontSize: 16)),
            ),
          ],
        ),
      );

  Widget _chip(String label, String? id) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: ChoiceChip(
          label: Text(label),
          selected: appState.filterCategory == id,
          onSelected: (_) => appState.setFilter(id),
        ),
      );

  List<Widget> _buildItems(List<TxItem> list) {
    final widgets = <Widget>[];
    String? lastDay;
    for (final t in list) {
      final day = Fmt.date(t.date);
      if (day != lastDay) {
        lastDay = day;
        widgets.add(Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: Text(Fmt.dayHeader(t.date),
              style: Theme.of(context).textTheme.labelLarge),
        ));
      }
      final cat = Categories.byId(t.category);
      final color = t.isExpense ? expenseColor : incomeColor;
      widgets.add(Dismissible(
        key: ValueKey('tx_${t.id}'),
        direction: DismissDirection.endToStart,
        background: Container(
          color: Colors.red,
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.only(right: 20),
          child: const Icon(Icons.delete, color: Colors.white),
        ),
        onDismissed: (_) => _onDismissed(t),
        child: ListTile(
          onTap: () => _edit(t),
          leading: CircleAvatar(
            backgroundColor: color.withValues(alpha: 0.15),
            child: Icon(cat.icon, color: color),
          ),
          title: Text(t.note.isEmpty ? cat.name : t.note),
          subtitle: Text('${cat.name} • ${Fmt.time(t.date)}'),
          trailing: Text(
            '${t.isExpense ? '-' : '+'}${Fmt.money(t.amount)}',
            style: TextStyle(color: color, fontWeight: FontWeight.w600),
          ),
        ),
      ));
    }
    return widgets;
  }
}
