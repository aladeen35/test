import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/format.dart';
import '../../core/i18n.dart';
import '../../core/state.dart';
import '../../core/theme.dart';
import '../../core/widgets.dart';
import '../../services/calendars.dart';
import '../life/life_common.dart';
import 'biz_common.dart';

/// نوع الأنعام وحدّ السنّ والاشتراك
class _Animal {
  final String key, emoji, sd, ar, en, ageAr, ageEn;
  final int maxShares;
  const _Animal(this.key, this.emoji, this.sd, this.ar, this.en, this.maxShares, this.ageAr, this.ageEn);
  String get name => t(sd, ar, en);
  String get age => tr(ageAr, ageEn);
}

const _animals = [
  _Animal('sheep', '🐑', 'خروف (ضأن)', 'ضأن', 'Sheep', 1, 'أتمّ 6 أشهر (الجذع من الضأن)', '6 months complete (jadha\')'),
  _Animal('goat', '🐐', 'غنماية (معز)', 'ماعز', 'Goat', 1, 'أتمّ سنة', '1 year complete'),
  _Animal('cow', '🐄', 'بقرة / عجل', 'بقر', 'Cow', 7, 'أتمّ سنتين', '2 years complete'),
  _Animal('camel', '🐪', 'جمل / ناقة', 'إبل', 'Camel', 7, 'أتمّ 5 سنوات', '5 years complete'),
];

/// موعد عيد الأضحى القادم (10 ذو الحجة) — أو اليوم إن كنّا في أيام النحر
({DateTime eid, int hYear, CalDate today}) nextAdha(DateTime today, int shift) {
  final h = toHijri(today, shift: shift);
  var y = h.y;
  if (h.m == 12 && h.d > 13) y++;
  return (eid: fromHijri(y, 12, 10, shift: shift), hYear: y, today: h);
}

class UdhiyaTool extends StatefulWidget {
  const UdhiyaTool({super.key});
  @override
  State<UdhiyaTool> createState() => _UdhiyaToolState();
}

class _UdhiyaToolState extends State<UdhiyaTool> {
  static const _key = 'udhiya_input';
  late final Map<String, dynamic> _in;
  late final TextEditingController _priceC, _partC, _meatC, _aqPriceC;

  @override
  void initState() {
    super.initState();
    _in = Map<String, dynamic>.from(context.read<AppState>().getData<Map>(_key) ?? const {});
    _priceC = TextEditingController(text: (_in['price'] as String?) ?? '');
    _partC = TextEditingController(text: (_in['partners'] as String?) ?? '7');
    _meatC = TextEditingController(text: (_in['meat'] as String?) ?? '');
    _aqPriceC = TextEditingController(text: (_in['aqPrice'] as String?) ?? '');
  }

  @override
  void dispose() {
    for (final c in [_priceC, _partC, _meatC, _aqPriceC]) {
      c.dispose();
    }
    super.dispose();
  }

