# Rocket Buddies — Design Documentation

## Vision
**Rocket Buddies** is a light-hearted, whimsical 2D space exploration adventure for children and families. Two buddies travel through the Solar System, manage their rocket, explore worlds, rescue adorable three-legged jellyfish-like **Meeps**, protect Moon Cheese from enormous twenty-legged **Merfs**, and complete missions inspired by real astronomy.

The game should feel like an adventure first. Learning happens because understanding space helps the player explore and solve problems.

## Product Structure
Rocket Buddies is intentionally built as **multiple independently playable demos that later compose into one full game**.

Each gameplay mode must:
1. Be launchable directly from a developer/demo menu.
2. Have a self-contained core loop.
3. Communicate through shared data contracts rather than depending on another mode's scene tree.
4. Be fun enough to test independently.
5. Eventually be entered through missions in the full game.

## Documents
- `01_GAME_DESIGN.md` — player experience, structure, progression, tone, modes.
- `02_VISUAL_DESIGN.md` — art direction, characters, worlds, UI and animation.
- `03_GAME_MECHANICS.md` — rules, resources, interactions, progression and educational mechanics.
- `04_GAMEPLAY_MODES.md` — specifications for each independently playable demo.
- `05_MISSIONS_AND_LEARNING.md` — mission framework and learning-through-play design.
- `06_TECHNICAL_ARCHITECTURE.md` — Godot architecture and integration contracts.
- `07_IMPLEMENTATION_PLAN.md` — Codex-oriented build order and milestones.
- `08_CONTENT_AND_DATA.md` — data-driven content schemas and examples.
- `09_VERTICAL_SLICE.md` — first complete Earth → Moon → Earth experience.

## Design Pillars
### Adventure First
Never interrupt fun merely to test the player. Facts should explain the world or provide useful clues.

### Small, Varied Activities
Rocket flight, exploration, cheese hunting, Meep rescue and Merf Mischief should feel different while contributing to one adventure.

### Cozy, Funny Space
Failure should normally produce funny setbacks rather than punishment.

### Curiosity Is Progress
Exploration, experimentation and discovery should be rewarded alongside mission completion.

### Buddy Cooperation
The fiction always emphasizes solving problems together, even in single-player.

### Scientifically Grounded, Whimsically Bent
Real Solar System properties form the foundation. Meeps, Merfs and Moon Cheese are knowingly fantastical additions.
