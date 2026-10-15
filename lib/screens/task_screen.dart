import 'package:flutter/material.dart';
import '../common.dart';
import '../services/storage.dart';
import '../services/notification_service.dart';

class Task {
  final int id;
  final String title;
  final DateTime? time;
  final bool done;
  const Task({required this.id, required this.title, this.time, this.done = false});
  Task copy({DateTime? time, bool? done}) => Task(id: id, title: title,
      time: time ?? this.time, done: done ?? this.done);
  Map<String, dynamic> toJson() => {'id': id, 'title': title,
      'time': time?.toIso8601String(), 'done': done};
  factory Task.fromJson(Map<String, dynamic> json) => Task(
    id: json['id'] as int, title: json['title'] as String,
    time: json['time'] == null ? null : DateTime.parse(json['time'] as String),
    done: json['done'] as bool,
  );
}
class TaskScreen extends StatefulWidget {
  const TaskScreen({super.key});
  @override
  State<TaskScreen> createState() => _TaskScreenState();
}
class _TaskScreenState extends State<TaskScreen> {
  List<Task> tasks = [];
  bool busy = true, loadFailed = false;
  @override
  void initState() { super.initState(); load(); }
  Future<void> load() async {
    try {
      final items = await Storage.loadJson('tasks.txt');
      if (mounted) setState(() => tasks = items.map(Task.fromJson).toList());
    } catch (e) {
      loadFailed = true;
      if (mounted) message(context, 'Không đọc được nhiệm vụ: $e', error: true);
    } finally { if (mounted) setState(() => busy = false); }
  }
  Future<void> saveList(List<Task> next) async {
    await Storage.saveJson('tasks.txt', next.map((e) => e.toJson()).toList());
    if (mounted) setState(() => tasks = next);
  }
  Future<void> add() async {
    final task = await Navigator.push<Task>(context,
      MaterialPageRoute<Task>(builder: (_) => AddTaskScreen(existing: List.of(tasks))));
    if (task != null && mounted) setState(() => tasks = [...tasks, task]);
  }
  Future<void> reschedule(int index) async {
    final old = tasks[index];
    final time = await pickDateTime(context, initial: old.time);
    if (!mounted || time == null) return;
    if (!time.isAfter(DateTime.now())) {
      message(context, 'Chọn thời gian trong tương lai.', error: true); return;
    }
    setState(() => busy = true);
    final service = NotificationService.instance;
    bool scheduled = false, saved = false;
    try {
      await service.schedule(id: old.id, title: 'Nhắc nhiệm vụ', body: old.title,
          time: time, payload: 'task:${old.id}');
      scheduled = true;
      final next = List<Task>.of(tasks); next[index] = old.copy(time: time);
      await saveList(next); saved = true;
      if (mounted) message(context, 'Đã cập nhật lịch nhắc.');
    } catch (e) {
      if (scheduled && !saved) {
        try {
          if (old.time != null && old.time!.isAfter(DateTime.now())) {
            await service.schedule(id: old.id, title: 'Nhắc nhiệm vụ', body: old.title,
                time: old.time!, payload: 'task:${old.id}');
          } else { await service.cancel(old.id); }
        } catch (_) {}
      }
      if (mounted) message(context, '$e', error: true);
    } finally { if (mounted) setState(() => busy = false); }
  }
  Future<void> complete(int index) async {
    // Khóa thao tác trước khi hiện hộp thoại để không xác nhận hai lần.
    setState(() => busy = true);
    final old = tasks[index];
    try {
      final confirmed = await showDialog<bool>(context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('Xác nhận hoàn thành'),
          content: Text('Bạn đã hoàn thành nhiệm vụ "${old.title}"?'),
          actions: [TextButton(onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Chưa')),
            TextButton(onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Có'))]));
      if (confirmed != true || !mounted) return;
      final service = NotificationService.instance;
      await service.ensurePermission();
      final next = List<Task>.of(tasks); next[index] = old.copy(done: true);
      await saveList(next);
      await service.cancel(old.id);
      final count = next.where((e) => e.done).length;
      await service.show('Nhiệm vụ đã hoàn thành',
          'Bạn đã hoàn thành $count/${next.length} nhiệm vụ.');
    } catch (e) {
      if (mounted) message(context, 'Lỗi xử lý nhiệm vụ: $e', error: true);
    } finally { if (mounted) setState(() => busy = false); }
  }
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Nhiệm vụ mỗi ngày')),
    floatingActionButton: FloatingActionButton(
      onPressed: busy || loadFailed ? null : add, child: const Icon(Icons.add)),
    body: loadFailed ? const Center(child: Text('Không đọc được file tasks.txt.'))
      : busy ? const Center(child: CircularProgressIndicator())
      : tasks.isEmpty ? const Center(child: Text('Chưa có nhiệm vụ. Nhấn + để thêm.'))
      : ListView.builder(padding: const EdgeInsets.all(12), itemCount: tasks.length,
        itemBuilder: (_, i) {
          final task = tasks[i];
          return Card(child: ListTile(
            leading: Checkbox(value: task.done,
              onChanged: task.done ? null : (_) => complete(i)),
            title: Text(task.title, style: TextStyle(
              decoration: task.done ? TextDecoration.lineThrough : null)),
            subtitle: Text(task.done ? 'Đã hoàn thành' : task.time == null
              ? 'Chưa đặt lịch nhắc' : 'Nhắc lúc ${formatTime(task.time!)}'),
            trailing: IconButton(icon: const Icon(Icons.notifications_outlined),
              onPressed: task.done ? null : () => reschedule(i)),
          ));
        }),
  );
}
class AddTaskScreen extends StatefulWidget {
  final List<Task> existing;
  const AddTaskScreen({super.key, required this.existing});
  @override
  State<AddTaskScreen> createState() => _AddTaskScreenState();
}
class _AddTaskScreenState extends State<AddTaskScreen> {
  final title = TextEditingController();
  DateTime? time;
  bool busy = false;
  @override
  void dispose() { title.dispose(); super.dispose(); }
  Future<void> save() async {
    final text = title.text.trim();
    if (text.isEmpty) {
      message(context, 'Nhập tên nhiệm vụ.', error: true); return;
    }
    if (time != null && !time!.isAfter(DateTime.now())) {
      message(context, 'Giờ nhắc phải ở tương lai.', error: true); return;
    }
    setState(() => busy = true);
    final service = NotificationService.instance;
    int? id;
    bool scheduled = false, saved = false;
    try {
      id = await service.newId();
      final task = Task(id: id, title: text, time: time);
      if (time != null) {
        await service.schedule(id: id, title: 'Nhắc nhiệm vụ', body: text,
          time: time!, payload: 'task:$id'); scheduled = true;
      }
      await Storage.saveJson('tasks.txt',
          [...widget.existing, task].map((e) => e.toJson()).toList());
      saved = true;
      if (mounted) Navigator.pop(context, task);
    } catch (e) {
      if (scheduled && !saved && id != null) {
        try { await service.cancel(id); } catch (_) {}
      }
      if (mounted) message(context, '$e', error: true);
    } finally { if (mounted) setState(() => busy = false); }
  }
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Thêm nhiệm vụ mới')),
    body: SingleChildScrollView(padding: const EdgeInsets.all(16), child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      TextField(controller: title, enabled: !busy,
        decoration: const InputDecoration(labelText: 'Tên nhiệm vụ',
          border: OutlineInputBorder())), const SizedBox(height: 12),
      OutlinedButton(onPressed: busy ? null : () async {
        final result = await pickDateTime(context, initial: time);
        if (result != null && mounted) setState(() => time = result);
      }, child: Text(time == null ? 'Giờ nhắc (tùy chọn)' : formatTime(time!))),
      const SizedBox(height: 12),
      ElevatedButton(onPressed: busy ? null : save, child: const Text('Lưu nhiệm vụ')),
    ])),
  );
}
