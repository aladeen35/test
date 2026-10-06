import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/format.dart';
import '../../core/i18n.dart';
import '../../core/state.dart';
import '../../core/theme.dart';
import '../../core/widgets.dart';
import '../life/life_common.dart';
import 'plus_common.dart';

/// سجل السكر والضغط — القيم تُحفظ دائمًا بوحدة mg/dL

const _kEntries = 'vitals_entries';
const _kUnit = 'vitals_unit';
const _mmolFactor = 18.0;

/// سياقات قياس السكر
const _ctxIds = ['fast', 'pre', 'post2', 'rand'];
String ctxLabel(String c) => switch (c) {
      'fast' => t('صايم', 'صائم', 'Fasting'),
      'pre' => t('قبل الأكل', 'قبل الوجبة', 'Before meal'),
      'post2' => t('بعد الأكل بساعتين', 'بعد الوجبة بساعتين', '2h after meal'),
      _ => t('أي وقت', 'عشوائي', 'Random'),
    };

/// نتيجة التصنيف
class VClass {
  final String label;
  final Color color;
  final bool normal;

  /// 0 لا شيء، 1 تنبيه، 2 خطير/عاجل
  final int alert;
  const VClass(this.label, this.color, {this.normal = false, this.alert = 0});
}

VClass classifyGlucose(double mg, String ctx) {
  if (mg < 54) return VClass(t('هبوط شديد', 'انخفاض شديد', 'Severe low'), SD.red, alert: 2);
  if (mg < 70) return VClass(t('هبوط', 'انخفاض', 'Low'), SD.orange, alert: 1);
  if (mg >= 300) return VClass(t('عالي جدًا', 'مرتفع جدًا', 'Very high'), SD.red, alert: 2);
  switch (ctx) {
    case 'fast':
      if (mg < 100) return VClass(t('طبيعي', 'طبيعي', 'Normal'), SD.green, normal: true);
      if (mg < 126) return VClass(t('نطاق ما قبل السكري', 'نطاق ما قبل السكري', 'Prediabetes range'), SD.gold);
      return VClass(t('عالي', 'مرتفع', 'High'), SD.henna);
    case 'pre':
      if (mg < 100) return VClass(t('طبيعي', 'طبيعي', 'Normal'), SD.green, normal: true);
      if (mg < 126) return VClass(t('فوق الطبيعي شوية', 'أعلى من الطبيعي', 'Above normal'), SD.gold);
      return VClass(t('عالي', 'مرتفع', 'High'), SD.henna);
    default: // بعد الأكل بساعتين / عشوائي
      if (mg < 140) return VClass(t('طبيعي', 'طبيعي', 'Normal'), SD.green, normal: true);
      if (mg < 200) return VClass(t('مرتفع شوية', 'مرتفع قليلًا', 'Elevated'), SD.gold);
      return VClass(t('عالي', 'مرتفع', 'High'), SD.henna);
  }
}

/// تصنيف جمعية القلب الأمريكية (AHA)
VClass classifyBp(int sys, int dia) {
  if (sys > 180 || dia > 120) return VClass(t('أزمة ضغط', 'أزمة ارتفاع ضغط', 'Hypertensive crisis'), SD.red, alert: 2);
  if (sys >= 140 || dia >= 90) return VClass(t('ضغط عالي — مرحلة 2', 'ارتفاع ضغط — المرحلة 2', 'High — stage 2'), SD.henna);
  if (sys >= 130 || dia >= 80) return VClass(t('ضغط عالي — مرحلة 1', 'ارتفاع ضغط — المرحلة 1', 'High — stage 1'), SD.orange);
  if (sys >= 120) return VClass(t('مرتفع شوية', 'مرتفع', 'Elevated'), SD.gold);
  if (sys < 90 || dia < 60) return VClass(t('واطي', 'منخفض', 'Low'), SD.nile, alert: 1);
  return VClass(t('طبيعي', 'طبيعي', 'Normal'), SD.green, normal: true);
}

class VitalsTool extends StatefulWidget {
  const VitalsTool({super.key});
  @override
  State<VitalsTool> createState() => _VitalsToolState();
}

class _VitalsToolState extends State<VitalsTool> {
  int mode = 0; // 0 سكر، 1 ضغط
  String ctx = 'fast';
  String chartCtx = 'all';
  int range = 14;
  DateTime? when;
  final gC = TextEditingController(), sC = TextEditingController(), dC = TextEditingController(), pC = TextEditingController(), nC = TextEditingController();

