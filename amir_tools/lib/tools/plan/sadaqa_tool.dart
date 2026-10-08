import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../core/format.dart';
import '../../core/i18n.dart';
import '../../core/state.dart';
import '../../core/theme.dart';
import '../../core/widgets.dart';
import 'plan_common.dart';

class _SCat {
  final String key, emoji, sd, ar, en;
  final Color color;
  const _SCat(this.key, this.emoji, this.sd, this.ar, this.en, this.color);
  String get name => t(sd, ar, en);
}

const _cats = [
  _SCat('family', '👨‍👩‍👧', 'الأهل والأقارب', 'الأقارب', 'Family & relatives', SD.green),
  _SCat('needy', '🤲', 'المحتاجين', 'الفقراء والمساكين', 'The needy', SD.nile),
  _SCat('mosque', '🕌', 'المسجد/الخلوة', 'المساجد', 'Mosque', SD.teal),
  _SCat('orphans', '🧒', 'الأيتام', 'الأيتام', 'Orphans', SD.orange),
  _SCat('other', '💝', 'حاجات تانية', 'أخرى', 'Other', SD.purple),
];

_SCat _cat(String? k) => _cats.firstWhere((c) => c.key == k, orElse: () => _cats.last);

/// نصوص ثابتة صحيحة مع مصدرها
class _Text {
  final String ar, srcAr, srcEn, en;
  const _Text(this.ar, this.srcAr, this.srcEn, this.en);
}

const _texts = [
  _Text('«مَا نَقَصَتْ صَدَقَةٌ مِنْ مَالٍ»', 'رواه مسلم (2588)', 'Sahih Muslim 2588', 'Charity does not decrease wealth.'),
  _Text('«اتَّقُوا النَّارَ وَلَوْ بِشِقِّ تَمْرَةٍ»', 'متفق عليه: البخاري (1417) ومسلم (1016)', 'Bukhari 1417, Muslim 1016', 'Protect yourselves from the Fire, even with half a date.'),
  _Text('﴿مَّثَلُ الَّذِينَ يُنفِقُونَ أَمْوَالَهُمْ فِي سَبِيلِ اللَّهِ كَمَثَلِ حَبَّةٍ أَنبَتَتْ سَبْعَ سَنَابِلَ فِي كُلِّ سُنبُلَةٍ مِّائَةُ حَبَّةٍ﴾',
      'سورة البقرة: 261', "Qur'an, al-Baqarah 2:261", 'Spending in the way of Allah is like a grain that sprouts seven ears, each with a hundred grains.'),
  _Text('﴿لَن تَنَالُوا الْبِرَّ حَتَّىٰ تُنفِقُوا مِمَّا تُحِبُّونَ﴾', 'سورة آل عمران: 92', "Qur'an, Al Imran 3:92", 'You will never attain righteousness until you spend from what you love.'),
  _Text('﴿الَّذِينَ يُنفِقُونَ أَمْوَالَهُم بِاللَّيْلِ وَالنَّهَارِ سِرًّا وَعَلَانِيَةً فَلَهُمْ أَجْرُهُمْ عِندَ رَبِّهِمْ وَلَا خَوْفٌ عَلَيْهِمْ وَلَا هُمْ يَحْزَنُونَ﴾',
      'سورة البقرة: 274', "Qur'an, al-Baqarah 2:274", 'Those who spend by night and day, secretly and openly, have their reward with their Lord.'),
];

class SadaqaTool extends StatefulWidget {
  const SadaqaTool({super.key});
  @override
  State<SadaqaTool> createState() => _SadaqaToolState();
}

class _SadaqaToolState extends State<SadaqaTool> {
  late int _y, _m;
  late int _textI;

  @override
  void initState() {
    super.initState();
    final n = todayPlace();
    _y = n.year;
    _m = n.month;
    _textI = n.day % _texts.length;
  }

  void _shift(int by) {
    final (y, m) = shiftMonth(_y, _m, by);
    setState(() {
      _y = y;
      _m = m;
    });
  }

