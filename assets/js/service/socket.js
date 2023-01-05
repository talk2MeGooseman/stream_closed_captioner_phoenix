import { Socket } from "phoenix"

/**
 * The socket connection
 * @type {Socket}
 */
let socket
if (window.userToken) {
  socket = new Socket("/socket", { params: { token: window.userToken } })
  socket.connect()
}

export default socket