  @override
  void dispose() {
    for (final c in [gC, sC, dC, pC, nC]) {
      c.dispose();
    }
    super.dispose();
  }

  List<Map<String, dynamic>> _all(AppState s) => mapList(s.getData<List>(_kEntries))..sort((a, b) => intOf(a['t']).compareTo(intOf(b['t'])));

  bool _mmol(AppState s) => s.getData<String>(_kUnit) == 'mmol';
  String _unit(AppState s) => _mmol(s) ? 'mmol/L' : 'mg/dL';
  String _gv(AppState s, double mg) => _mmol(s) ? fmt(mg / _mmolFactor, 1) : fmt(mg, 0);

  String _dt(DateTime d) => '${d.year}-${two(d.month)}-${two(d.day)} ${two(d.hour)}:${two(d.minute)}';

  void _save(AppState s) {
    final now = DateTime.now();
    final at = when ?? now;
    final note = nC.text.trim();
    Map<String, dynamic> e;
    VClass c;
    if (mode == 0) {
      final raw = parseNum(gC.text, -1);
      final mg = _mmol(s) ? raw * _mmolFactor : raw;
      if (raw <= 0 || mg < 10 || mg > 1000) {
        toast(t('اكتب قراءة سكر صحيحة', 'أدخل قراءة سكر صحيحة', 'Enter a valid glucose reading'));
        return;
      }
      e = {'id': newId(), 'k': 'g', 't': at.millisecondsSinceEpoch, 'v': double.parse(mg.toStringAsFixed(1)), 'c': ctx, if (note.isNotEmpty) 'n': note};
      c = classifyGlucose(mg, ctx);
    } else {
      final sys = parseNum(sC.text, -1).round(), dia = parseNum(dC.text, -1).round(), pulse = parseNum(pC.text, -1).round();
      if (sys < 50 || sys > 300 || dia < 30 || dia > 200 || dia >= sys) {
        toast(t('اكتب الضغط صاح: الانقباضي (الفوق) أكبر من الانبساطي (التحت)', 'أدخل قراءة صحيحة: الانقباضي أكبر من الانبساطي',
            'Enter a valid reading: systolic must be higher than diastolic'));
        return;
      }
      e = {'id': newId(), 'k': 'bp', 't': at.millisecondsSinceEpoch, 's': sys, 'd': dia, if (pulse >= 20 && pulse <= 250) 'p': pulse, if (note.isNotEmpty) 'n': note};
      c = classifyBp(sys, dia);
    }
    final list = mapList(s.getData<List>(_kEntries))..add(e);
    if (list.length > 1000) list.removeRange(0, list.length - 1000);
    s.setData(_kEntries, list);
    s.bump('vitals_logged');
    s.awardDaily('vitals_log', 5, t('سجّلت قراءة صحية', 'تسجيل قراءة صحية', 'Logged a health reading'));
    for (final x in [gC, sC, dC, pC, nC]) {
      x.clear();
    }
    FocusScope.of(context).unfocus();
    setState(() => when = null);
    if (c.alert == 2) {
      _urgentDialog();
    } else {
      toast('${t('اتسجّلت', 'تم الحفظ', 'Saved')} ✓ — ${c.label}');
    }
  }

  void _urgentDialog() {
    showDialog(
      context: context,
      builder: (c) => AlertDialog(
        icon: const Icon(Icons.emergency_rounded, color: SD.red, size: 36),
        title: Text(t('قراءة خطيرة!', 'قراءة خطيرة!', 'Dangerous reading!')),
        content: Text(_urgentText(mode == 0)),
        actions: [FilledButton(onPressed: () => Navigator.pop(c), child: Text(t('فهمت', 'فهمت', 'Understood')))],
      ),
    );
  }

