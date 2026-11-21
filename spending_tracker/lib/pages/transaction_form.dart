import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models.dart';
import '../state.dart';
import '../utils.dart';

class TransactionForm extends StatefulWidget {
  final TxItem? tx;
  const TransactionForm({super.key, this.tx});

  @override
  State<TransactionForm> createState() => _TransactionFormState();
}

class _TransactionFormState extends State<TransactionForm> {
  late bool _isExpense;
  late String _category;
  late DateTime _date;
  late final TextEditingController _amount;
  late final TextEditingController _note;

  @override
  void initState() {
    super.initState();
    final t = widget.tx;
    _isExpense = t?.isExpense ?? true;
    _category = t?.category ?? Categories.expense.first.id;
    _date = t?.date ?? DateTime.now();
    _amount = TextEditingController(
        text: t == null ? '' : Fmt.money(t.amount).replaceAll('đ', ''));
    _note = TextEditingController(text: t?.note ?? '');
  }

  @override
  void dispose() {
    _amount.dispose();
    _note.dispose();
    super.dispose();
  }

  void _addQuick(int v) {
    final total = parseAmount(_amount.text) + v;
    final text = Fmt.money(total).replaceAll('đ', '');
    _amount.value = TextEditingValue(
        text: text, selection: TextSelection.collapsed(offset: text.length));
  }

  Future<void> _pickDate() async {
    final d = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (d == null || !mounted) return;
    final t = await showTimePicker(
        context: context, initialTime: TimeOfDay.fromDateTime(_date));
    if (!mounted) return;
    setState(() => _date = DateTime(
        d.year, d.month, d.day, t?.hour ?? _date.hour, t?.minute ?? _date.minute));
  }

  Future<void> _save() async {
    final amount = parseAmount(_amount.text);
    if (amount <= 0) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Vui lòng nhập số tiền')));
      return;
    }
    await appState.saveTx(TxItem(
      id: widget.tx?.id,
      amount: amount,
      isExpense: _isExpense,
      category: _category,
      note: _note.text.trim(),
      date: _date,
    ));
    if (mounted) Navigator.pop(context);
  }

  Future<void> _delete() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xóa giao dịch?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Hủy')),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Xóa')),
        ],
      ),
    );
    if (ok != true) return;
    await appState.deleteTx(widget.tx!.id!);
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final cats = _isExpense ? Categories.expense : Categories.income;
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.tx == null ? 'Thêm giao dịch' : 'Sửa giao dịch'),
        actions: [
          if (widget.tx != null)
            IconButton(
                onPressed: _delete, icon: const Icon(Icons.delete_outline)),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          SegmentedButton<bool>(
            segments: const [
              ButtonSegment(value: true, label: Text('Chi')),
              ButtonSegment(value: false, label: Text('Thu')),
            ],
            selected: {_isExpense},
            onSelectionChanged: (s) => setState(() {
              _isExpense = s.first;
              _category =
                  (_isExpense ? Categories.expense : Categories.income).first.id;
            }),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _amount,
            autofocus: widget.tx == null,
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              ThousandsFormatter(),
            ],
            style: Theme.of(context).textTheme.headlineMedium,
            decoration: const InputDecoration(
              labelText: 'Số tiền',
              suffixText: 'đ',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: [
              for (final v in [10000, 50000, 100000, 500000])
                ActionChip(
                    label: Text('+${Fmt.money(v)}'),
                    onPressed: () => _addQuick(v)),
              ActionChip(
                  label: const Text('Xóa'),
                  avatar: const Icon(Icons.backspace_outlined, size: 16),
                  onPressed: () => _amount.clear()),
            ],
          ),
          const SizedBox(height: 16),
          Text('Danh mục', style: Theme.of(context).textTheme.labelLarge),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: [
              for (final c in cats)
                ChoiceChip(
                  avatar: Icon(c.icon, size: 18),
                  label: Text(c.name),
                  selected: _category == c.id,
                  onSelected: (_) => setState(() => _category = c.id),
                ),
            ],
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _note,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(
                labelText: 'Ghi chú', border: OutlineInputBorder()),
          ),
          const SizedBox(height: 8),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.event),
            title: Text('${Fmt.date(_date)}  ${Fmt.time(_date)}'),
            trailing: const Icon(Icons.edit_calendar_outlined),
            onTap: _pickDate,
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: _save,
            icon: const Icon(Icons.check),
            label: const Text('Lưu'),
            style:
                FilledButton.styleFrom(minimumSize: const Size.fromHeight(52)),
          ),
        ],
      ),
    );
  }
}
