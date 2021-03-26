import BaseController from "./base_controller"
import SpeechRecognitionHandler from "../SpeechRecognitionHandler"
import { isBrowserCompatible } from "../utils"
import { isEmpty } from "ramda"

export default class extends BaseController {
  static targets = ["output"]

  connect() {
    console.log("Captions Controller")
    if (isBrowserCompatible()) {
      // Need to open websocket channel
      // createSpeechChannel()
      this.ccActivityBroadcaster = new BroadcastChannel("cc-active")

      this.speechRecognitionHandler = new SpeechRecognitionHandler()

      this.speechRecognitionHandler.setLanguage("en-US")
      this.speechRecognitionHandler.onEvent("started", this.recognitionStarted)
      this.speechRecognitionHandler.onEvent("stopped", this.recognitionStopped)
      this.speechRecognitionHandler.onEvent("interim", this.sendMessage)

      this.initLanguageChangeListener()
      this.initBrowserChannelMessageListener()
      this.initOBSChannelListener()
    }
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

    console.log("STARTED")
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

    console.log("STOPPED")
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
    console.log(data)
    this.outputTarget.textContent = isEmpty(data.interim)
      ? data.final
      : data.interim
  }
}
