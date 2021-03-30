import { Socket } from "phoenix"

let socket
if (window.userToken) {
  socket = new Socket("/socket", { params: { token: window.userToken } })
  socket.connect()
}

export default socket
