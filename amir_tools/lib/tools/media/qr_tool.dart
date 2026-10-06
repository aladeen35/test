import 'dart:convert';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/state.dart';
import '../../core/theme.dart';
import '../../core/widgets.dart';
import 'media_common.dart';

enum _QrType {
  text('نص', Icons.notes_rounded),
  link('رابط', Icons.link_rounded),
  wifi('واي فاي', Icons.wifi_rounded),
  phone('رقم تلفون', Icons.call_rounded),
  whatsapp('واتساب', Icons.chat_rounded),
  contact('كرت اتصال', Icons.contact_page_rounded);

  final String label;
  final IconData icon;
  const _QrType(this.label, this.icon);
}

class QrTool extends StatefulWidget {
  const QrTool({super.key});
  @override
  State<QrTool> createState() => _QrToolState();
}

class _QrToolState extends State<QrTool> {
  int _tab = 0; // 0 = إنشاء، 1 = قراءة
  _QrType _type = _QrType.text;
  final _text = TextEditingController();
  final _url = TextEditingController();
  final _ssid = TextEditingController();
  final _wpass = TextEditingController();
  final _phone = TextEditingController();
  final _waMsg = TextEditingController();
  final _name = TextEditingController();
  final _org = TextEditingController();
  final _email = TextEditingController();
  String _security = 'WPA';
  bool _hidden = false;
  int _ecl = QrErrorCorrectLevel.M;
  Color _color = SD.black;
  String? _scanned;

  static const _colors = [SD.black, SD.green, SD.nile, SD.indigo, SD.coffee, SD.henna, SD.red, SD.purple, SD.teal];

  @override
  void dispose() {
    for (final c in [_text, _url, _ssid, _wpass, _phone, _waMsg, _name, _org, _email]) {
      c.dispose();
    }
    super.dispose();
  }

  // ---------- بناء البيانات ----------
  static String _esc(String s) => s.replaceAllMapped(RegExp(r'([\\;,:"])'), (m) => '\\${m[1]}');

  /// يحوّل الرقم السوداني لصيغة دولية بدون +: 0912345678 → 249912345678
  static String _intl(String p) {
    const ar = '٠١٢٣٤٥٦٧٨٩';
    final d = p.split('').map((c) => ar.contains(c) ? ar.indexOf(c).toString() : c).join().replaceAll(RegExp(r'[^\d+]'), '');
    if (d.startsWith('+')) return d.substring(1);
    if (d.startsWith('00')) return d.substring(2);
    if (d.startsWith('0') && d.length == 10) return '249${d.substring(1)}';
    if (d.length == 9 && (d.startsWith('9') || d.startsWith('1'))) return '249$d';
    return d;
  }

  String get _data {
    switch (_type) {
      case _QrType.text:
        return _text.text;
      case _QrType.link:
        final u = _url.text.trim();
        if (u.isEmpty) return '';
        return u.contains('://') ? u : 'https://$u';
      case _QrType.wifi:
        if (_ssid.text.isEmpty) return '';
        final t = _security == 'nopass' ? 'nopass' : _security;
        return 'WIFI:T:$t;S:${_esc(_ssid.text)};${t == 'nopass' ? '' : 'P:${_esc(_wpass.text)};'}${_hidden ? 'H:true;' : ''};';
      case _QrType.phone:
        final p = _intl(_phone.text);
        return p.isEmpty ? '' : 'tel:+$p';
      case _QrType.whatsapp:
        final p = _intl(_phone.text);
        if (p.isEmpty) return '';
        final m = _waMsg.text.trim();
        return 'https://wa.me/$p${m.isEmpty ? '' : '?text=${Uri.encodeComponent(m)}'}';
      case _QrType.contact:
        if (_name.text.trim().isEmpty) return '';
        final p = _intl(_phone.text);
        return [
          'BEGIN:VCARD',
          'VERSION:3.0',
          'N:;${_name.text.trim()};;;',
          'FN:${_name.text.trim()}',
          if (p.isNotEmpty) 'TEL;TYPE=CELL:+$p',
          if (_email.text.trim().isNotEmpty) 'EMAIL:${_email.text.trim()}',
          if (_org.text.trim().isNotEmpty) 'ORG:${_org.text.trim()}',
          'END:VCARD',
        ].join('\n');
    }
  }

