# Rocket Buddies

A whimsical 2D space adventure under development in **Godot 4.6 stable** (`4.6.stable.official.89cea1439`). The first playable milestone is a standalone Moon exploration toy.

## Run

Open `project.godot` in Godot 4.6 and press F6 on `modes/exploration/MoonExploration.tscn` to run the mode directly, or press F5 and choose **Play Demos → Explore the Moon**. The opening can be skipped.

On the Moon, move with WASD, arrow keys, or the left stick. Scan with Q or controller X, interact with E, Space, or controller A, restart with R or controller Y, and exit with Escape or controller B. Collect Moon Cheese, inspect the crater, offer the cheese to the hungry Meep on the right, then return to the rocket. Feeding the Meep consumes one cheese and adds the rescue to the demo result. Returning early produces an incomplete result without penalty.

The Meep occasionally strolls around its area and stops when approached or talking. Its comic bubble reveals dialogue a letter at a time. Press E/A or click the bubble to show the full line, then again to close it; Escape/B also closes it. Reduced motion shows the complete line immediately.

## Verify

```sh
godot --headless --path . --editor --quit
godot --headless --path . --script res://tests/test_moon_exploration.gd
```

## Project conventions

- One mode lives under `modes/<mode_name>/` and can be run directly during development.
- Screens emit navigation intent. The application shell owns transitions.
- Modes accept `ModeContext` and emit `ModeResult`; they do not decide the next mode.
- Input uses named actions in `project.godot`.
- Keep authored content separate from runtime state as the game grows.
- Add a focused test when introducing a rule or integration contract.

The Moon demo has a first pass of minimal SVG art and matching UI. Its palette and asset rules are in [`docs/02_VISUAL_DESIGN.md`](docs/02_VISUAL_DESIGN.md). The broader game design is in [`docs/`](docs/00_README.md).
