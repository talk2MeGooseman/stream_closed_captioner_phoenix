function isChromium() {
  if (navigator.userAgentData?.brands) {
    const hasGoogleChromeBrand = navigator.userAgentData.brands.find(
      (b) => b.brand === 'Google Chrome'
    );

    if (hasGoogleChromeBrand) {
      return true;
    }
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

export const isBrowserCompatible = () => {
  return (('webkitSpeechRecognition' in window) ||
    navigator.userAgent.indexOf('Opera') !== -1 ||
    isChromium() ||
    isEdge() ||
    isChromeiOS()) &&
    !window.Cypress
};
