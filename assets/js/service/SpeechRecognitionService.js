import uuid from "uuid/v4"
import * as workerTimers from 'worker-timers';

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

    if (this.isFinalSpeechResult(event.results)) {
      this.finalSpeechBuffer = this.interimSpeechBuffer
      this.interimSpeechBuffer = ""
    }
  }

  onRecognitionEnd() {
    if (!this._pause || this.finalSpeechBuffer.length > 0) {
      if (this.onRecognitionEndCallback && (this.lastFinal != this.speechData.final)) {
        this.lastFinal = this.speechData.final
        this.onRecognitionEndCallback(this.speechData)
      }
    }

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
    workerTimers.clearInterval(this.intervalId)
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
    this.intervalId = workerTimers.setInterval(() => {
      if (
        this.interimSpeechBuffer.length === 0 &&
        this.finalSpeechBuffer === this.lastSentFinalSpeechBuffer
      )
        return

      this.lastSentFinalSpeechBuffer = this.finalSpeechBuffer

      if (this.onSpeechIntervalCallback) {
        this.onSpeechIntervalCallback(this.speechData)
      }
    }, INTERVAL_TIMER)
  }

  get speechData() {
    return {
      session: this.sessionId,
      interim: this.interimSpeechBuffer,
      final: this.finalSpeechBuffer,
    }
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

  isFinalSpeechResult(speechArray) {
    const [speechResult] = speechArray
    return speechResult.isFinal == true
  }
}
