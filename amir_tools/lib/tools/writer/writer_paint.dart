import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../core/theme.dart';
import 'writer_data.dart';

/// خريطة العلاقات: الشخصيات على دائرة وخطوط ملوّنة بنوع العلاقة
class RelationMap extends StatelessWidget {
  final List<Map<String, dynamic>> chars;
  const RelationMap(this.chars, {super.key});

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return LayoutBuilder(builder: (context, c) {
      final w = c.maxWidth;
      return SizedBox(
        width: w,
        height: math.min(w, 340),
        child: CustomPaint(painter: _RelPainter(chars, dark, Directionality.of(context))),
      );
    });
  }
}

class _RelPainter extends CustomPainter {
  final List<Map<String, dynamic>> chars;
  final bool dark;
  final TextDirection dir;
  _RelPainter(this.chars, this.dark, this.dir);

  TextPainter _tp(String s, double size, Color c, double maxW, {FontWeight w = FontWeight.w700}) {
    final tp = TextPainter(
      text: TextSpan(text: s, style: TextStyle(fontSize: size, color: c, fontWeight: w)),
      textDirection: dir,
      maxLines: 1,
      ellipsis: '…',
      textAlign: TextAlign.center,
    )..layout(maxWidth: maxW);
    return tp;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final n = chars.length;
    if (n == 0) return;
    final center = Offset(size.width / 2, size.height / 2);
    final r = math.min(size.width, size.height) / 2 - 34;
    final pos = <String, Offset>{};
    for (var i = 0; i < n; i++) {
      final a = -math.pi / 2 + 2 * math.pi * i / n;
      pos['${chars[i]['id']}'] = n == 1 ? center : center + Offset(math.cos(a), math.sin(a)) * r;
    }
    final fg = dark ? SD.cream : SD.brownDeep;
    // الخطوط
    final drawn = <String>{};
    for (final c in chars) {
      for (final rel in mapList(c['rels'])) {
        final a = pos['${c['id']}'], b = pos['${rel['to']}'];
        if (a == null || b == null || a == b) continue;
        final key = ([c['id'], rel['to']]..sort((x, y) => '$x'.compareTo('$y'))).join('|');
        final type = wFind(wRelTypes, rel['type']);
        final offset = drawn.contains(key) ? 6.0 : 0.0;
        drawn.add(key);
        final d = b - a;
        final nrm = Offset(-d.dy, d.dx) / (d.distance == 0 ? 1 : d.distance) * offset;
        final p = Paint()
          ..color = type.color.withValues(alpha: .85)
          ..strokeWidth = 2.4
          ..style = PaintingStyle.stroke;
        canvas.drawLine(a + nrm, b + nrm, p);
        final mid = (a + b) / 2 + nrm * 2;
        final tp = _tp(type.emoji, 13, fg, 40);
        canvas.drawCircle(mid, 11, Paint()..color = dark ? SD.brownDeep : SD.cream);
        canvas.drawCircle(mid, 11, Paint()..color = type.color..style = PaintingStyle.stroke..strokeWidth = 1.5);
        tp.paint(canvas, mid - Offset(tp.width / 2, tp.height / 2));
      }
    }
    // العُقد
    for (var i = 0; i < n; i++) {
      final c = chars[i];
      final o = pos['${c['id']}']!;
      final col = wFind(wRoles, c['role']).color;
      canvas.drawCircle(o, 18, Paint()..color = col);
      canvas.drawCircle(o, 18, Paint()..color = SD.goldLight..style = PaintingStyle.stroke..strokeWidth = 2);
      final name = '${c['name'] ?? ''}'.trim();
      final ini = _tp(name.isEmpty ? '?' : name.characters.first, 15, Colors.white, 30, w: FontWeight.w800);
      ini.paint(canvas, o - Offset(ini.width / 2, ini.height / 2));
      final lbl = _tp(name, 11.5, fg, 86);
      var lp = o + Offset(-lbl.width / 2, 21);
      lp = Offset(lp.dx.clamp(0, size.width - lbl.width), lp.dy.clamp(0, size.height - lbl.height));
      lbl.paint(canvas, lp);
    }
  }

  @override
  bool shouldRepaint(covariant _RelPainter old) => true;
}

/// منحنى القصة: المشاهد بالترتيب على قوس تصاعدي، ملوّنة بالحالة، مع فواصل الفصول
class StoryArc extends StatelessWidget {
  final List<Map<String, dynamic>> chapters;
  const StoryArc(this.chapters, {super.key});

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return SizedBox(
      height: 170,
      width: double.infinity,
      child: CustomPaint(painter: _ArcPainter(chapters, dark, Directionality.of(context))),
    );
  }
}

