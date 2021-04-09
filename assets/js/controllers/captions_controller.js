import SpeechRecognitionHandler from "../SpeechRecognitionHandler"
import { isBrowserCompatible } from "../utils"
import { forEach, isEmpty } from "ramda"
import { ApplicationController } from "stimulus-use"

const TURN_OFF_TXT = "Click to Stop Captions"

export default class extends ApplicationController {
  static targets = [
    "outputOutline",
    "realOutput",
    "finalOutput",
    "interimOutput",
    "start",
  ]

  removeEvents = []
  cachedButtonText = ""

  connect() {
    if (isBrowserCompatible()) {
      import("../channels").then(this.successfulSocketConnection)

      // Need to open websocket channel
      // createSpeechChannel()
      this.ccActivityBroadcaster = new BroadcastChannel("cc-active")

      if (window._speechHandler) {
        this.speechRecognitionHandler = window._speechHandler
      } else {
        this.speechRecognitionHandler = window._speechHandler = new SpeechRecognitionHandler()
      }

      this.speechRecognitionHandler.setLanguage("en-US")

      this.removeEvents.push(
        this.speechRecognitionHandler.onEvent(
          "started",
          this.recognitionStarted.bind(this)
        )
      )
      this.removeEvents.push(
        this.speechRecognitionHandler.onEvent(
          "stopped",
          this.recognitionStopped.bind(this)
        )
      )
      this.removeEvents.push(
        this.speechRecognitionHandler.onEvent("interim", this.sendMessage)
      )

      this.initLanguageChangeListener()
      this.initBrowserChannelMessageListener()
      this.initOBSChannelListener()
    }
  }

  disconnect() {
    this.removeEvents.forEach((e) => e())
  }

  successfulSocketConnection = ({ captionsChannel }) => {
    this.captionsChannel = captionsChannel
    this.startTarget.disabled = false
  }

  initOBSChannelListener = () => {
    this.obsChannel = new BroadcastChannel("obs_channel")
    this.obsChannel.onmessage = (message) => this.handleOBSEvent(message)
  }

  startCaptions = () => {
    this.speechRecognitionHandler.toggleOn()
  }

  initLanguageChangeListener = () => {
    // document.body.addEventListener("stimulus-reflex:success", this.setLanguage)
  }

  initBrowserChannelMessageListener = () => {
    this.ccActivityBroadcaster.onmessage = (message) =>
      this.handleCCActiveInAnotherWindow(message)
  }

  /**
   * Broadcast CC activity to all browser windows with the dashboard open
   *
   * @memberof SpeechRecognitionHandler
   */
  publishActivityToBrowser = () => {
    this.ccActivityBroadcaster.postMessage({
      event: "CC_ACTIVE",
    })
  }

  /**
   * Disables the CC button if speech to text is active
   *
   * @memberof SpeechRecognitionHandler
   */
  handleCCActiveInAnotherWindow = () => {
    if (!this.speechToTextActive) {
      disableCCButton()
    }
  }

  recognitionStarted = () => {
    window.onbeforeunload = () =>
      "Navigating away will stop Closed Captioning, are you sure?"

    this.cachedButtonText = this.startTarget.textContent
    this.startTarget.textContent = "Click to Stop Captions"
    this.startTarget.classList.remove("btn-primary")
    this.startTarget.classList.add("btn-warning")

    try {
      gtag("event", "start", {
        // eslint-disable-next-line camelcase
        event_category: "CC",
      })
    } catch (error) {
      // Do nothing
    }
  }

  recognitionStopped = () => {
    window.onbeforeunload = null

    this.startTarget.classList.add("btn-primary")
    this.startTarget.classList.remove("btn-warning")
    this.startTarget.textContent = this.cachedButtonText

    try {
      gtag("event", "stop", {
        // eslint-disable-next-line camelcase
        event_category: "CC",
      })
    } catch (error) {
      // Do nothing
    }
  }

  sendMessage = (data) => {
    this.captionsChannel
      .push("publish", data, 5000)
      .receive("ok", this.displayCaptions)
      .receive("error", (err) => console.log("phoenix errored", err))
      .receive("timeout", () => console.log("timed out pushing"))
  }

  displayCaptions = (captions) => {
    this.dispatch("payload", captions)

    this.outputOutlineTarget.classList.add("hidden")
    this.realOutputTarget.classList.remove("hidden")

    this.interimOutputTarget.textContent = captions.interim
    this.finalOutputTarget.textContent = captions.final
  }
}
