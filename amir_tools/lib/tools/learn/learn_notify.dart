import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import '../../core/i18n.dart';

/// تنبيهات أدوات الحفظ وقيام الليل
/// - الحفظ: قناة 'hifz' والمعرّفات 8100–8109
/// - الثلث الأخير: قناة 'qiyam' والمعرّفات 8110–8119
class LearnNotifications {
  static final _plugin = FlutterLocalNotificationsPlugin();
  static bool _ready = false;
  static const hifzBase = 8100, qiyamBase = 8110, span = 10;

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

  static NotificationDetails _details(String channel, String name, String desc) => NotificationDetails(
        android: AndroidNotificationDetails(channel, name, channelDescription: desc, importance: Importance.high, priority: Priority.high),
        iOS: const DarwinNotificationDetails(presentSound: true),
      );

  static tz.TZDateTime _tzAt(DateTime instant) => tz.TZDateTime.from(instant.toUtc(), tz.UTC);

  static Future<void> _cancelRange(int base) async {
    for (var i = base; i < base + span; i++) {
      await _plugin.cancel(id: i);
    }
  }

  /// تذكير يومي بالحفظ في الدقيقة [minutes] من منتصف الليل (بتوقيت الجهاز)؛ null يلغي
  static Future<bool> scheduleHifz(int? minutes, String body) async {
    if (!supported) return false;
    await init();
    if (!_ready) return false;
    try {
      await _cancelRange(hifzBase);
      if (minutes == null) return true;
      final now = DateTime.now();
      var at = DateTime(now.year, now.month, now.day, minutes ~/ 60, minutes % 60);
      if (!at.isAfter(now)) at = DateTime(now.year, now.month, now.day + 1, minutes ~/ 60, minutes % 60);
      await _plugin.zonedSchedule(
        id: hifzBase,
        title: '📖 ${t('وردك من الحفظ', 'ورد الحفظ اليومي', 'Your daily hifz portion')}',
        body: body,
        scheduledDate: _tzAt(at),
        notificationDetails: _details('hifz', tr('حفظ القرآن', 'Quran memorization'), tr('تذكير يومي بورد الحفظ والمراجعة', 'Daily memorization & review reminder')),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.time,
      );
      return true;
    } catch (e) {
      debugPrint('hifz notifications: $e');
      return false;
    }
  }

  /// تنبيهات بداية الثلث الأخير لعدة ليالٍ قادمة (لحظات مطلقة)؛ قائمة فارغة تلغي
  static Future<int> scheduleQiyam(List<DateTime> instants) async {
    if (!supported) return 0;
    await init();
    if (!_ready) return 0;
    var n = 0;
    try {
      await _cancelRange(qiyamBase);
      final now = DateTime.now();
      for (final at in instants) {
        if (n >= span || !at.isAfter(now)) continue;
        await _plugin.zonedSchedule(
          id: qiyamBase + n++,
          title: '🌙 ${t('دخل الثلث الأخير من الليل', 'دخل الثلث الأخير من الليل', 'The last third of the night has begun')}',
          body: 'ينزل ربنا تبارك وتعالى كل ليلة إلى السماء الدنيا… «من يدعوني فأستجيب له»',
          scheduledDate: _tzAt(at),
          notificationDetails: _details('qiyam', tr('قيام الليل', 'Night prayer'), tr('تنبيه عند بداية الثلث الأخير من الليل', 'Alert at the start of the last third of the night')),
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        );
      }
    } catch (e) {
      debugPrint('qiyam notifications: $e');
    }
    return n;
  }
}
