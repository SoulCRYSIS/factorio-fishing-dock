local utils = {}

---@class FishContentOptions
---@field name string The internal name of the fish entity (e.g. "tuna")
---@field icon string Path to the icon
---@field ingredients table[] Recipe ingredients
---@field energy number Crafting time (determines spawn rate)

---Creates a fish entity, a caught item, and a fishing recipe
---@param options FishContentOptions
function utils.create_fishing_content(options)
  local fish_name = options.name
  local item_name = "fishing-result-" .. fish_name
  local recipe_name = "fishing-" .. fish_name -- STRICT NAMING CONVENTION

  local icons = {
    {
      icon = options.icon,
      icon_size = 64,
    },
    {
      icon = "__fishing-dock__/graphics/icons/fishing-hook.png",
      icon_size = 64,
      -- draw_as_background = true,
      scale = 0.25,
      shift = { 15, 15 },
    }
  }

  data:extend({
    {
      type = "item",
      name = item_name,
      icons = icons,
      subgroup = "agriculture",
      order = "z",
      stack_size = 50,
      spoil_ticks = 1,
    },
    {
      type = "recipe",
      name = recipe_name,
      category = "fish-collecting",
      subgroup = "agriculture",
      order = "f",
      icons = icons,
      ingredients = options.ingredients,
      results = {
        { type = "item", name = item_name, amount = 1 }
      },
      energy_required = options.energy or 10,
      enabled = true,
      allow_productivity = true,
      main_product = item_name,
    }
  })
end

return utils
