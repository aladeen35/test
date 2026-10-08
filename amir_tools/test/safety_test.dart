import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest_10y.dart' as tzdata;
import 'package:amir_tools/core/i18n.dart';
import 'package:amir_tools/core/state.dart';
import 'package:amir_tools/core/theme.dart';
import 'package:amir_tools/tools/registry.dart';
import 'package:amir_tools/tools/safety/link_logic.dart';

const _ids = ['account_security', 'fraud_alerts', 'news_check', 'link_check'];

void main() {
  setUpAll(tzdata.initializeTimeZones);

  group('فاحص الروابط — المنطق', () {
    test('Punycode', () {
      expect(punycodeDecode('bcher-kva'), 'bücher');
      expect(punycodeDecode('mgbh0fb'), 'مثال');
      expect(punycodeDecode('80ak6aa92e'), 'аррӏе');
      expect(decodeHost('xn--80ak6aa92e.com'), 'аррӏе.com');
      expect(punycodeDecode('!!'), isNull);
    });

    test('استخراج الرابط من رسالة', () {
      expect(extractUrl('شوف ده https://wa.me/249912345678 بسرعة.'), 'https://wa.me/249912345678');
      expect(extractUrl('(www.example.com/x),'), 'www.example.com/x');
      expect(extractUrl('visit example.org now'), 'example.org');
      expect(extractUrl('   '), '');
    });

    test('النطاق المسجّل', () {
      expect(registrableDomain('www.google.com'), 'google.com');
      expect(registrableDomain('news.bbc.co.uk'), 'bbc.co.uk');
      expect(registrableDomain('a.b.example.com.sd'), 'example.com.sd');
      expect(registrableDomain('example.com'), 'example.com');
    });

    test('مسافة التحرير والهيكل', () {
      expect(editDistance('paypal', 'paypa1'), 1);
      expect(editDistance('kitten', 'sitting'), 3);
      expect(editDistance('', 'abc'), 3);
      expect(skeleton('paypa1'), 'paypal');
      expect(skeleton('faceb00k'), 'facebook');
      expect(skeleton('аррӏе'), 'apple');
      expect(skeleton('rnicrosoft'), 'microsoft');
    });

    test('روابط رسمية = خطر قليل', () {
      for (final u in [
        'https://www.google.com/search?q=sudan',
        'https://wa.me/249912345678',
        'https://www.facebook.com/',
        'https://bankofkhartoum.com',
        'https://www.bbc.co.uk/news',
        'https://google.com.sa',
        'https://myaccount.google.com/security-checkup',
        'https://finance.com',
        'https://apply.com',
      ]) {
        final r = analyzeLink(u);
        expect(r.valid, isTrue, reason: u);
        expect(r.risk, LinkRisk.low, reason: '$u ${r.flags}');
      }
      expect(analyzeLink('https://www.facebook.com/login').officialBrand, 'facebook');
      expect(analyzeLink('https://www.facebook.com/login').has('keywords'), isFalse);
    });

    test('http تحذير', () {
      final r = analyzeLink('http://example.com');
      expect(r.has('http'), isTrue);
      expect(r.scheme, 'http');
    });

    test('عنوان IP', () {
      expect(analyzeLink('http://192.168.1.1/admin').isIp, isTrue);
      expect(analyzeLink('http://192.168.1.1/admin').risk, LinkRisk.high);
      expect(analyzeLink('http://3232235777/').has('ip_host'), isTrue);
      expect(analyzeLink('http://[2001:db8::1]/').isIp, isTrue);
      expect(analyzeLink('http://999.1.1.1/').isIp, isFalse);
    });

    test('علامة @', () {
      final r = analyzeLink('https://www.facebook.com@evil.tk/');
      expect(r.has('at_sign'), isTrue);
      expect(r.domain, 'evil.tk');
      expect(r.risk, LinkRisk.high);
    });

    test('Punycode وانتحال الحروف', () {
      final r = analyzeLink('https://xn--80ak6aa92e.com');
      expect(r.has('punycode'), isTrue);
      expect(r.flag('punycode')!.weight, 30);
      expect(r.has('brand_lookalike'), isTrue);
      expect(r.risk, LinkRisk.high);
      final m = analyzeLink('https://gооgle.com'); // o سيريلية
      expect(m.has('mixed_script'), isTrue);
      expect(m.risk, LinkRisk.high);
      // نطاق عربي حقيقي: علامة خفيفة فقط
      final a = analyzeLink('https://xn--mgbh0fb.xn--kgbechtv');
      expect(a.flag('punycode')!.weight, 10);
      expect(a.has('mixed_script'), isFalse);
      expect(a.risk, isNot(LinkRisk.high));
    });

    test('امتدادات مشبوهة ونطاقات فرعية كثيرة', () {
      expect(analyzeLink('https://example.xyz').has('tld'), isTrue);
      expect(analyzeLink('https://a.b.c.d.example.com').has('many_subdomains'), isTrue);
      expect(analyzeLink('https://www.example.com').has('many_subdomains'), isFalse);
    });

    test('روابط طويلة', () {
      final r = analyzeLink('https://example.com/${'a' * 250}');
      expect(r.flag('long_url')!.weight, 15);
    });

    test('مقصّرات الروابط', () {
      for (final u in ['bit.ly/3abc', 'https://tinyurl.com/x', 'https://t.co/abc', 'https://cutt.ly/x', 'https://is.gd/x', 'https://shorturl.at/x', 'https://rebrand.ly/x', 'https://ow.ly/x']) {
        final r = analyzeLink(u);
        expect(r.has('shortener'), isTrue, reason: u);
        expect(r.risk, LinkRisk.medium, reason: '$u ${r.flags}');
      }
    });

    test('انتحال الجهات', () {
      for (final (u, b) in [
        ('http://paypa1.com/login', 'paypal'),
        ('https://faceb00k.com', 'facebook'),
        ('https://whatsap.com', 'whatsapp'),
        ('https://goog1e.com', 'google'),
        ('https://amazon-prize.click', 'amazon'),
        ('https://bankofkhartoum-verify.top', 'bankofkhartoum'),
        ('https://bankofkhartum.com', 'bankofkhartoum'),
        ('https://bok-login.net', 'bankofkhartoum'),
        ('https://micros0ft-support.com', 'microsoft'),
      ]) {
        final r = analyzeLink(u);
        expect(r.has('brand_lookalike'), isTrue, reason: '$u ${r.flags}');
        expect(r.flag('brand_lookalike')!.detail, b, reason: u);
        expect(r.risk, LinkRisk.high, reason: '$u ${r.flags}');
      }
      final sub = analyzeLink('https://whatsapp.com.gift-free.xyz/claim');
      expect(sub.has('brand_in_sub'), isTrue);
      expect(sub.domain, 'gift-free.xyz');
      expect(sub.subdomains, 'whatsapp.com');
      expect(sub.risk, LinkRisk.high);
      expect(analyzeLink('https://paypal.com.secure-update.top').has('brand_in_sub'), isTrue);
      expect(analyzeLink('https://evil.example/whatsapp-gift').has('brand_in_path'), isTrue);
    });

    test('كلمات مشبوهة', () {
      final r = analyzeLink('https://example.net/verify-account/login?gift=free');
      expect(r.has('keywords'), isTrue);
      expect(r.flag('keywords')!.weight, 24);
      expect(analyzeLink('https://example.net/windows').has('keywords'), isFalse);
    });

    test('ملفات وروابط برمجية', () {
      expect(analyzeLink('https://example.com/app.apk').has('file_download'), isTrue);
      expect(analyzeLink('javascript:alert(1)').risk, LinkRisk.high);
      expect(analyzeLink('https://example.com:8080/').has('port'), isTrue);
    });

    test('مدخلات غير صالحة', () {
      expect(analyzeLink('').valid, isFalse);
      expect(analyzeLink('hello').valid, isFalse);
      expect(analyzeLink('mailto:a@b.com').valid, isFalse);
      expect(analyzeLink('https://').valid, isFalse);
    });
  });

  for (final width in [320.0, 411.0]) {
    for (final lang in Lang.values) {
      testWidgets('أدوات الأمان تُفتح دون أخطاء — ${lang.name} @$width', (tester) async {
        SharedPreferences.setMockInitialValues({});
        final s = await AppState.load();
        s.lang = lang;
        s.setData('account_security_done', ['wa_2sv', 'g_2sv', 'ph_lock']);
        s.setData('account_security_skip', ['telegram']);
        s.setData('link_check_hist', [
          {'u': 'https://faceb00k-login.xyz/verify', 'd': 'faceb00k-login.xyz', 'r': 2, 's': 80, 't': DateTime(2026, 10, 1).millisecondsSinceEpoch},
          {'u': 'https://www.google.com', 'd': 'google.com', 'r': 0, 's': 0, 't': DateTime(2026, 10, 2).millisecondsSinceEpoch},
        ]);
        tester.view.physicalSize = Size(width * 2.6, 2340 * 12);
        tester.view.devicePixelRatio = 2.6;
        addTearDown(tester.view.reset);
        final failures = <String>[];
        final orig = FlutterError.onError;
        String? cur;
        FlutterError.onError = (d) => failures.add('$cur: ${d.exceptionAsString().split('\n').first}');
        addTearDown(() => FlutterError.onError = orig);

        Future<void> pumpTool(String id, {Future<void> Function()? then}) async {
          cur = id;
          final tool = allTools.firstWhere((t) => t.id == id);
          expect(tool.cat, ToolCat.safety);
          await tester.pumpWidget(ChangeNotifierProvider.value(
            value: s,
            child: MaterialApp(
              locale: Locale(lang == Lang.en ? 'en' : 'ar'),
              theme: buildTheme(Brightness.dark),
              home: Directionality(
                textDirection: lang == Lang.en ? TextDirection.ltr : TextDirection.rtl,
                child: Scaffold(body: Builder(builder: tool.builder)),
              ),
            ),
          ));
          await tester.pump(const Duration(milliseconds: 50));
          if (then != null) await then();
          await tester.pumpWidget(const SizedBox());
          await tester.pump(const Duration(seconds: 2));
        }

        for (final id in _ids) {
          await pumpTool(id);
        }
        // حماية الحسابات: افتح عنصرًا وعلّم آخر وافتح «اتسرق؟»
        await pumpTool('account_security', then: () async {
          await tester.tap(find.byIcon(Icons.expand_more_rounded).first);
          await tester.pump();
          await tester.tap(find.byType(Checkbox).at(1));
          await tester.pump();
          for (final e in find.byType(ExpansionTile).evaluate().toList()) {
            await tester.tap(find.byWidget(e.widget));
            await tester.pumpAndSettle();
          }
        });
        // تنبيهات الاحتيال: افتح الأقسام ثم الاختبار كله
        await pumpTool('fraud_alerts', then: () async {
          await tester.tap(find.byType(ExpansionTile).first);
          await tester.pumpAndSettle();
          await tester.tap(find.byIcon(Icons.quiz_rounded));
          await tester.pump();
          for (var i = 0; i < 20; i++) {
            final b = find.byIcon(Icons.dangerous_rounded);
            if (b.evaluate().isEmpty) break;
            await tester.tap(b);
            await tester.pump();
            await tester.tap(find.byIcon(Icons.arrow_forward_rounded));
            await tester.pump();
          }
          expect(find.byIcon(Icons.replay_rounded), findsWidgets);
        });
        // التحقق من الأخبار: شغّل أسئلة
        await pumpTool('news_check', then: () async {
          for (var i = 0; i < 5; i++) {
            await tester.tap(find.byType(Switch).at(i));
            await tester.pump();
          }
          await tester.tap(find.byIcon(Icons.expand_more_rounded).first);
          await tester.pump();
        });
        // فاحص الروابط: عدة روابط
        await pumpTool('link_check', then: () async {
          for (final u in [
            'https://whatsapp.com.gift-free.xyz/claim?verify=login&update=1&a=${'x' * 120}',
            'https://xn--80ak6aa92e.com',
            'https://www.google.com',
            'bit.ly/x',
            'hello',
            'http://192.168.1.1@evil.tk:8080/app.apk',
          ]) {
            await tester.enterText(find.byType(TextField), u);
            await tester.tap(find.byIcon(Icons.policy_rounded).first);
            await tester.pump();
          }
          await tester.tap(find.byIcon(Icons.open_in_browser_rounded).last);
          await tester.pumpAndSettle();
          await tester.tap(find.byType(TextButton).last);
          await tester.pumpAndSettle();
        });
        expect(s.counter('links_checked'), greaterThan(0));
        FlutterError.onError = orig;
        expect(failures.toSet().toList(), isEmpty, reason: failures.toSet().join('\n'));
      });
    }
  }
}
