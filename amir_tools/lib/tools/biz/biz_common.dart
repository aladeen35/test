import 'package:flutter/material.dart';
import '../../core/format.dart';
import '../../core/i18n.dart';
import '../../core/theme.dart';

/// أدوات مشتركة لقسم «البيزنس والمناسبات»

/// مبلغ مع رمز العملة الذي يكتبه المستخدم
String money(num v, String cur, [int digits = 0]) => '${fmt(v, digits)} $cur'.trim();

/// رقم مختصر للعرض في المساحات الضيقة: 1.2K / 3.4M
String compact(num v) {
  final a = v.abs();
  if (a >= 1e9) return '${fmt(v / 1e9, 1)}B';
  if (a >= 1e6) return '${fmt(v / 1e6, 1)}M';
  if (a >= 1e4) return '${fmt(v / 1e3, 1)}K';
  return fmt(v, 0);
}

/// نص النسبة المئوية «42%»
String pct(num v, [int digits = 0]) => '${fmt(v, digits)}%';

/// شريط تقدّم مع عنوان وقيمة — القيمة تتصغّر بدل ما تطلع برّا الإطار
class BizBar extends StatelessWidget {
  final String label, trailing;
  final double fraction;
  final Color color;
  final String? hint;
  const BizBar(this.label, this.fraction, this.trailing, {super.key, this.color = SD.green, this.hint});

  @override
  Widget build(BuildContext context) {
    final f = fraction.isNaN || fraction.isInfinite ? 0.0 : fraction.clamp(0.0, 1.0);
    final muted = Theme.of(context).colorScheme.onSurface.withValues(alpha: .6);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Expanded(
            flex: 3,
            child: Text(label, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w700)),
          ),
          const SizedBox(width: 8),
          Flexible(
            flex: 2,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: AlignmentDirectional.centerEnd,
              child: Text(trailing, maxLines: 1, style: TextStyle(fontWeight: FontWeight.w800, color: readable(context, color))),
            ),
          ),
        ]),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(value: f, minHeight: 9, color: color, backgroundColor: color.withValues(alpha: .14)),
        ),
        if (hint != null) ...[
          const SizedBox(height: 3),
          Text(hint!, maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 11.5, color: muted)),
        ],
      ]),
    );
  }
}

/// حقل نصي لرمز/اسم العملة (يحفظ مع كل تعديل)
class CurField extends StatefulWidget {
  final String value;
  final ValueChanged<String> onChanged;
  const CurField(this.value, this.onChanged, {super.key});
  @override
  State<CurField> createState() => _CurFieldState();
}

class _CurFieldState extends State<CurField> {
  late final _c = TextEditingController(text: widget.value);
  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => TextField(
        controller: _c,
        maxLength: 8,
        decoration: InputDecoration(
          labelText: t('العملة (الرمز)', 'رمز العملة', 'Currency label'),
          hintText: t('ج.س أو \$ أو ر.س', 'ج.س أو \$ أو ر.س', 'SDG, \$, SAR…'),
          counterText: '',
          prefixIcon: const Icon(Icons.payments_rounded),
        ),
        onChanged: (v) => widget.onChanged(v.trim()),
      );
}

/// صف صغير: أيقونة + نص يتمدد + قيمة تتصغّر
class MiniRow extends StatelessWidget {
  final String title;
  final String? sub;
  final String value;
  final Color? color;
  final Widget? leading, trailing;
  final VoidCallback? onTap;
  const MiniRow(this.title, this.value, {super.key, this.sub, this.color, this.leading, this.trailing, this.onTap});

  @override
  Widget build(BuildContext context) {
    final muted = Theme.of(context).colorScheme.onSurface.withValues(alpha: .6);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 7, horizontal: 2),
        child: Row(children: [
          if (leading != null) ...[leading!, const SizedBox(width: 10)],
          Expanded(
            flex: 3,
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w700)),
              if (sub != null && sub!.isNotEmpty) Text(sub!, maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 12, color: muted)),
            ]),
          ),
          const SizedBox(width: 8),
          Flexible(
            flex: 2,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: AlignmentDirectional.centerEnd,
              child: Text(value, maxLines: 1, style: TextStyle(fontWeight: FontWeight.w800, color: color == null ? null : readable(context, color!))),
            ),
          ),
          ?trailing,
        ]),
      ),
    );
  }
}

/// زر صغير بأيقونة فقط
Widget iconBtn(IconData icon, String tip, VoidCallback onTap, {Color? color}) => IconButton(
      visualDensity: VisualDensity.compact,
      tooltip: tip,
      onPressed: onTap,
      icon: Icon(icon, color: color, size: 21),
    );
