import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/format.dart';
import '../../core/i18n.dart';
import '../../core/state.dart';
import '../../core/theme.dart';
import '../../core/widgets.dart';

/// المسطرة بالطول: تمتد من أعلى الشاشة لأسفلها على الحافة، مع معايرة ببطاقة بنكية (8.56 سم)
class RulerTool extends StatefulWidget {
  const RulerTool({super.key});
  @override
  State<RulerTool> createState() => _RulerToolState();
}

class _RulerToolState extends State<RulerTool> {
  late double _scale = context.read<AppState>().getData<num>('ruler_scale')?.toDouble() ?? 1.0;
  bool _inch = false;
  double? _mark;

  /// بكسل منطقي لكل سم (160 dp = بوصة في Flutter) × معامل المعايرة
  double get _pxPerCm => 160 / 2.54 * _scale;

  @override
  Widget build(BuildContext context) {
    final unitPx = _inch ? _pxPerCm * 2.54 : _pxPerCm;
    return LayoutBuilder(builder: (context, c) {
      final h = c.maxHeight;
      final total = h / unitPx;
      return Row(textDirection: TextDirection.ltr, children: [
        // المسطرة على الحافة اليسرى بطول الشاشة
        GestureDetector(
          onTapDown: (d) => setState(() => _mark = d.localPosition.dy),
          onVerticalDragUpdate: (d) => setState(() => _mark = d.localPosition.dy.clamp(0, h)),
          child: Container(
            width: 96,
            height: h,
            decoration: const BoxDecoration(
              gradient: LinearGradient(colors: [SD.goldLight, SD.gold]),
              border: Border(right: BorderSide(color: SD.brownDeep, width: 1.5)),
            ),
            child: CustomPaint(painter: _RulerPainter(unitPx, _inch, _mark), size: Size(96, h)),
          ),
        ),
        // اللوحة الجانبية: القياس والإعدادات
        Expanded(
          child: ListView(padding: const EdgeInsets.fromLTRB(14, 8, 14, 30), children: [
            SegmentedButton<bool>(
              segments: [ButtonSegment(value: false, label: Text(tr('سم', 'cm'))), ButtonSegment(value: true, label: Text(tr('بوصة', 'inch')))],
              selected: {_inch},
              onSelectionChanged: (v) => setState(() => _inch = v.first),
            ),
            const SizedBox(height: 12),
            ResultHero(
              label: t('القياس من فوق', 'القياس من الأعلى', 'Measured from top'),
              value: _mark == null ? '—' : (_inch ? '${fmt(_mark! / unitPx, 2)} in' : '${fmt(_mark! / unitPx, 1)} cm'),
              sub: _mark == null
                  ? t('اضغط أو اسحب على المسطرة', 'اضغط أو اسحب على المسطرة', 'Tap or drag on the ruler')
                  : (_inch ? '${fmt(_mark! / unitPx * 2.54, 1)} cm' : '${fmt(_mark! / unitPx / 2.54, 2)} in'),
            ),
            InfoRow(t('طول المسطرة في شاشتك', 'طول المسطرة على شاشتك', 'Ruler length on your screen'),
                _inch ? '${fmt(total, 1)} in' : '${fmt(total, 1)} cm'),
            NoteBox(
                t('ختّ الحاجة عند أعلى الشاشة (تحت الشريط)، واضغط عند نهايتها على المسطرة.', 'ضع الشيء عند أعلى الشاشة، ثم اضغط عند نهايته على المسطرة.',
                    'Place the object at the top edge, then tap where it ends on the ruler.'),
                kind: NoteKind.tip),
            SCard(
              title: tr('المعايرة', 'Calibration'),
              icon: Icons.credit_card_rounded,
              color: SD.nile,
              child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                Text(t('ختّ بطاقة بنك أو هوية بالطول جنب المسطرة؛ طولها 8.56 سم. حرّك الشريط لحدي ما الخط الأحمر يطابق نهايتها.',
                    'ضع بطاقة بنكية أو هوية بالطول بجانب المسطرة (طولها 8.56 سم)، وحرّك الشريط حتى يطابق الخط الأحمر نهايتها.',
                    'Hold a bank or ID card (8.56 cm long) along the ruler and move the slider until the red line matches its end.')),
                Slider(
                  value: _scale,
                  min: .6,
                  max: 1.6,
                  onChanged: (v) => setState(() {
                    _scale = v;
                    _mark = 8.56 * _pxPerCm;
                    _inch = false;
                  }),
                  onChangeEnd: (v) => context.read<AppState>().setData('ruler_scale', v),
                ),
                Text('${tr('معامل التصحيح', 'Correction factor')}: ${fmt(_scale, 3)}', textAlign: TextAlign.center),
                TextButton(
                  onPressed: () {
                    setState(() => _scale = 1);
                    context.read<AppState>().setData('ruler_scale', 1.0);
                  },
                  child: Text(tr('رجّع الأصل', 'Reset')),
                ),
              ]),
            ),
          ]),
        ),
      ]);
    });
  }
}

class _RulerPainter extends CustomPainter {
  final double unit;
  final bool inch;
  final double? mark;
  _RulerPainter(this.unit, this.inch, this.mark);

  @override
  void paint(Canvas c, Size s) {
    final p = Paint()..color = SD.brownDeep;
    final sub = inch ? 8 : 10;
    final step = unit / sub;
    var i = 0;
    for (double y = 0; y <= s.height; y += step, i++) {
      final major = i % sub == 0, half = i % (sub ~/ 2) == 0;
      c.drawLine(Offset(s.width, y), Offset(s.width - (major ? 44 : half ? 30 : 16), y), p..strokeWidth = major ? 1.8 : 1);
      if (major && i > 0) {
        final tp = TextPainter(
          text: TextSpan(text: '${i ~/ sub}', style: const TextStyle(color: SD.brownDeep, fontSize: 15, fontWeight: FontWeight.w800)),
          textDirection: TextDirection.ltr,
        )..layout();
        tp.paint(c, Offset(s.width - 48 - tp.width, y - tp.height / 2));
      }
    }
    final unitLbl = TextPainter(
      text: TextSpan(text: inch ? 'in' : 'cm', style: const TextStyle(color: SD.brownDeep, fontSize: 12, fontWeight: FontWeight.w700)),
      textDirection: TextDirection.ltr,
    )..layout();
    unitLbl.paint(c, const Offset(6, 6));
    if (mark != null) {
      c.drawLine(Offset(0, mark!), Offset(s.width, mark!), Paint()
        ..color = SD.red
        ..strokeWidth = 2.5);
    }
  }

  @override
  bool shouldRepaint(_RulerPainter o) => o.unit != unit || o.mark != mark || o.inch != inch;
}
