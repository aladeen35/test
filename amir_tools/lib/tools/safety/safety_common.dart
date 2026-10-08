import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/i18n.dart';
import '../../core/state.dart';
import '../../core/theme.dart';
import '../../screens/privacy_screen.dart' show supportEmail;

/// تاريخ آخر مراجعة لمحتوى أدوات الأمان
const safetyReviewed = '2026-10';

/// فتح رابط خارجي بأمان
Future<void> safetyOpen(String url) async {
  try {
    final ok = await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    if (!ok) toast(t('ما لقينا تطبيق يفتح الرابط ده', 'لم نجد تطبيقًا يفتح هذا الرابط', 'No app found to open this link'));
  } catch (_) {
    toast(t('الرابط ده ما بيتفتح', 'تعذّر فتح هذا الرابط', "This link can't be opened"));
  }
}

/// «بلّغ عن معلومة قديمة/غلط» ← بريد الدعم مع معرّف الأداة والعنصر
Future<void> reportOutdated(String toolId, [String item = '']) async {
  final subject = 'Ameer Tools — $toolId${item.isEmpty ? '' : ' — $item'} — outdated/wrong info';
  final uri = Uri(scheme: 'mailto', path: supportEmail, query: 'subject=${Uri.encodeComponent(subject)}');
  try {
    final ok = await launchUrl(uri);
    if (!ok) toast(t('ما لقينا تطبيق بريد — راسلنا على $supportEmail', 'لا يوجد تطبيق بريد — راسلنا على $supportEmail', 'No mail app — write to $supportEmail'));
  } catch (_) {
    toast(t('ما لقينا تطبيق بريد — راسلنا على $supportEmail', 'لا يوجد تطبيق بريد — راسلنا على $supportEmail', 'No mail app — write to $supportEmail'));
  }
}

/// سطر «آخر مراجعة» مع زر التبليغ
class ReviewedLine extends StatelessWidget {
  final String toolId;
  final String item;
  const ReviewedLine(this.toolId, {super.key, this.item = ''});
  @override
  Widget build(BuildContext context) {
    final muted = Theme.of(context).colorScheme.onSurface.withValues(alpha: .65);
    return Padding(
      padding: const EdgeInsets.only(top: 4, bottom: 8),
      child: Wrap(
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 8,
        runSpacing: 4,
        children: [
          Row(mainAxisSize: MainAxisSize.min, children: [
            Icon(Icons.event_available_rounded, size: 16, color: muted),
            const SizedBox(width: 6),
            Flexible(
              child: Text('${tr('آخر مراجعة', 'Last reviewed')}: $safetyReviewed',
                  maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 12.5, color: muted, fontWeight: FontWeight.w600)),
            ),
          ]),
          InkWell(
            borderRadius: BorderRadius.circular(10),
            onTap: () => reportOutdated(toolId, item),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(Icons.flag_rounded, size: 18, color: readable(context, SD.gold)),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(t('بلّغ عن معلومة قديمة أو غلط', 'أبلغ عن معلومة قديمة أو خاطئة', 'Report outdated / wrong info'),
                      maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(fontWeight: FontWeight.w700, color: readable(context, SD.gold))),
                ),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

/// عنصر قائمة تحقق: مربع + عنوان + خطوات قابلة للفتح
class CheckItemTile extends StatefulWidget {
  final String title;
  final List<String> steps;
  final bool done;
  final Color color;
  final ValueChanged<bool> onChanged;
  final Widget? extra;
  const CheckItemTile({super.key, required this.title, required this.steps, required this.done, required this.onChanged, this.color = SD.green, this.extra});
  @override
  State<CheckItemTile> createState() => _CheckItemTileState();
}

class _CheckItemTileState extends State<CheckItemTile> {
  bool open = false;
  @override
  Widget build(BuildContext context) {
    final c = readable(context, widget.color);
    final muted = Theme.of(context).colorScheme.onSurface.withValues(alpha: .75);
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: (widget.done ? widget.color : Colors.transparent).withValues(alpha: .08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: c.withValues(alpha: widget.done ? .55 : .25)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => setState(() => open = !open),
          child: Padding(
            padding: const EdgeInsetsDirectional.fromSTEB(4, 4, 8, 4),
            child: Row(children: [
              Checkbox(value: widget.done, activeColor: widget.color, onChanged: (v) => widget.onChanged(v == true)),
              Expanded(
                child: Text(widget.title,
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      decoration: widget.done ? TextDecoration.lineThrough : null,
                      decorationColor: c,
                    )),
              ),
              Icon(open ? Icons.expand_less_rounded : Icons.expand_more_rounded, color: c),
            ]),
          ),
        ),
        if (open)
          Padding(
            padding: const EdgeInsetsDirectional.fromSTEB(16, 0, 16, 12),
            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              for (var i = 0; i < widget.steps.length; i++)
                Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Container(
                      width: 22,
                      height: 22,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(color: widget.color.withValues(alpha: .2), shape: BoxShape.circle),
                      child: FittedBox(fit: BoxFit.scaleDown, child: Text('${i + 1}', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: c))),
                    ),
                    const SizedBox(width: 8),
                    Expanded(child: Text(widget.steps[i], style: TextStyle(height: 1.45, color: muted))),
                  ]),
                ),
              ?widget.extra,
            ]),
          ),
      ]),
    );
  }
}

