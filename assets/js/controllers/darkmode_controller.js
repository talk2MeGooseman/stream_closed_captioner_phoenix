import { ApplicationController } from "stimulus-use"

export default class extends ApplicationController {
  static targets = ["darkmodeOff", "darkmodeOn"]

  connect() {
    if (this.isDarkmode()) {
      this.darkmodeIconOn()
    } else {
      this.darkmodeIconOff()
    }
  }

  darkmodeIconOff() {
    this.darkmodeOnTarget.classList.remove('hidden')
    this.darkmodeOffTarget.classList.add('hidden')
  }

  darkmodeIconOn() {
    this.darkmodeOnTarget.classList.add('hidden')
    this.darkmodeOffTarget.classList.remove('hidden')
  }

  toggle() {
    if (this.isDarkmode()) {
      this.darkmodeIconOff()
      document.documentElement.classList.remove('dark')
      localStorage.theme = 'light'
    } else {
      this.darkmodeIconOn()
      document.documentElement.classList.add('dark')
      localStorage.theme = 'dark'
    }
  }

  isDarkmode() {
    return localStorage.theme === 'dark' || (!('theme' in localStorage) && window.matchMedia('(prefers-color-scheme: dark)').matches)
  }
}
