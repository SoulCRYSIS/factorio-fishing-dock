data:extend({
  {
    type = "technology",
    name = "fishing-dock",
    icon = "__fishing-dock__/graphics/icons/fishing-dock-technology.png",
    icon_size = 256,
    prerequisites = { "captivity", "fish-breeding" },
    unit = {
      count = 500,
      ingredients = {
        { "automation-science-pack",   1 },
        { "logistic-science-pack",     1 },
        { "chemical-science-pack",     1 },
        { "military-science-pack",     1 },
        { "space-science-pack",        1 },
        { "agricultural-science-pack", 1 }
      },
      time = 60,
    },
    effects = {
      { type = "unlock-recipe", recipe = "fishing-dock" },
      { type = "unlock-recipe", recipe = "fishing-fish" },
    },
  }
})
