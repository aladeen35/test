import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/format.dart';
import '../../core/state.dart';
import '../../core/theme.dart';
import '../../core/widgets.dart';

/// حاسبة الصحة: كتلة الجسم، الوزن المثالي، السعرات، الماء، نبض التمارين
class HealthTool extends StatefulWidget {
  const HealthTool({super.key});
  @override
  State<HealthTool> createState() => _HealthToolState();
}

class _HealthToolState extends State<HealthTool> {
  late final AppState _s = context.read<AppState>();
  late final _w = TextEditingController(text: '${_s.getData<num>('health_w') ?? 70}');
  late final _h = TextEditingController(text: '${_s.getData<num>('health_h') ?? 170}');
  late final _a = TextEditingController(text: '${_s.getData<num>('health_a') ?? 30}');
  final _waist = TextEditingController();
  late bool _male = _s.getData<bool>('health_male') ?? true;
  double _act = 1.375;

  static final _acts = <double, String>{1.2: 'قاعد ساي (شغل مكتب)', 1.375: 'حركة خفيفة', 1.55: 'رياضة 3–5 مرات', 1.725: 'رياضة كل يوم', 1.9: 'شغل بدني شاق'};

  @override
  void dispose() {
    for (final c in [_w, _h, _a, _waist]) {
      c.dispose();
    }
    super.dispose();
  }

  void _persist() {
    _s.setData('health_w', parseNum(_w.text));
    _s.setData('health_h', parseNum(_h.text));
    _s.setData('health_a', parseNum(_a.text));
    _s.setData('health_male', _male);
  }

