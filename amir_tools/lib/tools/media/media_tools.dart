import 'package:flutter/material.dart';
import '../../core/theme.dart';
import '../registry.dart';
import 'qr_tool.dart';

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
];
