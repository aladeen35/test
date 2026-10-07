import 'dart:math' as math;
import '../more/khatma_data.dart';

/// منطق خطة حفظ القرآن (مصحف المدينة 604 صفحة، 15 سطرًا للصفحة)

const hifzLinesPerPage = 15;

/// صفحة بداية كل جزء في مصحف المدينة (604 صفحات) — الجزء 11 يبدأ من الصفحة 201
const hifzJuzStarts = [
  1, 22, 42, 62, 82, 102, 121, 142, 162, 182, 201, 222, 242, 262, 282,
  302, 322, 342, 362, 382, 402, 422, 442, 462, 482, 502, 522, 542, 562, 582,
];

int hJuzStart(int j) => hifzJuzStarts[j.clamp(1, 30) - 1];

/// الجزء الذي تقع فيه الصفحة
int hJuzOf(int page) {
  var j = 1;
  for (var i = 0; i < 30; i++) {
    if (hifzJuzStarts[i] <= page) j = i + 1;
  }
  return j;
}

int juzEndPage(int j) => j >= 30 ? quranPages : hJuzStart(j + 1) - 1;
int juzPageCount(int j) => juzEndPage(j) - hJuzStart(j) + 1;

/// آخر صفحة تمسّها السورة (رقمها من 0): صفحة بداية السورة التالية لأنها غالبًا تبدأ في منتصف الصفحة
int surahEndPage(int i) => i >= 113 ? quranPages : math.max(surahStartPage[i], surahStartPage[i + 1]);

/// ترتيب صفحات الحفظ كاملًا (604 صفحة بلا تكرار):
/// للأمام: من السورة [startSurah] حتى الناس ثم من الفاتحة.
/// للخلف: سورة سورة من [startSurah] نحو الفاتحة (كل سورة تُحفظ من أولها) ثم يكمل من الناس.
List<int> hifzSequence(int startSurah, bool forward) {
  final s = startSurah.clamp(0, 113);
  final order = <int>[];
  if (forward) {
    for (var i = s; i < 114; i++) {
      order.add(i);
    }
    for (var i = 0; i < s; i++) {
      order.add(i);
    }
  } else {
    for (var i = s; i >= 0; i--) {
      order.add(i);
    }
    for (var i = 113; i > s; i--) {
      order.add(i);
    }
  }
  final seen = <int>{};
  final out = <int>[];
  for (final i in order) {
    for (var p = surahStartPage[i]; p <= surahEndPage(i); p++) {
      if (seen.add(p)) out.add(p);
    }
  }
  for (var p = 1; p <= quranPages; p++) {
    if (seen.add(p)) out.add(p);
  }
  return out;
}

/// جزء من ورد: صفحة وأسطر
class PortionPart {
  final int page, from, to;
  const PortionPart(this.page, this.from, this.to);
  bool get fullPage => from == 1 && to == hifzLinesPerPage;
}

/// الورد القادم بطول [lines] سطرًا ابتداءً من أول صفحة غير محفوظة في الترتيب
List<PortionPart> nextPortion(List<int> seq, Set<int> memorized, int partial, int lines) {
  final out = <PortionPart>[];
  var left = lines;
  var startLine = partial.clamp(0, hifzLinesPerPage - 1) + 1;
  for (final p in seq) {
    if (left <= 0) break;
    if (memorized.contains(p)) continue;
    final avail = hifzLinesPerPage - startLine + 1;
    final take = math.min(avail, left);
    out.add(PortionPart(p, startLine, startLine + take - 1));
    left -= take;
    startLine = 1;
  }
  return out;
}

/// نتيجة تطبيق ورد: الصفحات المكتملة والأسطر الجزئية الجديدة
({List<int> completed, int partial}) applyPortion(List<PortionPart> parts) {
  final done = <int>[];
  var partial = 0;
  for (final x in parts) {
    if (x.to >= hifzLinesPerPage) {
      done.add(x.page);
      partial = 0;
    } else {
      partial = x.to;
    }
  }
  return (completed: done, partial: partial);
}

/// خطة المراجعة ليوم معيّن
class ReviewPlan {
  /// صفحات الحفظ القريب (تُراجع يوميًا)
  final List<int> recent;

  /// نصيب اليوم من المحفوظ القديم (دوري)
  final List<int> old;

  /// طول دورة مراجعة القديم بالأيام، ورقم يوم اليوم في الدورة (من 1)
  final int cycleDays, dayInCycle, oldTotal;
  const ReviewPlan(this.recent, this.old, this.cycleDays, this.dayInCycle, this.oldTotal);
}

/// [memDates]: صفحة ← تاريخ حفظها (yyyy-mm-dd). القريب: ما حُفظ في آخر [recentDays] يومًا (بحد [recentMax] صفحة).
ReviewPlan reviewFor(Map<int, DateTime> memDates, DateTime day, {int recentDays = 7, int recentMax = 20, int perDay = 10}) {
  final d0 = DateTime.utc(day.year, day.month, day.day);
  final entries = memDates.entries.toList()
    ..sort((a, b) {
      final c = b.value.compareTo(a.value);
      return c != 0 ? c : b.key.compareTo(a.key);
    });
  final recent = <int>[];
  for (final e in entries) {
    final age = d0.difference(DateTime.utc(e.value.year, e.value.month, e.value.day)).inDays;
    if (age >= 0 && age < recentDays && recent.length < recentMax) recent.add(e.key);
  }
  final old = memDates.keys.where((p) => !recent.contains(p)).toList()..sort();
  final per = math.max(1, perDay);
  if (old.isEmpty) return ReviewPlan(recent..sort(), const [], 0, 0, 0);
  final cycle = (old.length / per).ceil();
  final idx = (d0.millisecondsSinceEpoch ~/ 86400000) % cycle;
  final chunk = old.sublist(idx * per, math.min(old.length, idx * per + per));
  return ReviewPlan(recent..sort(), chunk, cycle, idx + 1, old.length);
}

/// يضغط قائمة صفحات إلى نطاقات مجمّعة بالجزء: [(جزء، من، إلى)]
List<(int, int, int)> pageRanges(List<int> pages) {
  final s = pages.toSet().toList()..sort();
  final out = <(int, int, int)>[];
  for (final p in s) {
    final j = hJuzOf(p);
    if (out.isNotEmpty && out.last.$1 == j && out.last.$3 == p - 1) {
      out[out.length - 1] = (j, out.last.$2, p);
    } else {
      out.add((j, p, p));
    }
  }
  return out;
}

/// عدد الأيام المتتالية التي سُجّل فيها ورد حتى [today] (أو حتى أمس إن لم يُسجّل اليوم)
int hifzStreak(Set<String> days, DateTime today, String Function(DateTime) key) {
  var d = today;
  if (!days.contains(key(d))) d = DateTime(d.year, d.month, d.day - 1);
  var n = 0;
  while (days.contains(key(d))) {
    n++;
    d = DateTime(d.year, d.month, d.day - 1);
  }
  return n;
}

/// الأيام المتبقية لإكمال الحفظ (بأيام الحفظ الفعلية في الأسبوع)
int hifzDaysLeft(int memorizedPages, int partial, double linesPerDay, int daysPerWeek) {
  final remaining = (quranPages - memorizedPages) * hifzLinesPerPage - partial;
  if (remaining <= 0) return 0;
  if (linesPerDay <= 0) return -1;
  final studyDays = (remaining / linesPerDay).ceil();
  final dpw = daysPerWeek.clamp(1, 7);
  return (studyDays * 7 / dpw).ceil();
}
