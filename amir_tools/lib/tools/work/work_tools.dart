import 'package:flutter/material.dart';
import '../../core/i18n.dart';
import '../../core/theme.dart';
import '../registry.dart';
import 'documents_tool.dart';
import 'invoice_tool.dart';
import 'phrasebook_tool.dart';
import 'salary_tool.dart';

List<ToolDef> get workTools => [
      ToolDef(
        id: 'salary',
        name: t('حاسبة الماهية ونهاية الخدمة', 'حاسبة الراتب ونهاية الخدمة', 'Salary & End of Service'),
        sub: t('صافي راتبك وحقك لمن تطلع', 'صافي الراتب ومكافأة نهاية الخدمة', 'Net pay, overtime and your end-of-service award'),
        cat: ToolCat.work,
        icon: Icons.calculate_rounded,
        color: SD.green,
        keywords: 'راتب ماهية صافي بدل سكن نقل تأمينات اوفرتايم إضافي نهاية خدمة مكافأة استقالة نظام العمل السعودي '
            'salary net pay allowance overtime gosi end of service gratuity eos award resignation labor law saudi',
        builder: (_) => const SalaryTool(),
      ),
      ToolDef(
        id: 'documents',
        name: t('مواعيد الأوراق الرسمية', 'مواعيد المستندات الرسمية', 'Document Expiry Dates'),
        sub: t('جوازك وإقامتك ما يفوتوك', 'تذكير قبل انتهاء الجواز والإقامة', 'Never miss a passport or permit renewal'),
        cat: ToolCat.work,
        icon: Icons.badge_rounded,
        color: SD.nile,
        keywords: 'جواز اقامة إقامة تأشيرة فيزا رخصة قيادة بطاقة رقم وطني تأمين استمارة تجديد انتهاء تذكير '
            'passport iqama residence permit visa driving license national id insurance registration renewal expiry reminder',
        builder: (_) => const DocumentsTool(),
      ),
      ToolDef(
        id: 'phrasebook',
        name: t('عبارات المغترب', 'عبارات المغترب', 'Expat Phrasebook'),
        sub: t('إنجليزي بالسوداني — بدون نت', 'عبارات إنجليزية بالعربية — دون إنترنت', 'Sudanese Arabic ⇄ English, offline'),
        cat: ToolCat.work,
        icon: Icons.translate_rounded,
        color: SD.teal,
        keywords: 'عبارات ترجمة انجليزي إنجليزي كلمات مطار مستشفى بنك سوق شرطة سكن تحية نطق '
            'phrasebook phrases english arabic translate airport hospital bank shopping police housing greetings speak',
        builder: (_) => const PhrasebookTool(),
      ),
      ToolDef(
        id: 'invoice',
        name: t('فاتورة سريعة', 'فاتورة سريعة', 'Quick Invoice'),
        sub: t('فاتورة لزبونك في ثواني', 'أصدر فاتورة لعميلك في ثوانٍ', 'Make and share a receipt in seconds'),
        cat: ToolCat.work,
        icon: Icons.receipt_long_rounded,
        color: SD.gold,
        keywords: 'فاتورة إيصال ايصال محل متجر زبون عميل ضريبة خصم بيع '
            'invoice receipt bill shop store customer vat tax discount sale',
        builder: (_) => const InvoiceTool(),
      ),
    ];
