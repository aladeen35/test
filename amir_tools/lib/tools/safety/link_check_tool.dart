import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../core/format.dart';
import '../../core/i18n.dart';
import '../../core/state.dart';
import '../../core/theme.dart';
import '../../core/widgets.dart';
import 'link_logic.dart';
import 'safety_common.dart';

/// نص العلامة للعرض (عنوان + شرح)
(String, String) flagText(LinkFlag f) {
  final d = f.detail;
  return switch (f.code) {
    'dangerous_scheme' => (
        t('رابط برمجي خطير ($d:)', 'رابط برمجي خطير ($d:)', 'Dangerous script link ($d:)'),
        t('الرابط ده بيشغّل كود أو ملف بدل ما يفتح موقع — ما تفتحه.', 'هذا الرابط يشغّل كودًا أو ملفًا بدل فتح موقع — لا تفتحه.', 'This runs code or a file instead of opening a site — do not open it.'),
      ),
    'odd_scheme' => (
        t('نوع رابط غير معتاد ($d)', 'نوع رابط غير معتاد ($d)', 'Unusual link type ($d)'),
        t('المواقع العادية بتبدأ بـ https.', 'المواقع العادية تبدأ بـ https.', 'Normal websites start with https.'),
      ),
    'http' => (
        t('غير مشفّر (http)', 'غير مشفّر (http)', 'Not encrypted (http)'),
        t('أي بيانات تكتبها ممكن تنقرأ في الطريق. ما تكتب كلمة سر في صفحة http.', 'قد تُقرأ أي بيانات تكتبها أثناء النقل. لا تكتب كلمة سر في صفحة http.',
            'Anything you type can be read in transit. Never enter a password on an http page.'),
      ),
    'no_scheme' => (
        t('الرابط بدون http/https', 'الرابط بلا http/https', 'No http/https given'),
        t('فحصنا العنوان كما هو.', 'فحصنا العنوان كما هو.', 'We checked the address as-is.'),
      ),
    'at_sign' => (
        t('فيه علامة @ قبل اسم الموقع', 'يحتوي علامة @ قبل اسم الموقع', 'Contains @ before the site name'),
        t('كل الكلام القبل @ ($d) بيتجاهله المتصفح — الموقع الحقيقي هو البعدها. حيلة تصيّد معروفة.',
            'المتصفح يتجاهل ما قبل @ ($d) — الموقع الحقيقي هو ما بعدها. حيلة تصيّد معروفة.',
            'Browsers ignore everything before @ ($d) — the real site is what follows. A classic phishing trick.'),
      ),
    'ip_host' => (
        t('عنوان IP بدل اسم موقع', 'عنوان IP بدل اسم موقع', 'IP address instead of a name'),
        t('المواقع المعروفة ما بتستعمل أرقام. الروابط دي غالبًا مؤقتة أو مشبوهة.', 'المواقع المعروفة لا تستخدم أرقامًا. هذه الروابط غالبًا مؤقتة أو مشبوهة.',
            'Real services use names, not numbers. Such links are often temporary or suspicious.'),
      ),
    'port' => (
        t('منفذ غير معتاد (:$d)', 'منفذ غير معتاد (:$d)', 'Unusual port (:$d)'),
        t('المواقع العادية ما بتحتاج رقم منفذ.', 'المواقع العادية لا تحتاج رقم منفذ.', 'Normal sites do not need a port number.'),
      ),
    'punycode' => (
        t('اسم بحروف غير إنجليزية (xn--)', 'اسم بحروف غير لاتينية (xn--)', 'Non-Latin letters (xn--)'),
        t('الاسم الحقيقي: $d — ممكن يكون حروف شبه الإنجليزية لخداعك.', 'الاسم الحقيقي: $d — قد تكون حروفًا تشبه اللاتينية لخداعك.',
            'Real name: $d — may use lookalike letters to fool you.'),
      ),
    'mixed_script' => (
        t('حروف من لغات مخلوطة', 'حروف من لغات مختلطة', 'Mixed alphabets'),
        t('في الجزء «$d» حروف من أكتر من لغة (مثلًا روسي وإنجليزي) — دي حيلة انتحال.', 'في الجزء «$d» حروف من أكثر من لغة (كالسيريلية واللاتينية) — حيلة انتحال.',
            'The part "$d" mixes alphabets (e.g. Cyrillic + Latin) — an impersonation trick.'),
      ),
    'non_ascii' => (
        t('حروف غير إنجليزية', 'حروف غير لاتينية', 'Non-Latin letters'),
        t('مش بالضرورة خطر، بس اتأكد إنه الموقع المقصود.', 'ليس خطرًا بالضرورة، لكن تأكد أنه الموقع المقصود.', 'Not necessarily bad, but make sure it is the intended site.'),
      ),
    'shortener' => (
        t('رابط مختصر ($d)', 'رابط مختصر ($d)', 'Shortened link ($d)'),
        t('ما بيوريك الوجهة الحقيقية. افتحه بس لو بتثق في المرسل.', 'يخفي الوجهة الحقيقية. افتحه فقط إن كنت تثق بالمرسل.', 'Hides the real destination. Only open if you trust the sender.'),
      ),
    'tld' => (
        t('امتداد مشبوه ($d)', 'امتداد مشبوه ($d)', 'Suspicious ending ($d)'),
        t('الامتداد ده رخيص أو كتير الاستعمال في الاحتيال (أو بيشبه امتداد ملف).', 'هذا الامتداد رخيص أو شائع في الاحتيال (أو يشبه امتداد ملف).',
            'This ending is cheap or common in scams (or looks like a file extension).'),
      ),
    'many_subdomains' => (
        t('نطاقات فرعية كتيرة ($d)', 'نطاقات فرعية كثيرة ($d)', 'Many subdomains ($d)'),
        t('تطويل الرابط بيخبّي الاسم الحقيقي في الآخر.', 'إطالة الرابط تخفي الاسم الحقيقي في آخره.', 'Long chains hide the real name at the end.'),
      ),
    'hyphens' => (
        t('شرطات كتيرة في الاسم', 'شرطات كثيرة في الاسم', 'Many hyphens in the name'),
        t('زي secure-login-bank — نمط شائع في التصيّد.', 'مثل secure-login-bank — نمط شائع في التصيّد.', 'Like secure-login-bank — a common phishing pattern.'),
      ),
    'digits_in_name' => (
        t('أرقام وحروف مخلوطة في الاسم', 'أرقام وحروف مختلطة في الاسم', 'Digits mixed into the name'),
        t('الأسماء العشوائية الطويلة علامة مواقع مؤقتة.', 'الأسماء العشوائية الطويلة علامة مواقع مؤقتة.', 'Long random names suggest throwaway sites.'),
      ),
    'brand_lookalike' => (
        t('بيشبه اسم «$d» لكنه مش موقعهم', 'يشبه اسم «$d» لكنه ليس موقعهم', 'Looks like "$d" but is not theirs'),
        t('النطاق الحقيقي ما من نطاقات $d الرسمية المعروفة لينا — ممكن يكون انتحال.', 'النطاق الحقيقي ليس من نطاقات $d الرسمية المعروفة لدينا — قد يكون انتحالًا.',
            'The real domain is not one of $d\'s official domains we know — possible impersonation.'),
      ),
    'brand_in_sub' => (
        t('اسم «$d» في أول الرابط بس', 'اسم «$d» في أول الرابط فقط', '"$d" only at the start'),
        t('الاسم المعروف موضوع كنطاق فرعي، لكن الموقع الحقيقي حاجة تانية (شوف «النطاق الحقيقي»).', 'الاسم المعروف موضوع كنطاق فرعي، لكن الموقع الحقيقي شيء آخر (انظر «النطاق الحقيقي»).',
            'The famous name is just a subdomain; the real site is something else (see "Real domain").'),
      ),
    'brand_in_path' => (
        t('اسم «$d» في آخر الرابط', 'اسم «$d» في آخر الرابط', '"$d" in the path'),
        t('ذكر اسم جهة في المسار ما بيعني إنه موقعها.', 'ذكر اسم جهة في المسار لا يعني أنه موقعها.', 'A brand name in the path does not make it their site.'),
      ),
    'keywords' => (
        t('كلمات تصيّد ($d)', 'كلمات تصيّد ($d)', 'Phishing words ($d)'),
        t('كلمات زي login وverify وgift بتتكرر في روابط النصب.', 'كلمات مثل login وverify وgift تتكرر في روابط الاحتيال.', 'Words like login, verify and gift are common in scam links.'),
      ),
    'file_download' => (
        t('بينزّل ملف ($d)', 'ينزّل ملفًا ($d)', 'Downloads a file ($d)'),
        t('ملفات التطبيقات الجاية من روابط ممكن تتجسس على تلفونك وتقرأ أكواد البنك.', 'ملفات التطبيقات من الروابط قد تتجسس على هاتفك وتقرأ أكواد البنك.',
            'App files from links can spy on your phone and read bank codes.'),
      ),
    'redirect_param' => (
        t('فيه تحويل لرابط تاني', 'يحتوي تحويلًا لرابط آخر', 'Contains a redirect'),
        t('الرابط ممكن يوديك لموقع تاني غير الظاهر.', 'قد يأخذك الرابط إلى موقع آخر غير الظاهر.', 'It may send you to a different site than shown.'),
      ),
    'encoded' => (
        t('رموز مشفّرة كتيرة (%)', 'رموز مُرمّزة كثيرة (%)', 'Heavily encoded (%)'),
        t('الترميز الكتير ممكن يخبّي الوجهة.', 'كثرة الترميز قد تخفي الوجهة.', 'Heavy encoding can hide the destination.'),
      ),
    'long_url' => (
        t('رابط طويل شديد ($d حرف)', 'رابط طويل جدًا ($d حرفًا)', 'Very long link ($d chars)'),
        t('الطول بيصعّب تشوف الاسم الحقيقي.', 'الطول يصعّب رؤية الاسم الحقيقي.', 'Length makes the real name hard to spot.'),
      ),
    _ => (f.code, d),
  };
}

