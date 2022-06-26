export const isBrowserCompatible = () => {
  if(window.navigator.brave) return false

  return window.SpeechRecognition || window.webkitSpeechRecognition ? true : false
}
