import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/format.dart';
import '../../core/i18n.dart';
import '../../core/state.dart';
import '../../core/theme.dart';
import '../../core/widgets.dart';
import '../life/life_common.dart';
import 'plus_common.dart';

/// متابعة نمو الطفل — بدون أي ادعاء بالمئينات (percentiles)

const _kKids = 'child_growth_kids';
const _kSel = 'child_growth_sel';

/// عدد الأشهر الكاملة بين تاريخين
int fullMonths(DateTime from, DateTime to) {
  var m = (to.year - from.year) * 12 + to.month - from.month;
  if (to.day < from.day) m--;
  return m < 0 ? 0 : m;
}

/// العمر بالأشهر (كسري) — للرسم والزيادة الشهرية
double monthsF(DateTime from, DateTime to) => dayDiff(from, to) / 30.4375;

/// «سنة و3 شهور»
String ageText(DateTime birth, DateTime at) {
  final m = fullMonths(birth, at);
  if (m < 1) {
    final d = dayDiff(birth, at);
    return isEn ? '$d days' : '$d ${t('يوم', 'يومًا', '')}';
  }
  final y = m ~/ 12, r = m % 12;
  if (isEn) {
    if (y == 0) return '$m month${m == 1 ? '' : 's'}';
    return '$y yr${y == 1 ? '' : 's'}${r > 0 ? ' $r mo' : ''} ($m mo)';
  }
  final ys = y == 0 ? '' : (y == 1 ? t('سنة', 'سنة', '') : (y == 2 ? t('سنتين', 'سنتان', '') : '$y ${y <= 10 ? t('سنين', 'سنوات', '') : 'سنة'}'));
  final ms = r == 0 ? '' : (r == 1 ? t('شهر', 'شهر', '') : (r == 2 ? t('شهرين', 'شهران', '') : '$r ${r <= 10 ? t('شهور', 'أشهر', '') : 'شهرًا'}'));
  final s = [ys, ms].where((x) => x.isNotEmpty).join(' و');
  return y == 0 ? s : '$s ($m ${t('شهر', 'شهرًا', '')})';
}

class ChildGrowthTool extends StatefulWidget {
  const ChildGrowthTool({super.key});
  @override
  State<ChildGrowthTool> createState() => _ChildGrowthToolState();
}

class _ChildGrowthToolState extends State<ChildGrowthTool> {
  int metric = 0; // 0 وزن، 1 طول، 2 رأس، 3 BMI

  List<Map<String, dynamic>> _kids(AppState s) => mapList(s.getData<List>(_kKids));
  void _saveKids(AppState s, List<Map<String, dynamic>> k) {
    s.setData(_kKids, k);
    setState(() {});
  }

  List<Map<String, dynamic>> _meas(Map k) => mapList(k['m'])..sort((a, b) => '${a['d']}'.compareTo('${b['d']}'));

