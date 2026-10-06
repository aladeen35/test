import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../core/pattern.dart';
import '../core/state.dart';
import '../core/theme.dart';
import 'settings_screen.dart';
import '../core/i18n.dart';

/// شاشة القفل برمز من 4 أرقام
class PinLock extends StatefulWidget {
  final VoidCallback onUnlock;
  const PinLock({super.key, required this.onUnlock});
  @override
  State<PinLock> createState() => _PinLockState();
}

class _PinLockState extends State<PinLock> {
  String _pin = '';
  bool _wrong = false;

  Future<void> _press(String d) async {
    if (_pin.length >= 4) return;
    HapticFeedback.selectionClick();
    setState(() {
      _pin += d;
      _wrong = false;
    });
    if (_pin.length == 4) {
      final want = context.read<AppState>().pinHash;
      final ok = await hashPin(_pin) == want;
      if (ok) {
        widget.onUnlock();
      } else {
        HapticFeedback.heavyImpact();
        setState(() {
          _pin = '';
          _wrong = true;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) => SudanBackground(
        child: Scaffold(
          body: SafeArea(
            child: Column(children: [
              const SizedBox(height: 30),
              const AmirLogo(size: 110),
              const SizedBox(height: 20),
              Text(_wrong ? t('الرمز غلط، جرّب تاني', 'الرمز خاطئ، حاول مرة أخرى', 'Wrong PIN, try again') : t('أدخل رمز القفل', 'أدخل رمز القفل', 'Enter your PIN'),
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: _wrong ? SD.red : null)),
              const SizedBox(height: 14),
              Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                for (var i = 0; i < 4; i++)
                  Container(
                    margin: const EdgeInsets.all(8),
                    width: 18,
                    height: 18,
                    decoration: BoxDecoration(shape: BoxShape.circle, color: i < _pin.length ? SD.gold : Colors.transparent, border: Border.all(color: SD.gold, width: 2)),
                  ),
              ]),
              const Spacer(),
              Directionality(
                textDirection: TextDirection.ltr,
                child: Wrap(alignment: WrapAlignment.center, spacing: 18, runSpacing: 14, children: [
                  for (final d in ['1', '2', '3', '4', '5', '6', '7', '8', '9', '', '0', '⌫'])
                    SizedBox(
                      width: 76,
                      height: 76,
                      child: d.isEmpty
                          ? null
                          : OutlinedButton(
                              style: OutlinedButton.styleFrom(shape: const CircleBorder(), padding: EdgeInsets.zero),
                              onPressed: () => d == '⌫' ? setState(() => _pin = _pin.isEmpty ? '' : _pin.substring(0, _pin.length - 1)) : _press(d),
                              child: Text(d, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w800)),
                            ),
                    ),
                ]),
              ),
              const SizedBox(height: 40),
            ]),
          ),
        ),
      );
}
