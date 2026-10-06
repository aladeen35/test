import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/data.dart';
import '../core/i18n.dart';
import 'place_picker.dart';
import '../core/pattern.dart';
import '../core/state.dart';
import '../core/theme.dart';
import '../core/widgets.dart';

/// شاشة الترحيب أول مرة: الاسم، المدينة، النقاط
class Onboarding extends StatefulWidget {
  const Onboarding({super.key});
  @override
  State<Onboarding> createState() => _OnboardingState();
}

class _OnboardingState extends State<Onboarding> {
  final _name = TextEditingController();
  String _city = 'khartoum';
  bool _points = true;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SudanBackground(
      child: Scaffold(
        body: SafeArea(
          child: ListView(padding: const EdgeInsets.fromLTRB(20, 30, 20, 30), children: [
            const Center(child: AmirLogo(size: 150)),
            const SizedBox(height: 12),
            Center(
              child: SegmentedButton<Lang>(
                segments: [for (final l in Lang.values) ButtonSegment(value: l, label: Text('${l.flag} ${l.label}'))],
                selected: {context.watch<AppState>().lang},
                showSelectedIcon: false,
                onSelectionChanged: (v) => context.read<AppState>().lang = v.first,
              ),
            ),
            const GoldDivider(),
            Center(child: GoldText(t('حبابك عشرة! 🇸🇩', 'أهلًا وسهلًا! 🇸🇩', 'Welcome! 🇸🇩'), size: 30)),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(
                t('أكتر من 55 أداة في مكان واحد: الدولار والتحويلات، الذهب والزكاة، الطاقة الشمسية، مواقيت الصلاة في أي حتة في العالم، متتبع العادات والمصاريف والصندوق، حاسبة العمر المفصّلة، والكشاف لقطوعات الكهرباء… وغيرها كتير.',
                    'أكثر من 55 أداة في مكان واحد: الدولار والتحويلات، الذهب والزكاة، الطاقة الشمسية، مواقيت الصلاة في أي مكان في العالم، متتبع العادات والمصاريف والصندوق، حاسبة العمر المفصّلة، والكشاف لانقطاع الكهرباء… وغيرها.',
                    'More than 55 tools in one place: dollar rates and remittances, gold and zakat, solar power, prayer times anywhere in the world, habits, expenses and savings circles, a detailed age calculator, a flashlight for power cuts… and much more.'),
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 15, height: 1.6),
              ),
            ),
            GoldFrame(
              child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                TextField(
                  controller: _name,
                  decoration: InputDecoration(labelText: t('اسمك شنو؟', 'ما اسمك؟', "What's your name?"), hintText: t('مثلًا: أمير', 'مثلًا: أمير', 'e.g. Amir'), prefixIcon: const Icon(Icons.person_rounded)),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: _city.isEmpty ? null : _city,
                  isExpanded: true,
                  decoration: InputDecoration(labelText: t('ساكن وين؟', 'أين تسكن؟', 'Where do you live?'), prefixIcon: const Icon(Icons.location_on_rounded)),
                  items: [for (final c in cities) DropdownMenuItem(value: c.id, child: Text('${c.name} — ${c.state}'))],
                  onChanged: (v) => setState(() => _city = v!),
                ),
                TextButton.icon(
                  onPressed: () async {
                    await showPlacePicker(context);
                    if (!context.mounted) return;
                    final s = context.read<AppState>();
                    setState(() => _city = s.usingPlace ? '' : s.cityId);
                  },
                  icon: const Icon(Icons.travel_explore_rounded),
                  label: Text(_city.isEmpty ? '${flagOf(context.read<AppState>().city.country)} ${context.read<AppState>().city.name}' : t('برّه السودان؟ اختار أي مدينة في العالم', 'خارج السودان؟ اختر أي مدينة في العالم', 'Outside Sudan? Pick any city')),
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  value: _points,
                  onChanged: (v) => setState(() => _points = v),
                  title: Text(t('فعّل نظام النقاط 🏅', 'تفعيل نظام النقاط 🏅', 'Enable points 🏅'), style: const TextStyle(fontWeight: FontWeight.w700)),
                  subtitle: Text(t('مستويات وإنجازات وإنت بتستعمل الأدوات', 'مستويات وإنجازات أثناء استخدام الأدوات', 'Levels and achievements as you use the tools')),
                ),
              ]),
            ),
            FilledButton.icon(
              onPressed: () {
                final s = context.read<AppState>();
                s.name = _name.text;
                if (_city.isNotEmpty) s.cityId = _city;
                s.pointsEnabled = _points;
                s.onboarded = true;
                s.award(20, t('مرحب بيك في أدوات أمير', 'مرحبًا بك في أدوات أمير', 'Welcome to Amir Tools'));
              },
              icon: const Icon(Icons.arrow_back_rounded),
              label: Text(t('يلا نبدأ', 'لنبدأ', "Let's start")),
            ),
            const SizedBox(height: 16),
            NoteBox(t('كل بياناتك بتتحفظ في تلفونك بس.', 'تُحفظ كل بياناتك على هاتفك فقط.', 'All your data stays on your phone.'), kind: NoteKind.info),
            Center(child: Text(tr('من إنتاج البشري للتكنولوجيا', 'Made by Al-Bushra Technology'), style: const TextStyle(fontSize: 12, color: SD.gold))),
          ]),
        ),
      ),
    );
  }
}
