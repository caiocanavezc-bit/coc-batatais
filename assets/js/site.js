/* Comportamentos comuns a todas as páginas: menu do celular, sombra do
   cabeçalho ao rolar e a transição entre páginas para navegadores antigos. */

(() => {
  const header = document.querySelector('.site-header');
  const menuBtn = document.querySelector('.menu-btn');

  /* Menu do celular */
  if (menuBtn) {
    const isOpen = () => document.body.classList.contains('menu-open');
    const setMenu = open => {
      document.body.classList.toggle('menu-open', open);
      menuBtn.setAttribute('aria-expanded', open);
      menuBtn.setAttribute('aria-label', open ? 'Fechar menu' : 'Abrir menu');
    };

    menuBtn.addEventListener('click', () => setMenu(!isOpen()));
    document.querySelectorAll('.navlinks a').forEach(a => a.addEventListener('click', () => setMenu(false)));
    document.addEventListener('click', e => { if (isOpen() && !e.target.closest('.nav')) setMenu(false); });
    addEventListener('keydown', e => { if (e.key === 'Escape' && isOpen()) { setMenu(false); menuBtn.focus(); } });
  }

  /* Cabeçalho: ganha sombra (e, na página inicial, fundo branco) ao rolar */
  if (header) {
    const onScroll = () => header.classList.toggle('scrolled', scrollY > 16);
    addEventListener('scroll', onScroll, { passive: true });
    onScroll();
  }

  /* Transição entre páginas. Chrome, Edge e Safari fazem sozinhos pelo CSS
     (@view-transition). Nos demais, a página esmaece ao sair e ao entrar. */
  const nativeTransition = 'CSSViewTransitionRule' in window;
  const lessMotion = matchMedia('(prefers-reduced-motion: reduce)').matches;

  if (!nativeTransition && !lessMotion) {
    document.documentElement.classList.add('page-fade');

    document.addEventListener('click', e => {
      const link = e.target.closest('a[href]');
      if (!link || link.target || e.defaultPrevented || e.button || e.ctrlKey || e.metaKey || e.shiftKey || e.altKey) return;

      const url = new URL(link.href, location.href);
      if (url.origin !== location.origin || url.pathname === location.pathname) return;

      e.preventDefault();
      document.body.style.transition = 'opacity .18s';
      document.body.style.opacity = '0';
      setTimeout(() => { location.href = url.href; }, 180);
    });

    /* Ao voltar pelo botão do navegador, a página reaparece */
    addEventListener('pageshow', e => { if (e.persisted) document.body.style.opacity = ''; });
  }
})();
