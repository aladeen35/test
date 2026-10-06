/// حاسبة المواريث (الفرائض) — مذهب الجمهور، وتوافق المالكية في الحالات المدعومة.
/// منطق خالص بلا واجهة حتى يُختبر بسهولة.
/// الحالات النادرة أو الخلافية (المشتركة، الأكدرية، الجد مع الإخوة، ذوو الأرحام) لا تُحسب
/// بل تُعاد كحالة «غير مدعومة» ليعرض التطبيق تنبيهًا بمراجعة عالم أو محكمة.
library;

import '../../core/i18n.dart';

int _gcd(int a, int b) {
  a = a.abs();
  b = b.abs();
  while (b != 0) {
    final t = a % b;
    a = b;
    b = t;
  }
  return a == 0 ? 1 : a;
}

int _lcm(int a, int b) => a ~/ _gcd(a, b) * b;

/// كسر عادي مختزل
class Frac implements Comparable<Frac> {
  final int n, d;
  const Frac._(this.n, this.d);
  factory Frac(int n, [int d = 1]) {
    if (d == 0) throw ArgumentError('denominator 0');
    if (d < 0) {
      n = -n;
      d = -d;
    }
    final g = _gcd(n, d);
    return Frac._(n ~/ g, d ~/ g);
  }
  static const zero = Frac._(0, 1);
  static const one = Frac._(1, 1);

  Frac operator +(Frac o) => Frac(n * o.d + o.n * d, d * o.d);
  Frac operator -(Frac o) => Frac(n * o.d - o.n * d, d * o.d);
  Frac operator *(Frac o) => Frac(n * o.n, d * o.d);
  Frac operator /(Frac o) => Frac(n * o.d, d * o.n);
  Frac times(int k) => Frac(n * k, d);
  Frac div(int k) => Frac(n, d * k);

  bool get isZero => n == 0;
  bool get isPositive => n > 0;
  double get value => n / d;

  @override
  int compareTo(Frac o) => (n * o.d).compareTo(o.n * d);
  bool operator >(Frac o) => compareTo(o) > 0;
  bool operator <(Frac o) => compareTo(o) < 0;

  @override
  bool operator ==(Object o) => o is Frac && o.n == n && o.d == d;
  @override
  int get hashCode => Object.hash(n, d);
  @override
  String toString() => d == 1 ? '$n' : '$n/$d';
}

/// الورثة المُدخلون
class Heirs {
  final bool husband;
  final int wives;
  final int sons, daughters, sonsSons, sonsDaughters;
  final bool father, mother, grandfather;

  /// أم الأب، وأم الأم
  final bool patGrandmother, matGrandmother;
  final int fullBrothers, fullSisters, patBrothers, patSisters;

  /// الإخوة لأم (ذكورًا وإناثًا)
  final int matSiblings;

  const Heirs({
    this.husband = false,
    this.wives = 0,
    this.sons = 0,
    this.daughters = 0,
    this.sonsSons = 0,
    this.sonsDaughters = 0,
    this.father = false,
    this.mother = false,
    this.grandfather = false,
    this.patGrandmother = false,
    this.matGrandmother = false,
    this.fullBrothers = 0,
    this.fullSisters = 0,
    this.patBrothers = 0,
    this.patSisters = 0,
    this.matSiblings = 0,
  });

  bool get any =>
      husband ||
      wives > 0 ||
      sons + daughters + sonsSons + sonsDaughters + fullBrothers + fullSisters + patBrothers + patSisters + matSiblings > 0 ||
      father ||
      mother ||
      grandfather ||
      patGrandmother ||
      matGrandmother;
}

enum Unsupported { invalid, noHeirs, grandfatherSiblings, akdariyya, mushtaraka }

/// نصيب وارث (أو مجموعة ورثة من نفس الصنف)
class HeirShare {
  final String key;
  final int count;

  /// الفرض قبل العول/الرد (null إن لم يكن صاحب فرض)
  Frac? fard;

