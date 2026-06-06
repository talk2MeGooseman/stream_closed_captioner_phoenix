import { ApplicationController, useClickOutside } from "stimulus-use"

export default class extends ApplicationController {
  get menuTarget() {
    return this.element.querySelector('div[data-target="dropdown.menu"]')
  }

  connect() {
    this.toggleClass = this.data.get("class") || "hidden"
    useClickOutside(this)
  }

  toggle() {
    this.menuTarget.classList.toggle(this.toggleClass)
  }

  clickOutside() {
    this.menuTarget.classList.add(this.toggleClass)
  }
}
