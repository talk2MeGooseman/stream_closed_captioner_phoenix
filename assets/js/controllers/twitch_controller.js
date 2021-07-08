import debugLogger from "debug"

import { ApplicationController } from "stimulus-use"

import { isNil, isEmpty } from "ramda"
import { appClient } from "../service/app-client"
import { GET_ME } from "../utils/graphql"
import * as workerTimers from 'worker-timers';

// const debug = debugLogger("cc:obs-controller")
const debug = console.log

export default class extends ApplicationController {
  static targets = ["offSwitch", "onSwitch", "errorMarker", "errorMessage"]

  connect() {
    this.enabled = false
    this.extensionInstalled = false

    this.fetchExtensionStatus()
  }

  fetchExtensionStatus = () => {
    appClient.request(GET_ME).then(({ me }) => {
      this.extensionInstalled = me.extensionInstalled

      if (this.extensionInstalled) {
        this.clearErrorMessage()
        this.enableExtension()
      } else {
        this.disableExtension()
        this.displayErrorMessage("You do not have the Stream Closed Captioner Extension installed, please visit the 'Quick Starts Instructions' to learn how.")
        workerTimers.setTimeout(this.fetchExtensionStatus, 2000)
      }
    })
  }

  disconnect() { }

  toggleOn = () => {
    if (!this.extensionInstalled) return

    this.clearErrorMessage()
    if (this.enabled) {
      this.disableExtension()
    } else {
      this.enableExtension()
    }
  }

  clearErrorMessage() {
    this.errorMessageTarget.classList.add("hidden")
    this.errorMessageTarget.innerText = ""
  }

  displayErrorMessage(text) {
    this.errorMessageTarget.classList.remove("hidden")
    this.errorMessageTarget.innerText = text
  }

  enableExtension() {
    this.onSwitchTarget.classList.remove("hidden")
    this.offSwitchTarget.classList.add("hidden")
    this.errorMarkerTarget.classList.add("hidden")
    this.enabled = true
    this.dispatch("state", { enabled: this.enabled })
  }

  disableExtension() {
    this.onSwitchTarget.classList.add("hidden")
    this.offSwitchTarget.classList.remove("hidden")
    this.errorMarkerTarget.classList.add("hidden")
    this.enabled = false
    this.dispatch("state", { enabled: this.enabled })
  }
}
