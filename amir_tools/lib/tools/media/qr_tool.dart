import 'dart:convert';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/i18n.dart';
import '../../core/state.dart';
import '../../core/theme.dart';
import '../../core/widgets.dart';
import 'media_common.dart';

enum _QrType {
  text('نص', 'نص', 'Text', Icons.notes_rounded),
  link('رابط', 'رابط', 'Link', Icons.link_rounded),
  wifi('واي فاي', 'واي فاي', 'Wi‑Fi', Icons.wifi_rounded),
  phone('رقم تلفون', 'رقم هاتف', 'Phone number', Icons.call_rounded),
  whatsapp('واتساب', 'واتساب', 'WhatsApp', Icons.chat_rounded),
  contact('كرت اتصال', 'بطاقة اتصال', 'Contact card', Icons.contact_page_rounded);

  final String sd, ar, en;
  final IconData icon;
  const _QrType(this.sd, this.ar, this.en, this.icon);
  String get label => t(sd, ar, en);
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
        final sec = _security == 'nopass' ? 'nopass' : _security;
        return 'WIFI:T:$sec;S:${_esc(_ssid.text)};${sec == 'nopass' ? '' : 'P:${_esc(_wpass.text)};'}${_hidden ? 'H:true;' : ''};';
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
    if (d.isEmpty) return toast(t('أكتب البيانات أول', 'اكتب البيانات أولاً', 'Enter the data first'));
    final png = await _renderPng(d);
    if (png == null) {
      return toast(t('في مشكلة في رسم الرمز، يمكن البيانات طويلة شديد', 'حدثت مشكلة في رسم الرمز، ربما البيانات طويلة جداً', "Couldn't draw the code — the data may be too long"));
    }
    await shareBytes(png, 'amir_qr_${DateTime.now().millisecondsSinceEpoch}.png', 'image/png', text: '${tr('رمز QR', 'QR code')} (${_type.label})');
  }

  // ---------- القراءة ----------
  Future<void> _openScanner() async {
    final r = await Navigator.of(context).push<String>(MaterialPageRoute(builder: (_) => const _ScannerPage()));
    if (r != null && mounted) setState(() => _scanned = r);
  }

  Future<void> _scanFromGallery() async {
    if (kIsWeb) return toast(t('القراءة من الصور ما متاحة في نسخة الويب', 'القراءة من الصور غير متاحة في نسخة الويب', 'Scanning from images is not available on the web'));
    final ctrl = MobileScannerController(autoStart: false);
    try {
      final x = await ImagePicker().pickImage(source: ImageSource.gallery);
      if (x == null) return;
      final cap = await ctrl.analyzeImage(x.path);
      final v = cap?.barcodes.where((b) => (b.rawValue ?? '').isNotEmpty).map((b) => b.rawValue!).firstOrNull;
      if (v == null) {
        toast(t('ما لقينا رمز QR في الصورة دي', 'لم نجد رمز QR في هذه الصورة', 'No QR code found in this image'));
      } else if (mounted) {
        setState(() => _scanned = v);
      }
    } catch (_) {
      toast(t('ما قدرنا نقرأ الصورة', 'تعذّرت قراءة الصورة', "Couldn't read the image"));
    } finally {
      ctrl.dispose();
    }
  }

  @override
  Widget build(BuildContext context) {
    return ToolList(children: [
      SegmentedButton<int>(
        segments: [
          ButtonSegment(value: 0, icon: const Icon(Icons.qr_code_2_rounded), label: Text(t('اعمل رمز', 'أنشئ رمزاً', 'Create'))),
          ButtonSegment(value: 1, icon: const Icon(Icons.qr_code_scanner_rounded), label: Text(t('اقرأ رمز', 'اقرأ رمزاً', 'Scan'))),
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
        title: tr('نوع الرمز', 'Code type'),
        icon: Icons.category_rounded,
        color: SD.gold,
        child: Wrap(spacing: 8, runSpacing: 8, children: [
          for (final q in _QrType.values)
            ChoiceChip(
              avatar: Icon(q.icon, size: 18),
              label: Text(q.label),
              selected: _type == q,
              onSelected: (_) => setState(() => _type = q),
            ),
        ]),
      ),
      SCard(
        title: tr('البيانات', 'Data'),
        icon: Icons.edit_note_rounded,
        color: SD.green,
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: _fields()),
      ),
      SCard(
        title: tr('الشكل', 'Style'),
        icon: Icons.palette_rounded,
        color: SD.henna,
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Text(tr('لون الرمز', 'Code color')),
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
          Text(t('تصحيح الأخطاء (كل ما زاد، الرمز بيتقري حتى لو اتوسّخ أو اتخدش)', 'تصحيح الأخطاء (كلما زاد، أمكن قراءة الرمز حتى لو اتّسخ أو خُدش)',
              'Error correction (higher = still readable when dirty or scratched)')),
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
        NoteBox(t('أكتب البيانات فوق، والرمز بيطلع هنا طوالي 👇', 'اكتب البيانات أعلاه، وسيظهر الرمز هنا فوراً 👇', 'Enter the data above and the code appears here instantly 👇'), kind: NoteKind.tip)
      else if (v != null && !v.isValid)
        NoteBox(
            t('البيانات طويلة شديد على رمز QR واحد، قصّرها شوية أو اختار تصحيح أقل.', 'البيانات طويلة جداً على رمز QR واحد، اختصرها قليلاً أو اختر تصحيحاً أقل.',
                'Too much data for one QR code — shorten it or choose lower error correction.'),
            kind: NoteKind.warn)
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
          title: tr('تفاصيل الرمز', 'Code details'),
          icon: Icons.info_outline_rounded,
          color: SD.nile,
          child: Column(children: [
            InfoRow(tr('النوع', 'Type'), _type.label, icon: _type.icon),
            InfoRow(tr('عدد الحروف', 'Characters'), '${data.length}', icon: Icons.text_fields_rounded),
            InfoRow(tr('الحجم بالبايت (UTF-8)', 'Size in bytes (UTF-8)'), '$bytes ${tr('بايت', 'bytes')}', icon: Icons.memory_rounded),
            if (v?.qrCode != null) ...[
              InfoRow(tr('إصدار الرمز', 'QR version'), '${v!.qrCode!.typeNumber} ${tr('من', 'of')} 40', icon: Icons.layers_rounded),
              InfoRow(tr('عدد المربعات', 'Modules'), '${v.qrCode!.moduleCount} × ${v.qrCode!.moduleCount}', icon: Icons.grid_4x4_rounded),
            ],
            InfoRow(tr('مستوى التصحيح', 'Error correction'), _eclName, icon: Icons.healing_rounded),
            InfoRow(tr('مقاس الصورة المحفوظة', 'Saved image size'), tr('1184 × 1184 بكسل PNG', '1184 × 1184 px PNG'), icon: Icons.image_rounded),
          ]),
        ),
        Row(children: [
          Expanded(child: OutlinedButton.icon(onPressed: () => copyText(data), icon: const Icon(Icons.copy_rounded), label: Text(tr('انسخ النص', 'Copy text')))),
          const SizedBox(width: 10),
          Expanded(child: FilledButton.icon(onPressed: _sharePng, icon: const Icon(Icons.ios_share_rounded), label: Text(tr('احفظ / شارك', 'Save / share')))),
        ]),
        const SizedBox(height: 10),
        if (_type == _QrType.wifi)
          NoteBox(
              t('علّق الرمز ده في البيت أو الدكان، والضيوف يتصلوا بالواي فاي بدون ما تقول ليهم كلمة السر 👌',
                  'علّق هذا الرمز في البيت أو المحل، ويتصل الضيوف بالواي فاي دون أن تخبرهم بكلمة السر 👌',
                  'Hang this code at home or in your shop so guests can join the Wi‑Fi without you telling them the password 👌'),
              kind: NoteKind.tip),
        if (_type == _QrType.whatsapp)
          NoteBox(
              t('الرقم السوداني المحلي (09…) بيتحوّل براهو للصيغة الدولية (+249). لو الرقم من بلد تاني أكتبه بمفتاحه الدولي (+…).',
                  'الرقم السوداني المحلي (09…) يتحوّل تلقائياً إلى الصيغة الدولية (+249). إن كان الرقم من بلد آخر فاكتبه بمفتاحه الدولي (+…).',
                  'Local Sudanese numbers (09…) are converted to international format (+249) automatically. For other countries, type the number with its country code (+…).'),
              kind: NoteKind.info),
      ],
    ];
  }

  List<Widget> _fields() {
    Widget f(TextEditingController c, String label, {IconData? icon, TextInputType? kb, int lines = 1, bool ltr = false}) => Padding(
          padding: const EdgeInsetsDirectional.only(bottom: 10),
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
        return [f(_text, t('أكتب هنا أي نص', 'اكتب هنا أي نص', 'Type any text here'), icon: Icons.notes_rounded, lines: 6)];
      case _QrType.link:
        return [f(_url, tr('الرابط (مثلاً example.com)', 'Link (e.g. example.com)'), icon: Icons.link_rounded, kb: TextInputType.url, ltr: true)];
      case _QrType.wifi:
        return [
          f(_ssid, tr('اسم الشبكة (SSID)', 'Network name (SSID)'), icon: Icons.wifi_rounded, ltr: true),
          if (_security != 'nopass') f(_wpass, tr('كلمة السر', 'Password'), icon: Icons.key_rounded, ltr: true),
          Wrap(spacing: 8, children: [
            for (final s in [('WPA', 'WPA/WPA2'), ('WEP', 'WEP'), ('nopass', tr('مفتوحة', 'Open'))])
              ChoiceChip(label: Text(s.$2), selected: _security == s.$1, onSelected: (_) => setState(() => _security = s.$1)),
          ]),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(tr('الشبكة مخفية', 'Hidden network')),
            value: _hidden,
            onChanged: (v) => setState(() => _hidden = v),
          ),
        ];
      case _QrType.phone:
        return [f(_phone, t('رقم التلفون (مثلاً 0912345678)', 'رقم الهاتف (مثلاً 0912345678)', 'Phone number (e.g. +1 555 123 4567)'), icon: Icons.call_rounded, kb: TextInputType.phone, ltr: true)];
      case _QrType.whatsapp:
        return [
          f(_phone, tr('رقم الواتساب', 'WhatsApp number'), icon: Icons.call_rounded, kb: TextInputType.phone, ltr: true),
          f(_waMsg, tr('رسالة جاهزة (اختياري)', 'Prefilled message (optional)'), icon: Icons.message_rounded, lines: 3),
        ];
      case _QrType.contact:
        return [
          f(_name, tr('الاسم', 'Name'), icon: Icons.person_rounded),
          f(_phone, t('التلفون', 'الهاتف', 'Phone'), icon: Icons.call_rounded, kb: TextInputType.phone, ltr: true),
          f(_email, t('الإيميل (اختياري)', 'البريد الإلكتروني (اختياري)', 'Email (optional)'), icon: Icons.alternate_email_rounded, kb: TextInputType.emailAddress, ltr: true),
          f(_org, t('الشغل / الشركة (اختياري)', 'العمل / الشركة (اختياري)', 'Work / company (optional)'), icon: Icons.work_rounded),
        ];
    }
  }

  List<Widget> _buildScan() {
    return [
      SCard(
        title: tr('اقرأ رمز QR أو باركود', 'Scan a QR code or barcode'),
        icon: Icons.qr_code_scanner_rounded,
        color: SD.nile,
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          FilledButton.icon(onPressed: _openScanner, icon: const Icon(Icons.camera_alt_rounded), label: Text(tr('افتح الكاميرا', 'Open camera'))),
          const SizedBox(height: 10),
          OutlinedButton.icon(onPressed: _scanFromGallery, icon: const Icon(Icons.photo_library_rounded), label: Text(tr('اقرأ من صورة في الجهاز', 'Scan from a photo on device'))),
        ]),
      ),
      if (_scanned != null) _ScanResult(_scanned!) else
        NoteBox(t('وجّه الكاميرا على الرمز وخليها ثابتة شوية، بنقراهو براهو.', 'وجّه الكاميرا نحو الرمز وثبّتها قليلاً، وستتم قراءته تلقائياً.', "Point the camera at the code and hold steady — it's read automatically."),
            kind: NoteKind.tip),
      NoteBox(
          t('انتبه: ما تفتح أي رابط من رمز ما عارف مصدره، في ناس بيستعملوا الرموز للاحتيال وسرقة الحسابات.',
              'تنبيه: لا تفتح أي رابط من رمز لا تعرف مصدره، فهناك من يستخدم الرموز للاحتيال وسرقة الحسابات.',
              "Caution: don't open links from codes you don't trust — QR codes are used for scams and account theft."),
          kind: NoteKind.warn),
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
      if (!ok) toast(t('ما لقينا تطبيق يفتح الرابط ده', 'لم نجد تطبيقاً يفتح هذا الرابط', 'No app found to open this link'));
    } catch (_) {
      toast(t('الرابط ده ما بيتفتح', 'تعذّر فتح هذا الرابط', "This link can't be opened"));
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
      kind = tr('شبكة واي فاي', 'Wi‑Fi network');
      icon = Icons.wifi_rounded;
      final w = _parseWifi(s);
      rows.addAll([
        InfoRow(tr('اسم الشبكة', 'Network name'), w['S'] ?? '—', icon: Icons.router_rounded),
        InfoRow(tr('الحماية', 'Security'), w['T'] == 'nopass' || (w['T'] ?? '').isEmpty ? tr('مفتوحة', 'Open') : w['T']!, icon: Icons.shield_rounded),
        InfoRow(tr('كلمة السر', 'Password'), (w['P'] ?? '').isEmpty ? '—' : w['P']!, icon: Icons.key_rounded),
        if (w['H'] == 'true') InfoRow(tr('مخفية', 'Hidden'), t('أيوه', 'نعم', 'Yes'), icon: Icons.visibility_off_rounded),
      ]);
      if ((w['P'] ?? '').isNotEmpty) {
        actions.add(FilledButton.icon(onPressed: () => copyText(w['P']!), icon: const Icon(Icons.key_rounded), label: Text(tr('انسخ كلمة السر', 'Copy password'))));
      }
    } else if (up.startsWith('BEGIN:VCARD')) {
      kind = t('كرت اتصال', 'بطاقة اتصال', 'Contact card');
      icon = Icons.contact_page_rounded;
      for (final line in s.split(RegExp(r'\r?\n'))) {
        final i = line.indexOf(':');
        if (i < 0) continue;
        final k = line.substring(0, i).split(';').first.toUpperCase();
        final v = line.substring(i + 1);
        final label = {
          'FN': tr('الاسم', 'Name'),
          'TEL': t('التلفون', 'الهاتف', 'Phone'),
          'EMAIL': t('الإيميل', 'البريد', 'Email'),
          'ORG': tr('الجهة', 'Organization'),
          'TITLE': tr('الوظيفة', 'Job title'),
          'ADR': tr('العنوان', 'Address'),
          'URL': tr('الموقع', 'Website'),
        }[k];
        if (label != null && v.trim().isNotEmpty) rows.add(InfoRow(label, v.replaceAll(';', ' ').trim()));
        if (k == 'TEL') actions.add(FilledButton.icon(onPressed: () => _open('tel:$v'), icon: const Icon(Icons.call_rounded), label: Text('${tr('اتصل', 'Call')} $v')));
      }
    } else if (up.startsWith('TEL:') || RegExp(r'^\+?[\d\s-]{7,15}$').hasMatch(s)) {
      kind = t('رقم تلفون', 'رقم هاتف', 'Phone number');
      icon = Icons.call_rounded;
      final n = up.startsWith('TEL:') ? s.substring(4) : s;
      rows.add(InfoRow(tr('الرقم', 'Number'), n, icon: Icons.dialpad_rounded));
      actions.add(FilledButton.icon(onPressed: () => _open('tel:$n'), icon: const Icon(Icons.call_rounded), label: Text(tr('اتصل', 'Call'))));
    } else if (up.startsWith('SMSTO:') || up.startsWith('SMS:')) {
      kind = tr('رسالة SMS', 'SMS message');
      icon = Icons.sms_rounded;
      final parts = s.split(':');
      rows.add(InfoRow(tr('الرقم', 'Number'), parts.length > 1 ? parts[1] : '—'));
      if (parts.length > 2) rows.add(InfoRow(tr('الرسالة', 'Message'), parts.sublist(2).join(':')));
      actions.add(FilledButton.icon(onPressed: () => _open('sms:${parts.length > 1 ? parts[1] : ''}'), icon: const Icon(Icons.sms_rounded), label: Text(tr('افتح الرسائل', 'Open messages'))));
    } else if (up.startsWith('MAILTO:')) {
      kind = t('إيميل', 'بريد إلكتروني', 'Email');
      icon = Icons.email_rounded;
      rows.add(InfoRow(tr('العنوان', 'Address'), s.substring(7).split('?').first));
      actions.add(FilledButton.icon(onPressed: () => _open(s), icon: const Icon(Icons.email_rounded), label: Text(t('اكتب إيميل', 'اكتب بريداً', 'Write email'))));
    } else if (up.startsWith('GEO:')) {
      kind = tr('موقع جغرافي', 'Location');
      icon = Icons.place_rounded;
      final c = s.substring(4).split('?').first;
      rows.add(InfoRow(tr('الإحداثيات', 'Coordinates'), c));
      actions.add(FilledButton.icon(onPressed: () => _open('https://maps.google.com/?q=$c'), icon: const Icon(Icons.map_rounded), label: Text(tr('افتح في الخريطة', 'Open in maps'))));
    } else if (RegExp(r'^(https?://|www\.)', caseSensitive: false).hasMatch(s)) {
      final url = s.toLowerCase().startsWith('www.') ? 'https://$s' : s;
      final u = Uri.tryParse(url);
      final isWa = (u?.host ?? '').contains('wa.me') || (u?.host ?? '').contains('whatsapp');
      kind = isWa ? tr('رابط واتساب', 'WhatsApp link') : tr('رابط موقع', 'Website link');
      icon = isWa ? Icons.chat_rounded : Icons.link_rounded;
      rows.addAll([
        InfoRow(tr('الموقع (الدومين)', 'Domain'), u?.host ?? '—', icon: Icons.public_rounded),
        InfoRow(tr('آمن (https)', 'Secure (https)'), url.toLowerCase().startsWith('https') ? '${t('أيوه', 'نعم', 'Yes')} 🔒' : '${tr('لا', 'No')} ⚠️', icon: Icons.lock_rounded),
      ]);
      actions.add(FilledButton.icon(onPressed: () => _open(url), icon: const Icon(Icons.open_in_new_rounded), label: Text(tr('افتح الرابط', 'Open link'))));
    } else {
      kind = tr('نص عادي', 'Plain text');
      icon = Icons.notes_rounded;
      rows.add(InfoRow(tr('عدد الحروف', 'Characters'), '${s.length}'));
    }
    return SCard(
      title: '${tr('النتيجة', 'Result')}: $kind',
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
        for (final a in actions) Padding(padding: const EdgeInsetsDirectional.only(bottom: 8), child: a),
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
        title: Text(t('وجّه الكاميرا على الرمز', 'وجّه الكاميرا نحو الرمز', 'Point the camera at the code')),
        actions: [
          IconButton(onPressed: () => _ctrl.toggleTorch(), icon: const Icon(Icons.flashlight_on_rounded), tooltip: tr('الكشاف', 'Flashlight')),
          IconButton(onPressed: () => _ctrl.switchCamera(), icon: const Icon(Icons.cameraswitch_rounded), tooltip: tr('بدّل الكاميرا', 'Switch camera')),
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
              MobileScannerErrorCode.permissionDenied => t('ما عندنا إذن الكاميرا. افتح الإعدادات واسمح للتطبيق يستعمل الكاميرا.',
                  'لا يوجد إذن للكاميرا. افتح الإعدادات واسمح للتطبيق باستخدام الكاميرا.', 'No camera permission. Open Settings and allow the app to use the camera.'),
              MobileScannerErrorCode.unsupported =>
                t('الجهاز ده ما بيدعم قراءة الرموز بالكاميرا.', 'هذا الجهاز لا يدعم قراءة الرموز بالكاميرا.', "This device doesn't support scanning with the camera."),
              _ => '${t('في مشكلة في تشغيل الكاميرا', 'حدثت مشكلة في تشغيل الكاميرا', 'Camera error')}: ${e.errorDetails?.message ?? ''}',
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
