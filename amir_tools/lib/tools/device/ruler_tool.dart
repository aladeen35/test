import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/format.dart';
import '../../core/state.dart';
import '../../core/theme.dart';
import '../../core/widgets.dart';

/// المسطرة على الشاشة مع معايرة ببطاقة بنكية (8.56 سم)
class RulerTool extends StatefulWidget {
  const RulerTool({super.key});
  @override
  State<RulerTool> createState() => _RulerToolState();
}

class _RulerToolState extends State<RulerTool> {
  late double _scale = context.read<AppState>().getData<num>('ruler_scale')?.toDouble() ?? 1.0;
  bool _inch = false, _calib = false;
  double? _mark;

  /// بكسل منطقي لكل سم حسب معيار Flutter (160 dp/بوصة × التصحيح)
  double get _pxPerCm => 160 / 2.54 * _scale;

  @override
  Widget build(BuildContext context) {
    final unitPx = _inch ? _pxPerCm * 2.54 : _pxPerCm;
    return ToolList(children: [
      SegmentedButton<bool>(
        segments: const [ButtonSegment(value: false, label: Text('سنتيمتر')), ButtonSegment(value: true, label: Text('بوصة'))],
        selected: {_inch},
        onSelectionChanged: (v) => setState(() => _inch = v.first),
      ),
      const SizedBox(height: 12),
      GestureDetector(
        onTapDown: (d) => setState(() => _mark = d.localPosition.dx),
        onHorizontalDragUpdate: (d) => setState(() => _mark = d.localPosition.dx),
        child: Container(
          height: 130,
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [SD.goldLight, SD.gold], begin: Alignment.topCenter, end: Alignment.bottomCenter),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: SD.brownDeep, width: 1.5),
          ),
          child: Directionality(
            textDirection: TextDirection.ltr,
            child: CustomPaint(painter: _RulerPainter(unitPx, _inch, _mark), size: const Size(double.infinity, 130)),
          ),
        ),
      ),
      const SizedBox(height: 8),
      if (_mark != null)
        ResultHero(label: 'القياس من طرف الشاشة الشمال', value: _inch ? '${fmt(_mark! / unitPx, 2)} بوصة' : '${fmt(_mark! / unitPx, 1)} سم',
            sub: _inch ? '${fmt(_mark! / unitPx * 2.54, 1)} سم' : '${fmt(_mark! / unitPx / 2.54, 2)} بوصة'),
      const NoteBox('ختّ الحاجة على طرف الشاشة الشمال، واضغط أو اسحب صباعك لنهايتها.', kind: NoteKind.tip),
      SCard(
        title: 'المعايرة',
        icon: Icons.credit_card_rounded,
        color: SD.nile,
        trailing: Switch(value: _calib, onChanged: (v) => setState(() => _calib = v)),
        child: _calib
            ? Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                const Text('ختّ أي بطاقة بنك أو هوية (عرضها 8.56 سم) على الشاشة، وحرّك الشريط لغاية ما المستطيل يطابق البطاقة.'),
                const SizedBox(height: 10),
                Directionality(
                  textDirection: TextDirection.ltr,
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Container(
                      width: 8.56 * _pxPerCm,
                      height: 5.4 * _pxPerCm,
                      decoration: BoxDecoration(color: SD.nile.withValues(alpha: .25), border: Border.all(color: SD.nile, width: 2), borderRadius: BorderRadius.circular(10)),
                      alignment: Alignment.center,
                      child: const Text('8.56 × 5.4 سم'),
                    ),
                  ),
                ),
                Slider(
                  value: _scale,
                  min: .6,
                  max: 1.6,
                  onChanged: (v) => setState(() => _scale = v),
                  onChangeEnd: (v) => context.read<AppState>().setData('ruler_scale', v),
                ),
                Text('معامل التصحيح: ${fmt(_scale, 3)}', textAlign: TextAlign.center),
              ])
            : Text('المعايرة الحالية: ${fmt(_scale, 3)} — شغّلها لو المقاس ما مضبوط.'),
      ),
    ]);
  }
}

class _RulerPainter extends CustomPainter {
  final double unit;
  final bool inch;
  final double? mark;
  _RulerPainter(this.unit, this.inch, this.mark);

  @override
  void paint(Canvas c, Size s) {
    final p = Paint()
      ..color = SD.brownDeep
      ..strokeWidth = 1;
    final sub = inch ? 8 : 10;
    final step = unit / sub;
    var i = 0;
    for (double x = 0; x <= s.width; x += step, i++) {
      final major = i % sub == 0, half = i % (sub ~/ 2) == 0;
      c.drawLine(Offset(x, 0), Offset(x, major ? 40 : half ? 28 : 16), p..strokeWidth = major ? 1.6 : 1);
      if (major) {
        final tp = TextPainter(text: TextSpan(text: '${i ~/ sub}', style: const TextStyle(color: SD.brownDeep, fontSize: 13, fontWeight: FontWeight.w800)), textDirection: TextDirection.ltr)..layout();
        tp.paint(c, Offset(x + 2, 42));
      }
    }
    if (mark != null) {
      c.drawLine(Offset(mark!, 0), Offset(mark!, s.height), Paint()..color = SD.red..strokeWidth = 2.5);
    }
  }

  @override
  bool shouldRepaint(_RulerPainter o) => o.unit != unit || o.mark != mark || o.inch != inch;
}
