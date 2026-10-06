import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/format.dart';
import '../../core/i18n.dart';
import '../../core/state.dart';
import '../../core/theme.dart';
import '../../core/widgets.dart';
import '../life/life_common.dart' show LifeDateButton, dayDiff, todayPlace, parseDk, dk;
import '../money/money_common.dart' show ChoiceRow, CurrencyPicker, curSym;

/// حاسبة الراتب ومكافأة نهاية الخدمة
class SalaryTool extends StatefulWidget {
  const SalaryTool({super.key});
  @override
  State<SalaryTool> createState() => _SalaryToolState();
}

/// مدة الخدمة مفصّلة: سنوات/أشهر/أيام تقويمية
({int y, int m, int d}) serviceBreakdown(DateTime a, DateTime b) {
  var y = b.year - a.year, m = b.month - a.month, d = b.day - a.day;
  if (d < 0) {
    m--;
    d += DateTime(b.year, b.month, 0).day;
  }
  if (m < 0) {
    y--;
    m += 12;
  }
  return (y: y, m: m, d: d);
}

/// مكافأة نهاية الخدمة حسب نظام العمل السعودي (المادتان 84 و85)
/// [years] سنوات الخدمة (مع الكسور)، [wage] آخر أجر شهري.
/// [reason]: 'end' انتهاء العقد/إنهاء من صاحب العمل، 'resign' استقالة، 'art80' فصل وفق المادة 80
({double full, double factor, double award, double first5, double after5}) saudiEos(double years, double wage, String reason) {
  final y = math.max(0.0, years);
  final first5 = wage * .5 * math.min(y, 5.0);
  final after5 = wage * math.max(0.0, y - 5);
  final full = first5 + after5;
  double factor;
  if (reason == 'art80') {
    factor = 0;
  } else if (reason == 'resign') {
    factor = y < 2 ? 0 : y < 5 ? 1 / 3 : y < 10 ? 2 / 3 : 1;
  } else {
    factor = 1;
  }
  return (full: full, factor: factor, award: full * factor, first5: first5, after5: after5);
}

class _SalaryToolState extends State<SalaryTool> {
  static const _key = 'salary_cfg';
  String _mode = 'net';
  String _cur = 'SAR';
  final _basic = TextEditingController();
  final _housing = TextEditingController();
  final _transport = TextEditingController();
  final _other = TextEditingController();
  final _gosi = TextEditingController(text: '0');
  final _fixedDed = TextEditingController();
  final _hoursDay = TextEditingController(text: '8');
  final _otHours = TextEditingController();
  final _otRate = TextEditingController(text: '1.5');
  bool _otBasicOnly = false;
  // نهاية الخدمة
  String _eosLaw = 'sa';
  String _reason = 'end';
  DateTime? _start;
  DateTime? _end;
  bool _incHousing = true, _incTransport = true, _incOther = false;
  final _genDays = TextEditingController(text: '21');

  List<(String, TextEditingController)> get _ctrls => [
        ('basic', _basic),
        ('housing', _housing),
        ('transport', _transport),
        ('other', _other),
        ('gosi', _gosi),
        ('fixed', _fixedDed),
        ('hours', _hoursDay),
        ('otH', _otHours),
        ('otR', _otRate),
        ('genDays', _genDays),
      ];

  @override
  void initState() {
    super.initState();
    final s = context.read<AppState>();
    final c = Map<String, dynamic>.from(s.getData<Map>(_key) ?? const {});
    for (final (k, ctl) in _ctrls) {
      if (c[k] is String) ctl.text = c[k];
    }
    _mode = c['mode'] as String? ?? 'net';
    _cur = c['cur'] as String? ?? 'SAR';
    _otBasicOnly = c['otBasic'] == true;
    _eosLaw = c['law'] as String? ?? 'sa';
    _reason = c['reason'] as String? ?? 'end';
    _start = parseDk(c['start'] as String?);
    _end = parseDk(c['end'] as String?);
    _incHousing = c['incH'] as bool? ?? true;
    _incTransport = c['incT'] as bool? ?? true;
    _incOther = c['incO'] as bool? ?? false;
  }

