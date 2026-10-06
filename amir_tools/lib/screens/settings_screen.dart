import 'dart:convert';
import 'package:cryptography/cryptography.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import '../core/data.dart';
import '../core/format.dart';
import '../core/i18n.dart';
import 'place_picker.dart';
import '../core/pattern.dart';
import '../core/state.dart';
import '../core/theme.dart';
import '../core/widgets.dart';
import '../services/notifications.dart';
import '../services/prayer.dart';

Future<String> hashPin(String pin) async {
  final h = await Sha256().hash(utf8.encode('amir-tools:$pin'));
  return base64Encode(h.bytes);
}

/// الضبط: الاسم، المدينة، المظهر، النقاط، الصلاة، القفل، النسخ الاحتياطي
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});
  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late final _name = TextEditingController(text: context.read<AppState>().name);

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    return ListView(
      padding: EdgeInsets.fromLTRB(16, MediaQuery.of(context).padding.top + 16, 16, 120),
      children: [
        Center(child: GoldText(t('الضبط', 'الإعدادات', 'Settings'), size: 34)),
        const GoldDivider(),
        SCard(
          title: t('اللغة', 'اللغة', 'Language'),
          icon: Icons.translate_rounded,
          color: SD.gold,
          child: SegmentedButton<Lang>(
            segments: [for (final l in Lang.values) ButtonSegment(value: l, label: Text('${l.flag} ${l.label}'))],
            selected: {s.lang},
            showSelectedIcon: false,
            onSelectionChanged: (v) {
              s.lang = v.first;
              PrayerNotifications.reschedule(s);
            },
          ),
        ),
        SCard(
          title: t('إنت منو؟', 'من أنت؟', 'About you'),
          icon: Icons.person_rounded,
          child: TextField(
            controller: _name,
            decoration: InputDecoration(labelText: t('اسمك', 'اسمك', 'Your name'), hintText: t('مثلًا: أمير', 'مثلًا: أمير', 'e.g. Ameer'), prefixIcon: const Icon(Icons.badge_rounded)),
            onChanged: (v) => s.name = v,
          ),
        ),
        SCard(
          title: t('مكانك', 'موقعك', 'Your location'),
          icon: Icons.public_rounded,
          color: SD.nile,
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Text(flagOf(s.city.country), style: const TextStyle(fontSize: 30)),
              title: Text(s.city.name, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 17)),
              subtitle: Text([
                if (s.city.state.isNotEmpty) s.city.state,
                '${fmt(s.city.lat, 3)}, ${fmt(s.city.lng, 3)}',
                if (placeTz.isNotEmpty) placeTz,
              ].join(' • ')),
            ),
            FilledButton.icon(
              onPressed: () => showPlacePicker(context),
              icon: const Icon(Icons.travel_explore_rounded),
              label: Text(t('غيّر المكان (أي حتة في العالم)', 'تغيير الموقع (أي مكان في العالم)', 'Change location (anywhere)')),
            ),
            const SizedBox(height: 6),
            Text(
                t('المواقيت والقبلة والطقس والساعة بتتظبط على المكان دا، وطريقة حساب الصلاة بتتغيّر براها حسب البلد.',
                    'تُضبط المواقيت والقبلة والطقس والوقت على هذا الموقع، وتُختار طريقة حساب الصلاة تلقائيًا حسب الدولة.',
                    'Prayer times, qibla, weather and clock follow this place; the prayer method is picked automatically by country.'),
                style: const TextStyle(fontSize: 12.5)),
          ]),
        ),
        SCard(
          title: t('الشكل', 'المظهر', 'Appearance'),
          icon: Icons.palette_rounded,
          child: SegmentedButton<ThemeMode>(
            segments: [
              ButtonSegment(value: ThemeMode.dark, label: Text(t('تراثي بُني', 'تراثي بني', 'Heritage')), icon: const Icon(Icons.coffee_rounded)),
              ButtonSegment(value: ThemeMode.light, label: Text(t('رملي فاتح', 'رملي فاتح', 'Sand')), icon: const Icon(Icons.wb_sunny_rounded)),
              ButtonSegment(value: ThemeMode.system, label: Text(t('زي الجهاز', 'حسب الجهاز', 'System')), icon: const Icon(Icons.phone_android_rounded)),
            ],
            selected: {s.themeMode},
            onSelectionChanged: (v) => s.themeMode = v.first,
          ),
        ),
        SCard(
          title: t('نظام النقاط', 'نظام النقاط', 'Points system'),
          icon: Icons.emoji_events_rounded,
          color: SD.gold,
          child: Column(children: [
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              value: s.pointsEnabled,
              onChanged: (v) => s.pointsEnabled = v,
              title: Text(t('فعّل النقاط والمستويات', 'تفعيل النقاط والمستويات', 'Enable points & levels'), style: const TextStyle(fontWeight: FontWeight.w700)),
              subtitle: Text(t('اكسب نقاط لما تستعمل الأدوات وتسجّل صلواتك وأذكارك', 'اكسب نقاطًا باستخدام الأدوات وتسجيل صلواتك وأذكارك', 'Earn points by using tools and logging prayers and adhkar')),
            ),
            if (s.pointsEnabled) InfoRow(tr('مستواك الحالي', 'Current level'), '${s.level} — ${s.levelTitle} (${s.xp} ${tr('نقطة', 'XP')})'),
          ]),
        ),
        SCard(
          title: tr('الصلاة', 'Prayer'),
          icon: Icons.mosque_rounded,
          color: SD.green,
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            DropdownButtonFormField<String>(
              initialValue: s.prayerMethod,
              isExpanded: true,
              decoration: InputDecoration(labelText: tr('طريقة الحساب', 'Calculation method')),
              items: [for (final m in prayerMethods) DropdownMenuItem(value: m.id, child: Text(m.name, overflow: TextOverflow.ellipsis))],
              onChanged: (v) {
                s.prayerMethod = v!;
                PrayerNotifications.reschedule(s);
              },
            ),
            const SizedBox(height: 10),
            SegmentedButton<bool>(
              segments: [ButtonSegment(value: false, label: Text(tr('عصر الجمهور', 'Asr: Standard'))), ButtonSegment(value: true, label: Text(tr('عصر الحنفية', 'Asr: Hanafi')))],
              selected: {s.hanafi},
              onSelectionChanged: (v) {
                s.hanafi = v.first;
                PrayerNotifications.reschedule(s);
              },
            ),
            const SizedBox(height: 12),
            Text(t('تعديل بالدقائق عشان يطابق مسجد حيّك:', 'تعديل بالدقائق لمطابقة مسجد حيّك:', 'Adjust minutes to match your mosque:'), style: const TextStyle(fontWeight: FontWeight.w700)),
            const SizedBox(height: 6),
            for (final k in prayerKeys)
              Row(children: [
                Expanded(child: Text(prayerNames[k]!)),
                IconButton(onPressed: () => _adj(s, k, -1), icon: const Icon(Icons.remove_circle_outline)),
                SizedBox(width: 36, child: Text('${s.prayerAdjust[k] ?? 0}', textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.w800))),
                IconButton(onPressed: () => _adj(s, k, 1), icon: const Icon(Icons.add_circle_outline)),
              ]),
            const Divider(),
            Row(children: [
              Expanded(child: Text(tr('فرق التاريخ الهجري (حسب رؤية الهلال)', 'Hijri date offset (moon sighting)'))),
              IconButton(onPressed: () => s.hijriShift = (s.hijriShift - 1).clamp(-2, 2), icon: const Icon(Icons.remove_circle_outline)),
              Text('${s.hijriShift}', style: const TextStyle(fontWeight: FontWeight.w800)),
              IconButton(onPressed: () => s.hijriShift = (s.hijriShift + 1).clamp(-2, 2), icon: const Icon(Icons.add_circle_outline)),
            ]),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              value: s.prayerNotify,
              title: Text(t('نبّهني وقت الأذان', 'نبّهني عند الأذان', 'Notify me at adhan'), style: const TextStyle(fontWeight: FontWeight.w700)),
              subtitle: Text(PrayerNotifications.supported ? t('بيشتغل حتى لو التطبيق مقفول', 'يعمل حتى لو كان التطبيق مغلقًا', 'Works even when the app is closed') : t('متاح في تطبيق الموبايل بس', 'متاح في تطبيق الجوال فقط', 'Mobile app only')),
              onChanged: (v) async {
                if (v && !await PrayerNotifications.requestPermission()) {
                  toast(t('ما اتدّى إذن التنبيهات', 'لم يُمنح إذن التنبيهات', 'Notification permission denied'));
                  return;
                }
                s.prayerNotify = v;
                await PrayerNotifications.reschedule(s);
                if (v) toast(t('تمام — حننبّهك وقت كل صلاة 🕌', 'تم — سننبّهك عند كل صلاة 🕌', "Done — we'll alert you at each prayer 🕌"));
              },
            ),
          ]),
        ),
        SCard(
          title: t('القفل والخصوصية', 'القفل والخصوصية', 'Lock & privacy'),
          icon: Icons.lock_rounded,
          color: SD.red,
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Text(t('كل بياناتك محفوظة في جهازك بس، ما بنرسلها لأي زول.', 'كل بياناتك محفوظة على جهازك فقط ولا نرسلها لأحد.', 'All your data stays on your device; we never send it anywhere.')),
            const SizedBox(height: 10),
            if (s.pinHash == null)
              FilledButton.icon(onPressed: () => _setPin(s), icon: const Icon(Icons.pin_rounded), label: Text(t('اعمل رمز قفل للتطبيق', 'إنشاء رمز قفل للتطبيق', 'Set an app PIN')))
            else
              OutlinedButton.icon(onPressed: () => s.pinHash = null, icon: const Icon(Icons.lock_open_rounded), label: Text(t('شيل رمز القفل', 'إزالة رمز القفل', 'Remove PIN'))),
          ]),
        ),
        SCard(
          title: tr('النسخة الاحتياطية', 'Backup'),
          icon: Icons.backup_rounded,
          color: SD.nile,
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            OutlinedButton.icon(
              onPressed: () => SharePlus.instance.share(ShareParams(text: s.exportJson(), subject: tr('نسخة أدوات أمير', 'Ameer Tools backup'))),
              icon: const Icon(Icons.upload_rounded),
              label: Text(t('صدّر بياناتك (شاركها أو احفظها)', 'تصدير بياناتك (مشاركة أو حفظ)', 'Export your data (share or save)')),
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(onPressed: () => _import(s), icon: const Icon(Icons.download_rounded), label: Text(t('استرجع من نسخة', 'استعادة من نسخة', 'Restore from backup'))),
            const SizedBox(height: 8),
            TextButton.icon(
              style: TextButton.styleFrom(foregroundColor: SD.red),
              onPressed: () => _reset(s),
              icon: const Icon(Icons.delete_forever_rounded),
              label: Text(t('امسح كل البيانات', 'مسح كل البيانات', 'Erase all data')),
            ),
          ]),
        ),
        GoldFrame(
          child: Column(children: [
            const AmirLogo(size: 96),
            const SizedBox(height: 8),
            Text('${tr('الإصدار', 'Version')} 1.1.0', style: const TextStyle(fontWeight: FontWeight.w700)),
            const SizedBox(height: 10),
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              ClipRRect(borderRadius: BorderRadius.circular(8), child: Image.asset('assets/images/albushra.webp', width: 26)),
              const SizedBox(width: 8),
              Text(tr('من إنتاج البشري للتكنولوجيا', 'Made by Al-Bushra Technology'), style: const TextStyle(fontWeight: FontWeight.w700)),
            ]),
            const Text('Building meaningful digital products', style: TextStyle(fontSize: 12)),
          ]),
        ),
      ],
    );
  }

  void _adj(AppState s, String k, int d) {
    s.setPrayerAdjust(k, ((s.prayerAdjust[k] ?? 0) + d).clamp(-30, 30));
    PrayerNotifications.reschedule(s);
  }

  Future<void> _setPin(AppState s) async {
    final c = TextEditingController();
    final pin = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(t('رمز القفل (4 أرقام)', 'رمز القفل (4 أرقام)', 'PIN (4 digits)')),
        content: TextField(
          controller: c,
          autofocus: true,
          maxLength: 4,
          obscureText: true,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 28, letterSpacing: 12),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(t('خلّيها', 'إلغاء', 'Cancel'))),
          FilledButton(onPressed: () => Navigator.pop(ctx, c.text), child: Text(t('احفظ', 'حفظ', 'Save'))),
        ],
      ),
    );
    if (pin == null || pin.length != 4) return;
    s.pinHash = await hashPin(pin);
    toast(t('اتعمل القفل 🔒 — ما تنسى الرمز', 'تم إنشاء القفل 🔒 — لا تنسَ الرمز', "PIN set 🔒 — don't forget it"));
  }

  Future<void> _import(AppState s) async {
    final c = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(t('ألصق النسخة هنا', 'الصق النسخة هنا', 'Paste the backup here')),
        content: TextField(controller: c, maxLines: 6, decoration: const InputDecoration(hintText: '{ ... }')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(tr('إلغاء', 'Cancel'))),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: Text(t('استرجع', 'استعادة', 'Restore'))),
        ],
      ),
    );
    if (ok != true) return;
    try {
      s.importJson(c.text);
      _name.text = s.name;
      toast(t('اترجعت بياناتك ✓', 'تمت استعادة بياناتك ✓', 'Data restored ✓'));
    } catch (_) {
      toast(t('النص دا ما نسخة صحيحة', 'هذا النص ليس نسخة صحيحة', 'Not a valid backup'));
    }
  }

  Future<void> _reset(AppState s) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(t('متأكد؟', 'هل أنت متأكد؟', 'Are you sure?')),
        content: Text(t('حتمسح كل بياناتك: النقاط، المفضلة، الملاحظات المشفّرة، والإعدادات. ما بترجع.', 'سيتم مسح كل بياناتك: النقاط والمفضلة والملاحظات المشفّرة والإعدادات، ولا يمكن استرجاعها.', 'This erases everything: points, favorites, encrypted notes and settings. It cannot be undone.')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(t('لا، خلّيها', 'لا، إلغاء', 'No, keep it'))),
          FilledButton(style: FilledButton.styleFrom(backgroundColor: SD.red, foregroundColor: Colors.white), onPressed: () => Navigator.pop(ctx, true), child: Text(t('أيوا امسح', 'نعم، امسح', 'Yes, erase'))),
        ],
      ),
    );
    if (ok == true) await s.reset();
  }
}
