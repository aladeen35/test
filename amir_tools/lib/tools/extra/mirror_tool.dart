import 'dart:math' as math;
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import '../../core/i18n.dart';
import '../../core/state.dart';
import '../../core/theme.dart';
import '../../core/widgets.dart';

class MirrorTool extends StatefulWidget {
  const MirrorTool({super.key});
  @override
  State<MirrorTool> createState() => _MirrorToolState();
}

class _MirrorToolState extends State<MirrorTool> with WidgetsBindingObserver {
  CameraController? _cam;
  bool _starting = false;
  String? _error;
  bool _blocked = false;
  bool _ring = true;
  bool _frozen = false;
  bool _flip = false;
  double _zoom = 1, _minZoom = 1, _maxZoom = 1;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // تشغيل الكاميرا بعد أول إطار فقط (ومع التقاط أي خطأ)
    WidgetsBinding.instance.addPostFrameCallback((_) => _init());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    final c = _cam;
    _cam = null;
    try {
      c?.dispose();
    } catch (_) {}
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final c = _cam;
    if (state == AppLifecycleState.inactive || state == AppLifecycleState.paused) {
      if (c == null) return;
      _cam = null;
      if (mounted) setState(() => _frozen = false);
      try {
        c.dispose();
      } catch (_) {}
    } else if (state == AppLifecycleState.resumed && c == null && _error == null && !_blocked) {
      _init();
    }
  }

  Future<void> _init() async {
    if (!mounted || _starting || _cam != null) return;
    if (kIsWeb) {
      setState(() => _error = 'web');
      return;
    }
    _starting = true;
    try {
      final st = await Permission.camera.request();
      if (!st.isGranted) {
        if (mounted) {
          setState(() {
            _blocked = true;
            _error = st.isPermanentlyDenied ? 'perm_forever' : 'perm';
          });
        }
        return;
      }
      final cams = await availableCameras();
      if (cams.isEmpty) throw StateError('no camera');
      final front = cams.firstWhere((c) => c.lensDirection == CameraLensDirection.front, orElse: () => cams.first);
      final c = CameraController(front, ResolutionPreset.high, enableAudio: false);
      await c.initialize();
      if (!mounted) {
        await c.dispose();
        return;
      }
      double mn = 1, mx = 1;
      try {
        mn = await c.getMinZoomLevel();
        mx = await c.getMaxZoomLevel();
      } catch (_) {}
      if (!mounted) {
        await c.dispose();
        return;
      }
      setState(() {
        _cam = c;
        _error = null;
        _blocked = false;
        _minZoom = mn;
        _maxZoom = math.max(mn, math.min(mx, 8));
        _zoom = mn;
        _frozen = false;
      });
      context.read<AppState>().awardDaily('mirror', 2, tr('المراية', 'Mirror'));
    } catch (_) {
      if (mounted) setState(() => _error = 'fail');
    } finally {
      _starting = false;
    }
  }

  Future<void> _retry() async {
    setState(() {
      _error = null;
      _blocked = false;
    });
    await _init();
  }

  Future<void> _toggleFreeze() async {
    final c = _cam;
    if (c == null) return;
    try {
      if (_frozen) {
        await c.resumePreview();
      } else {
        await c.pausePreview();
      }
      if (mounted) setState(() => _frozen = !_frozen);
    } catch (_) {}
  }

  Future<void> _setZoom(double z) async {
    setState(() => _zoom = z);
    try {
      await _cam?.setZoomLevel(z);
    } catch (_) {}
  }

  Widget _fallback() {
    final msg = switch (_error) {
      'web' => t('المراية شغّالة في تطبيق الموبايل بس.', 'المرآة متاحة في تطبيق الجوال فقط.', 'The mirror works in the mobile app only.'),
      'perm' => t('محتاجين إذن الكاميرا عشان المراية تشتغل.', 'نحتاج إذن الكاميرا لتعمل المرآة.', 'Camera permission is needed for the mirror.'),
      'perm_forever' => t('إذن الكاميرا مقفول — افتح الإعدادات واسمح بيهو.', 'إذن الكاميرا مرفوض — افعّله من الإعدادات.', 'Camera permission is blocked — enable it in settings.'),
      _ => t('ما قدرنا نفتح الكاميرا الأمامية في الجهاز ده.', 'تعذّر تشغيل الكاميرا الأمامية على هذا الجهاز.', 'Could not open the front camera on this device.'),
    };
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      NoteBox(msg, kind: NoteKind.warn),
      if (_error != 'web')
        Row(children: [
          Expanded(
            child: FilledButton.icon(
              onPressed: _retry,
              icon: const Icon(Icons.refresh_rounded),
              label: FittedBox(fit: BoxFit.scaleDown, child: Text(t('جرّب تاني', 'إعادة المحاولة', 'Try again'))),
            ),
          ),
          if (_error == 'perm_forever') ...[
            const SizedBox(width: 10),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () async {
                  try {
                    await openAppSettings();
                  } catch (_) {}
                },
                icon: const Icon(Icons.settings_rounded),
                label: FittedBox(fit: BoxFit.scaleDown, child: Text(t('الإعدادات', 'الإعدادات', 'Settings'))),
              ),
            ),
          ],
        ]),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final c = _cam;
    final ready = c != null && c.value.isInitialized;
    final h = MediaQuery.sizeOf(context).height;
    return ToolList(children: [
      AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        height: math.max(320, h * .58),
        margin: const EdgeInsets.only(bottom: 14),
        padding: EdgeInsets.all(_ring ? 22 : 3),
        decoration: BoxDecoration(
          color: _ring ? Colors.white : SD.gold,
          borderRadius: BorderRadius.circular(_ring ? 40 : 28),
          boxShadow: _ring ? [BoxShadow(color: Colors.white.withValues(alpha: .7), blurRadius: 30, spreadRadius: 4)] : null,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(_ring ? 24 : 25),
          child: Container(
            color: Colors.black,
            child: ready
                ? Stack(fit: StackFit.expand, children: [
                    FittedBox(
                      fit: BoxFit.cover,
                      clipBehavior: Clip.hardEdge,
                      child: SizedBox(
                        width: 300,
                        height: 300 * (c.value.aspectRatio == 0 ? 1.33 : c.value.aspectRatio),
                        child: Transform(
                          alignment: Alignment.center,
                          transform: Matrix4.diagonal3Values(_flip ? -1 : 1, 1, 1),
                          child: CameraPreview(c),
                        ),
                      ),
                    ),
                    if (_frozen)
                      PositionedDirectional(
                        top: 10,
                        start: 10,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(12)),
                          child: Text('❄ ${t('الصورة واقفة', 'الصورة مجمّدة', 'Frozen')}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
                        ),
                      ),
                  ])
                : Center(
                    child: _error != null
                        ? const Icon(Icons.no_photography_rounded, color: Colors.white54, size: 56)
                        : const CircularProgressIndicator(),
                  ),
          ),
        ),
      ),
      if (_error != null) _fallback(),
      SCard(
        title: t('التحكم', 'التحكم', 'Controls'),
        icon: Icons.tune_rounded,
        color: SD.pink,
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            value: _ring,
            onChanged: (v) => setState(() => _ring = v),
            secondary: const Icon(Icons.light_mode_rounded),
            title: Text(t('إضاءة الحلقة (نور أبيض)', 'إضاءة حلقية (إطار أبيض)', 'Ring light (white frame)'), maxLines: 2, overflow: TextOverflow.ellipsis),
            subtitle: Text(t('بتنوّر وشّك في الضلمة — علّي سطوع الشاشة', 'تضيء وجهك في الإضاءة الخافتة — ارفع سطوع الشاشة', 'Lights your face in dim places — turn screen brightness up'),
                maxLines: 2, overflow: TextOverflow.ellipsis),
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            value: _flip,
            onChanged: (v) => setState(() => _flip = v),
            secondary: const Icon(Icons.flip_rounded),
            title: Text(t('اقلب الصورة', 'عكس الصورة', 'Flip image'), maxLines: 1, overflow: TextOverflow.ellipsis),
            subtitle: Text(t('لو الصورة ما طالعة زي المراية', 'إذا لم تظهر الصورة كالمرآة', 'If the view does not look like a mirror'), maxLines: 2, overflow: TextOverflow.ellipsis),
          ),
          if (_maxZoom > _minZoom) ...[
            Row(children: [
              const Icon(Icons.zoom_in_rounded),
              const SizedBox(width: 8),
              Expanded(child: Text(t('التكبير', 'التكبير', 'Zoom'), style: const TextStyle(fontWeight: FontWeight.w700))),
              Text('${_zoom.toStringAsFixed(1)}×'),
            ]),
            Slider(value: _zoom.clamp(_minZoom, _maxZoom), min: _minZoom, max: _maxZoom, onChanged: ready ? _setZoom : null),
          ],
          const SizedBox(height: 6),
          FilledButton.icon(
            onPressed: ready ? _toggleFreeze : null,
            icon: Icon(_frozen ? Icons.play_arrow_rounded : Icons.ac_unit_rounded),
            label: Text(_frozen ? t('شغّل تاني', 'استئناف', 'Resume') : t('وقّف الصورة', 'تجميد الصورة', 'Freeze frame')),
          ),
        ]),
      ),
      NoteBox(t('المراية ما بتصوّر ولا بتحفظ أي حاجة — الصورة بتظهر في جهازك بس.', 'المرآة لا تلتقط ولا تحفظ أي صور — العرض على جهازك فقط.',
          'The mirror never captures or saves anything — the view stays on your device.'), kind: NoteKind.tip),
    ]);
  }
}
