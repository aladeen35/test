import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import '../../core/state.dart';
import 'hp_common.dart';

/// قناة تنبيهات لأدوات «البيت+» — كل أداة لها قناة ونطاق معرّفات خاص بها
/// (الغاز 7300–7349، القطوعات 7400–7599، المخزن 7600–7899، العربية 8000–8099).
/// لا نستدعي cancelAll أبدًا؛ نلغي نطاقنا فقط.
class HpChannel {
  final String id;
  final String Function() name, desc;
  final int base, size;
  const HpChannel(this.id, this.name, this.desc, this.base, this.size);
}

class HpNotify {
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

  static NotificationDetails _details(HpChannel c) => NotificationDetails(
        android: AndroidNotificationDetails(c.id, c.name(), channelDescription: c.desc(), importance: Importance.high, priority: Priority.high),
        iOS: const DarwinNotificationDetails(presentSound: true),
      );

  /// تنبيه واحد مجدول
  static Future<void> _one(HpChannel c, int id, String title, String? body, DateTime wall, DateTimeComponents? match) async {
    final at = placeTZ(wall);
    if (match == null && !at.isAfter(tz.TZDateTime.now(tz.UTC))) return;
    await _plugin.zonedSchedule(
      id: id,
      title: title,
      body: body,
      scheduledDate: at,
      notificationDetails: _details(c),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      matchDateTimeComponents: match,
    );
  }

  /// يلغي تنبيهات القناة السابقة ثم يجدول القائمة الجديدة.
  /// [items]: (فهرس داخل النطاق، عنوان، نص، ساعة حائط المكان، تكرار)
  static Future<int> replace(AppState s, HpChannel c, List<(int, String, String?, DateTime, DateTimeComponents?)> items) async {
    if (!supported) return 0;
    await init();
    if (!_ready) return 0;
    var count = 0;
    try {
      final key = 'hp_notif_${c.id}';
      final prev = List<num>.from(s.getData<List>(key) ?? List.generate(c.size, (i) => i));
      for (final i in prev) {
        if (i >= 0 && i < c.size) await _plugin.cancel(id: c.base + i.toInt());
      }
      final used = <int>[];
      for (final it in items) {
        if (it.$1 < 0 || it.$1 >= c.size - 1) continue; // خارج النطاق (آخر معرّف للتجربة): يُتجاهل
        try {
          await _one(c, c.base + it.$1, it.$2, it.$3, it.$4, it.$5);
          used.add(it.$1);
          count++;
        } catch (e) {
          debugPrint('${c.id} notification: $e');
        }
      }
      s.setData(key, used);
    } catch (e) {
      debugPrint('${c.id} notifications: $e');
    }
    return count;
  }

  /// تنبيه تجريبي فوري (آخر معرّف في النطاق)
  static Future<void> test(HpChannel c, String title, String body) async {
    if (!supported) return;
    await init();
    if (!_ready) return;
    try {
      await _plugin.show(id: c.base + c.size - 1, title: title, body: body, notificationDetails: _details(c));
    } catch (_) {}
  }
}
