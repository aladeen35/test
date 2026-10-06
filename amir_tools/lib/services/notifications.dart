import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import '../core/state.dart';
import 'prayer.dart';
import '../core/i18n.dart';

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
      // نلغي تنبيهات الصلاة فقط (المعرّفات 100–199) حتى لا تُمسح تنبيهات الدواء
      for (var i = 100; i < 200; i++) {
        await _plugin.cancel(id: i);
      }
      if (!s.prayerNotify) return;
      final details = NotificationDetails(
        android: AndroidNotificationDetails('prayer', tr('مواقيت الصلاة', 'Prayer times'),
            channelDescription: tr('تنبيه عند دخول وقت الصلاة', 'Alert at prayer time'), importance: Importance.high, priority: Priority.high),
        iOS: const DarwinNotificationDetails(presentSound: true),
      );
      final now = DateTime.now();
      var id = 100;
      for (var day = 0; day < 7; day++) {
        final times = s.timesFor(sudanNow().add(Duration(days: day)));
        for (final k in fardKeys) {
          final at = times[k]!;
          if (at.isBefore(now)) continue;
          await _plugin.zonedSchedule(
            id: id++,
            title: '🕌 ${t('حان وقت صلاة', 'حان وقت صلاة', 'Time for')} ${prayerNames[k]}',
            body: '${s.city.name} — «إن الصلاة كانت على المؤمنين كتابًا موقوتًا»',
            scheduledDate: tz.TZDateTime.from(at.toUtc(), tz.UTC),
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