  @override
  Widget build(BuildContext context) {
    final w = parseNum(_w.text), h = parseNum(_h.text), age = parseNum(_a.text), waist = parseNum(_waist.text);
    final ok = w > 20 && h > 80 && age > 0;
    final m = h / 100;
    final bmi = ok ? w / (m * m) : 0.0;
    final (cat, catColor) = bmi < 18.5
        ? ('نحافة', SD.nileLight)
        : bmi < 25
            ? ('وزن طبيعي ✅', SD.green)
            : bmi < 30
                ? ('زيادة وزن', SD.gold)
                : bmi < 35
                    ? ('سمنة درجة أولى', SD.orange)
                    : ('سمنة متقدمة', SD.red);
    final bmr = 10 * w + 6.25 * h - 5 * age + (_male ? 5 : -161);
    final tdee = bmr * _act;
    final inches = h / 2.54;
    final devine = (_male ? 50 : 45.5) + 2.3 * (inches - 60);
    final bsa = math.sqrt(h * w / 3600);
    final maxHr = 220 - age;
    final water = w * 0.035 + .5; // زيادة لحر السودان

    return ToolList(children: [
      SCard(
        title: 'بياناتك',
        icon: Icons.person_rounded,
        color: SD.red,
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          SegmentedButton<bool>(
            segments: const [ButtonSegment(value: true, label: Text('راجل')), ButtonSegment(value: false, label: Text('مرة'))],
            selected: {_male},
            onSelectionChanged: (v) => setState(() {
              _male = v.first;
              _persist();
            }),
          ),
          const SizedBox(height: 10),
          Row(children: [
            Expanded(child: NumField('الوزن', _w, suffix: 'كجم', onChanged: (_) => setState(_persist))),
            const SizedBox(width: 8),
            Expanded(child: NumField('الطول', _h, suffix: 'سم', onChanged: (_) => setState(_persist))),
            const SizedBox(width: 8),
            Expanded(child: NumField('العمر', _a, suffix: 'سنة', decimal: false, onChanged: (_) => setState(_persist))),
          ]),
          NumField('محيط الوسط (اختياري)', _waist, suffix: 'سم', onChanged: (_) => setState(() {})),
          DropdownButtonFormField<double>(
            initialValue: _act,
            isExpanded: true,
            decoration: const InputDecoration(labelText: 'نشاطك اليومي'),
            items: [for (final e in _acts.entries) DropdownMenuItem(value: e.key, child: Text(e.value))],
            onChanged: (v) => setState(() => _act = v!),
          ),
        ]),
      ),
      if (ok) ...[
        ResultHero(label: 'مؤشر كتلة الجسم (BMI)', value: fmt(bmi, 1), sub: cat),
        SCard(
          title: 'وين إنت في المقياس؟',
          icon: Icons.speed_rounded,
          color: catColor,
          child: Column(children: [
            LayoutBuilder(builder: (context, c) {
              final pos = ((bmi - 15) / (40 - 15)).clamp(0.0, 1.0) * c.maxWidth;
              return SizedBox(
                height: 34,
                child: Stack(children: [
                  Positioned.fill(
                    top: 10,
                    bottom: 10,
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        gradient: const LinearGradient(colors: [SD.nileLight, SD.green, SD.gold, SD.orange, SD.red]),
                      ),
                    ),
                  ),
                  PositionedDirectional(start: pos - 8, top: 0, child: const Icon(Icons.arrow_drop_down_rounded, size: 34)),
                ]),
              );
            }),
            const Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('15'), Text('18.5'), Text('25'), Text('30'), Text('40')]),
          ]),
        ),
        SCard(
          title: 'الوزن',
          icon: Icons.monitor_weight_rounded,
          color: SD.green,
          child: Column(children: [
            InfoRow('الوزن الصحي لطولك', '${fmt(18.5 * m * m, 0)} – ${fmt(24.9 * m * m, 0)} كجم'),
            InfoRow('الوزن المثالي (معادلة ديفاين)', '${fmt(devine, 1)} كجم'),
            InfoRow(bmi > 25 ? 'محتاج تنزّل عشان توصل الطبيعي' : bmi < 18.5 ? 'محتاج تزيد' : 'وزنك', bmi > 25
                ? '${fmt(w - 24.9 * m * m, 1)} كجم'
                : bmi < 18.5
                    ? '${fmt(18.5 * m * m - w, 1)} كجم'
                    : 'تمام في الطبيعي 👌'),
            InfoRow('مساحة سطح الجسم', '${fmt(bsa, 2)} م²', hint: 'معادلة Mosteller'),
            if (waist > 0) InfoRow('نسبة الوسط للطول', fmt(waist / h, 2), hint: 'أقل من 0.5 = كويس', valueColor: waist / h < .5 ? SD.green : SD.red),
          ]),
        ),
        SCard(
          title: 'السعرات الحرارية في اليوم',
          icon: Icons.local_fire_department_rounded,
          color: SD.orange,
          child: Column(children: [
            InfoRow('معدّل الحرق وإنت قاعد (BMR)', '${fmt(bmr, 0)} سعرة', hint: 'معادلة Mifflin-St Jeor'),
            InfoRow('عشان تحافظ على وزنك', '${fmt(tdee, 0)} سعرة'),
            InfoRow('عشان تنزّل نص كيلو في الأسبوع', '${fmt(tdee - 500, 0)} سعرة'),
            InfoRow('عشان تزيد نص كيلو في الأسبوع', '${fmt(tdee + 500, 0)} سعرة'),
            InfoRow('بروتين (30%)', '${fmt(tdee * .3 / 4, 0)} جم'),
            InfoRow('نشويات (40%)', '${fmt(tdee * .4 / 4, 0)} جم'),
            InfoRow('دهون (30%)', '${fmt(tdee * .3 / 9, 0)} جم'),
          ]),
        ),
        SCard(
          title: 'الموية والنبض',
          icon: Icons.favorite_rounded,
          color: SD.nileLight,
          child: Column(children: [
            InfoRow('الموية المقترحة يوميًا', '${fmt(water, 1)} لتر', hint: 'في حرّ السودان زِيد أكتر'),
            InfoRow('أقصى نبض تقريبي', '${fmt(maxHr, 0)} نبضة/د'),
            InfoRow('حرق دهون (60–70%)', '${fmt(maxHr * .6, 0)} – ${fmt(maxHr * .7, 0)}'),
            InfoRow('لياقة قلب (70–80%)', '${fmt(maxHr * .7, 0)} – ${fmt(maxHr * .8, 0)}'),
            InfoRow('مجهود عالي (80–90%)', '${fmt(maxHr * .8, 0)} – ${fmt(maxHr * .9, 0)}'),
          ]),
        ),
        ShareBar(() => 'BMI: ${fmt(bmi, 1)} ($cat)\nالسعرات للمحافظة: ${fmt(tdee, 0)}\nالوزن الصحي: ${fmt(18.5 * m * m, 0)}–${fmt(24.9 * m * m, 0)} كجم'),
      ],
      const NoteBox('أرقام إرشادية عامة بس، وما بتغني عن الدكتور — خصوصًا لو عندك سكري أو ضغط أو حامل.', kind: NoteKind.warn),
    ]);
  }
}
