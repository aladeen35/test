/* فول مارك — إعدادات النشر (اختيارية)
   aiProxyUrl: عنوان خادم وسيط يمرّر الطلب إلى Claude بمفتاح الشركة
               (انشر cloudflare-worker-ai-proxy.js الموجود في جذر المستودع).
               إن تُرك فارغاً يُستخدم مزوّد Puter المجاني، ثم التلميح المدمج عند عدم توفر الإنترنت.
   contactEmail: بريد التواصل الظاهر في الخصوصية وزر «إبلاغ عن الرد». */
window.FM_CONFIG = {
  aiProxyUrl: null,
  aiModel: 'claude-haiku-4-5',
  contactEmail: 'CONTACT_EMAIL',
};
