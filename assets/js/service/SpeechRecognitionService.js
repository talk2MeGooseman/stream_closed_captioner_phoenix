import uuid from "uuid/v4"

const INTERVAL_TIMER = 1000

export default class SpeechRecognitionService {
  constructor() {
    this.onSpeechIntervalCallback = null
    this.onRecognitionEndCallback = null

    this.recognitionService = this.initSpeechRecognition()

    this.speechToTextActive = false
    this.finalSpeechBuffer = ""
    this.lastSentFinalSpeechBuffer = ""
    this.interimSpeechBuffer = ""
    this.sessionId = uuid()
    this._pause = false

    this.recognitionService.onresult = (event) =>
      this.onRecognitionResult(event)
    this.recognitionService.onend = () => this.onRecognitionEnd()
  }

  initSpeechRecognition() {
    const SpeechRecognition =
      window.SpeechRecognition || window.webkitSpeechRecognition

    const recognitionService = new SpeechRecognition()

    recognitionService.lang = "en-US"
    recognitionService.interimResults = true
    recognitionService.maxAlternatives = 1
    return recognitionService
  }

  onRecognitionResult(event) {
    if (event.results === "" || this._pause) return
    this.interimSpeechBuffer = this.parseSpeechResults(event.results)
  }

  // eslint-disable-next-line complexity
  onRecognitionEnd() {
    if (!this._pause || this.interimSpeechBuffer.length > 0) {
      this.finalSpeechBuffer = this.interimSpeechBuffer
      if (this.onRecognitionEndCallback)
        this.onRecognitionEndCallback(this.finalSpeechBuffer)
    }

    this.interimSpeechBuffer = ""

    if (this.speechToTextActive) {
      this.recognitionService.start()
    } else {
      this.finalSpeechBuffer = ""
      this.lastSentFinalSpeechBuffer = ""
    }
  }

  start() {
    this.recognitionService.start()
    this.speechToTextActive = true
    this.startSpeechInterval()
    this.sessionId = uuid()
  }

  stop() {
    this.recognitionService.abort()
    this.speechToTextActive = false
    clearInterval(this.intervalId)
  }

  pause(value) {
    if (value) {
      this._pause = value
    } else {
      this._pause = !this._pause
    }
  }

  destroy() {
    this.stop()
    this.onRecognitionEndCallback = null
    this.onSpeechIntervalCallback = null
  }

  setLanguage(lang) {
    this.recognitionService.lang = lang
  }

  startSpeechInterval() {
    // eslint-disable-next-line complexity
    this.intervalId = setInterval(() => {
      if (
        this.interimSpeechBuffer.length === 0 &&
        this.finalSpeechBuffer === this.lastSentFinalSpeechBuffer
      )
        return

      this.lastSentFinalSpeechBuffer = this.finalSpeechBuffer

      if (this.onSpeechIntervalCallback) {
        this.onSpeechIntervalCallback({
          session: this.sessionId,
          interim: this.interimSpeechBuffer,
          final: this.finalSpeechBuffer,
        })
      }
    }, INTERVAL_TIMER)
  }

  parseSpeechResults(speechArray) {
    let results = ""

    for (const key in speechArray) {
      // eslint-disable-next-line no-prototype-builtins
      if (speechArray.hasOwnProperty(key)) {
        const [result] = speechArray[key]

        results += result.transcript
      }
    }

    return results
  }
}
