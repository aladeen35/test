// albushra.app: language/theme, search & filters, featured carousel,
// scroll reveals, count-up stats. No dependencies.
(function () {
  var root = document.documentElement;
  var reduce = window.matchMedia && matchMedia("(prefers-reduced-motion: reduce)").matches;
  function store(k, v) { try { localStorage.setItem(k, v); } catch (e) {} }
  function $(s, el) { return (el || document).querySelector(s); }
  function $$(s, el) { return Array.prototype.slice.call((el || document).querySelectorAll(s)); }

  // ---- language + theme ----
  function setLang(l) {
    root.setAttribute("data-lang", l);
    root.lang = l;
    root.dir = l === "en" ? "ltr" : "rtl";
    store("ab-lang", l);
  }
  $$("[data-toggle-lang]").forEach(function (b) {
    b.addEventListener("click", function () { setLang(root.getAttribute("data-lang") === "en" ? "ar" : "en"); });
  });
  $$("[data-toggle-theme]").forEach(function (b) {
    b.addEventListener("click", function () {
      var next = root.getAttribute("data-theme") === "light" ? "dark" : "light";
      root.setAttribute("data-theme", next);
      store("ab-theme", next);
    });
  });

  // ---- catalog filter + search ----
  var pills = $$("[data-filter]");
  var search = $("[data-search]");
  var empty = $("[data-empty]");
  var active = "all";
  function apply() {
    var q = ((search && search.value) || "").trim().toLowerCase();
    var total = 0;
    $$("[data-group]").forEach(function (g) {
      var shown = 0;
      $$(".tile", g).forEach(function (c) {
        var ok = (active === "all" || c.dataset.cat === active) && (!q || c.textContent.toLowerCase().indexOf(q) !== -1);
        c.classList.toggle("is-hidden", !ok);
        if (ok) { shown++; c.classList.add("in"); }
      });
      g.classList.toggle("is-hidden", shown === 0);
      total += shown;
    });
    if (empty) empty.hidden = total !== 0;
  }
  pills.forEach(function (p) {
    p.addEventListener("click", function () {
      active = p.dataset.filter;
      pills.forEach(function (x) { x.classList.toggle("is-on", x === p); x.setAttribute("aria-pressed", String(x === p)); });
      apply();
    });
  });
  if (search) search.addEventListener("input", apply);

  // Header search: on the home page it drives the catalog search; elsewhere
  // it submits to the home page with ?q=.
  var top = $("[data-top-search]");
  if (top) {
    var tq = $("input", top);
    if (search) {
      tq.addEventListener("input", function () { search.value = tq.value; apply(); });
      top.addEventListener("submit", function (e) {
        e.preventDefault();
        var apps = $("#apps");
        if (apps) apps.scrollIntoView({ behavior: reduce ? "auto" : "smooth" });
      });
    }
  }
  var initial = new URLSearchParams(location.search).get("q");
  if (initial && search) {
    search.value = initial;
    if (top) $("input", top).value = initial;
    apply();
    setTimeout(function () { var a = $("#apps"); if (a) a.scrollIntoView(); }, 50);
  }

  // ---- featured carousel ----
  var car = $("[data-carousel]");
  if (car && !$(".slide", car)) car.hidden = true;
  else if (car) {
    var track = $("[data-slides]", car);
    var slides = $$(".slide", car);
    var dots = $$("[data-dot]", car); // the router removes a hidden app's slide and dot together
    var idx = 0, timer = null, MS = 6000;
    car.style.setProperty("--slide-ms", MS + "ms");
    function mark(i) {
      idx = i;
      slides.forEach(function (s, k) { s.classList.toggle("is-active", k === i); });
      dots.forEach(function (d, k) {
        if (k === i) {
          d.setAttribute("aria-selected", "true");
          var bar = d.querySelector("i"); // restart the progress animation
          bar.style.display = "none"; void bar.offsetWidth; bar.style.display = "";
        } else d.removeAttribute("aria-selected");
      });
    }
    function go(i) {
      i = (i + slides.length) % slides.length;
      var s = slides[i];
      track.scrollTo({ left: s.offsetLeft - track.offsetLeft, behavior: reduce ? "auto" : "smooth" });
      mark(i);
    }
    function play() { if (reduce || timer) return; timer = setInterval(function () { go(idx + 1); }, MS); car.classList.remove("is-paused"); }
    function pause() { clearInterval(timer); timer = null; car.classList.add("is-paused"); }
    dots.forEach(function (d, k) { d.addEventListener("click", function () { pause(); go(k); play(); }); });
    // Keep dots in sync when the visitor swipes.
    if ("IntersectionObserver" in window) {
      var io = new IntersectionObserver(function (es) {
        es.forEach(function (e) { if (e.isIntersecting && e.intersectionRatio > 0.6) mark(slides.indexOf(e.target)); });
      }, { root: track, threshold: [0.6] });
      slides.forEach(function (s) { io.observe(s); });
    }
    ["pointerenter", "touchstart", "focusin"].forEach(function (ev) { car.addEventListener(ev, pause, { passive: true }); });
    ["pointerleave", "focusout"].forEach(function (ev) { car.addEventListener(ev, play); });
    document.addEventListener("visibilitychange", function () { document.hidden ? pause() : play(); });
    mark(0);
    if (reduce) car.classList.add("is-paused"); else play();
  }

  // ---- reveal on scroll, with a small stagger inside rows/grids ----
  var reveals = $$("[data-reveal]");
  if (!reduce && "IntersectionObserver" in window) {
    var ro = new IntersectionObserver(function (es) {
      es.forEach(function (e) {
        if (!e.isIntersecting) return;
        var el = e.target, sib = el.parentElement ? Array.prototype.indexOf.call(el.parentElement.children, el) : 0;
        el.style.setProperty("--d", Math.min(sib, 6) * 60 + "ms");
        el.classList.add("in");
        ro.unobserve(el);
      });
    }, { rootMargin: "0px 0px -8% 0px", threshold: 0.08 });
    reveals.forEach(function (el) { ro.observe(el); });
  } else {
    reveals.forEach(function (el) { el.classList.add("in"); });
  }

  // ---- count-up stats ----
  var nums = $$("[data-count]");
  if (!reduce && nums.length && "IntersectionObserver" in window) {
    var co = new IntersectionObserver(function (es) {
      es.forEach(function (e) {
        if (!e.isIntersecting) return;
        var el = e.target, end = +el.dataset.count, t0 = performance.now();
        (function step(t) {
          var p = Math.min(1, (t - t0) / 900);
          el.textContent = Math.round(end * (1 - Math.pow(1 - p, 3)));
          if (p < 1) requestAnimationFrame(step);
        })(t0);
        co.unobserve(el);
      });
    }, { threshold: 0.5 });
    nums.forEach(function (n) { co.observe(n); });
  }

  // ---- highlight the current tab in the bottom bar ----
  var tabs = $$(".tabbar a");
  if (tabs.length) {
    function syncTab() {
      var h = location.hash || "";
      tabs.forEach(function (a, i) {
        var ah = a.getAttribute("href").split("#")[1];
        a.classList.toggle("is-on", ah ? h === "#" + ah : (!h && i === 0));
      });
    }
    window.addEventListener("hashchange", syncTab);
    syncTab();
  }
})();