  String get _eclName => switch (_ecl) {
        QrErrorCorrectLevel.L => 'L (7%)',
        QrErrorCorrectLevel.M => 'M (15%)',
        QrErrorCorrectLevel.Q => 'Q (25%)',
        _ => 'H (30%)',
      };

  Future<Uint8List?> _renderPng(String data) async {
    try {
      final painter = QrPainter(
        data: data,
        version: QrVersions.auto,
        errorCorrectionLevel: _ecl,
        gapless: true,
        eyeStyle: QrEyeStyle(eyeShape: QrEyeShape.square, color: _color),
        dataModuleStyle: QrDataModuleStyle(dataModuleShape: QrDataModuleShape.square, color: _color),
      );
      const size = 1024.0, pad = 80.0;
      // نرسم خلفية بيضاء حتى يقرأ الكود أي ماسح (الشفافية تتعب بعض الماسحات)
      final rec = ui.PictureRecorder();
      final canvas = Canvas(rec);
      canvas.drawRect(const Rect.fromLTWH(0, 0, size + pad * 2, size + pad * 2), Paint()..color = const Color(0xFFFFFFFF));
      canvas.translate(pad, pad);
      painter.paint(canvas, const Size(size, size));
      final img = await rec.endRecording().toImage((size + pad * 2).toInt(), (size + pad * 2).toInt());
      final bd = await img.toByteData(format: ui.ImageByteFormat.png);
      return bd?.buffer.asUint8List();
    } catch (_) {
      return null;
    }
  }

  Future<void> _sharePng() async {
    final d = _data;
    if (d.isEmpty) return toast('أكتب البيانات أول');
    final png = await _renderPng(d);
    if (png == null) return toast('في مشكلة في رسم الرمز، يمكن البيانات طويلة شديد');
    await shareBytes(png, 'amir_qr_${DateTime.now().millisecondsSinceEpoch}.png', 'image/png', text: 'رمز QR (${_type.label})');
  }

  // ---------- القراءة ----------
  Future<void> _openScanner() async {
    final r = await Navigator.of(context).push<String>(MaterialPageRoute(builder: (_) => const _ScannerPage()));
    if (r != null && mounted) setState(() => _scanned = r);
  }

  Future<void> _scanFromGallery() async {
    if (kIsWeb) return toast('القراءة من الصور ما متاحة في نسخة الويب');
    final ctrl = MobileScannerController(autoStart: false);
    try {
      final x = await ImagePicker().pickImage(source: ImageSource.gallery);
      if (x == null) return;
      final cap = await ctrl.analyzeImage(x.path);
      final v = cap?.barcodes.where((b) => (b.rawValue ?? '').isNotEmpty).map((b) => b.rawValue!).firstOrNull;
      if (v == null) {
        toast('ما لقينا رمز QR في الصورة دي');
      } else if (mounted) {
        setState(() => _scanned = v);
      }
    } catch (_) {
      toast('ما قدرنا نقرأ الصورة');
    } finally {
      ctrl.dispose();
    }
  }

  @override
  Widget build(BuildContext context) {
    return ToolList(children: [
      SegmentedButton<int>(
        segments: const [
          ButtonSegment(value: 0, icon: Icon(Icons.qr_code_2_rounded), label: Text('اعمل رمز')),
          ButtonSegment(value: 1, icon: Icon(Icons.qr_code_scanner_rounded), label: Text('اقرأ رمز')),
        ],
        selected: {_tab},
        onSelectionChanged: (v) => setState(() => _tab = v.first),
      ),
      const SizedBox(height: 14),
      if (_tab == 0) ..._buildCreate() else ..._buildScan(),
    ]);
  }

