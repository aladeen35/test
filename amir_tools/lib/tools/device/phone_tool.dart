import 'dart:async';
import 'package:battery_plus/battery_plus.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../../core/i18n.dart';
import '../../core/format.dart';
import '../../core/theme.dart';
import '../../core/widgets.dart';

/// هاتفي: البطارية، الجهاز، الذاكرة، الشبكة، والشاشة
class PhoneTool extends StatefulWidget {
  const PhoneTool({super.key});
  @override
  State<PhoneTool> createState() => _PhoneToolState();
}

class _PhoneToolState extends State<PhoneTool> {
  final _battery = Battery();
  int? _level;
  BatteryState? _state;
  bool? _saver;
  List<ConnectivityResult> _net = [];
  final _info = <(String, String)>[];
  StreamSubscription<BatteryState>? _bSub;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      _level = await _battery.batteryLevel;
      _state = await _battery.batteryState;
      _saver = await _battery.isInBatterySaveMode;
      _bSub ??= _battery.onBatteryStateChanged.listen((s) async {
        _state = s;
        _level = await _battery.batteryLevel;
        if (mounted) setState(() {});
      });
    } catch (_) {}
    try {
      _net = await Connectivity().checkConnectivity();
    } catch (_) {}
    _info.clear();
    try {
      final d = DeviceInfoPlugin();
      if (kIsWeb) {
        final w = await d.webBrowserInfo;
        _info.addAll([(tr('المتصفح', 'Browser'), w.browserName.name), (tr('النظام', 'Platform'), w.platform ?? '—')]);
      } else if (defaultTargetPlatform == TargetPlatform.android) {
        final a = await d.androidInfo;
        _info.addAll([
          (tr('الشركة', 'Manufacturer'), a.manufacturer),
          (tr('الموديل', 'Model'), '${a.brand} ${a.model}'),
          (tr('أندرويد', 'Android'), '${a.version.release} (SDK ${a.version.sdkInt})'),
          (tr('المعالج', 'Hardware'), a.hardware),
          (tr('جهاز حقيقي؟', 'Physical device?'), a.isPhysicalDevice ? t('أيوا', 'نعم', 'Yes') : tr('محاكي', 'Emulator')),
          (tr('الرام', 'RAM'), '${fmt(a.physicalRamSize / 1024, 1)} GB (${t('فاضي', 'متاح', 'free')} ${fmt(a.availableRamSize / 1024, 1)} GB)'),
          (tr('التخزين', 'Storage'), '${fmtBytes(a.totalDiskSize)} (${t('فاضي', 'متاح', 'free')} ${fmtBytes(a.freeDiskSize)})'),
        ]);
      } else if (defaultTargetPlatform == TargetPlatform.iOS) {
        final i = await d.iosInfo;
        _info.addAll([(tr('الجهاز', 'Device'), i.modelName), (tr('الاسم', 'Name'), i.name), ('iOS', i.systemVersion)]);
      }
    } catch (_) {}
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _bSub?.cancel();
    super.dispose();
  }

  String get _stateText => switch (_state) {
        BatteryState.charging => t('بيشحن ⚡', 'يشحن ⚡', 'Charging ⚡'),
        BatteryState.full => t('مليان ✓', 'ممتلئة ✓', 'Full ✓'),
        BatteryState.discharging => t('شغّال على البطارية', 'يعمل على البطارية', 'On battery'),
        BatteryState.connectedNotCharging => t('موصّل وما بيشحن', 'موصول ولا يشحن', 'Plugged in, not charging'),
        _ => '—',
      };

  String get _netText {
    if (_net.isEmpty || _net.contains(ConnectivityResult.none)) return t('ما في نت 📵', 'لا يوجد اتصال 📵', 'No connection 📵');
    return _net.map((n) => switch (n) {
          ConnectivityResult.wifi => tr('واي فاي', 'Wi‑Fi'),
          ConnectivityResult.mobile => t('بيانات الموبايل', 'بيانات الجوال', 'Mobile data'),
          ConnectivityResult.ethernet => t('سلك', 'سلكي', 'Ethernet'),
          ConnectivityResult.vpn => 'VPN',
          ConnectivityResult.bluetooth => tr('بلوتوث', 'Bluetooth'),
          _ => tr('أخرى', 'Other'),
        }).join(' + ');
  }

  List<String> get _tips {
    final l = _level ?? 100;
    return [
      if (l <= 20)
        t('🔋 البطارية قربت تخلص — شغّل وضع توفير الطاقة وطفّي البلوتوث والـ GPS.', '🔋 البطارية على وشك النفاد — شغّل وضع توفير الطاقة وأطفئ البلوتوث والـ GPS.',
            '🔋 Battery almost empty — turn on battery saver and switch off Bluetooth and GPS.'),
      if (_state == BatteryState.charging && l >= 90)
        t('🔌 أحسن تفصل الشاحن قريب من 90% عشان تطوّل عمر البطارية.', '🔌 يُفضّل فصل الشاحن قرب 90% لإطالة عمر البطارية.', '🔌 Unplug around 90% to extend battery lifespan.'),
      t('الشحن بين 20% و80% بيحافظ على البطارية أطول.', 'الشحن بين 20% و80% يحافظ على البطارية مدة أطول.', 'Keeping charge between 20% and 80% preserves the battery longer.'),
      t('في الحر ما تشحن التلفون في الشمس أو جوه العربية — الحرارة أكبر عدو للبطارية.', 'في الحر لا تشحن الهاتف في الشمس أو داخل السيارة — الحرارة أكبر عدو للبطارية.',
          "In hot weather, don't charge in the sun or inside a car — heat is the battery's worst enemy."),
      t('لو الكهرباء قاطعة كتير: باور بانك 10000 mAh بيشحن معظم التلفونات مرتين تقريبًا.', 'إن كثر انقطاع الكهرباء: باور بانك 10000 mAh يشحن معظم الهواتف مرتين تقريباً.',
          'Frequent power cuts? A 10,000 mAh power bank charges most phones about twice.'),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    final l = _level;
    return RefreshIndicator(
      onRefresh: _load,
      child: ToolList(children: [
        ResultHero(
          label: '${tr('البطارية', 'Battery')} • $_stateText',
          value: l == null ? '—' : '$l%',
          sub: _saver == true ? t('وضع توفير الطاقة شغّال', 'وضع توفير الطاقة مفعّل', 'Battery saver is on') : null,
          colors: l == null ? null : l <= 20 ? const [SD.red, SD.brownDeep] : l <= 50 ? const [SD.gold, SD.henna] : const [SD.green, Color(0xFF004D1C)],
        ),
        SCard(
          title: tr('جهازك', 'Your device'),
          icon: Icons.smartphone_rounded,
          color: SD.nile,
          child: Column(children: [
            if (_info.isEmpty) Text(t('بنجيب المعلومات…', 'جارٍ جلب المعلومات…', 'Loading info…')),
            for (final (k, v) in _info) InfoRow(k, v),
          ]),
        ),
        SCard(
          title: tr('الشاشة والشبكة', 'Screen & network'),
          icon: Icons.wifi_rounded,
          color: SD.teal,
          child: Column(children: [
            InfoRow(tr('الاتصال', 'Connection'), _netText),
            InfoRow(tr('مقاس الشاشة', 'Screen size'), '${fmt(mq.size.width * mq.devicePixelRatio, 0)} × ${fmt(mq.size.height * mq.devicePixelRatio, 0)} ${tr('بكسل', 'px')}'),
            InfoRow(tr('كثافة البكسل', 'Pixel ratio'), '${fmt(mq.devicePixelRatio, 2)}x'),
            InfoRow(tr('حجم الخط في النظام', 'System font scale'), '${fmt(mq.textScaler.scale(100), 0)}%'),
            InfoRow(tr('الوضع', 'Theme'), mq.platformBrightness == Brightness.dark ? tr('داكن', 'Dark') : tr('فاتح', 'Light')),
          ]),
        ),
        SCard(
          title: t('نصايح للبطارية', 'نصائح للبطارية', 'Battery tips'),
          icon: Icons.tips_and_updates_rounded,
          color: SD.gold,
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            for (final tip in _tips) Padding(padding: const EdgeInsetsDirectional.only(bottom: 6), child: Text('• $tip', style: const TextStyle(height: 1.5))),
          ]),
        ),
        ShareBar(() => [for (final (k, v) in _info) '$k: $v', '${tr('البطارية', 'Battery')}: ${l ?? '—'}%', '${tr('الاتصال', 'Connection')}: $_netText'].join('\n')),
      ]),
    );
  }
}
