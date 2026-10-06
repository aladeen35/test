import 'package:flutter/material.dart';
import '../../core/i18n.dart';
import '../../core/theme.dart';

/// تصنيف عبارات
class PhraseCat {
  final String key, emoji, sd, ar, en;
  final IconData icon;
  final Color color;
  const PhraseCat(this.key, this.emoji, this.sd, this.ar, this.en, this.icon, this.color);
  String get name => t(sd, ar, en);
}

/// عبارة: سوداني، فصحى، إنجليزي
class Phrase {
  final String cat, sd, ar, en;
  final int i;
  const Phrase(this.cat, this.i, this.sd, this.ar, this.en);
  String get id => '${cat}_$i';
}

const phraseCats = [
  PhraseCat('travel', '✈️', 'المطار والسفر', 'المطار والسفر', 'Airport & travel', Icons.flight_takeoff_rounded, SD.nile),
  PhraseCat('health', '🏥', 'المستشفى والصيدلية', 'المستشفى والصيدلية', 'Hospital & pharmacy', Icons.local_hospital_rounded, SD.red),
  PhraseCat('work', '💼', 'الشغل', 'العمل', 'At work', Icons.work_rounded, SD.coffee),
  PhraseCat('bank', '🏦', 'البنك والتحويل', 'البنك والتحويلات', 'Bank & transfers', Icons.account_balance_rounded, SD.green),
  PhraseCat('shop', '🛒', 'السوق والشراء', 'التسوّق', 'Shopping', Icons.shopping_bag_rounded, SD.orange),
  PhraseCat('sos', '🚨', 'البوليس والطوارئ', 'الشرطة والطوارئ', 'Police & emergency', Icons.local_police_rounded, SD.henna),
  PhraseCat('home', '🏠', 'السكن', 'السكن', 'Housing', Icons.apartment_rounded, SD.indigo),
  PhraseCat('greet', '🤝', 'التحية والأدب', 'التحية والمجاملة', 'Greetings & courtesy', Icons.waving_hand_rounded, SD.teal),
];

List<Phrase> _make(String cat, List<(String, String, String)> l) => [for (var i = 0; i < l.length; i++) Phrase(cat, i, l[i].$1, l[i].$2, l[i].$3)];

