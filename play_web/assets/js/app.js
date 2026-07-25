import "phoenix_html"
import {socket, lobbyChannel} from "./socket.js"
import game from "./game.js"
import { start } from "./main.js"

start(socket, lobbyChannel)
