import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models.dart';
import '../state.dart';
import '../utils.dart';

class BudgetPage extends StatelessWidget {
  const BudgetPage({super.key});

  static Color _color(double r) {
    if (r >= 1) return Colors.red.shade400;
    if (r >= 0.8) return Colors.orange.shade600;
    return Colors.teal.shade400;
  }

  Future<void> _editBudget(BuildContext context, Category c) async {
    final current = appState.budgets[c.id] ?? 0;
    final ctrl = TextEditingController(
        text: current == 0 ? '' : Fmt.money(current).replaceAll('đ', ''));
    final result = await showDialog<int>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Ngân sách ${c.name}'),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          keyboardType: TextInputType.number,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            ThousandsFormatter(),
          ],
          decoration: const InputDecoration(
              suffixText: 'đ', helperText: 'Để trống hoặc 0 để bỏ hạn mức'),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('Hủy')),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, parseAmount(ctrl.text)),
              child: const Text('Lưu')),
        ],
      ),
    );
    ctrl.dispose();
    if (result != null) await appState.setBudget(c.id, result);
  }

  Future<void> _copy(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Sao chép ngân sách?'),
        content: Text(
            'Ngân sách ${Fmt.monthLabel(appState.nextMonth)} sẽ được thay bằng ngân sách của ${Fmt.monthLabel(appState.currentMonth)}.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Hủy')),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Sao chép')),
        ],
      ),
    );
    if (ok == true) await appState.copyCurrentBudgetToNext();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: appState,
      builder: (context, _) {
        final isNext = appState.budgetMonth == appState.nextMonth;
        final total = appState.totalBudget;
        final spent = appState.totalSpent;
        final ratio = total == 0 ? 0.0 : spent / total;
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            SegmentedButton<bool>(
              segments: [
                ButtonSegment(
                    value: false,
                    label: Text(
                        'Tháng này (${appState.currentMonth.split('-')[1]})')),
                ButtonSegment(
                    value: true,
                    label:
                        Text('Tháng sau (${appState.nextMonth.split('-')[1]})')),
              ],
              selected: {isNext},
              onSelectionChanged: (s) => appState.setBudgetMonth(
                  s.first ? appState.nextMonth : appState.currentMonth),
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Tổng ngân sách ${Fmt.monthLabel(appState.budgetMonth)}',
                        style: Theme.of(context).textTheme.titleSmall),
                    const SizedBox(height: 8),
                    Text(total == 0 ? 'Chưa đặt ngân sách' : Fmt.money(total),
                        style: Theme.of(context).textTheme.headlineSmall),
                    if (total > 0) ...[
                      const SizedBox(height: 12),
                      _Bar(ratio: ratio),
                      const SizedBox(height: 8),
                      Text('Đã chi ${Fmt.money(spent)} (${(ratio * 100).round()}%)'
                          ' • ${spent > total ? 'Vượt' : 'Còn'} ${Fmt.money((total - spent).abs())}'),
                      if (ratio >= 0.8) _Warning(ratio: ratio),
                    ],
                  ],
                ),
              ),
            ),
            if (isNext)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: OutlinedButton.icon(
                  onPressed: () => _copy(context),
                  icon: const Icon(Icons.copy_all),
                  label: const Text('Sao chép ngân sách từ tháng này'),
                ),
              ),
            const SizedBox(height: 8),
            for (final c in Categories.expense) _row(context, c),
            const SizedBox(height: 8),
            Text(
              'Ngân sách được lưu theo từng tháng. Khi sang tháng mới, kế hoạch bạn đã đặt sẽ được giữ nguyên; '
              'nếu chưa đặt, app tự kế thừa từ tháng trước.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        );
      },
    );
  }

  Widget _row(BuildContext context, Category c) {
    final limit = appState.budgets[c.id] ?? 0;
    final used = appState.spent[c.id] ?? 0;
    final ratio = limit == 0 ? 0.0 : used / limit;
    return ListTile(
      contentPadding: EdgeInsets.zero,
      onTap: () => _editBudget(context, c),
      leading: CircleAvatar(child: Icon(c.icon)),
      title: Row(
        children: [
          Expanded(child: Text(c.name)),
          Text(limit == 0 ? 'Chưa đặt' : Fmt.money(limit),
              style: Theme.of(context).textTheme.bodyMedium),
        ],
      ),
      subtitle: limit == 0
          ? Text('Đã chi ${Fmt.money(used)}')
          : Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _Bar(ratio: ratio),
                  const SizedBox(height: 4),
                  Text(
                    ratio >= 1
                        ? 'Vượt ${Fmt.money(used - limit)} (${(ratio * 100).round()}%)'
                        : '${(ratio * 100).round()}% • còn ${Fmt.money(limit - used)}',
                    style: TextStyle(
                        color: ratio >= 0.8 ? _color(ratio) : null,
                        fontSize: 12),
                  ),
                ],
              ),
            ),
    );
  }
}

class _Bar extends StatelessWidget {
  final double ratio;
  const _Bar({required this.ratio});

  @override
  Widget build(BuildContext context) {
    return LinearProgressIndicator(
      value: math.min(1, ratio),
      minHeight: 10,
      borderRadius: BorderRadius.circular(6),
      color: BudgetPage._color(ratio),
    );
  }
}

class _Warning extends StatelessWidget {
  final double ratio;
  const _Warning({required this.ratio});

  @override
  Widget build(BuildContext context) {
    final c = BudgetPage._color(ratio);
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Row(
        children: [
          Icon(Icons.warning_amber_rounded, color: c, size: 20),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              ratio >= 1
                  ? 'Bạn đã vượt ngân sách tháng này!'
                  : 'Sắp chạm hạn mức ngân sách.',
              style: TextStyle(color: c, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}
