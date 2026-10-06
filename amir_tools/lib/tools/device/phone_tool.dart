import 'dart:async';
import 'package:battery_plus/battery_plus.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
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
        _info.addAll([('المتصفح', w.browserName.name), ('النظام', w.platform ?? '—')]);
      } else if (defaultTargetPlatform == TargetPlatform.android) {
        final a = await d.androidInfo;
        _info.addAll([
          ('الشركة', a.manufacturer),
          ('الموديل', '${a.brand} ${a.model}'),
          ('أندرويد', '${a.version.release} (SDK ${a.version.sdkInt})'),
          ('المعالج', a.hardware),
          ('جهاز حقيقي؟', a.isPhysicalDevice ? 'أيوا' : 'محاكي'),
          ('الرام', '${fmt(a.physicalRamSize / 1024, 1)} GB (فاضي ${fmt(a.availableRamSize / 1024, 1)} GB)'),
          ('التخزين', '${fmtBytes(a.totalDiskSize)} (فاضي ${fmtBytes(a.freeDiskSize)})'),
        ]);
      } else if (defaultTargetPlatform == TargetPlatform.iOS) {
        final i = await d.iosInfo;
        _info.addAll([('الجهاز', i.modelName), ('الاسم', i.name), ('iOS', i.systemVersion)]);
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
        BatteryState.charging => 'بيشحن ⚡',
        BatteryState.full => 'مليان ✓',
        BatteryState.discharging => 'شغّال على البطارية',
        BatteryState.connectedNotCharging => 'موصّل وما بيشحن',
        _ => '—',
      };

  String get _netText {
    if (_net.isEmpty || _net.contains(ConnectivityResult.none)) return 'ما في نت 📵';
    return _net.map((n) => switch (n) {
          ConnectivityResult.wifi => 'واي فاي',
          ConnectivityResult.mobile => 'بيانات الموبايل',
          ConnectivityResult.ethernet => 'سلك',
          ConnectivityResult.vpn => 'VPN',
          ConnectivityResult.bluetooth => 'بلوتوث',
          _ => 'أخرى',
        }).join(' + ');
  }

  List<String> get _tips {
    final l = _level ?? 100;
    return [
      if (l <= 20) '🔋 البطارية قربت تخلص — شغّل وضع توفير الطاقة وطفّي البلوتوث والـ GPS.',
      if (_state == BatteryState.charging && l >= 90) '🔌 أحسن تفصل الشاحن قريب من 90% عشان تطوّل عمر البطارية.',
      'الشحن بين 20% و80% بيحافظ على البطارية أطول.',
      'في حرّ السودان ما تشحن التلفون في الشمس أو جوه العربية — الحرارة أكبر عدو للبطارية.',
      'لو الكهرباء قاطعة كتير: باور بانك 10000 mAh بيشحن معظم التلفونات مرتين تقريبًا.',
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
          label: 'البطارية • $_stateText',
          value: l == null ? '—' : '$l%',
          sub: _saver == true ? 'وضع توفير الطاقة شغّال' : null,
          colors: l == null ? null : l <= 20 ? const [SD.red, SD.brownDeep] : l <= 50 ? const [SD.gold, SD.henna] : const [SD.green, Color(0xFF004D1C)],
        ),
        SCard(
          title: 'جهازك',
          icon: Icons.smartphone_rounded,
          color: SD.nile,
          child: Column(children: [
            if (_info.isEmpty) const Text('بنجيب المعلومات…'),
            for (final (k, v) in _info) InfoRow(k, v),
          ]),
        ),
        SCard(
          title: 'الشاشة والشبكة',
          icon: Icons.wifi_rounded,
          color: SD.teal,
          child: Column(children: [
            InfoRow('الاتصال', _netText),
            InfoRow('مقاس الشاشة', '${fmt(mq.size.width * mq.devicePixelRatio, 0)} × ${fmt(mq.size.height * mq.devicePixelRatio, 0)} بكسل'),
            InfoRow('كثافة البكسل', '${fmt(mq.devicePixelRatio, 2)}x'),
            InfoRow('حجم الخط في النظام', '${fmt(mq.textScaler.scale(100), 0)}%'),
            InfoRow('الوضع', mq.platformBrightness == Brightness.dark ? 'داكن' : 'فاتح'),
          ]),
        ),
        SCard(
          title: 'نصايح للبطارية',
          icon: Icons.tips_and_updates_rounded,
          color: SD.gold,
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            for (final t in _tips) Padding(padding: const EdgeInsets.only(bottom: 6), child: Text('• $t', style: const TextStyle(height: 1.5))),
          ]),
        ),
        ShareBar(() => [for (final (k, v) in _info) '$k: $v', 'البطارية: ${l ?? '—'}%', 'الاتصال: $_netText'].join('\n')),
      ]),
    );
  }
}