final List<Phrase> phrases = [
  ..._make('travel', const [
    ('وين كاونتر الوزن؟', 'أين مكتب تسجيل الأمتعة؟', 'Where is the check-in counter?'),
    ('الطيارة بتقوم متين؟', 'متى تُقلع الطائرة؟', 'What time does the flight leave?'),
    ('شنطتي ضاعت', 'فُقدت حقيبتي', 'My luggage is lost.'),
    ('دا جوازي ودي تذكرتي', 'هذا جواز سفري وهذه تذكرتي', 'Here are my passport and ticket.'),
    ('البوابة رقم كم؟', 'ما رقم البوابة؟', 'Which gate is it?'),
    ('داير مقعد جنب الشباك', 'أريد مقعدًا بجانب النافذة', 'I\'d like a window seat, please.'),
    ('الرحلة اتأخرت؟', 'هل تأخرت الرحلة؟', 'Is the flight delayed?'),
    ('وين أستلم العفش؟', 'أين أستلم الأمتعة؟', 'Where do I collect my baggage?'),
    ('أنا ترانزيت ماشي على…', 'أنا في رحلة عبور إلى…', 'I\'m in transit to…'),
    ('داير تاكسي للفندق', 'أريد سيارة أجرة إلى الفندق', 'I need a taxi to the hotel.'),
    ('المشوار دا بكم؟', 'كم أجرة هذا المشوار؟', 'How much is the fare?'),
    ('ما عندي حاجة أعلن عنها', 'ليس لديّ ما أُصرّح به', 'I have nothing to declare.'),
    ('جاي هنا للشغل', 'جئت إلى هنا للعمل', 'I\'m here for work.'),
    ('حاقعد أسبوعين', 'سأبقى أسبوعين', 'I\'ll be staying for two weeks.'),
    ('وين محل الصرافة؟', 'أين مكتب الصرافة؟', 'Where can I exchange money?'),
    ('ممكن توريني الطريق في الخريطة؟', 'هل يمكنك أن تريني الطريق على الخريطة؟', 'Could you show me the way on the map?'),
    ('الوزن الزايد بكم؟', 'كم رسوم الوزن الزائد؟', 'How much is the excess baggage fee?'),
  ]),
  ..._make('health', const [
    ('أنا عيان', 'أنا مريض', 'I\'m not feeling well.'),
    ('راسي واجعني', 'عندي صداع', 'I have a headache.'),
    ('عندي سخانة', 'عندي حُمّى', 'I have a fever.'),
    ('بطني بتوجعني', 'أشعر بألم في بطني', 'I have a stomach ache.'),
    ('عندي حساسية من البنسلين', 'لديّ حساسية من البنسلين', 'I\'m allergic to penicillin.'),
    ('عندي سكري', 'أنا مصاب بالسكري', 'I have diabetes.'),
    ('عندي ضغط', 'أعاني من ارتفاع ضغط الدم', 'I have high blood pressure.'),
    ('داير أشوف دكتور', 'أريد مقابلة طبيب', 'I need to see a doctor.'),
    ('الدوا دا بيتشرب كيف؟', 'كيف أتناول هذا الدواء؟', 'How should I take this medicine?'),
    ('كم مرة في اليوم؟', 'كم مرة في اليوم؟', 'How many times a day?'),
    ('قبل الأكل ولا بعدو؟', 'قبل الأكل أم بعده؟', 'Before or after meals?'),
    ('بتقبلوا التأمين دا؟', 'هل تقبلون هذا التأمين؟', 'Do you accept this insurance?'),
    ('محتاج روشتة؟', 'هل أحتاج إلى وصفة طبية؟', 'Do I need a prescription?'),
    ('الوجع بدا من يومين', 'بدأ الألم منذ يومين', 'The pain started two days ago.'),
    ('وين الطوارئ؟', 'أين قسم الطوارئ؟', 'Where is the emergency room?'),
    ('عندك دوا للكحة؟', 'هل لديك دواء للسعال؟', 'Do you have anything for a cough?'),
    ('داير ورقة إجازة مرضية', 'أحتاج تقريرًا بإجازة مرضية', 'I need a sick note for work.'),
  ]),
  ..._make('work', const [
    ('أنا الموظف الجديد', 'أنا الموظف الجديد', 'I\'m the new employee.'),
    ('الدوام بيبدا متين؟', 'متى يبدأ الدوام؟', 'What time does the shift start?'),
    ('ممكن تشرح لي تاني؟', 'هل يمكنك أن تشرح لي مرة أخرى؟', 'Could you explain that again?'),
    ('ما فهمت، ممكن تتكلم بشويش؟', 'لم أفهم، هل يمكنك التحدث ببطء؟', 'Sorry, I didn\'t catch that. Could you speak more slowly?'),
    ('الشغل دا لازم يخلص متين؟', 'متى يجب أن يُنجز هذا العمل؟', 'When is this due?'),
    ('داير إجازة يوم الخميس', 'أريد إجازة يوم الخميس', 'I\'d like to take Thursday off.'),
    ('الماهية بتنزل متين؟', 'متى يُصرف الراتب؟', 'When is payday?'),
    ('حأتأخر شوية الليلة', 'سأتأخر قليلًا اليوم', 'I\'ll be a little late today.'),
    ('أنا عيان وما حأقدر أجي', 'أنا مريض ولن أستطيع الحضور', 'I\'m sick and can\'t come in today.'),
    ('خلّصت الشغل', 'أنهيت العمل', 'I\'ve finished the task.'),
    ('محتاج مساعدة في الحتة دي', 'أحتاج مساعدة في هذا الجزء', 'I need some help with this part.'),
    ('الساعات الإضافية بتتحسب كيف؟', 'كيف تُحتسب الساعات الإضافية؟', 'How is overtime paid?'),
    ('ممكن آخد نسخة من عقدي؟', 'هل يمكنني الحصول على نسخة من عقدي؟', 'Can I get a copy of my contract?'),
    ('الاجتماع متين؟', 'متى الاجتماع؟', 'When is the meeting?'),
    ('شكراً على المساعدة', 'شكرًا على مساعدتك', 'Thanks for your help.'),
    ('أرسلها ليك بالإيميل؟', 'هل أرسلها إليك بالبريد الإلكتروني؟', 'Shall I email it to you?'),
  ]),
  ..._make('bank', const [
    ('داير أفتح حساب', 'أريد فتح حساب', 'I\'d like to open an account.'),
    ('داير أحوّل قروش للسودان', 'أريد تحويل مبلغ إلى السودان', 'I want to send money to Sudan.'),
    ('سعر الصرف كم الليلة؟', 'كم سعر الصرف اليوم؟', 'What\'s today\'s exchange rate?'),
    ('الرسوم كم؟', 'كم الرسوم؟', 'What are the fees?'),
    ('التحويل بياخد قدر شنو؟', 'كم يستغرق التحويل؟', 'How long does the transfer take?'),
    ('الصراف بلع بطاقتي', 'ابتلع الصراف الآلي بطاقتي', 'The ATM kept my card.'),
    ('داير كشف حساب', 'أريد كشف حساب', 'I need a bank statement.'),
    ('نسيت الرقم السري', 'نسيت الرقم السري', 'I forgot my PIN.'),
    ('داير أوقف البطاقة، اتسرقت', 'أريد إيقاف البطاقة فقد سُرقت', 'Please block my card — it was stolen.'),
    ('اسم المستلم…', 'اسم المستفيد…', 'The recipient\'s name is…'),
    ('ممكن رقم الحوالة؟', 'هل يمكنني الحصول على رقم الحوالة؟', 'Can I have the transfer reference number?'),
    ('داير أصرف دولار', 'أريد صرف دولارات', 'I\'d like to exchange some dollars.'),
    ('في حد أعلى للتحويل؟', 'هل يوجد حد أعلى للتحويل؟', 'Is there a transfer limit?'),
    ('القروش لسه ما وصلت', 'لم يصل المبلغ بعد', 'The money hasn\'t arrived yet.'),
    ('داير أدفع الفاتورة دي', 'أريد سداد هذه الفاتورة', 'I\'d like to pay this bill.'),
    ('محتاج إيصال', 'أحتاج إلى إيصال', 'Can I have a receipt, please?'),
  ]),
  ..._make('shop', const [
    ('دا بكم؟', 'بكم هذا؟', 'How much is this?'),
    ('غالي شديد', 'هذا غالٍ جدًا', 'That\'s too expensive.'),
    ('ممكن تنقّص شوية؟', 'هل يمكنك تخفيض السعر قليلًا؟', 'Can you do a better price?'),
    ('عندك مقاس أكبر؟', 'هل لديك مقاس أكبر؟', 'Do you have this in a bigger size?'),
    ('ممكن أجرّبو؟', 'هل يمكنني تجربته؟', 'Can I try it on?'),
    ('داير دا', 'أريد هذا', 'I\'ll take this one.'),
    ('بتقبلوا البطاقة؟', 'هل تقبلون الدفع بالبطاقة؟', 'Do you take cards?'),
    ('ممكن كيس؟', 'هل يمكنني الحصول على كيس؟', 'Could I have a bag?'),
    ('لو ما نفع ممكن أرجّعو؟', 'هل يمكنني إرجاعه إن لم يناسبني؟', 'Can I return it if it doesn\'t fit?'),
    ('وين ألقى الرز؟', 'أين أجد الأرز؟', 'Where can I find the rice?'),
    ('عندكم توصيل؟', 'هل لديكم خدمة توصيل؟', 'Do you deliver?'),
    ('بتقفلوا متين؟', 'متى تُغلقون؟', 'What time do you close?'),
    ('داير كيلو لحمة', 'أريد كيلو لحم', 'I\'d like a kilo of meat.'),
    ('دا طازة؟', 'هل هذا طازج؟', 'Is this fresh?'),
    ('الباقي غلط', 'الباقي غير صحيح', 'I think the change is wrong.'),
    ('بس بتفرّج، شكراً', 'أتفرّج فقط، شكرًا', 'I\'m just looking, thanks.'),
  ]),
  ..._make('sos', const [
    ('ألحقوني!', 'النجدة!', 'Help!'),
    ('أطلبوا الإسعاف', 'اتصلوا بالإسعاف', 'Call an ambulance!'),
    ('في حريقة!', 'يوجد حريق!', 'There\'s a fire!'),
    ('اتسرقت', 'تعرّضت للسرقة', 'I\'ve been robbed.'),
    ('جوازي ضاع', 'فقدت جواز سفري', 'I\'ve lost my passport.'),
    ('حصل حادث', 'وقع حادث', 'There\'s been an accident.'),
    ('في زول متعوّر', 'يوجد شخص مصاب', 'Someone is hurt.'),
    ('وين أقرب قسم بوليس؟', 'أين أقرب مركز شرطة؟', 'Where is the nearest police station?'),
    ('داير أفتح بلاغ', 'أريد تقديم بلاغ', 'I want to file a report.'),
    ('محتاج مترجم', 'أحتاج إلى مترجم', 'I need an interpreter.'),
    ('داير أتصل بسفارتي', 'أريد الاتصال بسفارتي', 'I want to contact my embassy.'),
    ('أنا تايه', 'أنا تائه', 'I\'m lost.'),
    ('ولدي ضاع', 'فُقد ابني', 'My child is missing.'),
    ('ما عملت أي حاجة غلط', 'لم أرتكب أي خطأ', 'I haven\'t done anything wrong.'),
    ('أنا من السودان', 'أنا من السودان', 'I\'m from Sudan.'),
    ('دي إقامتي', 'هذه إقامتي', 'Here is my residence permit.'),
  ]),
  ..._make('home', const [
    ('في شقة للإيجار؟', 'هل توجد شقة للإيجار؟', 'Do you have an apartment for rent?'),
    ('الإيجار كم في الشهر؟', 'كم الإيجار الشهري؟', 'How much is the rent per month?'),
    ('الكهربا والموية مع الإيجار؟', 'هل الكهرباء والماء ضمن الإيجار؟', 'Are utilities included?'),
    ('التأمين كم؟', 'كم مبلغ التأمين؟', 'How much is the deposit?'),
    ('ممكن أشوف الشقة؟', 'هل يمكنني رؤية الشقة؟', 'Can I see the apartment?'),
    ('المكيّف خربان', 'المكيّف معطّل', 'The air conditioner isn\'t working.'),
    ('في موية نازلة', 'يوجد تسرّب ماء', 'There\'s a water leak.'),
    ('الكهربا قاطعة', 'الكهرباء مقطوعة', 'The power is out.'),
    ('متين بتجي تصلّحو؟', 'متى ستأتي لإصلاحه؟', 'When can you come to fix it?'),
    ('العقد لكم سنة؟', 'ما مدة العقد؟', 'How long is the lease?'),
    ('الدفع كل شهر ولا كل تلاتة شهور؟', 'هل الدفع شهري أم كل ثلاثة أشهر؟', 'Do I pay monthly or every three months?'),
    ('داير أطلع من الشقة الشهر الجاي', 'أريد إخلاء الشقة الشهر القادم', 'I\'d like to move out next month.'),
    ('الجيران مزعجين شديد', 'الجيران مزعجون جدًا', 'The neighbors are very noisy.'),
    ('المفتاح ضاع مني', 'فقدت المفتاح', 'I\'ve lost my key.'),
    ('في موقف للعربية؟', 'هل يوجد موقف للسيارة؟', 'Is there parking?'),
    ('ممكن ترجّع لي التأمين؟', 'هل يمكن إعادة مبلغ التأمين؟', 'Can I get my deposit back?'),
  ]),
  ..._make('greet', const [
    ('السلام عليكم', 'السلام عليكم', 'Hello (peace be upon you).'),
    ('صباح الخير', 'صباح الخير', 'Good morning.'),
    ('مساء الخير', 'مساء الخير', 'Good evening.'),
    ('كيفك؟ إن شاء الله تمام', 'كيف حالك؟', 'How are you?'),
    ('الحمد لله، كويس', 'بخير والحمد لله', 'I\'m fine, thanks.'),
    ('اسمي…', 'اسمي…', 'My name is…'),
    ('اتشرّفنا', 'تشرّفنا', 'Nice to meet you.'),
    ('شكراً كتير', 'شكرًا جزيلًا', 'Thank you very much.'),
    ('العفو', 'عفوًا', 'You\'re welcome.'),
    ('معليش', 'آسف', 'Sorry.'),
    ('لو سمحت', 'من فضلك', 'Excuse me, please.'),
    ('ما في مشكلة', 'لا مشكلة', 'No problem.'),
    ('بتتكلم عربي؟', 'هل تتحدث العربية؟', 'Do you speak Arabic?'),
    ('إنجليزيتي ضعيفة شوية', 'لغتي الإنجليزية ضعيفة قليلًا', 'My English isn\'t very good.'),
    ('مع السلامة', 'مع السلامة', 'Goodbye.'),
    ('أشوفك بكرة', 'أراك غدًا', 'See you tomorrow.'),
    ('الله يسلمك', 'بارك الله فيك', 'God bless you.'),
  ]),
];
