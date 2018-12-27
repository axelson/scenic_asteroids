```
 __
(_  _  _ __  o  _ 
__)(_ (/_| | | (_ 
   _____            __                       __     ___
  /  _  \   _______/  |_  ___________  ____ |__| __| _/______
 /  /_\  \ /  ___/\   __\/ __ \_  __ \/  _ \|  |/ __ |/  ___/
/    |    \\___ \  |  | \  ___/|  | \(  <_> )  / /_/ |\___ \ 
\____|__  /____  > |__|  \___  >__|   \____/|__\____ /____  >
        \/     \/            \/                     \/    \/ 
```

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
* `cd play_ui`
* `mix deps.get`
* `iex -S mix`

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

TODO:
* [x] Get basic nerves install working on network
* [x] Run scenic play application on nerves!
