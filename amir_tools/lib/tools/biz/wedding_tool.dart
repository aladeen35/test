import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/format.dart';
import '../../core/i18n.dart';
import '../../core/state.dart';
import '../../core/theme.dart';
import '../../core/widgets.dart';
import '../life/life_common.dart';
import 'biz_common.dart';

/// بند افتراضي من بنود العرس السوداني
class _Def {
  final String key, emoji, sd, ar, en;
  final double planned;
  const _Def(this.key, this.emoji, this.sd, this.ar, this.en, this.planned);
  String get name => t(sd, ar, en);
}

const _defs = [
  _Def('shayla', '🧳', 'الشيلة', 'الشيلة', 'Shayla (gifts to bride)', 0),
  _Def('qola', '💍', 'القولة / الخطوبة', 'الخطوبة (القولة)', 'Engagement (Qola)', 0),
  _Def('mahr', '💰', 'المهر', 'المهر', 'Mahr (dowry)', 0),
  _Def('hall', '🏛️', 'الصالة / الصيوان', 'الصالة / الصيوان', 'Hall / tent', 0),
  _Def('artist', '🎤', 'الفنان والساوند', 'الفنان والصوتيات', 'Singer & sound', 0),
  _Def('food', '🍽️', 'الضيافة والعشاء', 'الضيافة والعشاء', 'Hospitality & dinner', 0),
  _Def('henna', '🌿', 'الحنة', 'ليلة الحناء', 'Henna night', 0),
  _Def('jirtig', '👑', 'الجرتق', 'الجرتق', 'Jirtig ceremony', 0),
  _Def('gold', '📿', 'الهدايا والدهب', 'الهدايا والذهب', 'Gifts & gold', 0),
  _Def('home', '🛋️', 'تجهيز البيت', 'تجهيز البيت', 'Furnishing the home', 0),
  _Def('transport', '🚐', 'المواصلات', 'المواصلات', 'Transport', 0),
  _Def('other', '📦', 'حاجات تانية', 'أخرى', 'Other', 0),
];

const _colors = [SD.henna, SD.pink, SD.gold, SD.indigo, SD.purple, SD.orange, SD.green, SD.goldDeep, SD.teal, SD.coffee, SD.nile, SD.brownLight];

class WeddingTool extends StatefulWidget {
  const WeddingTool({super.key});
  @override
  State<WeddingTool> createState() => _WeddingToolState();
}

class _WeddingToolState extends State<WeddingTool> {
  static const _key = 'wedding_budget_data';

  Map<String, dynamic> _data(AppState s) => Map<String, dynamic>.from(s.getData<Map>(_key) ?? const {});
  void _put(AppState s, Map<String, dynamic> d) => s.setData(_key, d);
  String _cur(Map d) => ((d['cur'] as String?) ?? '').isEmpty ? 'ج.س' : d['cur'] as String;

  List<Map<String, dynamic>> _cats(Map<String, dynamic> d) {
    if (d['cats'] is List) return mapList(d['cats']);
    return [
      for (final x in _defs) {'id': x.key, 'key': x.key, 'planned': x.planned, 'pays': <Map>[]},
    ];
  }

  String _name(Map c) {
    final n = (c['name'] as String?) ?? '';
    if (n.isNotEmpty) return n;
    final k = c['key'];
    for (final x in _defs) {
      if (x.key == k) return x.name;
    }
    return t('بند', 'بند', 'Item');
  }

  String _emoji(Map c) {
    final k = c['key'];
    for (final x in _defs) {
      if (x.key == k) return x.emoji;
    }
    return '🎉';
  }

  double _paid(Map c) => mapList(c['pays']).fold(0.0, (a, p) => a + numOf(p['a']));

  void _saveCats(AppState s, List<Map<String, dynamic>> cats) {
    final d = _data(s);
    d['cats'] = cats;
    _put(s, d);
  }