  Map<String, dynamic> _cfg(AppState s) => Map<String, dynamic>.from(s.getData<Map>('sadaqa_cfg') ?? const {});
  List<Map<String, dynamic>> _log(AppState s) => mapList(s.getData<List>('sadaqa_log'));
  String _cur(AppState s) => (_cfg(s)['cur'] as String?) ?? tr('ج.س', 'SDG');

  /// المبلغ المخطّط للشهر
  double _plan(Map<String, dynamic> c) =>
      c['mode'] == 'fixed' ? numOf(c['fixed']) : numOf(c['income']) * numOf(c['pct']) / 100;

  /// عدد الشهور المتتالية التي فيها صدقة (ينتهي بالشهر الحالي أو الذي قبله)
  int _streak(List<Map<String, dynamic>> l) {
    final months = l.map((e) => ((e['d'] as String?) ?? '').length >= 7 ? (e['d'] as String).substring(0, 7) : '').toSet();
    final n = todayPlace();
    var (y, m) = (n.year, n.month);
    if (!months.contains(mk(y, m))) (y, m) = shiftMonth(y, m, -1);
    var c = 0;
    while (months.contains(mk(y, m)) && c < 600) {
      c++;
      (y, m) = shiftMonth(y, m, -1);
    }
    return c;
  }

