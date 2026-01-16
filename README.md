## Overview

This mod propose a new way to get fish, main concept is to make it feel unique and interesting as possible.

Original idea is I want a way get different kind of fish for my mod [Planet Virentis](https://mods.factorio.com/mod/virentis) (but you can use whatever you want)

![](https://files.catbox.moe/vkc6np.mp4)

## How it work (technical)

Just place the dock on water edges (just like asteroid collector), a fishing boat will automatic spawn and start to collect fish around (base on recipe selected).

The fishing dock is act like spawner, it will try to spawn fish everytime a craft succeeds. It can only spawn on to specific tiles (every nauvis water tiles for normal fish), so the more water, the more chance it will spawn (maximum at 100% when all tiles are water).

Don't worry too much about not getting 100% spawn rate, the algorithm will try to spawn 3 times, which mean if you have water 40%, the spawn rate will be `1-(1-0.4)^3 = 78.4%`

## For developer

If you want to add your type of fish, it super easy.

After you add your fish item and entity like normal.

### Add fishing mock prototypes
Use util (or just copy the inside code if you want more adjustment)
```
local fishing_utils = require("__fishing-dock__.prototypes.utils")

fishing_utils.create_fishing_content({
  fish_name = "fish",
  icon = "__base__/graphics/icons/fish.png",
  ingredients = {
    { type = "item", name = "copper-biter-egg", amount = 1 }
  },
  recipe_name = "fishing-fish-pelagos", -- Optional: default to "fishing-{fish_name}"
  energy = 10,                          -- Optional: default 10
  order = "aa",                         -- Optional
  subgroup = "fishing",                 -- Optional: default "fishing"
  
  surface_conditions = {                -- Optional
    {
      property = "pressure",
      min = 1809,
      max = 1809,
    }
  },
})
```

### Register to logics
In control side, add fish entity and spawnable tiles. Usually in on_init and on_configuration_changed.
```
local function on_init()
  remote.call(
    "fishing_dock",
    "register_fish",
    "fishing-fish-pelagos", -- Recipe name
    {
      spawn_entity_name = "fish",
      spawn_tiles = { "pelagos-deepsea", "water" }
      target_entity_name = "fish",    -- Optional: default to spawn_entity_name
      min_spawn_radius = 5,           -- Optional: default 5
      max_spawn_radius = 20,          -- Optional: default 20
      max_count = 15,                 -- Optional: default 15
      spawn_angle = 1,                -- Optional: default 1 (full circle)
      boat_radius = 24,               -- Optional: default 24 (same as radius visualization)
      move_to_dock_after_spawn = true -- Optional: default false (if true, it will command the unit to move toward dock after spawn, only work with units that has commandable)
    }
  )
end

script.on_init(on_init)
script.on_configuration_changed(on_init)
```

### Adding your custom dock type
```
local function on_init()
  remote.call(
    "fishing_dock",
    "register_dcok",
    "watchtower",
    {
      boat_entity_name = "galley",
      seperation_distance = "40",
      boat_collect_radius = "64",
      boat_spawn_offset = 5 -- Offset from dock center, to avoid spawn inside the dock
    }
  )
end

script.on_init(on_init)
script.on_configuration_changed(on_init)
```