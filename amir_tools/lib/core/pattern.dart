import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'theme.dart';

/// خلفية تراثية: تدرّج بني دافئ، شبكة سداسيات بخط ذهبي خافت، وشريط بألوان العلم أعلى وأسفل الشاشة.
class SudanBackground extends StatelessWidget {
  final Widget child;
  const SudanBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: RadialGradient(
          center: const Alignment(0, -.6),
          radius: 1.3,
          colors: dark
              ? const [Color(0xFF7A4A24), Color(0xFF5A3418), Color(0xFF3A1F0C)]
              : const [Color(0xFFFFF7E8), Color(0xFFF6E3C0), Color(0xFFE9CC98)],
        ),
      ),
      child: CustomPaint(
        painter: HexPatternPainter(dark: dark),
        foregroundPainter: const FlagEdgesPainter(),
        child: child,
      ),
    );
  }
}

/// شبكة سداسيات مع معيّن صغير في وسط كل خلية (زخرفة الخلفية)
class HexPatternPainter extends CustomPainter {
  final bool dark;
  const HexPatternPainter({required this.dark});

  @override
  void paint(Canvas canvas, Size size) {
    final line = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.1
      ..color = (dark ? SD.goldLight : SD.brown).withValues(alpha: dark ? .07 : .08);
    final dot = Paint()..color = (dark ? SD.goldLight : SD.brown).withValues(alpha: dark ? .06 : .07);
    const r = 34.0;
    final w = math.sqrt(3) * r;
    const h = 1.5 * r;
    var row = 0;
    for (double y = 0; y < size.height + r; y += h, row++) {
      for (double x = (row.isOdd ? w / 2 : 0); x < size.width + w; x += w) {
        final path = Path();
        for (var i = 0; i < 6; i++) {
          final a = math.pi / 6 + i * math.pi / 3;
          final p = Offset(x + r * math.cos(a), y + r * math.sin(a));
          i == 0 ? path.moveTo(p.dx, p.dy) : path.lineTo(p.dx, p.dy);
        }
        path.close();
        canvas.drawPath(path, line);
        final d = Path()
          ..moveTo(x, y - 7)
          ..lineTo(x + 7, y)
          ..lineTo(x, y + 7)
          ..lineTo(x - 7, y)
          ..close();
        canvas.drawPath(d, dot);
      }
    }
  }

  @override
  bool shouldRepaint(HexPatternPainter old) => old.dark != dark;
}

/// شريطان رفيعان بألوان العلم في أعلى وأسفل الشاشة
class FlagEdgesPainter extends CustomPainter {
  const FlagEdgesPainter();
  @override
  void paint(Canvas c, Size s) {
    const cols = [SD.green, SD.black, Colors.white, SD.red];
    final seg = s.width / 4;
    for (var i = 0; i < 4; i++) {
      c.drawRect(Rect.fromLTWH(i * seg, 0, seg, 5), Paint()..color = cols[i]);
      c.drawRect(Rect.fromLTWH(i * seg, s.height - 5, seg, 5), Paint()..color = cols[3 - i]);
    }
  }

  @override
  bool shouldRepaint(_) => false;
}

/// شريط صغير بشكل العلم السوداني
class FlagStrip extends StatelessWidget {
  final double width, height;
  const FlagStrip({super.key, this.width = 34, this.height = 22});
  @override
  Widget build(BuildContext context) => ClipRRect(
        borderRadius: BorderRadius.circular(3),
        child: CustomPaint(size: Size(width, height), painter: _FlagPainter()),
      );
}

class _FlagPainter extends CustomPainter {
  @override
  void paint(Canvas c, Size s) {
    final h = s.height / 3;
    c.drawRect(Rect.fromLTWH(0, 0, s.width, h), Paint()..color = SD.red);
    c.drawRect(Rect.fromLTWH(0, h, s.width, h), Paint()..color = Colors.white);
    c.drawRect(Rect.fromLTWH(0, 2 * h, s.width, h), Paint()..color = SD.black);
    final t = Path()..moveTo(0, 0)..lineTo(s.width * .38, s.height / 2)..lineTo(0, s.height)..close();
    c.drawPath(t, Paint()..color = SD.green);
  }

  @override
  bool shouldRepaint(_) => false;
}

