// GitEasy site - card walkthrough navigation.
// No dependencies. Pure DOM. Loads in any browser, no build step.

(function () {
  'use strict';

  var cards = Array.prototype.slice.call(document.querySelectorAll('.card'));
  var prevBtn = document.getElementById('prev-btn');
  var nextBtn = document.getElementById('next-btn');
  var counter = document.getElementById('card-current');
  var dots = Array.prototype.slice.call(document.querySelectorAll('.card-dot'));
  var total = cards.length;
  var idx = 0;

  if (total === 0) return;

  function render() {
    cards.forEach(function (card, i) {
      if (i === idx) card.classList.add('active');
      else card.classList.remove('active');
    });
    dots.forEach(function (dot, i) {
      if (i === idx) dot.classList.add('active');
      else dot.classList.remove('active');
    });
    if (counter) counter.textContent = (idx + 1);
    if (prevBtn) prevBtn.disabled = (idx === 0);
    if (nextBtn) nextBtn.disabled = (idx === total - 1);

    // Sync URL hash so a card is bookmarkable / shareable.
    var hash = '#card-' + (idx + 1);
    if (history.replaceState) history.replaceState(null, '', hash);

    // Scroll the card into view (the article itself, not the page top).
    var active = cards[idx];
    if (active && active.scrollIntoView) {
      active.scrollIntoView({ behavior: 'smooth', block: 'nearest' });
    }
  }

  function goTo(target) {
    if (target < 0) target = 0;
    if (target > total - 1) target = total - 1;
    idx = target;
    render();
  }

  // Buttons
  if (prevBtn) prevBtn.addEventListener('click', function () { goTo(idx - 1); });
  if (nextBtn) nextBtn.addEventListener('click', function () { goTo(idx + 1); });

  // Dot indicators
  dots.forEach(function (dot, i) {
    dot.addEventListener('click', function () { goTo(i); });
  });

  // Keyboard arrows
  document.addEventListener('keydown', function (e) {
    // Don't intercept if a <details> or form element has focus.
    var tag = (document.activeElement && document.activeElement.tagName) || '';
    if (tag === 'INPUT' || tag === 'TEXTAREA' || tag === 'SELECT') return;

    if (e.key === 'ArrowRight' || e.key === 'PageDown') {
      goTo(idx + 1);
      e.preventDefault();
    } else if (e.key === 'ArrowLeft' || e.key === 'PageUp') {
      goTo(idx - 1);
      e.preventDefault();
    } else if (e.key === 'Home') {
      goTo(0);
      e.preventDefault();
    } else if (e.key === 'End') {
      goTo(total - 1);
      e.preventDefault();
    }
  });

  // Honor #card-N hash on page load
  function fromHash() {
    var m = (location.hash || '').match(/^#card-(\d+)$/);
    if (m) {
      var n = parseInt(m[1], 10) - 1;
      if (!isNaN(n) && n >= 0 && n < total) {
        idx = n;
      }
    }
  }

  fromHash();
  render();
})();