  @override
  void dispose() {
    for (final (_, c) in _ctrls) {
      c.dispose();
    }
    super.dispose();
  }

  void _save() {
    final s = context.read<AppState>();
    s.setData(_key, {
      for (final (k, c) in _ctrls) k: c.text,
      'mode': _mode,
      'cur': _cur,
      'otBasic': _otBasicOnly,
      'law': _eosLaw,
      'reason': _reason,
      'start': _start == null ? null : dk(_start!),
      'end': _end == null ? null : dk(_end!),
      'incH': _incHousing,
      'incT': _incTransport,
      'incO': _incOther,
    });
    s.awardDaily('work_salary', 3, tr('حساب الراتب', 'Salary calculation'));
  }

  void _changed([String? _]) {
    setState(() {});
    _save();
  }

  double get _b => parseNum(_basic.text);
  double get _h => parseNum(_housing.text);
  double get _tr => parseNum(_transport.text);
  double get _o => parseNum(_other.text);

  String _money(double v) => '${fmt(v, 2)} ${curSym(_cur)}';

  @override
  Widget build(BuildContext context) {
    context.watch<AppState>();
    return ToolList(children: [
      ChoiceRow<String>([
        ('net', t('صافي الراتب', 'صافي الراتب', 'Net salary')),
        ('eos', t('نهاية الخدمة', 'مكافأة نهاية الخدمة', 'End of service')),
      ], _mode, (v) {
        _mode = v;
        _changed();
      }, color: SD.gold),
      CurrencyPicker(t('العملة', 'العملة', 'Currency'), _cur, (v) {
        _cur = v;
        _changed();
      }),
      const SizedBox(height: 12),
      SCard(
        title: t('مكوّنات الراتب الشهري', 'مكوّنات الراتب الشهري', 'Monthly pay components'),
        icon: Icons.payments_rounded,
        child: Column(children: [
          NumField(t('الراتب الأساسي', 'الراتب الأساسي', 'Basic salary'), _basic, onChanged: _changed, suffix: curSym(_cur)),
          NumField(t('بدل السكن', 'بدل السكن', 'Housing allowance'), _housing, onChanged: _changed, suffix: curSym(_cur)),
          NumField(t('بدل المواصلات', 'بدل النقل', 'Transport allowance'), _transport, onChanged: _changed, suffix: curSym(_cur)),
          NumField(t('بدلات تانية', 'بدلات أخرى', 'Other allowances'), _other, onChanged: _changed, suffix: curSym(_cur)),
        ]),
      ),
      if (_mode == 'net') ..._netSection(context) else ..._eosSection(context),
    ]);
  }

