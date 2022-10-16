import { isNil } from 'ramda';

let mediaRecorder;

if (navigator.mediaDevices.getUserMedia) {
  const constraints = { audio: true };

  const onSuccess = function onSuccess(stream) {
    mediaRecorder = new MediaRecorder(stream, { mimeType: 'audio/webm' });
  };

  const onError = function onError() { };

  navigator.mediaDevices.getUserMedia(constraints).then(onSuccess, onError);
}

export const startMediaRecorder = (callback) => {
  if (isNil(mediaRecorder)) throw new Error('MediaRecorder is not initialized');

  mediaRecorder.start(1000);

  mediaRecorder.ondataavailable = function (evt) {
    if (evt.data.size > 0) {
      callback(evt.data);
    }
  };
};

export const stopMediaRecorder = () => {
  mediaRecorder.stop();
};

export const isMediaRecorderActive = () => mediaRecorder.state === 'recording';
