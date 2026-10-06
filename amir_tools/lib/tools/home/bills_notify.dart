import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import '../../core/i18n.dart';
import '../../core/state.dart';
import '../life/life_common.dart' show mapList, numOf, intOf;

/// تواريخ الاستحقاق والفترات للفواتير المتكررة
class BillDue {
  /// مفتاح الفترة: شهري «yyyy-mm»، سنوي «yyyy»
  static String period(Map b, DateTime due) => b['freq'] == 'y' ? '${due.year}' : '${due.year}-${due.month.toString().padLeft(2, '0')}';

  static DateTime _clampDay(int y, int m, int d) {
    final last = DateTime(y, m + 1, 0).day;
    return DateTime(y, m, d.clamp(1, last));
  }

  /// تاريخ الاستحقاق داخل شهر/سنة معيّنة
  static DateTime dueIn(Map b, int year, int month) {
    final day = intOf(b['day'], 1);
    if (b['freq'] == 'y') return _clampDay(year, intOf(b['month'], 1), day);
    return _clampDay(year, month, day);
  }

  static bool isPaid(Map b, String period, List<Map<String, dynamic>> payments) =>
      payments.any((p) => p['bill'] == b['id'] && p['period'] == period);

  /// استحقاقات قادمة (غير مدفوعة) ابتداءً من أقدم فترة غير مدفوعة في هذا الشهر/السنة
  static List<DateTime> upcoming(Map b, DateTime today, List<Map<String, dynamic>> payments, {int count = 3}) {
    final out = <DateTime>[];
    if (b['freq'] == 'y') {
      for (var y = today.year; out.length < count && y < today.year + count + 1; y++) {
        final d = dueIn(b, y, 1);
        if (!isPaid(b, period(b, d), payments)) out.add(d);
      }
    } else {
      for (var i = 0; out.length < count && i < count + 12; i++) {
        final d = dueIn(b, today.year, today.month + i);
        final dd = DateTime(d.year, d.month, d.day);
        if (!isPaid(b, period(b, dd), payments)) out.add(dd);
      }
    }
    return out;
  }
}

/// تنبيهات الفواتير — قناة 'bills' ومعرّفات 6500–6999
class BillNotifications {
  static final _plugin = FlutterLocalNotificationsPlugin();
  static bool _ready = false;
  static const baseId = 6500;
  static const maxIds = 490; // 6500..6989 ، و6999 للتجربة
  static const testId = 6999;

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
        android: AndroidNotificationDetails('bills', tr('الفواتير الشهرية', 'Monthly bills'),
            channelDescription: tr('تذكير بمواعيد سداد الفواتير', 'Reminders before bills are due'),
            importance: Importance.high, priority: Priority.high),
        iOS: const DarwinNotificationDetails(presentSound: true),
      );

  static tz.TZDateTime _tzAt(DateTime local) => tz.TZDateTime.from(local.toUtc(), tz.UTC);

  /// يلغي تنبيهات الفواتير السابقة (ضمن نطاقنا فقط) ويجدولها من جديد
  static Future<int> reschedule(AppState s) async {
    if (!supported) return 0;
    await init();
    if (!_ready) return 0;
    var count = 0;
    try {
      final prev = (s.getData<num>('bills_notif_n') ?? maxIds).toInt();
      for (var i = 0; i < prev && i < maxIds; i++) {
        await _plugin.cancel(id: baseId + i);
      }
      final bills = mapList(s.getData<List>('bills_list'));
      final pays = mapList(s.getData<List>('bills_paid'));
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      for (final b in bills) {
        if (b['notify'] == false) continue;
        final before = intOf(b['remind'], 3);
        for (final due in BillDue.upcoming(b, today, pays, count: 3)) {
          if (count >= maxIds) break;
          final amount = numOf(b['a']);
          final body = '${amount > 0 ? '${amount.toStringAsFixed(amount % 1 == 0 ? 0 : 2)} ${b['cur'] ?? ''} · ' : ''}'
              '${tr('الاستحقاق', 'Due')}: ${due.day}/${due.month}/${due.year}';
          // تذكير قبل N يوم، وتذكير يوم الاستحقاق نفسه
          for (final at in {
            DateTime(due.year, due.month, due.day - before, 9),
            DateTime(due.year, due.month, due.day, 9),
          }) {
            if (!at.isAfter(now) || count >= maxIds) continue;
            final isDay = at.day == due.day && at.month == due.month;
            await _plugin.zonedSchedule(
              id: baseId + count++,
              title: isDay
                  ? '🧾 ${t('الفاتورة دي مستحقة الليلة', 'فاتورة مستحقة اليوم', 'Bill due today')}: ${b['name']}'
                  : '🧾 ${t('فاتورة قرّبت', 'فاتورة قريبة', 'Bill coming up')}: ${b['name']}',
              body: body,
              scheduledDate: _tzAt(at),
              notificationDetails: _details,
              androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
            );
          }
        }
      }
      s.setData('bills_notif_n', count);
    } catch (e) {
      debugPrint('bills notifications: $e');
    }
    return count;
  }

  static Future<void> test() async {
    if (!supported) return;
    await init();
    if (!_ready) return;
    try {
      await _plugin.show(
        id: testId,
        title: '🧾 ${tr('تجربة تنبيه الفواتير', 'Bill reminder test')}',
        body: t('كدا حيجيك التنبيه قبل موعد الفاتورة ✓', 'هكذا سيصلك التنبيه قبل موعد الفاتورة ✓', 'This is how your bill reminder will look ✓'),
        notificationDetails: _details,
      );
    } catch (_) {}
  }
}
