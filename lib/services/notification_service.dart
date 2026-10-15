import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;
import 'storage.dart';

class NotificationService {
  NotificationService._();
  static final instance = NotificationService._();
  final _plugin = FlutterLocalNotificationsPlugin();
  int _lastId = 0;
  // Tuần tự cấp ID và ghi file, kể cả khi nhiều màn hình cùng yêu cầu.
  Future<void> _idQueue = Future<void>.value();

  Future<void> init() async {
    tzdata.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('Asia/Ho_Chi_Minh'));
    await _plugin.initialize(const InitializationSettings(
      android: AndroidInitializationSettings('ic_stat_notify'),
    ));
    _lastId = int.tryParse(await Storage.read('notification_id.txt') ?? '') ?? 0;
  }

  Future<int> newId() {
    final result = _idQueue.then((_) async {
      final id = _lastId + 1;
      if (id >= 2147483647) throw StateError('Đã hết ID thông báo.');
      await Storage.write('notification_id.txt', '$id');
      _lastId = id;
      return id;
    });
    _idQueue = result.then<void>((_) {}, onError: (Object _, StackTrace __) {});
    return result;
  }

  Future<void> ensurePermission({bool exact = false}) async {
    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (android == null) throw StateError('Bản bài tập này chạy trên Android.');
    var enabled = await android.areNotificationsEnabled();
    if (enabled != true) {
      enabled = await android.requestNotificationsPermission();
    }
    if (enabled != true) {
      throw StateError('Bạn cần bật quyền thông báo trong Cài đặt ứng dụng.');
    }
    if (exact && await android.canScheduleExactNotifications() != true) {
      await android.requestExactAlarmsPermission();
      if (await android.canScheduleExactNotifications() != true) {
        throw StateError('Hãy bật quyền Báo thức và lời nhắc rồi thử lại.');
      }
    }
  }

  NotificationDetails _details(String channel, String name) =>
      NotificationDetails(android: AndroidNotificationDetails(
        channel, name,
        importance: Importance.max, priority: Priority.high,
        icon: 'ic_stat_notify',
      ));

  Future<void> show(String title, String body) async {
    await ensurePermission();
    await _plugin.show(await newId(), title, body,
        _details('status_channel', 'Thông báo kết quả'));
  }

  Future<void> schedule({required int id, required String title,
    required String body, required DateTime time,
    required String payload}) async {
    if (!time.isAfter(DateTime.now())) {
      throw ArgumentError('Thời gian nhắc phải ở tương lai.');
    }
    await ensurePermission(exact: true);
    if (!time.isAfter(DateTime.now())) {
      throw ArgumentError('Thời gian đã qua trong lúc cấp quyền. Hãy chọn lại.');
    }
    await _plugin.zonedSchedule(
      id, title, body, tz.TZDateTime.from(time, tz.local),
      _details('reminder_channel', 'Lịch nhắc'),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      payload: payload,
    );
  }

  Future<void> cancel(int id) => _plugin.cancel(id);
  Future<List<PendingNotificationRequest>> pending() =>
      _plugin.pendingNotificationRequests();
}
