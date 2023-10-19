export const isBrowserCompatible = () => {
  if (window.navigator.brave) return false;
  if (window.navigator.userAgent.match(/Safari/).length > 0) return false;
  if (window.navigator.userAgent.match(/Firefox/).length > 0) return false;

  return !!(
    window.SpeechRecognition
    || window.webkitSpeechRecognition
    || navigator.mediaDevices.getUserMedia
  );
};