  List<Widget> _buildCreate() {
    final data = _data;
    final v = data.isEmpty ? null : QrValidator.validate(data: data, errorCorrectionLevel: _ecl);
    final bytes = utf8.encode(data).length;
    return [
      SCard(
        title: 'نوع الرمز',
        icon: Icons.category_rounded,
        color: SD.gold,
        child: Wrap(spacing: 8, runSpacing: 8, children: [
          for (final t in _QrType.values)
            ChoiceChip(
              avatar: Icon(t.icon, size: 18),
              label: Text(t.label),
              selected: _type == t,
              onSelected: (_) => setState(() => _type = t),
            ),
        ]),
      ),
      SCard(
        title: 'البيانات',
        icon: Icons.edit_note_rounded,
        color: SD.green,
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: _fields()),
      ),
      SCard(
        title: 'الشكل',
        icon: Icons.palette_rounded,
        color: SD.henna,
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          const Text('لون الرمز'),
          const SizedBox(height: 8),
          Wrap(spacing: 10, runSpacing: 10, children: [
            for (final c in _colors)
              GestureDetector(
                onTap: () => setState(() => _color = c),
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: c,
                    shape: BoxShape.circle,
                    border: Border.all(color: _color == c ? SD.gold : Colors.transparent, width: 3),
                  ),
                  child: _color == c ? const Icon(Icons.check_rounded, color: Colors.white, size: 18) : null,
                ),
              ),
          ]),
          const SizedBox(height: 12),
          const Text('تصحيح الأخطاء (كل ما زاد، الرمز بيتقري حتى لو اتوسّخ أو اتخدش)'),
          const SizedBox(height: 6),
          SegmentedButton<int>(
            showSelectedIcon: false,
            segments: const [
              ButtonSegment(value: QrErrorCorrectLevel.L, label: Text('L')),
              ButtonSegment(value: QrErrorCorrectLevel.M, label: Text('M')),
              ButtonSegment(value: QrErrorCorrectLevel.Q, label: Text('Q')),
              ButtonSegment(value: QrErrorCorrectLevel.H, label: Text('H')),
            ],
            selected: {_ecl},
            onSelectionChanged: (s) => setState(() => _ecl = s.first),
          ),
        ]),
      ),
      if (data.isEmpty)
        const NoteBox('أكتب البيانات فوق، والرمز بيطلع هنا طوالي 👇', kind: NoteKind.tip)
      else if (v != null && !v.isValid)
        const NoteBox('البيانات طويلة شديد على رمز QR واحد، قصّرها شوية أو اختار تصحيح أقل.', kind: NoteKind.warn)
      else ...[
        Center(
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              // الرمز يحتاج خلفية فاتحة عشان يتقري صاح
              color: const Color(0xFFFFFFFF),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: SD.gold, width: 2),
            ),
            child: QrImageView(
              data: data,
              size: 240,
              padding: EdgeInsets.zero,
              errorCorrectionLevel: _ecl,
              eyeStyle: QrEyeStyle(eyeShape: QrEyeShape.square, color: _color),
              dataModuleStyle: QrDataModuleStyle(dataModuleShape: QrDataModuleShape.square, color: _color),
            ),
          ),
        ),
        const SizedBox(height: 14),
        SCard(
          title: 'تفاصيل الرمز',
          icon: Icons.info_outline_rounded,
          color: SD.nile,
          child: Column(children: [
            InfoRow('النوع', _type.label, icon: _type.icon),
            InfoRow('عدد الحروف', '${data.length}', icon: Icons.text_fields_rounded),
            InfoRow('الحجم بالبايت (UTF-8)', '$bytes بايت', icon: Icons.memory_rounded),
            if (v?.qrCode != null) ...[
              InfoRow('إصدار الرمز', '${v!.qrCode!.typeNumber} من 40', icon: Icons.layers_rounded),
              InfoRow('عدد المربعات', '${v.qrCode!.moduleCount} × ${v.qrCode!.moduleCount}', icon: Icons.grid_4x4_rounded),
            ],
            InfoRow('مستوى التصحيح', _eclName, icon: Icons.healing_rounded),
            InfoRow('مقاس الصورة المحفوظة', '1184 × 1184 بكسل PNG', icon: Icons.image_rounded),
          ]),
        ),
        Row(children: [
          Expanded(child: OutlinedButton.icon(onPressed: () => copyText(data), icon: const Icon(Icons.copy_rounded), label: const Text('انسخ النص'))),
          const SizedBox(width: 10),
          Expanded(child: FilledButton.icon(onPressed: _sharePng, icon: const Icon(Icons.ios_share_rounded), label: const Text('احفظ / شارك'))),
        ]),
        const SizedBox(height: 10),
        if (_type == _QrType.wifi)
          const NoteBox('علّق الرمز ده في البيت أو الدكان، والضيوف يتصلوا بالواي فاي بدون ما تقول ليهم كلمة السر 👌', kind: NoteKind.tip),
        if (_type == _QrType.whatsapp)
          const NoteBox('الرقم السوداني بيتحوّل براهو للصيغة الدولية (+249). لو الرقم من بلد تاني أكتبه بمفتاحه.', kind: NoteKind.info),
      ],
    ];
  }

  List<Widget> _fields() {
    Widget f(TextEditingController c, String label, {IconData? icon, TextInputType? kb, int lines = 1, bool ltr = false}) => Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: TextField(
            controller: c,
            onChanged: (_) => setState(() {}),
            keyboardType: kb,
            minLines: 1,
            maxLines: lines,
            textDirection: ltr ? TextDirection.ltr : null,
            decoration: InputDecoration(labelText: label, prefixIcon: icon == null ? null : Icon(icon)),
          ),
        );
    switch (_type) {
      case _QrType.text:
        return [f(_text, 'أكتب هنا أي نص', icon: Icons.notes_rounded, lines: 6)];
      case _QrType.link:
        return [f(_url, 'الرابط (مثلاً example.com)', icon: Icons.link_rounded, kb: TextInputType.url, ltr: true)];
      case _QrType.wifi:
        return [
          f(_ssid, 'اسم الشبكة (SSID)', icon: Icons.wifi_rounded, ltr: true),
          if (_security != 'nopass') f(_wpass, 'كلمة السر', icon: Icons.key_rounded, ltr: true),
          Wrap(spacing: 8, children: [
            for (final s in const [('WPA', 'WPA/WPA2'), ('WEP', 'WEP'), ('nopass', 'مفتوحة')])
              ChoiceChip(label: Text(s.$2), selected: _security == s.$1, onSelected: (_) => setState(() => _security = s.$1)),
          ]),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('الشبكة مخفية'),
            value: _hidden,
            onChanged: (v) => setState(() => _hidden = v),
          ),
        ];
      case _QrType.phone:
        return [f(_phone, 'رقم التلفون (مثلاً 0912345678)', icon: Icons.call_rounded, kb: TextInputType.phone, ltr: true)];
      case _QrType.whatsapp:
        return [
          f(_phone, 'رقم الواتساب', icon: Icons.call_rounded, kb: TextInputType.phone, ltr: true),
          f(_waMsg, 'رسالة جاهزة (اختياري)', icon: Icons.message_rounded, lines: 3),
        ];
      case _QrType.contact:
        return [
          f(_name, 'الاسم', icon: Icons.person_rounded),
          f(_phone, 'التلفون', icon: Icons.call_rounded, kb: TextInputType.phone, ltr: true),
          f(_email, 'الإيميل (اختياري)', icon: Icons.alternate_email_rounded, kb: TextInputType.emailAddress, ltr: true),
          f(_org, 'الشغل / الشركة (اختياري)', icon: Icons.work_rounded),
        ];
    }
  }

  List<Widget> _buildScan() {
    return [
      SCard(
        title: 'اقرأ رمز QR أو باركود',
        icon: Icons.qr_code_scanner_rounded,
        color: SD.nile,
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          FilledButton.icon(onPressed: _openScanner, icon: const Icon(Icons.camera_alt_rounded), label: const Text('افتح الكاميرا')),
          const SizedBox(height: 10),
          OutlinedButton.icon(onPressed: _scanFromGallery, icon: const Icon(Icons.photo_library_rounded), label: const Text('اقرأ من صورة في الجهاز')),
        ]),
      ),
      if (_scanned != null) _ScanResult(_scanned!) else const NoteBox('وجّه الكاميرا على الرمز وخليها ثابتة شوية، بنقراهو براهو.', kind: NoteKind.tip),
      const NoteBox('انتبه: ما تفتح أي رابط من رمز ما عارف مصدره، في ناس بيستعملوا الرموز للاحتيال وسرقة الحسابات.', kind: NoteKind.warn),
    ];
  }
}

