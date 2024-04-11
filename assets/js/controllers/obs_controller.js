import debugLogger from "debug"

import { Controller } from '@hotwired/stimulus'

import OBSWebSocket, { EventSubscription } from 'obs-websocket-js';
const obs = new OBSWebSocket();
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

export default class extends Controller {
  static targets = ["offButton", "onButton", "errorMarker", "errorMessage"]
  connected = false

  connect() {
    this.password = undefined
    this.port = 4455
    this.captionsFinalTextsCache = []
  }

  async disconnect() {
    await obs.disconnect()
    this.connected = false
    this.removeCaptionsEvent()
  }

  onPasswordChange(e) {
    this.password = e.target.value
  }

  onPortChange(e) {
    this.port = e.target.value
  }

  async connectToOBS() {
    if (isNil(this.port) || isEmpty(this.port)) {
      return this.displayErrorMessage("Port is missing.")
    }

    try {
      if (this.connected) {
        await obs.disconnect()
        this.connected = false
        this.updateButtonState(CONNECTION_STATE.DISCONNECTED)
      } else {
        this.updateButtonState(CONNECTION_STATE.CONNECTING)
        await this.enableOBSConnection()

        this.connected = true
        this.updateButtonState(CONNECTION_STATE.CONNECTED)
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
    if (this.connected) {
      return Promise.reject()
    }

    await obs.connect(
      `ws://127.0.0.1:${this.port}`,
      this.password,
    )

    return Promise.resolve(true)
  }

  onConnectionReady = () => {
    debug("Connection is Ready")
    obs.getScenes().then(this.onGetScenes)
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
    if (this.connected) {
      debug({ interim, final })
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

      this.sendCaptions(textToSendBuffer.join(". "))
    }
  }

  sendCaptions = async (text) => {
    await obs.call('SendStreamCaption', { captionText: text }).then(() => {
      debug("Captions sent to obs")
    }).catch((error) => {
      debug("Error sending captions to obs")
    });
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