  Future<void> _editKid(AppState s, [Map<String, dynamic>? kid]) async {
    final nameC = TextEditingController(text: kid?['name'] ?? '');
    var sex = kid?['sex'] ?? 'm';
    DateTime? birth = parseDk(kid?['birth']);
    var color = intOf(kid?['color'], _kids(s).length % lifePalette.length);
    final ok = await lifeSheet<bool>(
      context,
      kid == null ? t('ضيف طفل', 'إضافة طفل', 'Add a child') : t('عدّل البيانات', 'تعديل البيانات', 'Edit details'),
      (ctx, set) => Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        TextField(controller: nameC, maxLength: 30, decoration: InputDecoration(labelText: t('الاسم', 'الاسم', 'Name'), counterText: '')),
        const SizedBox(height: 12),
        SegmentedButton<String>(
          segments: [
            ButtonSegment(value: 'm', icon: const Icon(Icons.boy_rounded), label: Text(t('ولد', 'ذكر', 'Boy'))),
            ButtonSegment(value: 'f', icon: const Icon(Icons.girl_rounded), label: Text(t('بت', 'أنثى', 'Girl'))),
          ],
          selected: {sex},
          onSelectionChanged: (v) => set(() => sex = v.first),
        ),
        const SizedBox(height: 12),
        LifeDateButton(
          label: t('تاريخ الميلاد', 'تاريخ الميلاد', 'Birth date'),
          value: birth,
          first: DateTime(DateTime.now().year - 19),
          last: todayPlace(),
          onPick: (d) => set(() => birth = d),
        ),
        const SizedBox(height: 12),
        ColorDots(color, (i) => set(() => color = i)),
        const SizedBox(height: 16),
        FilledButton.icon(
          onPressed: () {
            if (nameC.text.trim().isEmpty || birth == null) {
              toast(t('اكتب الاسم واختار تاريخ الميلاد', 'أدخل الاسم واختر تاريخ الميلاد', 'Enter a name and pick the birth date'));
              return;
            }
            Navigator.pop(ctx, true);
          },
          icon: const Icon(Icons.check_rounded),
          label: Text(t('احفظ', 'حفظ', 'Save')),
        ),
      ]),
    );
    final name = nameC.text.trim();
    nameC.dispose();
    if (ok != true || birth == null || name.isEmpty) return;
    final kids = _kids(s);
    if (kid == null) {
      final k = {'id': newId(), 'name': name, 'sex': sex, 'birth': dk(birth!), 'color': color, 'm': <Map>[], 'vac': <Map>[]};
      kids.add(k);
      s.setData(_kSel, k['id']);
      s.award(5, t('ضفت طفل', 'إضافة طفل', 'Added a child'));
    } else {
      final i = kids.indexWhere((x) => x['id'] == kid['id']);
      if (i >= 0) kids[i] = {...kids[i], 'name': name, 'sex': sex, 'birth': dk(birth!), 'color': color};
    }
    _saveKids(s, kids);
  }

  Future<void> _addMeasure(AppState s, Map<String, dynamic> kid, [Map<String, dynamic>? old]) async {
    final birth = parseDk(kid['birth'])!;
    DateTime? date = parseDk(old?['d']) ?? todayPlace();
    String f(dynamic v) => v == null ? '' : fmt(numOf(v), 2);
    final wC = TextEditingController(text: f(old?['w'])), hC = TextEditingController(text: f(old?['h'])), hcC = TextEditingController(text: f(old?['hc']));
    final ok = await lifeSheet<bool>(
      context,
      old == null ? t('قياس جديد', 'قياس جديد', 'New measurement') : t('عدّل القياس', 'تعديل القياس', 'Edit measurement'),
      (ctx, set) => Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        LifeDateButton(
          label: t('تاريخ القياس', 'تاريخ القياس', 'Measurement date'),
          value: date,
          first: birth,
          last: todayPlace(),
          color: SD.teal,
          onPick: (d) => set(() => date = d),
        ),
        if (date != null)
          Padding(
            padding: const EdgeInsets.only(top: 6, bottom: 4),
            child: Text('${t('العمر وقتها', 'العمر حينها', 'Age then')}: ${ageText(birth, date!)}', style: const TextStyle(fontWeight: FontWeight.w700)),
          ),
        const SizedBox(height: 8),
        NumField(t('الوزن', 'الوزن', 'Weight'), wC, suffix: 'kg'),
        NumField(t('الطول', 'الطول', 'Height / length'), hC, suffix: 'cm'),
        NumField(t('محيط الراس', 'محيط الرأس', 'Head circumference'), hcC, suffix: 'cm'),
        Text(t('عبّي الفي يدك بس — مش لازم الكل', 'أدخل المتوفر فقط — ليس شرطًا إدخال الكل', 'Fill in what you have — not all are required'),
            style: const TextStyle(fontSize: 12)),
        const SizedBox(height: 12),
        FilledButton.icon(
          onPressed: () {
            final w = parseNum(wC.text), h = parseNum(hC.text), hc = parseNum(hcC.text);
            if (w <= 0 && h <= 0 && hc <= 0) {
              toast(t('اكتب قياس واحد على الأقل', 'أدخل قياسًا واحدًا على الأقل', 'Enter at least one measurement'));
              return;
            }
            if (w > 200 || h > 250 || hc > 80) {
              toast(t('في رقم غلط — راجع الوحدات', 'يوجد رقم غير منطقي — راجع الوحدات', 'A value looks wrong — check the units'));
              return;
            }
            Navigator.pop(ctx, true);
          },
          icon: const Icon(Icons.check_rounded),
          label: Text(t('احفظ', 'حفظ', 'Save')),
        ),
      ]),
    );
    final w = parseNum(wC.text), h = parseNum(hC.text), hc = parseNum(hcC.text);
    wC.dispose();
    hC.dispose();
    hcC.dispose();
    if (ok != true || date == null) return;
    final e = {'id': old?['id'] ?? newId(), 'd': dk(date!), if (w > 0) 'w': w, if (h > 0) 'h': h, if (hc > 0) 'hc': hc};
    final kids = _kids(s);
    final i = kids.indexWhere((x) => x['id'] == kid['id']);
    if (i < 0) return;
    final m = mapList(kids[i]['m'])..removeWhere((x) => x['id'] == e['id']);
    m.add(e);
    kids[i]['m'] = m;
    _saveKids(s, kids);
    if (old == null) {
      s.bump('growth_measures');
      s.awardDaily('child_growth', 5, t('سجّلت قياس طفل', 'تسجيل قياس طفل', 'Logged a child measurement'));
    }
  }

  Future<void> _addVac(AppState s, Map<String, dynamic> kid) async {
    final c = TextEditingController();
    DateTime? date = todayPlace();
    final ok = await lifeSheet<bool>(
      context,
      t('ملاحظة تطعيم', 'ملاحظة تطعيم', 'Vaccination note'),
      (ctx, set) => Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        TextField(
          controller: c,
          maxLength: 120,
          decoration: InputDecoration(
              labelText: t('اسم التطعيم / الملاحظة', 'اسم التطعيم / الملاحظة', 'Vaccine / note'),
              hintText: t('زي ما مكتوب في كرت التطعيم', 'كما هو مكتوب في بطاقة التطعيم', 'As written on the vaccination card'),
              counterText: ''),
        ),
        const SizedBox(height: 8),
        LifeDateButton(
          label: t('التاريخ', 'التاريخ', 'Date'),
          value: date,
          first: parseDk(kid['birth']),
          last: DateTime(DateTime.now().year + 3),
          color: SD.purple,
          onPick: (d) => set(() => date = d),
        ),
        const SizedBox(height: 12),
        FilledButton.icon(
          onPressed: () => Navigator.pop(ctx, c.text.trim().isNotEmpty),
          icon: const Icon(Icons.check_rounded),
          label: Text(t('احفظ', 'حفظ', 'Save')),
        ),
      ]),
    );
    final text = c.text.trim();
    c.dispose();
    if (ok != true || date == null || text.isEmpty) return;
    final kids = _kids(s);
    final i = kids.indexWhere((x) => x['id'] == kid['id']);
    if (i < 0) return;
    kids[i]['vac'] = [...mapList(kids[i]['vac']), {'id': newId(), 'd': dk(date!), 'text': text}];
    _saveKids(s, kids);
  }

  void _removeFrom(AppState s, Map kid, String field, Map e) {
    final kids = _kids(s);
    final i = kids.indexWhere((x) => x['id'] == kid['id']);
    if (i < 0) return;
    final before = mapList(kids[i][field]);
    kids[i][field] = before.where((x) => x['id'] != e['id']).toList();
    _saveKids(s, kids);
    undoSnack(t('اتمسح', 'تم الحذف', 'Deleted'), () {
      final k2 = _kids(s);
      final j = k2.indexWhere((x) => x['id'] == kid['id']);
      if (j < 0) return;
      k2[j][field] = before;
      _saveKids(s, k2);
    });
  }

  Future<void> _deleteKid(AppState s, Map kid) async {
    final ok = await confirmAsk(context, t('تمسح ${kid['name']}؟', 'حذف ${kid['name']}؟', 'Delete ${kid['name']}?'),
        t('كل القياسات والملاحظات حتتمسح.', 'ستُحذف جميع القياسات والملاحظات.', 'All measurements and notes will be deleted.'));
    if (!ok) return;
    _saveKids(s, _kids(s)..removeWhere((x) => x['id'] == kid['id']));
  }

  double? _bmi(Map e) {
    final w = numOf(e['w']), h = numOf(e['h']);
    if (w <= 0 || h <= 0) return null;
    return w / ((h / 100) * (h / 100));
  }

  String _report(Map kid) {
    final birth = parseDk(kid['birth'])!;
    final ms = _meas(kid);
    final b = StringBuffer()
      ..writeln('👶 ${kid['name']} — ${t('متابعة النمو', 'متابعة النمو', 'Growth record')}')
      ..writeln('${t('تاريخ الميلاد', 'تاريخ الميلاد', 'Birth date')}: ${kid['birth']} • ${ageText(birth, todayPlace())}')
      ..writeln('');
    for (final e in ms.reversed) {
      final d = parseDk(e['d'])!;
      final parts = [
        if (e['w'] != null) '${fmt(numOf(e['w']), 2)} kg',
        if (e['h'] != null) '${fmt(numOf(e['h']), 1)} cm',
        if (e['hc'] != null) '${t('راس', 'رأس', 'head')} ${fmt(numOf(e['hc']), 1)} cm',
        if (_bmi(e) != null) 'BMI ${fmt(_bmi(e), 1)}',
      ];
      b.writeln('${e['d']} (${fullMonths(birth, d)} ${t('شهر', 'شهر', 'mo')}): ${parts.join(' • ')}');
    }
    final vac = mapList(kid['vac']);
    if (vac.isNotEmpty) {
      b.writeln('');
      b.writeln('💉 ${t('التطعيمات', 'التطعيمات', 'Vaccinations')}:');
      for (final v in vac..sort((a, b) => '${a['d']}'.compareTo('${b['d']}'))) {
        b.writeln('${v['d']}: ${v['text']}');
      }
    }
    return b.toString().trim();
  }

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final kids = _kids(s);
    final selId = s.getData<String>(_kSel);
    final kid = kids.isEmpty ? null : kids.firstWhere((k) => k['id'] == selId, orElse: () => kids.first);

    return ToolList(children: [
      if (kids.isEmpty)
        SCard(
          child: EmptyHint(
            Icons.child_care_rounded,
            t('ضيف طفلك وسجّل وزنو وطولو كل شهر وتابع نموه بالرسم', 'أضف طفلك وسجّل وزنه وطوله كل شهر وتابع نموه بالرسم',
                "Add your child, log weight and height monthly and follow their growth on a chart"),
            action: FilledButton.icon(onPressed: () => _editKid(s), icon: const Icon(Icons.person_add_rounded), label: Text(t('ضيف طفل', 'إضافة طفل', 'Add a child'))),
          ),
        )
      else ...[
        SizedBox(
          height: 46,
          child: ListView(scrollDirection: Axis.horizontal, children: [
            for (final k in kids)
              Padding(
                padding: const EdgeInsetsDirectional.only(end: 8),
                child: ChoiceChip(
                  avatar: Icon(k['sex'] == 'f' ? Icons.girl_rounded : Icons.boy_rounded, color: readable(context, palette(intOf(k['color'])))),
                  label: Text('${k['name']}', maxLines: 1, overflow: TextOverflow.ellipsis),
                  selected: k['id'] == kid!['id'],
                  selectedColor: palette(intOf(k['color'])).withValues(alpha: .25),
                  onSelected: (_) => s.setData(_kSel, k['id']),
                ),
              ),
            ActionChip(avatar: const Icon(Icons.add_rounded), label: Text(t('طفل', 'طفل', 'Child')), onPressed: () => _editKid(s)),
          ]),
        ),
        const SizedBox(height: 12),
        ..._kidView(s, kid!),
      ],
      NoteBox(
          t('الأداة دي للتسجيل والمتابعة بس. ما بتقول ليك الطفل «طبيعي» ولا لا — قارن القياسات مع منحنى النمو في كرت العيادة (منحنيات منظمة الصحة العالمية) واسأل طبيب الأطفال. التطعيمات حسب جدول بلدك ووزارة الصحة.',
              'هذه الأداة للتسجيل والمتابعة فقط، ولا تحكم بأن نمو الطفل «طبيعي» أو لا — قارن القياسات بمنحنى النمو في بطاقة العيادة (منحنيات منظمة الصحة العالمية) واستشر طبيب الأطفال. التطعيمات حسب جدول وزارة الصحة في بلدك.',
              "This tool is for recording only and does not judge whether growth is “normal” — compare measurements with the growth chart on your clinic card (WHO growth standards) and ask your paediatrician. Follow your country's official vaccination schedule."),
          kind: NoteKind.warn),
    ]);
  }

  List<Widget> _kidView(AppState s, Map<String, dynamic> kid) {
    final birth = parseDk(kid['birth']) ?? todayPlace();
    final ms = _meas(kid);
    final color = palette(intOf(kid['color']));
    double? latest(String k) {
      for (final e in ms.reversed) {
        if (e[k] != null) return numOf(e[k]);
      }
      return null;
    }

    Map<String, dynamic>? latestBmi;
    for (final e in ms.reversed) {
      if (_bmi(e) != null) {
        latestBmi = e;
        break;
      }
    }

    final keys = ['w', 'h', 'hc', 'bmi'];
    final units = ['kg', 'cm', 'cm', 'kg/m²'];
    final names = [t('الوزن', 'الوزن', 'Weight'), t('الطول', 'الطول', 'Height'), t('الراس', 'الرأس', 'Head'), 'BMI'];
    final key = keys[metric];
    final pts = <Offset>[];
    for (final e in ms) {
      final v = key == 'bmi' ? _bmi(e) : (e[key] == null ? null : numOf(e[key]));
      if (v != null) pts.add(Offset(monthsF(birth, parseDk(e['d'])!), v));
    }
    final vac = mapList(kid['vac'])..sort((a, b) => '${b['d']}'.compareTo('${a['d']}'));

    return [
      ResultHero(
        label: '${kid['sex'] == 'f' ? '👧' : '👦'} ${kid['name']}',
        value: '${fullMonths(birth, todayPlace())} ${t('شهر', 'شهرًا', 'months')}',
        sub: '${ageText(birth, todayPlace())} • ${t('اتولد', 'المولد', 'Born')} ${fmtDateAr(birth, weekday: false)}',
        colors: [Color.lerp(color, Colors.black, .2)!, const Color(0xFF5A3418), const Color(0xFF3A1F0C)],
      ),
      Row(children: [
        Expanded(
          child: FilledButton.icon(
            onPressed: () => _addMeasure(s, kid),
            icon: const Icon(Icons.straighten_rounded),
            label: Text(t('قياس جديد', 'قياس جديد', 'New measurement'), maxLines: 1, overflow: TextOverflow.ellipsis),
          ),
        ),
        const SizedBox(width: 8),
        PopupMenuButton<int>(
          icon: const Icon(Icons.more_vert_rounded),
          onSelected: (v) => v == 0 ? _editKid(s, kid) : _deleteKid(s, kid),
          itemBuilder: (_) => [
            PopupMenuItem(value: 0, child: Text(t('عدّل البيانات', 'تعديل البيانات', 'Edit details'))),
            PopupMenuItem(value: 1, child: Text(t('امسح الطفل', 'حذف الطفل', 'Delete child'))),
          ],
        ),
      ]),
      const SizedBox(height: 12),
      StatGrid([
        StatChip(latest('w') == null ? '—' : fmt(latest('w'), 2), '${t('الوزن', 'الوزن', 'Weight')} kg', color: SD.green, icon: Icons.monitor_weight_rounded),
        StatChip(latest('h') == null ? '—' : fmt(latest('h'), 1), '${t('الطول', 'الطول', 'Height')} cm', color: SD.nile, icon: Icons.height_rounded),
        StatChip(latest('hc') == null ? '—' : fmt(latest('hc'), 1), '${t('الراس', 'الرأس', 'Head')} cm', color: SD.purple, icon: Icons.face_rounded),
      ]),
      const SizedBox(height: 8),
      if (latestBmi != null)
        InfoRow(t('مؤشر كتلة الجسم (BMI)', 'مؤشر كتلة الجسم (BMI)', 'Body mass index (BMI)'), '${fmt(_bmi(latestBmi), 1)} kg/m²',
            icon: Icons.calculate_rounded,
            hint: t('قيمة بس — للأطفال بتتقرا على منحنى BMI حسب العمر في العيادة', 'قيمة فقط — تُقرأ للأطفال على منحنى BMI حسب العمر في العيادة',
                "Value only — for children it's read on the clinic's BMI-for-age chart")),
      const SizedBox(height: 8),
      SCard(
        title: t('الرسم حسب العمر', 'الرسم حسب العمر', 'Chart by age'),
        icon: Icons.show_chart_rounded,
        color: color,
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Wrap(spacing: 6, runSpacing: 6, children: [
            for (var i = 0; i < 4; i++) PickChip(names[i], metric == i, () => setState(() => metric = i), color: color),
          ]),
          const SizedBox(height: 10),
          if (pts.isEmpty)
            EmptyHint(Icons.insights_rounded, t('سجّل قياسات عشان يطلع الرسم', 'سجّل قياسات ليظهر الرسم', 'Log measurements to see the chart'))
          else ...[
            PlusLineChart(
              series: [ChartSeries(pts, color, names[metric])],
              startLabel: '${fmt(pts.first.dx, 1)} ${t('شهر', 'شهر', 'mo')}',
              endLabel: '${fmt(pts.last.dx, 1)} ${t('شهر', 'شهر', 'mo')}',
            ),
            const SizedBox(height: 4),
            Text('${names[metric]} (${units[metric]}) ${t('مقابل العمر بالشهور', 'مقابل العمر بالأشهر', 'vs. age in months')}',
                textAlign: TextAlign.center, style: const TextStyle(fontSize: 12)),
          ],
        ]),
      ),
      SCard(
        title: t('القياسات', 'القياسات', 'Measurements'),
        icon: Icons.list_alt_rounded,
        color: SD.teal,
        trailing: Text('${ms.length}', style: const TextStyle(fontWeight: FontWeight.w800)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          if (ms.isEmpty) Text(t('ما في قياسات لسه', 'لا توجد قياسات بعد', 'No measurements yet'), textAlign: TextAlign.center),
          for (var i = ms.length - 1; i >= 0; i--) _measRow(s, kid, birth, ms, i),
        ]),
      ),
      SCard(
        title: t('ملاحظات التطعيم', 'ملاحظات التطعيم', 'Vaccination notes'),
        icon: Icons.vaccines_rounded,
        color: SD.purple,
        trailing: IconButton(
          tooltip: t('ضيف', 'إضافة', 'Add'),
          onPressed: () => _addVac(s, kid),
          icon: const Icon(Icons.add_circle_rounded),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          if (vac.isEmpty)
            Text(t('سجّل التطعيمات زي ما مكتوبة في كرت الطفل', 'سجّل التطعيمات كما هي مكتوبة في بطاقة الطفل', "Record vaccines as written on the child's card"),
                textAlign: TextAlign.center),
          for (final v in vac)
            ListTile(
              contentPadding: EdgeInsets.zero,
              dense: true,
              leading: Icon(Icons.vaccines_rounded, color: readable(context, SD.purple)),
              title: Text('${v['text']}', maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w700)),
              subtitle: Text(() {
                final d = parseDk(v['d']);
                if (d == null) return '';
                final future = d.isAfter(todayPlace());
                return '${fmtDateAr(d, weekday: false)}${future ? ' • ${t('جاي', 'قادم', 'upcoming')}' : ' • ${t('العمر', 'العمر', 'age')} ${fullMonths(birth, d)} ${t('شهر', 'شهر', 'mo')}'}';
              }(), maxLines: 1, overflow: TextOverflow.ellipsis),
              trailing: IconButton(
                visualDensity: VisualDensity.compact,
                onPressed: () => _removeFrom(s, kid, 'vac', v),
                icon: const Icon(Icons.delete_outline_rounded),
              ),
            ),
        ]),
      ),
      if (ms.isNotEmpty || vac.isNotEmpty) ShareBar(() => _report(kid)),
      const SizedBox(height: 8),
    ];
  }

  Widget _measRow(AppState s, Map<String, dynamic> kid, DateTime birth, List<Map<String, dynamic>> ms, int i) {
    final e = ms[i];
    final d = parseDk(e['d'])!;
    final muted = Theme.of(context).colorScheme.onSurface.withValues(alpha: .6);
    // الزيادة الشهرية مقارنة بآخر قياس سابق فيه نفس القيمة
    String? gain(String k, String unit, int digits) {
      if (e[k] == null) return null;
      for (var j = i - 1; j >= 0; j--) {
        if (ms[j][k] != null) {
          final months = monthsF(parseDk(ms[j]['d'])!, d);
          if (months <= 0) return null;
          final g = (numOf(e[k]) - numOf(ms[j][k])) / months;
          return '${g >= 0 ? '+' : ''}${fmt(g, digits)} $unit/${t('شهر', 'شهر', 'mo')}';
        }
      }
      return null;
    }

    final vals = [
      if (e['w'] != null) '${fmt(numOf(e['w']), 2)} kg',
      if (e['h'] != null) '${fmt(numOf(e['h']), 1)} cm',
      if (e['hc'] != null) '${t('راس', 'رأس', 'head')} ${fmt(numOf(e['hc']), 1)}',
    ];
    final gains = [gain('w', 'kg', 2), gain('h', 'cm', 1)].whereType<String>().toList();
    return InkWell(
      onTap: () => _addMeasure(s, kid, e),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(border: Border(bottom: BorderSide(color: muted.withValues(alpha: .15)))),
        child: Row(children: [
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(vals.join(' • '), maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w800)),
              Text('${fmtDateAr(d, weekday: false)} • ${fullMonths(birth, d)} ${t('شهر', 'شهر', 'mo')}',
                  maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 12, color: muted)),
              if (gains.isNotEmpty)
                Text('${t('الزيادة', 'الزيادة', 'Gain')}: ${gains.join(' • ')}',
                    maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 12, color: readable(context, SD.green), fontWeight: FontWeight.w700)),
            ]),
          ),
          IconButton(
            visualDensity: VisualDensity.compact,
            tooltip: t('امسح', 'حذف', 'Delete'),
            onPressed: () => _removeFrom(s, kid, 'm', e),
            icon: Icon(Icons.delete_outline_rounded, color: muted),
          ),
        ]),
      ),
    );
  }
}
