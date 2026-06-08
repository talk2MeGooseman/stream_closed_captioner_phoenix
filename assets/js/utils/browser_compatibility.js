function isChromium() {
  if (navigator.userAgentData?.brands) {
    const hasGoogleChromeBrand = navigator.userAgentData.brands.find(
      (b) => b.brand === 'Google Chrome'
    );

    if (hasGoogleChromeBrand) {
      return true;
    }
    return false;
  } else {
    // Possibly older version of Chrome or Chromium that does not have
    // navigator.userAgentData.brands

    for (
      let i = 0, u = 'Chromium', l = u.length;
      i < navigator.plugins.length;
      i++
    ) {
      if (
        navigator.plugins[i].name != null &&
        navigator.plugins[i].name.substr(0, l) === u
      ) {
        return true;
      }
    }

    return false;
  }
}

const isEdge = () => {
  return navigator.userAgent && /(Edg\/|Edge)/.test(navigator.userAgent);
};

const isChromeiOS = () => {
  return navigator.userAgent && navigator.userAgent.match('CriOS');
};

// Headless / automation-driven browsers (Playwright, WebDriver, CDP) mimic a
// real browser closely enough to pass the checks below but can't run real
// speech-to-text. The Maestri portal is one of these: it presents as desktop
// Safari (Apple vendor, WebKit, webkitSpeechRecognition present) yet masks
// navigator.webdriver. Genuine desktop Safari always exposes window.safari and
// window.ApplePaySession; Playwright's WebKit build exposes neither — that gap
// is the tell.
const isAutomatedBrowser = () => {
  if (navigator.webdriver) return true;

  const ua = navigator.userAgent;
  const looksLikeDesktopSafari =
    /Macintosh/.test(ua) &&
    / Version\/\d/.test(ua) &&
    / Safari\//.test(ua) &&
    !/Chrome|Chromium|Edg|CriOS|OPR|Opera/.test(ua);

  const lacksGenuineSafariApis =
    typeof window.safari === 'undefined' &&
    typeof window.ApplePaySession === 'undefined';

  return looksLikeDesktopSafari && lacksGenuineSafariApis;
};

export const isBrowserCompatible = () => {
  return (('webkitSpeechRecognition' in window) ||
    navigator.userAgent.indexOf('Opera') !== -1 ||
    isChromium() ||
    isEdge() ||
    isChromeiOS()) &&
    !window.Cypress &&
    !isAutomatedBrowser()
};
