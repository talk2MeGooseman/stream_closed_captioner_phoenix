import debugLogger from "debug"

import { ApplicationController } from "stimulus-use"

import { isNil, isEmpty } from "ramda"

// const debug = debugLogger("cc:obs-controller")
const debug = console.log

export default class extends ApplicationController {
  static targets = ["offButton", "onButton", "errorMarker", "errorMessage"]

  connect() {
    this.url = undefined
    this.enabled = false
  }

  disconnect() { }

  onUrlChange(e) {
    this.url = e.target.value
    this.dispatch("state", { enabled: this.enabled, url: this.url })
  }

  enable = () => {
    console.log("zoom")
    this.clearErrorMessage()

    if (this.enabled) {
      this.onButtonTarget.classList.add("hidden")
      this.offButtonTarget.classList.remove("hidden")
      this.errorMarkerTarget.classList.add("hidden")
      this.enabled = false
    } else {
      if (isEmpty(this.url) || isNil(this.url)) {
        this.errorMarkerTarget.classList.remove("hidden")
        this.displayErrorMessage("Please provide a URL for Zoom")
        return
      }

      this.onButtonTarget.classList.remove("hidden")
      this.offButtonTarget.classList.add("hidden")
      this.errorMarkerTarget.classList.add("hidden")
      this.enabled = true
    }

    this.dispatch("state", { enabled: this.enabled, url: this.url })
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
