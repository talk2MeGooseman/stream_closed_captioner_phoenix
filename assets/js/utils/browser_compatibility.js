export const isBrowserCompatible = () => {
  try {
    const isChromium = window.chrome
    const winNav = window.navigator
    const vendorName = winNav.vendor
    const isOpera = typeof window.opr !== "undefined"
    const isIEedge = winNav.userAgent.indexOf("Edge") > -1
    const isEdge = winNav.userAgent.indexOf("Edg") > -1

    const isChrome =
      isChromium !== null &&
      typeof isChromium !== "undefined" &&
      vendorName === "Google Inc." &&
      isOpera === false &&
      isIEedge === false &&
      isEdge === false

    if (!isChrome) {
      return false
    }
  } catch (error) {
    return false
  }

  return true
}
