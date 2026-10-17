import '../models/expense.dart';
import '../utils/database_helper.dart';

class ExpenseController {
  final _helper = DatabaseHelper.instance;

  Future<List<Expense>> fetchExpenses() async {
    final db = await _helper.database;

    final result = await db.query(
      'expenses',
      orderBy: 'id DESC',
    );

    return result.map(Expense.fromMap).toList();
  }

  Future<void> save(Expense expense) async {
    if (expense.content.trim().isEmpty ||
        expense.amount <= 0 ||
        expense.amount > 1000000000000) {
      throw ArgumentError('Nội dung hoặc số tiền không hợp lệ.');
    }

    final db = await _helper.database;

    final data = {
      'content': expense.content.trim(),
      'amount': expense.amount,
      'note': expense.note.trim(),
    };

    if (expense.id == null) {
      await db.insert('expenses', data);
    } else {
      final count = await db.update(
        'expenses',
        data,
        where: 'id = ?',
        whereArgs: [expense.id],
      );

      if (count != 1) {
        throw StateError('Không tìm thấy khoản chi.');
      }
    }
  }

  Future<void> delete(int id) async {
    final db = await _helper.database;

    await db.delete(
      'expenses',
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}