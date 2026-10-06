import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import '../../core/i18n.dart';
import '../../core/state.dart';
import 'deen_common.dart';
import 'fast_calendar.dart';

/// تذكير صيام التطوع مساء اليوم السابق — قناة منفصلة 'fasting' ومعرّفات 7000–7299
class FastNotifications {
  static final _plugin = FlutterLocalNotificationsPlugin();
  static bool _ready = false;
  static const baseId = 7000;
  static const maxIds = 299; // 7000–7298، و7299 للتجربة

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

  static NotificationDetails get _details => NotificationDetails(
        android: AndroidNotificationDetails('fasting', tr('تذكير الصيام', 'Fasting reminders'),
            channelDescription: tr('تذكير بصيام التطوع مساء اليوم السابق', 'Evening-before reminders for voluntary fasts'),
            importance: Importance.high, priority: Priority.high),
        iOS: const DarwinNotificationDetails(presentSound: true),
      );

  static tz.TZDateTime _tzAt(DateTime local) => tz.TZDateTime.from(local.toUtc(), tz.UTC);

  /// الأنواع المفعّلة للتذكير
  static Set<FastType> enabled(AppState s) =>
      {for (final id in List<String>.from(s.getData<List>('fasting_remind') ?? const [])) ?FastType.byId(id)};

  /// وقت التذكير بالدقائق من منتصف الليل (الافتراضي 9 مساءً)
  static int remindMinutes(AppState s) => (s.getData<num>('fasting_remind_at') ?? 21 * 60).toInt();

  /// يلغي تذكيرات الصيام السابقة ويجدول الستين يومًا القادمة
  static Future<int> reschedule(AppState s) async {
    if (!supported) return 0;
    await init();
    if (!_ready) return 0;
    var count = 0;
    try {
      final prev = (s.getData<num>('fasting_notif_n') ?? maxIds).toInt();
      for (var i = 0; i < prev && i < maxIds; i++) {
        await _plugin.cancel(id: baseId + i);
      }
      final types = enabled(s);
      if (types.isNotEmpty) {
        final mins = remindMinutes(s);
        final now = DateTime.now();
        final today = DateTime(now.year, now.month, now.day);
        for (var i = 1; i <= 60 && count < 60; i++) {
          final f = fastDay(addDays(today, i), s.hijriShift);
          if (!f.suggested) continue;
          final hit = f.types.where((t) => types.contains(t) && (t != FastType.shawwal || f.hijri.d == 2)).toList();
          if (hit.isEmpty) continue;
          final eve = addDays(f.date, -1);
          final at = DateTime(eve.year, eve.month, eve.day, mins ~/ 60, mins % 60);
          if (!at.isAfter(now)) continue;
          final what = hit.contains(FastType.shawwal) ? FastType.shawwal.label : f.describe();
          await _plugin.zonedSchedule(
            id: baseId + count++,
            title: '🌙 ${t('بكرة صيام سنّة', 'غدًا صيام سنّة', 'Sunnah fast tomorrow')}: $what',
            body: t('نوّي الصيام واتسحّر — «تسحّروا فإن في السحور بركة»', 'انوِ الصيام وتسحّر — «تسحّروا فإن في السحور بركة»',
                'Make your intention and have suhoor — "Take suhoor, for in suhoor there is blessing"'),
            scheduledDate: _tzAt(at),
            notificationDetails: _details,
            androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
          );
        }
      }
      s.setData('fasting_notif_n', count);
    } catch (e) {
      debugPrint('fasting notifications: $e');
    }
    return count;
  }

  static Future<void> test() async {
    if (!supported) return;
    await init();
    if (!_ready) return;
    try {
      await _plugin.show(
        id: baseId + maxIds,
        title: '🌙 ${tr('تجربة تذكير الصيام', 'Fasting reminder test')}',
        body: t('كدا حيجيك التذكير مساء اليوم القبل الصيام ✓', 'هكذا سيصلك التذكير مساء اليوم السابق للصيام ✓', 'This is how the evening-before reminder will look ✓'),
        notificationDetails: _details,
      );
    } catch (_) {}
  }
}
