import 'package:path/path.dart' as path;
import 'package:sqflite/sqflite.dart';

class DatabaseHelper {
  DatabaseHelper._();

  static final DatabaseHelper instance = DatabaseHelper._();

  Future<Database>? _databaseFuture;

  Future<Database> get database {
    return _databaseFuture ??= _openDatabase();
  }

  Future<Database> _openDatabase() async {
    try {
      final databasePath = path.join(
        await getDatabasesPath(),
        'bai09.db',
      );

      return await openDatabase(
        databasePath,
        version: 1,
        onCreate: (db, version) async {
          await db.execute('''
            CREATE TABLE tasks (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              title TEXT NOT NULL COLLATE NOCASE UNIQUE,
              description TEXT NOT NULL DEFAULT '',
              isCompleted INTEGER NOT NULL DEFAULT 0
                CHECK(isCompleted IN (0, 1))
            )
          ''');

          await db.execute('''
            CREATE TABLE students (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              name TEXT NOT NULL,
              email TEXT NOT NULL COLLATE NOCASE UNIQUE
            )
          ''');

          await db.execute('''
            CREATE TABLE expenses (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              content TEXT NOT NULL,
              amount INTEGER NOT NULL CHECK(amount > 0),
              note TEXT NOT NULL DEFAULT ''
            )
          ''');

          await db.execute('''
            CREATE TABLE users (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              email TEXT NOT NULL COLLATE NOCASE UNIQUE,
              passwordHash TEXT NOT NULL,
              salt TEXT NOT NULL,
              iterations INTEGER NOT NULL
            )
          ''');
        },
      );
    } catch (_) {
      _databaseFuture = null;
      rethrow;
    }
  }
}