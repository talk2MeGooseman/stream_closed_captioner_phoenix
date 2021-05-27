import SpeechRecognitionHandler from "../SpeechRecognitionHandler"
import { isBrowserCompatible } from "../utils"
import { forEach, isEmpty, isNil } from "ramda"
import { ApplicationController } from "stimulus-use"

const TURN_OFF_TXT = "Click to Stop Captions"

export default class extends ApplicationController {
  static targets = [
    "outputOutline",
    "realOutput",
    "finalOutput",
    "interimOutput",
    "start",
    "warning"
  ]

  static values = { language: String }

  removeEvents = []
  cachedButtonText = ""

  connect() {
    this.zoomData = {
      enabled: false,
    }

    this.twitchData = {
      enabled: true,
    }

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

      this.speechRecognitionHandler.setLanguage(this.languageValue || "en-US")

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
        this.speechRecognitionHandler.onEvent("final", this.receiveFinalMessage)
      )
      this.removeEvents.push(
        this.speechRecognitionHandler.onEvent("interim", this.receiveInterimMessage)
      )

      this.initBrowserChannelMessageListener()
      this.initOBSChannelListener()
    } else {
      this.warningTarget.textContent = "Sorry, right now Speech To Text is only supported on Google Chrome browser at the moment. Once other browsers add support for Speech To Text it will be enabled."
    }
  }

  disconnect() {
    this.removeEvents.forEach((e) => e())
  }

  onZoomChange({ detail: { enabled, url } }) {
    this.zoomData = {
      ...this.zoomData,
      enabled,
      url,
    }
  }

  onTwitchChange({ detail: { enabled } }) {
    console.log("twitch", enabled)
    this.twitchData = {
      enabled,
    }
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

  receiveInterimMessage = (data) => {
    const publishData = {
      ...data,
      sentOn: (new Date()).toISOString(),
      twitch: this.twitchData,
    }

    this.captionsChannel
      .push("publishInterim", publishData, 5000)
      .receive("ok", (response) => this.displayCaptions(response))
      .receive("error", (err) => console.log("phoenix error", err))
      .receive("timeout", () => console.log("timed out pushing"))
  }

  receiveFinalMessage = (data) => {
    if (!this.zoomData.enabled) return

    const publishData = {
      ...data,
      zoom: {
        ...this.zoomData,
        seq: this.getZoomSequence(this.zoomData.url)
      },
    }

    this.captionsChannel
      .push("publishFinal", publishData, 5000)
      .receive("ok", (response) => {
        const seq = this.getZoomSequence(this.zoomData.url) + 1
        this.setZoomSequence(this.zoomData.url, seq)
      })
      .receive("error", (err) => console.log("phoenix error", err))
      .receive("timeout", () => console.log("timed out pushing"))
  }

  displayCaptions = (captions) => {
    this.dispatch("payload", captions)

    this.outputOutlineTarget.classList.add("hidden")
    this.realOutputTarget.classList.remove("hidden")

    this.interimOutputTarget.textContent = captions.interim
    this.finalOutputTarget.textContent = captions.final
  }

  setZoomSequence = (url, value = 1) => {
    const urlObj = new URL(url)
    let id = urlObj.searchParams.get("id")

    localStorage.setItem(`zoom:${id}`, value)
  }

  getZoomSequence = (url) => {
    const urlObj = new URL(url)
    let id = urlObj.searchParams.get("id")

    const result = localStorage.getItem(`zoom:${id}`)
    if (!isNil(result)) {
      return parseInt(localStorage.getItem(`zoom:${id}`))
    }

    return 1
  }
}
