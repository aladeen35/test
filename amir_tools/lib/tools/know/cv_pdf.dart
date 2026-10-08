import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'cv_model.dart';
import 'know_common.dart' show hasArabic;

/// ألوان القوالب (تراث بني وذهبي)
const _brown = PdfColor.fromInt(0xFF5A3418);
const _brownDeep = PdfColor.fromInt(0xFF3A1F0C);
const _gold = PdfColor.fromInt(0xFFD4A017);
const _goldLight = PdfColor.fromInt(0xFFF6D58B);
const _cream = PdfColor.fromInt(0xFFF8E9CF);
const _ink = PdfColor.fromInt(0xFF222222);
const _grey = PdfColor.fromInt(0xFF666666);
const _line = PdfColor.fromInt(0xFFCCCCCC);

/// يبني مستند PDF للسيرة الذاتية. الخطوط تُمرَّر (Tajawal) لدعم العربية.
/// القوالب: classic | modern | compact
pw.Document buildCvDoc(Map cv, pw.Font regular, pw.Font bold) {
  final rtl = cvRtl(cv);
  final glyphs = _glyphs(regular);
  // يحذف أي حرف غير موجود في الخط (إيموجي وغيره) حتى لا يفشل التصدير
  String clean(String s) => glyphs == null ? s : String.fromCharCodes(s.runes.where((c) => c == 10 || glyphs.contains(c) || _arabicBase(c)));
  final tpl = cvStr(cv, 'tpl').isEmpty ? 'modern' : cvStr(cv, 'tpl');
  final compact = tpl == 'compact';
  final modern = tpl == 'modern';
  final base = compact ? 9.5 : 10.5;
  final accent = modern ? _gold : (compact ? _brown : _ink);

  // نص يراعي اتجاه أي مقطع عربي داخل سيرة إنجليزية
  pw.Widget tx(String s, {double? size, bool b = false, PdfColor? color, pw.TextAlign? align, pw.FontStyle? style}) => pw.Text(
        clean(s),
        textDirection: !rtl && hasArabic(s) ? pw.TextDirection.rtl : null,
        textAlign: align ?? (!rtl && hasArabic(s) ? pw.TextAlign.left : null),
        style: pw.TextStyle(fontSize: size ?? base, fontWeight: b ? pw.FontWeight.bold : pw.FontWeight.normal, color: color ?? _ink, fontStyle: style, lineSpacing: 1.5),
      );

  pw.Widget heading(String key) {
    final label = cvLabel(cv, key);
    if (modern) {
      return pw.Padding(
        padding: const pw.EdgeInsets.only(top: 12, bottom: 5),
        child: pw.Row(children: [
          pw.Container(width: 4, height: 14, color: _gold),
          pw.SizedBox(width: 6),
          tx(label, size: base + 2.5, b: true, color: _brown),
          pw.SizedBox(width: 8),
          pw.Expanded(child: pw.Container(height: 0.8, color: _goldLight)),
        ]),
      );
    }
    return pw.Padding(
      padding: pw.EdgeInsets.only(top: compact ? 8 : 12, bottom: 4),
      child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.stretch, children: [
        tx(compact ? label : label.toUpperCase(), size: base + (compact ? 1.5 : 2.5), b: true, color: accent),
        pw.SizedBox(height: 2),
        pw.Container(height: compact ? 0.6 : 1, color: compact ? _line : _ink),
      ]),
    );
  }

  pw.Widget bullet(String s) => pw.Padding(
        padding: const pw.EdgeInsets.only(top: 1.5),
        child: pw.Row(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
          pw.Container(margin: pw.EdgeInsets.only(top: base * .45), width: 3, height: 3, decoration: pw.BoxDecoration(color: accent, shape: pw.BoxShape.circle)),
          pw.SizedBox(width: 5),
          pw.Expanded(child: tx(s)),
        ]),
      );

  pw.Widget level(int l) => pw.Row(mainAxisSize: pw.MainAxisSize.min, children: [
        for (var i = 1; i <= 5; i++)
          pw.Container(
            width: compact ? 7 : 9,
            height: compact ? 3.5 : 4,
            margin: const pw.EdgeInsets.symmetric(horizontal: 1),
            decoration: pw.BoxDecoration(color: i <= l ? (modern ? _gold : _brown) : _line, borderRadius: pw.BorderRadius.circular(2)),
          ),
      ]);

  pw.Widget titleRow(String left, String right) => pw.Row(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
        pw.Expanded(child: tx(left, b: true, size: base + 1)),
        if (right.isNotEmpty) ...[pw.SizedBox(width: 8), tx(right, color: _grey, size: base - .5)],
      ]);

  // ── الرأس ──
  final name = cvStr(cv, 'name');
  final job = cvStr(cv, 'jobTitle');
  final contacts = cvContacts(cv);
  final extra = [
    if (cvStr(cv, 'nationality').isNotEmpty) '${cvLabel(cv, 'nationality')}: ${cvStr(cv, 'nationality')}',
    if (cvStr(cv, 'birth').isNotEmpty) '${cvLabel(cv, 'birth')}: ${cvStr(cv, 'birth')}',
  ];
  final pw.Widget header;
  if (modern) {
    header = pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.fromLTRB(18, 16, 18, 14),
      decoration: const pw.BoxDecoration(
        color: _brown,
        border: pw.Border(bottom: pw.BorderSide(color: _gold, width: 3)),
      ),
      child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
        tx(name.isEmpty ? '—' : name, size: 22, b: true, color: PdfColors.white),
        if (job.isNotEmpty) tx(job, size: 13, b: true, color: _goldLight),
        if (contacts.isNotEmpty) ...[pw.SizedBox(height: 6), tx(contacts.join('   |   '), size: 9.5, color: _cream)],
        if (extra.isNotEmpty) tx(extra.join('   |   '), size: 9.5, color: _cream),
      ]),
    );
  } else if (compact) {
    header = pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
      pw.Row(crossAxisAlignment: pw.CrossAxisAlignment.end, children: [
        tx(name.isEmpty ? '—' : name, size: 18, b: true, color: _brownDeep),
        if (job.isNotEmpty) ...[pw.SizedBox(width: 10), pw.Expanded(child: tx(job, size: 11, color: _brown))],
      ]),
      if (contacts.isNotEmpty || extra.isNotEmpty) tx([...contacts, ...extra].join('  ·  '), size: 8.5, color: _grey),
      pw.SizedBox(height: 4),
      pw.Container(height: 2, color: _gold),
    ]);
  } else {
    header = pw.Column(children: [
      tx(name.isEmpty ? '—' : name, size: 22, b: true, align: pw.TextAlign.center),
      if (job.isNotEmpty) tx(job, size: 12.5, color: _grey, align: pw.TextAlign.center),
      if (contacts.isNotEmpty) ...[pw.SizedBox(height: 4), tx(contacts.join('  •  '), size: 9.5, align: pw.TextAlign.center)],
      if (extra.isNotEmpty) tx(extra.join('  •  '), size: 9.5, color: _grey, align: pw.TextAlign.center),
      pw.SizedBox(height: 6),
      pw.Container(height: 1.2, color: _ink),
    ]);
  }

  final body = <pw.Widget>[header];

  // ── الملخص ──
  final obj = cvStr(cv, 'objective');
  if (obj.isNotEmpty) {
    body
      ..add(heading('objective'))
      ..add(tx(obj));
  }

  // ── الخبرات ──
  final exp = cvList(cv, 'exp');
  if (exp.isNotEmpty) {
    body.add(heading('exp'));
    for (final e in exp) {
      body.add(pw.SizedBox(height: compact ? 3 : 5));
      body.add(titleRow(itemStr(e, 'title'), cvPeriod(e)));
      final org = [itemStr(e, 'org'), itemStr(e, 'place')].where((x) => x.isNotEmpty).join(' — ');
      if (org.isNotEmpty) body.add(tx(org, color: modern ? _brown : _grey, b: modern));
      for (final p in cvBullets(itemStr(e, 'desc'))) {
        body.add(bullet(p));
      }
    }
  }

  // ── التعليم ──
  final edu = cvList(cv, 'edu');
  if (edu.isNotEmpty) {
    body.add(heading('edu'));
    for (final e in edu) {
      body.add(pw.SizedBox(height: 3));
      body.add(titleRow(itemStr(e, 'degree'), itemStr(e, 'year')));
      final sch = [itemStr(e, 'school'), itemStr(e, 'note')].where((x) => x.isNotEmpty).join(' — ');
      if (sch.isNotEmpty) body.add(tx(sch, color: _grey));
    }
  }

  // ── المهارات ──
  final skills = cvList(cv, 'skills');
  if (skills.isNotEmpty) {
    body.add(heading('skills'));
    body.add(pw.Wrap(spacing: compact ? 10 : 14, runSpacing: 5, children: [
      for (final s in skills)
        pw.SizedBox(
          width: compact ? 150 : 160,
          child: pw.Row(children: [
            pw.Expanded(child: tx(itemStr(s, 'n'))),
            pw.SizedBox(width: 4),
            level(itemLvl(s)),
          ]),
        ),
    ]));
  }

  // ── اللغات ──
  final langs = cvList(cv, 'langs');
  if (langs.isNotEmpty) {
    body.add(heading('langs'));
    body.add(pw.Wrap(spacing: 18, runSpacing: 4, children: [
      for (final l in langs)
        pw.Row(mainAxisSize: pw.MainAxisSize.min, children: [
          tx(itemStr(l, 'n'), b: true),
          pw.SizedBox(width: 5),
          tx(langLevel(cv, itemLvl(l)), color: _grey),
        ]),
    ]));
  }

  // ── الشهادات ──
  final certs = cvList(cv, 'certs');
  if (certs.isNotEmpty) {
    body.add(heading('certs'));
    for (final c in certs) {
      body.add(titleRow([itemStr(c, 'n'), itemStr(c, 'org')].where((x) => x.isNotEmpty).join(' — '), itemStr(c, 'year')));
    }
  }

  // ── المعرّفون ──
  final refs = cvList(cv, 'refs');
  if (cv['refsOnRequest'] == true) {
    body
      ..add(heading('refs'))
      ..add(tx(cvLabel(cv, 'refsOnRequest'), color: _grey));
  } else if (refs.isNotEmpty) {
    body.add(heading('refs'));
    for (final r in refs) {
      body.add(pw.SizedBox(height: 2));
      body.add(tx(itemStr(r, 'n'), b: true));
      final d = [itemStr(r, 'role'), itemStr(r, 'contact')].where((x) => x.isNotEmpty).join(' — ');
      if (d.isNotEmpty) body.add(tx(d, color: _grey));
    }
  }

  final doc = pw.Document(title: name.isEmpty ? 'CV' : name, author: name, creator: 'Ameer Tools');
  doc.addPage(pw.MultiPage(
    maxPages: 8,
    pageTheme: pw.PageTheme(
      pageFormat: PdfPageFormat.a4,
      margin: pw.EdgeInsets.all(compact ? 26 : 34),
      textDirection: rtl ? pw.TextDirection.rtl : pw.TextDirection.ltr,
      theme: pw.ThemeData.withFont(base: regular, bold: bold),
      buildBackground: modern
          ? (ctx) => pw.FullPage(
                ignoreMargins: true,
                child: pw.Align(alignment: pw.Alignment.bottomCenter, child: pw.Container(height: 6, color: _gold)),
              )
          : null,
    ),
    crossAxisAlignment: pw.CrossAxisAlignment.stretch,
    build: (ctx) => body,
    footer: (ctx) => ctx.pagesCount > 1
        ? pw.Align(
            alignment: pw.Alignment.center,
            child: pw.Text('${ctx.pageNumber} / ${ctx.pagesCount}', style: const pw.TextStyle(fontSize: 8, color: _grey)),
          )
        : pw.SizedBox(),
  ));
  return doc;
}

final _glyphCache = Expando<Set<int>>();

Set<int>? _glyphs(pw.Font f) {
  if (f is! pw.TtfFont) return null;
  try {
    return _glyphCache[f] ??= TtfParser(f.data).charToGlyphIndexMap.keys.toSet();
  } catch (_) {
    return null;
  }
}

/// الحروف العربية الأساسية والتشكيل والأرقام والفواصل العربية (تُشكَّل قبل الرسم)
bool _arabicBase(int c) => (c >= 0x0621 && c <= 0x0652) || (c >= 0x0660 && c <= 0x0669) || c == 0x060C || c == 0x061B || c == 0x061F || c == 0x0640;

Future<Uint8List> buildCvPdf(Map cv, pw.Font regular, pw.Font bold) => buildCvDoc(cv, regular, bold).save();