  String _urgentText(bool glucose) => glucose
      ? t(
          'لو السكر واطي جدًا (أقل من 54) أو عالي جدًا (300 وفوق)، خصوصًا مع دوخة أو عرق أو لخبطة أو ترجيع أو نهجة — اتصل بالطوارئ أو امشي أقرب مستشفى هسي. لو مريض سكري وعندك هبوط: خُد 15 جرام سكر سريع (نص كباية عصير مثلًا) وأعد القياس بعد 15 دقيقة.',
          'إذا كان السكر منخفضًا جدًا (أقل من 54) أو مرتفعًا جدًا (300 فأكثر)، خاصةً مع دوخة أو تعرّق أو تشوّش أو قيء أو ضيق تنفس — اتصل بالطوارئ أو توجّه لأقرب مستشفى فورًا. إن كنت مريض سكري ولديك انخفاض: تناول 15 غرامًا من سكر سريع (نصف كوب عصير مثلًا) وأعد القياس بعد 15 دقيقة.',
          'If glucose is very low (under 54) or very high (300 or more), especially with dizziness, sweating, confusion, vomiting or shortness of breath — call emergency services or go to the nearest hospital now. If you have diabetes and are low: take 15 g of fast sugar (e.g. half a cup of juice) and recheck after 15 minutes.')
      : t(
          'الضغط فوق 180/120 خطير. لو معاه ألم صدر، ضيق نفس، ضعف أو تنميل، صعوبة كلام، أو زغللة — اتصل بالطوارئ هسي. لو ما في أعراض: ارتاح 5 دقايق وقيس تاني، ولو لسه عالي كلّم دكتورك فورًا.',
          'الضغط فوق 180/120 خطير. إذا صاحبه ألم في الصدر أو ضيق تنفس أو ضعف أو تنميل أو صعوبة كلام أو تغيّر في الرؤية — اتصل بالطوارئ فورًا. إن لم توجد أعراض: استرح 5 دقائق وأعد القياس، وإن بقي مرتفعًا فاتصل بطبيبك فورًا.',
          'Blood pressure above 180/120 is dangerous. With chest pain, shortness of breath, weakness or numbness, trouble speaking, or vision changes — call emergency services now. Without symptoms: rest 5 minutes and re-measure; if still high, contact your doctor immediately.');

  void _delete(AppState s, Map<String, dynamic> e) {
    final list = mapList(s.getData<List>(_kEntries));
    final i = list.indexWhere((x) => x['id'] == e['id']);
    if (i < 0) return;
    list.removeAt(i);
    s.setData(_kEntries, list);
    setState(() {});
    undoSnack(t('اتمسحت القراءة', 'حُذفت القراءة', 'Reading deleted'), () {
      final l = mapList(s.getData<List>(_kEntries));
      l.insert(math.min(i, l.length), e);
      s.setData(_kEntries, l);
      if (mounted) setState(() {});
    });
  }

  ({int n, double avg, double mn, double mx, double inRange}) _stats(List<double> v, int normals) => v.isEmpty
      ? (n: 0, avg: 0, mn: 0, mx: 0, inRange: 0)
      : (n: v.length, avg: v.reduce((a, b) => a + b) / v.length, mn: v.reduce(math.min), mx: v.reduce(math.max), inRange: normals * 100 / v.length);