String riskLabel(LinkRisk r) => switch (r) {
      LinkRisk.low => t('خطر قليل', 'خطورة منخفضة', 'Low risk'),
      LinkRisk.medium => t('خطر متوسط', 'خطورة متوسطة', 'Medium risk'),
      LinkRisk.high => t('خطر عالي', 'خطورة عالية', 'High risk'),
    };

Color riskColor(LinkRisk r) => switch (r) { LinkRisk.low => SD.green, LinkRisk.medium => SD.orange, LinkRisk.high => SD.red };

class LinkCheckTool extends StatefulWidget {
  const LinkCheckTool({super.key});
  @override
  State<LinkCheckTool> createState() => _LinkCheckToolState();
}

class _LinkCheckToolState extends State<LinkCheckTool> {
  final c = TextEditingController();
  LinkReport? rep;

  @override
  void dispose() {
    c.dispose();
    super.dispose();
  }

  List<Map<String, dynamic>> _hist(AppState s) =>
      (s.getData<List>('link_check_hist') ?? []).whereType<Map>().map((m) => Map<String, dynamic>.from(m)).toList();

  void _check(AppState s, [String? text]) {
    if (text != null) c.text = text;
    final v = c.text.trim();
    if (v.isEmpty) {
      setState(() => rep = null);
      return;
    }
    final r = analyzeLink(v);
    setState(() => rep = r);
    FocusScope.of(context).unfocus();
    if (!r.valid) return;
    final h = _hist(s)..removeWhere((m) => m['u'] == r.url);
    h.insert(0, {'u': r.url.length > 300 ? r.url.substring(0, 300) : r.url, 'd': r.domain, 'r': r.risk.index, 's': r.score, 't': DateTime.now().millisecondsSinceEpoch});
    s.setData('link_check_hist', h.take(15).toList());
    s.bump('links_checked');
    s.awardDaily('link_check', 5, t('فحصت رابط', 'فحص رابط', 'Checked a link'));
  }

