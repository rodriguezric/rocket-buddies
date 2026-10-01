# Rocket Buddies

A whimsical 2D space adventure under development in **Godot 4.6 stable** (`4.6.stable.official.89cea1439`). The standalone demos are Moon exploration, Rocket Flight, Moon Cheese Hunt, and Meep Rescue.

## Run

Open `project.godot` in Godot 4.6 and press F5, then choose **Play Demos** and select a mode. The opening can be skipped. Each mode can also run directly with F6 on its scene under `modes/`.

On the Moon, move with WASD, arrow keys, or the left stick. Scan with Q or controller X, interact with E, Space, or controller A, restart with R or controller Y, and exit with Escape or controller B. Collect Moon Cheese, inspect the crater, offer the cheese to the hungry Meep on the right, then return to the rocket. Feeding the Meep consumes one cheese and adds the rescue to the demo result. Returning early produces an incomplete result without penalty.

The Meep occasionally strolls around its area and stops when approached or talking. Its comic bubble reveals dialogue a letter at a time. Press E/A or click the bubble to show the full line, then again to close it; Escape/B also closes it. Reduced motion shows the complete line immediately.

In Rocket Flight, steer with WASD, arrow keys, or the left stick. Hold Shift or controller RB to boost, spending fuel for faster travel. Collect stardust, fuel canisters, and the optional Moon Cheese comet; avoid asteroids and reach the Moon. Bumps cost fuel but never strand the rocket. Press R/Y to restart or Escape/B to return to the demo menu.

In Moon Cheese Hunt, move the highlighted patch with WASD, arrow keys, or the left stick. Scan with Q or controller X, read the heat and direction clue, then dig with E, Space, or controller A. You can also click a patch to select it and click again to dig. Scanner charges refill; all buried cheese can be found without a time limit. The mode returns collected cheese and scan/dig counts.

In Meep Rescue, move with WASD, arrow keys, or the left stick. Scan with Q or controller X to reveal the loose boulder, then use E, Space, or controller A near that rock to open a path. Pick up Moon Cheese, share it with the trapped Meep, and return to the rocket together. The Meep speaks in a comic bubble and follows Buddy after the rescue. The mode also accepts starting Moon Cheese through `ModeContext.parameters["moon_cheese"]` for future mission integration.

Each run starts with the rocket landing and the Buddy walking out. Controls unlock after the arrival. Returning to the rocket plays boarding, an engine shake, and takeoff; the Meep reacts before the scene fades back to the launcher. Reduced motion shortens the staging and removes shaking and jumping.

## Verify

```sh
godot --headless --path . --editor --quit
godot --headless --path . --script res://tests/test_moon_exploration.gd
godot --headless --path . --script res://tests/test_rocket_flight.gd
godot --headless --path . --script res://tests/test_moon_cheese_hunt.gd
godot --headless --path . --script res://tests/test_meep_rescue.gd
```

## Project conventions

- One mode lives under `modes/<mode_name>/` and can be run directly during development.
- Screens emit navigation intent. The application shell owns transitions.
- Modes accept `ModeContext` and emit `ModeResult`; they do not decide the next mode.
- Input uses named actions in `project.godot`.
- Keep authored content separate from runtime state as the game grows.
- Add a focused test when introducing a rule or integration contract.

The Moon demo has a first pass of minimal SVG art and matching UI. Its palette and asset rules are in [`docs/02_VISUAL_DESIGN.md`](docs/02_VISUAL_DESIGN.md). The broader game design is in [`docs/`](docs/00_README.md).
