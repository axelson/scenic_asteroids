![Scenic Asteroids Logo](asteroids_r2_full.png)

# Scenic Asteroids

![Demo of Gameplay](game_demo.gif)

This is an Asteroids clone written in Elixir with Nerves, more for fun and
learning than for anything else. Also since the code (and behavior) is
relatively simple, I hope that it can serve as an example for Scenic, Nerves,
and as a simple [poncho
project](https://embedded-elixir.com/post/2017-05-19-poncho-projects/).

It is licensed under the 3-clause BSD license (see LICENSE) for details.

## Instructions

From the root of the repository run the following commands:
* Install [scenic pre-requisites](https://github.com/boydm/scenic_new#install-prerequisites)
* `cd play_ui`
* `mix deps.get`
* `iex -S mix`

Note: if scenic doesn't launch then you may be affected by the bug https://github.com/boydm/scenic_new/issues/36

Keys:
* `W` - Move up
* `A` - Move left
* `S` - Move down
* `D` - Move right
* `SPC` - Shoot an asteroid

Use the mouse to target the asteroids (or your finger if you're running with a
Nerves touch screen)

Have fun!

## Implementation Notes

[SchedEx](https://github.com/SchedEx/SchedEx) is used to implement the core
animation timer which runs at a rate of 60 frames per second.

Collision detection is incredibly basic and non-performant. Ideally either
scenic or a cooperating library would implement some collision detector helpers.
If you're interested in collision detection then please contribute to Scenic
[issue #91](https://github.com/boydm/scenic/issues/91).

# Projects

* `play/` - The main game logic
* `play_ui/` - Run via scenic on the desktop
* `fw/` - Run on a Nerves device with a touchscreen
  * Official Raspberry PI touch screen is supported

# JS Multiplayer (in progress)

TODO:
* [x] Get basic nerves install working on network
* [x] Run scenic play application on nerves!
* [x] Get scenic play web application working on nerves
* [x] PlayerControllers should die if the LobbyChannel for that user dies
* [x] Add multiplayer via Phoenix channels
  * [x] Add basic single player control via browser
  * [x] Add full single player control via browser
  * [x] Ask for player name
  * [x] Extract out player control state tracking from the Asteroids scene
  * [x] Add multiplayer control via browser
  * [x] Add a waiting screen/lobby
* [x] Assign a random color to each player and display it on screen and in their browser
* [x] Username max length of 8
* [ ] Track and display per-player score
* [ ] Add a full-screen button on the web client
* [ ] Clean up the view when playing the game (remove header?)
* [ ] Make ships spin if socket becomes disconnected
* [ ] Client javascript should resend keys periodically if they're still held down???
  * Or should we just dispense with the action timer and if the socket becomes disconnected then clear all actions?
* [ ] don't allow login with username "console" since that is reserved
* [ ] Waiting screen should show present users
* [ ] Deploy changes to nerves
* [ ] Add ability to boot people based on usernames

Maybe:
* [ ] Test possibility of rendering the current scene to an html canvas
* [ ] limit max players to 50
* [ ] fix restricting users to one UserSocket
* [ ] Convert from poncho to single application (with Boundary)?
* [ ] Display the join url somewhere?
* [ ] Set Phoenix Endpoint check_origin to a MFA tuple with Nerves.Network.status("wlan0").ipv4_address (and eth0, but preferring eth0)
* [ ] Splash screen add option to choose single player or multiplayer
  * [ ] Logo will come down and then the options appear
  * [ ] Pressing "SPC" or "s" will start single player immediately
  * [ ] Pressing "m" will start multi player immediately

The player javascript will record action states (not key states)
Actions:
* move_aim_direction (vector)
  * Note: This will also be used for aiming direction
* move_up
* move_right
* move_down
* move_left
* aim_direction (vector)
* shoot

Resources:
* https://developer.mozilla.org/en-US/docs/Games/Techniques/Control_mechanisms
  * Uses outdated version of phaser game library
* Phaser docs: https://photonstorm.github.io/phaser3-docs/index.html
* Simple phaser platformer game: https://www.phaser.io/examples/v3/view/games/firstgame/part7#
* Phaser touch notes: https://rexrainbow.github.io/phaser3-rex-notes/docs/site/touchevents/
* Phaser GameObject docs: https://photonstorm.github.io/phaser3-docs/Phaser.GameObjects.Image.html
* Phaser basic tutorial: https://phasergames.com/phaser-3-basics-images-text-and-click/
* Phaser basic shapes: https://www.phaser.io/examples/v3/view/geom/circle/area
* Phaser gamepad button https://photonstorm.github.io/phaser3-docs/Phaser.Input.Gamepad.Button.html

NOTE: if `move_aim_direction` is used then the other move and aim actions should
not be used. This will be enforced on the server-side.

* Channel actions
  * `set:actions`
    * When the channel receives this it will do a `GenServer.cast` to the Asteroids scene to update that players currently set actions
    * If the channel process goes down, the scene will clear all actions for that player
      * Perhaps this can be accomplished with a process link?


When the js player connects, then they get added to the js_players list if they get disconnected then their ship will begin floating for 10 seconds (maybe it will just spin around), after that it will die. This should be managed with a GenServer that is monitored by the Asteroids scene. The GenServer is started by the LobbyChannel (GameChannel) and is per-username so that you can refresh with the same name and .

Should have a list of live players and dead players
Players are unique based on their username, only one player with a given username can connect to the system at a time

When a ship dies it explodes in a small explosion

Extra content ideas:
* Add a top-5 leaderboard in the upper right
* Add a ship that will seek the nearest player ship
* Have large asteroids split into multiple
* Store a top-score on the touch-screen (in /root)

When the js player connects to the PlayChannel they get a PlayerController spun up for them (or get rejected if one is already running and taken). The PlayerController should be spun up under a new DynamicSupervisor

Then the PlayChannel adds the PlayerController to the Asteroids scene via GenServer.call which adds the new player to the live_players list, where they stay until they die.

Question:
* When do users switch from the lobby channel to the play channel? When the game starts?
* Is a message sent to them in the lobby channel?

Canvas load image notes:
* https://stackoverflow.com/questions/14757659/loading-an-image-onto-a-canvas-with-javascript
* https://github.com/pappersverk/scenic_driver_inky/blob/master/lib/scenic_driver_inky.ex
  * Captures fb data with rpi_fb_capture and displays it with inky
* Maybe I could just capture the fb with rpi_fb_capture and then send it over the phoenix channel
* picam streams image with a plug: https://github.com/elixir-vision/picam/blob/master/examples/picam_http/lib/picam_http/streamer.ex

WebRTC links
* https://github.com/smpallen99/webrtc_example
* DTLS is added in OTP 20

Random phaser code

+  var helloButtonRect = new Phaser.Geom.Rectangle(gameWidth / 2, gameHeight / 2, 100, 100);
+  var graphics = this.add.graphics({fillStyle: {color: 0x0000ff}});
+  graphics.fillRectShape(helloButtonRect);
+
+  const helloButton = this.add.text(gameWidth / 2, gameHeight / 2, 'Hello Phaser!', { fill: '#0f0', name: 'bob' });
+  helloButton.setInteractive();

Notes for updating socket config
+  # TODO: Implement this with nerves_network (on fw via config)
+  # socket "/socket", PlayWeb.UserSocket,
+  #   websocket: [check_origin: {PlayWeb.Auth, :check_origin, []}],
+  #   longpoll: false

Registry.select(Registry.Usernames, [{{:"$1", :"$2", :"$3"}, [], [{{:"$
1", :"$2", :"$3"}}]}])
Registry.select(:player_controllers, [{{:"$1", :"$2", :"$3"}, [],
[{{:"$1", :"$2", :"$3"}}]}])
