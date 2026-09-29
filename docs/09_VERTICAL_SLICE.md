# Vertical Slice — First Moon Adventure

## Goal
Prove that all major architectural ideas combine into a charming 10–15 minute experience.

## Story
A faint **MEEP!** signal has been detected on the Moon. The Rocket Buddies decide to investigate.

## Sequence

### 1. Rocket Hub
Player enters cockpit/mission board and chooses:

**A Meep on the Moon!**

Briefing introduces the signal.

### 2. Navigation
Solar System map highlights Earth and Moon.

Player sees:
- destination,
- required fuel,
- available fuel.

Select Moon.

### 3. Rocket Flight
Short 45–60 second flight:
- steer around asteroids/debris,
- collect one optional fuel pickup,
- collect stardust,
- see the Moon grow larger.

### 4. Moon Landing / Exploration
Objectives:
- investigate Meep signal,
- collect 3 Moon Cheese,
- make 1 scientific discovery.

Player learns scanner controls.

### 5. Discovery
Inspect a crater or landmark and add the first real astronomy entry to the journal.

Keep the interaction brief.

### 6. Cheese Hunt
Scanner reveals a buried Moon Cheese deposit.
Player completes the small cheese activity.

### 7. Meep Rescue
The signal leads to a hungry/trapped Meep.

Giving/using Moon Cheese helps complete the rescue.

The Meep joins the Buddies.

### 8. Merf Mischief
A Merf arrives and tries to steal the remaining cheese.

Small encounter demonstrates:
- readable Merf intent,
- silly actions,
- non-scary conflict.

Resolve by distracting/outsmarting it.

### 9. Return
Return to landing site and launch.

A shortened return flight is acceptable.

### 10. Hub Celebration
The Meep appears in its habitat.

Rewards:
- Stars,
- first Meep collection entry,
- discovery entry,
- optional rocket cosmetic/unlock.

## Slice Requirements
The slice must exercise:
- persistence,
- ModeContext,
- ModeResult,
- mission objectives,
- scene routing,
- fuel,
- inventory/rewards,
- discovery journal,
- Meep collection,
- at least five independently runnable modes.

## Explicitly Out of Scope
- all planets,
- large RPG combat system,
- online multiplayer,
- procedural planets,
- complex crafting,
- large skill trees,
- voice acting,
- elaborate economy.

## Success Criteria
The slice succeeds if:
1. a child understands what to do with minimal explanation;
2. changing gameplay modes feels like one continuous adventure;
3. the Meep rescue creates an emotional payoff;
4. the science discovery does not feel like homework;
5. replaying individual demos during development is fast;
6. adding Mars appears primarily to be a content/system-extension task rather than an architectural rewrite.
