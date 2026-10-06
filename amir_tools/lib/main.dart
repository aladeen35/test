import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'core/state.dart';
import 'core/theme.dart';
import 'screens/shell.dart';
import 'screens/onboarding.dart';
import 'screens/pin_lock.dart';
import 'services/net.dart';
import 'services/notifications.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final state = await AppState.load();
  runApp(ChangeNotifierProvider.value(value: state, child: const AmirApp()));
  // مهام خلفية لا تؤخّر فتح التطبيق
  refreshRates(state);
  PrayerNotifications.reschedule(state);
}

class AmirApp extends StatelessWidget {
  const AmirApp({super.key});

  @override
  Widget build(BuildContext context) {
    final mode = context.select<AppState, ThemeMode>((s) => s.themeMode);
    return MaterialApp(
      title: 'أدوات أمير',
      debugShowCheckedModeBanner: false,
      scaffoldMessengerKey: messengerKey,
      locale: const Locale('ar'),
      supportedLocales: const [Locale('ar'), Locale('en')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      theme: buildTheme(Brightness.light),
      darkTheme: buildTheme(Brightness.dark),
      themeMode: mode,
      builder: (context, child) {
        final dark = Theme.of(context).brightness == Brightness.dark;
        SystemChrome.setSystemUIOverlayStyle(dark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark);
        return child!;
      },
      home: const RootGate(),
    );
  }
}

/// البوابة: الترحيب أول مرة ← قفل الرمز (إن وُجد) ← التطبيق
class RootGate extends StatefulWidget {
  const RootGate({super.key});
  @override
  State<RootGate> createState() => _RootGateState();
}

class _RootGateState extends State<RootGate> {
  bool _unlocked = false;

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    if (!s.onboarded) return const Onboarding();
    if (s.pinHash != null && !_unlocked) return PinLock(onUnlock: () => setState(() => _unlocked = true));
    return const Shell();
  }
}
