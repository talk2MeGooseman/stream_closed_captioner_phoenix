export const sendEvent = (name, data) => {
  const event = new CustomEvent(name, { detail: data })

  window.dispatchEvent(event)
}

export const onEvent = (name, callback) => {
  window.addEventListener(name, callback, false)
  return () => window.removeEventListener(name, callback)
}
