import 'dart:io' show File;
import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../core/format.dart';
import '../../core/i18n.dart';
import '../../core/state.dart';
import '../../core/theme.dart';
import '../../core/widgets.dart';
import '../life/life_common.dart';
import '../money/money_common.dart' show ChoiceRow, CurrencyPicker, curSym;

/// فاتورة سريعة: ملف المحل، البنود، الخصم، الضريبة، معاينة إيصال، مشاركة نص/صورة، وسجل
class InvoiceTool extends StatefulWidget {
  const InvoiceTool({super.key});
  @override
  State<InvoiceTool> createState() => _InvoiceToolState();
}

/// حساب مجاميع الفاتورة
({double sub, double disc, double vat, double total}) invoiceTotals(Map inv) {
  final items = mapList(inv['items']);
  final sub = items.fold<double>(0, (a, e) => a + numOf(e['q']) * numOf(e['p']));
  final d = numOf(inv['disc']);
  final disc = (inv['discPct'] == true ? sub * d / 100 : d).clamp(0, sub).toDouble();
  final vat = (sub - disc) * numOf(inv['vat']) / 100;
  return (sub: sub, disc: disc, vat: vat, total: sub - disc + vat);
}

String invNo(int n) => 'INV-${n.toString().padLeft(4, '0')}';

