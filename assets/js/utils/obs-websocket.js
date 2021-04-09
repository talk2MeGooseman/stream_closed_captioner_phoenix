/* eslint-disable complexity */
/* eslint-disable max-statements */
import debugLogger from "debug"
import EventEmitter from "eventemitter3"
import Sha256Hash from "sha.js/sha256"
import { isNil } from "ramda"

const debug = debugLogger("cc:obs-websocket")

/*
 * Handle responses from server
 *
 * @param id
 * @param message
 */
function handleCallback(id, message) {
  const promise = this._promises[id]

  if (promise) {
    if (message.status === "error") {
      promise.reject(new Error(message.error))
    } else {
      promise.resolve(message)
    }

    delete this._promises[id]
  } else if (message.status === "error") {
    this.emit("error", message.error, message)
  }
}

/**
 * Handle general updates
 *
 * @param type
 * @param message
 */
function handleUpdate(type, message) {
  this.emit("event", message)
  this.emit(type, message)
}

/**
 * Handle socket opening
 */
function socketOnOpen() {
  if (this._connecting) {
    const { resolve, reject } = this._connecting

    this.send({ "request-type": "GetAuthRequired" }).then(
      ({ authRequired }) => {
        resolve({ authRequired })

        if (authRequired) {
          this.login()
        } else {
          this.emit("socket.ready")
        }
      },
      (err) => reject(err)
    )

    this._connecting = null
  }

  this.emit("socket.open")
}

/**
 * Handle socket messages
 *
 * @param message
 */
function socketOnMessage(message) {
  let received = null

  try {
    received = JSON.parse(message.data)
  } catch (error) {
    this.emit("error", error)
  }

  if (!received) {
    return
  }

  debug("receive", received)

  const type = received["update-type"]

  if (type) {
    handleUpdate.call(this, type, received)
  } else {
    handleCallback.call(this, received["message-id"], received)
  }
}

/**
 * Handle socket errors
 *
 * @param error
 */
function socketOnError(error) {
  debug("socket.error", error)
  this.emit("socket.error", error)
}

const disconnectReasons = {
  1006: "OBS Websocket server not reachable. Please double you have OBS running, OBS Websockets plugin installed, and the correct port configured.",
}

/**
 * Handle socket close events
 *
 * @param event
 */
function socketOnClose(event) {
  if (this._connecting) {
    let message = "Unknown Error"

    if (event.code in disconnectReasons) {
      message = disconnectReasons[event.code]
    } else if (event.message) {
      // eslint-disable-next-line prefer-destructuring
      message = event.message
    }

    const error = new Error(message)

    error.event = event

    debug("socket.close", message)
    this._connecting.reject(error)
    this._connecting = null
  }

  this.emit("socket.close")
}

export class OBSWebSocket extends EventEmitter {
  constructor() {
    super()

    this._connecting = null
    this._idCounter = 1
    this._promises = {}
    this._socket = undefined
    this._password = null
  }

  /**
   * Connect to OBS remote
   *
   * @param {string} [host="localhost"]
   * @param {number} [port=4444]
   * @param {string}
   * @returns {Promise}
   * @memberof OBSRemote
   */
  // eslint-disable-next-line default-param-last
  connect(host = "localhost", port = 4444, password) {
    debug("connect", "init")
    if (this._socket) {
      debug("connect", "closing existing socket")
      // this.removeListeners()
      this._socket.close()
    }

    return new Promise((resolve, reject) => {
      this._password = password
      this._connecting = { resolve, reject }

      const url = `ws://${host}:${port}`

      this._socket = new WebSocket(url)
      this._socket.addEventListener("open", socketOnOpen.bind(this))
      this._socket.addEventListener("message", socketOnMessage.bind(this))
      this._socket.addEventListener("error", socketOnError.bind(this))
      this._socket.onclose = socketOnClose.bind(this)
    })
  }

  /**
   * Convenience method for logging in
   *
   * @returns {Promise}
   */
  async login() {
    debug("login", "begin login")
    const { authRequired, salt, challenge } = await this.send({
      "request-type": "GetAuthRequired",
    })

    if (!authRequired) {
      debug("login", "no auth needed")
      this.emit("socket.ready")
      return true
    }

    if (isNil(this._password)) {
      debug("login", "password missing")
      this.emit("socket.auth")
      return false
    }

    const authHash = new Sha256Hash()

    authHash.update(this._password)
    authHash.update(salt)
    const authResponse = new Sha256Hash()

    authResponse.update(authHash.digest("base64"))
    authResponse.update(challenge)
    const auth = authResponse.digest("base64")

    try {
      await this.send({
        "request-type": "Authenticate",
        auth,
      })

      debug("login", "auth successful")
      this.emit("socket.ready")
    } catch (error) {
      debug("login", "auth failed")
      this.emit("socket.auth-failed")
    }

    return true
  }

  /**
   * Close socket connection
   */
  disconnect() {
    if (this._socket) {
      debug("disconnect")
      this._socket.close()
      this.removeListener()
    }
  }

  removeListeners() {
    this._socket.removeEventListener("open", socketOnOpen.bind(this))
    this._socket.removeEventListener("message", socketOnMessage.bind(this))
    this._socket.removeEventListener("error", socketOnError.bind(this))
  }

  /**
   * Sends raw message to OBS remote
   *
   * @param message
   * @returns {Promise}
   */
  send(message) {
    return new Promise((resolve, reject) => {
      if (this._socket) {
        const id = this._nextID()

        this._promises[id] = { resolve, reject }

        message["message-id"] = id

        debug("send", message)

        this._socket.send(JSON.stringify(message))
      } else {
        throw new Error("Connection isn't opened")
      }
    })
  }

  /**
   * Get ID for next request
   *
   * @returns {string}
   * @private
   */
  _nextID() {
    // eslint-disable-next-line no-plusplus
    return String(this._idCounter++)
  }
}
