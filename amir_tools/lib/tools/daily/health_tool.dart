import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/format.dart';
import '../../core/i18n.dart';
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

  static Map<double, String> get _acts => {
        1.2: t('قاعد ساي (شغل مكتب)', 'خامل (عمل مكتبي)', 'Sedentary (desk job)'),
        1.375: tr('حركة خفيفة', 'Lightly active'),
        1.55: t('رياضة 3–5 مرات', 'رياضة 3–5 مرات أسبوعيًا', 'Exercise 3–5 times a week'),
        1.725: t('رياضة كل يوم', 'رياضة يومية', 'Exercise every day'),
        1.9: t('شغل بدني شاق', 'عمل بدني شاق', 'Hard physical work'),
      };

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
        ? (tr('نحافة', 'Underweight'), SD.nileLight)
        : bmi < 25
            ? (tr('وزن طبيعي ✅', 'Normal weight ✅'), SD.green)
            : bmi < 30
                ? (tr('زيادة وزن', 'Overweight'), SD.gold)
                : bmi < 35
                    ? (tr('سمنة درجة أولى', 'Obesity class I'), SD.orange)
                    : (tr('سمنة متقدمة', 'Severe obesity'), SD.red);
    final bmr = 10 * w + 6.25 * h - 5 * age + (_male ? 5 : -161);
    final tdee = bmr * _act;
    final inches = h / 2.54;
    final devine = (_male ? 50 : 45.5) + 2.3 * (inches - 60);
    final bsa = math.sqrt(h * w / 3600);
    final maxHr = 220 - age;
    final water = w * 0.035 + .5; // زيادة للجو الحار

    return ToolList(children: [
      SCard(
        title: tr('بياناتك', 'Your details'),
        icon: Icons.person_rounded,
        color: SD.red,
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          SegmentedButton<bool>(
            segments: [
              ButtonSegment(value: true, label: Text(t('راجل', 'ذكر', 'Male'))),
              ButtonSegment(value: false, label: Text(t('مرة', 'أنثى', 'Female'))),
            ],
            selected: {_male},
            onSelectionChanged: (v) => setState(() {
              _male = v.first;
              _persist();
            }),
          ),
          const SizedBox(height: 10),
          Row(children: [
            Expanded(child: NumField(tr('الوزن', 'Weight'), _w, suffix: tr('كجم', 'kg'), onChanged: (_) => setState(_persist))),
            const SizedBox(width: 8),
            Expanded(child: NumField(tr('الطول', 'Height'), _h, suffix: tr('سم', 'cm'), onChanged: (_) => setState(_persist))),
            const SizedBox(width: 8),
            Expanded(child: NumField(tr('العمر', 'Age'), _a, suffix: tr('سنة', 'yrs'), decimal: false, onChanged: (_) => setState(_persist))),
          ]),
          NumField(tr('محيط الوسط (اختياري)', 'Waist (optional)'), _waist, suffix: tr('سم', 'cm'), onChanged: (_) => setState(() {})),
          DropdownButtonFormField<double>(
            initialValue: _act,
            isExpanded: true,
            decoration: InputDecoration(labelText: tr('نشاطك اليومي', 'Daily activity')),
            items: [for (final e in _acts.entries) DropdownMenuItem(value: e.key, child: Text(e.value))],
            onChanged: (v) => setState(() => _act = v!),
          ),
        ]),
      ),
      if (ok) ...[
        ResultHero(label: tr('مؤشر كتلة الجسم (BMI)', 'Body mass index (BMI)'), value: fmt(bmi, 1), sub: cat),
        SCard(
          title: t('وين إنت في المقياس؟', 'أين أنت على المقياس؟', 'Where are you on the scale?'),
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
                        gradient: const LinearGradient(
                            begin: AlignmentDirectional.centerStart, end: AlignmentDirectional.centerEnd, colors: [SD.nileLight, SD.green, SD.gold, SD.orange, SD.red]),
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
          title: tr('الوزن', 'Weight'),
          icon: Icons.monitor_weight_rounded,
          color: SD.green,
          child: Column(children: [
            InfoRow(tr('الوزن الصحي لطولك', 'Healthy weight for your height'), '${fmt(18.5 * m * m, 0)} – ${fmt(24.9 * m * m, 0)} ${tr('كجم', 'kg')}'),
            InfoRow(tr('الوزن المثالي (معادلة ديفاين)', 'Ideal weight (Devine formula)'), '${fmt(devine, 1)} ${tr('كجم', 'kg')}'),
            InfoRow(
                bmi > 25
                    ? t('محتاج تنزّل عشان توصل الطبيعي', 'تحتاج إلى خسارة للوصول للطبيعي', 'To lose to reach normal')
                    : bmi < 18.5
                        ? t('محتاج تزيد', 'تحتاج إلى زيادة', 'To gain')
                        : tr('وزنك', 'Your weight'),
                bmi > 25
                    ? '${fmt(w - 24.9 * m * m, 1)} ${tr('كجم', 'kg')}'
                    : bmi < 18.5
                        ? '${fmt(18.5 * m * m - w, 1)} ${tr('كجم', 'kg')}'
                        : t('تمام في الطبيعي 👌', 'ضمن الطبيعي 👌', 'In the normal range 👌')),
            InfoRow(tr('مساحة سطح الجسم', 'Body surface area'), '${fmt(bsa, 2)} ${tr('م²', 'm²')}', hint: tr('معادلة Mosteller', 'Mosteller formula')),
            if (waist > 0)
              InfoRow(tr('نسبة الوسط للطول', 'Waist-to-height ratio'), fmt(waist / h, 2),
                  hint: t('أقل من 0.5 = كويس', 'أقل من 0.5 = جيد', 'Below 0.5 = good'), valueColor: waist / h < .5 ? SD.green : SD.red),
          ]),
        ),
        SCard(
          title: tr('السعرات الحرارية في اليوم', 'Daily calories'),
          icon: Icons.local_fire_department_rounded,
          color: SD.orange,
          child: Column(children: [
            InfoRow(t('معدّل الحرق وإنت قاعد (BMR)', 'معدّل الأيض الأساسي (BMR)', 'Resting burn (BMR)'), '${fmt(bmr, 0)} ${tr('سعرة', 'kcal')}', hint: tr('معادلة Mifflin-St Jeor', 'Mifflin-St Jeor formula')),
            InfoRow(t('عشان تحافظ على وزنك', 'للمحافظة على وزنك', 'To maintain your weight'), '${fmt(tdee, 0)} ${tr('سعرة', 'kcal')}'),
            InfoRow(t('عشان تنزّل نص كيلو في الأسبوع', 'لخسارة نصف كيلو أسبوعيًا', 'To lose 0.5 kg a week'), '${fmt(tdee - 500, 0)} ${tr('سعرة', 'kcal')}'),
            InfoRow(t('عشان تزيد نص كيلو في الأسبوع', 'لزيادة نصف كيلو أسبوعيًا', 'To gain 0.5 kg a week'), '${fmt(tdee + 500, 0)} ${tr('سعرة', 'kcal')}'),
            InfoRow(tr('بروتين (30%)', 'Protein (30%)'), '${fmt(tdee * .3 / 4, 0)} ${tr('جم', 'g')}'),
            InfoRow(tr('نشويات (40%)', 'Carbs (40%)'), '${fmt(tdee * .4 / 4, 0)} ${tr('جم', 'g')}'),
            InfoRow(tr('دهون (30%)', 'Fat (30%)'), '${fmt(tdee * .3 / 9, 0)} ${tr('جم', 'g')}'),
          ]),
        ),
        SCard(
          title: t('الموية والنبض', 'الماء والنبض', 'Water & heart rate'),
          icon: Icons.favorite_rounded,
          color: SD.nileLight,
          child: Column(children: [
            InfoRow(t('الموية المقترحة يوميًا', 'الماء المقترح يوميًا', 'Suggested daily water'), '${fmt(water, 1)} ${tr('لتر', 'L')}',
                hint: t('في الحر زِيد أكتر', 'في الجو الحار زِد أكثر', 'Drink more in hot weather')),
            InfoRow(tr('أقصى نبض تقريبي', 'Approx. max heart rate'), '${fmt(maxHr, 0)} ${tr('نبضة/د', 'bpm')}'),
            InfoRow(tr('حرق دهون (60–70%)', 'Fat burn (60–70%)'), '${fmt(maxHr * .6, 0)} – ${fmt(maxHr * .7, 0)}'),
            InfoRow(tr('لياقة قلب (70–80%)', 'Cardio (70–80%)'), '${fmt(maxHr * .7, 0)} – ${fmt(maxHr * .8, 0)}'),
            InfoRow(tr('مجهود عالي (80–90%)', 'High intensity (80–90%)'), '${fmt(maxHr * .8, 0)} – ${fmt(maxHr * .9, 0)}'),
          ]),
        ),
        ShareBar(() => tr('BMI: ${fmt(bmi, 1)} ($cat)\nالسعرات للمحافظة: ${fmt(tdee, 0)}\nالوزن الصحي: ${fmt(18.5 * m * m, 0)}–${fmt(24.9 * m * m, 0)} كجم',
            'BMI: ${fmt(bmi, 1)} ($cat)\nMaintenance calories: ${fmt(tdee, 0)}\nHealthy weight: ${fmt(18.5 * m * m, 0)}–${fmt(24.9 * m * m, 0)} kg')),
      ],
      NoteBox(
          t('أرقام إرشادية عامة بس، وما بتغني عن الدكتور — خصوصًا لو عندك سكري أو ضغط أو حامل.', 'أرقام إرشادية عامة فقط، ولا تغني عن الطبيب — خصوصًا مع السكري أو الضغط أو الحمل.',
              "General guidance only — not a substitute for a doctor, especially if you have diabetes, high blood pressure or are pregnant."),
          kind: NoteKind.warn),
    ]);
  }
}
