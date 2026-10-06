import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/data.dart';
import '../core/i18n.dart';
import '../core/format.dart';
import '../core/pattern.dart';
import '../core/state.dart';
import '../core/theme.dart';
import '../core/widgets.dart';
import '../services/calendars.dart';
import '../services/net.dart';
import '../services/prayer.dart';
import '../tools/registry.dart';
import 'favorites_editor.dart';
import 'shell.dart';
import 'tool_page.dart';
import 'tool_tile.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  Timer? _t;
  Weather? _wx;

  @override
  void initState() {
    super.initState();
    _t = Timer.periodic(const Duration(seconds: 20), (_) => mounted ? setState(() {}) : null);
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load({bool force = false}) async {
    final s = context.read<AppState>();
    final w = await getWeather(s, s.city, force: force);
    await refreshRates(s, force: force);
    if (mounted) setState(() => _wx = w);
  }

  @override
  void dispose() {
    _t?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final now = sudanNow();
    final favs = s.favorites.map(toolById).whereType<ToolDef>().toList();
    final recent = s.recent.map(toolById).whereType<ToolDef>().where((t) => !t.hidden).take(6).toList();
    final proverb = sudaneseProverbs[dateToJdn(now) % sudaneseProverbs.length];

    return RefreshIndicator(
      onRefresh: () => _load(force: true),
      child: ListView(
        padding: EdgeInsets.fromLTRB(16, MediaQuery.of(context).padding.top + 12, 16, 120),
        children: [
          _header(s, now),
          if (s.pointsEnabled) _levelCard(s),
          _hero(s, now),
          _weatherCard(s),
          _rateCard(s),
          GoldFrame(
            title: '${t('مفضلاتك', 'المفضلة', 'Favorites')} ⭐',
            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              if (favs.isEmpty)
                NoteBox(t('ما عندك مفضلات لسه — اضغط ضغطة طويلة على أي أداة أو النجمة جوه الأداة عشان تضيفها هنا.', 'لا توجد مفضلات بعد — اضغط مطولًا على أي أداة أو على النجمة داخلها لإضافتها هنا.', 'No favorites yet — long-press any tool or tap the star inside it to add it here.'), kind: NoteKind.tip)
              else
                ToolGrid(favs),
              const SizedBox(height: 6),
              Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                TextButton.icon(
                  onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const FavoritesEditor())),
                  icon: const Icon(Icons.edit_rounded, size: 18),
                  label: Text(t('رتّب مفضلاتك', 'ترتيب المفضلة', 'Reorder')),
                ),
                TextButton.icon(
                  onPressed: () => Shell.tab.value = 1,
                  icon: const Icon(Icons.grid_view_rounded, size: 18),
                  label: Text(t('كل العِدّة', 'كل الأدوات', 'All tools')),
                ),
              ]),
            ]),
          ),
          _proverbCard(proverb),
          SectionTitle(t('أقسام العِدّة', 'أقسام الأدوات', 'Categories'), icon: Icons.category_rounded),
          _categories(),
          if (recent.isNotEmpty) GoldFrame(title: t('استعملتها قريب', 'المستخدمة مؤخرًا', 'Recently used'), child: ToolGrid(recent)),
          const SizedBox(height: 16),
          Center(
            child: Text(tr('أدوات أمير 🇸🇩 — من البشري للتكنولوجيا', 'Ameer Tools 🇸🇩 — by Al-Bushra Technology'),
                style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: .5))),
          ),
        ],
      ),
    );
  }

  Widget _header(AppState s, DateTime now) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(children: [
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          _roundBtn(Icons.tune_rounded, t('الضبط', 'الإعدادات', 'Settings'), () => Shell.tab.value = 4),
          const Expanded(child: Center(child: AmirLogo(size: 104))),
          _roundBtn(Icons.search_rounded, t('فتّش', 'بحث', 'Search'), () => Shell.tab.value = 1),
        ]),
        const GoldDivider(),
        Text('${sudaneseGreeting(now.hour)} ${s.name.isEmpty ? t('زول', 'صديقي', 'friend') : s.name} 👋',
            textAlign: TextAlign.center, style: TextStyle(fontFamily: 'Lalezar', fontSize: 24, color: scheme.onSurface)),
        Text('${fmtDateAr(now)} • ${hijriText(now, shift: s.hijriShift)}',
            textAlign: TextAlign.center, style: TextStyle(color: scheme.onSurface.withValues(alpha: .75), fontSize: 13)),
        const SizedBox(height: 4),
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Text(flagOf(s.city.country), style: const TextStyle(fontSize: 16)),
          const SizedBox(width: 6),
          Flexible(child: Text('${s.city.name}${s.city.state.isNotEmpty && !s.city.inSudan ? '، ${s.city.state}' : ''}', overflow: TextOverflow.ellipsis, style: const TextStyle(color: SD.gold, fontWeight: FontWeight.w800, fontSize: 13.5))),
        ]),
      ]),
    );
  }

  Widget _roundBtn(IconData icon, String tip, VoidCallback onTap) => Tooltip(
        message: tip,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: SD.brownDeep.withValues(alpha: .55),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: SD.gold, width: 1.4),
            ),
            child: Icon(icon, color: SD.goldLight),
          ),
        ),
      );

  Widget _levelCard(AppState s) => GestureDetector(
        onTap: () => Shell.tab.value = 3,
        child: Container(
          margin: const EdgeInsets.only(bottom: 14),
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [Color(0xFF8A5528), Color(0xFF5A3418)]),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: SD.gold, width: 1.4),
          ),
          child: Column(children: [
            Row(children: [
              const Text('🏅', style: TextStyle(fontSize: 22)),
              const SizedBox(width: 6),
              Text('${tr('المستوى', 'Level')} ${s.level}', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: SD.goldLight)),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                decoration: BoxDecoration(color: SD.gold.withValues(alpha: .18), borderRadius: BorderRadius.circular(20)),
                child: Text(s.levelTitle, style: const TextStyle(color: SD.goldLight, fontWeight: FontWeight.w700, fontSize: 12.5)),
              ),
              const Spacer(),
              Text('🔥 ${s.streak}', style: const TextStyle(fontWeight: FontWeight.w800, color: SD.cream)),
              const SizedBox(width: 10),
              Text('${s.xp} XP', style: const TextStyle(color: SD.goldLight, fontWeight: FontWeight.w800)),
            ]),
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: LinearProgressIndicator(
                value: s.levelProgress,
                minHeight: 10,
                backgroundColor: SD.brownDeep,
                valueColor: const AlwaysStoppedAnimation(SD.gold),
              ),
            ),
          ]),
        ),
      );

  Widget _hero(AppState s, DateTime now) {
    final np = s.nextPrayer();
    final left = np.at.difference(DateTime.now());
    final dark = Theme.of(context).brightness == Brightness.dark;
    final h = now.hour % 12 == 0 ? 12 : now.hour % 12;
    return GestureDetector(
      onTap: () => Shell.tab.value = 2,
      child: Container(
        height: 190,
        margin: const EdgeInsets.only(bottom: 14),
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: dark ? SD.heroDark : SD.heroLight, begin: Alignment.topRight, end: Alignment.bottomLeft),
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: SD.gold, width: 2),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: .35), blurRadius: 24, offset: const Offset(0, 10))],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(28),
          child: Stack(children: [
            // في الإنجليزية (يسار←يمين) نعكس الرسمة حتى لا تغطي الساعة
            Positioned.fill(child: Transform.flip(flipX: isEn, child: CustomPaint(painter: NileScenePainter(hour: now.hour)))),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
                  Text('$h:${two(now.minute)}', style: const TextStyle(color: Colors.white, fontSize: 56, fontWeight: FontWeight.w800, height: 1)),
                  const SizedBox(width: 6),
                  Text(now.hour < 12 ? tr('ص', 'AM') : tr('م', 'PM'), style: const TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.w800)),
                ]),
                const SizedBox(height: 10),
                Row(children: [
                  const Icon(Icons.mosque_rounded, color: Colors.white, size: 20),
                  const SizedBox(width: 6),
                  Text('${prayerNames[np.key]} • ${fmtTimeAr(toSudan(np.at))}',
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 17)),
                ]),
                Text('${t('فاضل ليها', 'متبقٍّ', 'in')} ${fmtDuration(left)}', style: const TextStyle(color: Colors.white70)),
              ]),
            ),
          ]),
        ),
      ),
    );
  }

  Widget _weatherCard(AppState s) {
    final w = _wx;
    final (desc, emo) = w == null ? (t('بنجيب الطقس…', 'جارٍ جلب الطقس…', 'Loading weather…'), '⛅') : weatherDesc(w.code);
    final alert = w?.dustAlert;
    return GestureDetector(
      onTap: () => ToolPage.open(context, 'weather'),
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          gradient: const LinearGradient(colors: SD.sunset, begin: Alignment.topRight, end: Alignment.bottomLeft),
          borderRadius: BorderRadius.circular(26),
          border: Border.all(color: SD.goldLight, width: 1.6),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: .3), blurRadius: 18, offset: const Offset(0, 8))],
        ),
        child: Row(children: [
          Text(emo, style: const TextStyle(fontSize: 46)),
          const SizedBox(width: 14),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(w == null ? '--°' : '${w.temp.round()}°',
                  style: const TextStyle(color: Colors.white, fontSize: 38, fontWeight: FontWeight.w800, height: 1)),
              Text(w == null ? desc : '$desc • ${s.city.name} • ${t('بيحسّ', 'المحسوسة', 'feels')} ${w.feels.round()}°', style: const TextStyle(color: Colors.white)),
              if (alert != null)
                Container(
                  margin: const EdgeInsets.only(top: 6),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                  decoration: BoxDecoration(color: alert.severe ? SD.red : Colors.white24, borderRadius: BorderRadius.circular(20)),
                  child: Text('🌪️ ${alert.severe ? t('هبوب', 'عاصفة ترابية', 'Dust storm') : tr('غبار', 'Dust')}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 12)),
                ),
            ]),
          ),
          const Icon(Icons.chevron_left_rounded, color: Colors.white, size: 30),
        ]),
      ),
    );
  }

  Widget _rateCard(AppState s) {
    final par = s.sdgParallel;
    final off = s.rate('USD', 'SDG', parallel: false);
    return SCard(
      color: SD.green,
      padding: const EdgeInsets.all(14),
      child: InkWell(
        onTap: () => ToolPage.open(context, 'currency'),
        child: Row(children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(color: SD.green.withValues(alpha: .14), borderRadius: BorderRadius.circular(16)),
            child: const Icon(Icons.attach_money_rounded, color: SD.green, size: 30),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(t('الدولار الليلة كم؟', 'سعر الدولار اليوم', 'Dollar today'), style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
              Text(par == null ? '${tr('رسمي', 'Official')} ${fmt(off, 0)} SDG • ${t('دخّل سعر السوق', 'أدخل سعر السوق', 'add market rate')}' : '${tr('موازي', 'Parallel')} ${fmt(par, 0)} • ${tr('رسمي', 'Official')} ${fmt(off, 0)} SDG',
                  style: TextStyle(fontSize: 13, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: .65))),
            ]),
          ),
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Text(fmt(s.rate('SAR', 'SDG'), 0), style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
            Text(tr('ج.س للريال', 'SDG per SAR'), style: const TextStyle(fontSize: 11.5)),
          ]),
        ]),
      ),
    );
  }

  Widget _proverbCard((String, String, String) p) => Container(
        margin: const EdgeInsets.only(top: 6, bottom: 4),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: SD.coffee.withValues(alpha: .9),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: SD.gold, width: 1.4),
        ),
        child: Stack(children: [
          const Positioned(left: 0, bottom: 0, child: CornerOrnament(color: SD.gold)),
          Row(children: [
            const Text('☕', style: TextStyle(fontSize: 34)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(t('مَثَل اليوم', 'مثل اليوم', 'Sudanese proverb of the day'), style: const TextStyle(color: SD.sandDeep, fontWeight: FontWeight.w700, fontSize: 12.5)),
                Text('«${p.$1}»', style: const TextStyle(fontFamily: 'Lalezar', color: Colors.white, fontSize: 21)),
                Text(isEn ? p.$3 : p.$2, style: const TextStyle(color: Colors.white70, fontSize: 13)),
              ]),
            ),
          ]),
        ]),
      );

  Widget _categories() => Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          for (final c in ToolCat.values)
            ActionChip(
              avatar: Icon(c.icon, size: 18, color: SD.green),
              label: Text(c.label, style: const TextStyle(fontWeight: FontWeight.w700)),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              onPressed: () {
                Shell.toolsFilter.value = c.name;
                Shell.tab.value = 1;
              },
            ),
        ],
      );
}

