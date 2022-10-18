import { curry, isNil } from 'ramda';

const audio = {
  mediaRecorder: null
}

const constraints = { audio: true };

const onSuccess = function onSuccess(callback, stream) {
  audio.mediaRecorder = new MediaRecorder(stream, { mimeType: 'audio/webm' });

  if (isNil(audio.mediaRecorder)) throw new Error('MediaRecorder is not initialized');

  audio.mediaRecorder.start(1000);

  audio.mediaRecorder.ondataavailable = function onData(evt) {
    if (evt.data.size > 0) {
      callback(evt.data);
    }
  };
};

const curriedOnSuccess = curry(onSuccess);

const onError = function onError() { };

export const startDeepgram = (callback) => {
  if (navigator.mediaDevices.getUserMedia) {
    navigator.mediaDevices.getUserMedia(constraints)
      .then(
        curriedOnSuccess(callback),
        onError,
      );
  }
};

export const stopDeepgram = () => {
  audio.mediaRecorder.stop();
  delete audio.mediaRecorder;
};

export const isDeepgramActive = () => audio.mediaRecorder?.state === 'recording';
