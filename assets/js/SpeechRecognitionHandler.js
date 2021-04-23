import debugLogger from "debug"

import SpeechRecognitionService from "./service/SpeechRecognitionService"

const debug = debugLogger("cc:speech-handler")

/**
 * @typedef
 * {{
 *    interim: string,
 *    final: string,
 *    session: number,
 * }} SpeechInterval
 */

const EVENT_TYPES = ["started", "stopped", "interim", "final"]

export default class SpeechRecognitionHandler {
  delayTime = 0

  constructor() {
    this.eventSubscribers = {}
    this.speechRecogService = new SpeechRecognitionService()

    this.speechRecogService.onSpeechIntervalCallback = this.onSpeechIntervals.bind(
      this
    )
    this.speechRecogService.onRecognitionEndCallback = this.onEndIntervals.bind(
      this
    )

    /**
     * Array of tuples containing the speech interval data and when
     * the data was received
     * @type {[SpeechInterval[], Date]}
     */
    this.interimDataQueue = []

    this.interimIntervalId = null

    this.setLanguage()
  }

  /**
   * Subscribe to Speech Recognition Handler events
   * @param {"started" | "stopped" | "interim" | "final"} event
   * @param {Function} callback
   */
  onEvent = (event, callback) => {
    if (!EVENT_TYPES.includes(event)) {
      console.log("Invalid event provided for subscription")
      return
    }
    this.eventSubscribers[event] = callback

    return () => {
      delete this.eventSubscribers[event]
    }
  }

  /**
   * Toggle the speech recognition on or off
   *
   * @memberof SpeechRecognitionHandler
   */
  toggleOn = () => {
    if (this.speechRecogService.speechToTextActive) {
      this.stopRecognition()
    } else {
      this.startRecognition()
    }
  }

  /**
   * @private
   */
  startRecognition = () => {
    debug("startRecognition")
    this.sendInterimDataWithDelay()
    this.speechRecogService.start()
    this.sendInterimDataWithDelay()
    if (this.eventSubscribers["started"]) {
      this.eventSubscribers["started"]()
    }
  }

  /**
   * @private
   */
  stopRecognition = () => {
    this.speechRecogService.stop()
    this.stopSendInterimDataInterval()
    debug("stopRecognition")
    if (this.eventSubscribers["stopped"]) {
      this.eventSubscribers["stopped"]()
    }
  }

  /**
   * Callback method to receive speech intervals from the
   * SpeechRecognitionService
   *
   * @private
   * @param {SpeechInterval} speechData
   */
  onSpeechIntervals(speechData) {
    this.interimDataQueue.push([speechData, Date.now()])
  }

  /**
   * Callback method to receive speech finalized interval text from
   * SpeechRecognitionService
   *
   * @private
   * @param {string} text
   */
  onEndIntervals(text) {
    debug("End Speech Interval", text)
    if (this.eventSubscribers["final"]) {
      this.eventSubscribers["final"](text)
    }
  }

  /**
   * Publishes the speech data based off the delayTime the user has set
   * @private
   */
  sendInterimDataWithDelay() {
    this.interimIntervalId = setInterval(() => {
      const callback = this.eventSubscribers["interim"]

      if (this.interimDataQueue.length === 0 || !callback) {
        return
      }

      if (Date.now() - this.interimDataQueue[0][1] >= this.delayTime) {
        const [speechData, timestamp] = this.interimDataQueue.shift()

        debug("Delayed: ", (Date.now() - timestamp) / 1000, "---", speechData)
        if (callback) {
          callback(speechData)
        }
      }
    }, 50)
  }

  /**
   *
   * @private
   */
  stopSendInterimDataInterval() {
    clearTimeout(this.interimIntervalId)
  }

  /**
   * The amount of time to delay publishing captions in seconds
   *
   * @param {Number} value
   */
  setDelayTime(value = 0) {
    this.delayTime = delayInput.value * 1000
  }

  /**
   * Set the spoken language of the user, so the recognition
   * service and properly transcribe it
   *
   * @param {string} language
   */
  setLanguage = (language = "en-US") => {
    this.speechRecogService.setLanguage(language)
  }

  /**
   * Events coming from OBS Websocket events
   *
   * @param { { data: { type: string, value } } } message
   * @memberof SpeechRecognitionHandler
   */
  handleOBSEvent = ({ data }) => {
    debug("OBS event received", data)
    switch (data.type) {
      case "stop": {
        const speechToTextButton = document.getElementById(
          "start-speech-to-text"
        )

        if (this.speechRecogService.speechToTextActive)
          speechToTextButton.click()
        break
      }
      case "scene_switch": {
        this.speechRecogService.pause()
        break
      }
      default:
        break
    }
  }
}
