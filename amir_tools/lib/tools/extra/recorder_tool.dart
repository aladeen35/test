import 'dart:async';
import 'dart:io';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:record/record.dart';
import 'package:share_plus/share_plus.dart';
import '../../core/format.dart';
import '../../core/i18n.dart';
import '../../core/state.dart';
import '../../core/theme.dart';
import '../../core/widgets.dart';
import '../life/life_common.dart' show mapList, intOf, newId, confirmAsk, askText, EmptyHint;

/// «03:25» أو «1:03:25»
String clock(Duration d) {
  final h = d.inHours, m = d.inMinutes % 60, s = d.inSeconds % 60;
  return h > 0 ? '$h:${two(m)}:${two(s)}' : '${two(m)}:${two(s)}';
}

/// تحويل مستوى الصوت (dBFS) إلى نسبة 0..1
double ampLevel(double db) => db.isNaN ? 0 : ((db + 50) / 50).clamp(0.0, 1.0);

class RecorderTool extends StatefulWidget {
  const RecorderTool({super.key});
  @override
  State<RecorderTool> createState() => _RecorderToolState();
}

enum _RecState { idle, recording, paused }

class _RecorderToolState extends State<RecorderTool> {
  AudioRecorder? _rec;
  _RecState _rs = _RecState.idle;
  final _sw = Stopwatch();
  Timer? _tick;
  StreamSubscription<Amplitude>? _ampSub;
  double _level = 0;
  final List<double> _wave = [];
  String? _curPath;
  bool _busy = false;

  AudioPlayer? _player;
  final List<StreamSubscription> _pSubs = [];
  String? _playingId;
  PlayerState _ps = PlayerState.stopped;
  Duration _pos = Duration.zero, _dur = Duration.zero;