  void _save([String? k, dynamic v]) {
    if (k != null) _in[k] = v;
    _in['price'] = _priceC.text;
    _in['partners'] = _partC.text;
    _in['meat'] = _meatC.text;
    _in['aqPrice'] = _aqPriceC.text;
    context.read<AppState>().setData(_key, Map<String, dynamic>.from(_in));
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final aqiqa = _in['mode'] == 'aqiqa';
    final cur = ((_in['cur'] as String?) ?? '').isEmpty ? 'ج.س' : _in['cur'] as String;
    final today = todayPlace();
    final adha = nextAdha(today, s.hijriShift);
    final days = dayDiff(today, adha.eid);
    final h = adha.today;
    final inNahr = h.m == 12 && h.d >= 10 && h.d <= 13;
    final inTen = h.m == 12 && h.d < 10;

    String heroSub() {
      final base = '${fmtDateAr(adha.eid)} · 10 ${hijriMonths[11]} ${adha.hYear} ${tr('هـ', 'AH')}';
      if (inNahr) {
        return '$base\n${t('دي أيام النحر — الذبح لحدي مغرب يوم 13 ذي الحجة', 'نحن في أيام النحر — يمتد الذبح إلى غروب 13 ذي الحجة', 'These are the days of sacrifice — until sunset of 13 Dhul-Hijjah')}';
      }
      if (inTen) return '$base\n${t('إنت في العشر الأوائل من ذي الحجة — أكتر من العمل الصالح', 'نحن في العشر الأوائل من ذي الحجة — أكثِر من العمل الصالح', 'We are in the first ten days of Dhul-Hijjah — increase good deeds')}';
      return base;
    }

    return ToolList(children: [
      ResultHero(
        label: t('عيد الضحية', 'عيد الأضحى', 'Eid al-Adha'),
        value: inNahr
            ? t('أيام العيد 🐑', 'أيام النحر 🐑', 'Days of sacrifice 🐑')
            : (days == 0 ? t('العيد الليلة!', 'العيد اليوم!', 'Eid is today!') : t('فاضل $days يوم', 'بعد $days يومًا', 'In $days days')),
        sub: heroSub(),
        colors: const [SD.green, SD.teal, SD.brownDeep],
      ),
      SegmentedButton<bool>(
        showSelectedIcon: false,
        segments: [
          ButtonSegment(value: false, label: Text(t('الضحية', 'الأضحية', 'Udhiya')), icon: const Icon(Icons.mosque_rounded)),
          ButtonSegment(value: true, label: Text(t('السماية', 'العقيقة', 'Aqiqa')), icon: const Icon(Icons.child_care_rounded)),
        ],
        selected: {aqiqa},
        onSelectionChanged: (x) => _save('mode', x.first ? 'aqiqa' : 'udhiya'),
      ),
      const SizedBox(height: 14),
      if (aqiqa) ..._aqiqa(cur) else ..._udhiya(cur),
      SCard(
        title: t('الضبط', 'الإعدادات', 'Settings'),
        icon: Icons.tune_rounded,
        color: SD.nile,
        child: CurField(cur, (v) => _save('cur', v)),
      ),
      NoteBox(
        t('دا ملخّص مبسّط لأحكام مشهورة عند أهل العلم وفيها خلاف في بعض التفاصيل — للتفاصيل والحالات الخاصة اسأل عالم أو شيخ موثوق.',
            'هذا ملخص مبسّط للأحكام المشهورة، وفي بعض تفاصيلها خلاف بين المذاهب؛ فاسأل عالمًا موثوقًا في التفاصيل والحالات الخاصة.',
            'A simplified summary of well-known rulings; schools differ on some details. Consult a trusted scholar for specifics.'),
        kind: NoteKind.warn,
      ),
      NoteBox(
        t('تاريخ العيد محسوب بتقويم أم القرى وممكن يختلف يوم حسب رؤية الهلال في بلدك (تقدر تعدّل الهجري من الضبط).',
            'التاريخ محسوب بتقويم أم القرى وقد يختلف يومًا بحسب رؤية الهلال في بلدك (يمكن تعديل الهجري من الإعدادات).',
            'Date computed with the Umm al-Qura calendar; it may differ by a day based on local moon sighting (adjust Hijri in Settings).'),
      ),
    ]);
  }

