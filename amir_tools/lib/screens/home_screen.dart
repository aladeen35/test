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
import 'bundles.dart';
import 'category_screen.dart';
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
    final recent = s.recent.map(toolById).whereType<ToolDef>().where((t) => !t.hidden).take(10).toList();
    final fresh = newTools.take(14).toList();
    final proverb = sudaneseProverbs[dateToJdn(now) % sudaneseProverbs.length];

    return RefreshIndicator(
      onRefresh: () => _load(force: true),
      child: ListView(
        padding: EdgeInsets.fromLTRB(16, MediaQuery.of(context).padding.top + 10, 16, 120),
        children: [
          _header(s, now),
          _todayStrip(s, now),
          if (s.pointsEnabled) _levelBar(s),
          GoldFrame(
            title: '${t('مفضلاتك', 'المفضلة', 'Favorites')} ⭐',
            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              if (favs.isEmpty)
                NoteBox(t('ما عندك مفضلات لسه — اضغط ضغطة طويلة على أي أداة أو النجمة جوه الأداة عشان تضيفها هنا.', 'لا توجد مفضلات بعد — اضغط مطولًا على أي أداة أو على النجمة داخلها لإضافتها هنا.', 'No favorites yet — long-press any tool or tap the star inside it to add it here.'), kind: NoteKind.tip)
              else
                ToolGrid(favs),
              const SizedBox(height: 6),
              Wrap(alignment: WrapAlignment.center, children: [
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
          if (recent.isNotEmpty) ...[
            SectionTitle(t('استعملتها قريب', 'المستخدمة مؤخرًا', 'Recently used'), icon: Icons.history_rounded),
            ToolStrip(recent),
          ],
          SectionTitle(
            t('حزم العِدّة', 'حزم الأدوات', 'Tool bundles'),
            icon: Icons.inventory_2_rounded,
            trailing: TextButton(onPressed: () => Shell.tab.value = 1, child: Text(t('الكل', 'الكل', 'All'))),
          ),
          _bundles(),
          if (fresh.isNotEmpty) ...[
            SectionTitle(t('جديد في العِدّة', 'الجديد', "What's new"), icon: Icons.fiber_new_rounded),
            ToolStrip(fresh),
            const SizedBox(height: 12),
          ],
          _proverbCard(proverb),
          const SizedBox(height: 16),
          Center(
            child: Text(tr('أدوات أمير 🇸🇩 — من البشري للتكنولوجيا', 'Ameer Tools 🇸🇩 — by Al-Bushra Technology'),
                textAlign: TextAlign.center, style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: .5))),
          ),
        ],
      ),
    );
  }

  /* ── الرأس المختصر: الشعار والتحية والمكان ── */
  Widget _header(AppState s, DateTime now) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(children: [
        Row(children: [
          const AmirLogo(size: 58, withText: false),
          const SizedBox(width: 10),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('${sudaneseGreeting(now.hour)} ${s.name.isEmpty ? t('زول', 'صديقي', 'friend') : s.name} 👋',
                  maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontFamily: 'Lalezar', fontSize: 21, height: 1.25, color: scheme.onSurface)),
              Row(children: [
                Text(flagOf(s.city.country), style: const TextStyle(fontSize: 14)),
                const SizedBox(width: 5),
                Flexible(
                  child: Text('${s.city.name}${s.city.state.isNotEmpty && !s.city.inSudan ? '، ${s.city.state}' : ''}',
                      maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: SD.gold, fontWeight: FontWeight.w800, fontSize: 13)),
                ),
              ]),
            ]),
          ),
          const SizedBox(width: 6),
          _roundBtn(Icons.search_rounded, t('فتّش', 'بحث', 'Search'), () => Shell.tab.value = 1),
          const SizedBox(width: 6),
          _roundBtn(Icons.tune_rounded, t('الضبط', 'الإعدادات', 'Settings'), () => Shell.tab.value = 4),
        ]),
        const SizedBox(height: 6),
        Text('${fmtDateAr(now)} • ${hijriText(now, shift: s.hijriShift)}',
            textAlign: TextAlign.center, maxLines: 2, style: TextStyle(color: scheme.onSurface.withValues(alpha: .75), fontSize: 12.5)),
      ]),
    );
  }

  Widget _roundBtn(IconData icon, String tip, VoidCallback onTap) => Tooltip(
        message: tip,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: SD.brownDeep.withValues(alpha: .55),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: SD.gold, width: 1.3),
            ),
            child: Icon(icon, color: SD.goldLight, size: 22),
          ),
        ),
      );

  /* ── شريط «اليوم»: الساعة والصلاة، الطقس، الدولار ── */
  Widget _todayStrip(AppState s, DateTime now) => LayoutBuilder(builder: (context, c) {
        final w = (c.maxWidth * .64).clamp(196.0, 240.0);
        final cards = [_clockCard(s, now), _weatherCard(s), _rateCard(s)];
        return SizedBox(
          height: 118,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            clipBehavior: Clip.none,
            itemCount: cards.length,
            separatorBuilder: (_, _) => const SizedBox(width: 10),
            itemBuilder: (_, i) => SizedBox(width: w, child: cards[i]),
          ),
        );
      });

  Widget _stripCard({required List<Color> colors, required VoidCallback onTap, required Widget child, Widget? background}) => GestureDetector(
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: colors, begin: Alignment.topRight, end: Alignment.bottomLeft),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: SD.gold, width: 1.5),
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: .25), blurRadius: 10, offset: const Offset(0, 5))],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(21),
            child: Stack(children: [
              ?background,
              Padding(padding: const EdgeInsets.fromLTRB(14, 10, 14, 10), child: child),
            ]),
          ),
        ),
      );

  static const _white = TextStyle(color: Colors.white);

  Widget _clockCard(AppState s, DateTime now) {
    final np = s.nextPrayer();
    final left = np.at.difference(DateTime.now());
    final dark = Theme.of(context).brightness == Brightness.dark;
    final h = now.hour % 12 == 0 ? 12 : now.hour % 12;
    return _stripCard(
      colors: dark ? SD.heroDark : SD.heroLight,
      onTap: () => Shell.tab.value = 2,
      // في الإنجليزية (يسار←يمين) نعكس الرسمة حتى لا تغطي الساعة
      background: Positioned.fill(child: Opacity(opacity: .8, child: Transform.flip(flipX: isEn, child: CustomPaint(painter: NileScenePainter(hour: now.hour))))),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Text('$h:${two(now.minute)}', style: const TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.w800, height: 1)),
            const SizedBox(width: 4),
            Text(now.hour < 12 ? tr('ص', 'AM') : tr('م', 'PM'), style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w800)),
          ]),
        ),
        const SizedBox(height: 6),
        Row(children: [
          const Icon(Icons.mosque_rounded, color: Colors.white, size: 16),
          const SizedBox(width: 5),
          Flexible(
            child: Text('${prayerNames[np.key]} • ${fmtTimeAr(toSudan(np.at))}',
                maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 14)),
          ),
        ]),
        Text('${t('فاضل ليها', 'متبقٍّ', 'in')} ${fmtDuration(left)}', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white70, fontSize: 12.5)),
      ]),
    );
  }

  Widget _weatherCard(AppState s) {
    final w = _wx;
    final (desc, emo) = w == null ? (t('بنجيب الطقس…', 'جارٍ جلب الطقس…', 'Loading weather…'), '⛅') : weatherDesc(w.code);
    final alert = w?.dustAlert;
    return _stripCard(
      colors: SD.sunset,
      onTap: () => ToolPage.open(context, 'weather'),
      child: Row(children: [
        Text(emo, style: const TextStyle(fontSize: 34)),
        const SizedBox(width: 10),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [
            Row(children: [
              Text(w == null ? '--°' : '${w.temp.round()}°', style: const TextStyle(color: Colors.white, fontSize: 30, fontWeight: FontWeight.w800, height: 1.05)),
              const SizedBox(width: 6),
              if (alert != null)
                Flexible(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                    decoration: BoxDecoration(color: alert.severe ? SD.red : Colors.white24, borderRadius: BorderRadius.circular(14)),
                    child: Text('🌪️ ${alert.severe ? t('هبوب', 'عاصفة ترابية', 'Dust storm') : tr('غبار', 'Dust')}',
                        maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 11)),
                  ),
                ),
            ]),
            Text(desc, maxLines: 1, overflow: TextOverflow.ellipsis, style: _white.copyWith(fontWeight: FontWeight.w700, fontSize: 13)),
            Text(w == null ? s.city.name : '${s.city.name} • ${t('بيحسّ', 'المحسوسة', 'feels')} ${w.feels.round()}°',
                maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white70, fontSize: 12)),
          ]),
        ),
      ]),
    );
  }

  Widget _rateCard(AppState s) {
    final par = s.sdgParallel;
    final off = s.rate('USD', 'SDG', parallel: false);
    return _stripCard(
      colors: const [Color(0xFF0E7A3A), Color(0xFF064722)],
      onTap: () => ToolPage.open(context, 'currency'),
      child: Row(children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(color: Colors.white.withValues(alpha: .15), shape: BoxShape.circle, border: Border.all(color: SD.goldLight)),
          child: const Icon(Icons.attach_money_rounded, color: Colors.white, size: 24),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [
            Text(t('الدولار الليلة كم؟', 'سعر الدولار اليوم', 'Dollar today'),
                maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: SD.goldLight, fontWeight: FontWeight.w800, fontSize: 13)),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: AlignmentDirectional.centerStart,
              child: Text('${fmt(par ?? off, 0)} SDG', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 22, height: 1.2)),
            ),
            Text(par == null ? '${tr('رسمي', 'Official')} • ${t('دخّل سعر السوق', 'أدخل سعر السوق', 'add market rate')}' : '${tr('موازي', 'Parallel')} • ${tr('رسمي', 'Official')} ${fmt(off, 0)}',
                maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white70, fontSize: 11.5)),
            Text('${tr('الريال', 'SAR')} ${fmt(s.rate('SAR', 'SDG'), 0)} ${tr('ج.س', 'SDG')}',
                maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white70, fontSize: 11.5)),
          ]),
        ),
      ]),
    );
  }

  /* ── شريط المستوى المختصر ── */
  Widget _levelBar(AppState s) => Padding(
        padding: const EdgeInsets.only(top: 12),
        child: InkWell(
          onTap: () => Shell.tab.value = 3,
          borderRadius: BorderRadius.circular(18),
          child: Ink(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [Color(0xFF8A5528), Color(0xFF5A3418)]),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: SD.gold, width: 1.2),
            ),
            child: Column(children: [
              Row(children: [
                const Text('🏅', style: TextStyle(fontSize: 17)),
                const SizedBox(width: 6),
                Expanded(
                  child: Text('${tr('المستوى', 'Level')} ${s.level} • ${s.levelTitle}',
                      maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13.5, color: SD.goldLight)),
                ),
                const SizedBox(width: 6),
                Text('🔥 ${s.streak}', style: const TextStyle(fontWeight: FontWeight.w800, color: SD.cream, fontSize: 13)),
                const SizedBox(width: 8),
                Text('${s.xp} XP', style: const TextStyle(color: SD.goldLight, fontWeight: FontWeight.w800, fontSize: 13)),
              ]),
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  value: s.levelProgress,
                  minHeight: 6,
                  backgroundColor: SD.brownDeep,
                  valueColor: const AlwaysStoppedAnimation(SD.gold),
                ),
              ),
            ]),
          ),
        ),
      );

  /* ── شبكة الحزم ── */
  Widget _bundles() => Padding(
        padding: const EdgeInsets.only(bottom: 4),
        child: GridView.builder(
          padding: EdgeInsets.zero,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: ToolBundle.values.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, mainAxisSpacing: 10, crossAxisSpacing: 10, mainAxisExtent: 150),
          itemBuilder: (_, i) => BundleCard(ToolBundle.values[i]),
        ),
      );

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
}

