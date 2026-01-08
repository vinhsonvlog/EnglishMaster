import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:get/get.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:flutter/material.dart';


class NotificationService extends GetxService {
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
  FlutterLocalNotificationsPlugin();

  // Khởi tạo Service
  Future<NotificationService> init() async {
    // 1. Cấu hình cho Android
    const AndroidInitializationSettings initializationSettingsAndroid =
    AndroidInitializationSettings('@mipmap/ic_launcher');

    // 2. Cấu hình cho iOS
    const DarwinInitializationSettings initializationSettingsDarwin =
    DarwinInitializationSettings(
      requestSoundPermission: true,
      requestBadgePermission: true,
      requestAlertPermission: true,
    );

    // 3. Tổng hợp cấu hình
    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsDarwin,
    );

    // 4. Khởi tạo plugin
    await flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        // Xử lý khi người dùng bấm vào thông báo
        if (response.payload != null) {
          print('User tapped notification with payload: ${response.payload}');
          Get.toNamed('/lesson', arguments: response.payload);
        }
      },
    );

    // 5. Khởi tạo Timezone (để lên lịch)
    tz.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('Asia/Ho_Chi_Minh'));

    return this;
  }

  // --- HÀM HIỂN THỊ THÔNG BÁO NGAY LẬP TỨC ---
  Future<void> showNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
    AndroidNotificationDetails(
      'english_master_channel',
      'Học tập',
      channelDescription: 'Thông báo nhắc nhở học tập',
      importance: Importance.max,
      priority: Priority.high,
      showWhen: true,
    );

    const NotificationDetails platformChannelSpecifics =
    NotificationDetails(android: androidPlatformChannelSpecifics);

    await flutterLocalNotificationsPlugin.show(
      id,
      title,
      body,
      platformChannelSpecifics,
      payload: payload,
    );
  }

  // --- HÀM LÊN LỊCH THÔNG BÁO (NHẮC HỌC BÀI) ---
  Future<void> scheduleDailyReminder() async {
    await flutterLocalNotificationsPlugin.zonedSchedule(
      0,
      'Đã đến giờ học!',
      'Duy trì Streak của bạn bằng cách hoàn thành 1 bài học ngay.',
      _nextInstanceOfTime(15, 20),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'daily_reminder_channel',
          'Nhắc nhở hàng ngày',
          channelDescription: 'Nhắc nhở học tiếng Anh mỗi ngày',
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
      UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time, // Lặp lại theo thời gian
    );
  }

  // Tính toán thời gian cho lần nhắc tiếp theo
  tz.TZDateTime _nextInstanceOfTime(int hour, int minute) {
    final tz.TZDateTime now = tz.TZDateTime.now(tz.local);
    tz.TZDateTime scheduledDate =
    tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }
    return scheduledDate;
  }

  // Hàm xin quyền (cần cho Android 13+)
  Future<void> requestPermissions() async {
    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();

  }
}