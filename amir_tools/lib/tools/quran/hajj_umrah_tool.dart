import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/i18n.dart';
import '../../core/state.dart';
import '../../core/theme.dart';
import '../../core/widgets.dart';
import 'hajj_data.dart';
import 'quran_common.dart';

/// دليل الحج والعمرة خطوة بخطوة مع متابعة التقدّم
class HajjUmrahTool extends StatefulWidget {
  const HajjUmrahTool({super.key});
  @override
  State<HajjUmrahTool> createState() => _HajjUmrahToolState();
}

class _HajjUmrahToolState extends State<HajjUmrahTool> {
  static const _key = 'hajj_umrah_done';
  String _tab = 'umrah';
  final Set<String> _open = {};

  Set<String> _done(AppState s) => Set<String>.from(s.getData<List>(_key) ?? const []);

  void _toggle(AppState s, String id, List<HStep> steps) {
    final d = _done(s);
    d.contains(id) ? d.remove(id) : d.add(id);
    s.setData(_key, d.toList());
    if (d.contains(id) && steps.every((x) => d.contains(x.id))) {
      s.awardDaily('hajj_umrah_$_tab', 20, _tab == 'umrah' ? tr('إتمام خطوات العمرة', 'Completed the Umrah steps') : tr('إتمام خطوات الحج', 'Completed the Hajj steps'));
      toast(_tab == 'umrah'
          ? t('تقبّل الله عمرتك 🤲', 'تقبّل الله عمرتك 🤲', 'May Allah accept your Umrah 🤲')
          : t('حجًّا مبرورًا وسعيًا مشكورًا 🤲', 'حجًّا مبرورًا وسعيًا مشكورًا 🤲', 'May Allah accept your Hajj 🤲'));
    }
    setState(() {});
  }

