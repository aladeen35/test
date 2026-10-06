import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import '../core/state.dart';
import 'prayer.dart';

/// تنبيهات مواقيت الصلاة — تُجدول لسبعة أيام قادمة وتعمل والتطبيق مقفول
class PrayerNotifications {
  static final _plugin = FlutterLocalNotificationsPlugin();
  static bool _ready = false;

  static bool get supported => !kIsWeb && (defaultTargetPlatform == TargetPlatform.android || defaultTargetPlatform == TargetPlatform.iOS);

  static Future<void> init() async {
    if (!supported || _ready) return;
    try {
      await _plugin.initialize(
        settings: const InitializationSettings(
          android: AndroidInitializationSettings('@mipmap/ic_launcher'),
          iOS: DarwinInitializationSettings(requestAlertPermission: false, requestBadgePermission: false, requestSoundPermission: false),
        ),
      );
      _ready = true;
    } catch (_) {}
  }

  /// يطلب الإذن؛ يعيد true عند الموافقة
  static Future<bool> requestPermission() async {
    if (!supported) return false;
    await init();
    try {
      final android = _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
      if (android != null) return await android.requestNotificationsPermission() ?? false;
      final ios = _plugin.resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>();
      return await ios?.requestPermissions(alert: true, sound: true, badge: true) ?? false;
    } catch (_) {
      return false;
    }
  }

  /// يعيد جدولة التنبيهات حسب الإعدادات الحالية
  static Future<void> reschedule(AppState s) async {
    if (!supported) return;
    await init();
    if (!_ready) return;
    try {
      await _plugin.cancelAll();
      if (!s.prayerNotify) return;
      const details = NotificationDetails(
        android: AndroidNotificationDetails('prayer', 'مواقيت الصلاة',
            channelDescription: 'تنبيه عند دخول وقت الصلاة', importance: Importance.high, priority: Priority.high),
        iOS: DarwinNotificationDetails(presentSound: true),
      );
      final now = DateTime.now();
      var id = 100;
      for (var day = 0; day < 7; day++) {
        final times = s.timesFor(sudanNow().add(Duration(days: day)));
        for (final k in fardKeys) {
          final t = times[k]!;
          if (t.isBefore(now)) continue;
          await _plugin.zonedSchedule(
            id: id++,
            title: '🕌 حان وقت صلاة ${prayerNames[k]}',
            body: '${s.city.name} — «إن الصلاة كانت على المؤمنين كتابًا موقوتًا»',
            scheduledDate: tz.TZDateTime.from(t.toUtc(), tz.UTC),
            notificationDetails: details,
            androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
          );
        }
      }
    } catch (e) {
      debugPrint('notifications: $e');
    }
  }
}