class _ArcPainter extends CustomPainter {
  final List<Map<String, dynamic>> chapters;
  final bool dark;
  final TextDirection dir;
  _ArcPainter(this.chapters, this.dark, this.dir);

  /// شكل التوتر الدرامي: صعود حتى ~80% ثم هبوط
  double _tension(double x) => x < .8 ? .12 + .83 * math.pow(x / .8, 1.4) : .95 - (x - .8) / .2 * .55;

  @override
  void paint(Canvas canvas, Size size) {
    final rtl = dir == TextDirection.rtl;
    const top = 10.0, bottom = 26.0, side = 12.0;
    final h = size.height - top - bottom, w = size.width - side * 2;
    double xAt(double f) => rtl ? side + w * (1 - f) : side + w * f;
    double yAt(double f) => top + h * (1 - _tension(f));
    final fg = dark ? SD.cream : SD.brownDeep;

    // خط الأساس
    canvas.drawLine(Offset(side, top + h), Offset(side + w, top + h), Paint()..color = fg.withValues(alpha: .25)..strokeWidth = 1);
    // المنحنى
    final path = Path();
    for (var i = 0; i <= 60; i++) {
      final f = i / 60;
      final o = Offset(xAt(f), yAt(f));
      i == 0 ? path.moveTo(o.dx, o.dy) : path.lineTo(o.dx, o.dy);
    }
    canvas.drawPath(path, Paint()..color = SD.gold.withValues(alpha: .6)..strokeWidth = 2.5..style = PaintingStyle.stroke);

    final scenes = <(Map<String, dynamic>, int)>[];
    for (var c = 0; c < chapters.length; c++) {
      for (final s in mapList(chapters[c]['scenes'])) {
        scenes.add((s, c));
      }
    }
    final n = scenes.length;
    if (n == 0) return;
    double fOf(int i) => n == 1 ? .5 : .03 + .94 * i / (n - 1);
    // فواصل الفصول
    var prev = -1;
    for (var i = 0; i < n; i++) {
      final c = scenes[i].$2;
      if (c != prev) {
        final x = xAt(fOf(i)) + (i == 0 ? 0 : (rtl ? 1 : -1) * (w * .47 / math.max(1, n - 1)));
        if (i > 0) {
          final dash = Paint()..color = fg.withValues(alpha: .3)..strokeWidth = 1;
          for (var y = top; y < top + h; y += 6) {
            canvas.drawLine(Offset(x, y), Offset(x, y + 3), dash);
          }
        }
        final tp = TextPainter(
          text: TextSpan(text: '${c + 1}', style: TextStyle(color: fg.withValues(alpha: .75), fontSize: 11, fontWeight: FontWeight.w800)),
          textDirection: dir,
        )..layout();
        tp.paint(canvas, Offset(xAt(fOf(i)) - tp.width / 2, top + h + 6));
        prev = c;
      }
    }
    // نقاط المشاهد
    for (var i = 0; i < n; i++) {
      final f = fOf(i);
      final o = Offset(xAt(f), yAt(f));
      final col = wFind(wSceneStatus, scenes[i].$1['status']).color;
      final rad = n > 40 ? 3.5 : 6.0;
      canvas.drawCircle(o, rad + 1.6, Paint()..color = dark ? SD.brownDeep : Colors.white);
      canvas.drawCircle(o, rad, Paint()..color = col);
    }
  }

  @override
  bool shouldRepaint(covariant _ArcPainter old) => true;
}

/// أعمدة الكلمات لآخر 7 أيام
class WeekBars extends StatelessWidget {
  final List<(String, int)> data;
  final int goal;
  const WeekBars(this.data, this.goal, {super.key});

  @override
  Widget build(BuildContext context) {
    final mx = math.max(goal, data.fold<int>(1, (a, b) => math.max(a, b.$2))).toDouble();
    return SizedBox(
      height: 150,
      child: Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
        for (final d in data)
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 3),
              child: Column(mainAxisAlignment: MainAxisAlignment.end, children: [
                FittedBox(fit: BoxFit.scaleDown, child: Text('${d.$2}', maxLines: 1, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700))),
                const SizedBox(height: 3),
                Container(
                  height: math.max(3, 96 * d.$2 / mx),
                  decoration: BoxDecoration(
                    color: goal > 0 && d.$2 >= goal ? SD.green : SD.purple,
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
                const SizedBox(height: 4),
                FittedBox(fit: BoxFit.scaleDown, child: Text(d.$1, maxLines: 1, style: const TextStyle(fontSize: 11))),
              ]),
            ),
          ),
      ]),
    );
  }
}
