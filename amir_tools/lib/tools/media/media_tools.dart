import 'package:flutter/material.dart';
import '../../core/theme.dart';
import '../registry.dart';
import 'image_tool.dart';
import 'password_tool.dart';
import 'qr_tool.dart';
import 'text_tool.dart';
import 'vault_tool.dart';

final List<ToolDef> mediaTools = [
  ToolDef(
    id: 'qr',
    name: 'رمز QR',
    sub: 'اعمل واقرأ رموز QR: روابط، واي فاي، واتساب',
    cat: ToolCat.media,
    icon: Icons.qr_code_2_rounded,
    color: SD.nile,
    keywords: 'qr باركود كيو ار واي فاي wifi مسح سكان',
    builder: (_) => const QrTool(),
  ),
  ToolDef(id: 'password', name: 'كلمات السر', sub: 'مولّد وفاحص', cat: ToolCat.media, icon: Icons.password_rounded,
      color: SD.indigo, keywords: 'كلمة سر باسوورد مرور', builder: (_) => const PasswordTool()),
  ToolDef(id: 'vault', name: 'الخزنة السرية', sub: 'ملاحظات مشفّرة', cat: ToolCat.media, icon: Icons.lock_rounded,
      color: SD.red, keywords: 'خزنة سر ملاحظات تشفير', builder: (_) => const VaultTool()),
  ToolDef(id: 'image', name: 'ضغط الصور', sub: 'وفّر الباقة', cat: ToolCat.media, icon: Icons.photo_size_select_large_rounded,
      color: SD.teal, sudan: true, keywords: 'صورة ضغط حجم باقة واتساب', builder: (_) => const ImageTool()),
  ToolDef(id: 'text', name: 'أدوات النص', sub: 'عدّ، تنظيف، نطق', cat: ToolCat.media, icon: Icons.text_fields_rounded,
      color: SD.henna, keywords: 'نص كلمات تشكيل نطق املاء صوت', builder: (_) => const TextTool()),
];
