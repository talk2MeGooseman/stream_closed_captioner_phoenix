export function capitalize(sentence) {
  if (sentence.length === 0) return ''

  return sentence[0].toUpperCase() + sentence.substr(1)
}
