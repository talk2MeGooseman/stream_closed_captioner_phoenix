import socket from '../service/socket';

// Now that you are connected, you can join channels with a topic:
export const captionsChannel = socket.channel(`captions:${window.userId}`, {});

captionsChannel
  .join()
  .receive('ok', (resp) => {
    console.debug('Joined successfully');
  })
  .receive('error', (resp) => {
    console.debug('Unable to join');
  });
