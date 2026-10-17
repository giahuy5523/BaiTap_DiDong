import 'package:flutter/material.dart';
import 'services/notification_service.dart';
import 'screens/notification_screen.dart';
import 'screens/todo_screen.dart';
import 'screens/vocabulary_screen.dart';
import 'screens/task_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await NotificationService.instance.init();
    runApp(const MyApp());
  } catch (e) {
    runApp(MaterialApp(home: Scaffold(body: Center(
      child: Padding(padding: const EdgeInsets.all(24),
        child: Text('Không khởi tạo được ứng dụng: $e'))))));
  }
}
class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
    debugShowCheckedModeBanner: false,
    title: 'Bài 08: Notification và File',
    theme: ThemeData(colorSchemeSeed: Colors.blue,
        scaffoldBackgroundColor: Colors.white, useMaterial3: true),
    home: const ExerciseMenu(),
  );
}
class ExerciseMenu extends StatelessWidget {
  const ExerciseMenu({super.key});
  @override
  Widget build(BuildContext context) {
    final titles = ['Bài 1: Thông báo học và uống nước', 'Bài 2: Todo lưu file',
      'Bài 3: Todo có lịch nhắc', 'Bài 4 tại lớp: Học từ vựng',
      'Bài 4 về nhà: Nhiệm vụ mỗi ngày'];
    final screens = <Widget>[const NotificationScreen(), const TodoScreen(),
      const TodoScreen(withReminder: true), const VocabularyScreen(),
      const TaskScreen()];
    return Scaffold(appBar: AppBar(title: const Text('Bài 08')),
      body: ListView.builder(itemCount: titles.length,
        itemBuilder: (context, i) => ListTile(title: Text(titles[i]),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => Navigator.push(context,
            MaterialPageRoute<void>(builder: (_) => screens[i])))));
  }
}
