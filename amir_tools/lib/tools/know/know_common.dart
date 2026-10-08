import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/i18n.dart';
import '../../core/state.dart';
import '../../core/theme.dart';
import '../../core/widgets.dart' show copyText;
import '../../screens/privacy_screen.dart' show supportEmail;

/// تاريخ آخر مراجعة لمحتوى أدوات «المعرفة»
const knowReviewed = '2026-10';

/// توحيد النص العربي للبحث: حذف التشكيل والتطويل، توحيد الألف والتاء المربوطة والياء
String normAr(String s) => s
    .toLowerCase()
    .replaceAll(RegExp('[ً-ْٰـ]'), '')
    .replaceAll(RegExp('[أإآٱ]'), 'ا')
    .replaceAll('ة', 'ه')
    .replaceAll('ى', 'ي')
    .replaceAll('ؤ', 'و')
    .replaceAll('ئ', 'ي')
    .trim();

/// مشاركة نص مع توقيع التطبيق
Future<void> shareKnowText(String text) async {
  try {
    await SharePlus.instance.share(ShareParams(text: '$text\n\n— ${tr('من تطبيق أدوات أمير', 'via Ameer Tools app')} 🇸🇩'));
  } catch (_) {
    await copyText(text);
  }
}

/// هل النص يحوي حروفًا عربية؟
bool hasArabic(String s) => RegExp('[؀-ۿ]').hasMatch(s);

/// يفتح بريد الإبلاغ عن معلومة قديمة/خاطئة
Future<void> reportOutdated(String toolId, String item) async {
  final subject = Uri.encodeComponent('[$toolId] ${tr('تبليغ', 'Report')}: $item');
  final body = Uri.encodeComponent(tr('المعلومة التي تحتاج تصحيح:\n$item\n\nالتصحيح المقترح:\n', 'Item that needs fixing:\n$item\n\nSuggested correction:\n'));
  final uri = Uri.parse('mailto:$supportEmail?subject=$subject&body=$body');
  try {
    if (!await launchUrl(uri)) throw Exception();
  } catch (_) {
    toast(t('ما لقينا تطبيق بريد — راسلنا على $supportEmail', 'لا يوجد تطبيق بريد — راسلنا على $supportEmail', 'No mail app found — email us at $supportEmail'));
  }
}

/// سطر «آخر مراجعة» مع زر إبلاغ
class ReviewedLine extends StatelessWidget {
  final String toolId;
  final String item;
  const ReviewedLine(this.toolId, {super.key, this.item = ''});

  @override
  Widget build(BuildContext context) {
    final muted = Theme.of(context).colorScheme.onSurface.withValues(alpha: .65);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(children: [
        Icon(Icons.verified_rounded, size: 18, color: readable(context, SD.green)),
        const SizedBox(width: 6),
        Expanded(
          child: Text('${t('آخر مراجعة', 'آخر مراجعة', 'Last reviewed')}: $knowReviewed',
              maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 12.5, color: muted, fontWeight: FontWeight.w600)),
        ),
        TextButton.icon(
          onPressed: () => reportOutdated(toolId, item.isEmpty ? toolId : item),
          icon: const Icon(Icons.flag_rounded, size: 18),
          label: Text(t('بلّغ عن خطأ', 'إبلاغ عن خطأ', 'Report error'), maxLines: 1, overflow: TextOverflow.ellipsis),
        ),
      ]),
    );
  }
}

/// حقل بحث قياسي مع زر مسح
class KnowSearch extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final ValueChanged<String> onChanged;
  const KnowSearch(this.controller, this.hint, this.onChanged, {super.key});

  @override
  Widget build(BuildContext context) => TextField(
        controller: controller,
        onChanged: onChanged,
        decoration: InputDecoration(
          prefixIcon: const Icon(Icons.search_rounded),
          hintText: hint,
          suffixIcon: controller.text.isEmpty
              ? null
              : IconButton(
                  tooltip: t('امسح', 'مسح', 'Clear'),
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () {
                    controller.clear();
                    onChanged('');
                  }),
        ),
      );
}

/// شارة صغيرة ملوّنة (تصنيف)
class TagPill extends StatelessWidget {
  final String text;
  final Color color;
  const TagPill(this.text, this.color, {super.key});
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(color: color.withValues(alpha: .15), borderRadius: BorderRadius.circular(10), border: Border.all(color: color.withValues(alpha: .4))),
        child: Text(text, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800, color: readable(context, color))),
      );
}
