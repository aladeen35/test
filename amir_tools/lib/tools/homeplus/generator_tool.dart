import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/format.dart';
import '../../core/i18n.dart';
import '../../core/state.dart';
import '../../core/theme.dart';
import '../../core/widgets.dart';
import 'hp_common.dart';

/// تقدير استهلاك الوقود (لتر/ساعة) بخط «ويلانز» الخطي المقرّب من جداول الاستهلاك الشائعة:
/// ديزل ≈ 0.045×القدرة المقنّنة + 0.25×القدرة الفعلية (≈0.28–0.30 ل/ك.و.س عند الحمل الكامل،
/// ≈0.4 عند ربع الحمل)، بنزين ≈ 0.1×المقنّنة + 0.5×الفعلية (مولدات البنزين الصغيرة أقل كفاءة).
double fuelLph({required double ratedKw, required double loadFrac, required bool diesel}) {
  if (ratedKw <= 0) return 0;
  final out = ratedKw * loadFrac.clamp(0.0, 1.1);
  return diesel ? 0.045 * ratedKw + 0.25 * out : 0.10 * ratedKw + 0.50 * out;
}

class GeneratorTool extends StatefulWidget {
  const GeneratorTool({super.key});
  @override
  State<GeneratorTool> createState() => _GeneratorToolState();
}

class _GeneratorToolState extends State<GeneratorTool> {
  late final TextEditingController ratingC, hoursC, priceC, curC, oilC;
  bool kva = true, diesel = true;
  double load = 50;

  @override
  void initState() {
    super.initState();
    final c = _cfg(context.read<AppState>());
    ratingC = TextEditingController(text: '${c['rating'] ?? 10}');
    hoursC = TextEditingController(text: '${c['hours'] ?? 6}');
    priceC = TextEditingController(text: '${c['price'] ?? ''}');
    curC = TextEditingController(text: (c['cur'] as String?) ?? t('جنيه', 'جنيه', 'SDG'));
    oilC = TextEditingController(text: '${c['oil'] ?? 150}');
    kva = c['kva'] != false;
    diesel = c['diesel'] != false;
    load = numOf(c['load'], 50);
  }

  @override
  void dispose() {
    for (final c in [ratingC, hoursC, priceC, curC, oilC]) {
      c.dispose();
    }
    super.dispose();
  }

  Map<String, dynamic> _cfg(AppState s) => Map<String, dynamic>.from(s.getData<Map>('generator_cfg') ?? {});

  void _save(AppState s) {
    s.setData('generator_cfg', {
      'rating': parseNum(ratingC.text),
      'hours': parseNum(hoursC.text),
      'price': parseNum(priceC.text),
      'cur': curC.text.trim(),
      'oil': parseNum(oilC.text, 150),
      'kva': kva,
      'diesel': diesel,
      'load': load,
    });
    setState(() {});
  }

  List<Map<String, dynamic>> _log(AppState s) {
    final l = mapList(s.getData<List>('generator_log'));
    l.sort((a, b) => intOf(a['t']).compareTo(intOf(b['t'])));
    return l;
  }

  void _addLog(AppState s, Map<String, dynamic> e) {
    final l = _log(s)..add(e);
    s.setData('generator_log', l.length > 400 ? l.sublist(l.length - 400) : l);
    setState(() {});
  }

