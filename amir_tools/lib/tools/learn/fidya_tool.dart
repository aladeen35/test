import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/date_input.dart';
import '../../core/format.dart';
import '../../core/i18n.dart';
import '../../core/state.dart';
import '../../core/theme.dart';
import '../../core/widgets.dart';
import 'learn_common.dart';

/// مقدار الإطعام لمسكين واحد
enum FeedMeasure { mudd, halfSaa, meal }

/// كيلوغرامات تقريبية لكل مسكين حسب المقدار (الوجبة = 0)
double feedKg(FeedMeasure m) => switch (m) {
      FeedMeasure.mudd => 0.6,
      FeedMeasure.halfSaa => 1.6,
      FeedMeasure.meal => 0,
    };

/// تكلفة إطعام [people] مسكينًا
({double kg, double cost}) feedCost(int people, FeedMeasure m, double pricePerKg, double mealPrice) {
  if (m == FeedMeasure.meal) return (kg: 0, cost: people * mealPrice);
  final kg = people * feedKg(m);
  return (kg: kg, cost: kg * pricePerKg);
}

class FidyaTool extends StatefulWidget {
  const FidyaTool({super.key});
  @override
  State<FidyaTool> createState() => _FidyaToolState();
}

class _FidyaToolState extends State<FidyaTool> {
  late final Map<String, TextEditingController> _c;
  int _tab = 0;
  FeedMeasure _m = FeedMeasure.mudd;
  DateTime? _start;

  static const _defaults = {'days': '30', 'kg': '1500', 'meal': '3000', 'cloth': '15000', 'n_y': '1', 'n_r': '1', 'cur': ''};

  @override
  void initState() {
    super.initState();
    final s = context.read<AppState>();
    final saved = Map<String, dynamic>.from(s.getData<Map>('fidya_in') ?? const {});
    _c = {for (final k in _defaults.keys) k: TextEditingController(text: '${saved[k] ?? _defaults[k]}')};
    if (_c['cur']!.text.isEmpty) _c['cur']!.text = tr('ج.س', 'SDG');
    _tab = lInt(saved['tab']).clamp(0, 2);
    _m = FeedMeasure.values[lInt(saved['m']).clamp(0, 2)];
    _start = lParseDk(saved['start'] as String?);
  }

  @override
  void dispose() {
    for (final c in _c.values) {
      c.dispose();
    }
    super.dispose();
  }

  void _save() {
    context.read<AppState>().setData('fidya_in', {
      for (final e in _c.entries) e.key: e.value.text,
      'tab': _tab,
      'm': _m.index,
      if (_start != null) 'start': lDk(_start!),
    });
    setState(() {});
  }

  double _v(String k) => parseNum(_c[k]!.text);
  String get _cur => _c['cur']!.text.trim();
  String _money(double x) => '${fmt(x, 0)} $_cur';

  String _measureName(FeedMeasure m) => switch (m) {
        FeedMeasure.mudd => t('مُد (≈ 0.6 كيلو) — رأي الجمهور', 'مُدّ (≈ 0.6 كجم) — قول الجمهور', 'One mudd (≈ 0.6 kg) — majority view'),
        FeedMeasure.halfSaa => t('نص صاع قمح (≈ 1.6 كيلو) — الحنفية', 'نصف صاع من القمح (≈ 1.6 كجم) — الحنفية', 'Half a sa‘ of wheat (≈ 1.6 kg) — Hanafi'),
        FeedMeasure.meal => t('وجبة مشبعة (بالقيمة)', 'وجبة مشبعة (بالقيمة)', 'A filling meal (by value)'),
      };

