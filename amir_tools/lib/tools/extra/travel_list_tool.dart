import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../core/i18n.dart';
import '../../core/state.dart';
import '../../core/theme.dart';
import '../../core/widgets.dart';
import '../life/life_common.dart' show mapList, intOf, newId, dk, parseDk, dayDiff, todayPlace, confirmAsk, lifeSheet, LifeDateButton, EmptyHint, PickChip, undoSnack;
import 'extra_common.dart';

/// تصنيف بنود السفر
class _TCat {
  final String key, emoji, sd, ar, en;
  final Color color;
  const _TCat(this.key, this.emoji, this.sd, this.ar, this.en, this.color);
  String get name => t(sd, ar, en);
}

const _tcats = [
  _TCat('docs', '📄', 'الأوراق', 'الوثائق', 'Documents', SD.nile),
  _TCat('ibadah', '🕋', 'العبادة والإحرام', 'العبادة والإحرام', 'Worship & ihram', SD.green),
  _TCat('health', '💊', 'العلاج والصحة', 'الصحة والأدوية', 'Health', SD.red),
  _TCat('clothes', '👕', 'اللبس', 'الملابس', 'Clothes', SD.henna),
  _TCat('care', '🧴', 'النضافة الشخصية', 'العناية الشخصية', 'Toiletries', SD.teal),
  _TCat('elec', '🔌', 'الإلكترونيات', 'الإلكترونيات', 'Electronics', SD.indigo),
  _TCat('kids', '🧸', 'حاجات الشفّع', 'مستلزمات الأطفال', 'Kids', SD.pink),
  _TCat('gifts', '🎁', 'هدايا ووصايا الأهل', 'هدايا الأهل', 'Gifts for family', SD.gold),
  _TCat('misc', '🎒', 'حاجات تانية', 'متفرقات', 'Other', SD.coffee),
];

/// بند قالب: (تصنيف، عربي، إنجليزي)
typedef _TI = (String, String, String);

class _Tpl {
  final String key, emoji, sd, ar, en;
  final List<_TI> items;
  const _Tpl(this.key, this.emoji, this.sd, this.ar, this.en, this.items);
  String get name => t(sd, ar, en);
}

