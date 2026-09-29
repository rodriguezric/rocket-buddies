# Content and Data

## Principle
Code defines rules. Resources/data define content.

Adding a new Meep, destination or discovery should usually not require editing core gameplay code.

## Destination Definition
Suggested fields:
```text
id
display_name
destination_type
parent_body
description
travel_cost
unlock_requirements
exploration_scene
flight_theme
environment_tags[]
discovery_ids[]
```

## Mission Definition
```text
id
title
briefing
destination_id
prerequisites[]
steps[]
rewards
optional_objectives[]
```

A step can specify:
```text
mode_id
context_parameters
completion_requirements
```

## Discovery Definition
```text
id
title
category
destination_id
short_fact
details[]
fictional = false
```

## Meep Definition
```text
id
name
personality
visual_variant
favorite_cheese
behavior_tags[]
```

## Merf Definition
```text
id
name
visual_variant
personality
mischief_tags[]
encounter_profile
```

## Item Definition
```text
id
display_name
category
icon
stackable
max_stack
tags[]
```

## Example Mission
```yaml
id: moon_first_meep
title: "A Meep on the Moon!"
destination: moon
steps:
  - mode: navigation
    objective: select_moon
  - mode: flight
    objective: arrive
  - mode: exploration
    objectives:
      - collect_moon_cheese
      - discover_crater
      - rescue_meep
  - mode: flight
    objective: return_home
rewards:
  stars: 3
  unlocks:
    - meep_habitat
```

The exact serialization can use `.tres` resources rather than YAML; this example communicates authoring intent.

## Seeds
Modes that contain procedural variation accept an optional seed. This gives:
- nondeterministic normal play,
- reproducible bug reports,
- reproducible Codex/testing scenarios.
