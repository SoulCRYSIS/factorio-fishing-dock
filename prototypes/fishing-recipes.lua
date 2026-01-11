local fishing_utils = require("prototypes.utils")

-- Base Game Fish
fishing_utils.create_fishing_content({
  name = "fish",
  icon = "__base__/graphics/icons/fish.png",
  energy = 10,
  order = "a",
  ingredients = {
    {type = "item", name = "biter-egg", amount = 1}
  },
})