const _tpls = [
  _Tpl('umrah', '🕋', 'عمرة / حج', 'عمرة / حج', 'Umrah / Hajj', [
    ('docs', 'جواز سفر ساري (6 شهور على الأقل)', 'Valid passport (6+ months)'),
    ('docs', 'التأشيرة أو تصريح العمرة/الحج', 'Visa or Umrah/Hajj permit'),
    ('docs', 'تذاكر الطيران', 'Flight tickets'),
    ('docs', 'حجز السكن', 'Hotel booking'),
    ('docs', 'شهادة التطعيمات المطلوبة', 'Required vaccination certificate'),
    ('docs', 'صور من الجواز والأوراق (ورقي وعلى التلفون)', 'Passport & document copies (paper + phone)'),
    ('docs', 'كاش وبطاقة بنك', 'Cash and bank card'),
    ('ibadah', 'ملابس الإحرام (للرجال: إزار ورداء)', 'Ihram garments (men: izar & rida)'),
    ('ibadah', 'حزام الإحرام', 'Ihram belt'),
    ('ibadah', 'صابون ومنتجات بدون ريحة', 'Unscented soap & products'),
    ('ibadah', 'مصحف صغير وكتيّب أدعية', 'Small Qur\'an & dua booklet'),
    ('ibadah', 'سجادة صلاة خفيفة', 'Light prayer mat'),
    ('ibadah', 'شنطة صغيرة للمراكيب', 'Small bag for shoes'),
    ('clothes', 'نعال مريحة', 'Comfortable sandals'),
    ('clothes', 'ملابس محتشمة وخفيفة', 'Light modest clothes'),
    ('clothes', 'عباية وطرح (للنساء)', 'Abaya & scarves (women)'),
    ('health', 'أدويتك اليومية مع الروشتة', 'Daily medicines with prescription'),
    ('health', 'كمامات', 'Face masks'),
    ('health', 'مسكّن وخافض حرارة', 'Painkillers / fever reducer'),
    ('health', 'لصقات للبثور والتسلّخ', 'Blister plasters'),
    ('health', 'شمسية وقزازة موية', 'Umbrella & water bottle'),
    ('care', 'قصّافة أضافر ومشط', 'Nail clipper & comb'),
    ('care', 'معجون وفرشة ومسواك', 'Toothpaste, brush & miswak'),
    ('elec', 'التلفون والشاحن', 'Phone & charger'),
    ('elec', 'باور بانك', 'Power bank'),
    ('elec', 'محوّل فيش', 'Plug adapter'),
  ]),
  _Tpl('sudan', '🇸🇩', 'سفر للسودان', 'السفر إلى السودان', 'Trip to Sudan', [
    ('docs', 'الجواز', 'Passport'),
    ('docs', 'الرقم الوطني / البطاقة', 'National ID / number'),
    ('docs', 'تأشيرة الخروج والعودة (للمغتربين)', 'Exit & re-entry visa (expats)'),
    ('docs', 'التذاكر', 'Tickets'),
    ('docs', 'صور الأوراق على التلفون', 'Document copies on phone'),
    ('docs', 'كاش (دولار/ريال) — عملات نضيفة', 'Cash (USD/SAR) — clean notes'),
    ('health', 'أدوية الملاريا (اسأل الطبيب)', 'Malaria prevention (ask a doctor)'),
    ('health', 'طارد ناموس وناموسية', 'Mosquito repellent & net'),
    ('health', 'أدويتك اليومية لكل المدة', 'Daily meds for the whole stay'),
    ('health', 'محلول تروية (ORS)', 'Oral rehydration salts (ORS)'),
    ('health', 'كريم واقي شمس', 'Sunscreen'),
    ('clothes', 'جلابية وعمّة / توب', 'Jalabiya & imma / toub'),
    ('clothes', 'لبس قطن خفيف', 'Light cotton clothes'),
    ('clothes', 'سفنجة / مركوب', 'Sandals / markoob'),
    ('elec', 'الشاحن وباور بانك كبير', 'Charger & big power bank'),
    ('elec', 'كشّاف/بطارية (للكهرباء القاطعة)', 'Torch (for power cuts)'),
    ('elec', 'شريحة أو باقة تجوال', 'SIM card or roaming plan'),
    ('gifts', 'هدايا الأهل (عطور، ملابس، حلويات)', 'Family gifts (perfume, clothes, sweets)'),
    ('gifts', 'وصايا الأهل والجيران', 'Items family & neighbours asked for'),
    ('gifts', 'هدايا الشفّع', 'Gifts for the kids'),
    ('misc', 'قزازة موية وأكل للطريق', 'Water bottle & road snacks'),
  ]),
  _Tpl('expat', '💼', 'مغترب جديد', 'مغترب جديد', 'New expat', [
    ('docs', 'الجواز (ساري لمدة طويلة)', 'Passport (long validity)'),
    ('docs', 'التأشيرة وعقد العمل', 'Visa & work contract'),
    ('docs', 'الشهادات موثّقة ومعتمدة', 'Attested certificates'),
    ('docs', 'رخصة القيادة + الدولية', 'Driving licence + international permit'),
    ('docs', 'الكشف الطبي', 'Medical report'),
    ('docs', 'صور شخصية بخلفية بيضاء', 'Passport photos (white background)'),
    ('docs', 'نسخ إلكترونية من كل الأوراق', 'Digital copies of all documents'),
    ('docs', 'أرقام الطوارئ والأهل مكتوبة', 'Emergency & family contacts written down'),
    ('health', 'أدوية شهر مع روشتة بالإنجليزي', 'A month of meds + English prescription'),
    ('clothes', 'لبس الشغل', 'Work clothes'),
    ('clothes', 'لبس يناسب جو البلد', 'Clothes for the local weather'),
    ('care', 'أدوات العناية الشخصية', 'Toiletries'),
    ('elec', 'اللابتوب والشاحن', 'Laptop & charger'),
    ('elec', 'تلفون مفتوح لكل الشبكات', 'Unlocked phone'),
    ('elec', 'محوّل فيش', 'Plug adapter'),
    ('misc', 'حاجات من البلد (اتأكد من قوانين الجمارك)', 'Food from home (check customs rules)'),
    ('misc', 'فلوس تكفي أول شهر', 'Money for the first month'),
    ('gifts', 'هدية صغيرة للمستضيف', 'Small gift for your host'),
  ]),
  _Tpl('short', '🧳', 'رحلة قصيرة', 'رحلة قصيرة', 'Short trip', [
    ('docs', 'البطاقة / الجواز', 'ID / passport'),
    ('docs', 'التذاكر والحجز', 'Tickets & booking'),
    ('clothes', 'غيارات لكل يوم', 'A change of clothes per day'),
    ('clothes', 'لبس نوم', 'Sleepwear'),
    ('care', 'فرشة ومعجون ومزيل عرق', 'Toothbrush, paste & deodorant'),
    ('health', 'أدويتك', 'Your medicines'),
    ('elec', 'الشاحن وباور بانك', 'Charger & power bank'),
    ('elec', 'سماعات', 'Earphones'),
    ('misc', 'قزازة موية وسناكس', 'Water bottle & snacks'),
    ('misc', 'مفتاح البيت', 'House keys'),
  ]),
  _Tpl('kids', '👨‍👩‍👧', 'سفر بالشفّع', 'السفر مع الأطفال', 'Travelling with kids', [
    ('docs', 'جوازات الأطفال', 'Children\'s passports'),
    ('docs', 'شهادات الميلاد', 'Birth certificates'),
    ('docs', 'كروت التطعيم', 'Vaccination cards'),
    ('docs', 'موافقة الوالد التاني لو مسافر براك', 'Other parent\'s consent if travelling alone'),
    ('health', 'خافض حرارة للأطفال', 'Children\'s fever reducer'),
    ('health', 'ميزان حرارة', 'Thermometer'),
    ('health', 'معقّم يدين ومناديل مبلولة', 'Hand sanitizer & wet wipes'),
    ('kids', 'حفاضات تكفي الطريق وزيادة', 'Enough diapers + extra'),
    ('kids', 'لبن وببرونة', 'Milk & bottle'),
    ('kids', 'سناكس وموية', 'Snacks & water'),
    ('kids', 'ألعاب صغيرة وكتب تلوين', 'Small toys & colouring books'),
    ('kids', 'تابلت عليهو كرتون منزّل', 'Tablet with downloaded cartoons'),
    ('kids', 'سماعات للأطفال', 'Kids\' headphones'),
    ('kids', 'عربية أطفال / حمّالة', 'Stroller / carrier'),
    ('clothes', 'غيار كامل في شنطة اليد', 'Full change in the carry-on'),
    ('clothes', 'جاكيت خفيف (الطيارة باردة)', 'Light jacket (planes are cold)'),
    ('misc', 'أكياس بلاستيك', 'Plastic bags'),
  ]),
];

