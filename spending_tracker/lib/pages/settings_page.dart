import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../state.dart';
import '../utils.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  String get _stamp {
    final n = DateTime.now();
    return '${n.year}${Fmt.two(n.month)}${Fmt.two(n.day)}_${Fmt.two(n.hour)}${Fmt.two(n.minute)}';
  }

  void _toast(String msg) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));

  Future<void> _share(String name, String content) async {
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/$name');
    await file.writeAsString(content);
        await SharePlus.instance.share(
        ShareParams(files: [XFile(file.path)], subject: name));
  }

  Future<void> _exportJson() async {
    try {
      final data = await appState.exportJson();
      await _share('chi_tieu_$_stamp.json',
          const JsonEncoder.withIndent('  ').convert(data));
    } catch (e) {
      if (mounted) _toast('Xuất thất bại: $e');
    }
  }

  Future<void> _exportCsv() async {
    try {
      await _share('chi_tieu_$_stamp.csv', await appState.exportCsv());
    } catch (e) {
      if (mounted) _toast('Xuất thất bại: $e');
    }
  }

  Future<void> _import() async {
    try {
            final picked = await FilePicker.pickFile();
      if (picked == null) return;
      final bytes = await picked.readAsBytes();
      final data = jsonDecode(utf8.decode(bytes));
      if (data is! Map<String, dynamic>) {
        throw const FormatException('File sao lưu không hợp lệ');
      }
      if (!mounted) return;
      final ok = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Khôi phục dữ liệu?'),
          content: const Text(
              'Toàn bộ giao dịch và ngân sách hiện tại sẽ bị thay thế bằng dữ liệu trong file.'),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Hủy')),
            FilledButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Khôi phục')),
          ],
        ),
      );
      if (ok != true) return;
      await appState.importJson(data);
      if (mounted) _toast('Khôi phục thành công');
    } catch (e) {
      if (mounted) _toast('Khôi phục thất bại: file không hợp lệ');
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: appState,
      builder: (context, _) => ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('Giao diện', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          SegmentedButton<ThemeMode>(
            segments: const [
              ButtonSegment(
                  value: ThemeMode.system,
                  label: Text('Hệ thống'),
                  icon: Icon(Icons.brightness_auto)),
              ButtonSegment(
                  value: ThemeMode.light,
                  label: Text('Sáng'),
                  icon: Icon(Icons.light_mode)),
              ButtonSegment(
                  value: ThemeMode.dark,
                  label: Text('Tối'),
                  icon: Icon(Icons.dark_mode)),
            ],
            selected: {appState.themeMode},
            onSelectionChanged: (s) => appState.setTheme(s.first),
          ),
          const SizedBox(height: 24),
          Text('Sao lưu & Khôi phục',
              style: Theme.of(context).textTheme.titleMedium),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.upload_file),
            title: const Text('Xuất sao lưu (JSON)'),
            subtitle:
                const Text('Đầy đủ giao dịch + ngân sách, dùng để khôi phục'),
            onTap: _exportJson,
          ),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.table_chart_outlined),
            title: const Text('Xuất giao dịch (CSV)'),
            subtitle: const Text('Mở được bằng Excel / Google Sheets'),
            onTap: _exportCsv,
          ),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.download),
            title: const Text('Khôi phục từ file JSON'),
            subtitle: const Text('Thay thế toàn bộ dữ liệu hiện tại'),
            onTap: _import,
          ),
          const SizedBox(height: 16),
          Text(
            'Ứng dụng hoạt động hoàn toàn offline. Dữ liệu chỉ lưu trên máy này — '
            'hãy xuất sao lưu định kỳ để tránh mất dữ liệu khi đổi máy hoặc gỡ app.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}
