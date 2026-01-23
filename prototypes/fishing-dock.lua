local item_sounds = require("__base__.prototypes.item_sounds")

local base_assembling_machine = data.raw["assembling-machine"]["assembling-machine-1"]

local dock_width = 576
local dock_height = 576

data:extend({
  ---@type data.ItemPrototype
  {
    type = "item",
    name = "fishing-dock",
    place_result = "fishing-dock",
    icon = "__fishing-dock__/graphics/icons/fishing-dock.png",
    subgroup = "agriculture",
    order = "ca",
    stack_size = 20,
    inventory_move_sound = item_sounds.mechanical_large_inventory_move,
    pick_sound = item_sounds.mechanical_large_inventory_pickup,
    drop_sound = item_sounds.mechanical_large_inventory_move,
    default_import_location = "nauvis",
  },
  ---@type data.RecipePrototype
  {
    type = "recipe",
    name = "fishing-dock",
    category = "crafting",
    enabled = false,
    ingredients = {
      { type = "item", name = "wood",       amount = 20 },
      { type = "item", name = "iron-plate", amount = 10 },
      { type = "item", name = "iron-stick", amount = 5 },
      { type = "item", name = "raw-fish",   amount = 5 },
    },
    results = { { type = "item", name = "fishing-dock", amount = 1 } }
  },
  ---@type data.AssemblingMachinePrototype
  {
    type = "assembling-machine",
    name = "fishing-dock",
    icon = "__fishing-dock__/graphics/icons/fishing-dock.png",
    flags = { "placeable-neutral", "placeable-player", "player-creation" },
    minable = { mining_time = 0.5, result = "fishing-dock" },
    max_health = 200,
    collision_box = { { -1.8, -1.9 }, { 1.8, 1.8 } },
    selection_box = { { -2, -2 }, { 2, 2 } },
    ingredient_count = 1,
    max_item_product_count = 1,
    trash_inventory_size = 1,
    crafting_speed = 1,
    module_slots = 4,
    -- Allow placement on water/deepwater by NOT colliding with tile layers like `item`.
    -- Keep object-ish layers so the dock still blocks overlaps with other entities.
    effect_receiver = { uses_beacon_effects = false },
    allowed_effects = { "speed", "productivity" },
    allowed_module_categories = { "productivity", "speed" },
    collision_mask = { layers = { object = true } },
    energy_usage = "100kW",
    energy_source = {
      type = "void",
    },
    crafting_categories = { "fishing" },
    tile_buildability_rules =
    {
      { area = { { -1.9, 1.1 }, { 1.9, 1.9 } },  required_tiles = { layers = { ground_tile = true } }, colliding_tiles = { layers = { water_tile = true } }, remove_on_collision = true },
      { area = { { -1.9, -4.9 }, { 1.9, 0.9 } }, required_tiles = { layers = { water_tile = true } },  remove_on_collision = true },
    },
    graphics_set = {
      water_reflection = {
        rotate = true,
        pictures = {
          filename = "__fishing-dock__/graphics/entities/fishing-dock-water-reflection.png",
          variation_count = 4,
          line_length = 4,
          lines_per_file = 1,
          width = dock_width + 40,
          height = dock_height + 40,
          scale = 0.4,
        }
      },
      animation = {
        south = {
          layers = {
            {
              filename = "__fishing-dock__/graphics/entities/fishing-dock.png",
              width = dock_width,
              height = dock_height,
              scale = 0.4,
            },
            {
              filename = "__fishing-dock__/graphics/entities/fishing-dock-shadow.png",
              width = dock_width,
              height = dock_height,
              scale = 0.4,
              draw_as_shadow = true,
            },
            {
              filename = "__fishing-dock__/graphics/entities/fishing-dock-glow.png",
              effect = "flicker",
              width = dock_width,
              height = dock_height,
              scale = 0.4,
              draw_as_glow = true,
              blend_mode = "additive",
            },
          }
        },
        east = {
          layers = {
            {
              filename = "__fishing-dock__/graphics/entities/fishing-dock.png",
              width = dock_width,
              height = dock_height,
              x = dock_width,
              scale = 0.4,
            },
            {
              filename = "__fishing-dock__/graphics/entities/fishing-dock-shadow.png",
              width = dock_width,
              height = dock_height,
              x = dock_width,
              scale = 0.4,
              draw_as_shadow = true,
            },
            {
              filename = "__fishing-dock__/graphics/entities/fishing-dock-glow.png",
              width = dock_width,
              height = dock_height,
              x = dock_width,
              scale = 0.4,
              draw_as_glow = true,
              blend_mode = "additive",
            },
          }
        },
        north = {
          layers = {
            {
              filename = "__fishing-dock__/graphics/entities/fishing-dock.png",
              width = dock_width,
              height = dock_height,
              x = dock_width * 2,
              scale = 0.4,
            },
            {
              filename = "__fishing-dock__/graphics/entities/fishing-dock-shadow.png",
              width = dock_width,
              height = dock_height,
              x = dock_width * 2,
              scale = 0.4,
              draw_as_shadow = true,
            },
            {
              filename = "__fishing-dock__/graphics/entities/fishing-dock-glow.png",
              width = dock_width,
              height = dock_height,
              x = dock_width * 2,
              scale = 0.4,
              draw_as_glow = true,
              blend_mode = "additive",
            },
          }
        },
        west = {
          layers = {
            {
              filename = "__fishing-dock__/graphics/entities/fishing-dock.png",
              width = dock_width,
              height = dock_height,
              x = dock_width * 3,
              scale = 0.4,
            },
            {
              filename = "__fishing-dock__/graphics/entities/fishing-dock-shadow.png",
              width = dock_width,
              height = dock_height,
              x = dock_width * 3,
              scale = 0.4,
              draw_as_shadow = true,
            },
            {
              filename = "__fishing-dock__/graphics/entities/fishing-dock-glow.png",
              width = dock_width,
              height = dock_height,
              x = dock_width * 3,
              scale = 0.4,
              draw_as_glow = true,
              blend_mode = "additive",
            },
          }
        },
      }
    },
    circuit_connector = base_assembling_machine.circuit_connector,
    circuit_wire_max_distance = 9,
    radius_visualisation_specification = {
      sprite = {
        filename = "__fishing-dock__/graphics/entities/dock-radius-visualization.png",
        priority = "extra-high-no-scale",
        width = 256,
        height = 256,
      },
      distance = 24,
    }
  },
})