  /// يرث بالتعصيب
  bool asaba;

  /// نصيب المجموعة النهائي من صافي التركة
  Frac share = Frac.zero;

  /// المصطلح الشرعي بالعربية (يبقى عربيًا في كل اللغات)
  String term;

  /// شرح السبب بلغة التطبيق
  String why;
  bool blocked;

  /// وزن التعصيب لكل فرد (ذكر 2، أنثى 1)
  final int unit;

  HeirShare(this.key, this.count, {this.fard, this.asaba = false, this.term = '', this.why = '', this.blocked = false, this.unit = 1});

  Frac get each => count == 0 ? Frac.zero : share.div(count);
  bool get isSpouse => key == 'husband' || key == 'wife';
}

class InheritanceResult {
  final List<HeirShare> rows;
  final Unsupported? unsupported;

  /// أصل المسألة (المقام المشترك للفروض) والعول
  final int base;
  final int awlTo;
  final bool awl, radd;

  /// باقٍ بلا مستحق من الورثة المدعومين (يذهب لذوي الأرحام/بيت المال حسب المذهب)
  final Frac unallocated;

  const InheritanceResult({
    this.rows = const [],
    this.unsupported,
    this.base = 1,
    this.awlTo = 0,
    this.awl = false,
    this.radd = false,
    this.unallocated = Frac.zero,
  });

  HeirShare? row(String key) {
    for (final r in rows) {
      if (r.key == key) return r;
    }
    return null;
  }

  /// نصيب الصنف كاملًا (صفر إن لم يوجد)
  Frac shareOf(String key) => row(key)?.share ?? Frac.zero;
  Frac eachOf(String key) => row(key)?.each ?? Frac.zero;
}

/// أسماء الأصناف (للعرض) — [n] العدد للإفراد/الجمع
String heirName(String key, [int n = 1]) {
  final many = n > 1;
  return switch (key) {
    'husband' => tr('الزوج', 'Husband'),
    'wife' => many ? tr('الزوجات', 'Wives') : tr('الزوجة', 'Wife'),
    'father' => tr('الأب', 'Father'),
    'mother' => tr('الأم', 'Mother'),
    'grandfather' => tr('الجد (أبو الأب)', 'Paternal grandfather'),
    'patGrandmother' => tr('الجدة (أم الأب)', 'Grandmother (father\'s mother)'),
    'matGrandmother' => tr('الجدة (أم الأم)', 'Grandmother (mother\'s mother)'),
    'sons' => many ? tr('الأبناء', 'Sons') : tr('الابن', 'Son'),
    'daughters' => many ? tr('البنات', 'Daughters') : tr('البنت', 'Daughter'),
    'sonsSons' => many ? tr('أبناء الابن', 'Son\'s sons') : tr('ابن الابن', 'Son\'s son'),
    'sonsDaughters' => many ? tr('بنات الابن', 'Son\'s daughters') : tr('بنت الابن', 'Son\'s daughter'),
    'fullBrothers' => many ? tr('الإخوة الأشقاء', 'Full brothers') : tr('الأخ الشقيق', 'Full brother'),
    'fullSisters' => many ? tr('الأخوات الشقيقات', 'Full sisters') : tr('الأخت الشقيقة', 'Full sister'),
    'patBrothers' => many ? tr('الإخوة لأب', 'Paternal half-brothers') : tr('الأخ لأب', 'Paternal half-brother'),
    'patSisters' => many ? tr('الأخوات لأب', 'Paternal half-sisters') : tr('الأخت لأب', 'Paternal half-sister'),
    'matSiblings' => many ? tr('الإخوة لأم', 'Maternal half-siblings') : tr('الأخ/الأخت لأم', 'Maternal half-sibling'),
    _ => key,
  };
}

String _blockedBy(String who) => tr('محجوب حجب حرمان بـ$who', 'Excluded (hajb) by: $who');