/// تحليل محتوى الرمز المقروء
class _ScanResult extends StatelessWidget {
  final String raw;
  const _ScanResult(this.raw);

  Map<String, String> _parseWifi(String s) {
    final m = <String, String>{};
    final body = s.substring(5);
    final re = RegExp(r'([TSPH]):((?:\\.|[^;])*);');
    for (final x in re.allMatches(body)) {
      m[x[1]!] = x[2]!.replaceAllMapped(RegExp(r'\\(.)'), (y) => y[1]!);
    }
    return m;
  }

  Future<void> _open(String url) async {
    try {
      final ok = await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
      if (!ok) toast('ما لقينا تطبيق يفتح الرابط ده');
    } catch (_) {
      toast('الرابط ده ما بيتفتح');
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = raw.trim();
    final up = s.toUpperCase();
    String kind;
    IconData icon;
    final rows = <Widget>[];
    final actions = <Widget>[];
    if (up.startsWith('WIFI:')) {
      kind = 'شبكة واي فاي';
      icon = Icons.wifi_rounded;
      final w = _parseWifi(s);
      rows.addAll([
        InfoRow('اسم الشبكة', w['S'] ?? '—', icon: Icons.router_rounded),
        InfoRow('الحماية', w['T'] == 'nopass' || (w['T'] ?? '').isEmpty ? 'مفتوحة' : w['T']!, icon: Icons.shield_rounded),
        InfoRow('كلمة السر', (w['P'] ?? '').isEmpty ? '—' : w['P']!, icon: Icons.key_rounded),
        if (w['H'] == 'true') const InfoRow('مخفية', 'أيوه', icon: Icons.visibility_off_rounded),
      ]);
      if ((w['P'] ?? '').isNotEmpty) {
        actions.add(FilledButton.icon(onPressed: () => copyText(w['P']!), icon: const Icon(Icons.key_rounded), label: const Text('انسخ كلمة السر')));
      }
    } else if (up.startsWith('BEGIN:VCARD')) {
      kind = 'كرت اتصال';
      icon = Icons.contact_page_rounded;
      for (final line in s.split(RegExp(r'\r?\n'))) {
        final i = line.indexOf(':');
        if (i < 0) continue;
        final k = line.substring(0, i).split(';').first.toUpperCase();
        final v = line.substring(i + 1);
        final label = {'FN': 'الاسم', 'TEL': 'التلفون', 'EMAIL': 'الإيميل', 'ORG': 'الجهة', 'TITLE': 'الوظيفة', 'ADR': 'العنوان', 'URL': 'الموقع'}[k];
        if (label != null && v.trim().isNotEmpty) rows.add(InfoRow(label, v.replaceAll(';', ' ').trim()));
        if (k == 'TEL') actions.add(FilledButton.icon(onPressed: () => _open('tel:$v'), icon: const Icon(Icons.call_rounded), label: Text('اتصل $v')));
      }
    } else if (up.startsWith('TEL:') || RegExp(r'^\+?[\d\s-]{7,15}$').hasMatch(s)) {
      kind = 'رقم تلفون';
      icon = Icons.call_rounded;
      final n = up.startsWith('TEL:') ? s.substring(4) : s;
      rows.add(InfoRow('الرقم', n, icon: Icons.dialpad_rounded));
      actions.add(FilledButton.icon(onPressed: () => _open('tel:$n'), icon: const Icon(Icons.call_rounded), label: const Text('اتصل')));
    } else if (up.startsWith('SMSTO:') || up.startsWith('SMS:')) {
      kind = 'رسالة SMS';
      icon = Icons.sms_rounded;
      final parts = s.split(':');
      rows.add(InfoRow('الرقم', parts.length > 1 ? parts[1] : '—'));
      if (parts.length > 2) rows.add(InfoRow('الرسالة', parts.sublist(2).join(':')));
      actions.add(FilledButton.icon(onPressed: () => _open('sms:${parts.length > 1 ? parts[1] : ''}'), icon: const Icon(Icons.sms_rounded), label: const Text('افتح الرسائل')));
    } else if (up.startsWith('MAILTO:')) {
      kind = 'إيميل';
      icon = Icons.email_rounded;
      rows.add(InfoRow('العنوان', s.substring(7).split('?').first));
      actions.add(FilledButton.icon(onPressed: () => _open(s), icon: const Icon(Icons.email_rounded), label: const Text('اكتب إيميل')));
    } else if (up.startsWith('GEO:')) {
      kind = 'موقع جغرافي';
      icon = Icons.place_rounded;
      final c = s.substring(4).split('?').first;
      rows.add(InfoRow('الإحداثيات', c));
      actions.add(FilledButton.icon(onPressed: () => _open('https://maps.google.com/?q=$c'), icon: const Icon(Icons.map_rounded), label: const Text('افتح في الخريطة')));
    } else if (RegExp(r'^(https?://|www\.)', caseSensitive: false).hasMatch(s)) {
      final url = s.toLowerCase().startsWith('www.') ? 'https://$s' : s;
      final u = Uri.tryParse(url);
      final isWa = (u?.host ?? '').contains('wa.me') || (u?.host ?? '').contains('whatsapp');
      kind = isWa ? 'رابط واتساب' : 'رابط موقع';
      icon = isWa ? Icons.chat_rounded : Icons.link_rounded;
      rows.addAll([
        InfoRow('الموقع (الدومين)', u?.host ?? '—', icon: Icons.public_rounded),
        InfoRow('آمن (https)', url.toLowerCase().startsWith('https') ? 'أيوه 🔒' : 'لا ⚠️', icon: Icons.lock_rounded),
      ]);
      actions.add(FilledButton.icon(onPressed: () => _open(url), icon: const Icon(Icons.open_in_new_rounded), label: const Text('افتح الرابط')));
    } else {
      kind = 'نص عادي';
      icon = Icons.notes_rounded;
      rows.add(InfoRow('عدد الحروف', '${s.length}'));
    }
    return SCard(
      title: 'النتيجة: $kind',
      icon: icon,
      color: SD.green,
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: SD.gold.withValues(alpha: .10), borderRadius: BorderRadius.circular(14)),
          child: SelectableText(s, textDirection: TextDirection.ltr),
        ),
        const SizedBox(height: 8),
        ...rows,
        const SizedBox(height: 10),
        for (final a in actions) Padding(padding: const EdgeInsets.only(bottom: 8), child: a),
        ShareBar(() => s),
      ]),
    );
  }
}

