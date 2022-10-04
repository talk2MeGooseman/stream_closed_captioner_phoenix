import { isNil } from 'ramda';

let mediaRecorder;

if (navigator.mediaDevices.getUserMedia) {
  const constraints = { audio: true };

  const onSuccess = function (stream) {
    mediaRecorder = new MediaRecorder(stream, { mimeType: 'audio/webm' });
  };

  const onError = function (err) {
    console.log(`The following error occurred: ${err}`);
  };

  navigator.mediaDevices.getUserMedia(constraints).then(onSuccess, onError);
} else {
  console.error('getUserMedia not supported on your browser!');
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