  String _report(AppState s) {
    final all = _all(s);
    final g = all.where((e) => e['k'] == 'g').toList();
    final bp = all.where((e) => e['k'] == 'bp').toList();
    final gs = g.length > range ? g.sublist(g.length - range) : g;
    final bs = bp.length > range ? bp.sublist(bp.length - range) : bp;
    final b = StringBuffer();
    b.writeln(t('📋 تقرير السكر والضغط — للدكتور', '📋 تقرير قياسات السكر والضغط — للطبيب', '📋 Glucose & blood pressure report — for the doctor'));
    b.writeln('${t('اتعمل يوم', 'تاريخ الإعداد', 'Prepared')}: ${_dt(DateTime.now())}');
    b.writeln('${t('آخر', 'آخر', 'Last')} $range ${t('قراءة من كل نوع', 'قراءة من كل نوع', 'readings of each type')}');
    b.writeln('');
    if (gs.isNotEmpty) {
      final vals = [for (final e in gs) numOf(e['v'])];
      final st = _stats(vals, gs.where((e) => classifyGlucose(numOf(e['v']), '${e['c']}').normal).length);
      b.writeln('━━ ${t('السكر', 'سكر الدم', 'Blood glucose')} (${_unit(s)}) ━━');
      b.writeln('${t('العدد', 'العدد', 'Count')}: ${st.n} | ${t('المتوسط', 'المتوسط', 'Avg')}: ${_gv(s, st.avg)} | ${t('الأقل', 'الأدنى', 'Min')}: ${_gv(s, st.mn)} | ${t('الأعلى', 'الأعلى', 'Max')}: ${_gv(s, st.mx)}');
      b.writeln('${t('في المعدل الطبيعي', 'ضمن الطبيعي', 'In normal range')}: ${fmt(st.inRange, 0)}%');
      for (final c in _ctxIds) {
        final cv = [for (final e in gs) if (e['c'] == c) numOf(e['v'])];
        if (cv.isNotEmpty) b.writeln('• ${ctxLabel(c)}: ${t('متوسط', 'متوسط', 'avg')} ${_gv(s, cv.reduce((a, b) => a + b) / cv.length)} (${cv.length})');
      }
      b.writeln('');
      for (final e in gs.reversed) {
        final mg = numOf(e['v']);
        b.writeln('${_dt(DateTime.fromMillisecondsSinceEpoch(intOf(e['t'])))} | ${ctxLabel('${e['c']}')} | ${_gv(s, mg)} | ${classifyGlucose(mg, '${e['c']}').label}${e['n'] != null ? ' | ${e['n']}' : ''}');
      }
      b.writeln('');
    }
    if (bs.isNotEmpty) {
      final sy = [for (final e in bs) numOf(e['s'])], di = [for (final e in bs) numOf(e['d'])];
      final pu = [for (final e in bs) if (e['p'] != null) numOf(e['p'])];
      final normals = bs.where((e) => classifyBp(intOf(e['s']), intOf(e['d'])).normal).length;
      b.writeln('━━ ${t('الضغط', 'ضغط الدم', 'Blood pressure')} (mmHg) ━━');
      b.writeln('${t('العدد', 'العدد', 'Count')}: ${bs.length} | ${t('المتوسط', 'المتوسط', 'Avg')}: ${fmt(sy.reduce((a, b) => a + b) / sy.length, 0)}/${fmt(di.reduce((a, b) => a + b) / di.length, 0)}');
      b.writeln('${t('الأقل', 'الأدنى', 'Min')}: ${fmt(sy.reduce(math.min), 0)}/${fmt(di.reduce(math.min), 0)} | ${t('الأعلى', 'الأعلى', 'Max')}: ${fmt(sy.reduce(math.max), 0)}/${fmt(di.reduce(math.max), 0)}');
      if (pu.isNotEmpty) b.writeln('${t('متوسط النبض', 'متوسط النبض', 'Avg pulse')}: ${fmt(pu.reduce((a, b) => a + b) / pu.length, 0)} bpm');
      b.writeln('${t('طبيعي (أقل من 120/80)', 'طبيعي (أقل من 120/80)', 'Normal (<120/80)')}: ${fmt(normals * 100 / bs.length, 0)}%');
      b.writeln('');
      for (final e in bs.reversed) {
        b.writeln(
            '${_dt(DateTime.fromMillisecondsSinceEpoch(intOf(e['t'])))} | ${e['s']}/${e['d']}${e['p'] != null ? ' • ${e['p']} bpm' : ''} | ${classifyBp(intOf(e['s']), intOf(e['d'])).label}${e['n'] != null ? ' | ${e['n']}' : ''}');
      }
      b.writeln('');
    }
    if (gs.isEmpty && bs.isEmpty) b.writeln(t('ما في قراءات لسه.', 'لا توجد قراءات بعد.', 'No readings yet.'));
    b.write(t('* سجل شخصي للمتابعة — مش تشخيص.', '* سجل شخصي للمتابعة وليس تشخيصًا.', '* Personal self-monitoring log — not a diagnosis.'));
    return b.toString();
  }

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final all = _all(s);
    final glucose = mode == 0;
    final kindList = all.where((e) => e['k'] == (glucose ? 'g' : 'bp')).toList();
    final chartList0 = glucose && chartCtx != 'all' ? kindList.where((e) => e['c'] == chartCtx).toList() : kindList;
    final chartList = chartList0.length > range ? chartList0.sublist(chartList0.length - range) : chartList0;
    final last = kindList.isEmpty ? null : kindList.last;
    final mm = _mmol(s);

    VClass? lastC;
    String lastV = '—';
    if (last != null) {
      if (glucose) {
        lastC = classifyGlucose(numOf(last['v']), '${last['c']}');
        lastV = '${_gv(s, numOf(last['v']))} ${_unit(s)}';
      } else {
        lastC = classifyBp(intOf(last['s']), intOf(last['d']));
        lastV = '${last['s']}/${last['d']}';
      }
    }

    // معاينة حية للتصنيف
    VClass? preview;
    if (glucose) {
      final raw = parseNum(gC.text, -1);
      final mg = mm ? raw * _mmolFactor : raw;
      if (raw > 0 && mg >= 10 && mg <= 1000) preview = classifyGlucose(mg, ctx);
    } else {
      final sy = parseNum(sC.text, -1).round(), di = parseNum(dC.text, -1).round();
      if (sy >= 50 && di >= 30 && di < sy) preview = classifyBp(sy, di);
    }

