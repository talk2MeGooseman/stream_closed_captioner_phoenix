import debugLogger from "debug"
import { isBrowserCompatible } from "../utils"

import { ApplicationController } from "stimulus-use"

// const debug = debugLogger("cc:obs-controller")
const debug = console.log

export default class extends ApplicationController {
  static targets = ["translationStatus", "bitsBalance"]

  connect() {
    if (isBrowserCompatible()) {
      import("../channels").then(this.successfulSocketConnection)
    }
  }

  disconnect() { }

  successfulSocketConnection = ({ captionsChannel }) => {
    this.captionsChannel = captionsChannel

    this.captionsChannel.on("transaction", ({ balance }) => {
      this.bitsBalanceTarget.innerHTML = balance
    })

    this.captionsChannel.on("translationActivated", ({ enabled, balance }) => {
      if (enabled) {
        this.translationStatusTarget.innerHTML = "Enabled"
        this.bitsBalanceTarget.innerHTML = balance
      }
    })
  }
}
