import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:torch_light/torch_light.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import '../../core/i18n.dart';
import '../../core/theme.dart';
import '../../core/widgets.dart';

/// الكشاف: فلاش الكاميرا، إشارة SOS، وميض، وشاشة بيضاء — لقطوعات الكهرباء
class FlashlightTool extends StatefulWidget {
  const FlashlightTool({super.key});
  @override
  State<FlashlightTool> createState() => _FlashlightToolState();
}

class _FlashlightToolState extends State<FlashlightTool> {
  bool _on = false, _available = true;
  String _mode = 'normal';
  double _speed = 5;
  Timer? _timer;
  int _step = 0;
  DateTime? _since;

  // SOS: ... --- ... (1 = مضيء، 0 = مطفي) بوحدات 200 مللي ثانية
  static const _sos = [1, 0, 1, 0, 1, 0, 0, 0, 1, 1, 1, 0, 1, 1, 1, 0, 1, 1, 1, 0, 0, 0, 1, 0, 1, 0, 1, 0, 0, 0, 0, 0, 0];

  @override
  void initState() {
    super.initState();
    _check();
  }

  Future<void> _check() async {
    if (kIsWeb) return setState(() => _available = false);
    try {
      final a = await TorchLight.isTorchAvailable();
      if (mounted) setState(() => _available = a);
    } catch (_) {
      if (mounted) setState(() => _available = false);
    }
  }

  Future<void> _torch(bool on) async {
    try {
      on ? await TorchLight.enableTorch() : await TorchLight.disableTorch();
    } catch (_) {
      if (mounted) setState(() => _available = false);
    }
  }

  Future<void> _start() async {
    HapticFeedback.mediumImpact();
    _timer?.cancel();
    setState(() {
      _on = true;
      _since = DateTime.now();
    });
    WakelockPlus.enable().catchError((_) {});
    if (_mode == 'normal') {
      await _torch(true);
    } else if (_mode == 'sos') {
      _step = 0;
      _timer = Timer.periodic(const Duration(milliseconds: 200), (_) => _torch(_sos[_step++ % _sos.length] == 1));
    } else {
      var lit = false;
      _timer = Timer.periodic(Duration(milliseconds: (1000 / _speed / 2).round()), (_) => _torch(lit = !lit));
    }
  }

  Future<void> _stop() async {
    _timer?.cancel();
    await _torch(false);
    WakelockPlus.disable().catchError((_) {});
    if (mounted) setState(() => _on = false);
  }

  @override
  void dispose() {
    _timer?.cancel();
    _torch(false);
    WakelockPlus.disable().catchError((_) {});
    super.dispose();
  }

  void _whiteScreen() {
    WakelockPlus.enable().catchError((_) {});
    Navigator.of(context).push(MaterialPageRoute(
      fullscreenDialog: true,
      builder: (ctx) => GestureDetector(
        onTap: () => Navigator.pop(ctx),
        child: Scaffold(
          backgroundColor: Colors.white,
          body: SafeArea(
              child: Align(
                  alignment: Alignment.bottomCenter,
                  child: Padding(
                      padding: const EdgeInsets.all(30),
                      child: Text(t('اضغط في أي حتة عشان تطلع', 'اضغط في أي مكان للخروج', 'Tap anywhere to exit'), style: const TextStyle(color: Colors.black38))))),
        ),
      ),
    )).then((_) => _on ? null : WakelockPlus.disable().catchError((_) {}));
  }

  @override
  Widget build(BuildContext context) {
    return ToolList(children: [
      if (!_available)
        NoteBox(
            t('الفلاش ما متاح هنا (أو الإذن مقفول) — استعمل «الشاشة البيضاء» تحت.', 'الفلاش غير متاح هنا (أو الإذن مرفوض) — استخدم «الشاشة البيضاء» أدناه.',
                'Flash is unavailable here (or permission denied) — use "White screen" below.'),
            kind: NoteKind.warn),
      Center(
        child: GestureDetector(
          onTap: _available ? (_on ? _stop : _start) : null,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            width: 210,
            height: 210,
            margin: const EdgeInsets.symmetric(vertical: 16),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(colors: _on ? [Colors.white, SD.goldLight, SD.gold] : [SD.brownLight, SD.brown, SD.brownDeep]),
              border: Border.all(color: SD.gold, width: 4),
              boxShadow: [if (_on) BoxShadow(color: SD.goldLight.withValues(alpha: .8), blurRadius: 60, spreadRadius: 10)],
            ),
            child: Icon(_on ? Icons.flashlight_on_rounded : Icons.flashlight_off_rounded, size: 90, color: _on ? SD.brownDeep : SD.goldLight),
          ),
        ),
      ),
      Center(
          child: Text(
              _on
                  ? '${t('شغّال', 'يعمل', 'On')} ${_mode == 'sos' ? '— SOS' : _mode == 'strobe' ? '— ${tr('وميض', 'Strobe')}' : ''}'
                  : t('اضغط الدائرة عشان تولّع', 'اضغط الدائرة للتشغيل', 'Tap the circle to turn on'), style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18))),
      const SizedBox(height: 14),
      SCard(
        title: tr('الوضع', 'Mode'),
        icon: Icons.tune_rounded,
        color: SD.gold,
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          SegmentedButton<String>(
            segments: [
              ButtonSegment(value: 'normal', label: Text(tr('عادي', 'Steady'))),
              const ButtonSegment(value: 'sos', label: Text('SOS')),
              ButtonSegment(value: 'strobe', label: Text(tr('وميض', 'Strobe'))),
            ],
            selected: {_mode},
            onSelectionChanged: (v) {
              setState(() => _mode = v.first);
              if (_on) _start();
            },
          ),
          if (_mode == 'strobe') ...[
            const SizedBox(height: 8),
            Text('${tr('السرعة', 'Speed')}: ${_speed.round()} ${tr('ومضة/ثانية', 'flashes/sec')}'),
            Slider(value: _speed, min: 1, max: 15, divisions: 14, onChanged: (v) => setState(() => _speed = v), onChangeEnd: (_) => _on ? _start() : null),
          ],
          if (_mode == 'sos')
            NoteBox(
                t('SOS هي إشارة الاستغاثة الدولية (··· ––– ···) — مفيدة لو اتزنقت بالليل في طريق سفر.', 'SOS هي إشارة الاستغاثة الدولية (··· ––– ···) — مفيدة إن علِقت ليلاً في طريق سفر.',
                    'SOS is the international distress signal (··· ––– ···) — useful if you get stranded at night on the road.'),
                kind: NoteKind.info),
        ]),
      ),
      OutlinedButton.icon(onPressed: _whiteScreen, icon: const Icon(Icons.brightness_high_rounded), label: Text(t('شاشة بيضاء (ارفع السطوع للآخر)', 'شاشة بيضاء (ارفع السطوع للحد الأقصى)', 'White screen (turn brightness all the way up)'))),
      const SizedBox(height: 12),
      if (_on && _since != null) InfoRow(t('شغّال من', 'يعمل منذ', 'On for'), '${DateTime.now().difference(_since!).inMinutes} ${tr('دقيقة', 'min')}'),
      NoteBox(
          t('الفلاش بيصرف بطارية — لو القطوعة طويلة، استعمله على فترات واحتفظ بشحن للتلفون.', 'الفلاش يستهلك البطارية — إن طال انقطاع الكهرباء فاستخدمه على فترات واحتفظ بشحن للهاتف.',
              'The flash drains the battery — during long power cuts, use it in bursts and save some charge.'),
          kind: NoteKind.tip),
    ]);
  }
}
