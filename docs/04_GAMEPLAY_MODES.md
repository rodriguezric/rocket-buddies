# Gameplay Modes and Standalone Demos

## Principle
Every major mode is a separately runnable Godot demo scene. The final game launches these same modes through mission/context data.

All modes accept an input `ModeContext` and return a `ModeResult`.

## Demo 00 — Rocket Hub
**Purpose:** prove menus, persistent state and transitions.

Loop:
walk/use rooms → select actions → inspect collections → launch another demo.

Minimum:
- cockpit,
- mission board,
- Meep room,
- journal,
- workshop.

## Demo 01 — Rocket Flight
Loop:
launch → steer → collect/avoid → arrival.

Minimum:
- rocket movement,
- asteroid hazards,
- fuel pickup,
- one whimsical event,
- arrival result.

Later:
Merf ships, comets, satellites, storms, destination-specific variants.

## Demo 02 — Planet Exploration
Loop:
arrive → explore compact map → scan/interact → objective → return.

Minimum Moon map:
- landing site,
- crater,
- cheese deposit,
- discovery,
- Meep,
- Merf trigger,
- return point.

## Demo 03 — Moon Cheese Hunt
Loop:
scan → interpret clue → dig/extract → collect cheese → finish.

Design it as a reusable activity that can be launched inside exploration or directly.

## Demo 04 — Meep Rescue
Loop varies by scenario but prototype:
locate signal → find trapped/hungry Meep → manipulate environment/use cheese → rescue → celebration.

## Demo 05 — Merf Mischief
Prototype as a lightweight turn-based encounter.

Example actions:
- Cheese Toss
- Buddy Gadget
- Meep Help
- Dodge
- Scan

Enemy intent should be visible and funny. Encounters can end through distraction, retreat, puzzle solution or victory.

## Demo 06 — Discovery / Science Activity
Prototype:
observe landmark → scanner investigation → short interactive task → discovery card → journal entry.

This demo tests whether learning feels integrated rather than quiz-like.

## Demo 07 — Solar System Navigation
Loop:
inspect map → compare destinations/fuel → select destination → confirm loadout.

Navigation itself teaches relative order and broad distance.

## Demo 08 — Mission Framework
A developer-facing integration demo:
select mission → launch required sequence of modes → collect results → update objectives → complete mission.

This is the bridge between demos and the full game.

## Full Game
The full game does not reimplement these activities. It orchestrates them:

`Hub → Mission → Navigation → Flight → Exploration → Activity → Exploration → Flight → Hub`

A mission can compose modes differently:

`Hub → Navigation → Flight → Merf Mischief → Flight → Hub`

or:

`Hub → Navigation → Flight → Exploration → Discovery → Meep Rescue → Exploration → Hub`

This composability is a core architectural requirement.
