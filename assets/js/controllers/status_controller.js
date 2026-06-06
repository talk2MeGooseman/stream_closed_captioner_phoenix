import { Controller } from "@hotwired/stimulus"
import { isBrowserCompatible } from "../utils"
import socket from "../service/socket"
import debugLogger from "debug"

const debug = debugLogger("cc:status-controller")

/**
 * Drives the dashboard "System Status" section. Each live row is addressed by
 * its `data-status-key` and updated in place (value text + the `data-state`
 * attribute that colours the status dot). Valid states: "ok" | "warn" | "idle".
 */
export default class extends Controller {
  static targets = ["row"]

  socketRefs = []
  micPermissionStatus = null
  listening = false
  onDeviceChange = () => this.refreshMicFromPermission()

  connect() {
    this.compatible = isBrowserCompatible()
    this.initBrowser()
    this.initSpeechEngine()
    this.initMicrophone()
    this.initRealtime()
  }

  disconnect() {
    if (socket && this.socketRefs.length) socket.off(this.socketRefs)
    this.socketRefs = []
    if (this.micPermissionStatus) this.micPermissionStatus.onchange = null
    navigator.mediaDevices?.removeEventListener?.("devicechange", this.onDeviceChange)
  }

  // ---- row helpers ----

  rowFor(key) {
    return this.element.querySelector(`[data-status-key="${key}"]`)
  }

  setRow(key, value, state) {
    const row = this.rowFor(key)
    if (!row) return
    const val = row.querySelector(".sysrow__val")
    if (val) val.textContent = value
    row.dataset.state = state
  }

  // ---- Twitch Extension ----

  // Driven by twitch_controller's `twitch:installed` event once it has verified
  // install status via GraphQL. Until then the row shows the server-rendered
  // "Checking…" placeholder (or "Not connected" when not signed in with Twitch).
  onExtensionStatus(event) {
    switch (event?.detail?.status) {
      case "installed":
        this.setRow("extension", "Installed", "ok")
        break
      case "not-installed":
        this.setRow("extension", "Not installed", "warn")
        break
      default:
        this.setRow("extension", "Check failed", "warn")
    }
  }

  // ---- Browser ----

  initBrowser() {
    if (this.compatible) {
      this.setRow("browser", "Compatible", "ok")
    } else {
      this.setRow("browser", "Not supported", "warn")
    }
  }

  // ---- Speech Engine ----

  initSpeechEngine() {
    if (this.compatible) {
      this.setRow("speech", "Idle", "idle")
    } else {
      this.setRow("speech", "Unavailable", "warn")
    }
  }

  onSpeechStarted = () => {
    this.listening = true
    this.setRow("speech", "Listening", "ok")
    if (this.micPermissionStatus?.state !== "denied") {
      this.displayMicLabel()
    }
  }

  onSpeechStopped = () => {
    this.listening = false
    if (this.compatible) this.setRow("speech", "Idle", "idle")
    this.refreshMicFromPermission()
  }

  onSpeechError = (event) => {
    const error = event?.detail?.error
    debug("speech error", error)
    if (error === "not-allowed" || error === "service-not-allowed") {
      this.setRow("mic", "Blocked", "warn")
    }
  }

  // ---- Microphone ----

  initMicrophone() {
    navigator.mediaDevices?.addEventListener?.("devicechange", this.onDeviceChange)

    if (!navigator.permissions?.query) {
      // Permissions API unusable (older Safari / Firefox) — fall back to a
      // neutral state; the recognition `onerror` signal upgrades to "Blocked".
      this.setRow("mic", "Ready", "idle")
      return
    }

    navigator.permissions
      .query({ name: "microphone" })
      .then((status) => {
        this.micPermissionStatus = status
        this.refreshMicFromPermission()
        status.onchange = () => this.refreshMicFromPermission()
      })
      .catch(() => {
        // Some browsers reject the 'microphone' PermissionName outright.
        this.setRow("mic", "Ready", "idle")
      })
  }

  refreshMicFromPermission() {
    const state = this.micPermissionStatus?.state
    if (state === "granted") {
      this.displayMicLabel()
    } else if (state === "denied") {
      this.setRow("mic", "Blocked", "warn")
    } else {
      this.setRow("mic", "Ready", "idle")
    }
  }

  // Resolve the default audio-input device label (Web Speech uses the system
  // default mic; there is no per-app selection). Labels are only present once
  // mic permission is granted — returns null otherwise.
  getDefaultMicLabel() {
    if (!navigator.mediaDevices?.enumerateDevices) return Promise.resolve(null)
    return navigator.mediaDevices
      .enumerateDevices()
      .then((devices) => {
        const inputs = devices.filter((d) => d.kind === "audioinput" && d.label)
        if (!inputs.length) return null
        const def = inputs.find((d) => d.deviceId === "default") || inputs[0]
        return def.label.replace(/^Default\s+-\s+/i, "")
      })
      .catch(() => null)
  }

  displayMicLabel() {
    this.getDefaultMicLabel().then((label) => {
      if (this.micPermissionStatus?.state === "denied") return
      this.setRow("mic", label || (this.listening ? "Active" : "Allowed"), "ok")
    })
  }

  // ---- Realtime Link ----

  initRealtime() {
    if (!socket) {
      this.setRow("realtime", "Disconnected", "warn")
      return
    }

    const connected = socket.isConnected()
    this.setRow(
      "realtime",
      connected ? "Connected" : "Connecting…",
      connected ? "ok" : "idle"
    )

    this.socketRefs.push(socket.onOpen(() => this.setRow("realtime", "Connected", "ok")))
    this.socketRefs.push(socket.onClose(() => this.setRow("realtime", "Reconnecting", "idle")))
    this.socketRefs.push(socket.onError(() => this.setRow("realtime", "Disconnected", "warn")))
  }
}
