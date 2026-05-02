import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:timezone/timezone.dart' as tz;
import '../models/notification_model.dart';

class NotificationController extends ChangeNotifier {
  List<NotificationModel> userNotifications = [];
  bool isLoading = true;

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  RealtimeChannel? _realtimeChannel;

  Future<void> initNotifications() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings initializationSettings =
        InitializationSettings(android: initializationSettingsAndroid);

    await flutterLocalNotificationsPlugin.initialize(initializationSettings);
    scheduleDailyNineAMNotification();
  }

  Future<void> scheduleDailyNineAMNotification() async {
    final tz.TZDateTime now =
        tz.TZDateTime.now(tz.getLocation('Asia/Jakarta'));
    tz.TZDateTime scheduledDate = tz.TZDateTime(
        tz.getLocation('Asia/Jakarta'), now.year, now.month, now.day, 9, 0);

    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    await flutterLocalNotificationsPlugin.zonedSchedule(
      0,
      'Reminder Harian 💗',
      'Ayo koleksi pc bias mu hari ini!',
      scheduledDate,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'daily_reminder_channel',
          'Daily Reminder',
          channelDescription: 'Pengingat harian untuk koleksi PC',
          importance: Importance.max,
          priority: Priority.high,
          color: Color(0xFFCF7486),
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  Future<void> loadUserNotifications() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    isLoading = true;
    notifyListeners();

    try {
      final data = await Supabase.instance.client
          .from('notifications')
          .select()
          .eq('target_user_id', user.id)
          .order('created_at', ascending: false);

      userNotifications = (data as List<dynamic>)
          .map((e) => NotificationModel.fromMap(Map<String, dynamic>.from(e)))
          .toList();
    } catch (e) {
      debugPrint("Error load notifications: $e");
    }

    isLoading = false;
    notifyListeners();
  }

  void subscribeUserNotifications() {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    _realtimeChannel = Supabase.instance.client
        .channel('user_notifications_${user.id}')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'notifications',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'target_user_id',
            value: user.id,
          ),
          callback: (payload) {
            final newNotif = NotificationModel.fromMap(
                Map<String, dynamic>.from(payload.newRecord));
            userNotifications.insert(0, newNotif);
            notifyListeners();
            _showLocalNotification(newNotif.title, newNotif.message);
          },
        )
        .subscribe();
  }

  Future<void> _showLocalNotification(String title, String body) async {
    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
      'collect_approval_channel',
      'Collect Approval',
      channelDescription: 'Notifikasi persetujuan collect photocard',
      importance: Importance.max,
      priority: Priority.high,
      color: Color(0xFFCF7486),
    );

    await flutterLocalNotificationsPlugin.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title,
      body,
      const NotificationDetails(android: androidDetails),
    );
  }

  Future<void> markAsRead(String id) async {
    final index = userNotifications.indexWhere((n) => n.id == id);
    if (index != -1) {
      userNotifications[index].isRead = true;
      notifyListeners();

      try {
        await Supabase.instance.client
            .from('notifications')
            .update({'is_read': true})
            .eq('id', id);
      } catch (e) {
        debugPrint("Error mark as read: $e");
      }
    }
  }

  @override
  void dispose() {
    _realtimeChannel?.unsubscribe();
    super.dispose();
  }
}
