# Technical Architecture — Godot

## Architecture Goal
Modes are independently runnable but share a stable application layer. No mode should need another mode's scene tree to function.

Prefer composition, Resources, signals and small services over deep inheritance.

## Suggested Project Layout
```text
rocket_buddies/
  project.godot
  autoload/
    app.gd
    game_state.gd
    save_service.gd
    content_db.gd
    audio_service.gd
    scene_router.gd
  core/
    events/
    data/
    components/
    interaction/
    objectives/
  content/
    missions/
    destinations/
    discoveries/
    items/
    meeps/
    merfs/
    upgrades/
  modes/
    hub/
    flight/
    exploration/
    cheese_hunt/
    meep_rescue/
    merf_mischief/
    discovery/
    navigation/
  ui/
    common/
    journal/
    mission/
  actors/
    buddies/
    meeps/
    merfs/
    rocket/
  full_game/
    game_flow/
  dev/
    demo_launcher/
    debug/
  tests/
```

## Shared Contracts

### ModeContext
Conceptual fields:
```gdscript
class_name ModeContext
extends Resource

@export var mode_id: StringName
@export var mission_id: StringName
@export var destination_id: StringName
@export var parameters: Dictionary
```

### ModeResult
```gdscript
class_name ModeResult
extends Resource

@export var status: StringName
@export var rewards: Dictionary
@export var objective_events: Array
@export var discoveries: Array[StringName]
@export var rescued_meeps: Array[StringName]
@export var metadata: Dictionary
```

Every mode must be able to:
- receive context,
- initialize deterministically from context/seed when requested,
- emit/return a result,
- exit without directly loading the next gameplay mode.

`SceneRouter/GameFlow` owns transitions.

## Game State
Persistent profile state contains:
- currencies/resources,
- rocket upgrades,
- unlocked destinations,
- rescued Meeps,
- discoveries,
- mission progress,
- settings.

Modes request changes through explicit result/events. Avoid arbitrary direct mutation of global state from dozens of nodes.

## Content
Use custom Godot `Resource` types for authored definitions:
- `MissionDef`
- `DestinationDef`
- `DiscoveryDef`
- `MeepDef`
- `MerfDef`
- `ItemDef`
- `UpgradeDef`

Runtime state is separate from definitions.

## Events
Use typed signals/events for meaningful gameplay facts:
- item_collected
- discovery_found
- meep_rescued
- merf_resolved
- location_reached
- interaction_completed

Objective logic listens to semantic events rather than inspecting scene internals.

## Input
Define actions rather than hardcoded keys:
- move_left/right/up/down
- interact
- scan
- primary_action
- secondary_action
- pause

Each mode maps these shared intentions to its gameplay.

## Save Format
Use versioned save data:
```json
{
  "save_version": 1,
  "profile": {},
  "missions": {},
  "collections": {}
}
```

Provide migration hooks from the beginning.

## Demo Launcher
A developer scene lists every registered mode and lets the developer:
- launch it,
- select test context,
- select seed,
- toggle debug overlays,
- reset demo state.

This is essential for Codex-driven development because each task can be tested without traversing the full game.

## Testing
Favor:
- pure tests for rules/calculations,
- smoke tests for mode startup/exit,
- contract tests for ModeContext/ModeResult,
- save/load round-trip tests,
- mission objective event tests.

Gameplay feel still requires human playtesting.

## Godot Version
Target the current stable Godot 4.x version chosen at project initialization and pin it in project documentation. Do not let Codex silently migrate engine versions.