/// نص بتدرّج ذهبي مع ظل خفيف (للعناوين)
class GoldText extends StatelessWidget {
  final String text;
  final double size;
  final TextAlign align;
  const GoldText(this.text, {super.key, this.size = 28, this.align = TextAlign.center});

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final style = TextStyle(fontFamily: 'Lalezar', fontSize: size, height: 1.25);
    if (!dark) return Text(text, textAlign: align, style: style.copyWith(color: SD.brown));
    return Stack(children: [
      Text(text, textAlign: align, style: style.copyWith(foreground: Paint()..color = Colors.black.withValues(alpha: .35)..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3))),
      ShaderMask(
        shaderCallback: (r) => const LinearGradient(colors: SD.goldText, begin: Alignment.topCenter, end: Alignment.bottomCenter).createShader(r),
        child: Text(text, textAlign: align, style: style.copyWith(color: Colors.white)),
      ),
    ]);
  }
}

/// فاصل زخرفي: خطّان ذهبيان ومعيّن في الوسط
class GoldDivider extends StatelessWidget {
  const GoldDivider({super.key});
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Container(width: 70, height: 1.5, decoration: BoxDecoration(gradient: LinearGradient(colors: [SD.gold.withValues(alpha: 0), SD.gold]))),
          const SizedBox(width: 8),
          Transform.rotate(angle: math.pi / 4, child: Container(width: 10, height: 10, color: SD.goldLight)),
          const SizedBox(width: 8),
          Container(width: 70, height: 1.5, decoration: BoxDecoration(gradient: LinearGradient(colors: [SD.gold, SD.gold.withValues(alpha: 0)]))),
        ]),
      );
}

/// إطار ذهبي بحدّ داخلي متقطّع (مثل لوحة «اختر لعبتك»)
class GoldFrame extends StatelessWidget {
  final Widget child;
  final EdgeInsets padding;
  final String? title;
  const GoldFrame({super.key, required this.child, this.padding = const EdgeInsets.all(14), this.title});

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: dark ? const [Color(0xFF6E4222), Color(0xFF52301A)] : const [Color(0xFFFFF8EC), Color(0xFFF5E2BE)],
        ),
        border: Border.all(color: SD.gold.withValues(alpha: .9), width: 2),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: dark ? .35 : .12), blurRadius: 18, offset: const Offset(0, 8))],
      ),
      child: CustomPaint(
        painter: _DashedBorderPainter(color: SD.goldLight.withValues(alpha: dark ? .45 : .8)),
        child: Padding(
          padding: padding,
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            if (title != null) ...[
              Center(child: GoldText(title!, size: 22)),
              const SizedBox(height: 10),
            ],
            child,
          ]),
        ),
      ),
    );
  }
}

class _DashedBorderPainter extends CustomPainter {
  final Color color;
  _DashedBorderPainter({required this.color});
  @override
  void paint(Canvas c, Size s) {
    final rr = RRect.fromRectAndRadius(Rect.fromLTWH(6, 6, s.width - 12, s.height - 12), const Radius.circular(22));
    final path = Path()..addRRect(rr);
    final p = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.3
      ..color = color;
    for (final m in path.computeMetrics()) {
      for (double d = 0; d < m.length; d += 9) {
        c.drawPath(m.extractPath(d, math.min(d + 5, m.length)), p);
      }
    }
  }

  @override
  bool shouldRepaint(_DashedBorderPainter o) => o.color != color;
}

/// زخرفة زاوية للبطاقات
class CornerOrnament extends StatelessWidget {
  final Color color;
  const CornerOrnament({super.key, required this.color});
  @override
  Widget build(BuildContext context) => IgnorePointer(child: CustomPaint(size: const Size(80, 80), painter: _CornerPainter(color)));
}

class _CornerPainter extends CustomPainter {
  final Color color;
  _CornerPainter(this.color);
  @override
  void paint(Canvas c, Size s) {
    final p = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4
      ..color = color.withValues(alpha: .2);
    for (int i = 1; i <= 3; i++) {
      c.drawCircle(Offset(s.width, 0), i * 20.0, p);
    }
  }

  @override
  bool shouldRepaint(_CornerPainter o) => o.color != color;
}

