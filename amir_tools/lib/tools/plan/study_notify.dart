import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import '../../core/i18n.dart';
import '../../core/state.dart';
import 'plan_common.dart';

/// تنبيهات جلسات المذاكرة — قناة منفصلة 'study' ومعرّفات 8200–8299
class StudyNotifications {
  static final _plugin = FlutterLocalNotificationsPlugin();
  static bool _ready = false;
  static const baseId = 8200;
  static const maxIds = 99; // 8200–8298 للجدولة، و8299 للتجربة

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
        android: AndroidNotificationDetails('study', tr('جدول المذاكرة', 'Study planner'),
            channelDescription: tr('تذكير بجلسات المذاكرة', 'Reminders for study sessions'), importance: Importance.high, priority: Priority.high),
        iOS: const DarwinNotificationDetails(presentSound: true),
      );

  static tz.TZDateTime _tzAt(DateTime local) => tz.TZDateTime.from(local.toUtc(), tz.UTC);

  /// أقرب موعد قادم ليوم أسبوع ووقت (دقائق من منتصف الليل)
  static DateTime nextWeekly(int weekday, int minutes, [DateTime? from]) {
    final now = from ?? DateTime.now();
    for (var i = 0; i < 8; i++) {
      final d = DateTime(now.year, now.month, now.day + i, minutes ~/ 60, minutes % 60);
      if (d.weekday == weekday && d.isAfter(now)) return d;
    }
    return DateTime(now.year, now.month, now.day + 7, minutes ~/ 60, minutes % 60);
  }

  static Future<void> _cancelOld(AppState s) async {
    final prev = (s.getData<num>('study_plan_notif_n') ?? maxIds).toInt();
    for (var i = 0; i < prev && i < maxIds; i++) {
      await _plugin.cancel(id: baseId + i);
    }
  }

  /// يلغي تنبيهات المذاكرة السابقة (ضمن نطاقها فقط) ويجدولها من جديد
  static Future<int> reschedule(AppState s) async {
    if (!supported) return 0;
    await init();
    if (!_ready) return 0;
    var count = 0;
    try {
      await _cancelOld(s);
      final data = Map<String, dynamic>.from(s.getData<Map>('study_plan') ?? const {});
      if (data['notify'] != true) {
        s.setData('study_plan_notif_n', 0);
        return 0;
      }
      final subs = {for (final x in mapList(data['subjects'])) x['id']: '${x['n']}'};
      String title(String? sub) => '📚 ${tr('وقت المذاكرة', 'Study time')}: ${subs[sub] ?? ''}';
      // الحصص الأسبوعية المتكررة
      for (final w in mapList(data['weekly'])) {
        if (count >= maxIds) break;
        if (!subs.containsKey(w['sub'])) continue;
        final at = nextWeekly(intOf(w['wd'], 1), intOf(w['m']));
        await _plugin.zonedSchedule(
          id: baseId + count++,
          title: title(w['sub'] as String?),
          body: '${intOf(w['dur'], 60)} ${tr('دقيقة', 'min')}',
          scheduledDate: _tzAt(at),
          notificationDetails: _details,
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
          matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
        );
      }
      // جلسات خطة المراجعة في الأسبوعين القادمين
      final now = DateTime.now();
      final limit = now.add(const Duration(days: 14));
      final sessions = mapList(data['sessions'])
        ..sort((a, b) => ('${a['d']}${intOf(a['m']).toString().padLeft(4, '0')}').compareTo('${b['d']}${intOf(b['m']).toString().padLeft(4, '0')}'));
      for (final x in sessions) {
        if (count >= maxIds) break;
        if (x['done'] == true || !subs.containsKey(x['sub'])) continue;
        final d = parseDk(x['d']);
        if (d == null) continue;
        final at = DateTime(d.year, d.month, d.day, intOf(x['m']) ~/ 60, intOf(x['m']) % 60);
        if (!at.isAfter(now) || at.isAfter(limit)) continue;
        await _plugin.zonedSchedule(
          id: baseId + count++,
          title: title(x['sub'] as String?),
          body: '${tr('مراجعة', 'Revision')} · ${intOf(x['dur'], 60)} ${tr('دقيقة', 'min')}',
          scheduledDate: _tzAt(at),
          notificationDetails: _details,
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        );
      }
      s.setData('study_plan_notif_n', count);
    } catch (e) {
      debugPrint('study notifications: $e');
    }
    return count;
  }

  /// يلغي كل تنبيهات المذاكرة (ضمن نطاقها فقط)
  static Future<void> cancel(AppState s) async {
    if (!supported) return;
    await init();
    if (!_ready) return;
    try {
      await _cancelOld(s);
      s.setData('study_plan_notif_n', 0);
    } catch (_) {}
  }

  static Future<void> test() async {
    if (!supported) return;
    await init();
    if (!_ready) return;
    try {
      await _plugin.show(
        id: baseId + 99,
        title: '📚 ${tr('تجربة تنبيه المذاكرة', 'Study reminder test')}',
        body: t('كدا حيجيك التنبيه في وقت المذاكرة ✓', 'هكذا سيصلك التنبيه في وقت المذاكرة ✓', 'This is how your study reminder will look ✓'),
        notificationDetails: _details,
      );
    } catch (_) {}
  }
}