  Widget _measureCard() => SCard(
        title: t('مقدار إطعام المسكين', 'مقدار إطعام المسكين', 'Food per poor person'),
        icon: Icons.rice_bowl_rounded,
        color: SD.orange,
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          lSegmented<FeedMeasure>(
            items: [(FeedMeasure.mudd, t('مُد', 'مُدّ', 'Mudd')), (FeedMeasure.halfSaa, t('نص صاع', 'نصف صاع', 'Half sa‘')), (FeedMeasure.meal, t('وجبة', 'وجبة', 'Meal'))],
            value: _m,
            onChanged: (v) {
              _m = v;
              _save();
            },
          ),
          const SizedBox(height: 8),
          Text(_measureName(_m), style: const TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 10),
          if (_m == FeedMeasure.meal)
            NumField(t('سعر الوجبة الواحدة', 'سعر الوجبة الواحدة', 'Price of one meal'), _c['meal']!, onChanged: (_) => _save(), suffix: _cur)
          else
            NumField(t('سعر الكيلو (قمح/دقيق/رز/عيش)', 'سعر الكيلوغرام من قوت البلد', 'Price per kg of staple food'), _c['kg']!,
                onChanged: (_) => _save(), suffix: _cur, hint: t('مثلاً القمح أو الذرة أو الرز', 'كالقمح أو الذرة أو الأرز', 'e.g. wheat, sorghum, rice')),
          TextField(
            controller: _c['cur'],
            onChanged: (_) => _save(),
            decoration: InputDecoration(labelText: t('العملة', 'العملة', 'Currency label')),
          ),
        ]),
      );

  @override
  Widget build(BuildContext context) {
    final price = _v('kg'), meal = _v('meal');
    final body = switch (_tab) {
      0 => _fidya(price, meal),
      1 => _yamin(price, meal),
      _ => _ramadan(price, meal),
    };
    return ToolList(children: [
      lSegmented<int>(
        items: [(0, t('الفدية', 'الفدية', 'Fidya')), (1, t('كفارة اليمين', 'كفارة اليمين', 'Oath')), (2, t('كفارة رمضان', 'كفارة رمضان', 'Ramadan'))],
        value: _tab,
        onChanged: (v) {
          _tab = v;
          _save();
        },
      ),
      const SizedBox(height: 12),
      ...body,
      NoteBox(
          t('الحاسبة دي للتقريب والتوضيح بس. الأحكام فيها تفاصيل وخلاف بين المذاهب — اسأل عالم أو جهة فتوى موثوقة في بلدك قبل ما تخرج.',
              'هذه الحاسبة للتقريب والتوضيح فقط، وفي المسائل تفصيل وخلاف بين المذاهب؛ فاسأل عالمًا أو جهة فتوى موثوقة قبل الإخراج.',
              'This calculator is an approximation for guidance only. Rulings have details and differ between schools — consult a qualified scholar or fatwa body before paying.'),
          kind: NoteKind.warn),
    ]);
  }

  /* ── (أ) فدية الصيام ── */
  List<Widget> _fidya(double price, double meal) {
    final days = _v('days').round().clamp(0, 10000);
    final r = feedCost(days, _m, price, meal);
    return [
      NoteBox(
          t('الفدية لمن ما بقدر يصوم ولا يُرجى يقدر يقضي: الكبير في السن والمريض مرض مزمن ما بيُرجى شفاه. بيطعم عن كل يوم مسكين واحد.',
              'الفدية لمن لا يستطيع الصوم ولا يُرجى قضاؤه: كالشيخ الكبير والمريض مرضًا مزمنًا لا يُرجى برؤه، فيُطعم عن كل يوم مسكينًا.',
              'Fidya is for those who cannot fast and are not expected to make up the days — e.g. the very elderly or the chronically ill with no hope of recovery: feed one poor person for each day.')),
      const Padding(
        padding: EdgeInsets.only(bottom: 10),
        child: Text('﴿وَعَلَى الَّذِينَ يُطِيقُونَهُ فِدْيَةٌ طَعَامُ مِسْكِينٍ﴾ [البقرة: 184]',
            textAlign: TextAlign.center, textDirection: TextDirection.rtl, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, height: 1.8)),
      ),
      SCard(
        title: t('الأيام', 'عدد الأيام', 'Days'),
        icon: Icons.calendar_month_rounded,
        color: SD.green,
        child: NumField(t('عدد الأيام الفاتتك', 'عدد الأيام المفطرة', 'Number of days missed'), _c['days']!, onChanged: (_) => _save(), decimal: false, suffix: t('يوم', 'يوم', 'days')),
      ),
      _measureCard(),
      ResultHero(
        label: t('جملة الفدية', 'إجمالي الفدية', 'Total fidya'),
        value: _money(r.cost),
        sub: _m == FeedMeasure.meal
            ? '$days ${t('وجبة', 'وجبة', 'meals')}'
            : '${fmt(r.kg, 1)} ${t('كيلو', 'كجم', 'kg')} · $days ${t('مسكين/يوم', 'مسكين/يوم', 'poor-person days')}',
      ),
      SCard(
        child: Column(children: [
          InfoRow(t('لليوم الواحد', 'عن اليوم الواحد', 'Per day'), _money(_m == FeedMeasure.meal ? meal : feedKg(_m) * price),
              hint: _m == FeedMeasure.meal ? null : '${fmt(feedKg(_m), 1)} ${t('كيلو', 'كجم', 'kg')}'),
          InfoRow(t('رمضان كامل (30 يوم)', 'شهر كامل (30 يومًا)', 'A full month (30 days)'), _money(feedCost(30, _m, price, meal).cost)),
        ]),
      ),
      NoteBox(
          t('المريض المرجو شفاه والمسافر والحامل والمرضع بيقضوا الأيام (وفي الحامل والمرضع تفصيل)، وما كفاية الفدية براها. الإطعام بالقوت عند الجمهور، والحنفية بيجيزوا دفع القيمة.',
              'المريض الذي يُرجى برؤه والمسافر يقضيان، وللحامل والمرضع تفصيل، ولا تكفي الفدية وحدها. والإطعام يكون بالقوت عند الجمهور، وأجاز الحنفية إخراج القيمة.',
              'Those expected to recover and travellers make up the days (pregnant/nursing women have their own details); fidya alone is not enough for them. The majority require food; Hanafis permit paying its value.')),
      ShareBar(() => [
            '🤲 ${t('فدية الصيام', 'فدية الصيام', 'Fasting fidya')}',
            '${t('الأيام', 'الأيام', 'Days')}: $days',
            '${t('المقدار', 'المقدار', 'Measure')}: ${_measureName(_m)}',
            if (_m != FeedMeasure.meal) '${t('الكمية', 'الكمية', 'Quantity')}: ${fmt(r.kg, 1)} ${t('كيلو', 'كجم', 'kg')}',
            '${t('الجملة', 'الإجمالي', 'Total')}: ${_money(r.cost)}',
          ].join('\n')),
      const SizedBox(height: 12),
    ];
  }

  /* ── (ب) كفارة اليمين ── */
  List<Widget> _yamin(double price, double meal) {
    final n = _v('n_y').round().clamp(1, 100);
    final feed = feedCost(10 * n, _m, price, meal);
    final cloth = 10 * n * _v('cloth');
    return [
      const Padding(
        padding: EdgeInsets.only(bottom: 10),
        child: Text(
            '﴿فَكَفَّارَتُهُ إِطْعَامُ عَشَرَةِ مَسَاكِينَ مِنْ أَوْسَطِ مَا تُطْعِمُونَ أَهْلِيكُمْ أَوْ كِسْوَتُهُمْ أَوْ تَحْرِيرُ رَقَبَةٍ فَمَنْ لَمْ يَجِدْ فَصِيَامُ ثَلَاثَةِ أَيَّامٍ﴾ [المائدة: 89]',
            textAlign: TextAlign.center, textDirection: TextDirection.rtl, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, height: 1.8)),
      ),
      SCard(
        title: t('الترتيب', 'الترتيب', 'The order'),
        icon: Icons.format_list_numbered_rounded,
        color: SD.nile,
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          _step('1', t('تختار واحدة: إطعام 10 مساكين، أو كسوة 10 مساكين، أو عتق رقبة (ما موجود اليوم)', 'يتخيّر بين: إطعام عشرة مساكين، أو كسوتهم، أو عتق رقبة (غير متاح اليوم)',
              'Choose one: feed 10 poor people, clothe 10 poor people, or free a slave (not applicable today)')),
          _step('2', t('لو ما قدرت على أيّ واحدة: صيام 3 أيام', 'فإن عجز عنها كلها: صيام ثلاثة أيام', 'If unable to do any of them: fast 3 days')),
          const SizedBox(height: 6),
          NumField(t('عدد الكفارات', 'عدد الكفارات', 'Number of expiations'), _c['n_y']!, onChanged: (_) => _save(), decimal: false),
        ]),
      ),
      _measureCard(),
      SCard(
        title: t('التكلفة', 'التكلفة', 'Cost'),
        icon: Icons.calculate_rounded,
        color: SD.green,
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          InfoRow(t('إطعام ${10 * n} مسكين', 'إطعام ${10 * n} مساكين', 'Feeding ${10 * n} poor'), _money(feed.cost),
              hint: _m == FeedMeasure.meal ? null : '${fmt(feed.kg, 1)} ${t('كيلو', 'كجم', 'kg')}', valueColor: SD.green),
          const SizedBox(height: 8),
          NumField(t('تمن كسوة المسكين الواحد', 'ثمن كسوة المسكين الواحد', 'Clothing cost per person'), _c['cloth']!, onChanged: (_) => _save(), suffix: _cur,
              hint: t('توب أو جلابية تكفي للصلاة', 'ثوب يجزئ في الصلاة', 'A garment sufficient for prayer')),
          InfoRow(t('كسوة ${10 * n} مسكين', 'كسوة ${10 * n} مساكين', 'Clothing ${10 * n} poor'), _money(cloth), valueColor: SD.nile),
          InfoRow(t('أو الصيام (عند العجز)', 'أو الصيام (عند العجز)', 'Or fasting (if unable)'), lDays(3 * n)),
        ]),
      ),
      NoteBox(t('تتابع الأيام التلاتة واجب عند الحنفية والحنابلة، وما شرط عند المالكية والشافعية. وتعدّد الأيمان والكفارات فيهو تفصيل، اسأل.',
          'التتابع في الأيام الثلاثة واجب عند الحنفية والحنابلة، وليس شرطًا عند المالكية والشافعية. وفي تعدد الأيمان وتداخل كفاراتها تفصيل فاسأل.',
          'Fasting the 3 days consecutively is required by Hanafis and Hanbalis, not by Malikis and Shafi‘is. Multiple oaths have details — ask a scholar.')),
      ShareBar(() => [
            '🤲 ${t('كفارة اليمين', 'كفارة اليمين', 'Oath expiation')} × $n',
            '${t('إطعام', 'إطعام', 'Feeding')} ${10 * n}: ${_money(feed.cost)}',
            '${t('كسوة', 'كسوة', 'Clothing')} ${10 * n}: ${_money(cloth)}',
            '${t('أو صيام', 'أو صيام', 'Or fast')}: ${lDays(3 * n)}',
          ].join('\n')),
      const SizedBox(height: 12),
    ];
  }

  /* ── (ج) كفارة الجماع في نهار رمضان ── */
  List<Widget> _ramadan(double price, double meal) {
    final n = _v('n_r').round().clamp(1, 30);
    final feed = feedCost(60 * n, _m, price, meal);
    final start = _start;
    final end = start == null ? null : lAddDays(start, 60 * n - 1);
    return [
      NoteBox(
          t('الكفارة دي بتجب على من جامع في نهار رمضان وهو صايم عامد. وفوقها لازم يقضي اليوم ويتوب.',
              'تجب هذه الكفارة على من جامع في نهار رمضان صائمًا عامدًا، ويلزمه مع ذلك قضاء اليوم والتوبة.',
              'This expiation is due on one who deliberately had intercourse while fasting in Ramadan, in addition to making up the day and repenting.'),
          kind: NoteKind.warn),
      SCard(
        title: t('الترتيب (لازم بالترتيب)', 'الترتيب (على الترتيب)', 'The order (in sequence)'),
        icon: Icons.format_list_numbered_rounded,
        color: SD.red,
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          _step('1', t('عتق رقبة — ما متاح اليوم', 'عتق رقبة — غير متاح اليوم', 'Freeing a slave — not applicable today'), muted: true),
          _step('2', t('صيام شهرين متتابعين (60 يوم ورا بعض)', 'صيام شهرين متتابعين (60 يومًا)', 'Fasting two consecutive months (60 days)')),
          _step('3', t('لو ما قدر على الصيام: إطعام 60 مسكين', 'فإن لم يستطع: إطعام ستين مسكينًا', 'If unable to fast: feed 60 poor people')),
          const SizedBox(height: 6),
          const Text('«هَلْ تَجِدُ رَقَبَةً تُعْتِقُهَا؟… فَهَلْ تَسْتَطِيعُ أَنْ تَصُومَ شَهْرَيْنِ مُتَتَابِعَيْنِ… فَهَلْ تَجِدُ إِطْعَامَ سِتِّينَ مِسْكِينًا؟» — متفق عليه',
              textDirection: TextDirection.rtl, textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.w700, height: 1.7)),
          const SizedBox(height: 8),
          NumField(t('عدد الكفارات', 'عدد الكفارات', 'Number of expiations'), _c['n_r']!, onChanged: (_) => _save(), decimal: false),
        ]),
      ),
      SCard(
        title: t('خطة الصيام', 'خطة الصيام', 'Fasting plan'),
        icon: Icons.event_repeat_rounded,
        color: SD.indigo,
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          OutlinedButton.icon(
            onPressed: () async {
              final d = await pickDate(
                context: context,
                initialDate: _start ?? lToday(),
                firstDate: DateTime(2000),
                lastDate: DateTime(2100),
                helpText: t('تبدأ الصيام متين؟', 'تاريخ بدء الصيام', 'Start date'),
              );
              if (d == null || !mounted) return;
              _start = d;
              _save();
            },
            icon: const Icon(Icons.calendar_month_rounded),
            label: Text(start == null ? t('اختار يوم البداية', 'اختر يوم البداية', 'Pick a start date') : fmtDateAr(start), maxLines: 1, overflow: TextOverflow.ellipsis),
          ),
          const SizedBox(height: 8),
          InfoRow(t('مدة الصيام', 'مدة الصيام', 'Duration'), lDays(60 * n)),
          if (end != null) InfoRow(t('آخر يوم', 'اليوم الأخير', 'Last day'), fmtDateAr(end), valueColor: SD.green),
          NoteBox(t('لو فطرت يوم في النص بدون عذر بتبدأ العدّ من أول. اتأكد إنو المدة ما فيها يوم عيد (صيامو حرام) واسأل عن التفاصيل.',
              'إن أفطر يومًا أثناءها بغير عذر استأنف العدّ من جديد. وتأكد ألا يتخلل المدة يوم عيد (يحرم صومه)، واسأل عن التفاصيل.',
              'Breaking a day without excuse restarts the count. Make sure the period contains no Eid day (fasting on it is forbidden) and ask about details.')),
        ]),
      ),
      _measureCard(),
      ResultHero(
        label: t('إطعام 60 مسكين (لو عجز عن الصيام)', 'إطعام ستين مسكينًا (عند العجز عن الصيام)', 'Feeding 60 poor (if unable to fast)'),
        value: _money(feed.cost),
        sub: _m == FeedMeasure.meal ? '${60 * n} ${t('وجبة', 'وجبة', 'meals')}' : '${fmt(feed.kg, 1)} ${t('كيلو', 'كجم', 'kg')} · ${60 * n} ${t('مسكين', 'مسكين', 'poor')}',
      ),
      NoteBox(t('لو الجماع اتكرر في أكتر من يوم، تعدّد الكفارة فيهو خلاف بين المذاهب — اسأل عالم.',
          'إذا تكرر الجماع في أكثر من يوم ففي تعدد الكفارة خلاف بين المذاهب — فاسأل عالمًا.',
          'If it happened on more than one day, whether the expiation multiplies differs between schools — ask a scholar.')),
      ShareBar(() => [
            '🤲 ${t('كفارة الجماع في رمضان', 'كفارة الجماع في نهار رمضان', 'Ramadan intercourse expiation')} × $n',
            '${t('الصيام', 'الصيام', 'Fasting')}: ${lDays(60 * n)}${start == null ? '' : ' (${fmtDateAr(start)} → ${fmtDateAr(end!)})'}',
            '${t('أو الإطعام', 'أو الإطعام', 'Or feeding')}: ${60 * n} — ${_money(feed.cost)}',
            t('+ قضاء اليوم', '+ قضاء اليوم', '+ make up the day'),
          ].join('\n')),
      const SizedBox(height: 12),
    ];
  }

  Widget _step(String n, String text, {bool muted = false}) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          CircleAvatar(
            radius: 13,
            backgroundColor: muted ? Colors.grey : SD.gold,
            child: Text(n, style: const TextStyle(fontWeight: FontWeight.w800, color: SD.brownDeep, fontSize: 13)),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(text,
                style: TextStyle(fontWeight: FontWeight.w700, height: 1.4, decoration: muted ? TextDecoration.lineThrough : null)),
          ),
        ]),
      );
}
