(() => {
  'use strict';

  const archive = document.querySelector('[data-archive]');
  const postList = archive?.querySelector('[data-post-list]');
  if (!archive || !postList) return;

  const dimensions = ['category', 'year', 'tag'];
  const filterLinks = Array.from(
    archive.querySelectorAll('a[data-filter-kind][data-filter-value]')
  );
  const count = archive.querySelector('[data-result-count]');
  const summary = archive.querySelector('[data-filter-summary]');
  const clearButtons = Array.from(archive.querySelectorAll('[data-clear-filters]'));
  const noResults = archive.querySelector('[data-no-results]');
  const sortControl = archive.querySelector('select[data-sort]');

  function readList(value) {
    try {
      const parsed = JSON.parse(value || '[]');
      return Array.isArray(parsed)
        ? parsed.filter((item) => typeof item === 'string')
        : [];
    } catch {
      return [];
    }
  }

  const posts = Array.from(postList.querySelectorAll('article[data-post]')).map(
    (element, index) => {
      const date = Date.parse(element.dataset.date || '');
      return {
        element,
        index,
        date: Number.isFinite(date) ? date : 0,
        categories: readList(element.dataset.categories),
        tags: readList(element.dataset.tags),
        year: element.dataset.year || '',
      };
    }
  );

  function readState() {
    const params = new URLSearchParams(window.location.search);
    return {
      category: params.get('category') || '',
      year: params.get('year') || '',
      tag: params.get('tag') || '',
      sort: params.get('sort') === 'oldest' ? 'oldest' : 'newest',
    };
  }

  let state = readState();

  function render() {
    const sortedPosts = [...posts].sort((a, b) => {
      const byDate = state.sort === 'oldest' ? a.date - b.date : b.date - a.date;
      return byDate || a.index - b.index;
    });
    const fragment = document.createDocumentFragment();
    let resultCount = 0;

    sortedPosts.forEach((post) => {
      const visible =
        (!state.category || post.categories.includes(state.category)) &&
        (!state.year || post.year === state.year) &&
        (!state.tag || post.tags.includes(state.tag));
      post.element.hidden = !visible;
      if (visible) resultCount += 1;
      fragment.appendChild(post.element);
    });
    postList.appendChild(fragment);

    filterLinks.forEach((link) => {
      const kind = link.dataset.filterKind;
      if (!dimensions.includes(kind)) return;
      const active = state[kind] === link.dataset.filterValue;
      link.classList.toggle('is-active', active);
      if (active) link.setAttribute('aria-current', 'true');
      else link.removeAttribute('aria-current');
    });

    if (count) count.textContent = String(resultCount);
    if (summary) {
      const labels = [];
      if (state.category) labels.push(`类别：${state.category}`);
      if (state.year) labels.push(`年份：${state.year}`);
      if (state.tag) labels.push(`标签：${state.tag}`);
      summary.textContent = labels.length ? labels.join(' · ') : '全部文章';
    }
    clearButtons.forEach((button) => {
      if (button.closest('[data-script-controls]')) {
        button.hidden = !dimensions.some((kind) => state[kind]);
      }
    });
    if (noResults) noResults.hidden = resultCount !== 0 || posts.length === 0;
    if (sortControl) sortControl.value = state.sort;
  }

  function updateState(nextState) {
    state = nextState;
    const url = new URL(window.location.href);
    dimensions.forEach((kind) => {
      if (state[kind]) url.searchParams.set(kind, state[kind]);
      else url.searchParams.delete(kind);
    });
    if (state.sort === 'oldest') url.searchParams.set('sort', 'oldest');
    else url.searchParams.delete('sort');
    if (url.href !== window.location.href) {
      window.history.pushState(null, '', url.href);
    }
    render();
  }

  archive.addEventListener('click', (event) => {
    if (
      event.defaultPrevented ||
      event.button !== 0 ||
      event.metaKey ||
      event.ctrlKey ||
      event.shiftKey ||
      event.altKey ||
      !(event.target instanceof Element)
    ) return;

    const link = event.target.closest('a[data-filter-kind][data-filter-value]');
    if (
      !link ||
      !archive.contains(link) ||
      !dimensions.includes(link.dataset.filterKind) ||
      (link.target && link.target !== '_self') ||
      link.hasAttribute('download')
    ) return;

    event.preventDefault();
    updateState({ ...state, [link.dataset.filterKind]: link.dataset.filterValue });
  });

  clearButtons.forEach((button) => {
    button.addEventListener('click', (event) => {
      event.preventDefault();
      updateState({ ...state, category: '', year: '', tag: '' });
    });
  });

  sortControl?.addEventListener('change', () => {
    updateState({ ...state, sort: sortControl.value === 'oldest' ? 'oldest' : 'newest' });
  });

  window.addEventListener('popstate', () => {
    state = readState();
    render();
  });

  render();
  archive.querySelectorAll('[data-script-controls]').forEach((control) => {
    control.hidden = false;
  });
})();