    return ToolList(children: [
      SegmentedButton<int>(
        segments: [
          ButtonSegment(value: 0, icon: const Icon(Icons.bloodtype_rounded), label: Text(tr('السكر', 'Glucose'), maxLines: 1, overflow: TextOverflow.ellipsis)),
          ButtonSegment(value: 1, icon: const Icon(Icons.monitor_heart_rounded), label: Text(tr('الضغط', 'Blood pressure'), maxLines: 1, overflow: TextOverflow.ellipsis)),
        ],
        selected: {mode},
        onSelectionChanged: (v) => setState(() => mode = v.first),
      ),
      const SizedBox(height: 12),
      ResultHero(
        label: glucose ? t('آخر قراءة سكر', 'آخر قراءة سكر', 'Last glucose reading') : t('آخر قراءة ضغط', 'آخر قراءة ضغط', 'Last BP reading'),
        value: lastV,
        sub: last == null
            ? t('ما سجّلت حاجة لسه', 'لا توجد قراءات بعد', 'No readings yet')
            : '${lastC!.label} • ${glucose ? '${ctxLabel('${last['c']}')} • ' : (last['p'] != null ? '${last['p']} bpm • ' : '')}${fmtDateAr(DateTime.fromMillisecondsSinceEpoch(intOf(last['t'])), weekday: false)}',
        colors: glucose ? const [Color(0xFFB4492D), Color(0xFF6B3E26), Color(0xFF3A1F0C)] : const [Color(0xFFD21034), Color(0xFF5A3418), Color(0xFF3A1F0C)],
      ),
      if (lastC != null && lastC.alert == 2)
        NoteBox(_urgentText(glucose), kind: NoteKind.danger)
      else if (lastC != null && lastC.alert == 1)
        NoteBox(
            glucose
                ? t('السكر واطي. لو مريض سكري: خُد 15 جرام سكر سريع وأعد القياس بعد 15 دقيقة، ولو ما اتحسّن أو عندك أعراض كلّم الدكتور.',
                    'السكر منخفض. إن كنت مريض سكري: تناول 15 غرامًا من سكر سريع وأعد القياس بعد 15 دقيقة، وإن لم يتحسّن أو ظهرت أعراض فاتصل بالطبيب.',
                    'Glucose is low. If you have diabetes: take 15 g of fast sugar and recheck in 15 minutes; if it does not improve or you have symptoms, contact a doctor.')
                : t('الضغط واطي. لو معاه دوخة أو إغماء كلّم الدكتور.', 'الضغط منخفض. إن صاحبه دوخة أو إغماء فاستشر الطبيب.',
                    'Blood pressure is low. If you feel dizzy or faint, consult a doctor.'),
            kind: NoteKind.warn),

      // الإدخال
      SCard(
        title: t('سجّل قراءة', 'تسجيل قراءة', 'Log a reading'),
        icon: Icons.add_chart_rounded,
        color: glucose ? SD.henna : SD.red,
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          if (glucose) ...[
            Row(children: [
              Expanded(child: Text(t('الوحدة', 'الوحدة', 'Unit'), style: const TextStyle(fontWeight: FontWeight.w700))),
              SegmentedButton<bool>(
                showSelectedIcon: false,
                segments: const [ButtonSegment(value: false, label: Text('mg/dL')), ButtonSegment(value: true, label: Text('mmol/L'))],
                selected: {mm},
                onSelectionChanged: (v) {
                  // تحويل القيمة المكتوبة للوحدة الجديدة
                  final raw = parseNum(gC.text, -1);
                  if (raw > 0 && v.first != mm) gC.text = v.first ? fmt(raw / _mmolFactor, 1) : fmt(raw * _mmolFactor, 0);
                  s.setData(_kUnit, v.first ? 'mmol' : 'mg');
                  setState(() {});
                },
              ),
            ]),
            const SizedBox(height: 8),
            Wrap(spacing: 6, runSpacing: 6, children: [
              for (final c in _ctxIds) PickChip(ctxLabel(c), ctx == c, () => setState(() => ctx = c), color: SD.henna),
            ]),
            const SizedBox(height: 10),
            NumField(t('قراءة السكر', 'قراءة السكر', 'Glucose reading'), gC, suffix: _unit(s), onChanged: (_) => setState(() {})),
          ] else ...[
            Row(children: [
              Expanded(child: NumField(t('الانقباضي (الفوق)', 'الانقباضي', 'Systolic'), sC, decimal: false, onChanged: (_) => setState(() {}))),
              const SizedBox(width: 8),
              Expanded(child: NumField(t('الانبساطي (التحت)', 'الانبساطي', 'Diastolic'), dC, decimal: false, onChanged: (_) => setState(() {}))),
            ]),
            NumField(t('النبض (اختياري)', 'النبض (اختياري)', 'Pulse (optional)'), pC, decimal: false, suffix: 'bpm'),
          ],
          if (preview != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(children: [
                Text('${t('التصنيف', 'التصنيف', 'Category')}: ', style: const TextStyle(fontWeight: FontWeight.w700)),
                Flexible(child: TagPill(preview.label, preview.color)),
              ]),
            ),
          TextField(
            controller: nC,
            maxLength: 80,
            decoration: InputDecoration(labelText: t('ملاحظة (اختياري)', 'ملاحظة (اختياري)', 'Note (optional)'), counterText: ''),
          ),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: () async {
              final d = await pickDateTime(context, when ?? DateTime.now());
              if (d != null) setState(() => when = d);
            },
            icon: const Icon(Icons.schedule_rounded),
            label: Text(when == null ? t('الوقت: هسي', 'الوقت: الآن', 'Time: now') : '${fmtDateAr(when!, weekday: false)} • ${fmtTimeAr(when!)}',
                maxLines: 1, overflow: TextOverflow.ellipsis),
          ),
          const SizedBox(height: 8),
          FilledButton.icon(onPressed: () => _save(s), icon: const Icon(Icons.save_rounded), label: Text(t('احفظ القراءة', 'حفظ القراءة', 'Save reading'))),
        ]),
      ),

      // الرسم والإحصاء
      SCard(
        title: t('الرسم البياني', 'الرسم البياني', 'Chart'),
        icon: Icons.show_chart_rounded,
        color: SD.nile,
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Wrap(spacing: 6, runSpacing: 6, children: [
            for (final r in [14, 30])
              PickChip('${t('آخر', 'آخر', 'Last')} $r', range == r, () => setState(() => range = r), color: SD.nile),
          ]),
          if (glucose) ...[
            const SizedBox(height: 6),
            Wrap(spacing: 6, runSpacing: 6, children: [
              PickChip(t('الكل', 'الكل', 'All'), chartCtx == 'all', () => setState(() => chartCtx = 'all'), color: SD.henna),
              for (final c in _ctxIds) PickChip(ctxLabel(c), chartCtx == c, () => setState(() => chartCtx = c), color: SD.henna),
            ]),
          ],
          const SizedBox(height: 10),
          if (chartList.isEmpty)
            EmptyHint(Icons.insights_rounded, t('سجّل قراءات عشان يطلع الرسم', 'سجّل قراءات ليظهر الرسم', 'Log readings to see the chart'))
          else
            ..._chartAndStats(s, chartList, glucose),
        ]),
      ),

      // السجل
      SCard(
        title: t('السجل', 'السجل', 'History'),
        icon: Icons.history_rounded,
        color: SD.coffee,
        trailing: Text('${kindList.length}', style: const TextStyle(fontWeight: FontWeight.w800)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          if (kindList.isEmpty) Text(t('فاضي لسه', 'لا يوجد شيء بعد', 'Empty for now'), textAlign: TextAlign.center),
          for (final e in kindList.reversed.take(30)) _row(s, e),
        ]),
      ),

      SCard(
        title: t('تقرير للدكتور', 'تقرير للطبيب', 'Doctor report'),
        icon: Icons.description_rounded,
        color: SD.teal,
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Text(t('ملخص نصي (آخر $range قراءة من السكر والضغط) تقدر تطبعو أو ترسلو للدكتور.',
              'ملخص نصي (آخر $range قراءة من السكر والضغط) يمكن طباعته أو إرساله للطبيب.',
              'A text summary (last $range glucose and BP readings) you can print or send to your doctor.')),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: () => showReportDialog(context, t('تقرير للدكتور', 'تقرير للطبيب', 'Doctor report'), _report(s), ShareBar(() => _report(s))),
            icon: const Icon(Icons.visibility_rounded),
            label: Text(t('اعرض التقرير', 'عرض التقرير', 'View report')),
          ),
          const SizedBox(height: 8),
          ShareBar(() => _report(s)),
        ]),
      ),

      NoteBox(
          t('الأداة دي للمتابعة الشخصية بس، ما بتشخّص ولا بتغني عن الدكتور. الحدود المستخدمة عامة للبالغين (الجمعية الأمريكية للسكري ADA وجمعية القلب الأمريكية AHA)، وأهدافك الشخصية — خصوصًا لو حامل أو مريض سكري أو كبير في السن — بيحددها دكتورك. ما تغيّر جرعة أي دواء من غير ما تسأل.',
              'هذه الأداة للمتابعة الشخصية فقط، لا تُشخّص ولا تغني عن الطبيب. الحدود المستخدمة عامة للبالغين (الجمعية الأمريكية للسكري ADA وجمعية القلب الأمريكية AHA)، وأهدافك الشخصية — خاصةً في الحمل أو السكري أو كبر السن — يحددها طبيبك. لا تغيّر جرعة أي دواء دون استشارة.',
              'This tool is for personal tracking only — it does not diagnose or replace a doctor. Thresholds are general adult references (ADA and AHA); your personal targets — especially in pregnancy, diabetes or older age — are set by your doctor. Never change a medicine dose without asking.'),
          kind: NoteKind.danger),
      NoteBox(
          t('عشان القراءة تكون صاح: الضغط بعد راحة 5 دقايق قاعد، ضهرك مسنود ورجلك في الواطة والكم في مستوى القلب. السكر: اغسل يدك قبل الوخز.',
              'لقراءة دقيقة: قِس الضغط بعد راحة 5 دقائق جالسًا، والظهر مسنود والقدمان على الأرض والكُمّ بمستوى القلب. للسكر: اغسل يديك قبل الوخز.',
              'For accurate readings: measure BP after 5 minutes of seated rest, back supported, feet flat, cuff at heart level. For glucose: wash your hands before the prick.'),
          kind: NoteKind.tip),
    ]);
  }

  List<Widget> _chartAndStats(AppState s, List<Map<String, dynamic>> list, bool glucose) {
    final first = DateTime.fromMillisecondsSinceEpoch(intOf(list.first['t'])), lastD = DateTime.fromMillisecondsSinceEpoch(intOf(list.last['t']));
    final mm = _mmol(s);
    if (glucose) {
      double cv(double mg) => mm ? mg / _mmolFactor : mg;
      final vals = [for (final e in list) numOf(e['v'])];
      final st = _stats(vals, list.where((e) => classifyGlucose(numOf(e['v']), '${e['c']}').normal).length);
      ChartGuide g(double mg, Color c) => ChartGuide(cv(mg), c, mm ? fmt(mg / _mmolFactor, 1) : fmt(mg, 0));
      final guides = chartCtx == 'fast' || chartCtx == 'pre'
          ? [g(70, SD.orange), g(100, SD.green), g(126, SD.red)]
          : [g(70, SD.orange), g(140, SD.gold), g(200, SD.red)];
      return [
        PlusLineChart(
          series: [ChartSeries([for (var i = 0; i < list.length; i++) Offset(i.toDouble(), cv(numOf(list[i]['v'])))], SD.henna, tr('السكر', 'Glucose'))],
          guides: guides,
          startLabel: fmtDateAr(first, weekday: false),
          endLabel: fmtDateAr(lastD, weekday: false),
        ),
        const SizedBox(height: 12),
        StatGrid([
          StatChip(_gv(s, st.avg), t('المتوسط', 'المتوسط', 'Average'), color: SD.nile, icon: Icons.functions_rounded),
          StatChip(_gv(s, st.mn), t('الأقل', 'الأدنى', 'Min'), color: SD.green, icon: Icons.arrow_downward_rounded),
          StatChip(_gv(s, st.mx), t('الأعلى', 'الأعلى', 'Max'), color: SD.red, icon: Icons.arrow_upward_rounded),
        ]),
        const SizedBox(height: 4),
        InfoRow(t('في المعدل الطبيعي', 'ضمن الطبيعي', 'In normal range'), '${fmt(st.inRange, 0)}%',
            icon: Icons.check_circle_outline_rounded, hint: '${st.n} ${t('قراءة', 'قراءة', 'readings')} • ${_unit(s)}', valueColor: st.inRange >= 70 ? SD.green : SD.orange),
      ];
    }
    final sy = [for (final e in list) numOf(e['s'])], di = [for (final e in list) numOf(e['d'])];
    final pu = [for (final e in list) if (e['p'] != null) numOf(e['p'])];
    final normals = list.where((e) => classifyBp(intOf(e['s']), intOf(e['d'])).normal).length;
    double avg(List<double> v) => v.reduce((a, b) => a + b) / v.length;
    return [
      PlusLineChart(
        series: [
          ChartSeries([for (var i = 0; i < list.length; i++) Offset(i.toDouble(), sy[i])], SD.red, t('الانقباضي', 'الانقباضي', 'Systolic')),
          ChartSeries([for (var i = 0; i < list.length; i++) Offset(i.toDouble(), di[i])], SD.nile, t('الانبساطي', 'الانبساطي', 'Diastolic')),
        ],
        guides: const [ChartGuide(120, SD.gold, '120'), ChartGuide(80, SD.gold, '80'), ChartGuide(140, SD.red, '140')],
        startLabel: fmtDateAr(first, weekday: false),
        endLabel: fmtDateAr(lastD, weekday: false),
      ),
      const SizedBox(height: 12),
      StatGrid([
        StatChip('${fmt(avg(sy), 0)}/${fmt(avg(di), 0)}', t('المتوسط', 'المتوسط', 'Average'), color: SD.nile, icon: Icons.functions_rounded),
        StatChip('${fmt(sy.reduce(math.min), 0)}/${fmt(di.reduce(math.min), 0)}', t('الأقل', 'الأدنى', 'Min'), color: SD.green, icon: Icons.arrow_downward_rounded),
        StatChip('${fmt(sy.reduce(math.max), 0)}/${fmt(di.reduce(math.max), 0)}', t('الأعلى', 'الأعلى', 'Max'), color: SD.red, icon: Icons.arrow_upward_rounded),
      ]),
      const SizedBox(height: 4),
      InfoRow(t('طبيعي (أقل من 120/80)', 'طبيعي (أقل من 120/80)', 'Normal (<120/80)'), '${fmt(normals * 100 / list.length, 0)}%',
          icon: Icons.check_circle_outline_rounded, hint: '${list.length} ${t('قراءة', 'قراءة', 'readings')}', valueColor: normals * 100 / list.length >= 70 ? SD.green : SD.orange),
      if (pu.isNotEmpty)
        InfoRow(t('متوسط النبض', 'متوسط النبض', 'Average pulse'), '${fmt(avg(pu), 0)} bpm',
            icon: Icons.favorite_rounded, hint: t('الطبيعي وقت الراحة 60–100 تقريبًا', 'المعتاد أثناء الراحة 60–100 تقريبًا', 'Usual resting range ≈ 60–100')),
    ];
  }

  Widget _row(AppState s, Map<String, dynamic> e) {
    final d = DateTime.fromMillisecondsSinceEpoch(intOf(e['t']));
    final glucose = e['k'] == 'g';
    final c = glucose ? classifyGlucose(numOf(e['v']), '${e['c']}') : classifyBp(intOf(e['s']), intOf(e['d']));
    final p = e['p'] == null ? null : intOf(e['p']);
    final muted = Theme.of(context).colorScheme.onSurface.withValues(alpha: .6);
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(border: Border(bottom: BorderSide(color: muted.withValues(alpha: .15)))),
      child: Row(children: [
        Container(width: 10, height: 10, decoration: BoxDecoration(color: readable(context, c.color), shape: BoxShape.circle)),
        const SizedBox(width: 10),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Flexible(
                child: Text(glucose ? '${_gv(s, numOf(e['v']))} ${_unit(s)}' : '${e['s']}/${e['d']} mmHg',
                    maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15.5)),
              ),
              const SizedBox(width: 8),
              Flexible(child: TagPill(c.label, c.color)),
            ]),
            Text(
              '${glucose ? '${ctxLabel('${e['c']}')} • ' : (p != null ? '$p bpm${p < 60 || p > 100 ? ' ⚠️' : ''} • ' : '')}${fmtDateAr(d, weekday: false)} ${fmtTimeAr(d)}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 12, color: muted),
            ),
            if (e['n'] != null) Text('${e['n']}', maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12.5)),
          ]),
        ),
        IconButton(
          tooltip: t('امسح', 'حذف', 'Delete'),
          visualDensity: VisualDensity.compact,
          onPressed: () => _delete(s, e),
          icon: Icon(Icons.delete_outline_rounded, color: muted),
        ),
      ]),
    );
  }
}
