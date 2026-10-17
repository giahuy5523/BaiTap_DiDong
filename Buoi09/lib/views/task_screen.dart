import 'package:flutter/material.dart';

import '../controllers/task_controller.dart';
import '../models/task.dart';
import '../utils/ui_helpers.dart';
import 'task_detail.dart';

class TaskScreen extends StatefulWidget {
  const TaskScreen({super.key});

  @override
  State<TaskScreen> createState() => _TaskScreenState();
}

class _TaskScreenState extends State<TaskScreen> {
  final _controller = TaskController();
  final _title = TextEditingController();
  final _description = TextEditingController();
  final _search = TextEditingController();

  List<Task> _tasks = [];
  Task? _selectedTask;
  bool _busy = true;
  String? _error;
  int _requestId = 0;

  @override
  void initState() {
    super.initState();
    _loadTasks();
  }

  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    _search.dispose();
    super.dispose();
  }

  Future<void> _loadTasks() async {
    final requestId = ++_requestId;

    try {
      final tasks = await _controller.searchTasks(_search.text);

      if (!mounted || requestId != _requestId) return;

      setState(() {
        _tasks = tasks;
        _error = null;
      });
    } catch (e) {
      if (mounted && requestId == _requestId) {
        setState(() => _error = errorMessage(e));
      }
    } finally {
      if (mounted && requestId == _requestId) {
        setState(() => _busy = false);
      }
    }
  }

  Future<void> _addTask() async {
    if (_title.text.trim().isEmpty) {
      showMessage(context, 'Nhập Title.', isError: true);
      return;
    }

    setState(() => _busy = true);

    try {
      await _controller.insertTask(
        Task(
          title: _title.text,
          description: _description.text,
        ),
      );

      _title.clear();
      _description.clear();
      _selectedTask = null;

      await _loadTasks();
    } catch (e) {
      if (mounted) {
        showMessage(context, errorMessage(e), isError: true);
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _deleteTask() async {
    if (_tasks.isEmpty) return;

    final task = _selectedTask ?? _tasks.last;
    setState(() => _busy = true);

    try {
      final confirmed = await confirmDelete(context, task.title);

      if (!confirmed || !mounted) return;

      await _controller.deleteTask(task.id!);

      _selectedTask = null;
      _title.clear();
      _description.clear();

      await _loadTasks();
    } catch (e) {
      if (mounted) {
        showMessage(context, errorMessage(e), isError: true);
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _openDetail(Task task) async {
    final changed = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => TaskDetail(task: task),
      ),
    );

    if (changed == true && mounted) {
      _selectedTask = null;
      await _loadTasks();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Task List')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _title,
              enabled: !_busy,
              decoration: const InputDecoration(labelText: 'Title'),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _description,
              enabled: !_busy,
              decoration: const InputDecoration(
                labelText: 'Description',
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: _busy ? null : _addTask,
                    child: const Text('Add Task'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _busy || _tasks.isEmpty
                        ? null
                        : _deleteTask,
                    child: const Text('Delete Task'),
                  ),
                ),
              ],
            ),
            if (_selectedTask != null)
              Text('Đang chọn: ${_selectedTask!.title}'),
            const SizedBox(height: 10),
            TextField(
              controller: _search,
              enabled: !_busy,
              decoration: const InputDecoration(
                labelText: 'Tìm tên hoặc mô tả',
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: (_) {
                setState(() => _selectedTask = null);
                _loadTasks();
              },
            ),
            const SizedBox(height: 10),
            Expanded(
              child: _busy
                  ? const Center(child: CircularProgressIndicator())
                  : _error != null
                  ? Center(child: Text(_error!))
                  : _tasks.isEmpty
                  ? const Center(child: Text('Không có công việc.'))
                  : ListView.builder(
                      itemCount: _tasks.length,
                      itemBuilder: (context, index) {
                        final task = _tasks[index];

                        return Card(
                          color: task.isCompleted
                              ? Colors.green.shade100
                              : Colors.white,
                          child: ListTile(
                            selected: _selectedTask?.id == task.id,
                            title: Text(task.title),
                            subtitle: Text(task.description),
                            trailing: IconButton(
                              icon: const Icon(Icons.edit),
                              onPressed: () => _openDetail(task),
                            ),
                            onTap: () {
                              setState(() {
                                _selectedTask = task;
                                _title.text = task.title;
                                _description.text = task.description;
                              });
                            },
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}