_Tpl? _tpl(String? k) {
  for (final x in _tpls) {
    if (x.key == k) return x;
  }
  return null;
}

/// اسم البند حسب اللغة (بنود القالب تُخزن بمفتاح)
(String, String)? _tplItem(String? key) {
  if (key == null) return null;
  final p = key.split('.');
  if (p.length != 2) return null;
  final tp = _tpl(p[0]);
  final i = int.tryParse(p[1]);
  if (tp == null || i == null || i < 0 || i >= tp.items.length) return null;
  final it = tp.items[i];
  return (it.$1, tr(it.$2, it.$3));
}

class TravelListTool extends StatefulWidget {
  const TravelListTool({super.key});
  @override
  State<TravelListTool> createState() => _TravelListToolState();
}

class _TravelListToolState extends State<TravelListTool> {
  String? _sel;
  bool _hideDone = false;
  String _newCat = 'misc';
  final _newC = TextEditingController();

  @override
  void dispose() {
    _newC.dispose();
    super.dispose();
  }

  List<Map<String, dynamic>> _trips(AppState s) => mapList(s.getData<List>('travel_list_trips'));
  void _saveTrips(AppState s, List<Map<String, dynamic>> l) => s.setData('travel_list_trips', l);

  void _saveTrip(Map<String, dynamic> trip) {
    final s = context.read<AppState>();
    final l = _trips(s);
    final i = l.indexWhere((x) => x['id'] == trip['id']);
    if (i >= 0) l[i] = trip;
    _saveTrips(s, l);
  }

  String _itemName(Map it) => _tplItem(it['k'] as String?)?.$2 ?? '${it['n'] ?? ''}';
  String _itemCat(Map it) => _tplItem(it['k'] as String?)?.$1 ?? '${it['c'] ?? 'misc'}';

