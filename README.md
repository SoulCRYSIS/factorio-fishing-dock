## Overview

This mod propose a new way to get fish, main concept is to make it feel unique and interesting as possible.

Original idea is I want a way get different kind of fish for my mod [Planet Virentis](https://mods.factorio.com/mod/virentis) (but you can use whatever you want)

![](https://files.catbox.moe/vkc6np.mp4)

## How it work (technical)

Just place the dock on water edges (just like asteroid collector), a fishing boat will automatic spawn and start to collect fish around (base on recipe selected).

The fishing dock is act like spawner, it will try to spawn fish everytime a craft succeeds. It can only spawn on to specific tiles (every nauvis water tiles for normal fish), so the more water, the more chance it will spawn (maximum at 100% when all tiles are water).

Don't worry too much about not getting 100% spawn rate, the algorithm will try to spawn 3 times, which mean if you have water 40%, the spawn rate will be `1-(1-0.4)^3 = 78.4%`

## For developer

If you want to add your type of fish, it super easy

1. Add your fish item and entity like normal
2. Use util (or just copy the inside code if you want more adjustment)
```
local fishing_utils = require("__fishing-dock__.prototypes.utils")

fishing_utils.create_fishing_content({
  fish_name = "fish",
  recipe_name = "fishing-fish-pelagos",
  icon = "__base__/graphics/icons/fish.png",
  energy = 10,
  order = "aa",
  ingredients = {
    { type = "item", name = "copper-biter-egg", amount = 1 }
  },
  surface_conditions = {
    {
      property = "pressure",
      min = 1809,
      max = 1809,
    }
  },
})
```

Here are arguments list
```
fish_name string
recipe_name? string default to "fishing-{name}"
result_item_name? string default to "fishing-result-{name}"
icon string Path to the icon
ingredients data.IngredientPrototype[]
energy? number Crafting time (determines spawn rate)
order? string
surface_conditions? data.SurfaceCondition[]
```
3. In control side, add fish entity and spawnable tiles. Usually in on_init.
```
local function on_init()
  remote.call(
    "fishing_dock",
    "register_fish",
    "fishing-fish-pelagos",         -- Recipe name
    "fish",                         -- Entity name
    { "pelagos-deepsea", "water" }  -- Spawnable tiles
  )
end

script.on_init(on_init)
```
4. Done!!