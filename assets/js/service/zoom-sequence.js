setZoomSequence = (url, value = 1) => {
  const urlObj = new URL(url)
  let id = urlObj.searchParams.get("id")

  localStorage.setItem(`zoom:${id}`, value)
}

getZoomSequence = (url) => {
  const urlObj = new URL(url)
  let id = urlObj.searchParams.get("id")

  const result = localStorage.getItem(`zoom:${id}`)
  if (!isNil(result)) {
    return parseInt(localStorage.getItem(`zoom:${id}`))
  }

  return 1
}
