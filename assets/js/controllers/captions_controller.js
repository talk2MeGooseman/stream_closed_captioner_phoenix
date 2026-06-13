import SpeechRecognitionHandler from "../SpeechRecognitionHandler"
import { isBrowserCompatible } from "../utils"
import { Controller } from '@hotwired/stimulus'
import { getZoomSequence, setZoomSequence } from "../service/zoom-sequence"
import { Channel } from "phoenix"
import debugLogger from "debug"

const debug = debugLogger("cc:caption-controller")
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

export default class extends Controller {
  static targets = [
    "outputOutline",
    "realOutput",
    "finalOutput",
    "interimOutput",
    "translationOutput",
    "confidence",
    "confidenceFill",
    "confidencePct",
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
  /** @type {?SpeechRecognitionHandler} */
  speechRecognitionHandler = null


  connect() {
    if (isBrowserCompatible()) {
      /**
       * @type {Promise<{ captionsChannel: Channel }>}
       */
      const channel = import("../channels")
      channel.then(this.successfulSocketConnection)

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
        this.speechRecognitionHandler.onEvent("final", this.receiveFinalMessage.bind(this))
      )
      this.removeEvents.push(
        this.speechRecognitionHandler.onEvent("interim", this.receiveInterimMessage.bind(this))
      )
      this.removeEvents.push(
        this.speechRecognitionHandler.onEvent("error", (event) =>
          this.dispatch("error", { detail: { error: event?.error } })
        )
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
    debug("zoom change", { enabled, url })
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

  /**
   * Receive phoenix Channel
   * @param {{ captionsChannel: Channel}} param0
   */
  successfulSocketConnection = ({ captionsChannel }) => {
    this.captionsChannel = captionsChannel
    this.startTarget.disabled = false

    this.captionsChannel.on("stream.offline", () => this.speechRecognitionHandler.stop())
  }

  initOBSChannelListener = () => {
    this.obsChannel = new BroadcastChannel("obs_channel")
    this.obsChannel.onmessage = (message) => this.handleOBSEvent(message)
  }

  startCaptions = () => {
    this.speechRecognitionHandler.toggleOn()

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

    this.dispatch("started")

    this.cachedButtonText = this.startTarget.textContent
    this.startTarget.textContent = "Click to Stop Captions"
    this.startTarget.classList.remove("btn-primary")
    this.startTarget.classList.add("btn-warning")
  }

  recognitionStopped = () => {
    window.onbeforeunload = null

    this.dispatch("stopped")

    this.startTarget.classList.add("btn-primary")
    this.startTarget.classList.remove("btn-warning")
    this.startTarget.textContent = this.cachedButtonText
  }

  receiveInterimMessage = (data) => {
    debug('interim', data)
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
    debug('final', data)
    // Confidence is dashboard-only; keep it off the channel payload and apply
    // it on the "ok" reply so the chip lands together with the rendered caption.
    const { confidence, ...speechData } = data

    if (this.zoomData.enabled) {
      const publishData = {
        ...speechData,
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
          this.displayCaptions(response, confidence)
        })
    } else {
      const publishData = {
        ...speechData,
        sentOn: (new Date()).toISOString(),
        twitch: this.twitchData,
      }

      this.captionsChannel
        .push("publishFinal", publishData, 5000)
        .receive("ok", (response) => this.displayCaptions(response, confidence))
    }
  }

  // Per-utterance meter beside the preview tag. Only final results carry a
  // usable score (interim confidence is 0 in Chrome), and some engines never
  // report one — the chip stays hidden until the first real value arrives.
  displayConfidence = (confidence) => {
    if (!this.hasConfidenceTarget || confidence == null) return

    const pct = Math.round(confidence * 100)
    const level = confidence >= 0.8 ? "high" : confidence >= 0.5 ? "fair" : "low"

    this.confidenceTarget.classList.remove("hidden")
    this.confidenceTarget.dataset.level = level
    this.confidenceFillTarget.style.width = `${pct}%`
    this.confidencePctTarget.textContent = `${pct}%`
  }

  // confidence is only passed for final results; interim calls leave it null
  // so the chip keeps its last value rather than flickering between captions.
  displayCaptions = (captions, confidence = null) => {
    this.dispatch("payload", { detail: { ...captions } })

    this.outputOutlineTarget.classList.add("hidden")
    this.realOutputTarget.classList.remove("hidden")

    this.interimOutputTarget.textContent = captions.interim
    this.finalOutputTarget.textContent = captions.final

    this.displayConfidence(confidence)

    this.displayTranslations(captions)
  }

  // Mirror the translated text in the preview, below the original caption.
  // Frame-type aware: interim frames (final === "") carry no translations and must keep
  // the last translation on screen; a final caption with no translations clears stale text.
  displayTranslations = (captions) => {
    if (!this.hasTranslationOutputTarget) return

    const translations = captions.translations
    if (translations && Object.keys(translations).length > 0) {
      this.translationOutputTarget.replaceChildren()

      for (const lang in translations) {
        const { name, text } = translations[lang]
        const p = document.createElement("p")
        p.className = "caplive__t"
        p.textContent = `${name}: ${text}`
        this.translationOutputTarget.appendChild(p)
      }
    } else if (captions.translation_error) {
      // Surface genuine failures (atoms serialize to JSON strings: "timeout" / "failed")
      this.translationOutputTarget.replaceChildren()
      const p = document.createElement("p")
      p.className = "caplive__t caplive__t--error"
      p.textContent = "Translations temporarily unavailable"
      this.translationOutputTarget.appendChild(p)
    } else if (captions.final) {
      this.translationOutputTarget.replaceChildren()
    } else if (
      this.translationOutputTarget.querySelector(".caplive__t--error")
    ) {
      // Interim frame (no translations, no error, not final): if the previous
      // frame left an error banner on screen, clear it so a transient failure
      // self-heals once captions resume. A good translation (no error node) is
      // left untouched, preserving the last on-screen text.
      this.translationOutputTarget.replaceChildren()
    }
  }

}
