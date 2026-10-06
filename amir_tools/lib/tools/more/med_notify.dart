import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import '../../core/i18n.dart';
import '../../core/state.dart';
import 'more_common.dart';

/// تنبيهات مواعيد الدواء — قناة منفصلة 'medicine' ومعرّفات تبدأ من 5000
class MedNotifications {
  static final _plugin = FlutterLocalNotificationsPlugin();
  static bool _ready = false;
  static const baseId = 5000;
  static const maxIds = 300;

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
        android: AndroidNotificationDetails('medicine', tr('مواعيد الدواء', 'Medicine reminders'),
            channelDescription: tr('تذكير بمواعيد جرعات الدواء', 'Reminders for medicine doses'), importance: Importance.high, priority: Priority.high),
        iOS: const DarwinNotificationDetails(presentSound: true),
      );

  /// أقرب موعد قادم لوقت يومي (دقائق من منتصف الليل) بتوقيت الجهاز، لا يسبق [notBefore]
  static DateTime nextOccurrence(int minutes, {DateTime? notBefore}) {
    final now = DateTime.now();
    var base = notBefore != null && notBefore.isAfter(now) ? notBefore : now;
    var at = DateTime(base.year, base.month, base.day, minutes ~/ 60, minutes % 60);
    if (!at.isAfter(base)) at = at.add(const Duration(days: 1));
    // تصحيح ساعة الحائط إذا تغيّر التوقيت الصيفي
    at = DateTime(at.year, at.month, at.day, minutes ~/ 60, minutes % 60);
    return at;
  }

  static tz.TZDateTime _tzAt(DateTime local) => tz.TZDateTime.from(local.toUtc(), tz.UTC);

  /// يلغي تنبيهات الدواء القديمة ويجدولها من جديد حسب القائمة المحفوظة
  static Future<int> reschedule(AppState s) async {
    if (!supported) return 0;
    await init();
    if (!_ready) return 0;
    var count = 0;
    try {
      final prev = (s.getData<num>('medicine_notif_n') ?? maxIds).toInt();
      for (var i = 0; i < prev && i < maxIds; i++) {
        await _plugin.cancel(id: baseId + i);
      }
      final meds = List<Map>.from(s.getData<List>('medicine_list') ?? []);
      final today = mDateOnly(DateTime.now());
      for (final m in meds) {
        if (m['notify'] == false) continue;
        final start = mParseKey(m['start']) ?? today;
        final end = mParseKey(m['end']);
        if (end != null && end.isBefore(today)) continue;
        final times = List<num>.from(m['times'] ?? []).map((e) => e.toInt()).toList();
        final title = '💊 ${tr('موعد الدواء', 'Medicine time')}: ${m['name']}';
        final body = [if ((m['dose'] ?? '').toString().isNotEmpty) m['dose'], if ((m['notes'] ?? '').toString().isNotEmpty) m['notes']].join(' — ');
        // كورس قصير بتاريخ نهاية: تنبيهات منفردة لكل يوم حتى تتوقف وحدها
        final shortCourse = end != null && mDaysBetween(today, end) < 14;
        for (final mins in times) {
          if (count >= maxIds) break;
          if (shortCourse) {
            for (var d = start.isAfter(today) ? start : today; !d.isAfter(end); d = DateTime(d.year, d.month, d.day + 1)) {
              final at = DateTime(d.year, d.month, d.day, mins ~/ 60, mins % 60);
              if (!at.isAfter(DateTime.now())) continue;
              if (count >= maxIds) break;
              await _plugin.zonedSchedule(
                id: baseId + count++,
                title: title,
                body: body.isEmpty ? null : body,
                scheduledDate: _tzAt(at),
                notificationDetails: _details,
                androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
              );
            }
          } else {
            final at = nextOccurrence(mins, notBefore: start.isAfter(today) ? start : null);
            await _plugin.zonedSchedule(
              id: baseId + count++,
              title: title,
              body: body.isEmpty ? null : body,
              scheduledDate: _tzAt(at),
              notificationDetails: _details,
              androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
              matchDateTimeComponents: DateTimeComponents.time,
            );
          }
        }
      }
      s.setData('medicine_notif_n', count);
    } catch (e) {
      debugPrint('medicine notifications: $e');
    }
    return count;
  }

  /// تنبيه تجريبي فوري
  static Future<void> test() async {
    if (!supported) return;
    await init();
    if (!_ready) return;
    try {
      await _plugin.show(
        id: baseId + maxIds,
        title: '💊 ${tr('تجربة تنبيه الدواء', 'Medicine reminder test')}',
        body: t('كدا حيجيك التنبيه في موعد الدواء ✓', 'هكذا سيصلك التنبيه في موعد الدواء ✓', "This is how your dose reminder will look ✓"),
        notificationDetails: _details,
      );
    } catch (_) {}
  }
}
