import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/format.dart';
import '../../core/i18n.dart';
import '../../core/state.dart';
import '../../core/theme.dart';
import '../../core/widgets.dart';
import 'plan_common.dart';

class _Opt {
  final String key, emoji, sd, ar, en;
  final Color color;
  const _Opt(this.key, this.emoji, this.sd, this.ar, this.en, [this.color = SD.nile]);
  String get name => t(sd, ar, en);
}

const _transports = [
  _Opt('plane', '✈️', 'طيارة', 'طائرة', 'Plane'),
  _Opt('bus', '🚌', 'بص', 'حافلة', 'Bus'),
  _Opt('car', '🚗', 'عربية', 'سيارة', 'Car'),
  _Opt('train', '🚆', 'قطر', 'قطار', 'Train'),
  _Opt('ship', '⛴️', 'باخرة', 'سفينة', 'Ship'),
  _Opt('other', '🧭', 'غيرها', 'أخرى', 'Other'),
];

const _budgetCats = [
  _Opt('transport', '🚌', 'المواصلات والتذاكر', 'النقل والتذاكر', 'Transport', SD.nile),
  _Opt('stay', '🏨', 'السكن', 'الإقامة', 'Stay', SD.indigo),
  _Opt('food', '🍲', 'الأكل', 'الطعام', 'Food', SD.orange),
  _Opt('gifts', '🎁', 'الهدايا', 'الهدايا', 'Gifts', SD.pink),
  _Opt('visas', '🛂', 'الفيزا والرسوم', 'التأشيرات والرسوم', 'Visas & fees', SD.teal),
  _Opt('other', '📦', 'حاجات تانية', 'أخرى', 'Other', SD.brownLight),
];

_Opt _tr(String? k) => _transports.firstWhere((x) => x.key == k, orElse: () => _transports.last);

List<String> get _defaultDocs => [
      t('الجواز (صالح لـ 6 شهور على الأقل)', 'جواز السفر (صالح 6 أشهر على الأقل)', 'Passport (valid 6+ months)'),
      t('الفيزا/التأشيرة', 'التأشيرة', 'Visa'),
      t('تذاكر السفر', 'تذاكر السفر', 'Tickets'),
      t('حجز السكن', 'حجز الإقامة', 'Accommodation booking'),
      t('البطاقة القومية', 'بطاقة الهوية', 'National ID'),
      t('كرت التطعيم (الحمى الصفراء لو مطلوب)', 'شهادة التطعيم (إن طُلبت)', 'Vaccination card (if required)'),
      t('التأمين الصحي للسفر', 'تأمين السفر الصحي', 'Travel health insurance'),
      t('صور شخصية + نسخ من الأوراق', 'صور شخصية ونسخ من المستندات', 'Photos & document copies'),
    ];

class TripPlanTool extends StatefulWidget {
  const TripPlanTool({super.key});
  @override
  State<TripPlanTool> createState() => _TripPlanToolState();
}

class _TripPlanToolState extends State<TripPlanTool> {
  List<Map<String, dynamic>> _trips(AppState s) => mapList(s.getData<List>('trip_plan_list'));
  String? _selId(AppState s) => s.getData<String>('trip_plan_sel');

  Map<String, dynamic>? _cur(AppState s) {
    final l = _trips(s);
    if (l.isEmpty) return null;
    return l.firstWhere((x) => x['id'] == _selId(s), orElse: () => l.first);
  }

  void _put(AppState s, Map<String, dynamic> trip) {
    final l = _trips(s);
    final i = l.indexWhere((x) => x['id'] == trip['id']);
    if (i >= 0) {
      l[i] = trip;
    } else {
      l.add(trip);
    }
    s.setData('trip_plan_list', l);
  }

