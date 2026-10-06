import 'package:flutter/material.dart';
import '../../core/format.dart';
import '../../core/state.dart';
import '../../core/theme.dart';
import '../../core/widgets.dart';

/// أدوات مشتركة لقسم «البيت والزراعة»

/// زر مقطّع بعناوين قصيرة (≤3) لا تفيض
class HSeg<T> extends StatelessWidget {
  final T value;
  final List<(T, String)> items;
  final ValueChanged<T> onChanged;
  const HSeg(this.value, this.items, this.onChanged, {super.key});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: SizedBox(
          width: double.infinity,
          child: SegmentedButton<T>(
            showSelectedIcon: false,
            style: const ButtonStyle(visualDensity: VisualDensity.compact, padding: WidgetStatePropertyAll(EdgeInsets.symmetric(horizontal: 4))),
            segments: [
              for (final it in items)
                ButtonSegment<T>(
                  value: it.$1,
                  label: FittedBox(fit: BoxFit.scaleDown, child: Text(it.$2, maxLines: 1)),
                ),
            ],
            selected: {value},
            onSelectionChanged: (s) => onChanged(s.first),
          ),
        ),
      );
}

/// صف من حقلين متجاورين
class Pair extends StatelessWidget {
  final Widget a, b;
  const Pair(this.a, this.b, {super.key});
  @override
  Widget build(BuildContext context) => Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Expanded(child: a),
        const SizedBox(width: 10),
        Expanded(child: b),
      ]);
}

/// حقول رقمية محفوظة تلقائيًا تحت مفتاح واحد في التخزين
class FieldBag {
  final String key;
  final Map<String, String> defaults;
  final Map<String, TextEditingController> _c = {};
  FieldBag(this.key, this.defaults);

  void load(AppState s) {
    final saved = s.getData<Map>(key) ?? const {};
    for (final e in defaults.entries) {
      _c[e.key] = TextEditingController(text: (saved[e.key] as String?) ?? e.value);
    }
  }

  TextEditingController operator [](String k) => _c.putIfAbsent(k, () => TextEditingController(text: defaults[k] ?? ''));
  double n(String k, [double f = 0]) => parseNum(this[k].text, f);

  void save(AppState s, [Map<String, dynamic> extra = const {}]) {
    final prev = Map<String, dynamic>.from(s.getData<Map>(key) ?? const {});
    s.setData(key, {...prev, for (final e in _c.entries) e.key: e.value.text, ...extra});
  }

  void set(String k, String v) => this[k].text = v;
  void reset() {
    for (final e in defaults.entries) {
      this[e.key].text = e.value;
    }
  }

  void dispose() {
    for (final c in _c.values) {
      c.dispose();
    }
  }
}

/// سطر مادة في جدول الكميات (اسم، كمية، تكلفة اختيارية)
class QtyRow extends StatelessWidget {
  final String label, qty;
  final String? cost;
  final IconData icon;
  final Color color;
  const QtyRow(this.label, this.qty, {super.key, this.cost, this.icon = Icons.inventory_2_rounded, this.color = SD.gold});

  @override
  Widget build(BuildContext context) {
    final muted = Theme.of(context).colorScheme.onSurface.withValues(alpha: .6);
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 2),
      decoration: BoxDecoration(border: Border(bottom: BorderSide(color: muted.withValues(alpha: .15)))),
      child: Row(children: [
        Icon(icon, size: 18, color: readable(context, color)),
        const SizedBox(width: 8),
        Expanded(child: Text(label, maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(color: muted, fontWeight: FontWeight.w600))),
        const SizedBox(width: 8),
        Flexible(
          child: Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Text(qty, textAlign: TextAlign.end, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
            if (cost != null) Text(cost!, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 12, color: muted)),
          ]),
        ),
      ]),
    );
  }
}

/// شبكة شرائح إحصائية آمنة من الفيضان (الرقم والوصف يتصغّران عند الحاجة)
class HStats extends StatelessWidget {
  final List<(String value, String label, Color color)> items;
  final int columns;
  const HStats(this.items, {super.key, this.columns = 3});
  @override
  Widget build(BuildContext context) => GridView.count(
        crossAxisCount: columns,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
        childAspectRatio: columns == 2 ? 2.1 : 1.35,
        children: [
          for (final it in items)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              decoration: BoxDecoration(
                color: it.$3.withValues(alpha: .14),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: readable(context, it.$3).withValues(alpha: .35)),
              ),
              child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                Flexible(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(it.$1, maxLines: 1, style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800, color: readable(context, it.$3))),
                  ),
                ),
                const SizedBox(height: 2),
                Text(it.$2, textAlign: TextAlign.center, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 11.5, height: 1.2)),
              ]),
            ),
        ],
      );
}