/// الحساب الرئيسي
InheritanceResult computeInheritance(Heirs h) {
  if (h.husband && h.wives > 0 || h.wives > 4 || [h.sons, h.daughters, h.sonsSons, h.sonsDaughters, h.fullBrothers, h.fullSisters, h.patBrothers, h.patSisters, h.matSiblings].any((x) => x < 0)) {
    return const InheritanceResult(unsupported: Unsupported.invalid);
  }
  if (!h.any) return const InheritanceResult(unsupported: Unsupported.noHeirs);

  final maleDesc = h.sons > 0 || h.sonsSons > 0;
  final femaleDesc = h.daughters > 0 || h.sonsDaughters > 0;
  final anyDesc = maleDesc || femaleDesc;
  final siblings = h.fullBrothers + h.fullSisters + h.patBrothers + h.patSisters + h.matSiblings;
  final effGF = h.grandfather && !h.father;
  final agnSiblings = h.fullBrothers + h.fullSisters + h.patBrothers + h.patSisters;

  // ── حالات غير مدعومة ──
  if (effGF && !maleDesc && agnSiblings > 0) {
    final akdariyya = h.husband &&
        h.mother &&
        h.fullSisters + h.patSisters == 1 &&
        h.fullBrothers + h.patBrothers == 0 &&
        !femaleDesc &&
        h.matSiblings == 0 &&
        h.wives == 0;
    return InheritanceResult(unsupported: akdariyya ? Unsupported.akdariyya : Unsupported.grandfatherSiblings);
  }
  final femaleAscSixth = h.mother || h.patGrandmother || h.matGrandmother;
  if (h.husband && femaleAscSixth && h.matSiblings >= 2 && h.fullBrothers >= 1 && !anyDesc && !h.father && !effGF) {
    return const InheritanceResult(unsupported: Unsupported.mushtaraka);
  }

  final rows = <HeirShare>[];
  HeirShare add(String key, int n, {int unit = 1}) {
    final r = HeirShare(key, n, unit: unit);
    rows.add(r);
    return r;
  }

  void fard(HeirShare r, Frac f, String term, String why) {
    r.fard = f;
    r.term = term;
    r.why = why;
  }

  void block(HeirShare r, String whoAr, String whoEn) {
    r.blocked = true;
    r.term = 'محجوب';
    r.why = _blockedBy(tr(whoAr, whoEn));
  }

  // ── الزوجان ──
  Frac spouseFard = Frac.zero;
  if (h.husband) {
    final r = add('husband', 1);
    anyDesc
        ? fard(r, Frac(1, 4), 'فرض: الربع', tr('الربع لوجود الفرع الوارث', '1/4 — the deceased has inheriting descendants'))
        : fard(r, Frac(1, 2), 'فرض: النصف', tr('النصف لعدم الفرع الوارث', '1/2 — no inheriting descendants'));
    spouseFard = r.fard!;
  }
  if (h.wives > 0) {
    final r = add('wife', h.wives);
    final shared = h.wives > 1 ? tr(' يشتركن فيه بالتساوي', ', shared equally') : '';
    anyDesc
        ? fard(r, Frac(1, 8), 'فرض: الثمن', tr('الثمن لوجود الفرع الوارث$shared', '1/8 — the deceased has inheriting descendants$shared'))
        : fard(r, Frac(1, 4), 'فرض: الربع', tr('الربع لعدم الفرع الوارث$shared', '1/4 — no inheriting descendants$shared'));
    spouseFard = r.fard!;
  }

  // ── الأب والجد ──
  void fatherLike(HeirShare r, String ar, String en) {
    if (maleDesc) {
      fard(r, Frac(1, 6), 'فرض: السدس', tr('السدس فرضًا لوجود الفرع الوارث المذكر', '1/6 — a male descendant exists'));
    } else if (femaleDesc) {
      fard(r, Frac(1, 6), 'فرض وتعصيب', tr('السدس فرضًا والباقي تعصيبًا لوجود فرع وارث مؤنث فقط', '1/6 fixed + residue (\'asaba) — only female descendants'));
      r.asaba = true;
    } else {
      r.asaba = true;
      r.term = 'تعصيب بالنفس';
      r.why = tr('يأخذ الباقي تعصيبًا لعدم الفرع الوارث', 'Takes the residue as \'asaba — no descendants');
    }
  }

  HeirShare? fatherRow, gfRow;
  if (h.father) {
    fatherRow = add('father', 1, unit: 2);
    fatherLike(fatherRow, 'الأب', 'father');
  }
  if (h.grandfather) {
    gfRow = add('grandfather', 1, unit: 2);
    if (h.father) {
      block(gfRow, 'الأب', 'the father');
    } else {
      fatherLike(gfRow, 'الجد', 'grandfather');
      gfRow.why += tr(' (الجد يقوم مقام الأب)', ' (grandfather stands in for the father)');
    }
  }

  // ── الأم ──
  if (h.mother) {
    final r = add('mother', 1);
    if (anyDesc) {
      fard(r, Frac(1, 6), 'فرض: السدس', tr('السدس لوجود الفرع الوارث', '1/6 — inheriting descendants exist'));
    } else if (siblings >= 2) {
      fard(r, Frac(1, 6), 'فرض: السدس', tr('السدس لوجود جمع من الإخوة (اثنان فأكثر)', '1/6 — two or more siblings exist'));
    } else if (h.father && (h.husband || h.wives > 0)) {
      fard(r, (Frac.one - spouseFard).div(3), 'ثلث الباقي (العُمَريّة)',
          tr('ثلث الباقي بعد فرض الزوج/الزوجة — إحدى العُمَريّتين', "1/3 of the remainder after the spouse — 'Umariyyatan case"));
    } else {
      fard(r, Frac(1, 3), 'فرض: الثلث', tr('الثلث لعدم الفرع الوارث وعدم جمع الإخوة', '1/3 — no descendants and fewer than two siblings'));
    }
  }

  // ── الجدات ──
  final gms = <HeirShare>[];
  if (h.patGrandmother) {
    final r = add('patGrandmother', 1);
    if (h.mother) {
      block(r, 'الأم', 'the mother');
    } else if (h.father) {
      block(r, 'الأب', 'the father');
    } else {
      gms.add(r);
    }
  }
  if (h.matGrandmother) {
    final r = add('matGrandmother', 1);
    if (h.mother) {
      block(r, 'الأم', 'the mother');
    } else {
      gms.add(r);
    }
  }
  for (final r in gms) {
    fard(r, Frac(1, 6).div(gms.length), 'فرض: السدس',
        gms.length > 1 ? tr('السدس تشترك فيه الجدتان بالتساوي لعدم الأم', '1/6 shared equally by both grandmothers — no mother') : tr('السدس لعدم الأم', '1/6 — no mother'));
  }

  // ── الأبناء والبنات ──
  HeirShare? sonsRow, daughtersRow, ssRow, sdRow;
  if (h.sons > 0) {
    sonsRow = add('sons', h.sons, unit: 2)
      ..asaba = true
      ..term = 'تعصيب بالنفس'
      ..why = h.daughters > 0
          ? tr('عصبة مع البنات: للذكر مثل حظ الأنثيين', '\'Asaba with daughters: male gets twice the female')
          : tr('يأخذون الباقي تعصيبًا', 'Take the residue as \'asaba');
  }
  if (h.daughters > 0) {
    daughtersRow = add('daughters', h.daughters);
    if (h.sons > 0) {
      daughtersRow
        ..asaba = true
        ..term = 'تعصيب بالغير'
        ..why = tr('عصبة بالابن: للذكر مثل حظ الأنثيين', '\'Asaba through the son: male gets twice the female');
    } else if (h.daughters == 1) {
      fard(daughtersRow, Frac(1, 2), 'فرض: النصف', tr('النصف لانفرادها وعدم المعصِّب', '1/2 — a single daughter with no son'));
    } else {
      fard(daughtersRow, Frac(2, 3), 'فرض: الثلثان', tr('الثلثان للبنتين فأكثر يقتسمنه بالتساوي', '2/3 — two or more daughters, shared equally'));
    }
  }
  if (h.sonsSons > 0) {
    ssRow = add('sonsSons', h.sonsSons, unit: 2);
    if (h.sons > 0) {
      block(ssRow, 'الابن', 'the son');
    } else {
      ssRow
        ..asaba = true
        ..term = 'تعصيب بالنفس'
        ..why = tr('يأخذون الباقي تعصيبًا (ابن الابن كالابن عند عدمه)', 'Take the residue as \'asaba (stand in for the son)');
    }
  }
  if (h.sonsDaughters > 0) {
    sdRow = add('sonsDaughters', h.sonsDaughters);
    if (h.sons > 0) {
      block(sdRow, 'الابن', 'the son');
    } else if (h.sonsSons > 0) {
      sdRow
        ..asaba = true
        ..term = 'تعصيب بالغير'
        ..why = tr('عصبة بابن الابن: للذكر مثل حظ الأنثيين', '\'Asaba with the son\'s son: male gets twice the female');
    } else if (h.daughters == 0) {
      h.sonsDaughters == 1
          ? fard(sdRow, Frac(1, 2), 'فرض: النصف', tr('النصف لانفرادها وعدم البنات', '1/2 — single, and no daughters'))
          : fard(sdRow, Frac(2, 3), 'فرض: الثلثان', tr('الثلثان لاثنتين فأكثر وعدم البنات', '2/3 — two or more, and no daughters'));
    } else if (h.daughters == 1) {
      fard(sdRow, Frac(1, 6), 'فرض: السدس تكملة الثلثين', tr('السدس تكملةً للثلثين مع البنت الواحدة', '1/6 completing 2/3 with one daughter'));
    } else {
      block(sdRow, 'البنتين فأكثر (استكملتا الثلثين)', 'two or more daughters (2/3 already complete)');
    }
  }

  // ── الإخوة والأخوات ──
  (String, String)? agnBlocker() {
    if (h.sons > 0) return ('الابن', 'the son');
    if (h.sonsSons > 0) return ('ابن الابن', 'the son\'s son');
    if (h.father) return ('الأب', 'the father');
    return null;
  }

  HeirShare? fbRow, fsRow, pbRow, psRow;
  var fsMaaGhayr = false, psMaaGhayr = false;
  final ab = agnBlocker();
  if (h.fullBrothers > 0) {
    fbRow = add('fullBrothers', h.fullBrothers, unit: 2);
    if (ab != null) {
      block(fbRow, ab.$1, ab.$2);
    } else {
      fbRow
        ..asaba = true
        ..term = 'تعصيب بالنفس'
        ..why = h.fullSisters > 0
            ? tr('عصبة مع الأخوات الشقيقات: للذكر مثل حظ الأنثيين', '\'Asaba with full sisters: male gets twice the female')
            : tr('يأخذون الباقي تعصيبًا', 'Take the residue as \'asaba');
    }
  }
  if (h.fullSisters > 0) {
    fsRow = add('fullSisters', h.fullSisters);
    if (ab != null) {
      block(fsRow, ab.$1, ab.$2);
    } else if (h.fullBrothers > 0) {
      fsRow
        ..asaba = true
        ..term = 'تعصيب بالغير'
        ..why = tr('عصبة بالأخ الشقيق: للذكر مثل حظ الأنثيين', '\'Asaba through the full brother: male gets twice the female');
    } else if (femaleDesc) {
      fsMaaGhayr = true;
      fsRow
        ..asaba = true
        ..term = 'تعصيب مع الغير'
        ..why = tr('عصبة مع البنات (الأخوات مع البنات عصبات) تأخذ الباقي', '\'Asaba ma\'a al-ghayr: sisters with daughters take the residue');
    } else {
      h.fullSisters == 1
          ? fard(fsRow, Frac(1, 2), 'فرض: النصف', tr('النصف لانفرادها وعدم الفرع الوارث والأصل الوارث المذكر والمعصِّب', '1/2 — single, no descendants, no father, no brother'))
          : fard(fsRow, Frac(2, 3), 'فرض: الثلثان', tr('الثلثان لاثنتين فأكثر يقتسمنه بالتساوي', '2/3 — two or more, shared equally'));
    }
  }
  if (h.patBrothers > 0) {
    pbRow = add('patBrothers', h.patBrothers, unit: 2);
    if (ab != null) {
      block(pbRow, ab.$1, ab.$2);
    } else if (h.fullBrothers > 0) {
      block(pbRow, 'الأخ الشقيق', 'the full brother');
    } else if (fsMaaGhayr) {
      block(pbRow, 'الأخت الشقيقة العاصبة مع البنات', 'the full sister (\'asaba with daughters)');
    } else {
      pbRow
        ..asaba = true
        ..term = 'تعصيب بالنفس'
        ..why = h.patSisters > 0
            ? tr('عصبة مع الأخوات لأب: للذكر مثل حظ الأنثيين', '\'Asaba with paternal sisters: male gets twice the female')
            : tr('يأخذون الباقي تعصيبًا', 'Take the residue as \'asaba');
    }
  }
  if (h.patSisters > 0) {
    psRow = add('patSisters', h.patSisters);
    if (ab != null) {
      block(psRow, ab.$1, ab.$2);
    } else if (h.fullBrothers > 0) {
      block(psRow, 'الأخ الشقيق', 'the full brother');
    } else if (fsMaaGhayr) {
      block(psRow, 'الأخت الشقيقة العاصبة مع البنات', 'the full sister (\'asaba with daughters)');
    } else if (h.patBrothers > 0) {
      psRow
        ..asaba = true
        ..term = 'تعصيب بالغير'
        ..why = tr('عصبة بالأخ لأب: للذكر مثل حظ الأنثيين', '\'Asaba through the paternal brother: male gets twice the female');
    } else if (h.fullSisters >= 2) {
      block(psRow, 'الأختين الشقيقتين (استكملتا الثلثين)', 'two full sisters (2/3 already complete)');
    } else if (femaleDesc) {
      psMaaGhayr = true;
      psRow
        ..asaba = true
        ..term = 'تعصيب مع الغير'
        ..why = tr('عصبة مع البنات تأخذ الباقي', '\'Asaba ma\'a al-ghayr: with daughters, takes the residue');
    } else if (h.fullSisters == 1) {
      fard(psRow, Frac(1, 6), 'فرض: السدس تكملة الثلثين', tr('السدس تكملةً للثلثين مع الأخت الشقيقة', '1/6 completing 2/3 with one full sister'));
    } else {
      h.patSisters == 1
          ? fard(psRow, Frac(1, 2), 'فرض: النصف', tr('النصف لانفرادها وعدم الحاجب والمعصِّب', '1/2 — single, no blocker, no brother'))
          : fard(psRow, Frac(2, 3), 'فرض: الثلثان', tr('الثلثان لاثنتين فأكثر', '2/3 — two or more'));
    }
  }
  if (h.matSiblings > 0) {
    final r = add('matSiblings', h.matSiblings);
    if (anyDesc) {
      block(r, 'الفرع الوارث', 'inheriting descendants');
    } else if (h.father) {
      block(r, 'الأب', 'the father');
    } else if (effGF) {
      block(r, 'الجد', 'the grandfather');
    } else if (h.matSiblings == 1) {
      fard(r, Frac(1, 6), 'فرض: السدس', tr('السدس لانفراده (الأخ/الأخت لأم)', '1/6 — a single maternal sibling'));
    } else {
      fard(r, Frac(1, 3), 'فرض: الثلث', tr('الثلث يقتسمونه بالتساوي ذكورًا وإناثًا', '1/3 shared equally, males and females alike'));
    }
  }

  // ── توزيع الفروض ──
  final fardRows = rows.where((r) => !r.blocked && r.fard != null).toList();
  var sum = Frac.zero;
  var base = 1;
  for (final r in fardRows) {
    sum = sum + r.fard!;
    base = _lcm(base, r.fard!.d);
  }
  final awl = sum > Frac.one;
  final awlTo = (sum.n * base) ~/ sum.d;
  for (final r in fardRows) {
    r.share = awl ? r.fard! / sum : r.fard!;
  }

  // ── التعصيب ──
  final groups = <List<HeirShare?>>[
    [sonsRow, if (daughtersRow?.asaba == true) daughtersRow],
    [ssRow?.blocked == false ? ssRow : null, if (sdRow?.asaba == true) sdRow],
    [fatherRow?.asaba == true ? fatherRow : null],
    [gfRow?.asaba == true ? gfRow : null],
    [fbRow?.blocked == false ? fbRow : null, if (fsRow?.asaba == true && !fsMaaGhayr) fsRow],
    [if (fsMaaGhayr) fsRow],
    [pbRow?.blocked == false ? pbRow : null, if (psRow?.asaba == true && !psMaaGhayr) psRow],
    [if (psMaaGhayr) psRow],
  ];
  List<HeirShare>? asabaGroup;
  for (final g in groups) {
    final m = g.whereType<HeirShare>().where((r) => !r.blocked).toList();
    if (m.isNotEmpty) {
      asabaGroup = m;
      break;
    }
  }
  final residue = awl ? Frac.zero : Frac.one - sum;
  var radd = false;
  var unallocated = Frac.zero;
  if (asabaGroup != null) {
    if (residue.isPositive) {
      final units = asabaGroup.fold<int>(0, (a, r) => a + r.unit * r.count);
      for (final r in asabaGroup) {
        r.share = r.share + residue.times(r.unit * r.count).div(units);
      }
    } else {
      for (final r in asabaGroup) {
        if (r.fard == null) r.why += tr(' — لم يبقَ شيء بعد أصحاب الفروض', ' — nothing remains after the fixed shares');
      }
    }
    // أي عاصب آخر لم يصله شيء
    for (final r in rows) {
      if (r.asaba && r.fard == null && !asabaGroup.contains(r) && !r.blocked) {
        r.blocked = true;
        r.term = 'محجوب';
        r.why = _blockedBy(tr('عصبة أقرب', 'a closer \'asaba'));
      }
    }
  } else if (residue.isPositive) {
    final nonSpouse = fardRows.where((r) => !r.isSpouse).toList();
    if (nonSpouse.isNotEmpty) {
      radd = true;
      final s = nonSpouse.fold<Frac>(Frac.zero, (a, r) => a + r.fard!);
      final avail = Frac.one - spouseFard;
      for (final r in nonSpouse) {
        r.share = avail * r.fard! / s;
        r.term += ' + ردّ';
        r.why += tr(' — ويُردّ عليه الباقي بنسبة فرضه', ' — plus radd: the surplus returned in proportion to the share');
      }
    } else {
      unallocated = residue;
    }
  }

  return InheritanceResult(rows: rows, base: base, awlTo: awlTo, awl: awl, radd: radd, unallocated: unallocated);
}

/// صافي التركة القابل للقسمة: بعد التجهيز والديون، ثم الوصية بحد أقصى الثلث
({double net, double bequest, bool capped}) netEstate(double estate, double funeral, double debts, double wasiyya) {
  final afterDebts = (estate - funeral - debts).clamp(0, double.infinity).toDouble();
  final cap = afterDebts / 3;
  final b = wasiyya.clamp(0, cap).toDouble();
  return (net: afterDebts - b, bequest: b, capped: wasiyya > cap + 1e-9);
}
