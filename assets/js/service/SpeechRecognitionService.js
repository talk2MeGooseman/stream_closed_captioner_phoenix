import { isEmpty, join, path, pipe, prop, head, map } from 'ramda';
import { v4 as uuidv4 } from 'uuid';
import * as workerTimers from 'worker-timers';
import debugLogger from "debug"

const debug = debugLogger("cc:recognition-service")

/**
 * Return true is the transcript received is the finalized speech
 * recognition result.
 *
 * @param {[{ isFinal: boolean }]} speechArray
 * @returns {boolean}
 */
const isFinalSpeechResult = pipe(head, prop('isFinal'));

/**
 * Convert the results of the speech recognition into a String
 * @param {SpeechRecognitionResultList} speechArray
 * @returns {string}
 */
const parseSpeechResults = pipe(
  map(path([0, 'transcript'])),
  join('')
);

export default class SpeechRecognitionService {
  constructor() {
    this.onSpeechInterimCallback = null;
    this.onSpeechFinalCallback = null;

    this.recognitionService = this.initSpeechRecognition();

    this.speechToTextActive = false;
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
    if (isEmpty(event.results) || this._pause) return;

    if (isFinalSpeechResult(event.results)) {
      let finalText = parseSpeechResults(event.results);
      this.publishFinalText(finalText)
    } else {
      let interimText = parseSpeechResults(event.results);
      this.publishInterimText(interimText)
    }
  }

  onRecognitionEnd() {
    if (this.speechToTextActive) {
      this.recognitionService.start();
    }
  }

  start() {
    this.recognitionService.start();
    this.speechToTextActive = true;
    this.sessionId = uuidv4();
  }

  stop() {
    this.recognitionService.abort();
    this.speechToTextActive = false;
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
    this.onSpeechFinalCallback = null;
    this.onSpeechInterimCallback = null;
  }

  setLanguage(lang) {
    this.recognitionService.lang = lang;
  }

  publishInterimText(text) {
    if (this.onSpeechInterimCallback) {
      debug("Publish Interim Text", { text })
      this.onSpeechInterimCallback({
        session: this.sessionId,
        interim: text,
        final: ''
      });
    }
  }

  publishFinalText(text) {
    if (this.onSpeechFinalCallback) {
      debug("Publish Final Text", { text })
      this.onSpeechFinalCallback({
        session: this.sessionId,
        interim: '',
        final: text
      })
    }
  }
}
