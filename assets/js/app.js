// We need to import the CSS so that webpack will load it.
// The MiniCssExtractPlugin is used to separate it out into
// its own CSS file.

// webpack automatically bundles all modules in your
// entry points. Those entry points can be configured
// in "webpack.config.js".
//
// Import deps with the dep name or local files with a relative path, for example:
//
//     import {Socket} from "phoenix"
//     import socket from "./socket"
//
import 'phoenix_html';
import { Socket } from 'phoenix';
import { LiveSocket } from 'phoenix_live_view';
import { InitToast } from './init_toast';
import topbar from '../vendor/topbar';

import './stimulus';
import 'alpinejs';
import './tailwind';

const Hooks = {};
Hooks.InitToast = InitToast;

// Stepper: +/- buttons that adjust a sibling number input and fire phx-change.
Hooks.Stepper = {
  mounted() {
    const input = this.el.querySelector('input');
    if (!input) return;
    this.el.querySelectorAll('[data-step]').forEach((btn) => {
      btn.addEventListener('click', () => {
        const min = input.min !== '' ? parseInt(input.min, 10) : -Infinity;
        const max = input.max !== '' ? parseInt(input.max, 10) : Infinity;
        const cur = parseInt(input.value || '0', 10) || 0;
        const next = Math.max(min, Math.min(max, cur + parseInt(btn.dataset.step, 10)));
        input.value = next;
        input.dispatchEvent(new Event('input', { bubbles: true }));
      });
    });
  },
};

// ScrollSpy: highlight the section-nav link for the card in view.
Hooks.ScrollSpy = {
  mounted() {
    const links = Array.from(this.el.querySelectorAll('[data-spy]'));
    const byId = {};
    links.forEach((l) => (byId[l.dataset.spy] = l));
    this.observer = new IntersectionObserver(
      (entries) => {
        entries.forEach((e) => {
          if (e.isIntersecting && byId[e.target.id]) {
            links.forEach((l) => l.classList.remove('active'));
            byId[e.target.id].classList.add('active');
          }
        });
      },
      { rootMargin: '-30% 0px -60% 0px' }
    );
    links.forEach((l) => {
      const target = document.getElementById(l.dataset.spy);
      if (target) this.observer.observe(target);
    });
  },
  destroyed() {
    if (this.observer) this.observer.disconnect();
  },
};

// Toast: auto-dismiss a flash toast, then clear the server-side flash.
Hooks.Toast = {
  mounted() {
    this.timer = setTimeout(() => {
      this.el.setAttribute('data-hide', '');
      this.pushEvent('clear_flash', { key: this.el.dataset.key });
    }, 3200);
  },
  destroyed() {
    clearTimeout(this.timer);
  },
};

// CopyToClipboard: copy the value of the input named by data-copy-target.
Hooks.CopyToClipboard = {
  mounted() {
    this.el.addEventListener('click', () => {
      const target = document.getElementById(this.el.dataset.copyTarget);
      if (!target) return;
      navigator.clipboard.writeText(target.value).then(() => {
        const original = this.el.textContent;
        this.el.textContent = 'Copied!';
        setTimeout(() => (this.el.textContent = original), 1500);
      });
    });
  },
};

Hooks.QuillEditor = {
  mounted() {
    if (!window.Quill) return;
    const hiddenInput = document.getElementById(this.el.dataset.inputId);
    this.quill = new window.Quill(this.el, {
      theme: 'snow',
      modules: {
        toolbar: [
          ['bold', 'italic', 'underline', 'strike'],
          ['blockquote'],
          [{ list: 'ordered' }, { list: 'bullet' }],
          [{ header: [1, 2, 3, false] }],
          ['link'],
          ['clean'],
        ],
      },
    });
    if (hiddenInput && hiddenInput.value) {
      this.quill.root.innerHTML = hiddenInput.value;
    }
    this.quill.on('text-change', () => {
      if (hiddenInput) {
        hiddenInput.value = this.quill.root.innerHTML;
        hiddenInput.dispatchEvent(new Event('input', { bubbles: true }));
      }
    });
  },
  destroyed() {
    this.quill = null;
  },
};

Hooks.CaptionObserver = {
  mounted() {
    const container = document.querySelector('#scrollerEndMarker');

    let options = { root: this.el, rootMargin: '0px 0px 100px 0px' }

    let observer = new IntersectionObserver(
      (entries) => {
        console.log('entries', entries)
        container.scrollIntoView({ behavior: 'smooth' });
        console.log('scrolling to end of chat...')
      }
      , options);
    observer.observe(container);
  }
}

const csrfToken = document
  .querySelector("meta[name='csrf-token']")
  .getAttribute('content');

const liveSocket = new LiveSocket('/live', Socket, {
  hooks: Hooks,
  params: { _csrf_token: csrfToken },
  dom: {
    onBeforeElUpdated(from, to) {
      if (from.__x) {
        window.Alpine.clone(from.__x, to);
      }
    },
  },
});

// Show progress bar on live navigation and form submits
topbar.config({ barColors: { 0: '#29d' }, shadowColor: 'rgba(0, 0, 0, .3)' });
window.addEventListener('phx:page-loading-start', (_info) => topbar.show(300));
window.addEventListener('phx:page-loading-stop', (_info) => topbar.hide());

// connect if there are any LiveViews on the page
liveSocket.connect();

// expose liveSocket on window for web console debug logs and latency simulation:
// >> liveSocket.enableDebug()
// >> liveSocket.enableLatencySim(1000)  // enabled for duration of browser session
// >> liveSocket.disableLatencySim()
window.liveSocket = liveSocket;
