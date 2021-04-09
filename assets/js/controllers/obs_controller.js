import debugLogger from "debug"

import BaseController from "./base_controller"

import OBSConnector from "../service/obs-connector"
import { sendEvent, onEvent, capitalize } from "../utils"

const debug = debugLogger("cc:obs-controller")

const CAPTIONS_MAX_LENGTH = 128
const CONNECTION_STATE = {
  DISCONNECTED: "Connect",
  CONNECTING: "Connecting",
  CONNECTED: "Connected",
}

export default class extends BaseController {
  static targets = ["offButton", "onButton", "onMarker", "errorMarker"]

  connect() {
    this.password = undefined
    this.port = undefined
    this.obsConnector = new OBSConnector()
    this.captionsFinalTextsCache = []
  }

  disconnect() {
    this.obsConnector.disconnect()
    this.removeCaptionsEvent()
  }

  onPasswordChange(e) {
    this.password = e.target.value
  }

  onPortChange(e) {
    this.port = e.target.value
  }

  async connectToOBS() {
    try {
      if (this.obsConnector.connected) {
        this.obsConnector.disconnect()
        this.updateButtonState(CONNECTION_STATE.DISCONNECTED)
      } else {
        this.updateButtonState(CONNECTION_STATE.CONNECTING)
        await this.enableOBSConnection()
        this.updateButtonState(CONNECTION_STATE.CONNECTED)
      }
    } catch (error) {
      this.updateButtonState(CONNECTION_STATE.DISCONNECTED)
      sendEvent("error", error)
    }
  }

  updateButtonState = (state) => {
    switch (state) {
      case CONNECTION_STATE.CONNECTING:
        break
      case CONNECTION_STATE.CONNECTED:
        console.log("connected")
        this.onButtonTarget.classList.remove("hidden")
        this.onMarkerTarget.classList.remove("hidden")
        this.offButtonTarget.classList.add("hidden")
        this.errorMarkerTarget.classList.add("hidden")
        break
      case CONNECTION_STATE.DISCONNECTED:
        console.log("disconnected")
        this.onButtonTarget.classList.add("hidden")
        this.onMarkerTarget.classList.add("hidden")
        this.offButtonTarget.classList.remove("hidden")
        this.errorMarkerTarget.classList.remove("hidden")
      default:
        break
    }
  }

  async enableOBSConnection() {
    if (this.obsConnector.connected) {
      return Promise.reject()
    }

    await this.obsConnector.connect({
      password: this.password,
      port: this.port,
    })

    this.obsConnector.on("socket.ready", this.onConnectionReady)
    this.obsConnector.on("socket.auth", this.onAuthNeeded)
    this.obsConnector.on("socket.auth-failed", this.onAuthFail)
    this.obsConnector.on("socket.close", this.onConnectionClose)
    this.obsConnector.onStreamStopped(this.onStreamStop)
    this.obsConnector.onSwitchScene(this.onSwitchScene)

    this.removeCaptionsEvent = onEvent("captions", this.onCaptionReceived)

    return Promise.resolve(true)
  }

  onConnectionReady = () => {
    debug("Connection is Ready")
    this.obsConnector.getScenes().then(this.onGetScenes)
  }

  onAuthNeeded = () => {
    debug("Auth is needed to connect")
    this.updateButtonState(false)
    sendEvent("error", "OBS Websocket requires a password")
  }

  onAuthFail = () => {
    debug("Auth has failed")
    this.updateButtonState(false)
    sendEvent("error", "OBS Websocket password was incorrect")
  }

  // eslint-disable-next-line no-empty-function
  onConnectionClose = () => {}

  onCaptionReceived = ({ detail: { final, interim } }) => {
    debug("Captions Received", { final, interim })
    if (this.obsConnector.connected) {
      const textToSendBuffer = []

      if (interim.length > 0) textToSendBuffer.push(capitalize(interim))

      const lastCached = this.captionsFinalTextsCache[
        this.captionsFinalTextsCache.length - 1
      ]
      const formatFinalText = capitalize(final)

      if (lastCached !== formatFinalText && final.length > 0) {
        this.captionsFinalTextsCache.push(formatFinalText)
        if (this.captionsFinalTextsCache.length > 50)
          this.captionsFinalTextsCache.shift()
      }

      const leftOverCharacterCount = CAPTIONS_MAX_LENGTH - interim.length

      let combinedFinalText = this.captionsFinalTextsCache.join(". ")

      if (combinedFinalText.length > leftOverCharacterCount) {
        const amountToRemove = combinedFinalText.length - leftOverCharacterCount

        combinedFinalText = combinedFinalText.substring(amountToRemove)
        const nextSpace = combinedFinalText.indexOf(" ")

        combinedFinalText = combinedFinalText.substring(nextSpace)
      }

      if (combinedFinalText.length > 0) {
        textToSendBuffer.unshift(combinedFinalText)
      }

      this.obsConnector.sendCaptions(textToSendBuffer.join(". "))
    }
  }

  onGetScenes = (data) => {
    debug("Get Scene", data)
  }

  onStreamStop = () => {
    debug("Stream Stopped")
    this.obsBroadcast.postMessage({ type: "stop" })
  }

  onSwitchScene = (data) => {
    debug("Scene Change", data)
  }
}
