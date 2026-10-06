import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'format.dart';
import 'i18n.dart';
import 'theme.dart';

/// يكتب الفاصلة «/» تلقائيًا أثناء كتابة التاريخ: 06102026 ← 06/10/2026 (يوم/شهر/سنة)
/// ويقبل الأرقام العربية (٠١٢…) ويحوّلها، ويترك الحذف يعمل بشكل طبيعي
class DateSlashFormatter extends TextInputFormatter {
  const DateSlashFormatter();

  static String _digits(String s) {
    final b = StringBuffer();
    for (final r in s.runes) {
      if (r >= 0x30 && r <= 0x39) {
        b.writeCharCode(r);
      } else if (r >= 0x660 && r <= 0x669) {
        b.writeCharCode(r - 0x660 + 0x30); // ٠-٩
      } else if (r >= 0x6F0 && r <= 0x6F9) {
        b.writeCharCode(r - 0x6F0 + 0x30); // ۰-۹
      }
    }
    final d = b.toString();
    return d.length > 8 ? d.substring(0, 8) : d;
  }

  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    var d = _digits(newValue.text);
    final typing = newValue.text.length > oldValue.text.length;
    // حذف الفاصلة وحدها يحذف الرقم الذي قبلها، حتى لا تعود الفاصلة فورًا
    if (!typing && oldValue.text.endsWith('/') && d == _digits(oldValue.text) && d.isNotEmpty) {
      d = d.substring(0, d.length - 1);
    }
    final out = StringBuffer();
    for (var i = 0; i < d.length; i++) {
      if (i == 2 || i == 4) out.write('/');
      out.write(d[i]);
    }
    if (typing && (d.length == 2 || d.length == 4)) out.write('/');
    final s = out.toString();
    return TextEditingValue(text: s, selection: TextSelection.collapsed(offset: s.length));
  }

  /// يحلّل «يوم/شهر/سنة» ويعيد null إن لم يكن تاريخًا صحيحًا
  static DateTime? parse(String s) {
    final p = s.split('/');
    if (p.length != 3 || p[2].length != 4) return null;
    final d = int.tryParse(p[0]), m = int.tryParse(p[1]), y = int.tryParse(p[2]);
    if (d == null || m == null || y == null || m < 1 || m > 12 || d < 1) return null;
    final dt = DateTime(y, m, d);
    return dt.month == m && dt.day == d ? dt : null;
  }

  static String format(DateTime d) => '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
}

/// بديل showDatePicker: تقويم أو كتابة يدوية بفواصل تلقائية — يُستخدم في كل التطبيق
Future<DateTime?> pickDate({
  required BuildContext context,
  required DateTime initialDate,
  required DateTime firstDate,
  required DateTime lastDate,
  String? helpText,
  String? cancelText,
  String? confirmText,
  DatePickerEntryMode initialEntryMode = DatePickerEntryMode.calendar,
}) {
  DateTime clamp(DateTime d) => d.isBefore(firstDate) ? firstDate : (d.isAfter(lastDate) ? lastDate : d);
  return showDialog<DateTime>(
    context: context,
    builder: (_) => _DateDialog(
      initial: DateUtils.dateOnly(clamp(initialDate)),
      first: DateUtils.dateOnly(firstDate),
      last: DateUtils.dateOnly(lastDate),
      help: helpText ?? t('اختار التاريخ', 'اختر التاريخ', 'Select date'),
      cancel: cancelText ?? t('خلاص', 'إلغاء', 'Cancel'),
      ok: confirmText ?? t('تمام', 'موافق', 'OK'),
      typing: initialEntryMode == DatePickerEntryMode.input || initialEntryMode == DatePickerEntryMode.inputOnly,
    ),
  );
}

class _DateDialog extends StatefulWidget {
  final DateTime initial, first, last;
  final String help, cancel, ok;
  final bool typing;
  const _DateDialog({required this.initial, required this.first, required this.last, required this.help, required this.cancel, required this.ok, required this.typing});
  @override
  State<_DateDialog> createState() => _DateDialogState();
}