  List<Widget> _udhiya(String cur) {
    final a = _animals.firstWhere((x) => x.key == _in['animal'], orElse: () => _animals.first);
    final price = parseNum(_priceC.text);
    final shared = a.maxShares > 1;
    final rawPartners = parseNum(_partC.text, 7).round();
    final partners = shared ? rawPartners.clamp(1, 7) : 1;
    final per = partners == 0 ? 0.0 : price / partners;
    final meat = parseNum(_meatC.text);

    String summary() {
      final b = StringBuffer('🐑 ${t('الضحية', 'الأضحية', 'Udhiya')} — ${a.name}\n');
      b.writeln('${t('السعر', 'السعر', 'Price')}: ${money(price, cur)}');
      if (shared) b.writeln('${t('الشركاء', 'عدد المشتركين', 'Partners')}: $partners → ${t('نصيب الواحد', 'نصيب الفرد', 'each')}: ${money(per, cur, 2)}');
      if (meat > 0) b.writeln('${t('اللحم', 'اللحم', 'Meat')}: ${fmt(meat, 1)} ${tr('كجم', 'kg')} → ${t('كل تلت', 'كل ثلث', 'each third')} ${fmt(meat / 3, 2)} ${tr('كجم', 'kg')}');
      return b.toString().trim();
    }

    return [
      SCard(
        title: t('حساب الضحية', 'حساب الأضحية', 'Udhiya calculator'),
        icon: Icons.calculate_rounded,
        color: SD.green,
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Wrap(spacing: 6, runSpacing: 6, children: [
            for (final x in _animals) PickChip('${x.emoji} ${x.name}', x.key == a.key, () => _save('animal', x.key), color: SD.green),
          ]),
          const SizedBox(height: 12),
          NumField(t('سعرها', 'سعر الأضحية', 'Price'), _priceC, suffix: cur, onChanged: (_) => _save()),
          if (shared) ...[
            NumField(t('كم زول مشترك؟ (1 – 7)', 'عدد المشتركين (1 – 7)', 'Number of partners (1 – 7)'), _partC, decimal: false, onChanged: (_) => _save()),
            if (rawPartners > 7)
              NoteBox(t('البقرة والجمل ما بتجزي عن أكتر من 7.', 'لا تُجزئ البقرة أو البدنة عن أكثر من سبعة.', 'A cow or camel cannot be shared by more than seven.'), kind: NoteKind.danger),
          ] else
            NoteBox(
              t('الخروف أو الغنماية بتجزي عن زول واحد وأهل بيتو — ما بيشتركوا فيها ناس من بيوت مختلفة.', 'الشاة تُجزئ عن الرجل وأهل بيته، ولا يُشترك فيها بالثمن.',
                  'A sheep or goat suffices for one person and his household; it is not shared among separate buyers.'),
              kind: NoteKind.info,
            ),
          if (price > 0) ...[
            StatGrid([
              StatChip(compact(price), t('السعر', 'السعر', 'Price'), color: SD.gold, icon: Icons.sell_rounded),
              StatChip('$partners', shared ? t('شريك', 'مشترك', 'partners') : t('بيت', 'أسرة', 'household'), color: SD.nile, icon: Icons.groups_rounded),
              StatChip(compact(per), t('نصيب الواحد', 'نصيب الفرد', 'per person'), color: SD.green, icon: Icons.person_rounded),
            ]),
            const SizedBox(height: 8),
            if (shared && partners < 7)
              Text(
                t('البقرة/الجمل 7 أسهم — لو إنتو $partners، في زول ممكن ياخد أكتر من سهم. السهم الواحد = ${money(price / 7, cur, 2)}', 'البقرة/البدنة سبعة أسهم، فمع $partners مشتركين قد يملك أحدهم أكثر من سهم. السهم = ${money(price / 7, cur, 2)}',
                    'A cow/camel is 7 shares; with $partners partners some hold more than one. One share = ${money(price / 7, cur, 2)}'),
                style: const TextStyle(fontSize: 12.5),
              ),
          ],
        ]),
      ),
      SCard(
        title: t('توزيع اللحم (اختياري)', 'توزيع اللحم (اختياري)', 'Meat distribution (optional)'),
        icon: Icons.pie_chart_rounded,
        color: SD.henna,
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          NumField(t('وزن اللحم', 'وزن اللحم', 'Meat weight'), _meatC, suffix: tr('كجم', 'kg'), onChanged: (_) => _save()),
          if (meat > 0) ...[
            InfoRow(t('ليك ولأهل بيتك', 'لك ولأهل بيتك', 'Your household'), '${fmt(meat / 3, 2)} ${tr('كجم', 'kg')}', icon: Icons.home_rounded),
            InfoRow(t('هدايا للأهل والجيران', 'هدية للأقارب والجيران', 'Gifts to relatives & neighbours'), '${fmt(meat / 3, 2)} ${tr('كجم', 'kg')}', icon: Icons.card_giftcard_rounded),
            InfoRow(t('صدقة للفقراء', 'صدقة للفقراء', 'Charity to the poor'), '${fmt(meat / 3, 2)} ${tr('كجم', 'kg')}', icon: Icons.volunteer_activism_rounded, valueColor: SD.green),
          ],
          NoteBox(
            t('التقسيم أتلاث مستحب ما واجب، وتقدر تتصدّق بأكتر. وما تدّي الجزار أجرتو من لحمها ولا جلدها، وما تبيع منها حاجة.',
                'التقسيم أثلاثًا مستحب وليس واجبًا، ويجوز التصدق بأكثر. ولا يُعطى الجزّار أجرته منها، ولا يُباع منها شيء ولا جلدها.',
                'Dividing into thirds is recommended, not obligatory; you may give more in charity. Do not pay the butcher from it, and do not sell any of it, including the skin.'),
            kind: NoteKind.tip,
          ),
        ]),
      ),
      SCard(
        title: t('شروط الضحية', 'شروط الأضحية', 'Conditions'),
        icon: Icons.rule_rounded,
        color: SD.gold,
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Text(t('السنّ الأدنى:', 'السنّ المعتبرة:', 'Minimum age:'), style: const TextStyle(fontWeight: FontWeight.w800)),
          for (final x in _animals) InfoRow('${x.emoji} ${x.name}', x.age, valueColor: SD.gold),
          Text(tr('على قول جمهور العلماء (وعند الشافعية: المعز ما أتمّ سنتين).', 'Per the majority of scholars (Shafi\'is: goat 2 years).'), style: const TextStyle(fontSize: 12)),
          const SizedBox(height: 10),
          Text(t('السلامة من العيوب — ما بتجزي:', 'السلامة من العيوب — لا تُجزئ:', 'Free of defects — not valid:'), style: const TextStyle(fontWeight: FontWeight.w800)),
          const SizedBox(height: 4),
          for (final l in [
            tr('العوراء البيّن عَوَرها', 'One clearly blind in one eye'),
            tr('المريضة البيّن مرضها', 'One clearly sick'),
            tr('العرجاء البيّن ظَلَعها', 'One clearly lame'),
            tr('الكسيرة / العجفاء التي لا تُنقي (هزيلة لا مخّ في عظمها)', 'One so emaciated it has no marrow'),
            tr('وما هو أشد منها من باب أولى كالعمياء ومقطوعة الرِّجل', 'And worse than these, e.g. fully blind or missing a leg'),
          ])
            _bullet(l),
          Text(tr('حديث البراء بن عازب رضي الله عنه: «أربعٌ لا تجوز في الأضاحي…» (رواه أبو داود والترمذي)', 'Hadith of al-Bara\' ibn \'Azib: "Four are not permissible in sacrifices…" (Abu Dawud, Tirmidhi)'),
              style: const TextStyle(fontSize: 12)),
        ]),
      ),
      SCard(
        title: t('وقت الذبح', 'وقت الذبح', 'Time of slaughter'),
        icon: Icons.schedule_rounded,
        color: SD.teal,
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          InfoRow(t('البداية', 'البداية', 'Starts'), t('بعد صلاة العيد — 10 ذو الحجة', 'بعد صلاة العيد يوم 10 ذي الحجة', 'After the Eid prayer, 10 Dhul-Hijjah'), icon: Icons.play_arrow_rounded),
          InfoRow(t('النهاية', 'النهاية', 'Ends'), t('مغرب يوم 13 ذو الحجة', 'غروب شمس 13 ذي الحجة', 'Sunset, 13 Dhul-Hijjah'), icon: Icons.stop_rounded,
              hint: t('وعند جمهور تاني لحدي مغرب يوم 12 — الأحوط ما تأخّر', 'وعند جمهور آخر إلى غروب يوم 12، فالأحوط عدم التأخير', 'Many scholars say until sunset of the 12th — better not to delay')),
          InfoRow(t('ذبح قبل الصلاة', 'الذبح قبل الصلاة', 'Before the prayer'), t('ما بتحسب ضحية', 'لا تُجزئ أضحية', 'Not valid as udhiya'), icon: Icons.block_rounded, valueColor: SD.red),
          const SizedBox(height: 6),
          for (final l in [
            tr('الأضحية سنة مؤكدة عند الجمهور، وواجبة على المستطيع عند الحنفية.', 'Udhiya is a confirmed sunnah per the majority; obligatory for the able per the Hanafis.'),
            tr('من أراد أن يضحي يمسك عن شعره وأظفاره من أول ذي الحجة حتى يذبح (رواه مسلم).', 'Whoever intends to sacrifice refrains from cutting hair and nails from 1 Dhul-Hijjah until he slaughters (Muslim).'),
            tr('يُسنّ أن يذبح بنفسه أو يشهدها، ويقول: «بسم الله والله أكبر».', 'It is sunnah to slaughter yourself or attend, saying: "Bismillah, Allahu Akbar".'),
          ])
            _bullet(l),
        ]),
      ),
      ShareBar(summary),
      const SizedBox(height: 10),
    ];
  }

  List<Widget> _aqiqa(String cur) {
    final boy = _in['gender'] != 'girl';
    final babies = (intOf(_in['babies'], 1)).clamp(1, 5);
    final perBaby = boy ? 2 : 1;
    final sheep = perBaby * babies;
    final price = parseNum(_aqPriceC.text);
    final birth = parseDk(_in['birth'] as String?);
    final d7 = birth?.add(const Duration(days: 6));
    final d14 = birth?.add(const Duration(days: 13));
    final d21 = birth?.add(const Duration(days: 20));
    final today = todayPlace();

    String summary() {
      final b = StringBuffer('👶 ${t('السماية (العقيقة)', 'العقيقة', 'Aqiqa')}\n');
      b.writeln('${boy ? t('ولد', 'ذكر', 'Boy') : t('بت', 'أنثى', 'Girl')} × $babies → $sheep ${t('خروف', 'شاة', 'sheep')}');
      if (price > 0) b.writeln('${t('التكلفة', 'التكلفة', 'Cost')}: ${money(price * sheep, cur)}');
      if (d7 != null) b.writeln('${t('اليوم السابع', 'اليوم السابع', '7th day')}: ${fmtDateAr(d7)}');
      return b.toString().trim();
    }

    return [
      SCard(
        title: t('حساب السماية', 'حساب العقيقة', 'Aqiqa calculator'),
        icon: Icons.child_care_rounded,
        color: SD.pink,
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          SegmentedButton<bool>(
            showSelectedIcon: false,
            segments: [
              ButtonSegment(value: true, label: Text(t('ولد', 'ذكر', 'Boy'))),
              ButtonSegment(value: false, label: Text(t('بت', 'أنثى', 'Girl'))),
            ],
            selected: {boy},
            onSelectionChanged: (x) => _save('gender', x.first ? 'boy' : 'girl'),
          ),
          const SizedBox(height: 10),
          Row(children: [
            Expanded(child: Text(t('كم مولود؟ (توأم مثلاً)', 'عدد المواليد (للتوائم)', 'Number of babies (twins)'), maxLines: 2, overflow: TextOverflow.ellipsis)),
            iconBtn(Icons.remove_circle_outline_rounded, '−', () => _save('babies', (babies - 1).clamp(1, 5))),
            Text('$babies', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
            iconBtn(Icons.add_circle_outline_rounded, '+', () => _save('babies', (babies + 1).clamp(1, 5))),
          ]),
          const SizedBox(height: 6),
          NumField(t('سعر الخروف', 'سعر الشاة', 'Price per sheep'), _aqPriceC, suffix: cur, onChanged: (_) => _save()),
          StatGrid([
            StatChip('$sheep', t('خروف', 'شاة', 'sheep'), color: SD.pink, icon: Icons.pets_rounded),
            StatChip(price > 0 ? compact(price * sheep) : '—', t('التكلفة', 'التكلفة', 'Total cost'), color: SD.gold, icon: Icons.payments_rounded),
          ], columns: 2),
          NoteBox(
            boy
                ? t('عن الولد خروفين متقاربين وعن البت خروف — دا قول الجمهور. ولو ما قدرت إلا على واحد للولد بتجزي إن شاء الله، فالنبي ﷺ عقّ عن الحسن والحسين كبش كبش.',
                    'عن الغلام شاتان متكافئتان وعن الجارية شاة (قول الجمهور)، وتُجزئ شاة واحدة عن الغلام لمن لم يستطع؛ فقد عقّ النبي ﷺ عن الحسن والحسين كبشًا كبشًا (رواه أبو داود).',
                    'Two comparable sheep for a boy and one for a girl (majority view). One sheep for a boy is also valid; the Prophet ﷺ offered one ram each for al-Hasan and al-Husayn (Abu Dawud).')
                : t('عن البت خروف واحد.', 'عن الجارية شاة واحدة.', 'One sheep for a girl.'),
            kind: NoteKind.info,
          ),
        ]),
      ),
      SCard(
        title: t('متين تذبح؟', 'موعد العقيقة', 'When?'),
        icon: Icons.event_rounded,
        color: SD.teal,
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          LifeDateButton(
            label: t('يوم الولادة', 'تاريخ الولادة', 'Birth date'),
            value: birth,
            color: SD.teal,
            clearable: true,
            first: DateTime(today.year - 20),
            last: today.add(const Duration(days: 300)),
            onPick: (v) => _save('birth', v == null ? null : dk(v)),
          ),
          const SizedBox(height: 8),
          if (d7 != null) ...[
            InfoRow(t('اليوم السابع (الأفضل)', 'اليوم السابع (الأفضل)', '7th day (best)'), fmtDateAr(d7), icon: Icons.star_rounded, valueColor: SD.green, hint: _rel(today, d7)),
            InfoRow(t('ولا اليوم 14', 'أو اليوم الرابع عشر', 'or the 14th day'), fmtDateAr(d14!), icon: Icons.looks_two_rounded, hint: _rel(today, d14)),
            InfoRow(t('ولا اليوم 21', 'أو اليوم الحادي والعشرين', 'or the 21st day'), fmtDateAr(d21!), icon: Icons.looks_3_rounded, hint: _rel(today, d21)),
          ],
          const SizedBox(height: 6),
          for (final l in [
            tr('يوم الولادة يُحسب اليوم الأول عند الجمهور (وعند المالكية لا يُحسب إن وُلد بعد الفجر).', 'The birth day counts as day one per the majority (Malikis exclude it if born after Fajr).'),
            tr('«كل غلام رهينة بعقيقته، تُذبح عنه يوم سابعه، ويُحلق، ويُسمّى» (رواه أبو داود والترمذي).', '"Every child is held in pledge by his aqiqa, slaughtered on his seventh day; his head is shaved and he is named" (Abu Dawud, Tirmidhi).'),
            tr('فإن فات السابع ففي الرابع عشر أو الحادي والعشرين عند بعض أهل العلم، وتجوز بعد ذلك.', 'If the 7th passes, some scholars say the 14th or 21st; it remains valid afterwards.'),
            tr('العقيقة سنة مؤكدة عند الجمهور، ويُشترط فيها ما يُشترط في الأضحية من السنّ والسلامة من العيوب، ويجوز الأكل منها والإهداء والتصدّق.', 'Aqiqa is a confirmed sunnah per the majority; it has the same age and defect conditions as udhiya, and one may eat, gift and give charity from it.'),
          ])
            _bullet(l),
        ]),
      ),
      ShareBar(summary),
      const SizedBox(height: 10),
    ];
  }

  String _rel(DateTime today, DateTime d) {
    final n = dayDiff(today, d);
    if (n == 0) return t('الليلة', 'اليوم', 'Today');
    if (n > 0) return t('بعد $n يوم', 'بعد $n يوم', 'In $n days');
    return t('فات قبل ${-n} يوم', 'مضى منذ ${-n} يوم', '${-n} days ago');
  }

  Widget _bullet(String s) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Padding(padding: EdgeInsetsDirectional.only(end: 6, top: 2), child: Icon(Icons.circle, size: 7, color: SD.gold)),
          Expanded(child: Text(s, style: const TextStyle(fontSize: 13.5, height: 1.5))),
        ]),
      );
}
