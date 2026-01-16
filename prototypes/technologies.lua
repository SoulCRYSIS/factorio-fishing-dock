data:extend({
  {
    type = "technology",
    name = "fishing-dock",
    icon = "__fishing-dock__/graphics/icons/fishing-dock-technology.png",
    icon_size = 256,
    prerequisites = { "captivity", "fish-breeding" },
    unit = {
      count = 1000,
      ingredients = {
        { "space-science-pack",        1 },
        { "agricultural-science-pack", 1 }
      },
      time = 60,
    },
    effects = {
      { type = "unlock-recipe", recipe = "fishing-dock" },
      { type = "unlock-recipe", recipe = "fishing-fish" },
      { type = "unlock-recipe", recipe = "fishing-bait" },
    },
  }
})

if mods["pelagos"] then
  table.insert(
    data.raw["technology"]["fishing-dock"].effects,
    { type = "unlock-recipe", recipe = "fishing-fish-pelagos" }
  )
  table.insert(
    data.raw["technology"]["fishing-dock"].effects,
    { type = "unlock-recipe", recipe = "fishing-bait-pelagos" }
  )
end
