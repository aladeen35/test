import 'dart:convert';
import 'package:cryptography/cryptography.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import '../core/data.dart';
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
        const Center(child: GoldText('الضبط', size: 34)),
        const GoldDivider(),
        SCard(
          title: 'إنت منو؟',
          icon: Icons.person_rounded,
          child: Column(children: [
            TextField(
              controller: _name,
              decoration: const InputDecoration(labelText: 'اسمك', hintText: 'مثلًا: أمير', prefixIcon: Icon(Icons.badge_rounded)),
              onChanged: (v) => s.name = v,
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: s.cityId,
              isExpanded: true,
              decoration: const InputDecoration(labelText: 'مدينتك', prefixIcon: Icon(Icons.location_city_rounded)),
              items: [for (final c in cities) DropdownMenuItem(value: c.id, child: Text('${c.name} — ${c.state}'))],
              onChanged: (v) {
                if (v == null) return;
                s.cityId = v;
                PrayerNotifications.reschedule(s);
              },
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: () => s.gps != null ? s.clearGps() : _gps(s),
              icon: Icon(s.gps != null ? Icons.location_off_rounded : Icons.my_location_rounded),
              label: Text(s.gps != null ? 'ألغِ موقعي الدقيق' : 'استخدم موقعي الدقيق (GPS)'),
            ),
          ]),
        ),
        SCard(
          title: 'الشكل',
          icon: Icons.palette_rounded,
          child: SegmentedButton<ThemeMode>(
            segments: const [
              ButtonSegment(value: ThemeMode.dark, label: Text('تراثي بُني'), icon: Icon(Icons.coffee_rounded)),
              ButtonSegment(value: ThemeMode.light, label: Text('رملي فاتح'), icon: Icon(Icons.wb_sunny_rounded)),
              ButtonSegment(value: ThemeMode.system, label: Text('زي الجهاز'), icon: Icon(Icons.phone_android_rounded)),
            ],
            selected: {s.themeMode},
            onSelectionChanged: (v) => s.themeMode = v.first,
          ),
        ),
        SCard(
          title: 'نظام النقاط',
          icon: Icons.emoji_events_rounded,
          color: SD.gold,
          child: Column(children: [
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              value: s.pointsEnabled,
              onChanged: (v) => s.pointsEnabled = v,
              title: const Text('فعّل النقاط والمستويات', style: TextStyle(fontWeight: FontWeight.w700)),
              subtitle: const Text('اكسب نقاط لما تستعمل الأدوات وتسجّل صلواتك وأذكارك'),
            ),
            if (s.pointsEnabled) InfoRow('مستواك الحالي', '${s.level} — ${s.levelTitle} (${s.xp} نقطة)'),
          ]),
        ),
        SCard(
          title: 'الصلاة',
          icon: Icons.mosque_rounded,
          color: SD.green,
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            DropdownButtonFormField<String>(
              initialValue: s.prayerMethod,
              isExpanded: true,
              decoration: const InputDecoration(labelText: 'طريقة الحساب'),
              items: [for (final m in prayerMethods) DropdownMenuItem(value: m.id, child: Text(m.name, overflow: TextOverflow.ellipsis))],
              onChanged: (v) {
                s.prayerMethod = v!;
                PrayerNotifications.reschedule(s);
              },
            ),
            const SizedBox(height: 10),
            SegmentedButton<bool>(
              segments: const [ButtonSegment(value: false, label: Text('عصر الجمهور')), ButtonSegment(value: true, label: Text('عصر الحنفية'))],
              selected: {s.hanafi},
              onSelectionChanged: (v) {
                s.hanafi = v.first;
                PrayerNotifications.reschedule(s);
              },
            ),
            const SizedBox(height: 12),
            const Text('تعديل بالدقائق عشان يطابق مسجد حيّك:', style: TextStyle(fontWeight: FontWeight.w700)),
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
              const Expanded(child: Text('فرق التاريخ الهجري (حسب رؤية الهلال)')),
              IconButton(onPressed: () => s.hijriShift = (s.hijriShift - 1).clamp(-2, 2), icon: const Icon(Icons.remove_circle_outline)),
              Text('${s.hijriShift}', style: const TextStyle(fontWeight: FontWeight.w800)),
              IconButton(onPressed: () => s.hijriShift = (s.hijriShift + 1).clamp(-2, 2), icon: const Icon(Icons.add_circle_outline)),
            ]),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              value: s.prayerNotify,
              title: const Text('نبّهني وقت الأذان', style: TextStyle(fontWeight: FontWeight.w700)),
              subtitle: Text(PrayerNotifications.supported ? 'بيشتغل حتى لو التطبيق مقفول' : 'متاح في تطبيق الموبايل بس'),
              onChanged: (v) async {
                if (v && !await PrayerNotifications.requestPermission()) {
                  toast('ما اتدّى إذن التنبيهات');
                  return;
                }
                s.prayerNotify = v;
                await PrayerNotifications.reschedule(s);
                if (v) toast('تمام — حننبّهك وقت كل صلاة 🕌');
              },
            ),
          ]),
        ),
        SCard(
          title: 'القفل والخصوصية',
          icon: Icons.lock_rounded,
          color: SD.red,
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            const Text('كل بياناتك محفوظة في جهازك بس، ما بنرسلها لأي زول.'),
            const SizedBox(height: 10),
            if (s.pinHash == null)
              FilledButton.icon(onPressed: () => _setPin(s), icon: const Icon(Icons.pin_rounded), label: const Text('اعمل رمز قفل للتطبيق'))
            else
              OutlinedButton.icon(onPressed: () => s.pinHash = null, icon: const Icon(Icons.lock_open_rounded), label: const Text('شيل رمز القفل')),
          ]),
        ),
        SCard(
          title: 'النسخة الاحتياطية',
          icon: Icons.backup_rounded,
          color: SD.nile,
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            OutlinedButton.icon(
              onPressed: () => SharePlus.instance.share(ShareParams(text: s.exportJson(), subject: 'نسخة أدوات أمير')),
              icon: const Icon(Icons.upload_rounded),
              label: const Text('صدّر بياناتك (شاركها أو احفظها)'),
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(onPressed: () => _import(s), icon: const Icon(Icons.download_rounded), label: const Text('استرجع من نسخة')),
            const SizedBox(height: 8),
            TextButton.icon(
              style: TextButton.styleFrom(foregroundColor: SD.red),
              onPressed: () => _reset(s),
              icon: const Icon(Icons.delete_forever_rounded),
              label: const Text('امسح كل البيانات'),
            ),
          ]),
        ),
        GoldFrame(
          child: Column(children: [
            const AmirLogo(size: 96),
            const SizedBox(height: 8),
            const Text('الإصدار 1.0.0', style: TextStyle(fontWeight: FontWeight.w700)),
            const SizedBox(height: 10),
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              ClipRRect(borderRadius: BorderRadius.circular(8), child: Image.asset('assets/images/icon-512.png', width: 26)),
              const SizedBox(width: 8),
              const Text('من إنتاج البشري للتكنولوجيا', style: TextStyle(fontWeight: FontWeight.w700)),
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

  Future<void> _gps(AppState s) async {
    try {
      var p = await Geolocator.checkPermission();
      if (p == LocationPermission.denied) p = await Geolocator.requestPermission();
      if (p == LocationPermission.denied || p == LocationPermission.deniedForever) {
        toast('ما اتدّى إذن الموقع');
        return;
      }
      toast('بنحدّد موقعك…');
      final pos = await Geolocator.getCurrentPosition();
      s.setGps(pos.latitude, pos.longitude);
      PrayerNotifications.reschedule(s);
      toast('تمام — قريب من ${cityById(s.cityId).name}');
    } catch (_) {
      toast('ما قدرنا نحدّد الموقع — اتأكد إنو الـ GPS شغّال');
    }
  }

  Future<void> _setPin(AppState s) async {
    final c = TextEditingController();
    final pin = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('رمز القفل (4 أرقام)'),
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
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('خلّيها')),
          FilledButton(onPressed: () => Navigator.pop(ctx, c.text), child: const Text('احفظ')),
        ],
      ),
    );
    if (pin == null || pin.length != 4) return;
    s.pinHash = await hashPin(pin);
    toast('اتعمل القفل 🔒 — ما تنسى الرمز');
  }

  Future<void> _import(AppState s) async {
    final c = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('ألصق النسخة هنا'),
        content: TextField(controller: c, maxLines: 6, decoration: const InputDecoration(hintText: '{ ... }')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('استرجع')),
        ],
      ),
    );
    if (ok != true) return;
    try {
      s.importJson(c.text);
      _name.text = s.name;
      toast('اترجعت بياناتك ✓');
    } catch (_) {
      toast('النص دا ما نسخة صحيحة');
    }
  }

  Future<void> _reset(AppState s) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('متأكد؟'),
        content: const Text('حتمسح كل بياناتك: النقاط، المفضلة، الملاحظات المشفّرة، والإعدادات. ما بترجع.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('لا، خلّيها')),
          FilledButton(style: FilledButton.styleFrom(backgroundColor: SD.red, foregroundColor: Colors.white), onPressed: () => Navigator.pop(ctx, true), child: const Text('أيوا امسح')),
        ],
      ),
    );
    if (ok == true) await s.reset();
  }
}
