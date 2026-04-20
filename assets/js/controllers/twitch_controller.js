import { isNil } from "ramda"
import { ApplicationController } from "stimulus-use"
import * as workerTimers from "worker-timers"

import { appClient } from "../service/app-client"
import { GET_ME } from "../utils/graphql"

export default class extends ApplicationController {
  static targets = ["offSwitch", "onSwitch", "errorMarker", "errorMessage"]

  static values = {
    maxRetryAttempts: { type: Number, default: 10 },
    retryBaseDelayMs: { type: Number, default: 2000 },
    maxRetryDelayMs: { type: Number, default: 30_000 },
  }

  connect() {
    this.enabled = false
    this.extensionInstalled = false
    this.retryAttempts = 0
    this.retryTimeout = null

    this.fetchExtensionStatus()
  }

  fetchExtensionStatus = () => {
    appClient.request(GET_ME)
      .then(({ me }) => {
        this.extensionInstalled = !isNil(me) && me.extensionInstalled

        if (this.extensionInstalled) {
          this.retryAttempts = 0
          this.clearRetryTimeout()
          this.clearErrorMessage()
          return this.enableExtension()
        }
        this.disableExtension()
        this.displayErrorMessage("You do not have the Stream Closed Captioner Extension installed, please visit the 'Quick Starts Instructions' to learn how.")
        return this.scheduleExtensionStatusRetry()

      })
      .catch(() => {
        this.disableExtension()
        this.displayErrorMessage("Could not verify Twitch extension status. Check your connection and try again.")
        return this.scheduleExtensionStatusRetry()
      })
  }

  disconnect() {
    this.clearRetryTimeout()
  }

  scheduleExtensionStatusRetry() {
    if (this.retryAttempts >= this.maxRetryAttemptsValue) {
      return
    }

    this.clearRetryTimeout()

    const delay = Math.min(
      this.retryBaseDelayMsValue * 2 ** this.retryAttempts,
      this.maxRetryDelayMsValue,
    )

    this.retryAttempts += 1
    this.retryTimeout = workerTimers.setTimeout(this.fetchExtensionStatus, delay)
  }

  clearRetryTimeout() {
    if (isNil(this.retryTimeout)) {
      return
    }

    workerTimers.clearTimeout(this.retryTimeout)
    this.retryTimeout = null
  }

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
    this.errorMessageTarget.textContent = ""
  }

  displayErrorMessage(text) {
    this.errorMessageTarget.classList.remove("hidden")
    this.errorMessageTarget.textContent = text
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
