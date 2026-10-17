import 'package:flutter/material.dart';

import 'views/auth_screen.dart';
import 'views/expense_screen.dart';
import 'views/student_screen.dart';
import 'views/task_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Bài 09 SQLite',
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.blue,
        inputDecorationTheme: const InputDecorationTheme(
          border: OutlineInputBorder(),
        ),
      ),
      home: const ExerciseMenu(),
    );
  }
}

class ExerciseMenu extends StatelessWidget {
  const ExerciseMenu({super.key});

  @override
  Widget build(BuildContext context) {
    final titles = [
      'Công việc: hướng dẫn và bài 1 tại lớp',
      'Sinh viên: bài 2 tại lớp',
      'Chi tiêu: bài 1 về nhà',
      'Tài khoản: bài 2 về nhà',
    ];

    final icons = [
      Icons.task,
      Icons.school,
      Icons.payments,
      Icons.login,
    ];

    final screens = <Widget>[
      const TaskScreen(),
      const StudentScreen(),
      const ExpenseScreen(),
      const AuthScreen(),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Bài 09: SQLite'),
      ),
      body: ListView.builder(
        itemCount: titles.length,
        itemBuilder: (context, index) {
          return ListTile(
            leading: Icon(icons[index]),
            title: Text(titles[index]),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => screens[index],
                ),
              );
            },
          );
        },
      ),
    );
  }
}