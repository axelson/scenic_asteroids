import {Socket} from "phoenix"

let socket = new Socket("/socket", {params: window.SocketExports})
let lobbyChannel

if (document.querySelector('#game')) {
  socket.connect()

  lobbyChannel = socket.channel("lobby", window.SocketExports)

  let onJoin = resp => {
    console.log("Joined!", resp)
  }

  window.onDirection = (direction) => {
    direction = determineDirection(direction);
    console.log(`Send direction: ${direction}`)
    lobbyChannel.push(`player_direction`, {direction: direction});
  }

  window.onClearDirection = (direction) => {
    direction = determineDirection(direction);
    lobbyChannel.push(`clear_player_direction`, {direction: direction});
  }

  window.onSendShoot = () => {
    lobbyChannel.push(`try_shoot`, {})
  }

  window.onSendShootDirection = (relX, relY) => {
    var obj = {x: relX, y: relY}
    // console.log("obj", obj)

    lobbyChannel.push(`try_shoot_direction`, obj);
  }

  window.onClearShooting = () => {
    lobbyChannel.push('clear_shooting', {});
  }

  window.onRotateLeft = () => {
    console.log("rot left!")
    lobbyChannel.push('rotate_left', {})
  }
  window.onClearRotateLeft = () => {
    lobbyChannel.push('clear_rotate_left', {})
  }

  window.onRotateRight = () => {
    lobbyChannel.push('rotate_right', {})
  }
  window.onClearRotateRight = () => {
    lobbyChannel.push('clear_rotate_right', {})
  }

  if (window.SocketExports) {
    lobbyChannel.join()
      .receive("ok", onJoin)
      .receive("error", resp => {
        var reason = resp["reason"]
        console.log(`Unable to join: ${reason}`)
        alert(`Unable to join: ${reason}`)
      })
  }
}

function determineDirection(direction) {
  switch(direction) {
    case "left": return "left"
    case "up": return "up"
    case "right": return "right"
    case "down": return "down"
    default: throw `unhandled direction ${direction}`
  }
}

export { socket, lobbyChannel }