class _InvoiceToolState extends State<InvoiceTool> {
  final _receiptKey = GlobalKey();
  final _disc = TextEditingController();
  final _vat = TextEditingController();
  final _customer = TextEditingController();
  final _notes = TextEditingController();
  late Map<String, dynamic> _draft;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    final s = context.read<AppState>();
    _draft = Map<String, dynamic>.from(s.getData<Map>('invoice_draft') ?? _blank());
    _fillControllers();
  }

  Map<String, dynamic> _blank() => {'items': <Map>[], 'disc': 0, 'discPct': false, 'vat': 0, 'notes': '', 'customer': '', 'no': null, 'date': dk(todayPlace())};

  void _fillControllers() {
    _disc.text = numOf(_draft['disc']) == 0 ? '' : fmt(numOf(_draft['disc']), 2).replaceAll(',', '');
    _vat.text = numOf(_draft['vat']) == 0 ? '' : fmt(numOf(_draft['vat']), 2).replaceAll(',', '');
    _customer.text = _draft['customer'] as String? ?? '';
    _notes.text = _draft['notes'] as String? ?? '';
  }

  @override
  void dispose() {
    for (final c in [_disc, _vat, _customer, _notes]) {
      c.dispose();
    }
    super.dispose();
  }

  Map<String, dynamic> _profile(AppState s) => Map<String, dynamic>.from(s.getData<Map>('invoice_profile') ?? const {});
  String _cur(AppState s) => _profile(s)['cur'] as String? ?? 'SAR';
  List<Map<String, dynamic>> _history(AppState s) => mapList(s.getData<List>('invoice_history'));
  int _next(AppState s) => (s.getData<num>('invoice_next') ?? 1).toInt();

  void _persist() {
    _draft['disc'] = parseNum(_disc.text);
    _draft['vat'] = parseNum(_vat.text);
    _draft['customer'] = _customer.text.trim();
    _draft['notes'] = _notes.text.trim();
    context.read<AppState>().setData('invoice_draft', _draft);
  }

  void _changed([String? _]) {
    setState(_persist);
  }

  String _money(AppState s, double v) => '${fmt(v, 2)} ${curSym(_cur(s))}';

  /* ── ملف المحل ── */
  Future<void> _editProfile() async {
    final s = context.read<AppState>();
    final p = _profile(s);
    final nameC = TextEditingController(text: p['name'] ?? '');
    final phoneC = TextEditingController(text: p['phone'] ?? '');
    final addrC = TextEditingController(text: p['addr'] ?? '');
    var cur = p['cur'] as String? ?? 'SAR';
    final ok = await lifeSheet<bool>(
      context,
      t('بيانات المحل', 'بيانات المتجر', 'Shop profile'),
      (ctx, set) => Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        TextField(controller: nameC, decoration: InputDecoration(labelText: t('اسم المحل', 'اسم المتجر', 'Shop name'))),
        const SizedBox(height: 10),
        TextField(controller: phoneC, keyboardType: TextInputType.phone, decoration: InputDecoration(labelText: t('التلفون', 'الهاتف', 'Phone'))),
        const SizedBox(height: 10),
        TextField(controller: addrC, decoration: InputDecoration(labelText: t('العنوان', 'العنوان', 'Address'))),
        const SizedBox(height: 12),
        CurrencyPicker(t('العملة', 'العملة', 'Currency'), cur, (v) => set(() => cur = v)),
        const SizedBox(height: 18),
        FilledButton.icon(
          onPressed: () => Navigator.pop(ctx, true),
          icon: const Icon(Icons.check_rounded),
          label: Text(t('احفظ', 'حفظ', 'Save')),
        ),
      ]),
    );
    if (ok == true) {
      s.setData('invoice_profile', {'name': nameC.text.trim(), 'phone': phoneC.text.trim(), 'addr': addrC.text.trim(), 'cur': cur});
    }
    nameC.dispose();
    phoneC.dispose();
    addrC.dispose();
    if (mounted) setState(() {});
  }

  /* ── البنود ── */
  Future<void> _editItem([int? index]) async {
    final items = mapList(_draft['items']);
    final e = index == null ? null : items[index];
    final nameC = TextEditingController(text: e?['n'] ?? '');
    final qC = TextEditingController(text: e == null ? '1' : fmt(numOf(e['q']), 3).replaceAll(',', ''));
    final pC = TextEditingController(text: e == null ? '' : fmt(numOf(e['p']), 2).replaceAll(',', ''));
    final ok = await lifeSheet<bool>(
      context,
      e == null ? t('بند جديد', 'بند جديد', 'New item') : t('عدّل البند', 'تعديل البند', 'Edit item'),
      (ctx, set) => Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        TextField(controller: nameC, autofocus: e == null, decoration: InputDecoration(labelText: t('اسم الصنف', 'اسم الصنف', 'Item name'))),
        const SizedBox(height: 10),
        Row(children: [
          Expanded(child: NumField(t('الكمية', 'الكمية', 'Qty'), qC)),
          const SizedBox(width: 10),
          Expanded(child: NumField(t('سعر الوحدة', 'سعر الوحدة', 'Unit price'), pC)),
        ]),
        const SizedBox(height: 8),
        Row(children: [
          if (e != null)
            Expanded(
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(foregroundColor: SD.red),
                onPressed: () => Navigator.pop(ctx, false),
                icon: const Icon(Icons.delete_outline_rounded),
                label: Text(t('امسح', 'حذف', 'Delete'), maxLines: 1, overflow: TextOverflow.ellipsis),
              ),
            ),
          if (e != null) const SizedBox(width: 10),
          Expanded(
            flex: 2,
            child: FilledButton.icon(
              onPressed: () {
                if (nameC.text.trim().isEmpty) return toast(t('أكتب اسم الصنف', 'اكتب اسم الصنف', 'Enter the item name'));
                Navigator.pop(ctx, true);
              },
              icon: const Icon(Icons.check_rounded),
              label: Text(t('تمام', 'حفظ', 'Save'), maxLines: 1, overflow: TextOverflow.ellipsis),
            ),
          ),
        ]),
      ]),
    );
    final data = {'n': nameC.text.trim(), 'q': parseNum(qC.text, 1), 'p': parseNum(pC.text)};
    nameC.dispose();
    qC.dispose();
    pC.dispose();
    if (!mounted || ok == null) return;
    if (ok == false && index != null) {
      items.removeAt(index);
    } else if (index == null) {
      items.add(data);
    } else {
      items[index] = data;
    }
    _draft['items'] = items;
    _changed();
  }

  /* ── حفظ / جديد / فتح ── */
  void _saveInvoice() {
    final s = context.read<AppState>();
    _persist();
    if (mapList(_draft['items']).isEmpty) return toast(t('ضيف بند واحد على الأقل', 'أضف بندًا واحدًا على الأقل', 'Add at least one item'));
    final h = _history(s);
    final isNew = _draft['no'] == null;
    if (isNew) {
      final n = _next(s);
      _draft['no'] = n;
      s.setData('invoice_next', n + 1);
    }
    final rec = {..._draft, 'cur': _cur(s), 'shop': _profile(s), 'saved': DateTime.now().millisecondsSinceEpoch};
    final i = h.indexWhere((x) => x['no'] == _draft['no']);
    if (i >= 0) {
      h[i] = rec;
    } else {
      h.insert(0, rec);
    }
    s.setData('invoice_history', h.take(200).toList());
    s.setData('invoice_draft', _draft);
    if (isNew) {
      s.award(5, tr('إصدار فاتورة', 'Issued an invoice'));
      s.bump('invoices');
    }
    toast('${t('اتحفظت', 'حُفظت', 'Saved')} ${invNo(_draft['no'] as int)} ✓');
    setState(() {});
  }

  Future<void> _newInvoice() async {
    if (mapList(_draft['items']).isNotEmpty && _draft['no'] == null) {
      final ok = await confirmAsk(context, t('فاتورة جديدة؟', 'فاتورة جديدة؟', 'New invoice?'),
          t('الفاتورة الحالية ما اتحفظت، حتتمسح.', 'الفاتورة الحالية غير محفوظة وستُمسح.', 'The current invoice is not saved and will be cleared.'));
      if (!ok) return;
    }
    setState(() {
      _draft = _blank();
      _fillControllers();
      _persist();
    });
  }

  void _open(Map<String, dynamic> rec) {
    setState(() {
      _draft = {
        for (final k in ['items', 'disc', 'discPct', 'vat', 'notes', 'customer', 'no', 'date']) k: rec[k],
      };
      _fillControllers();
      _persist();
    });
    toast('${t('اتفتحت', 'فُتحت', 'Opened')} ${invNo(intOf(rec['no']))}');
  }

  void _deleteRec(AppState s, Map<String, dynamic> rec) {
    final h = _history(s)..removeWhere((x) => x['no'] == rec['no']);
    s.setData('invoice_history', h);
    undoSnack(t('اتمسحت الفاتورة', 'حُذفت الفاتورة', 'Invoice deleted'), () {
      final l = _history(s)..add(rec);
      l.sort((a, b) => intOf(b['no']).compareTo(intOf(a['no'])));
      s.setData('invoice_history', l);
    });
  }

  /* ── المشاركة ── */
  String _asText(AppState s) {
    final p = _profile(s);
    final tot = invoiceTotals(_draft);
    final items = mapList(_draft['items']);
    final no = _draft['no'] == null ? invNo(_next(s)) : invNo(_draft['no'] as int);
    final date = parseDk(_draft['date'] as String?) ?? todayPlace();
    return [
      if ((p['name'] ?? '').toString().isNotEmpty) '🏪 ${p['name']}',
      if ((p['addr'] ?? '').toString().isNotEmpty) '📍 ${p['addr']}',
      if ((p['phone'] ?? '').toString().isNotEmpty) '📞 ${p['phone']}',
      '🧾 ${tr('فاتورة', 'Invoice')} $no — ${fmtDateAr(date, weekday: false)}',
      if ((_draft['customer'] ?? '').toString().isNotEmpty) '👤 ${tr('العميل', 'Customer')}: ${_draft['customer']}',
      '────────',
      for (final e in items) '• ${e['n']}: ${fmt(numOf(e['q']), 3)} × ${fmt(numOf(e['p']))} = ${_money(s, numOf(e['q']) * numOf(e['p']))}',
      '────────',
      '${tr('المجموع', 'Subtotal')}: ${_money(s, tot.sub)}',
      if (tot.disc > 0) '${tr('الخصم', 'Discount')}: -${_money(s, tot.disc)}',
      if (numOf(_draft['vat']) > 0) '${tr('الضريبة', 'VAT')} (${fmt(numOf(_draft['vat']))}%): ${_money(s, tot.vat)}',
      '${tr('الإجمالي', 'TOTAL')}: ${_money(s, tot.total)}',
      if ((_draft['notes'] ?? '').toString().isNotEmpty) '📝 ${_draft['notes']}',
    ].join('\n');
  }

  Future<void> _shareImage() async {
    if (_busy) return;
    final s = context.read<AppState>();
    if (mapList(_draft['items']).isEmpty) return toast(t('ضيف بند واحد على الأقل', 'أضف بندًا واحدًا على الأقل', 'Add at least one item'));
    setState(() => _busy = true);
    try {
      final boundary = _receiptKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) throw StateError('no boundary');
      final img = await boundary.toImage(pixelRatio: 3);
      final bd = await img.toByteData(format: ui.ImageByteFormat.png);
      img.dispose();
      if (bd == null) throw StateError('no bytes');
      final bytes = bd.buffer.asUint8List();
      final no = _draft['no'] == null ? invNo(_next(s)) : invNo(_draft['no'] as int);
      final name = 'invoice_$no.png';
      XFile f;
      if (kIsWeb) {
        f = XFile.fromData(bytes, name: name, mimeType: 'image/png');
      } else {
        final dir = await getTemporaryDirectory();
        final file = File('${dir.path}/$name');
        await file.writeAsBytes(bytes, flush: true);
        f = XFile(file.path, mimeType: 'image/png', name: name);
      }
      await SharePlus.instance.share(ShareParams(files: [f], text: '${tr('فاتورة', 'Invoice')} $no'));
    } catch (_) {
      toast(t('ما قدرنا نشارك الصورة، جرّب تاني', 'تعذّرت مشاركة الصورة، حاول مرة أخرى', "Couldn't share the image, try again"));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final p = _profile(s);
    final items = mapList(_draft['items']);
    final tot = invoiceTotals(_draft);
    final hist = _history(s);
    final muted = Theme.of(context).colorScheme.onSurface.withValues(alpha: .6);
    final shopName = (p['name'] ?? '').toString();

    return ToolList(children: [
      SCard(
        title: t('المحل', 'المتجر', 'Shop'),
        icon: Icons.storefront_rounded,
        trailing: IconButton(tooltip: t('عدّل', 'تعديل', 'Edit'), onPressed: _editProfile, icon: const Icon(Icons.edit_rounded)),
        child: shopName.isEmpty
            ? OutlinedButton.icon(
                onPressed: _editProfile,
                icon: const Icon(Icons.add_business_rounded),
                label: Text(t('أكتب بيانات محلك', 'أدخل بيانات متجرك', 'Set up your shop details'), maxLines: 1, overflow: TextOverflow.ellipsis),
              )
            : Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(shopName, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                Text([p['phone'], p['addr'], curSym(_cur(s))].where((x) => (x ?? '').toString().isNotEmpty).join(' · '),
                    maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(color: muted)),
              ]),
      ),
      SCard(
        title: '${t('البنود', 'البنود', 'Items')} — ${_draft['no'] == null ? invNo(_next(s)) : invNo(_draft['no'] as int)}',
        icon: Icons.list_alt_rounded,
        color: SD.nile,
        trailing: IconButton(tooltip: t('فاتورة جديدة', 'فاتورة جديدة', 'New invoice'), onPressed: _newInvoice, icon: const Icon(Icons.note_add_rounded)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          if (items.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(t('لسه ما في بنود', 'لا توجد بنود بعد', 'No items yet'), textAlign: TextAlign.center, style: TextStyle(color: muted)),
            ),
          for (var i = 0; i < items.length; i++)
            InkWell(
              borderRadius: BorderRadius.circular(10),
              onTap: () => _editItem(i),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(children: [
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('${items[i]['n']}', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w700)),
                      Text('${fmt(numOf(items[i]['q']), 3)} × ${fmt(numOf(items[i]['p']))}',
                          maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: muted, fontSize: 12.5)),
                    ]),
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(_money(s, numOf(items[i]['q']) * numOf(items[i]['p'])),
                        maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w800)),
                  ),
                ]),
              ),
            ),
          const SizedBox(height: 6),
          FilledButton.tonalIcon(
            onPressed: () => _editItem(),
            icon: const Icon(Icons.add_rounded),
            label: Text(t('ضيف بند', 'إضافة بند', 'Add item'), maxLines: 1, overflow: TextOverflow.ellipsis),
          ),
        ]),
      ),
      SCard(
        title: t('الخصم والضريبة', 'الخصم والضريبة', 'Discount & tax'),
        icon: Icons.percent_rounded,
        color: SD.orange,
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          ChoiceRow<bool>([
            (false, t('خصم بمبلغ', 'خصم بمبلغ', 'Amount off')),
            (true, t('خصم بنسبة %', 'خصم بنسبة %', 'Percent off')),
          ], _draft['discPct'] == true, (v) {
            _draft['discPct'] = v;
            _changed();
          }, color: SD.orange),
          NumField(t('الخصم', 'الخصم', 'Discount'), _disc, onChanged: _changed, suffix: _draft['discPct'] == true ? '%' : curSym(_cur(s))),
          NumField(t('ضريبة القيمة المضافة', 'ضريبة القيمة المضافة', 'VAT'), _vat, onChanged: _changed, suffix: '%'),
          Wrap(spacing: 6, runSpacing: 6, children: [
            for (final v in const [0, 5, 15])
              ActionChip(
                label: Text('$v%'),
                onPressed: () {
                  _vat.text = v == 0 ? '' : '$v';
                  _changed();
                },
              ),
          ]),
          const SizedBox(height: 10),
          TextField(controller: _customer, onChanged: _changed, decoration: InputDecoration(labelText: t('اسم الزبون (اختياري)', 'اسم العميل (اختياري)', 'Customer (optional)'))),
          const SizedBox(height: 10),
          TextField(controller: _notes, onChanged: _changed, maxLines: 2, decoration: InputDecoration(labelText: t('ملاحظات', 'ملاحظات', 'Notes'))),
        ]),
      ),
      SectionTitle(t('المعاينة', 'المعاينة', 'Preview'), icon: Icons.receipt_long_rounded),
      RepaintBoundary(key: _receiptKey, child: _receipt(s, p, items, tot)),
      const SizedBox(height: 14),
      Row(children: [
        Expanded(
          child: FilledButton.icon(
            onPressed: _saveInvoice,
            icon: const Icon(Icons.save_rounded),
            label: Text(t('احفظ الفاتورة', 'حفظ الفاتورة', 'Save invoice'), maxLines: 1, overflow: TextOverflow.ellipsis),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: _busy ? null : _shareImage,
            icon: _busy ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.image_rounded),
            label: Text(t('شارك صورة', 'مشاركة كصورة', 'Share image'), maxLines: 1, overflow: TextOverflow.ellipsis),
          ),
        ),
      ]),
      const SizedBox(height: 10),
      ShareBar(() => _asText(s)),
      if (hist.isNotEmpty) ...[
        SectionTitle(t('الفواتير السابقة', 'الفواتير السابقة', 'Past invoices'), icon: Icons.history_rounded),
        for (final r in hist.take(50)) _histTile(context, s, r, muted),
      ],
      NoteBox(
          t('دي فاتورة مبسطة للاستخدام اليومي، وما بتغني عن الفاتورة الضريبية الإلكترونية لو بلدك بتطلبها.',
              'هذه فاتورة مبسّطة للاستخدام اليومي ولا تُغني عن الفاتورة الضريبية الإلكترونية إن كان بلدك يشترطها.',
              'This is a simple everyday invoice and does not replace an official e-invoice where your country requires one.'),
          kind: NoteKind.info),
    ]);
  }

  Widget _histTile(BuildContext context, AppState s, Map<String, dynamic> r, Color muted) {
    final tot = invoiceTotals(r);
    final date = parseDk(r['date'] as String?);
    final cust = (r['customer'] ?? '').toString();
    final cur = r['cur'] as String? ?? _cur(s);
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        onTap: () => _open(r),
        leading: const Icon(Icons.receipt_rounded, color: SD.gold),
        title: Text(invNo(intOf(r['no'])), maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w800)),
        subtitle: Text([if (date != null) fmtDateAr(date, weekday: false), if (cust.isNotEmpty) cust, '${fmt(tot.total)} ${curSym(cur)}'].join(' · '),
            maxLines: 2, overflow: TextOverflow.ellipsis),
        trailing: IconButton(
          tooltip: t('امسح', 'حذف', 'Delete'),
          icon: Icon(Icons.delete_outline_rounded, color: muted),
          onPressed: () => _deleteRec(s, r),
        ),
      ),
    );
  }

  /// معاينة الإيصال (خلفية ورقية بيضاء حتى تظهر الصورة واضحة)
  Widget _receipt(AppState s, Map p, List<Map<String, dynamic>> items, ({double sub, double disc, double vat, double total}) tot) {
    const ink = Color(0xFF222222);
    const faint = Color(0xFF6B6B6B);
    final no = _draft['no'] == null ? invNo(_next(s)) : invNo(_draft['no'] as int);
    final date = parseDk(_draft['date'] as String?) ?? todayPlace();
    final name = (p['name'] ?? '').toString();
    Widget kv(String k, String v, {bool bold = false, double size = 13.5}) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: Row(children: [
            Expanded(child: Text(k, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: size, fontWeight: bold ? FontWeight.w800 : FontWeight.w500))),
            const SizedBox(width: 8),
            Flexible(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: AlignmentDirectional.centerEnd,
                child: Text(v, style: TextStyle(fontSize: size, fontWeight: bold ? FontWeight.w900 : FontWeight.w700)),
              ),
            ),
          ]),
        );
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFDF7),
        borderRadius: BorderRadius.circular(6),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: .25), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: DefaultTextStyle.merge(
        style: const TextStyle(color: ink, height: 1.35),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Text(name.isEmpty ? t('اسم المحل', 'اسم المتجر', 'Shop name') : name,
              textAlign: TextAlign.center, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w900)),
          if ((p['addr'] ?? '').toString().isNotEmpty)
            Text('${p['addr']}', textAlign: TextAlign.center, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12.5, color: faint)),
          if ((p['phone'] ?? '').toString().isNotEmpty)
            Text('${p['phone']}', textAlign: TextAlign.center, textDirection: TextDirection.ltr, style: const TextStyle(fontSize: 12.5, color: faint)),
          const _Dashes(),
          kv(tr('رقم الفاتورة', 'Invoice no.'), no, bold: true),
          kv(tr('التاريخ', 'Date'), fmtDateAr(date, weekday: false)),
          if ((_draft['customer'] ?? '').toString().isNotEmpty) kv(tr('العميل', 'Customer'), '${_draft['customer']}'),
          const _Dashes(),
          if (items.isEmpty)
            Text('—', textAlign: TextAlign.center, style: const TextStyle(color: faint)),
          for (final e in items)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 3),
              child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('${e['n']}', maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5)),
                    Text('${fmt(numOf(e['q']), 3)} × ${fmt(numOf(e['p']))}', style: const TextStyle(fontSize: 12, color: faint)),
                  ]),
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(fmt(numOf(e['q']) * numOf(e['p'])), style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13.5)),
                  ),
                ),
              ]),
            ),
          const _Dashes(),
          kv(tr('المجموع', 'Subtotal'), _money(s, tot.sub)),
          if (tot.disc > 0) kv('${tr('الخصم', 'Discount')}${_draft['discPct'] == true ? ' (${fmt(numOf(_draft['disc']))}%)' : ''}', '-${_money(s, tot.disc)}'),
          if (numOf(_draft['vat']) > 0) kv('${tr('الضريبة', 'VAT')} (${fmt(numOf(_draft['vat']))}%)', _money(s, tot.vat)),
          const SizedBox(height: 4),
          kv(tr('الإجمالي', 'TOTAL'), _money(s, tot.total), bold: true, size: 17),
          if ((_draft['notes'] ?? '').toString().isNotEmpty) ...[
            const _Dashes(),
            Text('${_draft['notes']}', textAlign: TextAlign.center, style: const TextStyle(fontSize: 12.5, color: faint)),
          ],
          const _Dashes(),
          Text(t('شكراً لتعاملكم معانا 🌹', 'شكرًا لتعاملكم معنا 🌹', 'Thank you for your business 🌹'),
              textAlign: TextAlign.center, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
        ]),
      ),
    );
  }
}

/// خط متقطع كخطوط الإيصال
class _Dashes extends StatelessWidget {
  const _Dashes();
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: SizedBox(height: 1, width: double.infinity, child: CustomPaint(painter: _DashPainter())),
      );
}

class _DashPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF9A9A9A)
      ..strokeWidth = 1;
    for (double x = 0; x < size.width; x += 7) {
      canvas.drawLine(Offset(x, 0), Offset(x + 4, 0), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
