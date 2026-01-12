local fishing_utils = require("prototypes.utils")

-- Base Game Fish
fishing_utils.create_fishing_content({
  fish_name = "fish",
  icon = "__base__/graphics/icons/fish.png",
  energy = 10,
  order = "a",
  ingredients = {
    { type = "item", name = "biter-egg", amount = 1 }
  },
  surface_conditions = {
    {
      property = "pressure",
      min = 1000,
      max = 1000,
    }
  },
})

-- Planet Pelagos
if mods["pelagos"] then
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
end