/// شاشة الكاميرا للقراءة
class _ScannerPage extends StatefulWidget {
  const _ScannerPage();
  @override
  State<_ScannerPage> createState() => _ScannerPageState();
}

class _ScannerPageState extends State<_ScannerPage> {
  final _ctrl = MobileScannerController(detectionSpeed: DetectionSpeed.noDuplicates);
  bool _done = false;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SD.black,
      appBar: AppBar(
        title: const Text('وجّه الكاميرا على الرمز'),
        actions: [
          IconButton(onPressed: () => _ctrl.toggleTorch(), icon: const Icon(Icons.flashlight_on_rounded), tooltip: 'الكشاف'),
          IconButton(onPressed: () => _ctrl.switchCamera(), icon: const Icon(Icons.cameraswitch_rounded), tooltip: 'بدّل الكاميرا'),
        ],
      ),
      body: Stack(children: [
        MobileScanner(
          controller: _ctrl,
          onDetect: (cap) {
            if (_done) return;
            final v = cap.barcodes.map((b) => b.rawValue).whereType<String>().where((x) => x.isNotEmpty).firstOrNull;
            if (v != null) {
              _done = true;
              Navigator.of(context).pop(v);
            }
          },
          errorBuilder: (ctx, e) {
            final msg = switch (e.errorCode) {
              MobileScannerErrorCode.permissionDenied => 'ما عندنا إذن الكاميرا. افتح الإعدادات واسمح للتطبيق يستعمل الكاميرا.',
              MobileScannerErrorCode.unsupported => 'الجهاز ده ما بيدعم قراءة الرموز بالكاميرا.',
              _ => 'في مشكلة في تشغيل الكاميرا: ${e.errorDetails?.message ?? ''}',
            };
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  const Icon(Icons.no_photography_rounded, color: SD.gold, size: 56),
                  const SizedBox(height: 12),
                  Text(msg, textAlign: TextAlign.center, style: const TextStyle(color: SD.sand, fontSize: 16)),
                ]),
              ),
            );
          },
        ),
        IgnorePointer(
          child: Center(
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(border: Border.all(color: SD.gold, width: 4), borderRadius: BorderRadius.circular(24)),
            ),
          ),
        ),
      ]),
    );
  }
}
