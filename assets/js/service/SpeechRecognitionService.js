import { v4 as uuidv4 } from 'uuid';
import * as workerTimers from 'worker-timers';

const INTERVAL_TIMER = 500;

export default class SpeechRecognitionService {
  constructor() {
    this.onSpeechIntervalCallback = null;
    this.onRecognitionEndCallback = null;

    this.recognitionService = this.initSpeechRecognition();

    this.speechToTextActive = false;
    this.finalSpeechBuffer = '';
    this.lastSentFinalSpeechBuffer = '';
    this.interimSpeechBuffer = '';
    this.sessionId = uuidv4();
    this._pause = false;

    this.recognitionService.onresult = (event) => this.onRecognitionResult(event);
    this.recognitionService.onend = () => this.onRecognitionEnd();
  }

  initSpeechRecognition() {
    const SpeechRecognition = window.SpeechRecognition || window.webkitSpeechRecognition;

    const recognitionService = new SpeechRecognition();

    recognitionService.lang = 'en-US';
    recognitionService.interimResults = true;
    recognitionService.maxAlternatives = 1;
    return recognitionService;
  }

  onRecognitionResult(event) {
    if (event.results === '' || this._pause) return;

    this.interimSpeechBuffer = SpeechRecognitionService.parseSpeechResults(event.results);

    if (SpeechRecognitionService.isFinalSpeechResult(event.results)) {
      this.finalSpeechBuffer = this.interimSpeechBuffer;
      this.interimSpeechBuffer = '';
    }
  }

  onRecognitionEnd() {
    if (!this._pause || this.finalSpeechBuffer.length > 0) {
      if (this.onRecognitionEndCallback && (this.lastFinal != this.speechData.final)) {
        this.lastFinal = this.speechData.final;
        this.onRecognitionEndCallback(this.speechData);
      }
    }

    if (this.speechToTextActive) {
      this.recognitionService.start();
    } else {
      this.finalSpeechBuffer = '';
      this.lastSentFinalSpeechBuffer = '';
    }
  }

  start() {
    this.recognitionService.start();
    this.speechToTextActive = true;
    this.startSpeechInterval();
    this.sessionId = uuidv4();
  }

  stop() {
    this.recognitionService.abort();
    this.speechToTextActive = false;
    workerTimers.clearInterval(this.intervalId);
  }

  pause(value) {
    if (value) {
      this._pause = value;
    } else {
      this._pause = !this._pause;
    }
  }

  destroy() {
    this.stop();
    this.onRecognitionEndCallback = null;
    this.onSpeechIntervalCallback = null;
  }

  setLanguage(lang) {
    this.recognitionService.lang = lang;
  }

  startSpeechInterval() {
    // eslint-disable-next-line complexity
    this.intervalId = workerTimers.setInterval(() => {
      if (
        this.interimSpeechBuffer.length === 0
        && this.finalSpeechBuffer === this.lastSentFinalSpeechBuffer
      ) { return; }

      this.lastSentFinalSpeechBuffer = this.finalSpeechBuffer;

      if (this.onSpeechIntervalCallback) {
        this.onSpeechIntervalCallback(this.speechData);
      }
    }, INTERVAL_TIMER);
  }

  get speechData() {
    return {
      session: this.sessionId,
      interim: this.interimSpeechBuffer,
      final: this.finalSpeechBuffer,
    };
  }

  /**
   * Parse speech results from speech recognition service
   * @param {SpeechRecognitionResultList} speechArray
   * @returns
   */
  static parseSpeechResults(speechArray) {
    const results = [];

    // map over result list and append transcript to results array
    for (let i = 0; i < speechArray.length; i++) {
      results.push(speechArray[i][0].transcript);
    }

    return results.join('');
  }

  static isFinalSpeechResult(speechArray) {
    const [speechResult] = speechArray;
    return speechResult.isFinal === true;
  }
}