/// بطاقة حزمة: تدرّج لوني، إطار ذهبي، أيقونة كبيرة، الاسم، العدد، ومعاينة لأربع أدوات
class BundleCard extends StatelessWidget {
  final ToolBundle bundle;
  const BundleCard(this.bundle, {super.key});

  @override
  Widget build(BuildContext context) {
    final tools = bundle.tools;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: () => CategoryScreen.open(context, bundle),
        child: Ink(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: bundle.colors, begin: AlignmentDirectional.topStart, end: AlignmentDirectional.bottomEnd),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: SD.gold, width: 1.6),
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: .3), blurRadius: 10, offset: const Offset(0, 5))],
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(color: Colors.white.withValues(alpha: .15), shape: BoxShape.circle, border: Border.all(color: SD.goldLight, width: 1.2)),
                child: Icon(bundle.icon, color: Colors.white, size: 24),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(bundle.label,
                    maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontFamily: 'Lalezar', fontSize: 17, height: 1.15, color: SD.goldLight)),
              ),
            ]),
            const Spacer(),
            Text(toolCountText(tools.length), maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 13)),
            const SizedBox(height: 6),
            Row(children: [
              for (final x in tools.take(4))
                Padding(
                  padding: const EdgeInsetsDirectional.only(end: 4),
                  child: Container(
                    width: 22,
                    height: 22,
                    decoration: BoxDecoration(
                      color: Color.lerp(x.color, Colors.black, .15),
                      shape: BoxShape.circle,
                      border: Border.all(color: SD.goldLight.withValues(alpha: .8), width: .8),
                    ),
                    child: Icon(x.icon, color: Colors.white, size: 12),
                  ),
                ),
              if (tools.length > 4)
                Flexible(child: Text('+${tools.length - 4}', maxLines: 1, overflow: TextOverflow.clip, style: const TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.w800))),
            ]),
          ]),
        ),
      ),
    );
  }
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
