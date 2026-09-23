/* ============================================================
   هاف مليون ½M — خادم وسيط اختياري للذكاء الاصطناعي
   Cloudflare Worker يمرّر طلبات التطبيق إلى Anthropic API
   بمفتاح الشركة، فلا يحتاج أي عضو لإدخال مفتاح بنفسه.

   خطوات النشر (مرة واحدة):
   1) أنشئ Worker جديدًا في لوحة Cloudflare والصق هذا الملف.
   2) من Settings → Variables أضف سرًّا باسم ANTHROPIC_API_KEY
      وقيمته مفتاح Anthropic الخاص بالشركة.
   3) انسخ عنوان الـ Worker (مثل https://ai.your-company.workers.dev)
      وضعه في js/config.js داخل APP_CONFIG.ai.proxyUrl.

   اختياري: ضع نطاق تطبيقك في ALLOWED_ORIGIN بدل "*" لقصر
   الاستخدام على موقعك فقط.
   ============================================================ */

const ALLOWED_ORIGIN = "*"; // مثال: "https://halfmillion.example.com"
const ALLOWED_MODELS = null; // مثال: ["claude-sonnet-5","claude-haiku-4-5"] أو null للسماح بالكل
const MAX_TOKENS_CAP = 8192;

export default {
  async fetch(request, env) {
    const cors = {
      "Access-Control-Allow-Origin": ALLOWED_ORIGIN,
      "Access-Control-Allow-Methods": "POST, OPTIONS",
      "Access-Control-Allow-Headers": "content-type, anthropic-version",
      "Access-Control-Max-Age": "86400",
    };
    if (request.method === "OPTIONS") return new Response(null, { status: 204, headers: cors });
    if (request.method !== "POST")
      return new Response(JSON.stringify({ error: { message: "POST only" } }), { status: 405, headers: { ...cors, "content-type": "application/json" } });
    if (!env.ANTHROPIC_API_KEY)
      return new Response(JSON.stringify({ error: { message: "ANTHROPIC_API_KEY secret not set" } }), { status: 500, headers: { ...cors, "content-type": "application/json" } });

    let body;
    try { body = await request.json(); }
    catch (e) { return new Response(JSON.stringify({ error: { message: "invalid JSON" } }), { status: 400, headers: { ...cors, "content-type": "application/json" } }); }

    if (ALLOWED_MODELS && !ALLOWED_MODELS.includes(body.model))
      return new Response(JSON.stringify({ error: { message: "model not allowed" } }), { status: 403, headers: { ...cors, "content-type": "application/json" } });
    if (typeof body.max_tokens === "number") body.max_tokens = Math.min(body.max_tokens, MAX_TOKENS_CAP);

    const upstream = await fetch("https://api.anthropic.com/v1/messages", {
      method: "POST",
      headers: {
        "content-type": "application/json",
        "x-api-key": env.ANTHROPIC_API_KEY,
        "anthropic-version": request.headers.get("anthropic-version") || "2023-06-01",
      },
      body: JSON.stringify(body),
    });

    const headers = new Headers(upstream.headers);
    for (const [k, v] of Object.entries(cors)) headers.set(k, v);
    return new Response(upstream.body, { status: upstream.status, headers });
  },
};
