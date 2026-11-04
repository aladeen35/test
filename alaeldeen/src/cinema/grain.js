/* Film grain: one noise tile is generated once, then a fixed, oversized layer is moved
   by a CSS steps() animation. That runs on the compositor, so it costs the main thread
   nothing and never touches the content DOM. */
export function initGrain(reduce) {
  const c = document.createElement("canvas"); c.width = c.height = 160;
  const g = c.getContext("2d"); const img = g.createImageData(160, 160);
  for (let i = 0; i < img.data.length; i += 4) { const v = Math.random() * 255; img.data[i] = img.data[i + 1] = img.data[i + 2] = v; img.data[i + 3] = 255; }
  g.putImageData(img, 0, 0);
  const el = document.createElement("div");
  el.id = "grain"; el.setAttribute("aria-hidden", "true");
  el.style.backgroundImage = `url(${c.toDataURL("image/png")})`;
  if (reduce) el.style.opacity = "0.04";
  document.body.appendChild(el);
}
