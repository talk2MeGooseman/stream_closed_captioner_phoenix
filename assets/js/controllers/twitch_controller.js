import debugLogger from "debug"

import { ApplicationController } from "stimulus-use"

import { isNil, isEmpty } from "ramda"

// const debug = debugLogger("cc:obs-controller")
const debug = console.log

export default class extends ApplicationController {
  static targets = ["offSwitch", "onSwitch", "errorMarker", "errorMessage"]

  connect() {
    this.enabled = true
  }

  disconnect() { }

  toggleOn = () => {
    this.clearErrorMessage()
    console.log("twitch")
    if (this.enabled) {
      this.onSwitchTarget.classList.add("hidden")
      this.offSwitchTarget.classList.remove("hidden")
      this.errorMarkerTarget.classList.add("hidden")
      this.enabled = false
    } else {
      this.onSwitchTarget.classList.remove("hidden")
      this.offSwitchTarget.classList.add("hidden")
      this.errorMarkerTarget.classList.add("hidden")
      this.enabled = true
    }

    this.dispatch("state", { enabled: this.enabled })
  }

  clearErrorMessage() {
    this.errorMessageTarget.classList.add("hidden")
    this.errorMessageTarget.innerText = ""
  }

  displayErrorMessage(text) {
    this.errorMessageTarget.classList.remove("hidden")
    this.errorMessageTarget.innerText = text
  }
}
