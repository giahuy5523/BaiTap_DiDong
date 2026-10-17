import 'package:flutter/material.dart';

import '../controllers/task_controller.dart';
import '../models/task.dart';
import '../utils/ui_helpers.dart';

class TaskDetail extends StatefulWidget {
  final Task task;

  const TaskDetail({
    super.key,
    required this.task,
  });

  @override
  State<TaskDetail> createState() => _TaskDetailState();
}

class _TaskDetailState extends State<TaskDetail> {
  bool _saving = false;

  Future<void> _updateCompleted(bool? value) async {
    if (value == null) return;

    setState(() => _saving = true);

    try {
      final updatedTask = widget.task.copyWith(
        isCompleted: value,
      );

      await TaskController().updateTask(updatedTask);

      if (!mounted) return;

      Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        showMessage(context, errorMessage(e), isError: true);
      }
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Task Details'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Title',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            Text(widget.task.title),
            const SizedBox(height: 20),
            const Text(
              'Description',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            Text(widget.task.description),
            const SizedBox(height: 20),
            Row(
              children: [
                const Text('Completed'),
                Checkbox(
                  value: widget.task.isCompleted,
                  onChanged: _saving ? null : _updateCompleted,
                ),
              ],
            ),
            if (_saving) const LinearProgressIndicator(),
          ],
        ),
      ),
    );
  }
}