/// رسمة البطاقة الرئيسية: شمس/قمر، أهرامات مروي، نخلة، وأمواج النيل
class NileScenePainter extends CustomPainter {
  final int hour;
  NileScenePainter({required this.hour});

  @override
  void paint(Canvas c, Size s) {
    final night = hour < 5 || hour >= 19;
    final w = Paint()..color = Colors.white.withValues(alpha: .16);
    // الشمس أو القمر
    final orb = Offset(s.width * .16, s.height * .30);
    if (night) {
      c.drawCircle(orb, 22, Paint()..color = Colors.white.withValues(alpha: .55));
      c.drawCircle(orb + const Offset(9, -6), 20, Paint()..color = SD.indigo.withValues(alpha: .9));
      final st = Paint()..color = Colors.white.withValues(alpha: .6);
      for (final p in [const Offset(.3, .15), const Offset(.42, .3), const Offset(.08, .1), const Offset(.25, .45)]) {
        c.drawCircle(Offset(s.width * p.dx, s.height * p.dy), 1.6, st);
      }
    } else {
      c.drawCircle(orb, 24, Paint()..color = SD.gold.withValues(alpha: .85));
      c.drawCircle(orb, 34, Paint()..color = SD.gold.withValues(alpha: .18));
    }
    // أهرامات مروي (حادّة)
    final base = s.height * .78;
    for (final (x, wd, ht) in [(.05, 34.0, 62.0), (.15, 26.0, 48.0), (.24, 40.0, 72.0), (.34, 24.0, 40.0)]) {
      final px = s.width * x;
      c.drawPath(Path()..moveTo(px, base)..lineTo(px + wd / 2, base - ht)..lineTo(px + wd, base)..close(), w);
    }
    // نخلة
    final tx = s.width * .46;
    final trunk = Paint()
      ..color = Colors.white.withValues(alpha: .2)
      ..strokeWidth = 5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    c.drawPath(Path()..moveTo(tx, base)..quadraticBezierTo(tx + 6, base - 40, tx - 2, base - 78), trunk);
    for (var i = 0; i < 6; i++) {
      final a = -math.pi / 2 + (i - 2.5) * .55;
      final top = Offset(tx - 2, base - 78);
      c.drawPath(
          Path()
            ..moveTo(top.dx, top.dy)
            ..quadraticBezierTo(top.dx + math.cos(a) * 22, top.dy + math.sin(a) * 22 - 6, top.dx + math.cos(a) * 36, top.dy + math.sin(a) * 30 + 14),
          trunk..strokeWidth = 3.5);
    }
    // أمواج النيل
    final wave = Paint()
      ..color = Colors.white.withValues(alpha: .22)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;
    for (var r = 0; r < 3; r++) {
      final y = base + 8 + r * 10.0;
      final path = Path()..moveTo(0, y);
      for (double x = 0; x <= s.width; x += 24) {
        path.quadraticBezierTo(x + 6, y - 5, x + 12, y);
        path.quadraticBezierTo(x + 18, y + 5, x + 24, y);
      }
      c.drawPath(path, wave);
    }
  }

  @override
  bool shouldRepaint(NileScenePainter o) => o.hour != hour;
}