  Future<void> _setup() async {
    final s = context.read<AppState>();
    final c = _cfg(s);
    var mode = (c['mode'] as String?) ?? 'pct';
    final incomeC = TextEditingController(text: rawNum(numOf(c['income'])));
    final pctC = TextEditingController(text: rawNum(numOf(c['pct'], 2.5)));
    final fixedC = TextEditingController(text: rawNum(numOf(c['fixed'])));
    final curC = TextEditingController(text: _cur(s));
    final ok = await lifeSheet<bool>(
      context,
      t('خطة الصدقة الشهرية', 'خطة الصدقة الشهرية', 'Monthly charity plan'),
      (ctx, set) => Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Wrap(spacing: 6, runSpacing: 6, children: [
          PickChip(t('نسبة من الدخل', 'نسبة من الدخل', '% of income'), mode == 'pct', () => set(() => mode = 'pct')),
          PickChip(t('مبلغ ثابت', 'مبلغ ثابت', 'Fixed amount'), mode == 'fixed', () => set(() => mode = 'fixed')),
        ]),
        const SizedBox(height: 12),
        if (mode == 'pct') ...[
          NumField(t('دخلك في الشهر', 'الدخل الشهري', 'Monthly income'), incomeC),
          NumField(t('النسبة اللي دايرها', 'النسبة المختارة', 'Chosen percentage'), pctC, suffix: '%'),
        ] else
          NumField(t('المبلغ في الشهر', 'المبلغ الشهري', 'Amount per month'), fixedC),
        TextField(controller: curC, decoration: InputDecoration(labelText: t('العملة', 'العملة', 'Currency label'), hintText: 'SDG, \$, SAR')),
        const SizedBox(height: 8),
        Text(t('النسبة دي اختيارك إنت — ما في نسبة محددة للصدقة التطوعية.', 'النسبة اختيارية؛ لا توجد نسبة محدّدة للصدقة التطوعية.', 'The percentage is your choice — voluntary charity has no fixed rate.'),
            style: const TextStyle(fontSize: 12)),
        const SizedBox(height: 16),
        sheetButtons(ctx, onSave: () => Navigator.pop(ctx, true)),
      ]),
    );
    final data = {'mode': mode, 'income': parseNum(incomeC.text), 'pct': parseNum(pctC.text), 'fixed': parseNum(fixedC.text), 'cur': curC.text.trim()};
    incomeC.dispose();
    pctC.dispose();
    fixedC.dispose();
    curC.dispose();
    if (ok != true || !mounted) return;
    s.setData('sadaqa_cfg', {...c, ...data});
    setState(() {});
  }

  Future<void> _edit([Map<String, dynamic>? e]) async {
    final s = context.read<AppState>();
    final aC = TextEditingController(text: e == null ? '' : rawNum(numOf(e['a'])));
    final toC = TextEditingController(text: e?['to'] ?? '');
    final noteC = TextEditingController(text: e?['note'] ?? '');
    var cat = (e?['cat'] as String?) ?? 'needy';
    final now = todayPlace();
    var date = parseDk(e?['d']) ?? ((_y == now.year && _m == now.month) ? now : DateTime(_y, _m, 1));
    final cur = _cur(s);
    final ok = await lifeSheet<bool>(
      context,
      e == null ? t('سجّل صدقة', 'تسجيل صدقة', 'Log charity') : t('عدّل الصدقة', 'تعديل الصدقة', 'Edit entry'),
      (ctx, set) => Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        NumField(t('المبلغ', 'المبلغ', 'Amount'), aC, suffix: cur),
        Wrap(spacing: 6, runSpacing: 6, children: [
          for (final c in _cats) PickChip('${c.emoji} ${c.name}', cat == c.key, () => set(() => cat = c.key), color: c.color),
        ]),
        const SizedBox(height: 12),
        TextField(controller: toC, decoration: InputDecoration(labelText: t('لمنو؟ (اختياري)', 'لمن؟ (اختياري)', 'To whom? (optional)'))),
        const SizedBox(height: 10),
        TextField(controller: noteC, decoration: InputDecoration(labelText: t('ملاحظة (اختياري)', 'ملاحظة (اختياري)', 'Note (optional)'))),
        const SizedBox(height: 12),
        LifeDateButton(label: t('التاريخ', 'التاريخ', 'Date'), value: date, onPick: (d) => set(() => date = d ?? date), color: SD.nile, last: now.add(const Duration(days: 1))),
        const SizedBox(height: 16),
        sheetButtons(ctx, onSave: () {
          if (parseNum(aC.text) <= 0) return toast(t('أكتب المبلغ', 'اكتب المبلغ', 'Enter the amount'));
          Navigator.pop(ctx, true);
        }, onDelete: e == null ? null : () => Navigator.pop(ctx, false)),
      ]),
    );
    final a = parseNum(aC.text), to = toC.text.trim(), note = noteC.text.trim();
    aC.dispose();
    toC.dispose();
    noteC.dispose();
    if (!mounted || ok == null) return;
    final l = _log(s);
    if (ok == false && e != null) {
      l.removeWhere((x) => x['id'] == e['id']);
    } else {
      final data = {'a': a, 'cat': cat, 'to': to, 'note': note, 'd': dk(date)};
      if (e == null) {
        l.add({'id': newId(), ...data});
        s.awardDaily('sadaqa_log', 5, tr('صدقة', 'Charity'));
        s.bump('sadaqa');
        HapticFeedback.selectionClick();
      } else {
        final i = l.indexWhere((x) => x['id'] == e['id']);
        if (i >= 0) l[i] = {...l[i], ...data};
      }
    }
    s.setData('sadaqa_log', l);
    setState(() {
      _y = date.year;
      _m = date.month;
    });
  }

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final cfg = _cfg(s);
    final cur = _cur(s);
    final plan = _plan(cfg);
    final log = _log(s);
    final month = log.where((e) => ((e['d'] as String?) ?? '').startsWith(mk(_y, _m))).toList()
      ..sort((a, b) => ((b['d'] as String?) ?? '').compareTo((a['d'] as String?) ?? ''));
    final given = month.fold(0.0, (a, e) => a + numOf(e['a']));
    final yearTotal = log.where((e) => ((e['d'] as String?) ?? '').startsWith('$_y-')).fold(0.0, (a, e) => a + numOf(e['a']));
    final monthsWithGiving = {
      for (final e in log)
        if (((e['d'] as String?) ?? '').startsWith('$_y-')) (e['d'] as String).substring(0, 7)
    }.length;
    final streak = _streak(log);
    final byCat = <String, double>{};
    for (final e in month) {
      byCat[_cat(e['cat']).key] = (byCat[_cat(e['cat']).key] ?? 0) + numOf(e['a']);
    }
    final tx = _texts[_textI % _texts.length];
    final today = todayPlace();

    String summary() {
      final b = StringBuffer('🤲 ${t('صدقة شهر', 'صدقة شهر', 'Charity for')} ${fmtMonth(_y, _m)}\n');
      b.writeln('${t('اتصدّقت بـ', 'المُتصدَّق به', 'Given')}: ${money(given, cur)}${plan > 0 ? ' / ${money(plan, cur)}' : ''}');
      for (final c in _cats) {
        if ((byCat[c.key] ?? 0) > 0) b.writeln('${c.emoji} ${c.name}: ${money(byCat[c.key]!, cur)}');
      }
      b.writeln('${t('مجموع سنة', 'إجمالي سنة', 'Total for')} $_y: ${money(yearTotal, cur)}');
      b.writeln('\n${tx.ar} — ${tx.srcAr}');
      return b.toString().trim();
    }

    return ToolList(children: [
      PeriodNav(fmtMonth(_y, _m),
          onPrev: () => _shift(-1),
          onNext: () => _shift(1),
          onReset: () => setState(() {
                _y = today.year;
                _m = today.month;
              })),
      ResultHero(
        label: t('اتصدّقت الشهر دا', 'صدقة هذا الشهر', 'Given this month'),
        value: money(given, cur),
        sub: plan > 0 ? '${t('الخطة', 'الخطة', 'Plan')}: ${money(plan, cur)} · ${fmt(given / plan * 100, 0)}%' : t('حدّد خطة شهرية تحت', 'حدّد خطة شهرية بالأسفل', 'Set a monthly plan below'),
        colors: const [SD.teal, SD.nile, SD.indigo],
      ),
      FilledButton.icon(
        style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14)),
        onPressed: () => _edit(),
        icon: const Icon(Icons.volunteer_activism_rounded),
        label: Text(t('سجّل صدقة', 'سجّل صدقة', 'Log charity')),
      ),
      const SizedBox(height: 14),
      SCard(
        title: t('الخطة', 'الخطة الشهرية', 'Monthly plan'),
        icon: Icons.track_changes_rounded,
        color: SD.green,
        trailing: TextButton(onPressed: _setup, child: Text(plan > 0 ? t('غيّر', 'تعديل', 'Change') : t('حدّد', 'تحديد', 'Set'))),
        child: plan <= 0
            ? Text(t('حدّد نسبة من دخلك أو مبلغ ثابت تتصدّق بيه كل شهر، والتطبيق بيتابع معاك.',
                'حدّد نسبة من دخلك أو مبلغًا ثابتًا للصدقة كل شهر لتتابع التزامك.', 'Pick a % of income or a fixed monthly amount and track your giving.'))
            : Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                if (cfg['mode'] != 'fixed')
                  InfoRow(t('الدخل × النسبة', 'الدخل × النسبة', 'Income × %'), '${money(numOf(cfg['income']), cur)} × ${fmt(numOf(cfg['pct']), 2)}%', icon: Icons.calculate_rounded),
                PercentBar('${money(given, cur)} / ${money(plan, cur)}', given / plan, '${fmt(given / plan * 100, 0)}%', color: given >= plan ? SD.green : SD.teal),
                InfoRow(t('الباقي من الخطة', 'المتبقي من الخطة', 'Left in plan'), given >= plan ? t('كمّلت ✓', 'اكتملت ✓', 'Done ✓') : money(plan - given, cur),
                    icon: Icons.flag_rounded, valueColor: given >= plan ? SD.green : null),
                InfoRow(t('خطة السنة', 'خطة السنة', 'Yearly plan'), money(plan * 12, cur), icon: Icons.calendar_today_rounded),
              ]),
      ),
      SCard(
        title: t('إحصائيات', 'إحصاءات', 'Stats'),
        icon: Icons.bar_chart_rounded,
        color: SD.nile,
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          StatGrid([
            StatChip(fmt(yearTotal, 0), '${t('مجموع', 'إجمالي', 'Total')} $_y', color: SD.teal, icon: Icons.savings_rounded),
            StatChip('$streak', t('شهور ورا بعض', 'أشهر متتالية', 'Month streak'), color: SD.orange, icon: Icons.local_fire_department_rounded),
            StatChip('$monthsWithGiving/12', t('شهور السنة', 'أشهر السنة', 'Months this year'), color: SD.green, icon: Icons.event_available_rounded),
          ]),
          const SizedBox(height: 10),
          for (final c in _cats)
            if ((byCat[c.key] ?? 0) > 0) PercentBar('${c.emoji} ${c.name}', given == 0 ? 0 : byCat[c.key]! / given, money(byCat[c.key]!, cur), color: c.color),
        ]),
      ),
      SectionTitle(t('صدقات الشهر', 'صدقات الشهر', 'This month'), icon: Icons.list_alt_rounded),
      if (month.isEmpty)
        EmptyHint(Icons.volunteer_activism_outlined, t('ما في صدقات مسجّلة في الشهر دا', 'لا توجد صدقات مسجّلة لهذا الشهر', 'Nothing logged this month'))
      else
        for (final e in month)
          Card(
            margin: const EdgeInsets.only(bottom: 6),
            child: ListTile(
              onTap: () => _edit(e),
              leading: CircleAvatar(backgroundColor: _cat(e['cat']).color.withValues(alpha: .2), child: Text(_cat(e['cat']).emoji)),
              title: Text(((e['to'] as String?) ?? '').isEmpty ? _cat(e['cat']).name : e['to'], maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w700)),
              subtitle: Text(
                  [if (parseDk(e['d']) != null) fmtShort(parseDk(e['d'])!), if (((e['note'] as String?) ?? '').isNotEmpty) e['note']].join(' · '),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 12)),
              trailing: trailAmount(context, money(numOf(e['a']), cur)),
            ),
          ),
      const SizedBox(height: 10),
      SCard(
        title: t('تذكرة', 'تذكرة', 'Reminder'),
        icon: Icons.auto_awesome_rounded,
        color: SD.gold,
        trailing: IconButton(onPressed: () => setState(() => _textI++), icon: const Icon(Icons.refresh_rounded), tooltip: t('غيرها', 'نص آخر', 'Another')),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Directionality(
            textDirection: TextDirection.rtl,
            child: Text(tx.ar, textAlign: TextAlign.center, style: const TextStyle(fontSize: 18, height: 1.8, fontWeight: FontWeight.w700)),
          ),
          const SizedBox(height: 4),
          Text(isEn ? tx.srcEn : tx.srcAr, textAlign: TextAlign.center, style: const TextStyle(fontSize: 12, color: SD.goldDeep, fontWeight: FontWeight.w700)),
          if (isEn) ...[
            const SizedBox(height: 4),
            Text('Meaning: ${tx.en}', textAlign: TextAlign.center, style: const TextStyle(fontSize: 12.5, fontStyle: FontStyle.italic)),
          ],
        ]),
      ),
      if (month.isNotEmpty || yearTotal > 0) ShareBar(summary),
      const SizedBox(height: 8),
      NoteBox(
        t('دي أداة للصدقة التطوعية بس، وهي غير الزكاة الواجبة. لحساب الزكاة استعمل أداة «الزكاة» في التطبيق، وللأحكام اسأل أهل العلم.',
            'هذه الأداة للصدقة التطوعية فقط، وهي منفصلة عن الزكاة الواجبة. لحساب الزكاة استخدم أداة «الزكاة» في التطبيق، وللأحكام الشرعية راجع أهل العلم.',
            'This tool is for voluntary charity (sadaqa) only — it is separate from obligatory zakat. Use the app\'s «Zakat» tool for zakat, and ask a qualified scholar for rulings.'),
      ),
      NoteBox(
        t('صدقة السر أفضل في العموم — سجلّك دا محفوظ في جهازك بس وما بيتشارك إلا لو إنت شاركته.',
            'إخفاء الصدقة أفضل في الجملة — هذا السجل محفوظ على جهازك فقط ولا يُشارك إلا إذا شاركته بنفسك.',
            'Giving in secret is generally better — this log stays on your device unless you share it.'),
        kind: NoteKind.tip,
      ),
    ]);
  }
}