  void _reset(AppState s, List<HStep> steps) {
    final d = _done(s)..removeAll(steps.map((e) => e.id));
    s.setData(_key, d.toList());
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    return ToolList(children: [
      SegmentedButton<String>(
        showSelectedIcon: false,
        segments: [
          ButtonSegment(value: 'umrah', label: _seg(tr('العمرة', 'Umrah'))),
          ButtonSegment(value: 'hajj', label: _seg(tr('الحج', 'Hajj'))),
          ButtonSegment(value: 'notes', label: _seg(t('تنبيهات', 'تنبيهات', 'Rules'))),
        ],
        selected: {_tab},
        onSelectionChanged: (v) => setState(() => _tab = v.first),
      ),
      const SizedBox(height: 14),
      ...switch (_tab) {
        'hajj' => _hajj(s),
        'notes' => _notes(),
        _ => _umrah(s),
      },
      NoteBox(
          t('الدليل ده تعريف مختصر بالمناسك وما بيغني عن سؤال العلماء. اتّبع إرشادات وزارة الحج والعمرة السعودية والجهات الرسمية (زي تطبيق «نسك» للتصاريح)، ومرشد حملتك.',
              'هذا الدليل تعريف مختصر بالمناسك ولا يغني عن سؤال أهل العلم. اتّبع إرشادات وزارة الحج والعمرة السعودية والجهات الرسمية (مثل تطبيق «نسك» للتصاريح)، ومرشد حملتك.',
              'This is a brief guide to the rites and is no substitute for asking scholars. Follow the Saudi Ministry of Hajj and Umrah and official channels (e.g. the Nusuk app for permits), and your group\'s guide.'),
          kind: NoteKind.warn),
      Text(
          '${tr('المصادر', 'Sources')}: ${tr('صفة حج النبي ﷺ (حديث جابر في صحيح مسلم)، وكتب المناسك المعتمدة في المذاهب الأربعة، وإرشادات وزارة الحج والعمرة بالمملكة العربية السعودية.', 'The Prophet\'s ﷺ Hajj (hadith of Jabir, Sahih Muslim), standard fiqh manuals of the four schools, and guidance of the Saudi Ministry of Hajj and Umrah.')}',
          style: TextStyle(fontSize: 12.5, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: .7), height: 1.5)),
      const ReviewedLine('hajj_umrah', 'manasik guide'),
    ]);
  }

  Widget _seg(String s) => FittedBox(fit: BoxFit.scaleDown, child: Text(s, maxLines: 1));

  Widget _progress(AppState s, List<HStep> steps, String title) {
    final d = _done(s);
    final n = steps.where((x) => d.contains(x.id)).length;
    final p = steps.isEmpty ? 0.0 : n / steps.length;
    return SCard(
      title: title,
      icon: Icons.flag_circle_rounded,
      color: SD.green,
      trailing: n == 0
          ? null
          : IconButton(tooltip: t('ابدأ من جديد', 'ابدأ من جديد', 'Start over'), icon: const Icon(Icons.restart_alt_rounded), onPressed: () => _reset(s, steps)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Row(children: [
          Expanded(
            child: Text('$n / ${steps.length} ${t('خطوات تمّت', 'خطوات منجزة', 'steps done')}',
                maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w800)),
          ),
          Text('${(p * 100).round()}%', style: TextStyle(fontWeight: FontWeight.w800, color: readable(context, SD.green))),
        ]),
        const SizedBox(height: 8),
        ClipRRect(borderRadius: BorderRadius.circular(8), child: LinearProgressIndicator(value: p, minHeight: 10, color: SD.green)),
        const SizedBox(height: 6),
        Text(t('علّم كل خطوة لمن تخلّصها عشان تتابع رحلتك.', 'علّم كل خطوة عند إنجازها لتتابع رحلتك.', 'Tick each step as you complete it to track your journey.'),
            style: TextStyle(fontSize: 12.5, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: .7))),
      ]),
    );
  }

  Widget _step(AppState s, HStep st, int i, List<HStep> all) {
    final done = _done(s).contains(st.id);
    final open = _open.contains(st.id);
    final cs = Theme.of(context).colorScheme;
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: () => setState(() => open ? _open.remove(st.id) : _open.add(st.id)),
          child: Padding(
            padding: const EdgeInsetsDirectional.fromSTEB(4, 6, 12, 6),
            child: Row(children: [
              Checkbox(value: done, onChanged: (_) => _toggle(s, st.id, all)),
              CircleAvatar(
                radius: 13,
                backgroundColor: (done ? SD.green : SD.gold).withValues(alpha: .25),
                child: FittedBox(fit: BoxFit.scaleDown, child: Text('${i + 1}', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13))),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(st.title(),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontWeight: FontWeight.w800, decoration: done ? TextDecoration.lineThrough : null, color: done ? cs.onSurface.withValues(alpha: .6) : null)),
              ),
              Icon(open ? Icons.expand_less_rounded : Icons.expand_more_rounded),
            ]),
          ),
        ),
        if (open)
          Padding(
            padding: const EdgeInsetsDirectional.fromSTEB(16, 0, 16, 14),
            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              for (final p in st.points())
                Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Padding(padding: const EdgeInsets.only(top: 7), child: Icon(Icons.circle, size: 7, color: readable(context, SD.goldDeep))),
                    const SizedBox(width: 8),
                    Expanded(child: Text(p, style: const TextStyle(height: 1.6))),
                  ]),
                ),
              if (st.id == 'u_ihram') _miqatBox(),
              for (final d in st.duas) _duaBox(d),
              if (st.madhab != null) _madhabBox(st.madhab!()),
            ]),
          ),
      ]),
    );
  }

  Widget _miqatBox() => Container(
        margin: const EdgeInsets.only(top: 4, bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(16), border: Border.all(color: SD.nile.withValues(alpha: .5)), color: SD.nile.withValues(alpha: .07)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Text(t('المواقيت الخمسة', 'المواقيت المكانية الخمسة', 'The five miqats'), style: const TextStyle(fontWeight: FontWeight.w800)),
          const SizedBox(height: 6),
          for (final (n, w) in miqats)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(n, style: TextStyle(fontWeight: FontWeight.w800, color: readable(context, SD.nile))),
                Text(w, style: const TextStyle(fontSize: 13)),
              ]),
            ),
          Text(
              tr('وقّتها النبي ﷺ (متفق عليه من حديث ابن عباس للأربعة الأولى، وذات عرق في صحيح مسلم وسنن أبي داود والنسائي).',
                  'Set by the Prophet ﷺ (Al-Bukhari & Muslim from Ibn Abbas for the first four; Dhat Irq in Muslim, Abu Dawud and an-Nasa\'i).'),
              style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: .7))),
        ]),
      );

  Widget _duaBox(HDua d) => Container(
        margin: const EdgeInsets.only(top: 6, bottom: 6),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(16), border: Border.all(color: SD.gold.withValues(alpha: .7)), color: SD.gold.withValues(alpha: .08)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Text(d.text, textAlign: TextAlign.center, textDirection: TextDirection.rtl, style: const TextStyle(fontSize: 18, height: 1.8, fontWeight: FontWeight.w700)),
          if (isEn && d.meaningEn != null) ...[
            const SizedBox(height: 4),
            Text(d.meaningEn!, textAlign: TextAlign.center, style: const TextStyle(fontSize: 13, fontStyle: FontStyle.italic)),
          ],
          const SizedBox(height: 6),
          Text(d.source, textAlign: TextAlign.center, style: TextStyle(fontSize: 12, color: readable(context, SD.goldDeep), fontWeight: FontWeight.w700)),
          Align(
            alignment: AlignmentDirectional.centerEnd,
            child: IconButton(
              tooltip: tr('نسخ', 'Copy'),
              icon: const Icon(Icons.copy_rounded, size: 18),
              onPressed: () => copyText('${d.text}\n— ${d.srcAr}'),
            ),
          ),
        ]),
      );

  Widget _madhabBox(String s) => Container(
        margin: const EdgeInsets.only(top: 6),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(14), color: SD.indigo.withValues(alpha: .1)),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Icon(Icons.balance_rounded, size: 18, color: readable(context, SD.indigo)),
          const SizedBox(width: 8),
          Expanded(child: Text('${t('خلاف المذاهب', 'خلاف المذاهب', 'Schools differ')}: $s', style: const TextStyle(fontSize: 13, height: 1.5))),
        ]),
      );

  List<Widget> _umrah(AppState s) {
    final steps = umrahSteps;
    return [
      _progress(s, steps, t('رحلة العمرة', 'رحلة العمرة', 'Umrah journey')),
      NoteBox(
          t('أركان العمرة: الإحرام والطواف والسعي. وواجباتها: الإحرام من الميقات والحلق أو التقصير.', 'أركان العمرة: الإحرام والطواف والسعي. وواجباتها: الإحرام من الميقات، والحلق أو التقصير.',
              'Pillars of Umrah: ihram, tawaf and sa\'i. Obligations: ihram from the miqat, and shaving or trimming.'),
          kind: NoteKind.tip),
      for (var i = 0; i < steps.length; i++) _step(s, steps[i], i, steps),
      _packing(),
    ];
  }

  List<Widget> _hajj(AppState s) {
    final steps = hajjSteps;
    return [
      _progress(s, steps, t('رحلة الحج', 'رحلة الحج', 'Hajj journey')),
      SCard(
        title: t('أنواع النُّسُك', 'أنواع النسك', 'Types of Hajj'),
        icon: Icons.category_rounded,
        color: SD.indigo,
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          for (final (n, d) in hajjTypes)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(n, style: TextStyle(fontWeight: FontWeight.w800, color: readable(context, SD.indigo))),
                Text(d, style: const TextStyle(height: 1.5)),
              ]),
            ),
          _madhabBox(tr('الأفضل عند الحنابلة التمتّع، وعند الحنفية القِران، وعند المالكية والشافعية الإفراد؛ والهدي على غير حاضري المسجد الحرام، ومن لم يجده صام ثلاثة أيام في الحج وسبعة إذا رجع (البقرة: 196).',
              'Best type: tamattu\' (Hanbali), qiran (Hanafi), ifrad (Maliki & Shafi\'i). Hady is due on those not residing at al-Masjid al-Haram; whoever cannot find one fasts three days during Hajj and seven on return (Qur\'an 2:196).')),
        ]),
      ),
      NoteBox(
          t('أركان الحج: الإحرام، والوقوف بعرفة، وطواف الإفاضة، والسعي. ومن واجباته: الإحرام من الميقات، والبقاء بعرفة للغروب، والمبيت بمزدلفة وبمنى، والرمي، والحلق أو التقصير، وطواف الوداع. وفي حكم بعضها خلاف، وترك الواجب يُجبر بدم عند الجمهور.',
              'أركان الحج: الإحرام، والوقوف بعرفة، وطواف الإفاضة، والسعي. ومن واجباته: الإحرام من الميقات، والبقاء بعرفة إلى الغروب، والمبيت بمزدلفة ومنى، والرمي، والحلق أو التقصير، وطواف الوداع. وفي حكم بعضها خلاف، وترك الواجب يُجبر بدم عند الجمهور.',
              'Pillars of Hajj: ihram, standing at Arafah, Tawaf al-Ifadah and sa\'i. Obligations include: ihram from the miqat, staying at Arafah until sunset, nights at Muzdalifah and Mina, stoning, shaving/trimming, and the farewell tawaf. Schools differ on some; a missed obligation is compensated by a sacrifice according to the majority.'),
          kind: NoteKind.tip),
      for (var i = 0; i < steps.length; i++) _step(s, steps[i], i, steps),
      NoteBox(
          t('الحائض بتعمل كل المناسك غير الطواف بالبيت لحدي ما تطهر (متفق عليه).', 'الحائض تفعل المناسك كلها غير الطواف بالبيت حتى تطهر (متفق عليه).',
              'A menstruating woman does all the rites except tawaf until she becomes pure (Al-Bukhari & Muslim).'),
          kind: NoteKind.info),
      _packing(),
    ];
  }

  List<Widget> _notes() => [
        SCard(
          title: t('محظورات الإحرام', 'محظورات الإحرام', 'Ihram prohibitions'),
          icon: Icons.block_rounded,
          color: SD.red,
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            for (final p in ihramProhibitions) _bullet(p, SD.red),
            const SizedBox(height: 4),
            Text(
                t('من وقع في محظور ناسيًا أو جاهلًا أو محتاجًا ففي حكمه وفديته تفصيل وخلاف — اسأل عالمًا.', 'من وقع في محظور ناسيًا أو جاهلًا أو لحاجة ففي حكمه وفديته تفصيل وخلاف — اسأل أهل العلم.',
                    'Committing a prohibition by forgetfulness, ignorance or need has detailed rulings on expiation with differences — ask a scholar.'),
                style: TextStyle(fontSize: 12.5, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: .75))),
          ]),
        ),
        SCard(
          title: t('أخطاء شائعة', 'أخطاء شائعة', 'Common mistakes'),
          icon: Icons.report_gmailerrorred_rounded,
          color: SD.orange,
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [for (final p in commonMistakes) _bullet(p, SD.orange)]),
        ),
        SCard(
          title: tr('التلبية', 'Talbiyah'),
          icon: Icons.record_voice_over_rounded,
          color: SD.gold,
          child: _duaBox(talbiyah),
        ),
        _packing(),
      ];

  Widget _bullet(String s, Color c) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Padding(padding: const EdgeInsets.only(top: 3), child: Icon(Icons.chevron_right_rounded, size: 18, color: readable(context, c))),
          const SizedBox(width: 6),
          Expanded(child: Text(s, style: const TextStyle(height: 1.55))),
        ]),
      );

  Widget _packing() => NoteBox(
      t('للشنطة: في أداة «قائمة تجهيز السفر» قالب جاهز اسمه «عمرة / حج».', 'لتجهيز الحقيبة: في أداة «قائمة تجهيز السفر» قالب جاهز باسم «عمرة / حج».',
          'For packing: the “Travel Packing List” tool has a ready “Umrah / Hajj” template.'),
      kind: NoteKind.tip);
}
