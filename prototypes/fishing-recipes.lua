local fishing_utils = require("prototypes.utils")

-- Base Game Fish
fishing_utils.create_fishing_content({
  fish_name = "fish",
  icon = "__base__/graphics/icons/fish.png",
  energy = 16,
  order = "ba",
  ingredients = {
    { type = "item", name = "fishing-bait", amount = 1 }
  },
  surface_conditions = {
    {
      property = "pressure",
      min = 1000,
      max = 1000,
    }
  },
})

data:extend({
  {
    type = "recipe",
    name = "fishing-bait",
    subgroup = "fishing",
    order = "aa",
    category = "organic-or-hand-crafting",
    icon = "__fishing-dock__/graphics/icons/fishing-bait.png",
    enabled = false,
    energy_required = 8,
    ingredients = {
      { type = "item", name = "biter-egg",    amount = 5 },
      { type = "item", name = "raw-fish",     amount = 1 },
      { type = "item", name = "copper-cable", amount = 1 },
    },
    results = {
      { type = "item", name = "fishing-bait", amount = 1 }
    },
    auto_recycle = false,
    result_is_always_fresh = true,
  },
  {
    type = "item",
    name = "fishing-bait",
    icon = "__fishing-dock__/graphics/icons/fishing-bait.png",
    subgroup = "fishing",
    order = "aa",
    stack_size = 20,
    spoil_ticks = 30 * minute,
    spoil_result = "spoilage",
    weight = 5 * kg,
  }
})

-- Planet Pelagos
if mods["pelagos"] then
  fishing_utils.create_fishing_content({
    fish_name = "fish",
    recipe_name = "fishing-fish-pelagos",
    icon = "__base__/graphics/icons/fish.png",
    energy = 16,
    order = "bb",
    ingredients = {
      { type = "item", name = "fishing-bait", amount = 1 }
    },
    surface_conditions = {
      {
        property = "pressure",
        min = 1809,
        max = 1809,
      }
    },
  })

  data:extend({
    {
      type = "recipe",
      name = "fishing-bait-pelagos",
      subgroup = "fishing",
      order = "ab",
      category = "organic-or-hand-crafting",
      icon = "__fishing-dock__/graphics/icons/fishing-bait.png",
      enabled = false,
      energy_required = 8,
      ingredients = {
        { type = "item", name = "copper-biter-egg", amount = 5 },
        { type = "item", name = "fermented-fish",   amount = 1 },
        { type = "item", name = "copper-cable",     amount = 1 },
      },
      results = {
        { type = "item", name = "fishing-bait", amount = 1 }
      },
      auto_recycle = false,
      result_is_always_fresh = true,
      surface_conditions = {
        {
          property = "pressure",
          min = 1809,
          max = 1809,
        }
      },
    },
  })
end
