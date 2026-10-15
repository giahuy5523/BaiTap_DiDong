import 'package:flutter/material.dart';
import '../common.dart';
import '../services/storage.dart';
import '../services/notification_service.dart';

class Todo {
  final String title;
  final DateTime time;
  final int? reminderId;
  Todo(this.title, this.time, {this.reminderId});
  // Mã hóa tên để dấu | hoặc xuống dòng không làm hỏng file.
  String toLine() => '${Uri.encodeComponent(title)}|${time.toIso8601String()}'
      '${reminderId == null ? '' : '|$reminderId'}';
  factory Todo.fromLine(String line) {
    final parts = line.split('|');
    if (parts.length < 2 || parts.length > 3) {
      throw const FormatException('Dòng todo không hợp lệ.');
    }
    return Todo(Uri.decodeComponent(parts[0]), DateTime.parse(parts[1]),
        reminderId: parts.length == 3 ? int.parse(parts[2]) : null);
  }
}
class TodoScreen extends StatefulWidget {
  final bool withReminder;
  const TodoScreen({super.key, this.withReminder = false});
  @override
  State<TodoScreen> createState() => _TodoScreenState();
}
class _TodoScreenState extends State<TodoScreen> {
  final controller = TextEditingController();
  List<Todo> todos = [];
  DateTime? selectedTime;
  bool busy = true;
  bool loadFailed = false;
  String get filename => widget.withReminder ? 'todo_reminder.txt' : 'todo.txt';
  @override
  void initState() { super.initState(); load(); }
  @override
  void dispose() { controller.dispose(); super.dispose(); }
  Future<void> load() async {
    try {
      final content = await Storage.read(filename);
      final items = (content ?? '').split('\n').where((e) => e.trim().isNotEmpty)
          .map(Todo.fromLine).toList();
      if (mounted) setState(() { todos = items; loadFailed = false; });
    } catch (e) {
      loadFailed = true;
      if (mounted) message(context, 'Không đọc được file: $e', error: true);
    } finally { if (mounted) setState(() => busy = false); }
  }
  Future<void> add() async {
    final title = controller.text.trim();
    final time = selectedTime;
    if (title.isEmpty || time == null) {
      message(context, 'Nhập tên công việc và chọn thời gian.', error: true); return;
    }
    if (widget.withReminder && !time.isAfter(DateTime.now())) {
      message(context, 'Chọn thời gian trong tương lai.', error: true); return;
    }
    setState(() => busy = true);
    final service = NotificationService.instance;
    int? id;
    bool scheduled = false;
    bool saved = false;
    try {
      if (widget.withReminder) {
        id = await service.newId();
        await service.schedule(id: id, title: 'Nhắc công việc', body: title,
            time: time, payload: 'todo:$id');
        scheduled = true;
      }
      final next = [...todos, Todo(title, time, reminderId: id)];
      await Storage.write(filename, next.map((e) => e.toLine()).join('\n'));
      saved = true;
      if (mounted) setState(() {
        todos = next; controller.clear(); selectedTime = null;
      });
      if (widget.withReminder) {
        await service.show('Đã thêm lịch công việc', '$title lúc ${formatTime(time)}');
      }
      if (mounted) message(context, 'Đã lưu công việc.');
    } catch (e) {
      if (scheduled && !saved && id != null) {
        try { await service.cancel(id); } catch (_) {}
      }
      if (mounted) message(context,
          saved ? 'Đã lưu lịch, nhưng không gửi được thông báo xác nhận: $e' : '$e',
          error: true);
    } finally { if (mounted) setState(() => busy = false); }
  }
  @override
  Widget build(BuildContext context) {
    final colors = [Colors.red.shade100, Colors.green.shade100,
      Colors.blue.shade100, Colors.yellow.shade100, Colors.purple.shade100];
    return Scaffold(appBar: AppBar(title: Text(
      widget.withReminder ? 'Todo có lịch nhắc' : 'Todo App')),
      body: Padding(padding: const EdgeInsets.all(16), child: Column(children: [
        TextField(controller: controller, enabled: !busy && !loadFailed,
          decoration: const InputDecoration(labelText: 'Tên công việc',
            border: OutlineInputBorder())),
        const SizedBox(height: 10),
        Row(children: [Expanded(child: Text(selectedTime == null
          ? 'Chưa chọn thời gian' : formatTime(selectedTime!))),
          OutlinedButton(onPressed: busy || loadFailed ? null : () async {
            final result = await pickDateTime(context, initial: selectedTime);
            if (result != null && mounted) setState(() => selectedTime = result);
          }, child: const Text('Chọn thời gian'))]),
        ElevatedButton(onPressed: busy || loadFailed ? null : add,
          child: const Text('Lưu')),
        if (loadFailed) const Text('File lỗi. Kiểm tra file trước khi tiếp tục.'),
        const SizedBox(height: 20),
        Expanded(child: busy ? const Center(child: CircularProgressIndicator())
          : ListView.builder(itemCount: todos.length, itemBuilder: (_, i) =>
            Card(color: colors[i % colors.length], child: ListTile(
              leading: const Icon(Icons.task), title: Text(todos[i].title),
              subtitle: Text(formatTime(todos[i].time))))))
      ])));
  }
}
