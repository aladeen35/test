import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'pattern.dart';
import 'state.dart';
import 'theme.dart';
import 'i18n.dart';

/// بطاقة قسم مزخرفة بعنوان وأيقونة
class SCard extends StatelessWidget {
  final String? title;
  final IconData? icon;
  final Color? color;
  final Widget child;
  final Widget? trailing;
  final EdgeInsets padding;
  const SCard({super.key, this.title, this.icon, this.color, required this.child, this.trailing, this.padding = const EdgeInsets.all(16)});

  @override
  Widget build(BuildContext context) {
    final c = color ?? SD.gold;
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: dark ? const [Color(0xFF6B4022), Color(0xFF55321A)] : const [Color(0xFFFFFAF0), Color(0xFFFBEBD0)],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: SD.gold.withValues(alpha: dark ? .55 : .7), width: 1.4),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: dark ? .3 : .08), blurRadius: 14, offset: const Offset(0, 6))],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Stack(children: [
          Positioned(top: 0, right: 0, child: CornerOrnament(color: dark ? SD.goldLight : SD.brown)),
          Padding(
            padding: padding,
            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              if (title != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(children: [
                    if (icon != null)
                      Container(
                        padding: const EdgeInsets.all(7),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(colors: [c, Color.lerp(c, Colors.black, .3)!]),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: SD.goldLight.withValues(alpha: .6)),
                        ),
                        child: Icon(icon, size: 19, color: Colors.white),
                      ),
                    if (icon != null) const SizedBox(width: 10),
                    Expanded(
                      child: Text(title!,
                          style: TextStyle(fontSize: 17.5, fontWeight: FontWeight.w800, color: dark ? SD.goldLight : SD.brown)),
                    ),
                    ?trailing,
                  ]),
                ),
              child,
            ]),
          ),
        ]),
      ),
    );
  }
}

/// صندوق النتيجة الكبيرة بتدرّج لوني
class ResultHero extends StatelessWidget {
  final String label, value;
  final String? sub;
  final List<Color>? colors;
  const ResultHero({super.key, required this.label, required this.value, this.sub, this.colors});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
            colors: colors ?? const [Color(0xFF8A5528), Color(0xFF5A3418), Color(0xFF3A1F0C)], begin: Alignment.topRight, end: Alignment.bottomLeft),
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: SD.gold, width: 2),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: .3), blurRadius: 18, offset: const Offset(0, 8))],
      ),
      child: Stack(children: [
        const Positioned(left: -10, bottom: -10, child: Opacity(opacity: .7, child: CornerOrnament(color: SD.goldLight))),
        Column(children: [
          Text(label, textAlign: TextAlign.center, style: const TextStyle(color: SD.cream, fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
          GestureDetector(
            onLongPress: () => copyText(value),
            child: ShaderMask(
              shaderCallback: (r) => const LinearGradient(colors: SD.goldText, begin: Alignment.topCenter, end: Alignment.bottomCenter).createShader(r),
              child: Text(value,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white, fontSize: 34, fontWeight: FontWeight.w800, height: 1.2)),
            ),
          ),
          if (sub != null) ...[
            const SizedBox(height: 6),
            Text(sub!, textAlign: TextAlign.center, style: TextStyle(color: SD.cream.withValues(alpha: .8), fontSize: 13)),
          ],
        ]),
      ]),
    );
  }
}

/// سطر «عنوان ← قيمة» (ضغطة طويلة للنسخ)
class InfoRow extends StatelessWidget {
  final String label, value;
  final IconData? icon;
  final String? hint;
  final Color? valueColor;
  const InfoRow(this.label, this.value, {super.key, this.icon, this.hint, this.valueColor});

  @override
  Widget build(BuildContext context) {
    final muted = Theme.of(context).colorScheme.onSurface.withValues(alpha: .6);
    return InkWell(
      onLongPress: () => copyText(value),
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 2),
        decoration: BoxDecoration(border: Border(bottom: BorderSide(color: muted.withValues(alpha: .15), style: BorderStyle.solid))),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          if (icon != null) ...[Icon(icon, size: 18, color: muted), const SizedBox(width: 8)],
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(label, style: TextStyle(color: muted, fontWeight: FontWeight.w600)),
              if (hint != null) Text(hint!, style: TextStyle(color: muted, fontSize: 11.5)),
            ]),
          ),
          const SizedBox(width: 10),
          Flexible(
            child: Text(value,
                textAlign: TextAlign.end,
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: valueColor == null ? null : readable(context, valueColor!))),
          ),
        ]),
      ),
    );
  }
}

