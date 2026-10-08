import 'package:flutter/material.dart';
import '../../core/i18n.dart';

/// نوع رقم الطوارئ
enum EmKind {
  general(Icons.sos_rounded, 'طوارئ موحّد', 'Unified emergency'),
  police(Icons.local_police_rounded, 'الشرطة', 'Police'),
  ambulance(Icons.emergency_rounded, 'الإسعاف', 'Ambulance'),
  fire(Icons.local_fire_department_rounded, 'الدفاع المدني / المطافئ', 'Fire / civil defence'),
  health(Icons.health_and_safety_rounded, 'استشارة صحية (غير طارئة)', 'Health advice (non-emergency)'),
  crisis(Icons.support_rounded, 'خط الأزمات النفسية', 'Suicide & crisis line'),
  traffic(Icons.traffic_rounded, 'شرطة المرور', 'Traffic police'),
  power(Icons.electric_bolt_rounded, 'طوارئ الكهرباء', 'Electricity emergency'),
  relief(Icons.volunteer_activism_rounded, 'الهلال الأحمر', 'Red Crescent');

  final IconData icon;
  final String ar, en;
  const EmKind(this.icon, this.ar, this.en);
  String get label => tr(ar, en);
}

class EmNumber {
  final String number;
  final EmKind kind;
  final String? noteAr, noteEn;
  const EmNumber(this.number, this.kind, [this.noteAr, this.noteEn]);
  String? get note => noteAr == null ? null : tr(noteAr!, noteEn ?? noteAr!);
}

class EmCountry {
  final String code, ar, en;
  final List<EmNumber> numbers;
  const EmCountry(this.code, this.ar, this.en, this.numbers);
  String get name => tr(ar, en);
}