  Future<void> _paste(AppState s) async {
    final d = await Clipboard.getData(Clipboard.kTextPlain);
    final txt = d?.text?.trim() ?? '';
    if (txt.isEmpty) {
      toast(t('الحافظة فاضية', 'الحافظة فارغة', 'Clipboard is empty'));
      return;
    }
    _check(s, txt);
  }

  Future<void> _openAnyway(LinkReport r) async {
    final high = r.risk == LinkRisk.high;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        icon: Icon(high ? Icons.gpp_bad_rounded : Icons.open_in_browser_rounded, color: riskColor(r.risk), size: 36),
        title: Text(high ? t('متأكد؟ الرابط ده خطير', 'هل أنت متأكد؟ الرابط خطير', 'Sure? This link looks dangerous') : t('تفتح الرابط؟', 'فتح الرابط؟', 'Open the link?')),
        content: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Text('${t('الموقع الحقيقي', 'الموقع الحقيقي', 'Real site')}:', style: const TextStyle(fontWeight: FontWeight.w700)),
          Text(r.domain.isEmpty ? r.url : r.domain,
              textDirection: TextDirection.ltr, style: TextStyle(fontWeight: FontWeight.w800, fontSize: 17, color: readable(ctx, riskColor(r.risk)))),
          const SizedBox(height: 10),
          Text(t('ما تكتب كلمة سر ولا رمز ولا بيانات بطاقة في الصفحة دي إلا لو متأكد 100%.', 'لا تكتب كلمة سر أو رمزًا أو بيانات بطاقة في هذه الصفحة إلا إن كنت متأكدًا تمامًا.',
              'Do not enter passwords, codes or card details on this page unless you are 100% sure.')),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(t('لا خلاص', 'إلغاء', 'Cancel'))),
          FilledButton(
            style: high ? FilledButton.styleFrom(backgroundColor: SD.red, foregroundColor: Colors.white) : null,
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(t('افتحه برضو', 'افتحه على أي حال', 'Open anyway')),
          ),
        ],
      ),
    );
    if (ok != true) return;
    var u = r.url;
    if (!RegExp(r'^[a-zA-Z][a-zA-Z0-9+.\-]*://').hasMatch(u)) u = 'https://$u';
    await safetyOpen(u);
  }

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final r = rep;
    final hist = _hist(s);
    return ToolList(children: [
      SCard(
        title: t('الصق الرابط المشكوك فيه', 'الصق الرابط المشكوك فيه', 'Paste the suspicious link'),
        icon: Icons.link_rounded,
        color: SD.nile,
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          TextField(
            controller: c,
            textDirection: TextDirection.ltr,
            keyboardType: TextInputType.url,
            autocorrect: false,
            minLines: 1,
            maxLines: 4,
            onSubmitted: (_) => _check(s),
            decoration: InputDecoration(
              hintText: 'https://…',
              hintTextDirection: TextDirection.ltr,
              suffixIcon: c.text.isEmpty
                  ? null
                  : IconButton(
                      tooltip: tr('مسح', 'Clear'),
                      icon: const Icon(Icons.clear_rounded),
                      onPressed: () => setState(() {
                        c.clear();
                        rep = null;
                      }),
                    ),
            ),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 10),
          Row(children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _paste(s),
                icon: const Icon(Icons.content_paste_rounded),
                label: FittedBox(fit: BoxFit.scaleDown, child: Text(t('الصق وافحص', 'لصق وفحص', 'Paste & check'))),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: FilledButton.icon(
                onPressed: () => _check(s),
                icon: const Icon(Icons.policy_rounded),
                label: FittedBox(fit: BoxFit.scaleDown, child: Text(t('افحص', 'افحص', 'Check'))),
              ),
            ),
          ]),
          const SizedBox(height: 6),
          Text(t('بنفحص بدون إنترنت وما بنفتح الرابط. ممكن تلصق الرسالة كلها وبنطلّع الرابط منها.', 'نفحص دون إنترنت ولا نفتح الرابط. يمكنك لصق الرسالة كاملة وسنستخرج الرابط منها.',
              'Checked offline — the link is not opened. You can paste a whole message and we will extract the link.'),
              style: TextStyle(fontSize: 12.5, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: .6))),
        ]),
      ),
      if (r != null && !r.valid)
        NoteBox(t('ده ما شكله رابط موقع. اتأكد إنك نسخته كامل.', 'لا يبدو هذا رابط موقع. تأكد من نسخه كاملًا.', 'This does not look like a web link. Make sure you copied all of it.'),
            kind: NoteKind.warn),
      if (r != null && r.valid) ..._result(context, r),
      if (r == null) ...[
        SCard(
          title: t('جرّب أمثلة', 'جرّب أمثلة', 'Try examples'),
          icon: Icons.science_rounded,
          color: SD.purple,
          child: Wrap(spacing: 8, runSpacing: 8, children: [
            for (final ex in const ['https://www.whatsapp.com', 'http://faceb00k-login.xyz/verify', 'https://paypal.com.secure-update.top', 'bit.ly/3xYz', 'https://xn--80ak6aa92e.com'])
              ActionChip(
                label: Text(ex, textDirection: TextDirection.ltr, maxLines: 1, overflow: TextOverflow.ellipsis),
                onPressed: () => _check(s, ex),
              ),
          ]),
        ),
      ],
      _disclaimer(),
      if (hist.isNotEmpty)
        SCard(
          title: t('آخر الروابط', 'آخر الروابط', 'Recent checks'),
          icon: Icons.history_rounded,
          color: SD.coffee,
          trailing: IconButton(
            tooltip: t('امسح السجل', 'مسح السجل', 'Clear history'),
            icon: const Icon(Icons.delete_sweep_rounded),
            onPressed: () => s.setData('link_check_hist', <Map>[]),
          ),
          child: Column(children: [
            StatGrid([
              StatChip('${s.counter('links_checked')}', t('روابط فحصتها', 'روابط فحصتها', 'Links checked'), color: SD.nile, icon: Icons.policy_rounded),
              StatChip('${hist.where((m) => m['r'] == LinkRisk.high.index).length}', t('خطيرة (الأخيرة)', 'خطيرة (الأخيرة)', 'High (recent)'), color: SD.red, icon: Icons.gpp_bad_rounded),
              StatChip('${hist.where((m) => m['r'] == LinkRisk.low.index).length}', t('قليلة الخطر', 'منخفضة الخطر', 'Low (recent)'), color: SD.green, icon: Icons.gpp_good_rounded),
            ]),
            const SizedBox(height: 8),
            for (final m in hist.take(8))
              ListTile(
                contentPadding: EdgeInsets.zero,
                dense: true,
                leading: Icon(Icons.circle, size: 14, color: riskColor(LinkRisk.values[(m['r'] as num? ?? 0).toInt().clamp(0, 2)])),
                title: Text('${m['d'] ?? ''}', maxLines: 1, overflow: TextOverflow.ellipsis, textDirection: TextDirection.ltr, style: const TextStyle(fontWeight: FontWeight.w700)),
                subtitle: Text('${riskLabel(LinkRisk.values[(m['r'] as num? ?? 0).toInt().clamp(0, 2)])} · ${fmtDateAr(DateTime.fromMillisecondsSinceEpoch((m['t'] as num? ?? 0).toInt()), weekday: false)}',
                    maxLines: 1, overflow: TextOverflow.ellipsis),
                onTap: () => _check(s, '${m['u']}'),
              ),
          ]),
        ),
      const ReviewedLine('link_check', item: 'brand/shortener lists'),
    ]);
  }

  Widget _disclaimer() => NoteBox(
      t('الفحص ده تقديري (قواعد معروفة) وما ضمان: رابط «خطره قليل» ممكن يكون نصب، وموقع سليم ممكن يطلع عليه تحذير. لو الرسالة بتستعجلك وبتطلب بيانات — ما تفتحه.',
          'هذا الفحص تقديري (قواعد معروفة) وليس ضمانًا: رابط «منخفض الخطورة» قد يكون احتيالًا، وموقع سليم قد يظهر عليه تحذير. إن كانت الرسالة تستعجلك وتطلب بيانات — لا تفتحه.',
          'This is a heuristic check, not a guarantee: a "low risk" link can still be a scam, and a safe site may get a warning. If the message rushes you for details — don\'t open it.'),
      kind: NoteKind.warn);

  List<Widget> _result(BuildContext context, LinkReport r) {
    final rc = riskColor(r.risk);
    final muted = Theme.of(context).colorScheme.onSurface.withValues(alpha: .6);
    final sorted = [...r.flags.where((f) => f.weight > 0)]..sort((a, b) => b.weight.compareTo(a.weight));
    final info = r.flags.where((f) => f.weight == 0).toList();
    return [
      ResultHero(
        label: t('النتيجة', 'النتيجة', 'Result'),
        value: riskLabel(r.risk),
        sub: '${t('نقاط الخطر', 'نقاط الخطر', 'Risk points')}: ${r.score} · ${sorted.length} ${t('سبب', 'سبب', 'reason(s)')}',
        colors: switch (r.risk) {
          LinkRisk.low => const [Color(0xFF0B6B32), Color(0xFF075226), Color(0xFF033815)],
          LinkRisk.medium => const [Color(0xFFE2702B), Color(0xFFB4492D), Color(0xFF6E2A12)],
          LinkRisk.high => const [Color(0xFFB0182E), Color(0xFF7A0F1F), Color(0xFF450812)],
        },
      ),
      SCard(
        title: t('النطاق الحقيقي', 'النطاق الحقيقي', 'Real domain'),
        icon: Icons.domain_verification_rounded,
        color: rc,
        trailing: r.domain.isEmpty
            ? null
            : IconButton(tooltip: t('انسخ النطاق', 'نسخ النطاق', 'Copy domain'), icon: const Icon(Icons.copy_rounded), onPressed: () => copyText(r.domain)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          if (r.domain.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: rc.withValues(alpha: .1), borderRadius: BorderRadius.circular(14), border: Border.all(color: readable(context, rc).withValues(alpha: .4))),
              child: Directionality(
                textDirection: TextDirection.ltr,
                child: Text.rich(
                  TextSpan(children: [
                    if (r.subdomains.isNotEmpty) TextSpan(text: '${r.subdomains}.', style: TextStyle(color: muted, fontSize: 15)),
                    TextSpan(text: r.domain, style: TextStyle(color: readable(context, rc), fontSize: 21, fontWeight: FontWeight.w900)),
                  ]),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          const SizedBox(height: 6),
          Text(
              t('الجزء الملوّن هو صاحب الموقع الفعلي — أي كلام قبله ممكن أي زول يكتبه.', 'الجزء الملوّن هو صاحب الموقع الفعلي — أي كلام قبله يمكن لأي أحد كتابته.',
                  'The coloured part is who really owns the site — anything before it can be written by anyone.'),
              style: TextStyle(fontSize: 12.5, color: muted)),
          if (r.officialBrand != null)
            NoteBox(
                t('النطاق ده من نطاقات «${r.officialBrand}» الرسمية المعروفة لينا. برضو اتأكد من باقي الرابط.', 'هذا النطاق من نطاقات «${r.officialBrand}» الرسمية المعروفة لدينا. مع ذلك تحقق من بقية الرابط.',
                    'This is one of the official "${r.officialBrand}" domains we know. Still check the rest of the link.'),
                kind: NoteKind.tip),
          InfoRow(t('النوع', 'البروتوكول', 'Scheme'), r.scheme.isEmpty ? '—' : r.scheme, icon: r.scheme == 'https' ? Icons.lock_rounded : Icons.lock_open_rounded,
              valueColor: r.scheme == 'https' ? SD.green : (r.scheme.isEmpty ? null : SD.red)),
          if (r.host.isNotEmpty) InfoRow(t('المضيف كامل', 'المضيف كاملًا', 'Full host'), r.hostUnicode, icon: Icons.dns_rounded),
          if (r.hostUnicode != r.host) InfoRow(t('بالترميز (Punycode)', 'بالترميز (Punycode)', 'Encoded (Punycode)'), r.host, icon: Icons.code_rounded),
          if (r.tld.isNotEmpty) InfoRow(t('الامتداد', 'الامتداد', 'Ending (TLD)'), '.${r.tld}', icon: Icons.label_rounded),
          if (r.isIp) InfoRow(t('عنوان IP', 'عنوان IP', 'IP address'), tr('نعم', 'Yes'), icon: Icons.numbers_rounded, valueColor: SD.red),
        ]),
      ),
      SCard(
        title: t('الأسباب', 'الأسباب', 'Reasons'),
        icon: Icons.rule_rounded,
        color: rc,
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          if (sorted.isEmpty)
            Text(t('ما لقينا علامات خطر معروفة في الرابط ده.', 'لم نجد علامات خطر معروفة في هذا الرابط.', 'No known warning signs found in this link.'),
                style: const TextStyle(fontWeight: FontWeight.w600)),
          for (final f in [...sorted, ...info])
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Icon(f.weight >= 30 ? Icons.dangerous_rounded : (f.weight >= 10 ? Icons.warning_amber_rounded : Icons.info_outline_rounded),
                    color: readable(context, f.weight >= 30 ? SD.red : (f.weight >= 10 ? SD.orange : SD.nile)), size: 22),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(flagText(f).$1, style: const TextStyle(fontWeight: FontWeight.w800)),
                    Text(flagText(f).$2, style: TextStyle(height: 1.4, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: .8))),
                  ]),
                ),
                if (f.weight > 0) ...[
                  const SizedBox(width: 6),
                  Text('+${f.weight}', style: TextStyle(color: muted, fontSize: 12, fontWeight: FontWeight.w700)),
                ],
              ]),
            ),
        ]),
      ),
      Row(children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () => _openAnyway(r),
            icon: const Icon(Icons.open_in_browser_rounded),
            label: FittedBox(fit: BoxFit.scaleDown, child: Text(t('افتحه برضو', 'افتحه على أي حال', 'Open anyway'))),
          ),
        ),
      ]),
      const SizedBox(height: 10),
      ShareBar(() => [
            '🔗 ${t('فحص رابط', 'فحص رابط', 'Link check')}: ${riskLabel(r.risk)} (${r.score})',
            '${t('النطاق الحقيقي', 'النطاق الحقيقي', 'Real domain')}: ${r.domain}',
            for (final f in sorted) '• ${flagText(f).$1}',
            '',
            t('⚠️ فحص تقديري — ما تدخّل بياناتك في روابط ما متأكد منها.', '⚠️ فحص تقديري — لا تُدخل بياناتك في روابط غير موثوقة.', '⚠️ Heuristic check — never enter your details on links you are unsure of.'),
          ].join('\n')),
      const SizedBox(height: 12),
    ];
  }
}
