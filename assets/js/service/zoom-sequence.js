import { isNil } from 'ramda';

export const setZoomSequence = (url, value = 1) => {
  const urlObj = new URL(url);
  const id = urlObj.searchParams.get('id');

  localStorage.setItem(`zoom:${id}`, value);
};

export const getZoomSequence = (url) => {
  const urlObj = new URL(url);
  const id = urlObj.searchParams.get('id');

  const result = localStorage.getItem(`zoom:${id}`);
  if (!isNil(result)) {
    return parseInt(localStorage.getItem(`zoom:${id}`), 10);
  }

  return 1;
};
