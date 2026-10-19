# Starlight Rescue

A small arcade game made with [LÖVE](https://love2d.org/) 11.5: fly your ship around, collect falling stars and dodge the drones hunting you.

![Love2D](https://img.shields.io/badge/Love2D-11.5-purple) ![Language](https://img.shields.io/badge/Language-Lua-blue)

## Running

Install LÖVE 11.5, then from this folder run:

```
love .
```

On Windows you can also drag the project folder onto `love.exe`.

## Controls

| Action        | Keyboard            | Gamepad      |
|---------------|---------------------|--------------|
| Move          | Arrow keys / WASD   | Left stick / D-pad |
| Start / Retry | Enter / Space / R   | A / Start    |
| Pause         | P / Esc             | Start        |
| Back to menu  | Q (paused), Esc (game over) | Back  |
| Mute          | M                   | Y            |
| Quit          | Esc (title screen)  | Back (title screen) |

The game also pauses itself when the window loses focus.

## How to play

- **Blue stars**: 10 points. **Gold stars**: 50 points. **Green stars**: an extra life (up to 5).
- **Red spiky stars** appear after 50 points. Touching one costs a life.
- Collect stars quickly in a row to build a **combo** multiplier (up to ×5).
- **Drones** chase you. They get faster as your score rises, and another drone joins every 250 points (up to 4).
- After a hit you blink and are invulnerable for a moment.
- **Power-ups** appear every so often:
  - **Shield**: absorbs one hit.
  - **Magnet**: pulls nearby stars toward you.
  - **Boost**: makes your ship faster.
- Your best score is saved between sessions.

## Project layout

```
main.lua          game states and the game loop
conf.lua          window settings
src/config.lua    every tuning value (speeds, spawn rates, durations)
src/player.lua    the ship
src/enemies.lua   chasing drones
src/stars.lua     falling collectibles
src/powerups.lua  shield / magnet / boost
src/effects.lua   starfield, particles, popups, screen shake
src/audio.lua     sound effects and music, generated in code
src/ui.lua        HUD, title, pause and game-over screens
src/input.lua     keyboard and gamepad mapping
src/save.lua      high score file
```

To rebalance the game, edit `src/config.lua`.

## Building

```
powershell -ExecutionPolicy Bypass -File build.ps1
```

This creates `dist/StarlightRescue.love` (runs anywhere LÖVE is installed) and `dist/StarlightRescue-win/`, a standalone Windows folder you can zip and share. Pass `-LovePath` if LÖVE isn't installed in `C:\Program Files\LOVE`.

## License

MIT — feel free to fork, remix, and share.
