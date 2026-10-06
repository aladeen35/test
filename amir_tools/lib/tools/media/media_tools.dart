import 'package:flutter/material.dart';
import '../../core/theme.dart';
import '../../core/i18n.dart';
import '../registry.dart';
import 'image_tool.dart';
import 'ocr_tool.dart';
import 'password_tool.dart';
import 'qr_tool.dart';
import 'text_tool.dart';
import 'vault_tool.dart';

List<ToolDef> get mediaTools => [
  ToolDef(
    id: 'ocr',
    name: t('استخراج النص من الصور', 'استخراج النص من الصور', 'Text from Image (OCR)'),
    sub: t('عربي وإنجليزي', 'عربي وإنجليزي', 'Arabic & English'),
    cat: ToolCat.media,
    icon: Icons.document_scanner_rounded,
    color: SD.teal,
    keywords: 'ocr نص صورة استخراج مسح كتابة text scan image extract',
    builder: (_) => const OcrTool(),
  ),
  ToolDef(
    id: 'qr',
    name: tr('رمز QR', 'QR Code'),
    sub: t('اعمل واقرأ رموز QR: روابط، واي فاي، واتساب', 'أنشئ واقرأ رموز QR: روابط، واي فاي، واتساب', 'Create & scan QR codes: links, Wi‑Fi, WhatsApp'),
    cat: ToolCat.media,
    icon: Icons.qr_code_2_rounded,
    color: SD.nile,
    keywords: 'qr باركود كيو ار واي فاي wifi مسح سكان barcode scan code link whatsapp',
    builder: (_) => const QrTool(),
  ),
  ToolDef(id: 'password', name: tr('كلمات السر', 'Passwords'), sub: tr('مولّد وفاحص', 'Generator & checker'), cat: ToolCat.media, icon: Icons.password_rounded,
      color: SD.indigo, keywords: 'كلمة سر باسوورد مرور password generator strength passphrase', builder: (_) => const PasswordTool()),
  ToolDef(id: 'vault', name: tr('الخزنة السرية', 'Secret Vault'), sub: tr('ملاحظات مشفّرة', 'Encrypted notes'), cat: ToolCat.media, icon: Icons.lock_rounded,
      color: SD.red, keywords: 'خزنة سر ملاحظات تشفير vault secret notes encrypt private pin', builder: (_) => const VaultTool()),
  ToolDef(id: 'image', name: tr('ضغط الصور', 'Image Compressor'), sub: t('وفّر الباقة', 'وفّر باقة الإنترنت', 'Save mobile data'), cat: ToolCat.media, icon: Icons.photo_size_select_large_rounded,
      color: SD.teal, sudan: true, keywords: 'صورة ضغط حجم باقة واتساب image photo compress resize size data', builder: (_) => const ImageTool()),
  ToolDef(id: 'text', name: tr('أدوات النص', 'Text Tools'), sub: tr('عدّ، تنظيف، نطق، زخرفة', 'Count, clean, speak, decorate'), cat: ToolCat.media, icon: Icons.text_fields_rounded,
      color: SD.henna, keywords: 'نص كلمات تشكيل نطق املاء صوت text words count diacritics speech tts dictation voice', builder: (_) => const TextTool()),
];
