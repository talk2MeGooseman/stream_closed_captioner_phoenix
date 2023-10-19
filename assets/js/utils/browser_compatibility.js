export const isBrowserCompatible = () => {
  if (window.navigator.brave) return false;

  return !!(
    window.SpeechRecognition
    || window.webkitSpeechRecognition
    || navigator.mediaDevices.getUserMedia
  );
};