  Future<void> _create([String? tplKey]) async {
    final nameC = TextEditingController(text: _tpl(tplKey)?.name ?? '');
    var tk = tplKey ?? 'short';
    DateTime? date;
    final ok = await lifeSheet<bool>(
      context,
      t('رحلة جديدة', 'رحلة جديدة', 'New trip'),
      (ctx, set) => Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Text(t('القالب', 'القالب', 'Template'), style: const TextStyle(fontWeight: FontWeight.w700)),
        const SizedBox(height: 6),
        Wrap(spacing: 6, runSpacing: 6, children: [
          for (final x in _tpls)
            PickChip('${x.emoji} ${x.name}', tk == x.key, () {
              set(() {
                if (nameC.text.trim().isEmpty || _tpls.any((y) => y.name == nameC.text.trim())) nameC.text = x.name;
                tk = x.key;
              });
            }, color: SD.nile),
        ]),
        const SizedBox(height: 12),
        TextField(controller: nameC, decoration: InputDecoration(labelText: t('اسم الرحلة', 'اسم الرحلة', 'Trip name'))),
        const SizedBox(height: 12),
        LifeDateButton(
          label: t('تاريخ السفر', 'تاريخ السفر', 'Departure date'),
          value: date,
          clearable: true,
          first: todayPlace().subtract(const Duration(days: 30)),
          onPick: (d) => set(() => date = d),
          color: SD.nile,
        ),
        const SizedBox(height: 16),
        FilledButton.icon(onPressed: () => Navigator.pop(ctx, true), icon: const Icon(Icons.luggage_rounded), label: Text(t('جهّز القائمة', 'أنشئ القائمة', 'Create list'))),
      ]),
    );
    final name = nameC.text.trim();
    nameC.dispose();
    if (ok != true || !mounted) return;
    final tp = _tpl(tk)!;
    final trip = {
      'id': newId(),
      'name': name.isEmpty ? tp.name : name,
      'tpl': tk,
      'date': date == null ? null : dk(date!),
      'items': [
        for (var i = 0; i < tp.items.length; i++) {'id': newId(), 'k': '$tk.$i', 'd': false},
      ],
      'c': DateTime.now().millisecondsSinceEpoch,
    };
    final s = context.read<AppState>();
    _saveTrips(s, [..._trips(s), trip]);
    s.awardDaily('travel_list', 3, tr('قائمة السفر', 'Packing list'));
    setState(() => _sel = trip['id'] as String);
  }

  void _toggle(Map<String, dynamic> trip, String id) {
    final items = mapList(trip['items']);
    final i = items.indexWhere((e) => e['id'] == id);
    if (i < 0) return;
    items[i]['d'] = items[i]['d'] != true;
    final allDone = items.every((e) => e['d'] == true);
    _saveTrip({...trip, 'items': items});
    HapticFeedback.selectionClick();
    if (allDone) {
      context.read<AppState>().award(5, tr('جهّزت شنطة السفر', 'Packed for a trip'));
      toast(t('🎉 الشنطة جاهزة! سفر سعيد', '🎉 الحقيبة جاهزة! رحلة سعيدة', '🎉 All packed! Have a great trip'));
    }
  }

  void _addItem(Map<String, dynamic> trip) {
    final v = _newC.text.trim();
    if (v.isEmpty) return;
    _saveTrip({
      ...trip,
      'items': [...mapList(trip['items']), {'id': newId(), 'n': v, 'c': _newCat, 'd': false}],
    });
    _newC.clear();
  }

  void _removeItem(Map<String, dynamic> trip, Map<String, dynamic> it) {
    final items = mapList(trip['items'])..removeWhere((e) => e['id'] == it['id']);
    _saveTrip({...trip, 'items': items});
    undoSnack(t('البند اتمسح', 'حُذف البند', 'Item removed'), () {
      final s = context.read<AppState>();
      final cur = _trips(s).where((x) => x['id'] == trip['id']).firstOrNull;
      if (cur != null) _saveTrip({...cur, 'items': [...mapList(cur['items']), it]});
    });
  }

  String _remaining(Map trip) {
    final items = mapList(trip['items']).where((e) => e['d'] != true).toList();
    final b = StringBuffer('🧳 ${trip['name']} — ${t('الفاضل نجهّزو', 'المتبقي للتجهيز', 'Still to pack')} (${items.length})\n');
    for (final c in _tcats) {
      final inCat = items.where((e) => _itemCat(e) == c.key).toList();
      if (inCat.isEmpty) continue;
      b.writeln('\n${c.emoji} ${c.name}:');
      for (final e in inCat) {
        b.writeln('☐ ${_itemName(e)}');
      }
    }
    return b.toString().trim();
  }

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final trips = _trips(s);
    final trip = trips.where((x) => x['id'] == _sel).firstOrNull ?? trips.lastOrNull;
    return ToolList(children: [
      if (trips.isNotEmpty)
        SizedBox(
          height: 42,
          child: ListView(scrollDirection: Axis.horizontal, children: [
            for (final x in trips.reversed)
              Padding(
                padding: const EdgeInsetsDirectional.only(end: 6),
                child: ChoiceChip(
                  label: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 160),
                    child: Text('${_tpl(x['tpl'] as String?)?.emoji ?? '🧳'} ${x['name']}', maxLines: 1, overflow: TextOverflow.ellipsis),
                  ),
                  selected: x['id'] == trip?['id'],
                  onSelected: (_) => setState(() => _sel = x['id'] as String),
                ),
              ),
            ActionChip(avatar: const Icon(Icons.add_rounded, size: 18), label: Text(t('رحلة', 'رحلة', 'Trip')), onPressed: () => _create()),
          ]),
        ),
      if (trips.isNotEmpty) const SizedBox(height: 12),
      if (trip == null) ..._templates() else ..._tripView(trip),
    ]);
  }

  List<Widget> _templates() => [
        SCard(
          title: t('اختار نوع السفرة', 'اختر نوع الرحلة', 'Choose a trip type'),
          icon: Icons.luggage_rounded,
          color: SD.nile,
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            for (final x in _tpls)
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Text(x.emoji, style: const TextStyle(fontSize: 26)),
                title: Text(x.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w800)),
                subtitle: Text('${x.items.length} ${t('بند جاهز', 'بندًا جاهزًا', 'ready items')}'),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () => _create(x.key),
              ),
          ]),
        ),
        EmptyHint(Icons.flight_takeoff_rounded, t('اختار قالب وبعدين زيد أو شيل البنود على كيفك', 'اختر قالبًا ثم أضف أو احذف البنود كما تريد', 'Pick a template, then add or remove items as you like')),
      ];

  List<Widget> _tripView(Map<String, dynamic> trip) {
    final items = mapList(trip['items']);
    final done = items.where((e) => e['d'] == true).length;
    final frac = items.isEmpty ? 0.0 : done / items.length;
    final date = parseDk(trip['date'] as String?);
    final days = date == null ? null : dayDiff(todayPlace(), date);
    final countdown = days == null
        ? t('ما حددت تاريخ السفر', 'لم يُحدد تاريخ السفر', 'No departure date set')
        : days > 0
            ? t('فاضل $days يوم على السفر', 'متبقٍ $days يومًا على السفر', '$days days to departure')
            : days == 0
                ? t('السفر الليلة/اليوم! ✈️', 'السفر اليوم! ✈️', 'Departure is today! ✈️')
                : t('سافرت قبل ${-days} يوم', 'سافرت منذ ${-days} يومًا', 'Departed ${-days} days ago');
    final cats = [for (final c in _tcats) if (items.any((e) => _itemCat(e) == c.key)) c];
    return [
      ResultHero(
        label: '${_tpl(trip['tpl'] as String?)?.emoji ?? '🧳'} ${trip['name']}',
        value: '${(frac * 100).round()}%',
        sub: '$done / ${items.length} ${t('جاهز', 'جاهز', 'packed')} • $countdown',
        colors: frac >= 1 ? const [SD.green, Color(0xFF00501D), SD.brownDeep] : null,
      ),
      LifeDateButton(
        label: t('تاريخ السفر', 'تاريخ السفر', 'Departure date'),
        value: date,
        clearable: true,
        first: todayPlace().subtract(const Duration(days: 365)),
        onPick: (d) => _saveTrip({...trip, 'date': d == null ? null : dk(d)}),
        color: SD.nile,
      ),
      const SizedBox(height: 14),
      if (trip['tpl'] == 'umrah')
        NoteBox(t('شروط التأشيرة والتطعيمات بتتغيّر — راجعها من المصادر الرسمية (منصة نسك/السفارة) قبل السفر.',
            'اشتراطات التأشيرة والتطعيمات تتغير — راجعها من المصادر الرسمية (منصة نسك/السفارة) قبل السفر.',
            'Visa and vaccination rules change — check the official sources (Nusuk / embassy) before you travel.'), kind: NoteKind.warn),
      SCard(
        title: t('التقدّم', 'التقدم', 'Progress'),
        icon: Icons.donut_large_rounded,
        color: SD.green,
        child: Column(children: [
          for (final c in cats)
            () {
              final inCat = items.where((e) => _itemCat(e) == c.key).toList();
              final d = inCat.where((e) => e['d'] == true).length;
              return XBar('${c.emoji} ${c.name}', d / inCat.length, '$d/${inCat.length}', color: c.color);
            }(),
        ]),
      ),
      Row(children: [
        Expanded(
          child: SwitchListTile(
            contentPadding: EdgeInsets.zero,
            value: _hideDone,
            onChanged: (v) => setState(() => _hideDone = v),
            title: Text(t('أخفي الجاهز', 'إخفاء المنجز', 'Hide packed'), maxLines: 1, overflow: TextOverflow.ellipsis),
          ),
        ),
      ]),
      for (final c in cats)
        () {
          final inCat = items.where((e) => _itemCat(e) == c.key && (!_hideDone || e['d'] != true)).toList();
          if (inCat.isEmpty) return const SizedBox.shrink();
          return SCard(
            title: '${c.emoji} ${c.name}',
            color: c.color,
            padding: const EdgeInsets.fromLTRB(10, 14, 10, 8),
            child: Column(children: [
              for (final it in inCat)
                Row(children: [
                  Checkbox(value: it['d'] == true, onChanged: (_) => _toggle(trip, it['id'] as String)),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => _toggle(trip, it['id'] as String),
                      child: Text(_itemName(it),
                          style: TextStyle(
                            decoration: it['d'] == true ? TextDecoration.lineThrough : null,
                            color: it['d'] == true ? Theme.of(context).colorScheme.onSurface.withValues(alpha: .5) : null,
                          )),
                    ),
                  ),
                  IconButton(
                    visualDensity: VisualDensity.compact,
                    tooltip: t('شيل', 'حذف', 'Remove'),
                    onPressed: () => _removeItem(trip, it),
                    icon: const Icon(Icons.close_rounded, size: 18),
                  ),
                ]),
            ]),
          );
        }(),
      SCard(
        title: t('زيد بند', 'إضافة بند', 'Add item'),
        icon: Icons.add_rounded,
        color: SD.gold,
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Row(children: [
            Expanded(
              child: TextField(
                controller: _newC,
                onSubmitted: (_) => _addItem(trip),
                decoration: InputDecoration(isDense: true, hintText: t('مثلًا: شاحن العربية', 'مثال: شاحن السيارة', 'e.g. car charger')),
              ),
            ),
            const SizedBox(width: 6),
            IconButton.filled(onPressed: () => _addItem(trip), icon: const Icon(Icons.add_rounded)),
          ]),
          const SizedBox(height: 8),
          Wrap(spacing: 6, runSpacing: 6, children: [
            for (final c in _tcats) PickChip('${c.emoji} ${c.name}', _newCat == c.key, () => setState(() => _newCat = c.key), color: c.color),
          ]),
        ]),
      ),
      if (done < items.length) ...[ShareBar(() => _remaining(trip)), const SizedBox(height: 10)],
      Row(children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: done == 0 ? null : () => _saveTrip({...trip, 'items': [for (final e in items) {...e, 'd': false}]}),
            icon: const Icon(Icons.restart_alt_rounded),
            label: FittedBox(fit: BoxFit.scaleDown, child: Text(t('ابدأ من جديد', 'إلغاء التحديد', 'Uncheck all'))),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: OutlinedButton.icon(
            style: OutlinedButton.styleFrom(foregroundColor: SD.red),
            onPressed: () async {
              final s = context.read<AppState>();
              if (await confirmAsk(context, t('نمسح الرحلة؟', 'حذف الرحلة؟', 'Delete trip?'), '${trip['name']}')) {
                _saveTrips(s, _trips(s)..removeWhere((x) => x['id'] == trip['id']));
                if (mounted) setState(() => _sel = null);
              }
            },
            icon: const Icon(Icons.delete_outline_rounded),
            label: FittedBox(fit: BoxFit.scaleDown, child: Text(t('امسح الرحلة', 'حذف الرحلة', 'Delete trip'))),
          ),
        ),
      ]),
      Padding(
        padding: const EdgeInsets.only(top: 6),
        child: Text('${t('بنود', 'بنود', 'Items')}: ${items.length} • ${t('الرحلات', 'الرحلات', 'Trips')}: ${intOf(_trips(context.read<AppState>()).length)}',
            textAlign: TextAlign.center, style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: .55), fontSize: 12)),
      ),
    ];
  }
}
