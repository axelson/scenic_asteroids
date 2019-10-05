import {Socket} from "phoenix"

let socket = new Socket("/socket", {params: window.SocketExports})

if (document.querySelector('#game')) {
  socket.connect()

  let channel = socket.channel("lobby", window.SocketExports)

  let onJoin = resp => {
    console.log("Joined!", resp)
  }

  window.onDirection = (direction) => {
    direction = determineDirection(direction);
    console.log(`Send direction: ${direction}`)
    channel.push(`player_direction`, {direction: direction});
  }

  window.onClearDirection = (direction) => {
    direction = determineDirection(direction);
    channel.push(`clear_player_direction`, {direction: direction});
  }

  window.onSendShoot = (relX, relY) => {
    var obj = {x: relX, y: relY}
    console.log("obj", obj)

    channel.push(`try_shoot`, obj);
  }

  window.onClearShooting = () => {
    channel.push('clear_shooting', {});
  }

  if (window.SocketExports) {
    channel.join()
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

export default socket
