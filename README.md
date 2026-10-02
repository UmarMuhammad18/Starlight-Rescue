# Starlight Rescue

A fast, polished arcade game made with **LÖVE (Love2D)**.

Pilot your golden ship through deep space, collect falling stars, dodge hostile drones, grab power-ups, and chase high scores.

![Love2D](https://img.shields.io/badge/Love2D-11.4+-purple) ![Language](https://img.shields.io/badge/Language-Lua-blue)

> **Tip:** Run the game (`love .`), take a screenshot, save it as `screenshot.png` in the repo root, then add this line under the description in the README:
> `![Starlight Rescue gameplay](screenshot.png)`

## Features

- Smooth 8-directional movement + gamepad support
- Chasing enemies that scale with score
- Falling stars + special **power-ups**:
  - **Shield** – absorb one hit
  - **Time Slow** – slow all enemies
  - **Magnet** – pull stars toward you
  - **2× Multiplier** – double score for a while
  - **Extra Life**
- Combo system that rewards rapid collecting
- Particle effects, screen shake, player trail & invulnerability frames
- Parallax starfield background
- Persistent high score
- Title screen, pause, and game-over states
- Clean modular codebase

## How to Run

1. Install [LÖVE](https://love2d.org/) (11.4 or newer recommended).
2. Clone or download this repository.
3. Drag the folder onto the Love2D executable, **or** run from terminal:

```bash
love .
```

(or `love /path/to/Starlight-Rescue`)

## Controls

| Action          | Keys / Input              |
|-----------------|---------------------------|
| Move            | WASD or Arrow Keys        |
| Move (gamepad)  | Left stick                |
| Pause           | P or Escape               |
| Start           | Space or Enter             |
| Restart         | R or Space (on game over) |
| Title screen    | Escape (from game over)   |

## Project Structure

```
Starlight-Rescue/
├── main.lua          # Entry point
├── conf.lua          # Window & module settings
├── config.lua        # Balancing values & colors
├── utils.lua         # Math helpers
├── background.lua    # Parallax starfield
├── particles.lua     # Simple particle system
├── player.lua        # Player ship + power-up timers
├── enemy.lua         # Chasing drones
├── star.lua          # Collectibles & power-ups
├── game.lua          # Core loop, states, scoring
└── README.md
```

## Tips for High Scores

- Keep the combo alive — points scale with it.
- Prioritize power-ups, especially Shield and Magnet.
- Don’t get greedy near multiple drones.
- Difficulty and enemy count rise with your score.

## Future Ideas

- Sound effects & music (drop `.ogg` files into an `assets/` folder and load them)
- More enemy types (zig-zag, shooter)
- Achievements / daily challenges
- Mobile touch controls
- Sprite art instead of procedural shapes

## License

MIT — feel free to fork, remix, and share.

---

Made with ❤️ and LÖVE.
