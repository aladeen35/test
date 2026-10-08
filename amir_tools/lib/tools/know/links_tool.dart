import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/data.dart' show flagOf;
import '../../core/i18n.dart';
import '../../core/state.dart';
import '../../core/theme.dart';
import '../../core/widgets.dart';
import '../life/life_common.dart' show EmptyHint, PickChip;
import 'know_common.dart';

/// رابط رسمي موثوق
class OLink {
  final String group, name, nameEn, url, descAr, descEn;

  /// حسابات التواصل الرسمية (اختيارية)
  final String? x, fb;
  const OLink(this.group, this.name, this.nameEn, this.url, this.descAr, this.descEn, {this.x, this.fb});
  String get title => isEn ? nameEn : name;
  String get desc => isEn ? descEn : descAr;
  String get host => Uri.parse(url).host;
}

/// المجموعات: intl = منظمات دولية، والبقية رموز الدول
const linkGroups = ['SD', 'intl', 'SA', 'AE', 'EG', 'QA', 'GB', 'US', 'CA'];

String linkGroupName(String g) => switch (g) {
      'SD' => t('السودان', 'السودان', 'Sudan'),
      'intl' => t('منظمات دولية وإنسانية', 'منظمات دولية وإنسانية', 'International & humanitarian'),
      'SA' => t('السعودية', 'السعودية', 'Saudi Arabia'),
      'AE' => t('الإمارات', 'الإمارات', 'UAE'),
      'EG' => t('مصر', 'مصر', 'Egypt'),
      'QA' => t('قطر', 'قطر', 'Qatar'),
      'GB' => t('بريطانيا', 'المملكة المتحدة', 'United Kingdom'),
      'US' => t('أمريكا', 'الولايات المتحدة', 'United States'),
      'CA' => t('كندا', 'كندا', 'Canada'),
      _ => g,
    };

String linkGroupFlag(String g) => g == 'intl' ? '🌐' : flagOf(g);

