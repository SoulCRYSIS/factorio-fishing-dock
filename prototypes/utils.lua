local utils = {
  all_fishing_recipes = {},
  all_fishing_results = {},
}

---@class FishContentOptions
---@field fish_name string
---@field recipe_name string? default to "fishing-{name}"
---@field result_item_name string? default to "fishing-result-{name}"
---@field subgroup string? default to "fishing"
---@field icon string Path to the icon
---@field ingredients data.IngredientPrototype[]
---@field energy number? Crafting time (determines spawn rate)
---@field order string?
---@field surface_conditions data.SurfaceCondition[]?
---@field allow_productivity boolean? default to true

---@param options FishContentOptions
function utils.create_fishing_content(options)
  local fish_name = options.fish_name
  local item_name = options.result_item_name or ("fishing-result-" .. fish_name)
  local recipe_name = options.recipe_name or ("fishing-" .. fish_name)
  table.insert(utils.all_fishing_recipes, recipe_name)
  table.insert(utils.all_fishing_results, item_name)

  local icons = {
    {
      icon = options.icon,
      icon_size = 64,
    },
    {
      icon = "__fishing-dock__/graphics/icons/fishing-hook.png",
      icon_size = 64,
      draw_background = true,
    }
  }

  data:extend({
    -- Mock item
    {
      type = "item",
      name = item_name,
      icons = icons,
      localised_name = { "item-name.spawn-fish", fish_name },
      hidden = true,
      subgroup = options.subgroup or "fishing",
      order = "z",
      stack_size = 50,
      spoil_ticks = 1,
      weight = 10000,
      auto_recycle = false,
    },
    -- Spawn fish recipe
    {
      type = "recipe",
      name = recipe_name,
      category = "fishing",
      subgroup = options.subgroup or "fishing",
      order = options.order,
      icons = icons,
      localised_name = { "recipe-name.fishing", fish_name },
      ingredients = options.ingredients,
      results = {
        { type = "item", name = item_name, amount = 1 }
      },
      energy_required = options.energy or 10,
      enabled = false,
      surface_conditions = options.surface_conditions,
      auto_recycle = false,
      allow_productivity = options.allow_productivity or true,
    }
  })
end

return utils
