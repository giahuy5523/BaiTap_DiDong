import 'package:flutter/material.dart';
import '../common.dart';
import '../services/notification_service.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});
  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}
class _NotificationScreenState extends State<NotificationScreen> {
  bool busy = false;
  Future<void> run(Future<void> Function() action, String success) async {
    setState(() => busy = true);
    try {
      await action();
      if (mounted) message(context, success);
    } catch (e) {
      if (mounted) message(context, '$e', error: true);
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }
  Future<void> schedule(Duration delay, String title, String body) async {
    final service = NotificationService.instance;
    await service.ensurePermission(exact: true);
    await service.schedule(id: await service.newId(), title: title, body: body,
      time: DateTime.now().add(delay), payload: 'exercise1');
  }
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Thông báo')),
    body: Center(child: Padding(padding: const EdgeInsets.all(16),
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        ElevatedButton(onPressed: busy ? null : () => run(
          () => NotificationService.instance.show('Nhắc học Ngoại ngữ',
            'Bạn đã học 5 từ mới hôm nay chưa?'), 'Đã gửi thông báo.'),
          child: const Text('Gửi thông báo nhắc học Ngoại ngữ')),
        const SizedBox(height: 20),
        ElevatedButton(onPressed: busy ? null : () => run(
          () => schedule(const Duration(minutes: 2), 'Uống nước',
            'Đến giờ uống nước rồi!'), 'Đã đặt lịch sau 2 phút.'),
          child: const Text('Nhắc uống nước sau 2 phút')),
        const SizedBox(height: 20),
        ElevatedButton(onPressed: busy ? null : () => run(
          () => schedule(const Duration(minutes: 10), 'Nhắc học Ngoại ngữ',
            'Hãy ôn tập từ vựng!'), 'Đã đặt lịch sau 10 phút.'),
          child: const Text('Hẹn giờ học Ngoại ngữ sau 10 phút')),
      ]))),
  );
}
