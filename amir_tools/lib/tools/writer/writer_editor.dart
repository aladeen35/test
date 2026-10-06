import 'dart:async';
import 'package:flutter/material.dart';
import '../../core/i18n.dart';
import '../../core/state.dart';
import '../../core/theme.dart';
import 'writer_data.dart';

/// محرر بلا مشتتات لنص المشهد: حفظ تلقائي، عدّ كلمات وحروف، زمن القراءة
class SceneEditor extends StatefulWidget {
  final AppState state;
  final String projectId, chapterId, sceneId;
  const SceneEditor({super.key, required this.state, required this.projectId, required this.chapterId, required this.sceneId});

  static Future<void> open(BuildContext context, AppState s, String pid, String cid, String sid) =>
      Navigator.of(context).push(MaterialPageRoute(fullscreenDialog: true, builder: (_) => SceneEditor(state: s, projectId: pid, chapterId: cid, sceneId: sid)));

  @override
  State<SceneEditor> createState() => _SceneEditorState();
}

class _SceneEditorState extends State<SceneEditor> {
  late final WStore st = WStore(widget.state);
  late final TextEditingController _c;
  Timer? _debounce;
  late int _savedWc;
  late String _savedText;
  bool _focus = false;
  bool _dirty = false;
  double _font = 18;
  String _title = '';

  @override
  void initState() {
    super.initState();
    _savedText = st.text(widget.sceneId);
    _savedWc = wordCount(_savedText);
    _c = TextEditingController(text: _savedText);
    _font = numOf((widget.state.getData<Map>('writer_prefs') ?? const {})['font'], 18);
    final p = st.projects.firstWhere((x) => x['id'] == widget.projectId, orElse: () => {});
    for (final ch in chaptersOf(p)) {
      for (final sc in mapList(ch['scenes'])) {
        if (sc['id'] == widget.sceneId) _title = '${sc['title'] ?? ''}';
      }
    }
  }

  void _changed(String _) {
    setState(() => _dirty = true);
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 900), _save);
  }

  void _save() {
    _debounce?.cancel();
    _saveText(_c.text);
  }

  void _saveText(String txt) {
    if (txt == _savedText) {
      if (mounted && _dirty) setState(() => _dirty = false);
      return;
    }
    final wc = wordCount(txt);
    st.setText(widget.sceneId, txt);
    st.edit((p) {
      for (final ch in sub(p, 'chapters')) {
        if (ch['id'] != widget.chapterId) continue;
        for (final sc in sub(ch, 'scenes')) {
          if (sc['id'] == widget.sceneId) {
            sc['wc'] = wc;
            if (sc['status'] == null || sc['status'] == 'idea') sc['status'] = 'draft';
          }
        }
      }
    }, id: widget.projectId);
    st.addWords(wc - _savedWc);
    _savedWc = wc;
    _savedText = txt;
    if (mounted) setState(() => _dirty = false);
  }

  void _setFont(double v) {
    setState(() => _font = v.clamp(13, 30));
    widget.state.setData('writer_prefs', {...?widget.state.getData<Map>('writer_prefs'), 'font': _font});
  }

  @override
  void dispose() {
    _debounce?.cancel();
    final txt = _c.text;
    // الحفظ بعد إغلاق الشاشة (لا نُخطر المستمعين أثناء التفكيك)
    if (txt != _savedText) Future.microtask(() => _saveText(txt));
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final txt = _c.text;
    final wc = wordCount(txt);
    final chars = txt.replaceAll(RegExp(r'\s'), '').length;
    final mins = readMinutes(wc);
    final dark = Theme.of(context).brightness == Brightness.dark;
    final bg = dark ? const Color(0xFF2A160A) : const Color(0xFFFFFBF2);
    return PopScope(
      onPopInvokedWithResult: (_, _) => _save(),
      child: Scaffold(
        backgroundColor: bg,
        appBar: _focus
            ? null
            : AppBar(
                backgroundColor: bg,
                titleSpacing: 0,
                title: Text(_title.isEmpty ? t('مشهد', 'مشهد', 'Scene') : _title, maxLines: 1, overflow: TextOverflow.ellipsis),
                actions: [
                  IconButton(tooltip: t('صغّر الخط', 'تصغير الخط', 'Smaller text'), onPressed: () => _setFont(_font - 1), icon: const Icon(Icons.text_decrease_rounded)),
                  IconButton(tooltip: t('كبّر الخط', 'تكبير الخط', 'Larger text'), onPressed: () => _setFont(_font + 1), icon: const Icon(Icons.text_increase_rounded)),
                  IconButton(
                      tooltip: t('وضع التركيز', 'وضع التركيز', 'Focus mode'),
                      onPressed: () => setState(() => _focus = true),
                      icon: const Icon(Icons.center_focus_strong_rounded)),
                ],
              ),
        body: SafeArea(
          child: Column(children: [
            if (_focus)
              Align(
                alignment: AlignmentDirectional.centerEnd,
                child: IconButton(
                  tooltip: t('اطلع من التركيز', 'الخروج من التركيز', 'Exit focus'),
                  onPressed: () => setState(() => _focus = false),
                  icon: Icon(Icons.close_fullscreen_rounded, color: SD.gold.withValues(alpha: .7)),
                ),
              ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 18),
                child: TextField(
                  controller: _c,
                  onChanged: _changed,
                  expands: true,
                  maxLines: null,
                  minLines: null,
                  autofocus: false,
                  keyboardType: TextInputType.multiline,
                  textAlignVertical: TextAlignVertical.top,
                  style: TextStyle(fontSize: _font, height: 1.8),
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    filled: false,
                    hintText: t('ابدأ اكتب هنا… الحفظ تلقائي', 'ابدأ الكتابة هنا… الحفظ تلقائي', 'Start writing… it saves automatically'),
                  ),
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(border: Border(top: BorderSide(color: SD.gold.withValues(alpha: .3)))),
              child: Row(children: [
                Expanded(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: AlignmentDirectional.centerStart,
                    child: Text(
                      '${tr('كلمات', 'Words')}: $wc · ${tr('حروف', 'Chars')}: $chars · ⏱ $mins ${tr('د قراءة', 'min read')}',
                      maxLines: 1,
                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Icon(_dirty ? Icons.edit_rounded : Icons.cloud_done_rounded, size: 18, color: _dirty ? SD.orange : SD.green),
              ]),
            ),
          ]),
        ),
      ),
    );
  }
}
