/* Informe François — pre-informe con DeepSeek.

   POST /api/preinforme   { modo, rango, notas, pendientes }
     Authorization: Bearer <token de la sesión de Supabase de la app>
     → { ok, informe, observaciones:[…], modelo, cortado }
   GET  /api/preinforme   → { ok, deepseek } (si la clave está cargada)

   La clave de DeepSeek vive SOLO en Vercel, nunca en la página:
     DEEPSEEK_API_KEY   (obligatoria)
     DEEPSEEK_MODEL     (opcional; si no existe para la clave, se busca otro)
   Las reglas del informe son las mismas de «Copiar prompt»: prompt.js.

   Solo responde a quien entró con la cuenta de la app (sesión de Supabase
   que no sea anónima): así nadie de afuera gasta el saldo de DeepSeek. */
const PROMPT = require("../prompt.js");

const SB_URL = "https://zmpiqkbvmjvfvxyvcdhi.supabase.co";
const SB_KEY = "sb_publishable_wk2KPYx1W--YcsrbRrEPxw_ORy1fati";      // llave pública, la misma del index.html
const DEEPSEEK_API = (process.env.DEEPSEEK_API_URL || "https://api.deepseek.com/").replace(/\/?$/, "/");
const MODOS = ["DIARIO", "SEMANAL", "CIERRE"];
const MAX_NOTAS = 60000, MAX_PEND = 4000;
/* Prueba en el computador sin cuenta (servir-local.cjs). En Vercel nunca aplica: allá VERCEL=1. */
const PRUEBA_LOCAL = !process.env.VERCEL && process.env.PREINFORME_PRUEBA === "1";

/* ---- quién pide: la sesión de la app ---- */
async function cuenta(req) {
  const m = /^Bearer\s+(\S+)$/i.exec(req.headers.authorization || "");
  if (!m) return null;
  const r = await fetch(SB_URL + "/auth/v1/user", {
    headers: { apikey: SB_KEY, Authorization: "Bearer " + m[1] },
    signal: AbortSignal.timeout(10000)
  });
  if (r.status === 401 || r.status === 403) return null;
  if (!r.ok) throw new Error("Supabase " + r.status);
  const u = await r.json().catch(() => null);
  return u && u.id && !u.is_anonymous ? u : null;
}

/* ---- DeepSeek (formato OpenAI) ----
   Si el modelo pedido ya no existe (400/404), se le pregunta a la API cuáles hay:
   primero los «flash» (los más baratos) y después el resto. Igual que el panel. */
let hallado = "";
async function modelos() {
  const r = await fetch(DEEPSEEK_API + "models", { headers: { Authorization: "Bearer " + process.env.DEEPSEEK_API_KEY } });
  const d = await r.json().catch(() => ({}));
  if (!r.ok) throw new Error("DeepSeek " + r.status + ": " + ((d.error && d.error.message) || ""));
  return (d.data || []).map(m => m.id).sort((a, b) => (/flash/.test(b) ? 1 : 0) - (/flash/.test(a) ? 1 : 0));
}
async function pedir(modelo, sistema, mensaje) {
  let r;
  try {
    r = await fetch(DEEPSEEK_API + "chat/completions", {
      signal: AbortSignal.timeout(55000),               // la función tiene 60 s (vercel.json)
      method: "POST",
      headers: { "Content-Type": "application/json", Authorization: "Bearer " + process.env.DEEPSEEK_API_KEY },
      body: JSON.stringify({
        model: modelo,
        messages: [{ role: "system", content: sistema }, { role: "user", content: mensaje }],
        response_format: { type: "json_object" },
        temperature: 0.7,
        max_tokens: 8000
      })
    });
  } catch (e) { const x = new Error("DeepSeek tardó demasiado en responder"); x.status = 504; throw x; }
  const d = await r.json().catch(() => ({}));
  if (!r.ok) {
    const motivo = r.status === 401 ? "la clave DEEPSEEK_API_KEY no es válida"
      : r.status === 402 ? "la cuenta de DeepSeek no tiene saldo: hay que recargar en platform.deepseek.com"
      : r.status === 429 ? "DeepSeek está sin cupo por ahora, prueba en un minuto"
      : ((d.error && d.error.message) || "error " + r.status);
    const e = new Error(motivo); e.status = r.status; throw e;
  }
  const c = (d.choices && d.choices[0]) || {};
  return { texto: (c.message && c.message.content) || "", modelo: d.model || modelo, cortado: c.finish_reason === "length" };
}
async function conDeepseek(sistema, mensaje) {
  const primero = process.env.DEEPSEEK_MODEL || hallado || "deepseek-flash";
  let falla;
  try { return await pedir(primero, sistema, mensaje); }
  catch (e) { if (e.status !== 400 && e.status !== 404) throw e; falla = e; }
  for (const m of (await modelos()).filter(x => x !== primero).slice(0, 3)) {
    try { const salida = await pedir(m, sistema, mensaje); hallado = m; return salida; }
    catch (e) { if (e.status !== 400 && e.status !== 404) throw e; falla = e; }
  }
  throw falla;
}

