import debugLogger from "debug"

import { ApplicationController } from "stimulus-use"

import OBSConnector from "../service/obs-connector"
import { capitalize } from "../utils"
import { isNil, isEmpty } from "ramda"

// const debug = debugLogger("cc:obs-controller")
const debug = console.log

const CAPTIONS_MAX_LENGTH = 128
const CONNECTION_STATE = {
  DISCONNECTED: "Connect",
  CONNECTING: "Connecting",
  CONNECTED: "Connected",
  ERROR: "Error",
}

export default class extends ApplicationController {
  static targets = ["offButton", "onButton", "errorMarker", "errorMessage"]

  connect() {
    this.password = undefined
    this.port = 4444
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
    console.log("obs")
    if (isNil(this.port) || isEmpty(this.port)) {
      return this.displayErrorMessage("Port is missing.")
    }

    try {
      if (this.obsConnector.connected) {
        this.obsConnector.disconnect()
        this.updateButtonState(CONNECTION_STATE.DISCONNECTED)
      } else {
        this.updateButtonState(CONNECTION_STATE.CONNECTING)
        const isConnected = await this.enableOBSConnection()
        if (isConnected) {
          this.updateButtonState(CONNECTION_STATE.CONNECTED)
        }
      }
    } catch (error) {
      this.updateButtonState(CONNECTION_STATE.ERROR, error)
    }
  }

  updateButtonState = (state, message) => {
    this.clearErrorMessage()

    switch (state) {
      case CONNECTION_STATE.CONNECTING:
        break
      case CONNECTION_STATE.CONNECTED:
        debug("Connected")
        this.onButtonTarget.classList.remove("hidden")
        this.offButtonTarget.classList.add("hidden")
        this.errorMarkerTarget.classList.add("hidden")
        break
      case CONNECTION_STATE.DISCONNECTED:
        debug("Disconnected")
        this.onButtonTarget.classList.add("hidden")
        this.offButtonTarget.classList.remove("hidden")
        this.errorMarkerTarget.classList.add("hidden")
        break
      case CONNECTION_STATE.ERROR:
        debug("Error Occurred")
        this.onButtonTarget.classList.add("hidden")
        this.offButtonTarget.classList.remove("hidden")
        this.errorMarkerTarget.classList.remove("hidden")
        this.displayErrorMessage(message)
        break
      default:
        break
    }
  }

  clearErrorMessage() {
    this.errorMessageTarget.classList.add("hidden")
    this.errorMessageTarget.innerText = ""
  }

  displayErrorMessage(text) {
    this.errorMessageTarget.classList.remove("hidden")
    this.errorMessageTarget.innerText = text
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

    return Promise.resolve(true)
  }

  onConnectionReady = () => {
    debug("Connection is Ready")
    this.obsConnector.getScenes().then(this.onGetScenes)
  }

  onAuthNeeded = () => {
    debug("Auth is needed to connect")
    this.updateButtonState(
      CONNECTION_STATE.ERROR,
      "OBS Websocket requires a password"
    )
  }

  onAuthFail = () => {
    debug("Auth has failed")
    this.updateButtonState(
      CONNECTION_STATE.ERROR,
      "OBS Websocket password was incorrect"
    )
  }

  // eslint-disable-next-line no-empty-function
  onConnectionClose = () => { }

  onCaptionsReceived = ({ detail: { interim, final } }) => {
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
