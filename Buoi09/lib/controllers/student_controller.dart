import '../models/sinh_vien.dart';
import '../utils/database_helper.dart';
import '../utils/validation.dart';

class StudentController {
  final _helper = DatabaseHelper.instance;

  Future<List<SinhVien>> search(String query) async {
    final db = await _helper.database;
    final text = query.trim();
    final pattern = '%${escapeLike(text)}%';

    final result = await db.query(
      'students',
      where: text.isEmpty
          ? null
          : r"name LIKE ? ESCAPE '\' OR email LIKE ? ESCAPE '\'",
      whereArgs: text.isEmpty ? null : [pattern, pattern],
      orderBy: 'id DESC',
    );

    return result.map(SinhVien.fromMap).toList();
  }

  Future<void> save(SinhVien student) async {
    if (requiredText(student.name) != null ||
        emailError(student.email) != null) {
      throw ArgumentError('Nhập tên và email hợp lệ.');
    }

    final db = await _helper.database;

    final data = {
      'name': student.name.trim(),
      'email': student.email.trim().toLowerCase(),
    };

    if (student.id == null) {
      await db.insert('students', data);
    } else {
      final count = await db.update(
        'students',
        data,
        where: 'id = ?',
        whereArgs: [student.id],
      );

      if (count != 1) {
        throw StateError('Không tìm thấy sinh viên.');
      }
    }
  }

  Future<void> delete(int id) async {
    final db = await _helper.database;

    await db.delete(
      'students',
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}