# سياسة الخصوصية — فول مارك

**التطبيق:** فول مارك (Full Mark) — `com.albushra.fullmark`
**الناشر:** البشرى للتكنولوجيا (Al-Bushra Technology)
**تاريخ السريان:** 1 أكتوبر 2026
**للتواصل:** Aladeen35@gmail.com

> [English version below](#privacy-policy--full-mark)

---

## الخلاصة في سطور

- لا نطلب منك حسابًا ولا تسجيلًا.
- لا إعلانات، ولا تحليلات، ولا تتبّع.
- نتائجك وأسماؤك وإعداداتك محفوظة **على جهازك فقط**.
- لا نشغّل خوادم تخزّن بياناتك، ولا نجمع بيانات شخصية عنك.
- بعض الميزات الاختيارية ترسل بيانات محدودة خارج جهازك، وهي: **المساعد الذكي**، و**اللعب أونلاين**، و**البلوتوث**. التفاصيل أدناه.

---

## 1. البيانات المحفوظة على جهازك فقط

يحفظ التطبيق في التخزين المحلي على جهازك:
- أسماء اللاعبين التي تدخلها مرة واحدة.
- النتائج، لوحة الصدارة، منحنيات النتائج مع التواريخ، متوسطات المستويات، والسجل الكامل.
- الإعدادات (مثل الثيم والأصوات).
- الأسئلة التي ظهرت لك، حتى لا تتكرر قبل انتهاء بنك الأسئلة.

هذه البيانات **لا تُرسل إلينا ولا إلى أي جهة**. ميزة النسخ الاحتياطي تُنشئ ملف JSON على جهازك، وميزة الاستيراد تقرأ ملفًا تختاره أنت؛ ولا يُرفع أي منهما إلى الإنترنت.

## 2. المساعد الذكي (اختياري)

في المستوى الصعب يمكنك استخدام وسيلة «المساعد الذكي» لتحصل على تلميح، بالكتابة أو بالصوت.

**ما الذي يُرسل؟** عند استخدامه فقط، يُرسل:
- نص السؤال الحالي وخيارات الإجابة.
- الرسالة التي كتبتها أو قلتها (بعد تحويلها إلى نص)، مع رسائلك وردود المساعد السابقة في محادثة التلميح نفسها حتى يفهم السياق.

**إلى أين؟** إلى إحدى خدمتين:
- **خدمة Puter.com المجانية للذكاء الاصطناعي** — تخضع لسياسة خصوصية Puter: https://puter.com/privacy
- أو **خادم وسيط (proxy) اختياري يشغّله المطوّر**، يمرّر الطلب إلى **Claude API من شركة Anthropic** ثم يعيد الرد. الخادم الوسيط لا يحفظ محتوى الطلبات. تخضع معالجة Anthropic لسياستها: https://www.anthropic.com/legal/privacy

**نصيحة:** لا تكتب في رسالتك للمساعد أي معلومات شخصية (اسمك الكامل، رقمك، عنوانك…)؛ فهو يحتاج فقط إلى سؤالك عن المسابقة.

**الإبلاغ عن الردود:** يمكنك الإبلاغ عن أي رد غير مناسب من المساعد بزر «الإبلاغ عن الرد» داخل التطبيق. يفتح الزر تطبيق البريد في جهازك برسالة جاهزة إلى Aladeen35@gmail.com تتضمن الرد المُبلَّغ عنه، ولا تُرسل إلا إذا ضغطت أنت «إرسال». نستخدم البلاغات فقط لتحسين المساعد، ولا نستخدم عنوان بريدك لأي غرض آخر.

**الإدخال الصوتي:** عند الضغط على زر الميكروفون، يستخدم التطبيق **خدمة التعرّف على الكلام الموجودة في نظام جهازك** لتحويل كلامك إلى نص. التطبيق لا يسجّل ملفات صوتية ولا يحفظ صوتك ولا يرسله إلينا؛ يستلم النص فقط ويرسله إلى المساعد كما في الرسالة المكتوبة. معالجة الصوت داخل خدمة النظام تخضع لسياسة مزوّد تلك الخدمة (مثل Google). لا يُستخدم الميكروفون إلا عندما تضغط على زر الميكروفون.

إذا لم تستخدم المساعد الذكي، فلا يُرسل أي شيء من ذلك.

## 3. اللعب أونلاين (اختياري)

عند اللعب أونلاين بين جهازين برمز الغرفة المكوّن من 5 أرقام، أو في غرفة العائلة:
- يتبادل جهازك مع أجهزة اللاعبين الآخرين **الاسم المستعار، وإجابات اللعبة، وحالة اللعبة** فقط.
- يتم التبادل **مباشرة بين الأجهزة** عبر تقنية **PeerJS (WebRTC)** باتصال مشفّر.
- يُستخدم **خادم الإشارة العام لـ PeerJS (0.peerjs.com)** فقط لربط الأجهزة ببعضها في البداية (بيانات اتصال تقنية مثل معرّف جلسة عشوائي وعنوان الشبكة). لا يُستخدم لتخزين بيانات اللعبة.
- **لا توجد دردشة** بين اللاعبين، ولا تبادل صور أو صوت.
- **نحن لا نشغّل أي خادم للعب أونلاين ولا نخزّن شيئًا.**

## 4. البلوتوث (اختياري)

يُستخدم البلوتوث فقط لربط جوالين قريبين للعب بدون إنترنت، ويتبادلان الاسم المستعار وإجابات اللعبة وحالتها. لا نستخدم البلوتوث لتحديد موقعك ولا لأي غرض آخر.

## 5. الصلاحيات ولماذا نحتاجها

| الصلاحية | الاستخدام |
|---|---|
| الإنترنت (INTERNET) | المساعد الذكي واللعب أونلاين. |
| الأجهزة القريبة (BLUETOOTH_CONNECT) — Android 12 فأحدث | الاتصال بجوال قريب للعب عبر البلوتوث. |
| BLUETOOTH و BLUETOOTH_ADMIN — Android 11 فأقدم | نفس الغرض في الإصدارات القديمة من Android. |
| الميكروفون (RECORD_AUDIO) — اختيارية | سؤال المساعد الذكي بالصوت، فقط عند الضغط على زر الميكروفون. |
| الاهتزاز (VIBRATE) | اهتزاز الاحتفال عند الفوز. |

يمكنك رفض صلاحية الميكروفون أو البلوتوث، وستعمل بقية اللعبة بشكل طبيعي.

## 6. ما الذي لا نفعله

- لا نجمع اسمك الحقيقي أو بريدك أو رقمك أو موقعك أو جهات اتصالك.
- لا نستخدم أدوات تحليلات أو تتبّع أو تقارير أعطال من أطراف خارجية.
- لا نعرض إعلانات ولا نستخدم معرّف الإعلانات.
- لا نبيع أي بيانات ولا نشاركها لأغراض تسويقية.

## 7. الاحتفاظ بالبيانات وحذفها

- بياناتك على جهازك تبقى حتى تحذفها أنت.
- **لحذفها:** استخدم زر «مسح السجلات» داخل التطبيق، أو احذف التطبيق من جهازك (يؤدي ذلك لحذف كل بياناته).
- نحن لا نحتفظ بأي بيانات عنك على خوادمنا، فلا يوجد ما نحذفه من جهتنا. أما ما يُرسل إلى Puter أو Anthropic عبر المساعد الذكي فيخضع لسياسات الاحتفاظ لديهما.
- لأي طلب أو استفسار عن بياناتك راسلنا على: Aladeen35@gmail.com

## 8. الأمان

كل اتصال يخرج من التطبيق مشفّر: خدمات الذكاء الاصطناعي عبر HTTPS، واللعب أونلاين عبر اتصال WebRTC المشفّر، وخادم الإشارة عبر اتصال آمن.

## 9. الأطفال

التطبيق موجّه لمن هم في **13 سنة فأكثر**، ويمكن للعائلة أن تلعب معًا على جهاز أحد الوالدين. لا نجمع عن قصد أي بيانات شخصية من الأطفال دون 13 سنة. ننصح الوالدين بالإشراف على استخدام الأطفال لميزتي المساعد الذكي واللعب أونلاين. إذا علمت أن طفلًا أرسل معلومات شخصية عبر المساعد الذكي، فراسلنا على Aladeen35@gmail.com وسنساعدك في التواصل مع الجهة المعنية.

## 10. التغييرات على هذه السياسة

قد نحدّث هذه السياسة عند تغيير ميزات التطبيق. سننشر النسخة الجديدة في الرابط نفسه مع تحديث تاريخ السريان. إذا كان التغيير جوهريًا فسنوضّحه في ملاحظات التحديث على المتجر.

## 11. تواصل معنا

البشرى للتكنولوجيا — Aladeen35@gmail.com

---
---

# Privacy Policy — Full Mark

**App:** Full Mark (فول مارك) — `com.albushra.fullmark`
**Publisher:** Al-Bushra Technology (البشرى للتكنولوجيا)
**Effective date:** October 1, 2026
**Contact:** Aladeen35@gmail.com

---

## Summary

- No account or sign-up is required.
- No ads, no analytics, no tracking.
- Your scores, names and settings are stored **only on your device**.
- We run no servers that store your data, and we do not collect personal data about you.
- A few optional features send limited data off your device: the **AI assistant**, **online play** and **Bluetooth play**. Details below.

## 1. Data stored only on your device

The app keeps the following in local storage on your device:
- Player names you enter once.
- Scores, the leaderboard, score curves with dates, level averages and the full history.
- Settings (such as theme and sounds).
- Which questions you have already seen, so none repeats before the bank is exhausted.

This data is **never sent to us or to anyone else**. Backup creates a JSON file on your device and import reads a file you choose; neither is uploaded.

## 2. AI assistant (optional)

On the hard level you can use the "AI assistant" lifeline to get a hint, by typing or speaking.

**What is sent?** Only when you use it:
- The current question text and its answer choices.
- The message you typed or spoke (after it is converted to text), together with your earlier messages and the assistant's replies in the same hint conversation, so it keeps the context.

**Where?** To one of two services:
- **Puter.com's free AI service**, governed by Puter's privacy policy: https://puter.com/privacy
- Or an **optional proxy server operated by the developer**, which forwards the request to **Anthropic's Claude API** and returns the reply. The proxy does not store request content. Anthropic's processing is governed by its policy: https://www.anthropic.com/legal/privacy

**Tip:** do not include personal information (full name, phone number, address…) in your message; the assistant only needs your question about the quiz.

**Reporting replies:** you can report any inappropriate AI reply with the in-app "Report reply" button. It opens your device's email app with a pre-filled message to Aladeen35@gmail.com containing the reported reply; nothing is sent unless you tap "Send" yourself. We use reports only to improve the assistant and do not use your email address for anything else.

**Voice input:** when you tap the microphone button, the app uses **your device's built-in speech recognition service** to turn your speech into text. The app does not record audio files, does not store your voice and does not send it to us; it receives only the text and sends it to the assistant like a typed message. Audio processing inside the system service is governed by that service provider's policy (for example, Google). The microphone is used only when you tap the microphone button.

If you do not use the AI assistant, none of this is sent.

## 3. Online play (optional)

When you play online between two devices with a 5-digit room code, or in a family room:
- Your device exchanges **only your nickname, game answers and game state** with the other players' devices.
- The exchange happens **directly between devices** using **PeerJS (WebRTC)** over an encrypted connection.
- The **public PeerJS signaling server (0.peerjs.com)** is used only to connect the devices at the start (technical connection data such as a random session ID and network address). It does not store game data.
- There is **no chat** between players, and no exchange of photos or audio.
- **We run no server for online play and store nothing.**

## 4. Bluetooth (optional)

Bluetooth is used only to connect two nearby phones for offline play; they exchange nicknames, game answers and game state. We do not use Bluetooth to determine your location or for any other purpose.

## 5. Permissions and why we need them

| Permission | Use |
|---|---|
| Internet (INTERNET) | AI assistant and online play. |
| Nearby devices (BLUETOOTH_CONNECT) — Android 12+ | Connecting to a nearby phone for Bluetooth play. |
| BLUETOOTH and BLUETOOTH_ADMIN — Android 11 and below | The same purpose on older Android versions. |
| Microphone (RECORD_AUDIO) — optional | Asking the AI assistant by voice, only when you tap the microphone button. |
| Vibration (VIBRATE) | Celebration vibration when you win. |

You can deny the microphone or Bluetooth permission and the rest of the game works normally.

## 6. What we do not do

- We do not collect your real name, email, phone number, location or contacts.
- We do not use third-party analytics, tracking or crash-reporting tools.
- We show no ads and do not use the advertising ID.
- We do not sell any data or share it for marketing.

## 7. Data retention and deletion

- Data on your device stays there until you delete it.
- **To delete it:** use the in-app "Clear records" button, or uninstall the app (which deletes all of its data).
- We keep no data about you on our servers, so there is nothing to delete on our side. Data sent to Puter or Anthropic through the AI assistant is subject to their retention policies.
- For any request or question about your data, email: Aladeen35@gmail.com

## 8. Security

All connections leaving the app are encrypted: AI services over HTTPS, online play over encrypted WebRTC, and the signaling server over a secure connection.

## 9. Children

The app is intended for users **aged 13 and over**, and families can play together on a parent's device. We do not knowingly collect personal data from children under 13. We recommend that parents supervise children's use of the AI assistant and online play. If you learn that a child sent personal information through the AI assistant, contact us at Aladeen35@gmail.com and we will help you reach the relevant service.

## 10. Changes to this policy

We may update this policy when the app's features change. The new version will be posted at the same address with an updated effective date. Significant changes will be mentioned in the store release notes.

## 11. Contact us

Al-Bushra Technology — Aladeen35@gmail.com

---

من إنتاج البشرى للتكنولوجيا — Al-Bushra Technology
