import 'package:flutter/material.dart';
import '../../core/data.dart';
import '../../core/theme.dart';

/// قائمة منسدلة لاختيار عملة (علم + اسم)
class CurrencyPicker extends StatelessWidget {
  final String label;
  final String value;
  final ValueChanged<String> onChanged;
  final List<String>? codes;
  const CurrencyPicker(this.label, this.value, this.onChanged, {super.key, this.codes});

  @override
  Widget build(BuildContext context) {
    final list = codes == null ? currencies : currencies.where((c) => codes!.contains(c.code)).toList();
    return DropdownButtonFormField<String>(
      initialValue: value,
      isExpanded: true,
      decoration: InputDecoration(labelText: label, contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10)),
      items: [
        for (final c in list)
          DropdownMenuItem(
            value: c.code,
            child: Text('${c.flag} ${c.name} (${c.code})', overflow: TextOverflow.ellipsis),
          ),
      ],
      onChanged: (v) {
        if (v != null) onChanged(v);
      },
    );
  }
}

/// مجموعة اختيارات أفقية (شرائح) — بديل بسيط لأزرار الراديو
class ChoiceRow<T> extends StatelessWidget {
  final List<(T, String)> options;
  final T value;
  final ValueChanged<T> onChanged;
  final Color color;
  const ChoiceRow(this.options, this.value, this.onChanged, {super.key, this.color = SD.green});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Wrap(spacing: 8, runSpacing: 8, children: [
          for (final o in options)
            ChoiceChip(
              label: Text(o.$2),
              selected: o.$1 == value,
              selectedColor: color.withValues(alpha: .22),
              side: BorderSide(color: color.withValues(alpha: .35)),
              labelStyle: TextStyle(fontWeight: o.$1 == value ? FontWeight.w800 : FontWeight.w500),
              onSelected: (_) => onChanged(o.$1),
            ),
        ]),
      );
}

/// جدول بسيط مزخرف قابل للتمرير أفقيًا
class MiniTable extends StatelessWidget {
  final List<String> headers;
  final List<List<String>> rows;
  final Color color;
  final int? highlight;
  const MiniTable(this.headers, this.rows, {super.key, this.color = SD.nile, this.highlight});

  @override
  Widget build(BuildContext context) {
    final muted = Theme.of(context).colorScheme.onSurface.withValues(alpha: .12);
    Widget cell(String t, {bool head = false}) => Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          child: Text(t,
              textAlign: TextAlign.center,
              style: TextStyle(fontWeight: head ? FontWeight.w800 : FontWeight.w600, fontSize: 13)),
        );
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: ConstrainedBox(
        constraints: BoxConstraints(minWidth: MediaQuery.sizeOf(context).width - 64),
        child: Table(
          defaultColumnWidth: const IntrinsicColumnWidth(),
          defaultVerticalAlignment: TableCellVerticalAlignment.middle,
          border: TableBorder(horizontalInside: BorderSide(color: muted)),
          children: [
            TableRow(
              decoration: BoxDecoration(color: color.withValues(alpha: .28), borderRadius: BorderRadius.circular(10)),
              children: [for (final h in headers) cell(h, head: true)],
            ),
            for (var i = 0; i < rows.length; i++)
              TableRow(
                decoration: BoxDecoration(
                  color: i == highlight
                      ? SD.gold.withValues(alpha: .22)
                      : i.isOdd
                          ? color.withValues(alpha: .06)
                          : null,
                ),
                children: [for (final c in rows[i]) cell(c)],
              ),
          ],
        ),
      ),
    );
  }
}

/// شريط نسبة ملوّن (للمقارنة)
class PercentBar extends StatelessWidget {
  final String label;
  final double fraction;
  final String trailing;
  final Color color;
  const PercentBar(this.label, this.fraction, this.trailing, {super.key, this.color = SD.green});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 5),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Row(children: [
            Expanded(child: Text(label, style: const TextStyle(fontWeight: FontWeight.w700))),
            Text(trailing, style: TextStyle(fontWeight: FontWeight.w800, color: color)),
          ]),
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: fraction.isNaN ? 0 : fraction.clamp(0, 1).toDouble(),
              minHeight: 9,
              color: color,
              backgroundColor: color.withValues(alpha: .14),
            ),
          ),
        ]),
      );
}

String curName(String code) => currencyByCode(code).name;
String curSym(String code) => currencyByCode(code).sym;