  AppState? _s;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _s = context.read<AppState>();
  }

  @override
  void dispose() {
    _tick?.cancel();
    _ampSub?.cancel();
    for (final s in _pSubs) {
      s.cancel();
    }
    final rec = _rec, path = _curPath, s = _s, ms = _sw.elapsedMilliseconds;
    if (rec != null) {
      // لو الخروج أثناء التسجيل: احفظه باسم تلقائي
      () async {
        try {
          if (_rs != _RecState.idle && path != null) {
            final p = await rec.stop();
            if (s != null && p != null) _addEntry(s, p, null, ms);
          }
        } catch (_) {}
        try {
          await rec.dispose();
        } catch (_) {}
      }();
    }
    try {
      _player?.dispose();
    } catch (_) {}
    super.dispose();
  }

  List<Map<String, dynamic>> _list(AppState s) => mapList(s.getData<List>('recorder_list'));

  String _defaultName(AppState s) => '${t('تسجيل', 'تسجيل', 'Recording')} ${_list(s).length + 1}';

  void _addEntry(AppState s, String path, String? name, int ms) {
    var size = 0;
    try {
      size = File(path).lengthSync();
    } catch (_) {}
    final l = _list(s);
    l.insert(0, {'id': newId(), 'name': (name == null || name.trim().isEmpty) ? _defaultName(s) : name.trim(), 'path': path, 'ms': ms, 'size': size, 't': DateTime.now().millisecondsSinceEpoch});
    s.setData('recorder_list', l);
    s.awardDaily('recorder', 3, tr('مسجّل الصوت', 'Voice recorder'));
  }

  Future<bool> _askMic() async {
    try {
      final st = await Permission.microphone.request();
      if (st.isGranted) return true;
      if (!mounted) return false;
      if (st.isPermanentlyDenied || st.isRestricted) {
        final go = await confirmAsk(
          context,
          t('محتاجين إذن المايك', 'نحتاج إذن الميكروفون', 'Microphone permission needed'),
          t('الإذن مقفول. افتح الإعدادات واسمح للتطبيق يستخدم المايك.', 'الإذن مرفوض. افتح الإعدادات واسمح للتطبيق باستخدام الميكروفون.', 'Permission is blocked. Open settings and allow microphone access.'),
          ok: t('افتح الإعدادات', 'فتح الإعدادات', 'Open settings'),
          danger: false,
        );
        if (go) await openAppSettings();
      } else {
        toast(t('ما بنقدر نسجّل من غير إذن المايك', 'لا يمكن التسجيل دون إذن الميكروفون', 'Cannot record without microphone permission'));
      }
    } catch (_) {
      toast(t('التسجيل ما متاح في الجهاز ده', 'التسجيل غير متاح على هذا الجهاز', 'Recording is not available on this device'));
    }
    return false;
  }

  Future<void> _start() async {
    if (_busy) return;
    _busy = true;
    try {
      if (!await _askMic()) return;
      await _stopPlayback();
      _rec ??= AudioRecorder();
      final dir = Directory('${(await getApplicationDocumentsDirectory()).path}/recordings');
      await dir.create(recursive: true);
      final path = '${dir.path}/rec_${DateTime.now().millisecondsSinceEpoch}.m4a';
      await _rec!.start(const RecordConfig(encoder: AudioEncoder.aacLc, bitRate: 96000, sampleRate: 44100, numChannels: 1), path: path);
      _curPath = path;
      _sw
        ..reset()
        ..start();
      _wave.clear();
      _tick?.cancel();
      _tick = Timer.periodic(const Duration(milliseconds: 250), (_) {
        if (mounted) setState(() {});
      });
      await _ampSub?.cancel();
      _ampSub = _rec!.onAmplitudeChanged(const Duration(milliseconds: 120)).listen((a) {
        if (!mounted) return;
        setState(() {
          _level = ampLevel(a.current);
          _wave.add(_level);
          if (_wave.length > 48) _wave.removeAt(0);
        });
      });
      HapticFeedback.mediumImpact();
      if (mounted) setState(() => _rs = _RecState.recording);
    } catch (_) {
      toast(t('ما قدرنا نبدأ التسجيل', 'تعذّر بدء التسجيل', 'Could not start recording'));
    } finally {
      _busy = false;
    }
  }

  Future<void> _pauseResume() async {
    final r = _rec;
    if (r == null) return;
    try {
      if (_rs == _RecState.recording) {
        await r.pause();
        _sw.stop();
        setState(() {
          _rs = _RecState.paused;
          _level = 0;
        });
      } else if (_rs == _RecState.paused) {
        await r.resume();
        _sw.start();
        setState(() => _rs = _RecState.recording);
      }
    } catch (_) {
      toast(t('الإيقاف المؤقت ما مدعوم هنا', 'الإيقاف المؤقت غير مدعوم هنا', 'Pause is not supported here'));
    }
  }

  void _resetRecUi() {
    _tick?.cancel();
    _ampSub?.cancel();
    _ampSub = null;
    _sw.stop();
    _curPath = null;
    _level = 0;
    _rs = _RecState.idle;
  }

  Future<void> _stop() async {
    final r = _rec;
    if (r == null || _rs == _RecState.idle) return;
    final ms = _sw.elapsedMilliseconds;
    String? path;
    try {
      path = await r.stop();
    } catch (_) {}
    path ??= _curPath;
    if (!mounted) return;
    setState(_resetRecUi);
    if (path == null) return toast(t('التسجيل ما اتحفظ', 'لم يُحفظ التسجيل', 'Recording was not saved'));
    final s = context.read<AppState>();
    final name = await askText(context, t('سمّي التسجيل', 'اسم التسجيل', 'Name this recording'), initial: _defaultName(s));
    _addEntry(s, path, name, ms);
    toast(t('اتحفظ ✓', 'تم الحفظ ✓', 'Saved ✓'));
  }

  Future<void> _discard() async {
    final r = _rec;
    if (r == null) return;
    try {
      await r.cancel();
    } catch (_) {}
    if (mounted) setState(_resetRecUi);
  }

  /* ───── التشغيل ───── */

  AudioPlayer _makePlayer() {
    final p = AudioPlayer();
    _pSubs.addAll([
      p.onPositionChanged.listen((d) {
        if (mounted) setState(() => _pos = d);
      }),
      p.onDurationChanged.listen((d) {
        if (mounted && d > Duration.zero) setState(() => _dur = d);
      }),
      p.onPlayerStateChanged.listen((st) {
        if (mounted) setState(() => _ps = st);
      }),
      p.onPlayerComplete.listen((_) {
        if (mounted) {
          setState(() {
            _pos = Duration.zero;
            _ps = PlayerState.completed;
          });
        }
      }),
    ]);
    return p;
  }

  Future<void> _stopPlayback() async {
    try {
      await _player?.stop();
    } catch (_) {}
    if (mounted) {
      setState(() {
        _playingId = null;
        _pos = Duration.zero;
      });
    }
  }

  Future<void> _play(Map<String, dynamic> e) async {
    if (_rs != _RecState.idle) return toast(t('وقّف التسجيل أول', 'أوقف التسجيل أولًا', 'Stop recording first'));
    try {
      _player ??= _makePlayer();
      final p = _player!;
      if (_playingId == e['id']) {
        if (_ps == PlayerState.playing) {
          await p.pause();
        } else {
          await p.resume();
        }
        return;
      }
      final path = '${e['path']}';
      if (!await File(path).exists()) return toast(t('الملف ما موجود', 'الملف غير موجود', 'File not found'));
      await p.stop();
      setState(() {
        _playingId = e['id'] as String;
        _pos = Duration.zero;
        _dur = Duration(milliseconds: intOf(e['ms']));
      });
      await p.play(DeviceFileSource(path));
    } catch (_) {
      toast(t('ما قدرنا نشغّل التسجيل', 'تعذّر تشغيل التسجيل', 'Could not play the recording'));
    }
  }

  Future<void> _rename(Map<String, dynamic> e) async {
    final s = context.read<AppState>();
    final v = await askText(context, t('اسم جديد', 'اسم جديد', 'New name'), initial: '${e['name']}');
    if (v == null || v.trim().isEmpty) return;
    final l = _list(s);
    final i = l.indexWhere((x) => x['id'] == e['id']);
    if (i >= 0) l[i]['name'] = v.trim();
    s.setData('recorder_list', l);
  }

  Future<void> _share(Map<String, dynamic> e) async {
    try {
      final path = '${e['path']}';
      if (!await File(path).exists()) return toast(t('الملف ما موجود', 'الملف غير موجود', 'File not found'));
      await SharePlus.instance.share(ShareParams(files: [XFile(path, mimeType: 'audio/mp4')], text: '${e['name']}'));
    } catch (_) {
      toast(t('ما قدرنا نشارك', 'تعذرت المشاركة', 'Could not share'));
    }
  }

  Future<void> _delete(Map<String, dynamic> e) async {
    final s = context.read<AppState>();
    if (!await confirmAsk(context, t('نمسح التسجيل؟', 'حذف التسجيل؟', 'Delete recording?'), '${e['name']}')) return;
    if (_playingId == e['id']) await _stopPlayback();
    try {
      final f = File('${e['path']}');
      if (await f.exists()) await f.delete();
    } catch (_) {}
    s.setData('recorder_list', _list(s)..removeWhere((x) => x['id'] == e['id']));
  }

  @override
  Widget build(BuildContext context) {
    if (kIsWeb) {
      return ToolList(children: [
        NoteBox(t('المسجّل شغّال في تطبيق الموبايل بس (أندرويد/آيفون).', 'المسجّل متاح في تطبيق الجوال فقط (أندرويد/آيفون).', 'The recorder works in the mobile app only (Android/iOS).'), kind: NoteKind.warn),
      ]);
    }
    final s = context.watch<AppState>();
    final list = _list(s);
    final totalMs = list.fold(0, (a, e) => a + intOf(e['ms']));
    final totalSize = list.fold(0, (a, e) => a + intOf(e['size']));
    final recOn = _rs != _RecState.idle;
    return ToolList(children: [
      _recorderCard(recOn),
      StatGrid([
        StatChip('${list.length}', t('تسجيل', 'تسجيل', 'Recordings'), color: SD.henna, icon: Icons.mic_rounded),
        StatChip(clock(Duration(milliseconds: totalMs)), t('المدة الكلية', 'المدة الكلية', 'Total time'), color: SD.nile, icon: Icons.timer_rounded),
        StatChip(fmtBytes(totalSize), t('الحجم', 'الحجم', 'Size'), color: SD.gold, icon: Icons.sd_storage_rounded),
      ]),
      const SizedBox(height: 14),
      SCard(
        title: t('تسجيلاتي', 'تسجيلاتي', 'My recordings'),
        icon: Icons.library_music_rounded,
        color: SD.indigo,
        child: list.isEmpty
            ? EmptyHint(Icons.mic_none_rounded, t('لسه ما سجّلت حاجة — جرّب تسجّل ملاحظة صوتية أو محاضرة', 'لا توجد تسجيلات بعد — سجّل ملاحظة صوتية أو محاضرة', 'No recordings yet — try a voice memo or a lecture'))
            : Column(children: [for (final e in list) _item(e)]),
      ),
      NoteBox(t('التسجيلات محفوظة جوه التطبيق بصيغة m4a. شاركها عشان تحفظها في مكان تاني.', 'التسجيلات محفوظة داخل التطبيق بصيغة m4a. شاركها لحفظها في مكان آخر.',
          'Recordings are saved inside the app as m4a. Share them to keep a copy elsewhere.')),
    ]);
  }

  Widget _recorderCard(bool recOn) {
    final paused = _rs == _RecState.paused;
    final c = recOn ? (paused ? SD.gold : SD.red) : SD.henna;
    return SCard(
      title: recOn ? (paused ? t('موقّف مؤقتًا', 'متوقف مؤقتًا', 'Paused') : t('بنسجّل…', 'جارٍ التسجيل…', 'Recording…')) : t('تسجيل جديد', 'تسجيل جديد', 'New recording'),
      icon: Icons.fiber_manual_record_rounded,
      color: c,
      child: Column(children: [
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(clock(_sw.elapsed),
              style: TextStyle(fontSize: 46, fontWeight: FontWeight.w800, color: readable(context, c), fontFeatures: const [FontFeature.tabularFigures()])),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 48,
          child: Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
            for (var i = 0; i < 48; i++)
              Expanded(
                child: Center(
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 120),
                    width: 3,
                    height: 4 + 44 * (i < 48 - _wave.length ? 0 : _wave[i - (48 - _wave.length)]),
                    decoration: BoxDecoration(color: c.withValues(alpha: recOn ? .85 : .25), borderRadius: BorderRadius.circular(2)),
                  ),
                ),
              ),
          ]),
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(value: recOn ? _level : 0, minHeight: 6, color: c, backgroundColor: c.withValues(alpha: .15)),
        ),
        const SizedBox(height: 16),
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          if (recOn)
            IconButton.outlined(
              tooltip: t('الغِ', 'إلغاء', 'Discard'),
              onPressed: _discard,
              icon: const Icon(Icons.delete_outline_rounded),
            ),
          const SizedBox(width: 14),
          SizedBox(
            width: 76,
            height: 76,
            child: FilledButton(
              style: FilledButton.styleFrom(shape: const CircleBorder(), padding: EdgeInsets.zero, backgroundColor: recOn ? SD.red : SD.henna, foregroundColor: Colors.white),
              onPressed: recOn ? _stop : _start,
              child: Icon(recOn ? Icons.stop_rounded : Icons.mic_rounded, size: 38),
            ),
          ),
          const SizedBox(width: 14),
          if (recOn)
            IconButton.outlined(
              tooltip: paused ? t('واصل', 'استئناف', 'Resume') : t('وقّف شوية', 'إيقاف مؤقت', 'Pause'),
              onPressed: _pauseResume,
              icon: Icon(paused ? Icons.play_arrow_rounded : Icons.pause_rounded),
            ),
        ]),
        const SizedBox(height: 6),
        Text(
          recOn ? t('دوس المربع عشان توقف وتحفظ', 'اضغط المربع للإيقاف والحفظ', 'Tap stop to save') : t('دوس المايك عشان تبدأ', 'اضغط الميكروفون للبدء', 'Tap the mic to start'),
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 12.5, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: .6)),
        ),
      ]),
    );
  }

  Widget _item(Map<String, dynamic> e) {
    final active = _playingId == e['id'];
    final playing = active && _ps == PlayerState.playing;
    final dur = active && _dur > Duration.zero ? _dur : Duration(milliseconds: intOf(e['ms']));
    final muted = Theme.of(context).colorScheme.onSurface.withValues(alpha: .6);
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsetsDirectional.fromSTEB(4, 4, 0, 4),
      decoration: BoxDecoration(
        color: active ? SD.indigo.withValues(alpha: .12) : null,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(children: [
        Row(children: [
          IconButton.filledTonal(onPressed: () => _play(e), icon: Icon(playing ? Icons.pause_rounded : Icons.play_arrow_rounded)),
          const SizedBox(width: 6),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('${e['name']}', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w800)),
              Text(
                '${clock(Duration(milliseconds: intOf(e['ms'])))} • ${fmtBytes(intOf(e['size']))} • ${fmtDateAr(DateTime.fromMillisecondsSinceEpoch(intOf(e['t'])), weekday: false)}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 12, color: muted),
              ),
            ]),
          ),
          PopupMenuButton<String>(
            onSelected: (v) => switch (v) {
              'rename' => _rename(e),
              'share' => _share(e),
              _ => _delete(e),
            },
            itemBuilder: (_) => [
              PopupMenuItem(value: 'rename', child: Text(t('غيّر الاسم', 'إعادة تسمية', 'Rename'))),
              PopupMenuItem(value: 'share', child: Text(t('شارك', 'مشاركة', 'Share'))),
              PopupMenuItem(value: 'del', child: Text(t('امسح', 'حذف', 'Delete'))),
            ],
          ),
        ]),
        if (active)
          Row(children: [
            Text(clock(_pos), style: TextStyle(fontSize: 12, color: muted)),
            Expanded(
              child: Slider(
                value: _pos.inMilliseconds.clamp(0, dur.inMilliseconds == 0 ? 1 : dur.inMilliseconds).toDouble(),
                max: dur.inMilliseconds == 0 ? 1 : dur.inMilliseconds.toDouble(),
                onChanged: (v) => setState(() => _pos = Duration(milliseconds: v.round())),
                onChangeEnd: (v) async {
                  try {
                    await _player?.seek(Duration(milliseconds: v.round()));
                  } catch (_) {}
                },
              ),
            ),
            Text(clock(dur), style: TextStyle(fontSize: 12, color: muted)),
            const SizedBox(width: 8),
          ]),
      ]),
    );
  }
}
