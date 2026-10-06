import 'package:flutter/material.dart';
import '../../core/i18n.dart';
import '../../core/theme.dart';
import '../../core/widgets.dart';

/// شريحة صغيرة ملوّنة (للحالة/الدور/الوسوم)
class WTag extends StatelessWidget {
  final String text;
  final Color color;
  final VoidCallback? onDelete;
  const WTag(this.text, {super.key, this.color = SD.purple, this.onDelete});
  @override
  Widget build(BuildContext context) {
    final rc = readable(context, color);
    return Container(
      padding: EdgeInsetsDirectional.fromSTEB(9, 3, onDelete == null ? 9 : 4, 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: rc.withValues(alpha: .4)),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Flexible(
          child: Text(text, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: rc)),
        ),
        if (onDelete != null)
          InkWell(onTap: onDelete, child: Padding(padding: const EdgeInsets.all(2), child: Icon(Icons.close_rounded, size: 14, color: rc))),
      ]),
    );
  }
}

/// حالة فارغة: لا يوجد مشروع بعد
class NeedProject extends StatelessWidget {
  final VoidCallback onCreate;
  const NeedProject(this.onCreate, {super.key});
  @override
  Widget build(BuildContext context) => ToolList(children: [
        const SizedBox(height: 30),
        const Center(child: Text('📖', style: TextStyle(fontSize: 56))),
        const SizedBox(height: 10),
        Text(
          t('أول حاجة أعمل مشروع (قصة) جديد', 'ابدأ أولًا بإنشاء مشروع (قصة) جديد', 'Create a story project first'),
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 16),
        Center(
          child: FilledButton.icon(
            onPressed: onCreate,
            icon: const Icon(Icons.add_rounded),
            label: Text(t('مشروع جديد', 'مشروع جديد', 'New project')),
          ),
        ),
      ]);
}

/// حقل نص قياسي
Widget wField(TextEditingController c, String label, {int lines = 1, String? hint, TextInputType? type, Widget? suffix}) => Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: TextField(
        controller: c,
        minLines: lines > 1 ? 2 : 1,
        maxLines: lines,
        keyboardType: type ?? (lines > 1 ? TextInputType.multiline : TextInputType.text),
        decoration: InputDecoration(labelText: label, hintText: hint, suffixIcon: suffix, alignLabelWithHint: lines > 1),
      ),
    );

/// عنوان صغير داخل الورقة
Widget wLabel(String s) => Padding(
      padding: const EdgeInsets.only(top: 6, bottom: 6),
      child: Text(s, style: const TextStyle(fontWeight: FontWeight.w800)),
    );

/// زرّا حفظ/حذف أسفل الورقة
Widget wSheetButtons(BuildContext ctx, {required VoidCallback onSave, VoidCallback? onDelete}) => Padding(
      padding: const EdgeInsets.only(top: 14),
      child: Row(children: [
        if (onDelete != null) ...[
          Expanded(
            child: OutlinedButton.icon(
              style: OutlinedButton.styleFrom(foregroundColor: SD.red),
              onPressed: onDelete,
              icon: const Icon(Icons.delete_outline_rounded),
              label: FittedBox(fit: BoxFit.scaleDown, child: Text(t('امسح', 'حذف', 'Delete'))),
            ),
          ),
          const SizedBox(width: 10),
        ],
        Expanded(
          flex: 2,
          child: FilledButton.icon(
            onPressed: onSave,
            icon: const Icon(Icons.check_rounded),
            label: FittedBox(fit: BoxFit.scaleDown, child: Text(t('احفظ', 'حفظ', 'Save'))),
          ),
        ),
      ]),
    );

/// شريط تقدّم بنسبة ونص
class WProgress extends StatelessWidget {
  final double value;
  final Color color;
  final String? label;
  const WProgress(this.value, {super.key, this.color = SD.purple, this.label});
  @override
  Widget build(BuildContext context) => Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
            value: value.clamp(0, 1).toDouble(),
            minHeight: 8,
            color: color,
            backgroundColor: color.withValues(alpha: .15),
          ),
        ),
        if (label != null) ...[
          const SizedBox(height: 4),
          Text(label!, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12)),
        ],
      ]);
}
