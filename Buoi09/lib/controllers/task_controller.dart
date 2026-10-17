import '../models/task.dart';
import '../utils/database_helper.dart';
import '../utils/validation.dart';

class TaskController {
  final _helper = DatabaseHelper.instance;

  Future<int> insertTask(Task task) async {
    if (task.title.trim().isEmpty) {
      throw ArgumentError('Nhập tên công việc.');
    }

    final db = await _helper.database;

    return db.insert('tasks', {
      'title': task.title.trim(),
      'description': task.description.trim(),
      'isCompleted': task.isCompleted ? 1 : 0,
    });
  }

  Future<void> updateTask(Task task) async {
    if (task.id == null) {
      throw ArgumentError('Công việc chưa có ID.');
    }

    final db = await _helper.database;

    final count = await db.update(
      'tasks',
      {
        'title': task.title,
        'description': task.description,
        'isCompleted': task.isCompleted ? 1 : 0,
      },
      where: 'id = ?',
      whereArgs: [task.id],
    );

    if (count != 1) {
      throw StateError('Không tìm thấy công việc.');
    }
  }

  Future<void> deleteTask(int id) async {
    final db = await _helper.database;

    await db.delete(
      'tasks',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<bool> isTaskExist(String title) async {
    final db = await _helper.database;

    final result = await db.query(
      'tasks',
      columns: ['id'],
      where: 'title = ? COLLATE NOCASE',
      whereArgs: [title.trim()],
      limit: 1,
    );

    return result.isNotEmpty;
  }

  Future<List<Task>> fetchTasks() {
    return searchTasks('');
  }

  Future<List<Task>> searchTasks(String query) async {
    final db = await _helper.database;
    final text = query.trim();
    final pattern = '%${escapeLike(text)}%';

    final result = await db.query(
      'tasks',
      where: text.isEmpty
          ? null
          : r"title LIKE ? ESCAPE '\' OR description LIKE ? ESCAPE '\'",
      whereArgs: text.isEmpty ? null : [pattern, pattern],
      orderBy: 'id ASC',
    );

    return result.map(Task.fromMap).toList();
  }
}