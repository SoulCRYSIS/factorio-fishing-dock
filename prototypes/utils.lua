local utils = {}

---@class FishContentOptions
---@field name string The internal name of the fish entity (e.g. "tuna")
---@field item_factoriopedia_alternative string The name of the item that use as factoriopedia alternative
---@field icon string Path to the icon
---@field ingredients table[] Recipe ingredients
---@field energy number Crafting time (determines spawn rate)
---@field order string Item order

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
      factoriopedia_alternative = options.item_factoriopedia_alternative,
      subgroup = "fishing",
      order = "z",
      stack_size = 50,
      spoil_ticks = 1,
      weight = 10000,
    },
    -- Spawn fish recipe
    {
      type = "recipe",
      name = recipe_name,
      category = "fishing",
      subgroup = "fishing",
      order = options.order,
      icons = icons,
      localised_name = { "recipe-name.fishing", fish_name },
      ingredients = options.ingredients,
      results = {
        { type = "item", name = item_name, amount = 1 }
      },
      energy_required = options.energy or 10,
      enabled = false,
      main_product = item_name,
    }
  })
end

return utils
