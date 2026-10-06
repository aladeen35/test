import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import '../../core/i18n.dart';
import '../../core/state.dart';
import '../life/life_common.dart' show parseDk;

/// تنبيهات تجديد الأوراق الرسمية — قناة منفصلة 'documents' ومعرّفات 6000–6499
class DocNotifications {
  static final _plugin = FlutterLocalNotificationsPlugin();
  static bool _ready = false;
  static const baseId = 6000;
  static const maxIds = 499; // 6000..6498، و6499 للتجربة

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
        android: AndroidNotificationDetails('documents', tr('مواعيد الأوراق الرسمية', 'Document renewals'),
            channelDescription: tr('تذكير قبل انتهاء الجواز والإقامة والرخص', 'Reminders before passports, permits and licenses expire'),
            importance: Importance.high,
            priority: Priority.high),
        iOS: const DarwinNotificationDetails(presentSound: true),
      );

  static tz.TZDateTime _tzAt(DateTime local) => tz.TZDateTime.from(local.toUtc(), tz.UTC);

  /// يلغي تنبيهات الأوراق السابقة ويجدولها من جديد
  /// [title] تُعيد اسم الورقة المعروض لكل عنصر
  static Future<int> reschedule(AppState s, String Function(Map doc) title) async {
    if (!supported) return 0;
    await init();
    if (!_ready) return 0;
    var count = 0;
    try {
      final prev = (s.getData<num>('documents_notif_n') ?? maxIds).toInt();
      for (var i = 0; i < prev && i < maxIds; i++) {
        await _plugin.cancel(id: baseId + i);
      }
      final enabled = (s.getData<Map>('documents_cfg') ?? const {})['notify'] != false;
      if (!enabled) {
        s.setData('documents_notif_n', 0);
        return 0;
      }
      final docs = List<Map>.from(s.getData<List>('documents_list') ?? []);
      final now = DateTime.now();
      for (final d in docs) {
        final exp = parseDk(d['exp'] as String?);
        if (exp == null) continue;
        final before = (d['remind'] as num?)?.toInt() ?? 30;
        final name = title(d);
        final points = <(DateTime, String)>[
          if (before > 0)
            (
              DateTime(exp.year, exp.month, exp.day - before, 10),
              t('باقي $before يوم على انتهاء $name — جهّز التجديد', 'متبقٍ $before يومًا على انتهاء $name — جهّز للتجديد',
                  '$name expires in $before days — time to renew'),
            ),
          if (before > 7)
            (
              DateTime(exp.year, exp.month, exp.day - 7, 10),
              t('أسبوع بس وينتهي $name', 'أسبوع واحد على انتهاء $name', 'One week left before $name expires'),
            ),
          (DateTime(exp.year, exp.month, exp.day, 10), t('$name انتهى الليلة!', 'ينتهي $name اليوم!', '$name expires today!')),
        ];
        for (final (at, body) in points) {
          if (!at.isAfter(now) || count >= maxIds) continue;
          await _plugin.zonedSchedule(
            id: baseId + count++,
            title: '📄 ${tr('تذكير تجديد', 'Renewal reminder')}',
            body: body,
            scheduledDate: _tzAt(at),
            notificationDetails: _details,
            androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
          );
        }
      }
      s.setData('documents_notif_n', count);
    } catch (e) {
      debugPrint('documents notifications: $e');
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
        title: '📄 ${tr('تجربة تنبيه الأوراق', 'Document reminder test')}',
        body: t('كدا حيجيك التذكير قبل ما ورقك ينتهي ✓', 'هكذا سيصلك التذكير قبل انتهاء أوراقك ✓', 'This is how renewal reminders will look ✓'),
        notificationDetails: _details,
      );
    } catch (_) {}
  }
}
