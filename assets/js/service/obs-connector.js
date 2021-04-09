import { T } from "ramda"

import { OBSWebSocket } from "../utils"

export default class OBSConnector {
  constructor() {
    if (OBSConnector.instance) {
      return OBSConnector.instance
    }

    OBSConnector.instance = this

    this.obs = new OBSWebSocket()
    this.connected = false
    this.eventListeners = {}

    return this
  }

  /**
   * Establishes connection with OBS WebSocket
   *
   * @param {*} { host, password, port }
   * @returns {Promise
   * @memberof OBSConnector
   */
  connect({ host, password, port } = {}) {
    this.password = password

    this.obs.on("socket.open", T)
    this.obs.on("socket.auth", this.disconnect)
    this.obs.on("socket.auth-failed", this.disconnect)
    this.obs.on("socket.ready", () => {
      this.connected = true
    })
    this.obs.on("socket.close", this.onClose)
    this.obs.on("event", (message) => {
      const event = message["update-type"]
      const listeners = this.eventListeners[event]

      if (listeners) {
        listeners.forEach((callback) => callback(message))
      }
    })

    return this.obs.connect(host, port, password)
  }

  onClose = () => {
    this.connected = false
    this.obs.removeAllListeners("socket.close")
  }

  disconnect = () => {
    this.obs.removeAllListeners("socket.open")
    this.obs.removeAllListeners("socket.auth")
    this.obs.removeAllListeners("socket.auth-failed")
    this.obs.removeAllListeners("socket.ready")
    this.obs.removeAllListeners("event")
    this.obs.disconnect()
    this.eventListeners = {}
  }

  on(event, callback) {
    this.obs.on(event, callback)
  }

  /**
   * Send an event to OBS
   *
   * @param {String} type
   * @param {Object} [fields={}]
   * @returns {Promise}
   * @memberof OBSConnector
   */
  sendEvent(type, fields = {}) {
    return this.obs.send({
      "request-type": type,
      ...fields,
    })
  }

  /**
   * Listen to an event from OBS
   *
   * @param {String} event
   * @param {function} callback
   * @returns {Promise}
   * @memberof OBSConnector
   */
  onEvent(event, callback) {
    if (!this.eventListeners[event]) {
      this.eventListeners[event] = []
    }
    this.eventListeners[event].push(callback)
  }

  /**
   * Send closed captioning text to OBS
   *
   * @param {String} text
   * @returns {Promise}
   * @memberof OBSConnector
   */
  sendCaptions(text = "") {
    return this.sendEvent("SendCaptions", {
      text,
    })
  }

  /**
   * Get all the scenes from OBS
   *
   * @returns {Promise.<{'current-scene': String , scenes: Array}>}
   * @memberof OBSConnector
   */
  getScenes() {
    return this.sendEvent("GetSceneList")
  }

  /**
   * Subscribe to stream stopped event
   *
   * @param {function} callback
   * @returns {Promise}
   * @memberof OBSConnector
   */
  onStreamStopped(callback) {
    this.onEvent("StreamStopped", callback)
  }

  /**
   * Subscribe to recording stopped event
   *
   * @param {function} callback
   * @returns {Promise}
   * @memberof OBSConnector
   */
  onRecordingStopped(callback) {
    this.onEvent("RecordingStopped", callback)
  }

  /**
   * Subscribe to scene switch event
   *
   * @param {function} callback
   * @returns {Promise}
   * @memberof OBSConnector
   */
  onSwitchScene(callback) {
    this.onEvent("SwitchScenes", callback)
  }
}
