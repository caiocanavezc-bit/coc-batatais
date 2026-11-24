/* Mural dos aprovados: busca os aprovados no Supabase e monta a esteira infinita.
   Uso: CocMural.mount(elemento, {limit, onEmpty}) */
(function () {
  const cfg = window.COC_SUPABASE || {};
  const configured = !!(cfg.url && cfg.anonKey);
  const base = (cfg.url || '').replace(/\/+$/, '');
  const esc = s => String(s ?? '').replace(/[&<>"']/g, c => ({ '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&#39;' })[c]);
  const reduce = matchMedia('(prefers-reduced-motion: reduce)');

  function photoUrl(path) {
    return `${base}/storage/v1/object/public/aprovados/${encodeURIComponent(path)}`;
  }

  async function load(limit) {
    if (!configured) return [];
    const q = `select=id,nome,genero,curso,faculdade,foto_path&order=created_at.desc${limit ? `&limit=${limit}` : ''}`;
    const res = await fetch(`${base}/rest/v1/aprovados?${q}`, {
      headers: { apikey: cfg.anonKey }
    });
    if (!res.ok) throw new Error(`Supabase respondeu ${res.status}`);
    return res.json();
  }

  function card(a) {
    const status = a.genero === 'f' ? 'Aprovada!' : 'Aprovado!';
    const alt = `${a.nome}, ${a.genero === 'f' ? 'aprovada' : 'aprovado'} em ${a.curso} na ${a.faculdade}`;
    return `<article class="mq-card"><div class="mq-photo"><img src="${esc(photoUrl(a.foto_path))}" alt="${esc(alt)}" width="600" height="750" loading="lazy" decoding="async"></div>`
      + `<div class="mq-cap"><span class="mq-name">${esc(a.nome)}</span><span class="mq-pill">${status}</span>`
      + `<span class="mq-course">${esc(a.curso)}</span><span class="mq-inst">${esc(a.faculdade)}</span></div></article>`;
  }

  /* Repete a lista até passar da largura da tela e duplica o bloco: a animação anda 50% e recomeça sem emenda */
  function build(el, rows) {
    const one = rows.map(card).join('');
    el.innerHTML = `<div class="mq-track"><div class="mq-group">${one}</div></div>`;
    const track = el.firstElementChild;
    const group = track.firstElementChild;
    if (reduce.matches) return;
    const setWidth = group.scrollWidth || 1;
    const reps = Math.max(1, Math.ceil((el.clientWidth + 1) / setWidth));
    group.innerHTML = one.repeat(reps);
    const clone = group.cloneNode(true);
    clone.setAttribute('aria-hidden', 'true');
    clone.querySelectorAll('img').forEach(img => { img.alt = ''; });
    track.appendChild(clone);
    const pxPerSecond = 45;
    track.style.setProperty('--mq-dur', `${Math.round(group.scrollWidth / pxPerSecond)}s`);
  }

  async function mount(el, opts = {}) {
    let rows;
    try {
      rows = await load(opts.limit);
    } catch (err) {
      console.error('[mural]', err);
      rows = [];
    }
    if (!rows.length) {
      if (opts.onEmpty) opts.onEmpty(el, configured);
      else el.innerHTML = '<p class="mq-empty">Em breve, os aprovados de 2026 aparecem aqui.</p>';
      return rows;
    }
    el.classList.add('mq');
    el.setAttribute('role', 'region');
    el.setAttribute('aria-roledescription', 'carrossel');
    el.addEventListener('click', e => { if (e.pointerType === 'touch' || matchMedia('(hover: none)').matches) el.classList.toggle('is-paused'); });
    build(el, rows);
    let w = el.clientWidth, t;
    addEventListener('resize', () => {
      clearTimeout(t);
      t = setTimeout(() => { if (el.clientWidth !== w) { w = el.clientWidth; build(el, rows); } }, 200);
    });
    reduce.addEventListener?.('change', () => build(el, rows));
    return rows;
  }

  window.CocMural = { configured, load, mount, photoUrl, esc };
})();
