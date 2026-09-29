# Implementation Plan — Godot + Codex

## Development Strategy
Build **vertical capability slices**, not the entire shared engine first.

Each phase must end in something playable.

## Phase 0 — Repository Contract
Create:
- Godot project,
- README,
- coding conventions,
- directory structure,
- input map,
- CI/test command if used,
- demo launcher shell.

Document exact Godot version.

**Done when:** project opens cleanly and demo launcher runs.

## Phase 1 — Exploration Toy
Build one Moon room with:
- Buddy movement,
- camera,
- interaction component,
- scanner,
- cheese collectible,
- return marker.

No missions yet.

**Done when:** moving, scanning and collecting are pleasant.

## Phase 2 — Exploration Demo
Add:
- objective display,
- one discovery,
- one Meep interaction,
- one Merf trigger,
- `ModeContext/ModeResult`.

**Done when:** Exploration runs standalone and returns a valid result.

## Phase 3 — Rocket Flight Demo
Implement independent flight scene, hazards, pickups, arrival and result contract.

## Phase 4 — Cheese Hunt Demo
Build scanner/dig minigame and reward output.

## Phase 5 — Meep Rescue Demo
Build one complete rescue puzzle with celebration/result.

## Phase 6 — Merf Mischief Demo
Prototype the smallest turn-based encounter. Prioritize humor/readability over RPG complexity.

## Phase 7 — Discovery Demo
Build interactive discovery flow and journal card.

## Phase 8 — Navigation Demo
Build Solar System selection, destination definitions and fuel-cost presentation.

## Phase 9 — Persistent Hub
Build basic rocket rooms, collections, mission board and workshop placeholders.

## Phase 10 — Mission Orchestrator
Implement mission definitions, objectives and mode sequencing.

Critical rule: the orchestrator launches existing demos; do not fork/rewrite them.

## Phase 11 — Vertical Slice
Implement `09_VERTICAL_SLICE.md`.

## Phase 12 — Content Expansion
Only after the Moon slice works:
1. Mars
2. additional Moon missions
3. asteroid-space missions
4. outer planet moon destinations
5. broader progression/upgrades.

## Codex Workflow
For each task, give Codex:
1. relevant design document(s),
2. exact acceptance criteria,
3. files/directories it may change,
4. expected test/run command,
5. instruction not to broaden scope.

Good task:
> Implement `ModeContext` and `ModeResult` according to `06_TECHNICAL_ARCHITECTURE.md`. Add a minimal standalone Exploration demo that accepts context and prints/returns a result. Do not implement mission progression.

Bad task:
> Build the Rocket Buddies architecture.

Keep changes reviewable and commit-sized.

## Definition of Done for a Mode
A mode is complete enough to integrate when:
- runnable from Demo Launcher,
- starts with default test context,
- accepts custom context,
- has a complete beginning/end loop,
- produces `ModeResult`,
- can restart,
- can exit safely,
- does not depend on another mode,
- has debug tooling,
- basic rules are tested,
- no errors appear during a normal run.

## Anti-Patterns
Avoid:
- giant `GameManager` controlling everything,
- scene paths hardcoded throughout gameplay,
- missions directly manipulating mode nodes,
- inheritance trees for every actor,
- content encoded in giant match statements,
- building all planets before the Moon loop is fun,
- allowing Codex to refactor unrelated systems during feature tasks.