  Future<void> _editCat([Map<String, dynamic>? c]) async {
    final s = context.read<AppState>();
    final d = _data(s);
    final cur = _cur(d);
    final nameC = TextEditingController(text: c == null ? '' : _name(c));
    final planC = TextEditingController(text: c == null || numOf(c['planned']) == 0 ? '' : fmt(numOf(c['planned']), 2).replaceAll(',', ''));
    final ok = await lifeSheet<bool>(
      context,
      c == null ? t('بند جديد', 'بند جديد', 'New item') : t('عدّل البند', 'تعديل البند', 'Edit item'),
      (ctx, set) => Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        TextField(controller: nameC, decoration: InputDecoration(labelText: t('اسم البند', 'اسم البند', 'Item name'), hintText: t('مثلاً: الكوافير', 'مثلًا: الكوافير', 'e.g. Hair & makeup'))),
        const SizedBox(height: 12),
        NumField(t('المبلغ المخطط', 'المبلغ المخطط', 'Planned amount'), planC, suffix: cur),
        const SizedBox(height: 8),
        Row(children: [
          if (c != null)
            Expanded(
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(foregroundColor: SD.red),
                onPressed: () => Navigator.pop(ctx, false),
                icon: const Icon(Icons.delete_outline_rounded),
                label: Text(t('امسح', 'حذف', 'Delete'), maxLines: 1, overflow: TextOverflow.ellipsis),
              ),
            ),
          if (c != null) const SizedBox(width: 10),
          Expanded(
            flex: 2,
            child: FilledButton.icon(
              onPressed: () {
                if (nameC.text.trim().isEmpty) return toast(t('أكتب اسم البند', 'اكتب اسم البند', 'Enter a name'));
                Navigator.pop(ctx, true);
              },
              icon: const Icon(Icons.check_rounded),
              label: Text(t('احفظ', 'حفظ', 'Save')),
            ),
          ),
        ]),
      ]),
    );
    final name = nameC.text.trim(), planned = parseNum(planC.text);
    nameC.dispose();
    planC.dispose();
    if (!mounted || ok == null) return;
    final cats = _cats(_data(s));
    if (ok == false && c != null) {
      final paid = _paid(c);
      if (paid > 0 &&
          !await confirmAsk(context, t('تمسح البند؟', 'حذف البند؟', 'Delete item?'),
              t('البند دا فيهو مدفوعات ${money(paid, cur)} — حتنمسح معاهو.', 'يحتوي البند على مدفوعات ${money(paid, cur)} ستُحذف معه.', 'This item has ${money(paid, cur)} in payments that will be deleted too.'))) {
        return;
      }
      cats.removeWhere((x) => x['id'] == c['id']);
      _saveCats(s, cats);
      return;
    }
    if (c == null) {
      cats.add({'id': newId(), 'key': 'custom', 'name': name, 'planned': planned, 'pays': <Map>[]});
    } else {
      final i = cats.indexWhere((x) => x['id'] == c['id']);
      if (i >= 0) {
        cats[i]['planned'] = planned;
        if (name != _name(cats[i])) cats[i]['name'] = name;
      }
    }
    _saveCats(s, cats);
    s.awardDaily('wedding_plan', 3, tr('تخطيط ميزانية العرس', 'Planned wedding budget'));
  }

  Future<void> _addPay(Map<String, dynamic> c, [Map<String, dynamic>? p]) async {
    final s = context.read<AppState>();
    final d = _data(s);
    final cur = _cur(d);
    final payers = <String>{};
    for (final x in _cats(d)) {
      for (final y in mapList(x['pays'])) {
        final b = ((y['by'] as String?) ?? '').trim();
        if (b.isNotEmpty) payers.add(b);
      }
    }
    final aC = TextEditingController(text: p == null ? '' : fmt(numOf(p['a']), 2).replaceAll(',', ''));
    final byC = TextEditingController(text: (p?['by'] as String?) ?? '');
    final noteC = TextEditingController(text: (p?['note'] as String?) ?? '');
    var date = parseDk(p?['d']) ?? todayPlace();
    final ok = await lifeSheet<bool>(
      context,
      '${_emoji(c)} ${p == null ? t('دفعة جديدة', 'دفعة جديدة', 'New payment') : t('عدّل الدفعة', 'تعديل الدفعة', 'Edit payment')} — ${_name(c)}',
      (ctx, set) => Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        NumField(t('المبلغ', 'المبلغ', 'Amount'), aC, suffix: cur),
        TextField(
          controller: byC,
          decoration: InputDecoration(
            labelText: t('منو الدفع؟', 'اسم الدافع', 'Paid by'),
            hintText: t('العريس، أبو العريس، الخال…', 'العريس، والد العريس…', 'Groom, father, uncle…'),
          ),
        ),
        if (payers.isNotEmpty) ...[
          const SizedBox(height: 8),
          Wrap(spacing: 6, runSpacing: 6, children: [
            for (final n in payers.take(12)) PickChip(n, byC.text.trim() == n, () => set(() => byC.text = n), color: SD.henna),
          ]),
        ],
        const SizedBox(height: 10),
        TextField(controller: noteC, decoration: InputDecoration(labelText: t('ملاحظة (اختياري)', 'ملاحظة (اختياري)', 'Note (optional)'))),
        const SizedBox(height: 12),
        LifeDateButton(label: t('التاريخ', 'التاريخ', 'Date'), value: date, onPick: (v) => set(() => date = v ?? date), color: SD.henna),
        const SizedBox(height: 16),
        Row(children: [
          if (p != null)
            Expanded(
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(foregroundColor: SD.red),
                onPressed: () => Navigator.pop(ctx, false),
                icon: const Icon(Icons.delete_outline_rounded),
                label: Text(t('امسح', 'حذف', 'Delete'), maxLines: 1, overflow: TextOverflow.ellipsis),
              ),
            ),
          if (p != null) const SizedBox(width: 10),
          Expanded(
            flex: 2,
            child: FilledButton.icon(
              onPressed: () {
                if (parseNum(aC.text) <= 0) return toast(t('أكتب المبلغ', 'اكتب المبلغ', 'Enter the amount'));
                Navigator.pop(ctx, true);
              },
              icon: const Icon(Icons.check_rounded),
              label: Text(t('احفظ', 'حفظ', 'Save')),
            ),
          ),
        ]),
      ]),
    );
    final a = parseNum(aC.text), by = byC.text.trim(), note = noteC.text.trim();
    aC.dispose();
    byC.dispose();
    noteC.dispose();
    if (!mounted || ok == null) return;
    final cats = _cats(_data(s));
    final i = cats.indexWhere((x) => x['id'] == c['id']);
    if (i < 0) return;
    final pays = mapList(cats[i]['pays']);
    if (ok == false && p != null) {
      pays.removeWhere((x) => x['id'] == p['id']);
    } else if (p == null) {
      pays.add({'id': newId(), 'a': a, 'by': by, 'note': note, 'd': dk(date)});
      s.awardDaily('wedding_pay', 3, tr('تسجيل دفعة العرس', 'Logged a wedding payment'));
    } else {
      final j = pays.indexWhere((x) => x['id'] == p['id']);
      if (j >= 0) pays[j] = {...pays[j], 'a': a, 'by': by, 'note': note, 'd': dk(date)};
    }
    cats[i]['pays'] = pays;
    _saveCats(s, cats);
  }

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final d = _data(s);
    final cur = _cur(d);
    final cats = _cats(d);
    final date = parseDk(d['date'] as String?);
    final today = todayPlace();
    final days = date == null ? null : dayDiff(today, date);

    final planned = cats.fold(0.0, (a, c) => a + numOf(c['planned']));
    final paid = cats.fold(0.0, (a, c) => a + _paid(c));
    final remaining = planned - paid;
    final noName = t('ما معروف', 'غير محدد', 'Unspecified');

    final byPayer = <String, double>{};
    final allPays = <(Map<String, dynamic>, Map<String, dynamic>)>[];
    for (final c in cats) {
      for (final p in mapList(c['pays'])) {
        final b = ((p['by'] as String?) ?? '').trim();
        byPayer[b.isEmpty ? noName : b] = (byPayer[b.isEmpty ? noName : b] ?? 0) + numOf(p['a']);
        allPays.add((c, p));
      }
    }
    final payers = byPayer.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    allPays.sort((a, b) => ((b.$2['d'] as String?) ?? '').compareTo((a.$2['d'] as String?) ?? ''));
    final over = cats.where((c) => numOf(c['planned']) > 0 && _paid(c) > numOf(c['planned'])).toList();
    final couple = ((d['couple'] as String?) ?? '').trim();

    String countdown() {
      if (days == null) return t('حدّد يوم العرس', 'حدّد موعد الزفاف', 'Set the wedding date');
      if (days > 0) return t('فاضل $days يوم للعرس', 'متبقٍ $days يومًا على الزفاف', '$days days to the wedding');
      if (days == 0) return t('العرس الليلة! ألف مبروك 🎉', 'الزفاف اليوم! ألف مبروك 🎉', 'The wedding is today! Congrats 🎉');
      return t('العرس فات قبل ${-days} يوم — بالرفاه والبنين', 'مضى على الزفاف ${-days} يومًا', 'Wedding was ${-days} days ago');
    }

    String summary() {
      final b = StringBuffer('💍 ${t('ميزانية العرس', 'ميزانية الزفاف', 'Wedding budget')}${couple.isEmpty ? '' : ' — $couple'}\n');
      if (date != null) b.writeln('📅 ${fmtDateAr(date)} (${countdown()})');
      b.writeln('${t('المخطط', 'المخطط', 'Planned')}: ${money(planned, cur)}');
      b.writeln('${t('المدفوع', 'المدفوع', 'Paid')}: ${money(paid, cur)}');
      b.writeln('${t('الفاضل', 'المتبقي', 'Remaining')}: ${money(remaining, cur)}');
      b.writeln('');
      for (final c in cats) {
        if (numOf(c['planned']) == 0 && _paid(c) == 0) continue;
        b.writeln('${_emoji(c)} ${_name(c)}: ${money(_paid(c), cur)} / ${money(numOf(c['planned']), cur)}');
      }
      if (payers.isNotEmpty) {
        b.writeln('\n🤝 ${t('المساهمات', 'المساهمات', 'Contributions')}:');
        for (final p in payers) {
          b.writeln('• ${p.key}: ${money(p.value, cur)}');
        }
      }
      return b.toString().trim();
    }

    return ToolList(children: [
      ResultHero(
        label: couple.isEmpty ? t('ميزانية العرس', 'ميزانية الزفاف', 'Wedding budget') : '💍 $couple',
        value: money(planned, cur),
        sub: '${t('مدفوع', 'مدفوع', 'Paid')} ${money(paid, cur)} · ${t('فاضل', 'متبقٍ', 'Left')} ${money(remaining, cur)}\n${countdown()}',
        colors: const [SD.henna, SD.coffee, SD.brownDeep],
      ),
      StatGrid([
        StatChip(compact(planned), t('المخطط', 'المخطط', 'Planned'), color: SD.gold, icon: Icons.assignment_rounded),
        StatChip(compact(paid), t('المدفوع', 'المدفوع', 'Paid'), color: SD.green, icon: Icons.check_circle_rounded),
        StatChip(compact(remaining), t('الفاضل', 'المتبقي', 'Remaining'), color: remaining < 0 ? SD.red : SD.orange, icon: Icons.hourglass_bottom_rounded),
        StatChip(days == null ? '—' : '${days.abs()}', days == null || days >= 0 ? t('يوم للعرس', 'يوم للزفاف', 'days to go') : t('يوم من العرس', 'يوم منذ الزفاف', 'days since'),
            color: SD.pink, icon: Icons.event_rounded),
        StatChip('${cats.length}', t('بند', 'بند', 'items'), color: SD.nile, icon: Icons.list_alt_rounded),
        StatChip('${payers.length}', t('مساهم', 'مساهم', 'contributors'), color: SD.purple, icon: Icons.groups_rounded),
      ]),
      const SizedBox(height: 12),
      if (planned > 0)
        BizBar(t('اتدفع من الميزانية', 'نسبة المدفوع', 'Paid so far'), paid / planned, pct(paid / planned * 100), color: paid > planned ? SD.red : SD.green),
      if (over.isNotEmpty)
        NoteBox(
          '${t('البنود دي عدّت المخطط', 'بنود تجاوزت المخطط', 'Over plan')}: ${over.map((c) => '${_name(c)} (+${money(_paid(c) - numOf(c['planned']), cur)})').join('، ')}',
          kind: NoteKind.warn,
        ),
      const SizedBox(height: 8),
      SCard(
        title: t('بيانات العرس', 'بيانات الزفاف', 'Wedding details'),
        icon: Icons.favorite_rounded,
        color: SD.pink,
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          _CoupleField(couple, (v) => _put(s, {..._data(s), 'couple': v})),
          const SizedBox(height: 10),
          LifeDateButton(
            label: t('يوم العرس', 'موعد الزفاف', 'Wedding date'),
            value: date,
            clearable: true,
            color: SD.pink,
            onPick: (v) => _put(s, {..._data(s), 'date': v == null ? null : dk(v)}),
          ),
          const SizedBox(height: 10),
          CurField(cur, (v) => _put(s, {..._data(s), 'cur': v})),
        ]),
      ),
      SCard(
        title: t('بنود العرس', 'بنود الزفاف', 'Budget items'),
        icon: Icons.checklist_rounded,
        color: SD.henna,
        trailing: iconBtn(Icons.add_circle_rounded, t('بند جديد', 'إضافة بند', 'Add item'), () => _editCat(), color: SD.gold),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Text(t('دوس على البند عشان تشوف الدفعات وتضيف دفعة. القلم للتعديل والمسح.', 'اضغط على البند لعرض الدفعات وإضافتها، والقلم للتعديل أو الحذف.',
              'Tap an item to see/add payments; the pencil edits or deletes it.'), style: const TextStyle(fontSize: 12)),
          const SizedBox(height: 6),
          for (var i = 0; i < cats.length; i++) _catTile(cats[i], cur, _colors[i % _colors.length]),
          if (cats.isEmpty) EmptyHint(Icons.checklist_rounded, t('ما في بنود — ضيف بند', 'لا بنود — أضف بندًا', 'No items — add one')),
        ]),
      ),
      SCard(
        title: t('المساهمات (النقطة)', 'المساهمات', 'Contributions'),
        icon: Icons.groups_rounded,
        color: SD.purple,
        child: payers.isEmpty
            ? Text(t('لمن تسجّل دفعة وتكتب منو الدفعها، بتظهر هنا مساهمة كل زول.', 'عند تسجيل الدفعات مع اسم الدافع تظهر هنا مساهمة كل شخص.',
                'When you log payments with a payer name, each person\'s contribution shows here.'))
            : Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                for (var i = 0; i < payers.length; i++)
                  BizBar('🤝 ${payers[i].key}', paid == 0 ? 0 : payers[i].value / paid, '${money(payers[i].value, cur)} · ${pct(paid == 0 ? 0 : payers[i].value / paid * 100)}',
                      color: _colors[(i + 3) % _colors.length]),
              ]),
      ),
      if (allPays.isNotEmpty)
        SCard(
          title: t('آخر الدفعات', 'أحدث الدفعات', 'Latest payments'),
          icon: Icons.receipt_long_rounded,
          color: SD.green,
          child: Column(children: [
            for (final x in allPays.take(15))
              MiniRow(
                '${_emoji(x.$1)} ${_name(x.$1)}',
                money(numOf(x.$2['a']), cur),
                sub: [
                  if (((x.$2['by'] as String?) ?? '').isNotEmpty) x.$2['by'] as String,
                  if (parseDk(x.$2['d']) != null) fmtShort(parseDk(x.$2['d'])!),
                  if (((x.$2['note'] as String?) ?? '').isNotEmpty) x.$2['note'] as String,
                ].join(' · '),
                color: SD.green,
                onTap: () => _addPay(x.$1, x.$2),
              ),
          ]),
        ),
      ShareBar(summary),
      const SizedBox(height: 8),
      NoteBox(
        t('خلّي ليك احتياطي 10% للحاجات الما في الحساب — العرس دايماً بيزيد. والمهر حق العروس، والمهم البركة: «خير النكاح أيسره».',
            'احتفظ باحتياطي 10% للمصروفات غير المتوقعة. والمهر حق للزوجة، وفي الحديث: «خير النكاح أيسره» (رواه أبو داود).',
            'Keep a 10% buffer for surprises — weddings always run over. Simplicity brings blessing.'),
        kind: NoteKind.tip,
      ),
      Align(
        alignment: AlignmentDirectional.centerStart,
        child: TextButton.icon(
          style: TextButton.styleFrom(foregroundColor: SD.red),
          onPressed: () async {
            if (await confirmAsk(context, t('تبدأ من جديد؟', 'البدء من جديد؟', 'Start over?'),
                t('حتنمسح كل البنود والدفعات.', 'سيتم حذف جميع البنود والدفعات.', 'All items and payments will be deleted.'))) {
              _put(s, {'cur': d['cur'], 'couple': d['couple'], 'date': d['date']});
            }
          },
          icon: const Icon(Icons.restart_alt_rounded),
          label: Text(t('صفّر الميزانية', 'إعادة تعيين', 'Reset budget')),
        ),
      ),
    ]);
  }

  Widget _catTile(Map<String, dynamic> c, String cur, Color color) {
    final planned = numOf(c['planned']), paid = _paid(c);
    final pays = mapList(c['pays'])..sort((a, b) => ((b['d'] as String?) ?? '').compareTo((a['d'] as String?) ?? ''));
    final frac = planned <= 0 ? (paid > 0 ? 1.0 : 0.0) : paid / planned;
    final barColor = planned > 0 && paid > planned ? SD.red : (frac >= 1 ? SD.green : color);
    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        key: PageStorageKey('wcat_${c['id']}'),
        tilePadding: EdgeInsets.zero,
        childrenPadding: const EdgeInsetsDirectional.only(start: 8, bottom: 8),
        title: BizBar(
          '${_emoji(c)} ${_name(c)}',
          frac,
          planned > 0 ? '${compact(paid)} / ${compact(planned)}' : compact(paid),
          color: barColor,
          hint: planned > 0
              ? (paid >= planned
                  ? (paid > planned ? t('عدّى بـ ${money(paid - planned, cur)}', 'تجاوز بـ ${money(paid - planned, cur)}', 'Over by ${money(paid - planned, cur)}') : t('اكتمل ✓', 'مكتمل ✓', 'Done ✓'))
                  : t('فاضل ${money(planned - paid, cur)}', 'متبقٍ ${money(planned - paid, cur)}', '${money(planned - paid, cur)} left'))
              : t('ما حدّدت مبلغ مخطط', 'لم يُحدَّد مبلغ مخطط', 'No planned amount'),
        ),
        trailing: iconBtn(Icons.edit_rounded, t('عدّل', 'تعديل', 'Edit'), () => _editCat(c)),
        children: [
          for (final p in pays)
            MiniRow(
              ((p['by'] as String?) ?? '').isEmpty ? t('دفعة', 'دفعة', 'Payment') : p['by'] as String,
              money(numOf(p['a']), cur),
              sub: [if (parseDk(p['d']) != null) fmtShort(parseDk(p['d'])!), if (((p['note'] as String?) ?? '').isNotEmpty) p['note'] as String].join(' · '),
              onTap: () => _addPay(c, p),
            ),
          if (pays.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Text(t('ما في دفعات لسه', 'لا دفعات بعد', 'No payments yet'), style: const TextStyle(fontSize: 12.5)),
            ),
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: TextButton.icon(
              onPressed: () => _addPay(c),
              icon: const Icon(Icons.add_rounded),
              label: Text(t('سجّل دفعة', 'تسجيل دفعة', 'Add payment')),
            ),
          ),
        ],
      ),
    );
  }
}

class _CoupleField extends StatefulWidget {
  final String value;
  final ValueChanged<String> onChanged;
  const _CoupleField(this.value, this.onChanged);
  @override
  State<_CoupleField> createState() => _CoupleFieldState();
}

class _CoupleFieldState extends State<_CoupleField> {
  late final _c = TextEditingController(text: widget.value);
  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => TextField(
        controller: _c,
        decoration: InputDecoration(
          labelText: t('العرسان (اختياري)', 'اسم العروسين (اختياري)', 'Couple names (optional)'),
          hintText: t('أحمد ومنى', 'أحمد ومنى', 'Ahmed & Mona'),
          prefixIcon: const Icon(Icons.favorite_border_rounded),
        ),
        onChanged: (v) => widget.onChanged(v.trim()),
      );
}
