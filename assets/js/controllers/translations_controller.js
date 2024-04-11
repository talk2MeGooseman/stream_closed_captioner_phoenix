import debugLogger from "debug"
import { isBrowserCompatible } from "../utils"

import { ApplicationController } from "stimulus-use"

const debug = debugLogger("cc:obs-controller")

export default class extends ApplicationController {
  static targets = ["translationStatus", "bitsBalance", "displayTranslations", "translationsList"]

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

  onCaptionsReceived = ({ detail: { translations } }) => {
    if (translations) {
      this.displayTranslationsTarget.classList.remove("hidden")
      this.translationsListTarget.innerHTML = ""

      for (const lang in translations) {
        const { name, text } = translations[lang];

        const liNode = document.createElement("li")
        liNode.classList.add('list-item')
        liNode.innerText = `${name}: ${text}`

        this.translationsListTarget.appendChild(liNode)
      }
    }
  }
}
