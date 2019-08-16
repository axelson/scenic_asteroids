// NOTE: The contents of this file will only be executed if
// you uncomment its entry in "assets/js/app.js".

// To use Phoenix channels, the first step is to import Socket,
// and connect at the socket path in "lib/web/endpoint.ex".
//
// Pass the token on params as below. Or remove it
// from the params if you are not using authentication.
import {Socket} from "phoenix"

let socket = new Socket("/socket", {params: window.SocketExports})

// When you connect, you'll often need to authenticate the client.
// For example, imagine you have an authentication plug, `MyAuth`,
// which authenticates the session and assigns a `:current_user`.
// If the current user exists you can assign the user's token in
// the connection for use in the layout.
//
// In your "lib/web/router.ex":
//
//     pipeline :browser do
//       ...
//       plug MyAuth
//       plug :put_user_token
//     end
//
//     defp put_user_token(conn, _) do
//       if current_user = conn.assigns[:current_user] do
//         token = Phoenix.Token.sign(conn, "user socket", current_user.id)
//         assign(conn, :user_token, token)
//       else
//         conn
//       end
//     end
//
// Now you need to pass this token to JavaScript. You can do so
// inside a script tag in "lib/web/templates/layout/app.html.eex":
//
//     <script>window.userToken = "<%= assigns[:user_token] %>";</script>
//
// You will need to verify the user token in the "connect/3" function
// in "lib/web/channels/user_socket.ex":
//
//     def connect(%{"token" => token}, socket, _connect_info) do
//       # max_age: 1209600 is equivalent to two weeks in seconds
//       case Phoenix.Token.verify(socket, "user socket", token, max_age: 1209600) do
//         {:ok, user_id} ->
//           {:ok, assign(socket, :user, user_id)}
//         {:error, reason} ->
//           :error
//       end
//     end
//
// Finally, connect to the socket:
socket.connect()

// Now that you are connected, you can join channels with a topic:
let channel = socket.channel("lobby", window.SocketExports)

let onJoin = resp => {
  console.log("Joined!", resp)
  // alert("joined!");
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

export default socket