  Future<void> _logHours(AppState s, double hoursPerDay) async {
    var date = pToday();
    final hC = TextEditingController(text: fmt(hoursPerDay, 1));
    final ok = await lifeSheet<bool>(
      context,
      t('سجّل ساعات التشغيل', 'تسجيل ساعات التشغيل', 'Log running hours'),
      (ctx, set) => Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        LifeDateButton(label: t('اليوم', 'التاريخ', 'Date'), value: date, onPick: (d) => set(() => date = d ?? date), last: pToday()),
        const SizedBox(height: 12),
        NumField(t('عدد الساعات', 'عدد الساعات', 'Hours'), hC, suffix: t('ساعة', 'ساعة', 'h')),
        FilledButton.icon(onPressed: () => Navigator.pop(ctx, true), icon: const Icon(Icons.check_rounded), label: Text(t('احفظ', 'حفظ', 'Save'))),
      ]),
    );
    final h = parseNum(hC.text);
    hC.dispose();
    if (ok != true || h <= 0 || !mounted) return;
    _addLog(s, {'id': newId(), 'k': 'run', 'd': dk(date), 'h': h, 't': DateTime(date.year, date.month, date.day, 12).millisecondsSinceEpoch});
    s.awardDaily('generator_log', 3, t('سجّلت ساعات المولّد', 'تسجيل ساعات المولد', 'Logged generator hours'));
  }

  Future<void> _oilChanged(AppState s) async {
    final ok = await confirmAsk(context, t('غيّرت الزيت؟', 'تم تغيير الزيت؟', 'Oil changed?'),
        t('حنبدأ نعدّ الساعات من الليلة', 'سيبدأ عدّ الساعات من اليوم', 'Hours will be counted again from today'),
        danger: false);
    if (!ok || !mounted) return;
    final d = pNow();
    _addLog(s, {'id': newId(), 'k': 'oil', 'd': dk(d), 't': DateTime(d.year, d.month, d.day, 12, 1).millisecondsSinceEpoch});
    s.award(5, t('غيّرت زيت المولّد', 'تغيير زيت المولد', 'Changed generator oil'));
  }

  void _delete(AppState s, Map e) {
    final l = _log(s)..removeWhere((x) => x['id'] == e['id']);
    s.setData('generator_log', l);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final rating = parseNum(ratingC.text);
    final ratedKw = kva ? rating * 0.8 : rating;
    final hours = parseNum(hoursC.text).clamp(0, 24).toDouble();
    final price = parseNum(priceC.text);
    final cur = curC.text.trim();
    final lph = fuelLph(ratedKw: ratedKw, loadFrac: load / 100, diesel: diesel);
    final daily = lph * hours, monthly = daily * 30;
    final kwhDay = ratedKw * load / 100 * hours;
    final perKwh = kwhDay <= 0 || price <= 0 ? null : daily * price / kwhDay;
    final oilEvery = parseNum(oilC.text, 150).clamp(10, 2000).toDouble();

    final log = _log(s);
    final lastOilIdx = log.lastIndexWhere((e) => e['k'] == 'oil');
    final since = log.skip(lastOilIdx + 1).where((e) => e['k'] == 'run').fold<double>(0, (a, e) => a + numOf(e['h']));
    final totalH = log.where((e) => e['k'] == 'run').fold<double>(0, (a, e) => a + numOf(e['h']));
    final untilOil = oilEvery - since;
    final daysToOil = hours > 0 && untilOil > 0 ? (untilOil / hours).ceil() : null;
    final last7 = pToday().subtract(const Duration(days: 6));
    final h7 = log.where((e) => e['k'] == 'run' && (parseDk(e['d'])?.isBefore(last7) == false)).fold<double>(0, (a, e) => a + numOf(e['h']));
    final oilColor = untilOil <= 0 ? SD.red : (untilOil <= oilEvery * .15 ? SD.orange : SD.green);
    final fuelName = diesel ? t('جازولين', 'ديزل', 'Diesel') : t('بنزين', 'بنزين', 'Petrol');

    String summary() => [
          '⚡ ${t('المولّد والوقود', 'المولد والوقود', 'Generator & fuel')}',
          '${t('القدرة', 'القدرة', 'Rating')}: ${fmt(rating, 1)} ${kva ? 'kVA' : 'kW'} · ${t('الحمل', 'الحمل', 'Load')} ${fmt(load, 0)}% · $fuelName',
          '${t('الاستهلاك', 'الاستهلاك', 'Consumption')}: ≈ ${fmt(lph, 2)} ${t('لتر/ساعة', 'لتر/ساعة', 'L/h')}',
          '${t('في اليوم', 'يوميًا', 'Per day')}: ${fmt(daily, 1)} ${t('لتر', 'لتر', 'L')}${price > 0 ? ' = ${fmt(daily * price, 0)} $cur' : ''}',
          '${t('في الشهر', 'شهريًا', 'Per month')}: ${fmt(monthly, 0)} ${t('لتر', 'لتر', 'L')}${price > 0 ? ' = ${fmt(monthly * price, 0)} $cur' : ''}',
          '${t('الزيت الجاي بعد', 'تغيير الزيت القادم بعد', 'Next oil change in')}: ${fmt(untilOil, 0)} ${t('ساعة', 'ساعة', 'h')}',
        ].join('\n');

    return ToolList(children: [
      ResultHero(
        label: t('الوقود في الشهر', 'الوقود شهريًا', 'Fuel per month'),
        value: rating <= 0 ? '—' : '${fmt(monthly, 0)} ${t('لتر', 'لتر', 'L')}',
        sub: rating <= 0
            ? t('دخّل قدرة المولّد', 'أدخل قدرة المولد', 'Enter generator rating')
            : '≈ ${fmt(lph, 2)} ${t('لتر/ساعة', 'لتر/ساعة', 'L/h')}${price > 0 ? ' · ${fmt(monthly * price, 0)} $cur' : ''}',
        colors: const [Color(0xFF0E8C84), Color(0xFF5A3418), Color(0xFF3A1F0C)],
      ),
      SCard(
        title: t('بيانات المولّد', 'بيانات المولد', 'Generator details'),
        icon: Icons.electrical_services_rounded,
        color: SD.teal,
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Row(children: [
            Expanded(flex: 3, child: NumField(t('القدرة', 'القدرة', 'Rating'), ratingC, onChanged: (_) => _save(s))),
            const SizedBox(width: 8),
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Wrap(spacing: 6, runSpacing: 6, children: [
                  PickChip('kVA', kva, () {
                    kva = true;
                    _save(s);
                  }, color: SD.teal),
                  PickChip('kW', !kva, () {
                    kva = false;
                    _save(s);
                  }, color: SD.teal),
                ]),
              ),
            ),
          ]),
          Wrap(spacing: 8, runSpacing: 8, children: [
            PickChip('⛽ ${t('جازولين', 'ديزل', 'Diesel')}', diesel, () {
              diesel = true;
              _save(s);
            }, color: SD.coffee),
            PickChip('⛽ ${t('بنزين', 'بنزين', 'Petrol')}', !diesel, () {
              diesel = false;
              _save(s);
            }, color: SD.orange),
          ]),
          const SizedBox(height: 12),
          HpBar(load / 100,
              color: load > 85 ? SD.red : SD.teal, left: t('الحمل (كم من قدرته شغّال)', 'نسبة الحمل', 'Load (share of capacity used)'), right: '${fmt(load, 0)}%'),
          Slider(
            value: load,
            min: 10,
            max: 100,
            divisions: 18,
            label: '${fmt(load, 0)}%',
            onChanged: (v) => setState(() => load = v),
            onChangeEnd: (_) => _save(s),
          ),
          NumField(t('ساعات التشغيل في اليوم', 'ساعات التشغيل يوميًا', 'Running hours per day'), hoursC, suffix: t('ساعة', 'ساعة', 'h'), onChanged: (_) => _save(s)),
          Row(children: [
            Expanded(flex: 3, child: NumField(t('سعر اللتر', 'سعر اللتر', 'Price per litre'), priceC, onChanged: (_) => _save(s))),
            const SizedBox(width: 8),
            Expanded(flex: 2, child: HpTextField(t('العملة', 'العملة', 'Currency'), curC, onChanged: (_) => _save(s))),
          ]),
          if (kva) NoteBox(t('حوّلنا kVA لـ kW بمعامل قدرة 0.8 (المعتاد في لوحة المولدات).', 'حُوِّلت kVA إلى kW بمعامل قدرة 0.8 (المعتاد في لوحات المولدات).', 'kVA converted to kW using a 0.8 power factor (typical nameplate value).')),
        ]),
      ),
      StatGrid([
        StatChip(fmt(lph, 2), t('لتر/ساعة', 'لتر/ساعة', 'litres / hour'), color: SD.teal, icon: Icons.local_gas_station_rounded),
        StatChip(fmt(daily, 1), t('لتر في اليوم', 'لتر يوميًا', 'litres / day'), color: SD.nile, icon: Icons.today_rounded),
        StatChip(fmt(monthly, 0), t('لتر في الشهر', 'لتر شهريًا', 'litres / month'), color: SD.indigo, icon: Icons.calendar_month_rounded),
        StatChip(price > 0 ? fmt(daily * price, 0) : '—', '${t('تكلفة اليوم', 'تكلفة اليوم', 'cost / day')} ($cur)', color: SD.gold),
        StatChip(price > 0 ? fmt(monthly * price, 0) : '—', '${t('تكلفة الشهر', 'تكلفة الشهر', 'cost / month')} ($cur)', color: SD.henna),
        StatChip(perKwh == null ? '—' : fmt(perKwh, 1), '${t('الكيلوواط/ساعة', 'تكلفة ك.و.س', 'per kWh')} ($cur)', color: SD.orange),
      ]),
      const SizedBox(height: 14),
      SCard(
        title: t('الاستهلاك حسب الحمل', 'الاستهلاك حسب الحمل', 'Consumption by load'),
        icon: Icons.table_chart_rounded,
        color: SD.nile,
        child: Column(children: [
          for (final f in const [.25, .5, .75, 1.0])
            InfoRow(
              '${fmt(f * 100, 0)}% ${t('حمل', 'حمل', 'load')}',
              '${fmt(fuelLph(ratedKw: ratedKw, loadFrac: f, diesel: diesel), 2)} ${t('ل/س', 'ل/س', 'L/h')}${price > 0 ? ' · ${fmt(fuelLph(ratedKw: ratedKw, loadFrac: f, diesel: diesel) * hours * 30 * price, 0)} $cur/${t('شهر', 'شهر', 'mo')}' : ''}',
            ),
        ]),
      ),
      NoteBox(
        t('دا تقدير تقريبي من جداول الاستهلاك المعروفة (فرق ±20–30%). الاستهلاك الحقيقي بيعتمد على الماركة وحالة الماكينة والحرارة. أحسن طريقة: املأ التانك واحسب اللترات بعد عدد ساعات معروف.',
            'هذا تقدير تقريبي مبني على جداول الاستهلاك الشائعة (قد يختلف ±20–30%). الاستهلاك الفعلي يعتمد على الطراز وحالة المحرك والحرارة. الأدق: املأ الخزان وقِس اللترات بعد ساعات معروفة.',
            'This is an approximate estimate from common consumption tables (±20–30%). Real use depends on model, engine condition and heat. Most accurate: fill the tank and measure litres after known hours.'),
        kind: NoteKind.warn,
      ),
      SCard(
        title: t('عدّاد الساعات والزيت', 'عداد الساعات والزيت', 'Hour meter & oil'),
        icon: Icons.oil_barrel_rounded,
        color: SD.coffee,
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          HpBar(since / oilEvery,
              color: oilColor,
              left: t('ساعات من آخر غيار زيت', 'ساعات منذ آخر تغيير زيت', 'Hours since last oil change'),
              right: '${fmt(since, 1)} / ${fmt(oilEvery, 0)}'),
          const SizedBox(height: 8),
          InfoRow(
            t('الغيار الجاي بعد', 'التغيير القادم بعد', 'Next oil change in'),
            untilOil <= 0 ? t('فات وقتو — غيّر الزيت!', 'حان وقته — غيّر الزيت!', 'Due now — change the oil!') : '${fmt(untilOil, 1)} ${t('ساعة', 'ساعة', 'h')}',
            valueColor: oilColor,
            hint: daysToOil == null ? null : '≈ ${daysLabel(daysToOil)} ${t('بالتشغيل الحالي', 'بمعدل التشغيل الحالي', 'at current usage')}',
          ),
          InfoRow(t('مجموع الساعات المسجلة', 'إجمالي الساعات المسجلة', 'Total logged hours'), '${fmt(totalH, 1)} ${t('ساعة', 'ساعة', 'h')}'),
          InfoRow(t('آخر 7 أيام', 'آخر 7 أيام', 'Last 7 days'), '${fmt(h7, 1)} ${t('ساعة', 'ساعة', 'h')}'),
          NumField(t('غيّر الزيت كل', 'تغيير الزيت كل', 'Change oil every'), oilC, suffix: t('ساعة', 'ساعة', 'h'), hint: '100–250', onChanged: (_) => _save(s)),
          Row(children: [
            Expanded(
              child: FilledButton.icon(
                onPressed: () => _logHours(s, hours > 0 ? hours : 1),
                icon: const Icon(Icons.more_time_rounded),
                label: FittedBox(fit: BoxFit.scaleDown, child: Text(t('سجّل ساعات', 'سجّل ساعات', 'Log hours'), maxLines: 1)),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _oilChanged(s),
                icon: const Icon(Icons.oil_barrel_rounded),
                label: FittedBox(fit: BoxFit.scaleDown, child: Text(t('غيّرت الزيت', 'غيّرت الزيت', 'Oil changed'), maxLines: 1)),
              ),
            ),
          ]),
        ]),
      ),
      SCard(
        title: t('السجل', 'السجل', 'History'),
        icon: Icons.history_rounded,
        color: SD.nile,
        child: log.isEmpty
            ? EmptyHint(Icons.timer_outlined, t('سجّل ساعات التشغيل عشان نعرف موعد الزيت', 'سجّل ساعات التشغيل لمعرفة موعد الزيت', 'Log running hours to track oil changes'))
            : Column(children: [
                for (final e in log.reversed.take(60))
                  HpLogTile(
                    icon: e['k'] == 'oil' ? Icons.oil_barrel_rounded : Icons.timer_rounded,
                    color: e['k'] == 'oil' ? SD.gold : SD.teal,
                    title: e['k'] == 'oil' ? t('غيار زيت', 'تغيير زيت', 'Oil change') : '${fmt(numOf(e['h']), 1)} ${t('ساعة تشغيل', 'ساعة تشغيل', 'running hours')}',
                    sub: fmtDateAr(parseDk(e['d']) ?? pToday()),
                    onDelete: () => _delete(s, e),
                  ),
              ]),
      ),
      NoteBox(
        t('شغّل المولّد برّه البيت في مكان مفتوح — عادم المولد فيه أول أكسيد الكربون وممكن يقتل. وما تعبّي وقود والماكينة حارّة.',
            'شغّل المولد خارج المنزل في مكان مفتوح — العادم يحوي أول أكسيد الكربون القاتل. ولا تعبّئ الوقود والمحرك ساخن.',
            'Run the generator outdoors only — exhaust contains deadly carbon monoxide. Never refuel while the engine is hot.'),
        kind: NoteKind.danger,
      ),
      ShareBar(summary),
    ]);
  }
}
