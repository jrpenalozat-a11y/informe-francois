/* Servidor mínimo para ver la app en el computador, con la función de /api
   como en Vercel (req.body ya leído, res.status().json()).
   Uso:  node servir-local.cjs [puerto]        (por defecto 5189)
   La clave de DeepSeek se pasa por variable de entorno, nunca en un archivo:
     DEEPSEEK_API_KEY=…  node servir-local.cjs
   Para probar sin cuenta ni clave (respuestas simuladas): PREINFORME_PRUEBA=1
   y DEEPSEEK_API_URL apuntando a un DeepSeek de mentira. */
const http = require("http");
const fs = require("fs");
const path = require("path");

const RAIZ = __dirname;
const PUERTO = Number(process.argv[2]) || Number(process.env.PORT) || 5189;
const TIPOS = {
  ".html":"text/html; charset=utf-8", ".js":"text/javascript; charset=utf-8",
  ".json":"application/json; charset=utf-8", ".css":"text/css; charset=utf-8",
  ".png":"image/png", ".jpg":"image/jpeg", ".svg":"image/svg+xml", ".ico":"image/x-icon"
};

function conAyudas(res){
  res.status = c => { res.statusCode = c; return res; };
  res.json = o => { res.setHeader("Content-Type", "application/json; charset=utf-8"); res.end(JSON.stringify(o)); return res; };
  return res;
}

http.createServer((req, res) => {
  const rel = decodeURIComponent(req.url.split("?")[0]);

  if (rel.startsWith("/api/")) {
    const nombre = rel.slice(5).replace(/[^a-z0-9_-]/gi, "");
    const archivo = path.join(RAIZ, "api", nombre + ".js");
    if (!fs.existsSync(archivo)) { res.writeHead(404).end("no existe"); return; }
    let cuerpo = "";
    req.on("data", d => { cuerpo += d; });
    req.on("end", async () => {
      try { req.body = cuerpo && /json/.test(req.headers["content-type"] || "") ? JSON.parse(cuerpo) : {}; }
      catch (e) { res.writeHead(400).end("JSON mal formado"); return; }
      try { delete require.cache[require.resolve(archivo)]; await require(archivo)(req, conAyudas(res)); }
      catch (e) { console.error(e); if (!res.headersSent) res.writeHead(500).end(String(e && e.message)); }
    });
    return;
  }

  const abs = path.join(RAIZ, path.normalize(rel === "/" ? "/index.html" : rel).replace(/^[\\/]+/, ""));
  if (!abs.startsWith(RAIZ) || /[\\/]\.(git|vercel)([\\/]|$)/.test(abs)) { res.writeHead(403).end("prohibido"); return; }
  fs.readFile(abs, (err, buf) => {
    if (err) { res.writeHead(404, {"Content-Type":"text/plain; charset=utf-8"}).end("no encontrado: " + rel); return; }
    res.writeHead(200, { "Content-Type": TIPOS[path.extname(abs).toLowerCase()] || "application/octet-stream", "Cache-Control": "no-store" }).end(buf);
  });
}).listen(PUERTO, () => console.log("Informe François en http://localhost:" + PUERTO));
