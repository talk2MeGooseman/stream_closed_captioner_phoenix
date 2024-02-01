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