/// روابط مختارة — فقط النطاقات الرسمية المعروفة بدقة
const officialLinks = <OLink>[
  // ── السودان (مراجعة 2026-10) ──
  OLink('SD', 'جمعية الهلال الأحمر السوداني', 'Sudanese Red Crescent Society', 'https://srcs.sd',
      'الإغاثة والإسعاف والدعم الإنساني داخل السودان.', 'Relief, first aid and humanitarian support inside Sudan.', x: 'https://x.com/SRCS_SD', fb: 'https://facebook.com/SRCS.SD'),
  OLink('SD', 'الأمانة العامة لمجلس الوزراء', 'General Secretariat of the Council of Ministers', 'https://sudan.gov.sd',
      'البوابة الحكومية وأخبار وقرارات مجلس الوزراء.', 'Government portal and Cabinet news and decisions.', x: 'https://x.com/SudanCabinet', fb: 'https://facebook.com/SudanCabinet'),
  OLink('SD', 'وزارة الداخلية', 'Ministry of Interior', 'https://moi.gov.sd',
      'الشرطة والجوازات والسجل المدني والمرور.', 'Police, passports, civil registry and traffic.', x: 'https://x.com/SudanPoliceHQ', fb: 'https://facebook.com/sudanesepolice'),
  OLink('SD', 'وزارة الصحة الاتحادية', 'Federal Ministry of Health', 'https://fmoh.gov.sd',
      'الخدمات الصحية والتوعية والأوبئة.', 'Health services, awareness and epidemics.', x: 'https://x.com/FMOH_SUDAN', fb: 'https://facebook.com/fmohsudan'),
  OLink('SD', 'وزارة الخارجية', 'Ministry of Foreign Affairs', 'https://mofasudan.website',
      'السفارات والقنصليات وخدمات السودانيين في الخارج.', 'Embassies, consulates and services for Sudanese abroad.', x: 'https://x.com/MofaSudan', fb: 'https://facebook.com/MofaSudan1'),
  OLink('SD', 'وزارة التعليم العالي والبحث العلمي', 'Ministry of Higher Education & Scientific Research', 'https://mohe.gov.sd',
      'القبول للجامعات وتوثيق الشهادات الجامعية.', 'University admission and certificate attestation.', x: 'https://x.com/mohesudan', fb: 'https://facebook.com/mohe.gov.sd'),
  OLink('SD', 'وزارة المالية والتخطيط الاقتصادي', 'Ministry of Finance & Economic Planning', 'https://mof.gov.sd',
      'الموازنة والسياسات المالية والاقتصادية.', 'Budget and fiscal and economic policy.', x: 'https://x.com/MoF_Sudan', fb: 'https://facebook.com/MoFSudan'),
  OLink('SD', 'وزارة التربية والتعليم', 'Ministry of Education', 'https://moe.gov.sd',
      'المدارس والامتحانات ونتائج الشهادة السودانية.', 'Schools, exams and Sudan School Certificate results.', x: 'https://x.com/MOEGOVSD', fb: 'https://facebook.com/moe.gov.sd'),
  OLink('SD', 'وزارة العدل', 'Ministry of Justice', 'https://moj.gov.sd',
      'التشريعات والتوثيق والشؤون القانونية.', 'Legislation, notarisation and legal affairs.', x: 'https://x.com/moj_sd', fb: 'https://facebook.com/moj.sd'),
  OLink('SD', 'وزارة الثقافة والإعلام', 'Ministry of Culture & Information', 'https://moci.gov.sd',
      'الإعلام الرسمي والثقافة.', 'Official media and culture.', x: 'https://x.com/MoCI_Sudan', fb: 'https://facebook.com/MoCI.Sudan'),
  OLink('SD', 'وزارة الزراعة والغابات', 'Ministry of Agriculture & Forests', 'https://moaf.gov.sd',
      'الزراعة والمواسم والغابات.', 'Agriculture, seasons and forests.', fb: 'https://facebook.com/moaf.sudan'),
  OLink('SD', 'وزارة الطاقة والنفط', 'Ministry of Energy & Oil', 'https://mop.gov.sd',
      'الكهرباء والنفط والوقود.', 'Electricity, oil and fuel.', x: 'https://x.com/mopsudan', fb: 'https://facebook.com/MoP.Sudan'),
  OLink('SD', 'وزارة الري والموارد المائية', 'Ministry of Irrigation & Water Resources', 'https://mwri.gov.sd',
      'الري ومياه النيل والفيضانات.', 'Irrigation, Nile waters and floods.', fb: 'https://facebook.com/mwri.gov.sd'),
  OLink('SD', 'وزارة المعادن', 'Ministry of Minerals', 'https://minerals.gov.sd',
      'التعدين والذهب والمعادن.', 'Mining, gold and minerals.', x: 'https://x.com/minerals_sd', fb: 'https://facebook.com/minerals.sudan'),
  OLink('SD', 'وزارة التنمية الاجتماعية', 'Ministry of Social Development', 'https://mosd.gov.sd',
      'الرعاية والدعم الاجتماعي.', 'Social welfare and support.', fb: 'https://facebook.com/mosdsudan'),
  OLink('SD', 'وزارة الشؤون الدينية والأوقاف', 'Ministry of Religious Affairs & Endowments', 'https://mara.gov.sd',
      'الحج والعمرة والأوقاف والشؤون الدينية.', 'Hajj, Umrah, endowments and religious affairs.', fb: 'https://facebook.com/mara.sudan'),
  OLink('SD', 'وزارة الثروة الحيوانية', 'Ministry of Animal Resources', 'https://moar.gov.sd',
      'الثروة الحيوانية والبيطرة والصادر.', 'Livestock, veterinary services and exports.', fb: 'https://facebook.com/moar.sudan'),
  OLink('SD', 'وزارة الاستثمار والتعاون الدولي', 'Ministry of Investment & International Cooperation', 'https://moinv.gov.sd',
      'فرص وإجراءات الاستثمار.', 'Investment opportunities and procedures.', fb: 'https://facebook.com/moinv.gov.sd'),
  OLink('SD', 'المركز القومي للمعلومات', 'National Information Center', 'https://nic.gov.sd',
      'الحكومة الإلكترونية والخدمات الرقمية.', 'E-government and digital services.', x: 'https://x.com/nicsudan', fb: 'https://facebook.com/nic.gov.sd'),

  // ── دولية وإنسانية ──
  OLink('intl', 'ريليف ويب — السودان', 'ReliefWeb — Sudan', 'https://reliefweb.int/country/sdn',
      'تقارير وأخبار إنسانية محدّثة عن السودان من الأمم المتحدة والمنظمات.', 'Up-to-date humanitarian reports and news on Sudan from the UN and NGOs.'),
  OLink('intl', 'المفوضية السامية للأمم المتحدة لشؤون اللاجئين', 'UNHCR — UN Refugee Agency', 'https://www.unhcr.org',
      'حماية اللاجئين وطالبي اللجوء ومعلومات عن خدماتها في الدول.', 'Protection for refugees and asylum seekers and info on services by country.'),
  OLink('intl', 'مساعدة المفوضية (معلومات للاجئين)', 'UNHCR Help (info for refugees)', 'https://help.unhcr.org',
      'معلومات عملية للاجئين وطالبي اللجوء حسب البلد.', 'Practical information for refugees and asylum seekers by country.'),
  OLink('intl', 'اللجنة الدولية للصليب الأحمر', 'ICRC — International Committee of the Red Cross', 'https://www.icrc.org',
      'العمل الإنساني في مناطق النزاع.', 'Humanitarian work in conflict areas.'),
  OLink('intl', 'إعادة الروابط العائلية (الصليب الأحمر)', 'Restoring Family Links (ICRC)', 'https://familylinks.icrc.org',
      'خدمة للبحث عن الأقارب المفقودين بسبب النزاع أو الكوارث أو الهجرة.', 'Help finding relatives separated by conflict, disaster or migration.'),
  OLink('intl', 'الاتحاد الدولي لجمعيات الصليب الأحمر والهلال الأحمر', 'IFRC — Red Cross & Red Crescent Societies', 'https://www.ifrc.org',
      'شبكة الجمعيات الوطنية للهلال والصليب الأحمر.', 'The network of national Red Cross and Red Crescent societies.'),
  OLink('intl', 'منظمة الصحة العالمية', 'WHO — World Health Organization', 'https://www.who.int',
      'معلومات صحية موثوقة عن الأمراض والتطعيمات.', 'Reliable health information on diseases and vaccines.'),
  OLink('intl', 'منظمة الصحة العالمية — شرق المتوسط', 'WHO Eastern Mediterranean (EMRO)', 'https://www.emro.who.int',
      'المكتب الإقليمي الذي يشمل السودان ودول المنطقة.', 'Regional office covering Sudan and the region.'),
  OLink('intl', 'اليونيسف', 'UNICEF', 'https://www.unicef.org',
      'حقوق الأطفال وصحتهم وتعليمهم.', 'Children\'s rights, health and education.'),
  OLink('intl', 'برنامج الأغذية العالمي', 'WFP — World Food Programme', 'https://www.wfp.org',
      'المساعدات الغذائية الطارئة.', 'Emergency food assistance.'),
  OLink('intl', 'المنظمة الدولية للهجرة', 'IOM — International Organization for Migration', 'https://www.iom.int',
      'خدمات ومعلومات للمهاجرين والنازحين.', 'Services and information for migrants and displaced people.'),
  OLink('intl', 'مكتب الأمم المتحدة لتنسيق الشؤون الإنسانية', 'OCHA — UN Humanitarian Affairs', 'https://www.unocha.org',
      'تنسيق الاستجابة الإنسانية وتقارير الأوضاع.', 'Coordinates humanitarian response; situation reports.'),
  OLink('intl', 'أطباء بلا حدود', 'MSF — Doctors Without Borders', 'https://www.msf.org',
      'رعاية طبية طارئة في مناطق الأزمات.', 'Emergency medical care in crisis areas.'),

  // ── السعودية ──
  OLink('SA', 'أبشر', 'Absher', 'https://www.absher.sa', 'خدمات الجوازات والأحوال والمرور والإقامة إلكترونيًا.', 'Online passports, civil affairs, traffic and residency services.'),
  OLink('SA', 'المنصة الوطنية الموحدة', 'Unified National Platform (my.gov.sa)', 'https://my.gov.sa', 'البوابة الموحدة للخدمات الحكومية السعودية.', 'Saudi Arabia\'s unified government services portal.'),
  OLink('SA', 'قوى', 'Qiwa', 'https://www.qiwa.sa', 'خدمات العمل: العقود ونقل الخدمات.', 'Labour services: contracts and employment transfers.'),
  OLink('SA', 'مساند', 'Musaned', 'https://musaned.com.sa', 'منصة العمالة المنزلية.', 'Domestic labour platform.'),
  OLink('SA', 'المؤسسة العامة للتأمينات الاجتماعية', 'GOSI', 'https://www.gosi.gov.sa', 'التأمينات الاجتماعية والاشتراكات.', 'Social insurance and contributions.'),
  OLink('SA', 'وزارة الموارد البشرية', 'Ministry of Human Resources (HRSD)', 'https://www.hrsd.gov.sa', 'أنظمة العمل والحقوق العمالية.', 'Labour law and worker rights.'),
  OLink('SA', 'منصة التأشيرات — الخارجية', 'Visa platform — MOFA', 'https://visa.mofa.gov.sa', 'طلبات التأشيرات ومتابعتها.', 'Visa applications and tracking.'),
  OLink('SA', 'وزارة الصحة', 'Ministry of Health', 'https://www.moh.gov.sa', 'الخدمات والتوعية الصحية.', 'Health services and awareness.'),
  OLink('SA', 'البنك المركزي السعودي', 'Saudi Central Bank (SAMA)', 'https://www.sama.gov.sa', 'الجهة المنظمة للبنوك والتحويلات.', 'Regulator of banks and transfers.'),
  OLink('SA', 'نُسُك', 'Nusuk', 'https://www.nusuk.sa', 'المنصة الرسمية للعمرة والحج والزيارة.', 'Official platform for Umrah, Hajj and visits.'),

  // ── الإمارات ──
  OLink('AE', 'البوابة الرسمية لحكومة الإمارات', 'UAE Government portal', 'https://u.ae', 'معلومات وخدمات حكومة الإمارات.', 'UAE government information and services.'),
  OLink('AE', 'الهيئة الاتحادية للهوية والجنسية والجمارك وأمن المنافذ', 'ICP — Identity, Citizenship, Customs & Port Security', 'https://icp.gov.ae', 'الهوية والإقامة والتأشيرات.', 'Emirates ID, residency and visas.'),
  OLink('AE', 'وزارة الموارد البشرية والتوطين', 'MOHRE', 'https://www.mohre.gov.ae', 'تصاريح وعقود العمل.', 'Work permits and contracts.'),
  OLink('AE', 'الإدارة العامة للإقامة وشؤون الأجانب — دبي', 'GDRFA Dubai', 'https://gdrfad.gov.ae', 'إقامات وتأشيرات دبي.', 'Dubai residency and visas.'),
  OLink('AE', 'مصرف الإمارات المركزي', 'Central Bank of the UAE', 'https://www.centralbank.ae', 'الجهة المنظمة للبنوك.', 'Banking regulator.'),

  // ── مصر ──
  OLink('EG', 'بوابة الحكومة المصرية', 'Egyptian Government portal', 'https://www.egypt.gov.eg', 'دليل الخدمات الحكومية المصرية.', 'Directory of Egyptian government services.'),
  OLink('EG', 'مصر الرقمية', 'Digital Egypt', 'https://digital.gov.eg', 'الخدمات الحكومية الإلكترونية.', 'Online government services.'),
  OLink('EG', 'وزارة الخارجية المصرية', 'Egypt Ministry of Foreign Affairs', 'https://www.mfa.gov.eg', 'الخدمات القنصلية والتصديقات.', 'Consular services and attestations.'),
  OLink('EG', 'البنك المركزي المصري', 'Central Bank of Egypt', 'https://www.cbe.org.eg', 'أسعار الصرف الرسمية وتنظيم البنوك.', 'Official exchange rates and banking regulation.'),

  // ── قطر ──
  OLink('QA', 'حكومي — البوابة الحكومية', 'Hukoomi — Qatar e-Government', 'https://hukoomi.gov.qa', 'البوابة الرسمية لخدمات حكومة قطر.', 'Official portal for Qatar government services.'),

  // ── بريطانيا ──
  OLink('GB', 'الموقع الحكومي البريطاني', 'GOV.UK', 'https://www.gov.uk', 'التأشيرات واللجوء والخدمات الحكومية.', 'Visas, asylum and government services.'),

  // ── أمريكا ──
  OLink('US', 'دائرة الهجرة الأمريكية', 'USCIS', 'https://www.uscis.gov', 'الهجرة والإقامة والجنسية.', 'Immigration, residency and citizenship.'),
  OLink('US', 'السفر — الخارجية الأمريكية', 'travel.state.gov', 'https://travel.state.gov', 'التأشيرات ومعلومات السفر.', 'Visas and travel information.'),

  // ── كندا ──
  OLink('CA', 'الحكومة الكندية', 'Government of Canada', 'https://www.canada.ca', 'الهجرة واللجوء والخدمات.', 'Immigration, refugees and services.'),
];