class _DateDialogState extends State<_DateDialog> {
  late DateTime _date = widget.initial;
  late bool _typing = widget.typing;
  late final _c = TextEditingController(text: DateSlashFormatter.format(widget.initial));
  String? _error;

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  /// يتحقق من النص المكتوب؛ يعيد التاريخ إن كان صحيحًا وضمن المدى
  DateTime? _check(String s, {bool show = false}) {
    final d = DateSlashFormatter.parse(s);
    String? err;
    if (d == null) {
      err = s.length < 10 ? null : t('التاريخ دا ما صاح', 'تاريخ غير صحيح', 'Invalid date');
      if (show && s.length < 10) err = t('أكتب التاريخ كامل: يوم/شهر/سنة', 'اكتب التاريخ كاملًا: يوم/شهر/سنة', 'Enter the full date: DD/MM/YYYY');
    } else if (d.isBefore(widget.first) || d.isAfter(widget.last)) {
      err = '${t('لازم يكون بين', 'يجب أن يكون بين', 'Must be between')} ${DateSlashFormatter.format(widget.first)} – ${DateSlashFormatter.format(widget.last)}';
    }
    setState(() => _error = err);
    if (err == null && d != null) _date = d;
    return err == null ? d : null;
  }

  void _submit() {
    if (_typing) {
      final d = _check(_c.text, show: true);
      if (d == null) return;
    }
    Navigator.pop(context, _date);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: SingleChildScrollView(
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Padding(
            padding: const EdgeInsetsDirectional.fromSTEB(22, 18, 10, 8),
            child: Row(children: [
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(widget.help, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 6),
                  FittedBox(fit: BoxFit.scaleDown, alignment: AlignmentDirectional.centerStart, child: Text(fmtDateAr(_date), style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800))),
                ]),
              ),
              IconButton(
                tooltip: _typing ? t('التقويم', 'التقويم', 'Calendar') : t('أكتب بإيدك', 'إدخال يدوي', 'Type the date'),
                icon: Icon(_typing ? Icons.calendar_month_rounded : Icons.edit_rounded),
                onPressed: () => setState(() {
                  _typing = !_typing;
                  _error = null;
                  _c.text = DateSlashFormatter.format(_date);
                }),
              ),
            ]),
          ),
          const Divider(height: 1),
          if (_typing)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 4),
              child: TextField(
                controller: _c,
                autofocus: true,
                keyboardType: TextInputType.number,
                textDirection: TextDirection.ltr,
                textAlign: TextAlign.center,
                inputFormatters: const [DateSlashFormatter()],
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, letterSpacing: 1.5),
                decoration: InputDecoration(
                  labelText: t('يوم / شهر / سنة', 'يوم / شهر / سنة', 'DD / MM / YYYY'),
                  hintText: '06/10/2026',
                  helperText: t('الفاصلة / بتتكتب براها', 'تُكتب الفاصلة / تلقائيًا', 'The / is added for you'),
                  errorText: _error,
                  errorMaxLines: 2,
                ),
                onChanged: (s) => _check(s),
                onSubmitted: (_) => _submit(),
              ),
            )
          else
            SizedBox(
              height: 330,
              child: CalendarDatePicker(
                initialDate: _date,
                firstDate: widget.first,
                lastDate: widget.last,
                onDateChanged: (d) => setState(() => _date = d),
              ),
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 4, 12, 10),
            child: Row(mainAxisAlignment: MainAxisAlignment.end, children: [
              TextButton(onPressed: () => Navigator.pop(context), child: Text(widget.cancel)),
              const SizedBox(width: 6),
              FilledButton(
                onPressed: _submit,
                style: FilledButton.styleFrom(backgroundColor: SD.gold, foregroundColor: cs.brightness == Brightness.dark ? SD.brownDeep : Colors.white),
                child: Text(widget.ok),
              ),
            ]),
          ),
        ]),
      ),
    );
  }
}