/// أرقام طوارئ وطنية منشورة على نطاق واسع — فقط ما نحن متأكدون منه (آخر مراجعة 2026-10)
/// المصدر: المواقع الرسمية للجهات الحكومية وقوائم أرقام الطوارئ الدولية المنشورة.
const emergencyCountries = [
  EmCountry('SD', 'السودان', 'Sudan', [
    EmNumber('999', EmKind.general, 'شرطة النجدة والطوارئ العامة', 'Police emergency (Najda) & general'),
    EmNumber('998', EmKind.fire, 'قوات الدفاع المدني (المطافي)', 'Civil Defence (fire brigade)'),
    EmNumber('777', EmKind.traffic),
    EmNumber('9090', EmKind.health, 'مركز الاتصال الوطني للطوارئ – وزارة الصحة، على مدار الساعة: الحالات الصحية الطارئة والاستفسارات والأوبئة',
        'National emergency call centre – Ministry of Health, 24/7: health emergencies, enquiries and epidemics'),
    EmNumber('0183432500', EmKind.ambulance, 'الإسعاف المركزي – الخرطوم', 'Central ambulance – Khartoum'),
    EmNumber('0187551100', EmKind.ambulance, 'الإسعاف المركزي – أم درمان', 'Central ambulance – Omdurman'),
    EmNumber('0183777256', EmKind.power, 'طوارئ كهرباء الخرطوم', 'Electricity emergency – Khartoum'),
    EmNumber('0185341164', EmKind.power, 'طوارئ كهرباء بحري', 'Electricity emergency – Khartoum North (Bahri)'),
    EmNumber('0187558866', EmKind.power, 'طوارئ كهرباء أم درمان', 'Electricity emergency – Omdurman'),
    EmNumber('0912881874', EmKind.relief, 'جمعية الهلال الأحمر السوداني – خط ساخن للدعم', 'Sudanese Red Crescent – support hotline'),
    EmNumber('0114521874', EmKind.relief, 'جمعية الهلال الأحمر السوداني – خط ساخن للدعم', 'Sudanese Red Crescent – support hotline'),
  ]),
  EmCountry('SA', 'السعودية', 'Saudi Arabia', [
    EmNumber('911', EmKind.general, 'الرقم الموحّد للبلاغات الطارئة', 'Unified emergency number'),
    EmNumber('999', EmKind.police),
    EmNumber('997', EmKind.ambulance, 'الهلال الأحمر', 'Red Crescent'),
    EmNumber('998', EmKind.fire),
  ]),
  EmCountry('AE', 'الإمارات', 'UAE', [
    EmNumber('999', EmKind.police),
    EmNumber('998', EmKind.ambulance),
    EmNumber('997', EmKind.fire),
  ]),
  EmCountry('QA', 'قطر', 'Qatar', [EmNumber('999', EmKind.general)]),
  EmCountry('KW', 'الكويت', 'Kuwait', [EmNumber('112', EmKind.general)]),
  EmCountry('OM', 'عُمان', 'Oman', [EmNumber('9999', EmKind.general)]),
  EmCountry('BH', 'البحرين', 'Bahrain', [EmNumber('999', EmKind.general)]),
  EmCountry('EG', 'مصر', 'Egypt', [
    EmNumber('122', EmKind.police),
    EmNumber('123', EmKind.ambulance),
    EmNumber('180', EmKind.fire),
  ]),
  EmCountry('JO', 'الأردن', 'Jordan', [EmNumber('911', EmKind.general)]),
  EmCountry('TR', 'تركيا', 'Turkey', [EmNumber('112', EmKind.general)]),
  EmCountry('GB', 'المملكة المتحدة', 'United Kingdom', [
    EmNumber('999', EmKind.general),
    EmNumber('112', EmKind.general),
    EmNumber('111', EmKind.health, 'NHS 111', 'NHS 111'),
  ]),
  EmCountry('US', 'الولايات المتحدة', 'United States', [
    EmNumber('911', EmKind.general),
    EmNumber('988', EmKind.crisis),
  ]),
  EmCountry('CA', 'كندا', 'Canada', [
    EmNumber('911', EmKind.general),
    EmNumber('988', EmKind.crisis),
  ]),
  EmCountry('DE', 'ألمانيا', 'Germany', [
    EmNumber('112', EmKind.general, 'الإسعاف والمطافئ', 'Ambulance & fire'),
    EmNumber('110', EmKind.police),
  ]),
  EmCountry('FR', 'فرنسا', 'France', [
    EmNumber('112', EmKind.general),
    EmNumber('15', EmKind.ambulance, 'SAMU', 'SAMU'),
    EmNumber('17', EmKind.police),
    EmNumber('18', EmKind.fire),
  ]),
  EmCountry('EU', 'الاتحاد الأوروبي', 'European Union', [
    EmNumber('112', EmKind.general, 'الرقم الأوروبي الموحّد في كل دول الاتحاد', 'Single European emergency number in all EU countries'),
  ]),
  EmCountry('AU', 'أستراليا', 'Australia', [EmNumber('000', EmKind.general)]),
  EmCountry('NZ', 'نيوزيلندا', 'New Zealand', [EmNumber('111', EmKind.general)]),
  EmCountry('IN', 'الهند', 'India', [EmNumber('112', EmKind.general)]),
  EmCountry('MY', 'ماليزيا', 'Malaysia', [EmNumber('999', EmKind.general)]),
];

/// دول الاتحاد الأوروبي (رمز ISO) — يُعرض لها 112 إن لم يكن لها جدول خاص
const euCountries = {
  'AT', 'BE', 'BG', 'HR', 'CY', 'CZ', 'DK', 'EE', 'FI', 'FR', 'DE', 'GR', 'HU', 'IE', 'IT', 'LV', 'LT', 'LU', 'MT', 'NL', 'PL', 'PT', 'RO', 'SK', 'SI', 'ES', 'SE',
};

/// يختار جدول الدولة من رمزها؛ null إن لم تكن في الجدول
EmCountry? emergencyFor(String code) {
  final c = code.toUpperCase();
  for (final x in emergencyCountries) {
    if (x.code == c) return x;
  }
  if (euCountries.contains(c)) return emergencyCountries.firstWhere((x) => x.code == 'EU');
  return null;
}
