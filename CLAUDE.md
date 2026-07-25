# Scenic Asteroids

Asteroids clone in Elixir using the Scenic UI framework. Poncho project structure.

## Sub-projects

- `play/` - Core game logic (the `:play` app)
- `play_ui/` - Desktop UI via Scenic (the `:play_ui` app)
- `play_web/` - Phoenix web interface for multiplayer (the `:play_web` app)
- `fw/` - Nerves firmware for Raspberry Pi (the `:fw` app)

## Common commands

```sh
# Run the desktop game
cd play_ui && mix deps.get && iex -S mix

# Run the web interface
cd play_web && mix deps.get && iex -S mix phx.server
```

Each sub-project has its own `mix.exs` — run `mix` commands from within the relevant directory.
