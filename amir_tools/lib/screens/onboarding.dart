import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/data.dart';
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
            const GoldDivider(),
            const Center(child: GoldText('حبابك عشرة! 🇸🇩', size: 30)),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Text(
                'أكتر من 40 أداة سودانية في مكان واحد: الدولار والتحويلات، الذهب والزكاة، الطاقة الشمسية، مواقيت الصلاة لكل الولايات، حاسبة العمر المفصّلة، والكشاف لقطوعات الكهرباء… وغيرها كتير.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 15, height: 1.6),
              ),
            ),
            GoldFrame(
              child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                TextField(
                  controller: _name,
                  decoration: const InputDecoration(labelText: 'اسمك شنو؟', hintText: 'مثلًا: أمير', prefixIcon: Icon(Icons.person_rounded)),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: _city,
                  isExpanded: true,
                  decoration: const InputDecoration(labelText: 'ساكن وين؟', prefixIcon: Icon(Icons.location_on_rounded)),
                  items: [for (final c in cities) DropdownMenuItem(value: c.id, child: Text('${c.name} — ${c.state}'))],
                  onChanged: (v) => setState(() => _city = v!),
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  value: _points,
                  onChanged: (v) => setState(() => _points = v),
                  title: const Text('فعّل نظام النقاط 🏅', style: TextStyle(fontWeight: FontWeight.w700)),
                  subtitle: const Text('مستويات وإنجازات وإنت بتستعمل الأدوات'),
                ),
              ]),
            ),
            FilledButton.icon(
              onPressed: () {
                final s = context.read<AppState>();
                s.name = _name.text;
                s.cityId = _city;
                s.pointsEnabled = _points;
                s.onboarded = true;
                s.award(20, 'مرحب بيك في أدوات أمير');
              },
              icon: const Icon(Icons.arrow_back_rounded),
              label: const Text('يلا نبدأ'),
            ),
            const SizedBox(height: 16),
            const NoteBox('كل بياناتك بتتحفظ في تلفونك بس.', kind: NoteKind.info),
            const Center(child: Text('من إنتاج البشري للتكنولوجيا', style: TextStyle(fontSize: 12, color: SD.gold))),
          ]),
        ),
      ),
    );
  }
}