  Future<void> _editTrip([Map<String, dynamic>? tp]) async {
    final s = context.read<AppState>();
    final nC = TextEditingController(text: tp?['name'] ?? '');
    final curC = TextEditingController(text: (tp?['cur'] as String?) ?? tr('ج.س', 'SDG'));
    final today = todayPlace();
    DateTime? start = parseDk(tp?['start']), end = parseDk(tp?['end']);
    final ok = await lifeSheet<bool>(
      context,
      tp == null ? t('رحلة جديدة', 'رحلة جديدة', 'New trip') : t('عدّل الرحلة', 'تعديل الرحلة', 'Edit trip'),
      (ctx, set) => Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        TextField(controller: nC, decoration: InputDecoration(labelText: t('اسم الرحلة', 'اسم الرحلة', 'Trip name'), hintText: t('مثلًا: عمرة رمضان، زيارة القاهرة', 'مثلًا: عمرة رمضان', 'e.g. Umrah, Cairo visit'))),
        const SizedBox(height: 10),
        LifeDateButton(label: t('يوم السفر', 'تاريخ المغادرة', 'Start date'), value: start, onPick: (d) => set(() => start = d), color: SD.nile, first: DateTime(today.year - 1), last: DateTime(today.year + 5)),
        const SizedBox(height: 8),
        LifeDateButton(label: t('يوم الرجوع', 'تاريخ العودة', 'End date'), value: end, onPick: (d) => set(() => end = d), color: SD.henna, first: DateTime(today.year - 1), last: DateTime(today.year + 5), clearable: true),
        const SizedBox(height: 10),
        TextField(controller: curC, decoration: InputDecoration(labelText: t('عملة الميزانية', 'عملة الميزانية', 'Budget currency label'))),
        const SizedBox(height: 16),
        sheetButtons(ctx, onSave: () {
          if (nC.text.trim().isEmpty) return toast(t('أكتب اسم الرحلة', 'اكتب اسم الرحلة', 'Enter a trip name'));
          if (start == null) return toast(t('اختار يوم السفر', 'اختر تاريخ المغادرة', 'Pick a start date'));
          Navigator.pop(ctx, true);
        }, onDelete: tp == null ? null : () => Navigator.pop(ctx, false)),
      ]),
    );
    final name = nC.text.trim(), cur = curC.text.trim();
    nC.dispose();
    curC.dispose();
    if (!mounted || ok == null) return;
    if (ok == false && tp != null) {
      if (!await confirmAsk(context, t('تمسح الرحلة؟', 'حذف الرحلة؟', 'Delete trip?'), '${tp['name']}')) return;
      s.setData('trip_plan_list', _trips(s)..removeWhere((x) => x['id'] == tp['id']));
      return;
    }
    if (end != null && end!.isBefore(start!)) end = start;
    final data = <String, dynamic>{...?tp, 'name': name, 'cur': cur, 'start': dk(start!), 'end': end == null ? null : dk(end!)};
    if (tp == null) {
      data['id'] = newId();
      data['stops'] = <Map>[];
      data['days'] = <String, dynamic>{};
      data['budget'] = <String, dynamic>{};
      data['docs'] = [for (final d in _defaultDocs) {'id': newId(), 'n': d, 'done': false}];
      s.award(5, tr('رحلة جديدة', 'New trip'));
    }
    _put(s, data);
    s.setData('trip_plan_sel', data['id']);
  }

  Future<void> _editStop(Map<String, dynamic> tp, [Map<String, dynamic>? st]) async {
    final s = context.read<AppState>();
    final pC = TextEditingController(text: st?['place'] ?? '');
    final refC = TextEditingController(text: st?['ref'] ?? '');
    final noteC = TextEditingController(text: st?['notes'] ?? '');
    var tr0 = (st?['tr'] as String?) ?? 'plane';
    DateTime? from = parseDk(st?['from']) ?? parseDk(tp['start']), to = parseDk(st?['to']);
    final today = todayPlace();
    final ok = await lifeSheet<bool>(
      context,
      st == null ? t('محطة جديدة', 'محطة جديدة', 'New stop') : t('عدّل المحطة', 'تعديل المحطة', 'Edit stop'),
      (ctx, set) => Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        TextField(controller: pC, decoration: InputDecoration(labelText: t('المكان', 'الوجهة', 'Place'), hintText: t('مثلًا: بورتسودان، جدة، القاهرة', 'مثلًا: جدة، القاهرة', 'e.g. Jeddah, Cairo'))),
        const SizedBox(height: 10),
        LifeDateButton(label: t('من', 'من', 'From'), value: from, onPick: (d) => set(() => from = d), color: SD.nile, first: DateTime(today.year - 1), last: DateTime(today.year + 5)),
        const SizedBox(height: 8),
        LifeDateButton(label: t('لحدي', 'إلى', 'To'), value: to, onPick: (d) => set(() => to = d), color: SD.henna, clearable: true, first: DateTime(today.year - 1), last: DateTime(today.year + 5)),
        const SizedBox(height: 10),
        Text(t('وسيلة السفر', 'وسيلة النقل', 'Transport'), style: const TextStyle(fontWeight: FontWeight.w700)),
        const SizedBox(height: 6),
        Wrap(spacing: 6, runSpacing: 6, children: [
          for (final o in _transports) PickChip('${o.emoji} ${o.name}', tr0 == o.key, () => set(() => tr0 = o.key), color: SD.nile),
        ]),
        const SizedBox(height: 10),
        TextField(controller: refC, decoration: InputDecoration(labelText: t('رقم الحجز (اختياري)', 'رقم الحجز (اختياري)', 'Booking ref (optional)'))),
        const SizedBox(height: 10),
        TextField(controller: noteC, minLines: 1, maxLines: 4, decoration: InputDecoration(labelText: t('ملاحظات', 'ملاحظات', 'Notes'))),
        const SizedBox(height: 16),
        sheetButtons(ctx, onSave: () {
          if (pC.text.trim().isEmpty) return toast(t('أكتب المكان', 'اكتب الوجهة', 'Enter the place'));
          Navigator.pop(ctx, true);
        }, onDelete: st == null ? null : () => Navigator.pop(ctx, false)),
      ]),
    );
    final place = pC.text.trim(), ref = refC.text.trim(), notes = noteC.text.trim();
    pC.dispose();
    refC.dispose();
    noteC.dispose();
    if (!mounted || ok == null) return;
    final stops = mapList(tp['stops']);
    if (ok == false && st != null) {
      stops.removeWhere((x) => x['id'] == st['id']);
    } else {
      final data = {'place': place, 'from': from == null ? null : dk(from!), 'to': to == null ? null : dk(to!), 'tr': tr0, 'ref': ref, 'notes': notes};
      if (st == null) {
        stops.add({'id': newId(), ...data});
      } else {
        final i = stops.indexWhere((x) => x['id'] == st['id']);
        if (i >= 0) stops[i] = {...stops[i], ...data};
      }
    }
    stops.sort((a, b) => ((a['from'] as String?) ?? '').compareTo((b['from'] as String?) ?? ''));
    _put(s, {...tp, 'stops': stops});
    s.awardDaily('trip_plan', 3, tr('تخطيط رحلة', 'Trip planning'));
  }

  Future<void> _editBudget(Map<String, dynamic> tp, _Opt c) async {
    final s = context.read<AppState>();
    final b = Map<String, dynamic>.from(tp['budget'] as Map? ?? const {});
    final cur = Map<String, dynamic>.from(b[c.key] as Map? ?? const {});
    final pC = TextEditingController(text: rawNum(numOf(cur['plan'])));
    final sC = TextEditingController(text: rawNum(numOf(cur['spent'])));
    final ok = await lifeSheet<bool>(
      context,
      '${c.emoji} ${c.name}',
      (ctx, set) => Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        NumField(t('المخطط', 'المخطط', 'Planned'), pC, suffix: tp['cur']),
        NumField(t('الصرفته فعلًا', 'المصروف فعليًا', 'Spent'), sC, suffix: tp['cur']),
        const SizedBox(height: 8),
        sheetButtons(ctx, onSave: () => Navigator.pop(ctx, true)),
      ]),
    );
    final plan = parseNum(pC.text), spent = parseNum(sC.text);
    pC.dispose();
    sC.dispose();
    if (ok != true || !mounted) return;
    b[c.key] = {'plan': plan, 'spent': spent};
    _put(s, {...tp, 'budget': b});
  }

  Future<void> _editDay(Map<String, dynamic> tp, DateTime d) async {
    final s = context.read<AppState>();
    final days = Map<String, dynamic>.from(tp['days'] as Map? ?? const {});
    final v = await askMultiline(context, fmtDateAr(d), initial: (days[dk(d)] as String?) ?? '', hint: t('برنامج اليوم: زيارة، مشوار، موعد…', 'برنامج اليوم: زيارة، موعد…', 'Plan for the day: visits, errands…'));
    if (v == null || !mounted) return;
    if (v.trim().isEmpty) {
      days.remove(dk(d));
    } else {
      days[dk(d)] = v.trim();
    }
    _put(s, {...tp, 'days': days});
  }

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final trips = _trips(s);
    final tp = _cur(s);
    return ToolList(children: [
      SizedBox(
        height: 48,
        child: ListView(scrollDirection: Axis.horizontal, children: [
          for (final x in trips)
            Padding(
              padding: const EdgeInsetsDirectional.only(end: 6),
              child: PickChip('🧳 ${x['name']}', x['id'] == tp?['id'], () => s.setData('trip_plan_sel', x['id']), color: SD.nile),
            ),
          ActionChip(avatar: const Icon(Icons.add_rounded, size: 18), label: Text(t('رحلة جديدة', 'رحلة جديدة', 'New trip')), onPressed: () => _editTrip()),
        ]),
      ),
      const SizedBox(height: 8),
      if (tp == null)
        SCard(
          title: t('مخطط الرحلة', 'مخطط الرحلة', 'Trip planner'),
          icon: Icons.flight_takeoff_rounded,
          color: SD.nile,
          child: EmptyHint(
            Icons.luggage_outlined,
            t('خطّط سفرك: المحطات، برنامج كل يوم، الميزانية، والأوراق المطلوبة — كلو في مكان واحد.', 'خطّط رحلتك: المحطات وبرنامج كل يوم والميزانية والمستندات في مكان واحد.',
                'Plan your trip: stops, day-by-day itinerary, budget and documents — all in one place.'),
            action: FilledButton.icon(onPressed: () => _editTrip(), icon: const Icon(Icons.add_rounded), label: Text(t('أضف رحلة', 'أضف رحلة', 'Add a trip'))),
          ),
        )
      else
        ..._detail(s, tp),
      NoteBox(
        t('للشنطة وتجهيز الحاجات استعمل أداة «قائمة تجهيز السفر» في التطبيق.', 'لتجهيز الحقيبة استخدم أداة «قائمة تجهيز السفر» في التطبيق.',
            'For packing, use the app\'s «Travel Packing List» tool.'),
        kind: NoteKind.tip,
      ),
      NoteBox(
        t('شروط الفيزا والتطعيمات والجواز بتختلف من بلد لبلد وبتتغير — اتأكد من السفارة أو الجهة الرسمية قبل السفر.',
            'تختلف شروط التأشيرة والتطعيمات وصلاحية الجواز بين الدول وتتغير؛ تحقّق من السفارة أو الجهة الرسمية قبل السفر.',
            'Visa, vaccination and passport rules differ by country and change — confirm with the embassy or official source before you travel.'),
        kind: NoteKind.warn,
      ),
    ]);
  }

  List<Widget> _detail(AppState s, Map<String, dynamic> tp) {
    final today = todayPlace();
    final start = parseDk(tp['start']) ?? today;
    final end = parseDk(tp['end']);
    final cur = (tp['cur'] as String?) ?? '';
    final toStart = dayDiff(today, start);
    final nDays = end == null ? 1 : dayDiff(start, end) + 1;
    final stops = mapList(tp['stops']);
    final days = Map<String, dynamic>.from(tp['days'] as Map? ?? const {});
    final budget = Map<String, dynamic>.from(tp['budget'] as Map? ?? const {});
    final docs = mapList(tp['docs']);
    double planOf(String k) => numOf((budget[k] as Map?)?['plan']);
    double spentOf(String k) => numOf((budget[k] as Map?)?['spent']);
    final totalPlan = _budgetCats.fold(0.0, (a, c) => a + planOf(c.key));
    final totalSpent = _budgetCats.fold(0.0, (a, c) => a + spentOf(c.key));
    final docsDone = docs.where((d) => d['done'] == true).length;

    final String heroValue, heroLabel;
    if (toStart > 0) {
      heroLabel = t('فاضل على السفر', 'متبقٍ على السفر', 'Days until departure');
      heroValue = '$toStart ${t('يوم', 'يومًا', toStart == 1 ? 'day' : 'days')}';
    } else if (end != null && !today.isAfter(end)) {
      heroLabel = t('إنت في الرحلة', 'الرحلة جارية', 'Trip in progress');
      heroValue = '${t('اليوم', 'اليوم', 'Day')} ${-toStart + 1} / $nDays';
    } else if (toStart == 0) {
      heroLabel = t('السفر الليلة!', 'السفر اليوم!', 'Departure today!');
      heroValue = '✈️';
    } else {
      heroLabel = t('الرحلة انتهت', 'انتهت الرحلة', 'Trip finished');
      heroValue = '✓';
    }

    String itinerary() {
      final b = StringBuffer('🧳 ${tp['name']}\n📅 ${fmtDateAr(start, weekday: false)}${end == null ? '' : ' → ${fmtDateAr(end, weekday: false)}'}\n');
      if (stops.isNotEmpty) {
        b.writeln('\n${t('المحطات', 'المحطات', 'Stops')}:');
        for (final st in stops) {
          final f = parseDk(st['from']), to = parseDk(st['to']);
          b.writeln('${_tr(st['tr']).emoji} ${st['place']}${f == null ? '' : ' — ${fmtShort(f)}'}${to == null ? '' : ' → ${fmtShort(to)}'}'
              '${((st['ref'] as String?) ?? '').isEmpty ? '' : ' (${t('حجز', 'حجز', 'ref')}: ${st['ref']})'}');
        }
      }
      if (end != null) {
        final dayLines = <String>[];
        for (var i = 0; i < nDays && i < 90; i++) {
          final d = start.add(Duration(days: i));
          final txt = days[dk(d)] as String?;
          if (txt != null && txt.isNotEmpty) dayLines.add('• ${fmtDateAr(d)}: ${txt.replaceAll('\n', ' / ')}');
        }
        if (dayLines.isNotEmpty) b.writeln('\n${t('البرنامج', 'البرنامج اليومي', 'Itinerary')}:\n${dayLines.join('\n')}');
      }
      if (totalPlan > 0) b.writeln('\n${t('الميزانية', 'الميزانية', 'Budget')}: ${money(totalSpent, cur)} / ${money(totalPlan, cur)}');
      return b.toString().trim();
    }

    return [
      ResultHero(
        label: heroLabel,
        value: heroValue,
        sub: '${tp['name']} · ${fmtShort(start)}${end == null ? '' : ' → ${fmtShort(end)}'} · $nDays ${t('يوم', 'يوم', 'days')}',
        colors: const [SD.nile, SD.indigo, SD.brownDeep],
      ),
      ActionRow([
        MiniAction(Icons.add_location_alt_rounded, t('محطة', 'محطة', 'Stop'), () => _editStop(tp), color: SD.nile),
        MiniAction(Icons.edit_rounded, t('تعديل', 'تعديل', 'Edit'), () => _editTrip(tp), color: SD.gold),
      ]),
      SCard(
        title: t('المحطات', 'المحطات', 'Stops'),
        icon: Icons.route_rounded,
        color: SD.nile,
        child: stops.isEmpty
            ? Text(t('أضف المدن اللي حتمشي ليها بالتواريخ ووسيلة السفر.', 'أضف الوجهات بتواريخها ووسيلة النقل.', 'Add destinations with dates and transport.'))
            : Column(children: [
                for (final st in stops)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    onTap: () => _editStop(tp, st),
                    leading: Text(_tr(st['tr']).emoji, style: const TextStyle(fontSize: 24)),
                    title: Text('${st['place']}', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w800)),
                    subtitle: Text(
                      [
                        if (parseDk(st['from']) != null) '${fmtShort(parseDk(st['from'])!)}${parseDk(st['to']) == null ? '' : ' → ${fmtShort(parseDk(st['to'])!)}'}',
                        _tr(st['tr']).name,
                        if (((st['ref'] as String?) ?? '').isNotEmpty) '${t('حجز', 'حجز', 'Ref')}: ${st['ref']}',
                        if (((st['notes'] as String?) ?? '').isNotEmpty) st['notes'],
                      ].join(' · '),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
              ]),
      ),
      SCard(
        title: t('برنامج كل يوم', 'البرنامج اليومي', 'Day-by-day itinerary'),
        icon: Icons.view_agenda_rounded,
        color: SD.teal,
        child: end == null
            ? Text(t('حدّد يوم الرجوع عشان يظهر برنامج الأيام.', 'حدّد تاريخ العودة لإظهار البرنامج اليومي.', 'Set an end date to plan each day.'))
            : Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                for (var i = 0; i < nDays && i < 60; i++)
                  Builder(builder: (context) {
                    final d = start.add(Duration(days: i));
                    final txt = (days[dk(d)] as String?) ?? '';
                    return InkWell(
                      onTap: () => _editDay(tp, d),
                      borderRadius: BorderRadius.circular(12),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Container(
                            width: 44,
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            decoration: BoxDecoration(color: (d == today ? SD.gold : SD.teal).withValues(alpha: .18), borderRadius: BorderRadius.circular(10)),
                            child: Column(children: [
                              FittedBox(fit: BoxFit.scaleDown, child: Text('${i + 1}', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16))),
                              FittedBox(fit: BoxFit.scaleDown, child: Text(shortDaysL[d.weekday - 1], style: const TextStyle(fontSize: 11))),
                            ]),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              Text(fmtDateAr(d, weekday: false), maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                              Text(txt.isEmpty ? t('دوس عشان تكتب البرنامج', 'اضغط لكتابة البرنامج', 'Tap to add plans') : txt,
                                  maxLines: 4, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 13.5, color: txt.isEmpty ? Colors.grey : null)),
                            ]),
                          ),
                        ]),
                      ),
                    );
                  }),
                if (nDays > 60) Text(t('بيظهر أول 60 يوم بس', 'تظهر أول 60 يومًا فقط', 'Only the first 60 days are shown'), style: const TextStyle(fontSize: 11.5)),
              ]),
      ),
      SCard(
        title: t('الميزانية', 'الميزانية', 'Budget'),
        icon: Icons.account_balance_wallet_rounded,
        color: SD.gold,
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          StatGrid([
            StatChip(fmt(totalPlan, 0), t('المخطط', 'المخطط', 'Planned'), color: SD.nile),
            StatChip(fmt(totalSpent, 0), t('المصروف', 'المصروف', 'Spent'), color: totalPlan > 0 && totalSpent > totalPlan ? SD.red : SD.green),
            StatChip(fmt(totalPlan - totalSpent, 0), t('الباقي', 'المتبقي', 'Left'), color: SD.orange),
          ]),
          const SizedBox(height: 8),
          for (final c in _budgetCats)
            InkWell(
              onTap: () => _editBudget(tp, c),
              child: PercentBar(
                '${c.emoji} ${c.name}',
                planOf(c.key) <= 0 ? (spentOf(c.key) > 0 ? 1 : 0) : spentOf(c.key) / planOf(c.key),
                '${fmt(spentOf(c.key), 0)} / ${fmt(planOf(c.key), 0)}',
                color: planOf(c.key) > 0 && spentOf(c.key) > planOf(c.key) ? SD.red : c.color,
              ),
            ),
          Text('${t('دوس على أي بند عشان تعدّله', 'اضغط على أي بند لتعديله', 'Tap a category to edit')} · $cur', style: const TextStyle(fontSize: 11.5)),
        ]),
      ),
      SCard(
        title: t('الأوراق والمستندات', 'المستندات', 'Documents checklist'),
        icon: Icons.badge_rounded,
        color: SD.henna,
        trailing: Tag('$docsDone/${docs.length}', color: docsDone == docs.length && docs.isNotEmpty ? SD.green : SD.henna),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          for (final d in docs)
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              dense: true,
              controlAffinity: ListTileControlAffinity.leading,
              value: d['done'] == true,
              title: Text('${d['n']}', maxLines: 2, overflow: TextOverflow.ellipsis,
                  style: TextStyle(decoration: d['done'] == true ? TextDecoration.lineThrough : null)),
              secondary: IconButton(
                visualDensity: VisualDensity.compact,
                icon: const Icon(Icons.close_rounded, size: 18),
                tooltip: t('امسح', 'حذف', 'Remove'),
                onPressed: () => _put(s, {...tp, 'docs': docs.where((x) => x['id'] != d['id']).toList()}),
              ),
              onChanged: (v) => _put(s, {...tp, 'docs': [for (final x in docs) x['id'] == d['id'] ? {...x, 'done': v == true} : x]}),
            ),
          TextButton.icon(
            onPressed: () async {
              final v = await askText(context, t('مستند جديد', 'مستند جديد', 'New document'));
              if (v == null || v.trim().isEmpty) return;
              _put(s, {...tp, 'docs': [...docs, {'id': newId(), 'n': v.trim(), 'done': false}]});
            },
            icon: const Icon(Icons.add_rounded),
            label: Text(t('أضف مستند', 'إضافة مستند', 'Add document')),
          ),
        ]),
      ),
      ShareBar(itinerary),
      const SizedBox(height: 8),
    ];
  }
}