/// شريط تقدّم بعنوان ونسبة
class SafetyProgress extends StatelessWidget {
  final String label;
  final int done, total;
  final Color color;
  const SafetyProgress(this.label, this.done, this.total, {super.key, this.color = SD.green});
  @override
  Widget build(BuildContext context) {
    final p = total == 0 ? 0.0 : done / total;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Row(children: [
          Expanded(child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w700))),
          const SizedBox(width: 8),
          Text('$done/$total', style: TextStyle(fontWeight: FontWeight.w800, color: readable(context, color))),
        ]),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(value: p, minHeight: 8, color: color, backgroundColor: color.withValues(alpha: .15)),
        ),
      ]),
    );
  }
}

/// زر رابط خارجي (يعرض النطاق تحت الاسم)
class LinkTile extends StatelessWidget {
  final String title, url;
  final String? sub;
  final IconData icon;
  final Color color;
  const LinkTile(this.title, this.url, {super.key, this.sub, this.icon = Icons.open_in_new_rounded, this.color = SD.nile});
  @override
  Widget build(BuildContext context) {
    final c = readable(context, color);
    final muted = Theme.of(context).colorScheme.onSurface.withValues(alpha: .6);
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: () => safetyOpen(url),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        child: Row(children: [
          Icon(icon, color: c, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
              if (sub != null) Text(sub!, style: TextStyle(fontSize: 12.5, color: muted)),
              Text(Uri.parse(url).host + Uri.parse(url).path,
                  maxLines: 1, overflow: TextOverflow.ellipsis, textDirection: TextDirection.ltr, style: TextStyle(fontSize: 12, color: c)),
            ]),
          ),
          Icon(Icons.open_in_new_rounded, size: 18, color: muted),
        ]),
      ),
    );
  }
}

/// قراءة قائمة نصوص من التخزين
List<String> strList(dynamic v) => v is List ? v.whereType<String>().toList() : <String>[];

/// قسم قابل للفتح يعرض خطوات مرقّمة (بدون مربع اختيار)
class StepsExpander extends StatelessWidget {
  final String title;
  final List<String> steps;
  final Color color;
  final Widget? extra;
  final IconData? icon;
  const StepsExpander({super.key, required this.title, required this.steps, this.color = SD.nile, this.extra, this.icon});
  @override
  Widget build(BuildContext context) {
    final c = readable(context, color);
    final muted = Theme.of(context).colorScheme.onSurface.withValues(alpha: .8);
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(16), border: Border.all(color: c.withValues(alpha: .3))),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          shape: const RoundedRectangleBorder(),
          collapsedShape: const RoundedRectangleBorder(),
          leading: icon == null ? null : Icon(icon, color: c),
          iconColor: c,
          collapsedIconColor: c,
          title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
          childrenPadding: const EdgeInsetsDirectional.fromSTEB(16, 0, 16, 12),
          expandedCrossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (var i = 0; i < steps.length; i++)
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('${i + 1}.', style: TextStyle(fontWeight: FontWeight.w800, color: c)),
                  const SizedBox(width: 8),
                  Expanded(child: Text(steps[i], style: TextStyle(height: 1.45, color: muted))),
                ]),
              ),
            ?extra,
          ],
        ),
      ),
    );
  }
}
