import socket from '../service/socket';

// Now that you are connected, you can join channels with a topic:
export const captionsChannel = socket.channel(`captions:${window.userId}`, {});

captionsChannel
  .join()
  .receive('ok', (resp) => {
    console.log('Joined successfully', resp);
  })
  .receive('error', (resp) => {
    console.log('Unable to join', resp);
  });