/* DeepSeek a veces deja saltos de línea crudos dentro de un texto del JSON: se escapan solo los que van entre comillas */
function sinControles(t) {
  let r = "", enTexto = false, escape = false;
  for (const c of t) {
    if (enTexto) {
      if (escape) escape = false;
      else if (c === "\\") escape = true;
      else if (c === '"') enTexto = false;
      else if (c < " ") { r += c === "\n" ? "\\n" : c === "\r" ? "\\r" : c === "\t" ? "\\t" : "\\u" + c.charCodeAt(0).toString(16).padStart(4, "0"); continue; }
    } else if (c === '"') enTexto = true;
    r += c;
  }
  return r;
}
function leerSalida(s) {
  const m = /\{[\s\S]*\}/.exec(String(s || ""));
  let d = null;
  if (m) { try { d = JSON.parse(m[0]); } catch (e) { try { d = JSON.parse(sinControles(m[0])); } catch (e2) { d = null; } } }
  if (!d || typeof d.informe !== "string") return { informe: String(s || "").trim(), observaciones: [] };   // vino texto suelto: se usa tal cual
  const obs = (Array.isArray(d.observaciones) ? d.observaciones : [])
    .map(x => String(x || "").trim()).filter(Boolean).slice(0, 5);
  return { informe: d.informe.replace(/\r/g, "").trim(), observaciones: obs };
}

module.exports = async function handler(req, res) {
  const hayClave = !!process.env.DEEPSEEK_API_KEY;
  if (req.method === "GET") return res.status(200).json({ ok: true, deepseek: hayClave });
  if (req.method !== "POST") return res.status(405).json({ error: "Solo GET o POST" });

  try {
    if (!PRUEBA_LOCAL && !(await cuenta(req)))
      return res.status(401).json({ error: "Para usar DeepSeek entra con la cuenta de la app en Datos.", sinSesion: true });
  } catch (e) {
    return res.status(502).json({ error: "No se pudo verificar la cuenta. ¿Hay internet?" });
  }
  if (!hayClave) return res.status(501).json({
    error: "Falta la clave de DeepSeek en Vercel: proyecto informe-francois → Settings → Environment Variables → DEEPSEEK_API_KEY.",
    sinClave: true
  });

  const b = req.body || {};
  const modo = String(b.modo || "").toUpperCase();
  if (!MODOS.includes(modo)) return res.status(400).json({ error: "Modo desconocido" });
  const notas = String(b.notas || "").trim();
  if (!notas) return res.status(400).json({ error: "No hay notas en el período" });
  if (notas.length > MAX_NOTAS) return res.status(413).json({ error: "Son demasiadas notas para un solo informe: acorta el período." });
  const o = { modo, rango: String(b.rango || "").slice(0, 80).trim(), notas,
              pendientes: modo === "CIERRE" ? String(b.pendientes || "").slice(0, MAX_PEND).trim() : "" };

  const t0 = Date.now();
  try {
    const r = await conDeepseek(PROMPT.sistemaIA(modo, o.rango), PROMPT.mensajeIA(o));
    const s = leerSalida(r.texto);
    if (!s.informe) throw new Error("DeepSeek devolvió un informe vacío");
    return res.status(200).json({ ok: true, informe: s.informe, observaciones: s.observaciones,
                                  modelo: r.modelo, cortado: r.cortado, ms: Date.now() - t0 });
  } catch (e) {
    console.error("preinforme", modo, e && e.message);
    return res.status(502).json({ error: "DeepSeek no pudo armar el pre-informe: " + ((e && e.message) || "error") });
  }
};
