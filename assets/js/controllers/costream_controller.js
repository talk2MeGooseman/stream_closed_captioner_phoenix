import SpeechRecognitionHandler from "../SpeechRecognitionHandler"
import { isBrowserCompatible } from "../utils"
import { Controller } from "@hotwired/stimulus"
import { Socket } from "phoenix"
import debugLogger from "debug"

const debug = debugLogger("cc:costream-controller")

const BADGE_BASE = "rounded-full px-3 py-1"

/**
 * Guest ("co-streamer") caption dashboard.
 *
 * Unlike the host dashboard, this page has no logged-in user: the socket is
 * authenticated with the signed guest link token, and the channel topic is
 * the HOST's costream topic. The server pushes control events the UI must
 * honor: "muted" (stop forwarding indicator), "kicked" (link revoked live),
 * and "host_status" (whether the host is actively captioning).
 */
export default class extends Controller {
  static targets = [
    "start",
    "warning",
    "kicked",
    "connectionBadge",
    "hostBadge",
    "mutedBadge",
    "language",
    "finalOutput",
    "interimOutput",
  ]

  static values = {
    token: String,
    hostId: String,
    language: String,
  }

  removeEvents = []
  kicked = false

  connect() {
    if (!isBrowserCompatible()) {
      this.warningTarget.classList.remove("hidden")
      return
    }

    this.speechRecognitionHandler = new SpeechRecognitionHandler()
    this.speechRecognitionHandler.setLanguage(
      this.languageValue || "en-US"
    )

    this.removeEvents.push(
      this.speechRecognitionHandler.onEvent("started", this.recognitionStarted),
      this.speechRecognitionHandler.onEvent("stopped", this.recognitionStopped),
      this.speechRecognitionHandler.onEvent("interim", this.publishSpeech),
      this.speechRecognitionHandler.onEvent("final", this.publishSpeech)
    )

    this.joinChannel()
  }

  disconnect() {
    this.removeEvents.forEach((remove) => remove())
    if (this.speechRecognitionHandler) this.speechRecognitionHandler.stop()
    if (this.socket) this.socket.disconnect()
  }

  joinChannel() {
    this.socket = new Socket("/socket", {
      params: { costreamToken: this.tokenValue },
    })
    this.socket.connect()

    this.socket.onError(() => this.setConnectionBadge("error"))

    this.channel = this.socket.channel(`costream:${this.hostIdValue}`, {})

    this.channel.on("host_status", ({ active }) => this.setHostBadge(active))
    this.channel.on("muted", ({ muted }) => this.setMuted(muted))
    this.channel.on("kicked", () => this.handleKicked())

    this.channel
      .join()
      .receive("ok", ({ muted }) => {
        debug("joined costream channel")
        this.setConnectionBadge("connected")
        this.setMuted(muted)
        this.startTarget.disabled = false
      })
      .receive("error", (resp) => {
        debug("unable to join", resp)
        this.setConnectionBadge("error")
      })
  }

  toggleCaptions = () => {
    if (this.kicked) return
    this.speechRecognitionHandler.toggleOn()
  }

  languageChanged = () => {
    this.speechRecognitionHandler.setLanguage(this.languageTarget.value)
  }

  publishSpeech = (data) => {
    if (this.kicked) return

    // confidence is dashboard-only on the host page; guests don't send it
    const { confidence: _confidence, ...speechData } = data

    this.channel
      .push("publish", speechData, 5000)
      .receive("ok", (captions) => this.displayCaptions(captions))
      .receive("error", ({ reason }) => this.handlePublishError(reason))
  }

  handlePublishError = (reason) => {
    debug("publish rejected", reason)
    switch (reason) {
      case "muted":
        this.setMuted(true)
        break
      case "host_offline":
        this.setHostBadge(false)
        break
      default:
        break
    }
  }

  displayCaptions = (captions) => {
    // A successful publish implies the host is live and we're not muted.
    this.setHostBadge(true)
    this.interimOutputTarget.textContent = captions.interim
    if (captions.final) this.finalOutputTarget.textContent = captions.final
  }

  recognitionStarted = () => {
    window.onbeforeunload = () =>
      "Navigating away will stop your co-stream captions, are you sure?"
    this.startTarget.textContent = "Stop Captions"
  }

  recognitionStopped = () => {
    window.onbeforeunload = null
    this.startTarget.textContent = "Start Captions"
  }

  setConnectionBadge(state) {
    const badge = this.connectionBadgeTarget
    if (state === "connected") {
      badge.className = `${BADGE_BASE} bg-green-200 text-green-800`
      badge.textContent = "Connected"
    } else {
      badge.className = `${BADGE_BASE} bg-red-200 text-red-800`
      badge.textContent = "Connection problem — retrying…"
    }
  }

  setHostBadge(active) {
    const badge = this.hostBadgeTarget
    if (active) {
      badge.className = `${BADGE_BASE} bg-green-200 text-green-800`
      badge.textContent = "Streamer is captioning"
    } else {
      badge.className = `${BADGE_BASE} bg-gray-200 text-gray-700`
      badge.textContent = "Streamer offline — captions paused"
    }
  }

  setMuted(muted) {
    this.mutedBadgeTarget.classList.toggle("hidden", !muted)
  }

  handleKicked() {
    this.kicked = true
    this.speechRecognitionHandler.stop()
    this.kickedTarget.classList.remove("hidden")
    this.startTarget.disabled = true
    this.socket.disconnect()
  }
}
