import 'package:flutter/material.dart';
import '../../core/i18n.dart';
import '../../core/theme.dart';
import '../registry.dart';
import 'elder_care_tool.dart';
import 'emergency_numbers_tool.dart';
import 'family_health_tool.dart';
import 'first_aid_tool.dart';
import 'vaccines_tool.dart';

List<ToolDef> get careTools => [
      ToolDef(
        id: 'vaccines',
        name: tr('اللقاحات والفحوصات', 'Vaccines & Check-ups'),
        sub: t('مواعيد الأسرة مع تذكير', 'مواعيد الأسرة مع تذكير', 'Family due dates & reminders'),
        cat: ToolCat.health,
        icon: Icons.vaccines_rounded,
        color: SD.teal,
        keywords: 'لقاح لقاحات تطعيم فحص فحوصات دوري كزاز انفلونزا ضغط سكر تراكمي اسنان عيون تذكير موعد vaccine vaccination immunization checkup check-up screening tetanus flu blood pressure hba1c dental eye reminder due',
        builder: (_) => const VaccinesTool(),
      ),
      ToolDef(
        id: 'family_health',
        name: tr('السجل الصحي العائلي', 'Family Health Record'),
        sub: t('فصيلة الدم والحساسية وبطاقة طوارئ', 'فصيلة الدم والحساسية وبطاقة طوارئ', 'Blood type, allergies & emergency card'),
        cat: ToolCat.health,
        icon: Icons.medical_information_rounded,
        color: SD.henna,
        keywords: 'سجل صحي ملف طبي فصيلة دم حساسية امراض مزمنة ادوية تأمين بطاقة طوارئ اسرة عائلة health record medical file blood type allergies chronic medicines insurance emergency card family',
        builder: (_) => const FamilyHealthTool(),
      ),
      ToolDef(
        id: 'elder_care',
        name: tr('رعاية كبار السن', 'Elder Care'),
        sub: t('دواء الحبوبة ومراجعاتها واطمئنان يومي', 'أدوية ومواعيد واطمئنان يومي', 'Medicines, visits & daily check-in'),
        cat: ToolCat.health,
        icon: Icons.elderly_rounded,
        color: SD.purple,
        keywords: 'كبار السن حبوبة جدة جد والد والدة رعاية دواء مراجعة طبيب ضغط سكر اطمئنان ممرض elder elderly care grandparent parent medicine appointment doctor caregiver check-in blood pressure sugar',
        builder: (_) => const ElderCareTool(),
      ),
      ToolDef(
        id: 'first_aid',
        name: tr('الإسعافات الأولية', 'First Aid Guide'),
        sub: t('خطوات واضحة بدون نت', 'خطوات واضحة دون إنترنت', 'Clear steps, works offline'),
        cat: ToolCat.health,
        icon: Icons.medical_services_rounded,
        color: SD.red,
        keywords: 'اسعافات اولية اسعاف نزيف حرق شرقة اختناق اغماء كسر رعاف ضربة شمس جفاف عقرب ثعبان تسمم تشنج صرع انعاش كهرباء عين حساسية first aid cpr bleeding burn choking fainting fracture nosebleed heat stroke dehydration ors scorpion snake poisoning seizure electric shock eye allergy',
        builder: (_) => const FirstAidTool(),
      ),
      ToolDef(
        id: 'emergency_numbers',
        name: tr('أرقام الطوارئ', 'Emergency Numbers'),
        sub: t('الشرطة والإسعاف حسب بلدك', 'الشرطة والإسعاف حسب بلدك', 'Police & ambulance by country'),
        cat: ToolCat.health,
        icon: Icons.sos_rounded,
        color: SD.red,
        keywords: 'طوارئ ارقام شرطة اسعاف مطافئ دفاع مدني نجدة 999 911 112 emergency numbers police ambulance fire civil defence sos call',
        builder: (_) => const EmergencyNumbersTool(),
      ),
    ];