/// حقل إدخال رقمي
class NumField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final ValueChanged<String>? onChanged;
  final String? suffix, hint;
  final bool decimal;
  const NumField(this.label, this.controller, {super.key, this.onChanged, this.suffix, this.hint, this.decimal = true});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: TextField(
          controller: controller,
          onChanged: onChanged,
          keyboardType: TextInputType.numberWithOptions(decimal: decimal),
          textDirection: TextDirection.ltr,
          textAlign: TextAlign.right,
          decoration: InputDecoration(labelText: label, suffixText: suffix, hintText: hint),
        ),
      );
}

/// تنبيه/ملاحظة ملوّنة (للتحذيرات الشرعية والطبية والتقديرية)
class NoteBox extends StatelessWidget {
  final String text;
  final NoteKind kind;
  const NoteBox(this.text, {super.key, this.kind = NoteKind.info});

  @override
  Widget build(BuildContext context) {
    final (c, ic) = switch (kind) {
      NoteKind.info => (SD.nile, Icons.info_outline),
      NoteKind.tip => (SD.green, Icons.lightbulb_outline),
      NoteKind.warn => (SD.gold, Icons.warning_amber_rounded),
      NoteKind.danger => (SD.red, Icons.block),
    };
    return Container(
      margin: const EdgeInsets.only(top: 6, bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: c.withValues(alpha: .10),
        borderRadius: BorderRadius.circular(16),
        border: Border(right: BorderSide(color: c, width: 4)),
      ),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(ic, color: c, size: 20),
        const SizedBox(width: 8),
        Expanded(child: Text(text, style: const TextStyle(fontSize: 13.5, height: 1.5))),
      ]),
    );
  }
}

enum NoteKind { info, tip, warn, danger }

/// عنوان قسم داخل الشاشة
class SectionTitle extends StatelessWidget {
  final String text;
  final IconData? icon;
  final Widget? trailing;
  const SectionTitle(this.text, {super.key, this.icon, this.trailing});
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(4, 18, 4, 10),
        child: Row(children: [
          if (icon != null) ...[Icon(icon, color: SD.gold), const SizedBox(width: 8)],
          Expanded(child: GoldText(text, size: 22, align: TextAlign.start)),
          ?trailing,
        ]),
      );
}

/// شريحة إحصائية صغيرة (رقم + وصف)
class StatChip extends StatelessWidget {
  final String value, label;
  final Color color;
  final IconData? icon;
  const StatChip(this.value, this.label, {super.key, this.color = SD.green, this.icon});
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: .14),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: readable(context, color).withValues(alpha: .35)),
        ),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          if (icon != null) Icon(icon, color: readable(context, color), size: 22),
          FittedBox(child: Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: readable(context, color)))),
          Text(label, textAlign: TextAlign.center, style: const TextStyle(fontSize: 12)),
        ]),
      );
}

/// شبكة شرائح إحصائية
class StatGrid extends StatelessWidget {
  final List<StatChip> items;
  final int columns;
  const StatGrid(this.items, {super.key, this.columns = 3});
  @override
  Widget build(BuildContext context) => GridView.count(
        crossAxisCount: columns,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
        childAspectRatio: 1.15,
        children: items,
      );
}

/// زر مشاركة/نسخ ملخص النتيجة
class ShareBar extends StatelessWidget {
  final String Function() text;
  const ShareBar(this.text, {super.key});
  @override
  Widget build(BuildContext context) => Row(children: [
        Expanded(
          child: OutlinedButton.icon(onPressed: () => copyText(text()), icon: const Icon(Icons.copy_rounded), label: Text(tr('انسخ النتيجة', 'Copy'))),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: FilledButton.icon(
            onPressed: () => SharePlus.instance.share(ShareParams(text: '${text()}\n\n— ${tr('من تطبيق أدوات أمير', 'via Amir Tools app')} 🇸🇩')),
            icon: const Icon(Icons.share_rounded),
            label: Text(t('شارك', 'مشاركة', 'Share')),
          ),
        ),
      ]);
}

Future<void> copyText(String s) async {
  if (s.isEmpty || s == '—') return;
  await Clipboard.setData(ClipboardData(text: s));
  toast(t('اتنسخ تمام ✓', 'تم النسخ ✓', 'Copied ✓'));
}

/// قائمة أدوات قياسية: ListView بحشوات مناسبة للشريط السفلي
class ToolList extends StatelessWidget {
  final List<Widget> children;
  const ToolList({super.key, required this.children});
  @override
  Widget build(BuildContext context) => ListView(padding: const EdgeInsets.fromLTRB(16, 8, 16, 40), children: children);
}
