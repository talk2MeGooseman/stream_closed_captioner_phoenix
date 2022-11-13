import SpeechRecognitionHandler from "../SpeechRecognitionHandler"
import { isBrowserCompatible } from "../utils"
import { ApplicationController } from "stimulus-use"
import { startDeepgram, stopDeepgram, isDeepgramActive } from "../service/deepgram"
import { getZoomSequence, setZoomSequence } from "../service/zoom-sequence"
import { isEmpty } from "ramda"

const TURN_OFF_TXT = "Click to Stop Captions"

/**
 * @typedef
 * {{
 *    ...SpeechInterval,
 *   twitch: {
 *    enabled: boolean
 *   },
 *   sentOn: string,
 * }} TwitchCaptionPayload
 */

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
  zoomData = {
    enabled: false,
  }
  twitchData = {
    enabled: false,
  }


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
      this.warningTarget.textContent = "Sorry, right now Speech To Text is only supported on Google Chrome, Edge, and Safari browser at the moment. Once other browsers add support for Speech To Text it will be enabled."
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
    this.twitchData = {
      enabled,
    }
  }

  successfulSocketConnection = ({ captionsChannel }) => {
    this.captionsChannel = captionsChannel
    this.startTarget.disabled = false

    this.captionsChannel.on("deepgram", this.displayCaptions)
  }

  initOBSChannelListener = () => {
    this.obsChannel = new BroadcastChannel("obs_channel")
    this.obsChannel.onmessage = (message) => this.handleOBSEvent(message)
  }

  startCaptions = () => {
    // Need to check if it's deepgram enabled account and choose flow
    if (window.permissions.isDeepgramEnabled) {
      if (isDeepgramActive()) {
        stopDeepgram()
        this.recognitionStopped()
      } else {
        startDeepgram(this.sendAudioStream)
        this.recognitionStarted()
      }
    } else {
      this.speechRecognitionHandler.toggleOn()
    }

    this.captionsChannel
      .push("active", {})
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
  }

  recognitionStopped = () => {
    window.onbeforeunload = null

    this.startTarget.classList.add("btn-primary")
    this.startTarget.classList.remove("btn-warning")
    this.startTarget.textContent = this.cachedButtonText
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
  }

  receiveFinalMessage = (data) => {
    if (!this.zoomData.enabled) return

    const publishData = {
      ...data,
      zoom: {
        ...this.zoomData,
        seq: getZoomSequence(this.zoomData.url)
      },
    }

    this.captionsChannel
      .push("publishFinal", publishData, 5000)
      .receive("ok", (response) => {
        const seq = getZoomSequence(this.zoomData.url) + 1
        setZoomSequence(this.zoomData.url, seq)
      })
  }

  displayCaptions = (captions) => {
    this.dispatch("payload", captions)

    this.outputOutlineTarget.classList.add("hidden")
    this.realOutputTarget.classList.remove("hidden")

    this.interimOutputTarget.textContent = captions.interim
    this.finalOutputTarget.textContent = captions.final
  }

  sendAudioStream = async (data) => {
    var audioBlob = new Blob([data], {
      type: "audio/webm"
    });
    const arrayBuffer = await audioBlob.arrayBuffer();

    this.captionsChannel
      .push("publishBlob", arrayBuffer, 5000)
  }
}
