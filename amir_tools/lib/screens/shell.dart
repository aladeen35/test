import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/pattern.dart';
import '../core/state.dart';
import '../core/theme.dart';
import 'home_screen.dart';
import 'tools_screen.dart';
import 'prayer_screen.dart';
import 'points_screen.dart';
import 'settings_screen.dart';

/// الهيكل الرئيسي مع الشريط السفلي العائم
class Shell extends StatefulWidget {
  const Shell({super.key});

  /// للتنقل بين التبويبات من أي مكان (مثلًا: «الكل» في البيت)
  static final tab = ValueNotifier<int>(0);

  /// تصنيف مختار مسبقًا عند فتح تبويب الأدوات
  static final toolsFilter = ValueNotifier<String?>(null);

  @override
  State<Shell> createState() => _ShellState();
}

class _ShellState extends State<Shell> {
  static const _items = [
    (Icons.home_rounded, 'البيت'),
    (Icons.grid_view_rounded, 'العِدّة'),
    (Icons.mosque_rounded, 'الصلاة'),
    (Icons.emoji_events_rounded, 'نقاطي'),
    (Icons.tune_rounded, 'الضبط'),
  ];

  @override
  Widget build(BuildContext context) {
    final points = context.select<AppState, bool>((s) => s.pointsEnabled);
    return ValueListenableBuilder<int>(
      valueListenable: Shell.tab,
      builder: (context, i, _) {
        final visible = [for (var k = 0; k < _items.length; k++) if (k != 3 || points) k];
        final idx = visible.contains(i) ? i : 0;
        return PopScope(
          canPop: idx == 0,
          onPopInvokedWithResult: (didPop, _) {
            if (!didPop) Shell.tab.value = 0;
          },
          child: SudanBackground(
            child: Scaffold(
              extendBody: true,
              body: IndexedStack(index: idx, children: const [
                HomeScreen(),
                ToolsScreen(),
                PrayerScreen(),
                PointsScreen(),
                SettingsScreen(),
              ]),
              bottomNavigationBar: _NavBar(
                items: [for (final k in visible) _items[k]],
                selected: visible.indexOf(idx),
                onTap: (j) => Shell.tab.value = visible[j],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _NavBar extends StatelessWidget {
  final List<(IconData, String)> items;
  final int selected;
  final ValueChanged<int> onTap;
  const _NavBar({required this.items, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final scheme = Theme.of(context).colorScheme;
    return SafeArea(
      minimum: const EdgeInsets.fromLTRB(14, 0, 14, 12),
      child: Container(
        height: 72,
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: dark ? const [Color(0xFF6B4022), Color(0xFF3A1F0C)] : const [Color(0xFFFFFAF0), Color(0xFFF3DDB3)], begin: Alignment.topCenter, end: Alignment.bottomCenter),
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: SD.gold, width: 1.6),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: .12), blurRadius: 24, offset: const Offset(0, 8))],
        ),
        child: Column(children: [
          // خيط بألوان العلم أعلى الشريط
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
            child: Row(children: [
              for (final c in [SD.red, Colors.white, SD.black, SD.green]) Expanded(child: Container(height: 3, color: c.withValues(alpha: .8))),
            ]),
          ),
          Expanded(
            child: Row(children: [
              for (var i = 0; i < items.length; i++)
                Expanded(
                  child: InkWell(
                    borderRadius: BorderRadius.circular(22),
                    onTap: () => onTap(i),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 220),
                      margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
                      decoration: BoxDecoration(
                        color: i == selected ? SD.gold.withValues(alpha: dark ? .22 : .3) : Colors.transparent,
                        border: i == selected ? Border.all(color: SD.goldLight.withValues(alpha: .6)) : null,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                        Icon(items[i].$1, color: i == selected ? (dark ? SD.goldLight : SD.brown) : scheme.onSurface.withValues(alpha: .55), size: 26),
                        Text(items[i].$2,
                            style: TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w700,
                              color: i == selected ? (dark ? SD.goldLight : SD.brown) : scheme.onSurface.withValues(alpha: .6),
                            )),
                      ]),
                    ),
                  ),
                ),
            ]),
          ),
        ]),
      ),
    );
  }
}