  /* ───────────── صافي الراتب ───────────── */
  List<Widget> _netSection(BuildContext context) {
    final gross = _b + _h + _tr + _o;
    final gosiBase = _b + _h;
    final gosiPct = parseNum(_gosi.text).clamp(0, 100).toDouble();
    final gosi = gosiBase * gosiPct / 100;
    final fixed = parseNum(_fixedDed.text);
    final net = gross - gosi - fixed;
    final hoursDay = math.max(1.0, parseNum(_hoursDay.text, 8));
    final daily = gross / 30;
    final hourly = daily / hoursDay;
    final otBaseHourly = (_otBasicOnly ? _b : gross) / 30 / hoursDay;
    final otH = parseNum(_otHours.text);
    final otRate = parseNum(_otRate.text, 1.5);
    final ot = otH * otBaseHourly * otRate;

    String summary() => [
          '💰 ${t('حساب الراتب', 'حساب الراتب', 'Salary breakdown')}',
          '${t('الإجمالي الشهري', 'الإجمالي الشهري', 'Monthly gross')}: ${_money(gross)}',
          '${t('الاستقطاعات', 'الاستقطاعات', 'Deductions')}: ${_money(gosi + fixed)}',
          '${t('الصافي الشهري', 'الصافي الشهري', 'Monthly net')}: ${_money(net)}',
          '${t('الصافي السنوي', 'الصافي السنوي', 'Annual net')}: ${_money(net * 12)}',
          '${t('أجر اليوم', 'الأجر اليومي', 'Daily rate')}: ${_money(daily)}',
          '${t('أجر الساعة', 'أجر الساعة', 'Hourly rate')}: ${_money(hourly)}',
          if (otH > 0) '${t('الأوفرتايم', 'العمل الإضافي', 'Overtime')} (${fmt(otH)} ${tr('ساعة', 'h')}): ${_money(ot)}',
        ].join('\n');

    return [
      SCard(
        title: t('الاستقطاعات', 'الاستقطاعات', 'Deductions'),
        icon: Icons.remove_circle_outline_rounded,
        color: SD.henna,
        child: Column(children: [
          NumField(t('نسبة التأمينات (من الأساسي + السكن)', 'نسبة التأمينات الاجتماعية (من الأساسي + السكن)', 'Social insurance % (of basic + housing)'), _gosi,
              onChanged: _changed, suffix: '%'),
          NumField(t('استقطاعات ثابتة (سلفة، غياب…)', 'استقطاعات ثابتة (سلفة، غياب…)', 'Fixed deductions (loan, absence…)'), _fixedDed,
              onChanged: _changed, suffix: curSym(_cur)),
          NoteBox(
              t(
                  'في السعودية: غير السعوديين ما بيتخصم منهم تأمينات في العادة — صاحب العمل بيدفع 2% أخطار مهنية. السعوديين عليهم نسبة بتختلف حسب النظام وتاريخ التسجيل، أكتبها بنفسك من كشف راتبك.',
                  'في السعودية: لا يُستقطع عادةً من غير السعوديين اشتراك تأمينات — يدفع صاحب العمل 2% للأخطار المهنية. على السعوديين نسبة تختلف بحسب النظام وتاريخ التسجيل، أدخلها من كشف راتبك.',
                  'Saudi Arabia: non-Saudi employees usually have no GOSI deduction — the employer pays 2% for occupational hazards. Saudi nationals pay a share that depends on the scheme and joining date; enter it from your payslip.'),
              kind: NoteKind.info),
        ]),
      ),
      ResultHero(
        label: t('صافي راتبك في الشهر', 'صافي الراتب الشهري', 'Monthly net salary'),
        value: _money(net),
        sub: '${t('الإجمالي', 'الإجمالي', 'Gross')}: ${_money(gross)}',
      ),
      SCard(
        title: t('المعدّلات', 'المعدّلات', 'Rates'),
        icon: Icons.schedule_rounded,
        color: SD.nile,
        child: Column(children: [
          NumField(t('ساعات الشغل في اليوم', 'ساعات العمل اليومية', 'Working hours per day'), _hoursDay, onChanged: _changed),
          InfoRow(t('الإجمالي الشهري', 'الإجمالي الشهري', 'Monthly gross'), _money(gross)),
          InfoRow(t('الاستقطاعات', 'مجموع الاستقطاعات', 'Total deductions'), _money(gosi + fixed), valueColor: SD.red),
          InfoRow(t('الصافي السنوي', 'الصافي السنوي', 'Annual net'), _money(net * 12), valueColor: SD.green),
          InfoRow(t('أجر اليوم', 'الأجر اليومي', 'Daily rate'), _money(daily), hint: t('الإجمالي ÷ 30', 'الإجمالي ÷ 30', 'Gross ÷ 30')),
          InfoRow(t('أجر الساعة', 'أجر الساعة', 'Hourly rate'), _money(hourly),
              hint: t('أجر اليوم ÷ ساعات اليوم', 'الأجر اليومي ÷ ساعات العمل', 'Daily rate ÷ hours per day')),
        ]),
      ),
      SCard(
        title: t('حاسبة الأوفرتايم', 'حاسبة العمل الإضافي', 'Overtime calculator'),
        icon: Icons.more_time_rounded,
        color: SD.orange,
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          NumField(t('عدد ساعات الأوفرتايم', 'عدد الساعات الإضافية', 'Overtime hours'), _otHours, onChanged: _changed),
          NumField(t('المعامل', 'معامل الأجر الإضافي', 'Rate multiplier'), _otRate, onChanged: _changed, hint: '1.5'),
          ChoiceRow<bool>([
            (false, t('على الإجمالي', 'على الأجر الإجمالي', 'On full wage')),
            (true, t('على الأساسي بس', 'على الأساسي فقط', 'On basic only')),
          ], _otBasicOnly, (v) {
            _otBasicOnly = v;
            _changed();
          }, color: SD.orange),
          InfoRow(t('أجر الساعة المعتمد', 'أجر الساعة المعتمد', 'Hourly base'), _money(otBaseHourly)),
          InfoRow(t('قيمة الأوفرتايم', 'قيمة العمل الإضافي', 'Overtime pay'), _money(ot), valueColor: SD.green),
          NoteBox(
              t(
                  'نظام العمل السعودي (م 107): الساعة الإضافية = أجر الساعة + 50% من أجر الساعة الأساسي. المعامل 1.5 تقريب شائع — راجع عقدك.',
                  'نظام العمل السعودي (المادة 107): أجر الساعة الإضافية = أجر الساعة + 50% من أجر الساعة الأساسي. المعامل 1.5 تقريب شائع — راجع عقدك.',
                  'Saudi Labor Law (Art. 107): an overtime hour = the hourly wage + 50% of the basic hourly wage. The 1.5 multiplier is a common approximation — check your contract.'),
              kind: NoteKind.tip),
        ]),
      ),
      ShareBar(summary),
    ];
  }

  /* ───────────── نهاية الخدمة ───────────── */
  List<Widget> _eosSection(BuildContext context) {
    final today = todayPlace();
    final end = _end ?? today;
    final wage = _b + (_incHousing ? _h : 0) + (_incTransport ? _tr : 0) + (_incOther ? _o : 0);
    final days = _start == null ? 0 : math.max(0, dayDiff(_start!, end));
    final years = days / 365;
    final bd = _start == null || _start!.isAfter(end) ? (y: 0, m: 0, d: 0) : serviceBreakdown(_start!, end);
    final periodText = isEn ? '${bd.y} y ${bd.m} m ${bd.d} d' : '${bd.y} سنة ${bd.m} شهر ${bd.d} يوم';

    double award;
    List<Widget> rows;
    if (_eosLaw == 'sa') {
      final r = saudiEos(years, wage, _reason);
      award = r.award;
      rows = [
        InfoRow(t('أول 5 سنين (نص شهر للسنة)', 'أول 5 سنوات (نصف شهر لكل سنة)', 'First 5 years (½ month/year)'), _money(r.first5)),
        InfoRow(t('بعد 5 سنين (شهر للسنة)', 'ما بعد 5 سنوات (شهر لكل سنة)', 'After 5 years (1 month/year)'), _money(r.after5)),
        InfoRow(t('المكافأة كاملة', 'المكافأة كاملة', 'Full award'), _money(r.full)),
        InfoRow(t('النسبة المستحقة', 'النسبة المستحقة', 'Entitled share'), _factorText(r.factor), valueColor: r.factor == 1 ? SD.green : SD.gold),
      ];
    } else {
      final perYear = parseNum(_genDays.text);
      award = years * perYear * wage / 30;
      rows = [
        InfoRow(t('أجر اليوم', 'الأجر اليومي', 'Daily wage'), _money(wage / 30), hint: t('الأجر ÷ 30', 'الأجر ÷ 30', 'Wage ÷ 30')),
        InfoRow(t('أيام المكافأة', 'أيام المكافأة', 'Award days'), fmt(years * perYear, 1)),
      ];
    }

    String summary() => [
          '🧾 ${t('مكافأة نهاية الخدمة', 'مكافأة نهاية الخدمة', 'End-of-service award')}',
          '${t('مدة الخدمة', 'مدة الخدمة', 'Service')}: $periodText (${fmt(years, 2)} ${tr('سنة', 'years')})',
          '${t('الأجر المعتمد', 'الأجر المعتمد', 'Wage basis')}: ${_money(wage)}',
          '${t('المكافأة', 'المكافأة', 'Award')}: ${_money(award)}',
          '(${tr('تقدير — للتأكد راجع مكتب العمل', 'Estimate — verify with the labor office')})',
        ].join('\n');

    return [
      SCard(
        title: t('القانون', 'النظام', 'Law'),
        icon: Icons.gavel_rounded,
        color: SD.indigo,
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          ChoiceRow<String>([
            ('sa', t('نظام العمل السعودي', 'نظام العمل السعودي', 'Saudi Labor Law')),
            ('gen', t('عام (أيام لكل سنة)', 'عام (أيام لكل سنة)', 'Generic (days/year)')),
          ], _eosLaw, (v) {
            _eosLaw = v;
            _changed();
          }, color: SD.indigo),
          if (_eosLaw == 'sa') ...[
            Text(t('سبب نهاية العلاقة', 'سبب انتهاء العلاقة', 'Reason for leaving'), style: const TextStyle(fontWeight: FontWeight.w700)),
            const SizedBox(height: 6),
            ChoiceRow<String>([
              ('end', t('انتهاء العقد / فصل من الشركة', 'انتهاء العقد / إنهاء من صاحب العمل', 'Contract end / let go by employer')),
              ('resign', t('استقالة', 'استقالة', 'Resignation')),
              ('art80', t('فصل حسب المادة 80', 'فصل وفق المادة 80', 'Dismissal under Art. 80')),
            ], _reason, (v) {
              _reason = v;
              _changed();
            }, color: SD.indigo),
          ] else
            NumField(t('أيام لكل سنة خدمة', 'عدد الأيام لكل سنة خدمة', 'Days per year of service'), _genDays, onChanged: _changed, hint: '21'),
        ]),
      ),
      SCard(
        title: t('مدة الخدمة والأجر', 'مدة الخدمة والأجر', 'Service period & wage'),
        icon: Icons.date_range_rounded,
        color: SD.teal,
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          LifeDateButton(
            label: t('تاريخ بداية الشغل', 'تاريخ مباشرة العمل', 'Start date'),
            value: _start,
            first: DateTime(1960),
            last: DateTime(today.year + 10),
            color: SD.teal,
            onPick: (d) {
              _start = d;
              _changed();
            },
          ),
          const SizedBox(height: 8),
          LifeDateButton(
            label: t('تاريخ نهاية الشغل (فاضي = الليلة)', 'تاريخ انتهاء العمل (فارغ = اليوم)', 'End date (empty = today)'),
            value: _end,
            clearable: true,
            first: DateTime(1960),
            last: DateTime(today.year + 30),
            color: SD.teal,
            onPick: (d) {
              _end = d;
              _changed();
            },
          ),
          const SizedBox(height: 12),
          Text(t('الأجر المحسوب عليه (آخر أجر)', 'الأجر الذي تُحسب عليه (آخر أجر)', 'Wage basis (last wage)'), style: const TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
          Wrap(spacing: 6, runSpacing: 6, children: [
            FilterChip(label: Text(t('الأساسي', 'الأساسي', 'Basic')), selected: true, onSelected: null),
            FilterChip(
                label: Text(t('السكن', 'السكن', 'Housing')),
                selected: _incHousing,
                onSelected: (v) {
                  _incHousing = v;
                  _changed();
                }),
            FilterChip(
                label: Text(t('المواصلات', 'النقل', 'Transport')),
                selected: _incTransport,
                onSelected: (v) {
                  _incTransport = v;
                  _changed();
                }),
            FilterChip(
                label: Text(t('تانية', 'أخرى', 'Other')),
                selected: _incOther,
                onSelected: (v) {
                  _incOther = v;
                  _changed();
                }),
          ]),
          const SizedBox(height: 6),
          InfoRow(t('الأجر الشهري المعتمد', 'الأجر الشهري المعتمد', 'Monthly wage basis'), _money(wage)),
          InfoRow(t('مدة الخدمة', 'مدة الخدمة', 'Service period'), _start == null ? '—' : periodText,
              hint: _start == null ? null : '${fmt(years, 3)} ${tr('سنة (الأيام ÷ 365)', 'years (days ÷ 365)')}'),
        ]),
      ),
      ResultHero(
        label: t('مكافأة نهاية الخدمة (تقدير)', 'مكافأة نهاية الخدمة (تقديرية)', 'End-of-service award (estimate)'),
        value: _money(award),
        colors: const [Color(0xFF0E8C84), Color(0xFF0B5C8A), Color(0xFF3B2F8F)],
      ),
      SCard(
        title: t('التفاصيل', 'التفاصيل', 'Breakdown'),
        icon: Icons.list_alt_rounded,
        child: Column(children: rows),
      ),
      if (_eosLaw == 'sa')
        NoteBox(
            t(
                'الطريقة: نص شهر عن كل سنة من أول 5 سنين، وشهر كامل عن كل سنة بعدها، وأجزاء السنة بتتحسب بنسبتها. في الاستقالة: أقل من سنتين ما في حاجة، من 2 لأقل من 5 التلت، من 5 لأقل من 10 التلتين، 10 سنين وأكتر كاملة. في حالات (زي القوة القاهرة، أو الموظفة خلال 6 شهور من الزواج أو 3 شهور من الولادة) بتستحق كاملة.',
                'الطريقة: نصف أجر شهر عن كل سنة من السنوات الخمس الأولى، وأجر شهر عن كل سنة بعدها، وتُحسب أجزاء السنة بنسبتها. عند الاستقالة: أقل من سنتين لا شيء، من 2 إلى أقل من 5 الثلث، من 5 إلى أقل من 10 الثلثان، و10 سنوات فأكثر كاملة. وتُستحق كاملة في حالات منها القوة القاهرة، والعاملة خلال 6 أشهر من الزواج أو 3 أشهر من الوضع.',
                'Method: half a month\'s wage for each of the first 5 years, a full month for each year after, with partial years pro-rated. On resignation: under 2 years nothing, 2 to under 5 one third, 5 to under 10 two thirds, 10+ years full. The full award applies in some cases, such as force majeure, or a female worker leaving within 6 months of marriage or 3 months of giving birth.'),
            kind: NoteKind.info),
      NoteBox(
          t(
              'ده تقدير بس. القوانين بتختلف من بلد لبلد وممكن تكون في تعديلات جديدة أو شروط في عقدك — اتأكد من مكتب العمل أو منصة الوزارة الرسمية.',
              'هذا تقدير فقط. تختلف الأنظمة من بلد لآخر وقد توجد تعديلات حديثة أو شروط في عقدك — تحقّق من مكتب العمل أو المنصة الرسمية للوزارة.',
              'This is only an estimate. Rules differ by country and there may be recent amendments or contract terms — verify with the labor office or the ministry\'s official platform.'),
          kind: NoteKind.warn),
      ShareBar(summary),
    ];
  }

  String _factorText(double f) {
    if (f == 1) return t('كاملة', 'كاملة', 'Full');
    if (f == 0) return t('ما في', 'لا شيء', 'None');
    if ((f - 1 / 3).abs() < 1e-9) return t('التلت', 'الثلث', 'One third');
    return t('التلتين', 'الثلثان', 'Two thirds');
  }
}
