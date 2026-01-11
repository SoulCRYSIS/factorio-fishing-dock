local fishing_utils = require("prototypes.utils")

-- Base Game Fish
fishing_utils.create_fishing_content({
  name = "fish",
  icon = "__base__/graphics/icons/fish.png",
  energy = 10,
  ingredients = {
    {type = "item", name = "biter-egg", amount = 1}
  },
})

-- NOTE: For "fish", we must ensure it's in the registry (handled in logics/fish-and-boat.lua)
-- The utils created "fishing-fish" recipe which will map to "fish" entity automatically.