class LinksTool extends StatefulWidget {
  const LinksTool({super.key});
  @override
  State<LinksTool> createState() => _LinksToolState();
}

class _LinksToolState extends State<LinksTool> {
  final _search = TextEditingController();
  String _q = '';
  String _group = 'all';

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _open(AppState s, OLink l, [String? url]) async {
    try {
      final ok = await launchUrl(Uri.parse(url ?? l.url), mode: LaunchMode.externalApplication);
      if (!ok) throw Exception();
      s.awardDaily('official_links_open', 2, tr('فتح رابط رسمي', 'Opened an official link'));
    } catch (_) {
      toast(t('ما قدرنا نفتح الرابط', 'تعذّر فتح الرابط', "Couldn't open the link"));
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final q = normAr(_q);
    var list = officialLinks.where((l) => _group == 'all' || l.group == _group);
    if (q.isNotEmpty) {
      list = list.where((l) => normAr('${l.name} ${l.nameEn} ${l.url} ${l.descAr} ${l.descEn} ${linkGroupName(l.group)}').contains(q));
    }
    final items = list.toList();
    final groups = [for (final g in linkGroups) if (items.any((l) => l.group == g)) g];

    return ToolList(children: [
      NoteBox(
          t('احذر المواقع المزيفة! قبل ما تدخل بياناتك أو تدفع، اتأكد من اسم النطاق (الدومين) حرف حرف، وما تفتح روابط جاتك في واتساب أو رسائل مجهولة.',
              'احذر المواقع المزيّفة! قبل إدخال بياناتك أو الدفع تحقّق من اسم النطاق حرفًا حرفًا، ولا تفتح روابط وصلتك عبر واتساب أو رسائل مجهولة.',
              'Beware of fake sites! Before entering data or paying, check the domain name letter by letter, and don\'t open links sent via WhatsApp or unknown messages.'),
          kind: NoteKind.danger),
      KnowSearch(_search, t('فتّش: إقامة، لاجئين، تأشيرة…', 'ابحث: إقامة، لاجئين، تأشيرة…', 'Search: residency, refugees, visa…'), (v) => setState(() => _q = v)),
      const SizedBox(height: 10),
      Wrap(spacing: 6, runSpacing: 6, children: [
        PickChip('📚 ${t('الكل', 'الكل', 'All')}', _group == 'all', () => setState(() => _group = 'all'), color: SD.gold),
        for (final g in linkGroups) PickChip('${linkGroupFlag(g)} ${linkGroupName(g)}', _group == g, () => setState(() => _group = g), color: SD.nile),
      ]),
      const SizedBox(height: 12),
      if (items.isEmpty) EmptyHint(Icons.link_off_rounded, t('ما لقينا رابط', 'لا توجد روابط مطابقة', 'No matching links')),
      for (final g in groups)
        SCard(
          title: '${linkGroupFlag(g)} ${linkGroupName(g)}',
          child: Column(children: [for (final l in items.where((l) => l.group == g)) _tile(context, s, l)]),
        ),
      NoteBox(
          t('الروابط دي للمواقع الرسمية المعروفة بس، وما بنضيف رابط ما متأكدين منو. لو لقيت رابط بايظ أو اتغير، بلّغنا.',
              'هذه روابط لمواقع رسمية معروفة فقط، ولا نضيف رابطًا غير مؤكد. إن وجدت رابطًا معطّلًا أو متغيّرًا فأبلغنا.',
              'These are well-known official sites only; we don\'t add links we aren\'t sure of. If a link is broken or changed, let us know.'),
          kind: NoteKind.info),
      const ReviewedLine('official_links'),
    ]);
  }

  Widget _tile(BuildContext context, AppState s, OLink l) {
    final muted = Theme.of(context).colorScheme.onSurface.withValues(alpha: .65);
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(border: Border(bottom: BorderSide(color: muted.withValues(alpha: .15)))),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => _open(s, l),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Icon(Icons.public_rounded, color: readable(context, SD.nile), size: 22),
            const SizedBox(width: 10),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(l.title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
                Text(l.desc, style: TextStyle(color: muted, fontSize: 13, height: 1.4)),
                const SizedBox(height: 2),
                Text(l.host,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textDirection: TextDirection.ltr,
                    style: TextStyle(color: readable(context, SD.green), fontWeight: FontWeight.w700, fontSize: 13)),
              ]),
            ),
            Icon(Icons.open_in_new_rounded, size: 18, color: muted),
          ]),
        ),
        Row(mainAxisAlignment: MainAxisAlignment.end, children: [
          if (l.x != null)
            TextButton(
              style: TextButton.styleFrom(visualDensity: VisualDensity.compact, padding: const EdgeInsets.symmetric(horizontal: 8)),
              onPressed: () => _open(s, l, l.x),
              child: const Text('𝕏', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
            ),
          if (l.fb != null)
            TextButton(
              style: TextButton.styleFrom(visualDensity: VisualDensity.compact, padding: const EdgeInsets.symmetric(horizontal: 8)),
              onPressed: () => _open(s, l, l.fb),
              child: const Text('Facebook', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12.5)),
            ),
          const Spacer(),
          IconButton(
            visualDensity: VisualDensity.compact,
            tooltip: t('انسخ الرابط', 'نسخ الرابط', 'Copy link'),
            onPressed: () => copyText(l.url),
            icon: const Icon(Icons.copy_rounded, size: 19),
          ),
          IconButton(
            visualDensity: VisualDensity.compact,
            tooltip: t('بلّغ عن رابط بايظ', 'إبلاغ عن رابط معطّل', 'Report broken link'),
            onPressed: () => reportOutdated('official_links', '${l.nameEn} — ${l.url}'),
            icon: const Icon(Icons.flag_outlined, size: 19),
          ),
        ]),
      ]),
    );
  }
}
