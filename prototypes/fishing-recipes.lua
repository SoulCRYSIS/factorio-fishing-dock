data:extend({
  {
    type = "recipe",
    name = "fishing-with-eggs",
    category = "fish-collecting",
    order = "a",
    icon = "__base__/graphics/icons/fish.png",
    ingredients = {
      { type = "item", name = "biter-egg", amount = 1 }
    },
    results = {
      { type = "item", name = "collected-fish", amount = 1 }
    },
    energy_required = 10, 
    enabled = true,
  },
  {
    type = "item",
    name = "collected-fish",
    icon = "__base__/graphics/icons/fish.png",
    subgroup = "agriculture",
    order = "ca",
    stack_size = 20,
    spoil_ticks = 1,
    spoil_result = nil
  }
})