/// شعار «أدوات أمير»: ختم دائري (حلقة ذهبية، خضرة العلم، هلال ونجمة ومفتاح) مع الاسم بالذهبي
class AmirLogo extends StatelessWidget {
  final double size;
  final bool withText;
  const AmirLogo({super.key, this.size = 110, this.withText = true});

  @override
  Widget build(BuildContext context) => Column(mainAxisSize: MainAxisSize.min, children: [
        SizedBox(width: size, height: size, child: CustomPaint(painter: _EmblemPainter())),
        if (withText) ...[
          const SizedBox(height: 4),
          GoldText('أدوات أمير', size: size * .36),
          Text('عِدّتك السودانية في جيبك 🇸🇩',
              style: TextStyle(fontSize: size * .12, fontWeight: FontWeight.w700, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: .8))),
        ],
      ]);
}

class _EmblemPainter extends CustomPainter {
  @override
  void paint(Canvas c, Size s) {
    final ctr = s.center(Offset.zero);
    final r = s.width / 2;
    // ظل
    c.drawCircle(ctr + const Offset(0, 4), r * .98, Paint()..color = Colors.black.withValues(alpha: .35)..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8));
    // حلقة ذهبية
    c.drawCircle(ctr, r, Paint()..shader = const SweepGradient(colors: [SD.goldLight, SD.goldDeep, SD.goldLight, SD.goldDeep, SD.goldLight]).createShader(Rect.fromCircle(center: ctr, radius: r)));
    // حلقة بألوان العلم
    final ring = Rect.fromCircle(center: ctr, radius: r * .86);
    const cols = [SD.red, Colors.white, SD.black, SD.green];
    for (var i = 0; i < 4; i++) {
      c.drawArc(ring, -math.pi / 2 + i * math.pi / 2, math.pi / 2, true, Paint()..color = cols[i]);
    }
    // القرص الداخلي البني
    c.drawCircle(ctr, r * .74, Paint()..shader = RadialGradient(colors: const [SD.brownLight, SD.brown, SD.brownDeep]).createShader(Rect.fromCircle(center: ctr, radius: r * .74)));
    c.drawCircle(ctr, r * .74, Paint()..style = PaintingStyle.stroke..strokeWidth = 2..color = SD.goldLight);
    // مفتاح ربط ذهبي مائل
    final g = Paint()
      ..color = SD.goldLight
      ..strokeWidth = r * .14
      ..strokeCap = StrokeCap.round;
    c.save();
    c.translate(ctr.dx, ctr.dy);
    c.rotate(-math.pi / 4);
    c.drawLine(Offset(0, -r * .38), Offset(0, r * .36), g);
    final head = Path()
      ..addOval(Rect.fromCircle(center: Offset(0, -r * .42), radius: r * .17))
      ..addRect(Rect.fromCenter(center: Offset(0, -r * .55), width: r * .13, height: r * .2));
    c.drawPath(head, Paint()..color = SD.goldLight);
    c.drawCircle(Offset(0, -r * .42), r * .07, Paint()..color = SD.brown);
    c.drawRect(Rect.fromCenter(center: Offset(0, -r * .56), width: r * .12, height: r * .18), Paint()..color = SD.brown);
    c.restore();
    // هلال ونجمة
    final mc = ctr + Offset(r * .26, -r * .28);
    c.drawCircle(mc, r * .2, Paint()..color = Colors.white);
    c.drawCircle(mc + Offset(r * .08, -r * .04), r * .17, Paint()..color = SD.brown);
    _star(c, mc + Offset(r * .02, r * .02), r * .07, Paint()..color = SD.gold);
    // نقطة خضراء (لمسة العلم)
    c.drawCircle(ctr + Offset(-r * .3, r * .32), r * .08, Paint()..color = SD.green);
  }

  void _star(Canvas c, Offset o, double r, Paint p) {
    final path = Path();
    for (var i = 0; i < 10; i++) {
      final a = -math.pi / 2 + i * math.pi / 5;
      final rr = i.isEven ? r : r * .45;
      final pt = o + Offset(math.cos(a) * rr, math.sin(a) * rr);
      i == 0 ? path.moveTo(pt.dx, pt.dy) : path.lineTo(pt.dx, pt.dy);
    }
    c.drawPath(path..close(), p);
  }

  @override
  bool shouldRepaint(_) => false;
}
