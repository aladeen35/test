import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import '../../core/i18n.dart';
import '../../core/state.dart';

/// موعد تنبيه واحد
class CareAlarm {
  final String title;
  final String? body;
  final DateTime at;

  /// يتكرر يوميًا في نفس الساعة (مثل الدواء)
  final bool daily;
  const CareAlarm(this.title, this.at, {this.body, this.daily = false});
}

/// تنبيهات قسم الرعاية — كل أداة بقناتها ومدى معرّفاتها الخاص (لا يُستدعى cancelAll أبدًا)
class CareNotifier {
  final String channel, nameAr, nameEn, descAr, descEn, countKey;
  final int baseId, maxIds;
  const CareNotifier({
    required this.channel,
    required this.nameAr,
    required this.nameEn,
    required this.descAr,
    required this.descEn,
    required this.countKey,
    required this.baseId,
    required this.maxIds,
  });

  /// الفحوصات واللقاحات: القناة 'checkups' والمعرّفات 8300–8399
  static const checkups = CareNotifier(
    channel: 'checkups',
    nameAr: 'اللقاحات والفحوصات',
    nameEn: 'Vaccines & check-ups',
    descAr: 'تذكير بمواعيد اللقاحات والفحوصات الدورية',
    descEn: 'Reminders for vaccines and routine check-ups',
    countKey: 'vaccines_notif_n',
    baseId: 8300,
    maxIds: 100,
  );

  /// رعاية كبار السن: القناة 'elder' والمعرّفات 8400–8499
  static const elder = CareNotifier(
    channel: 'elder',
    nameAr: 'رعاية كبار السن',
    nameEn: 'Elder care',
    descAr: 'مواعيد دواء ومراجعات كبار السن',
    descEn: 'Medicines and appointments for elders',
    countKey: 'elder_care_notif_n',
    baseId: 8400,
    maxIds: 100,
  );

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

  NotificationDetails get _details => NotificationDetails(
        android: AndroidNotificationDetails(channel, tr(nameAr, nameEn), channelDescription: tr(descAr, descEn), importance: Importance.high, priority: Priority.high),
        iOS: const DarwinNotificationDetails(presentSound: true),
      );

  static tz.TZDateTime _tzAt(DateTime local) => tz.TZDateTime.from(local.toUtc(), tz.UTC);

  /// يلغي تنبيهات هذه الأداة فقط ثم يجدول القائمة الجديدة (الأقرب أولًا حتى الحد الأقصى)
  Future<int> schedule(AppState s, List<CareAlarm> alarms) async {
    if (!supported) return 0;
    await init();
    if (!_ready) return 0;
    var count = 0;
    try {
      final prev = (s.getData<num>(countKey) ?? maxIds).toInt();
      for (var i = 0; i < prev && i < maxIds; i++) {
        await _plugin.cancel(id: baseId + i);
      }
      final now = DateTime.now();
      final list = alarms.where((a) => a.daily || a.at.isAfter(now)).toList()..sort((a, b) => a.at.compareTo(b.at));
      for (final a in list) {
        if (count >= maxIds) break;
        var at = a.at;
        if (a.daily) {
          at = DateTime(now.year, now.month, now.day, at.hour, at.minute);
          if (!at.isAfter(now)) at = DateTime(now.year, now.month, now.day + 1, a.at.hour, a.at.minute);
        }
        await _plugin.zonedSchedule(
          id: baseId + count++,
          title: a.title,
          body: a.body,
          scheduledDate: _tzAt(at),
          notificationDetails: _details,
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
          matchDateTimeComponents: a.daily ? DateTimeComponents.time : null,
        );
      }
      s.setData(countKey, count);
    } catch (e) {
      debugPrint('care notifications ($channel): $e');
    }
    return count;
  }
}
