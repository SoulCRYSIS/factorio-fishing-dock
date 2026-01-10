local item_sounds = require("__base__.prototypes.item_sounds")

local base_assembling_machine = data.raw["assembling-machine"]["assembling-machine-1"]

local dock_width = 384
local dock_height = 384
local boat_width = 320
local boat_height = 320

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
  ---@type data.FurnacePrototype
  {
    type = "furnace",
    name = "fishing-dock",
    icon = "__fishing-dock__/graphics/icons/fishing-dock.png",
    flags = { "placeable-neutral", "placeable-player", "player-creation" },
    minable = { mining_time = 0.5, result = "fishing-dock" },
    max_health = 200,
    collision_box = { { -1.2, -1.4 }, { 1.2, 1.2 } },
    selection_box = { { -1.5, -1.5 }, { 1.5, 1.5 } },
    result_inventory_size = 1,
    source_inventory_size = 1,
    crafting_speed = 1,
    -- Allow placement on water/deepwater by NOT colliding with tile layers like `item`.
    -- Keep object-ish layers so the dock still blocks overlaps with other entities.
    collision_mask = { layers = {} },
    energy_usage = "100kW",
    energy_source = {
      type = "void",
    },
    crafting_categories = { "fish-collecting" },
    tile_height = 3,
    tile_width = 3,
    tile_buildability_rules =
    {
      { area = { { -1.4, 1.1 }, { 1.4, 1.4 } },   required_tiles = { layers = { ground_tile = true } }, colliding_tiles = { layers = { water_tile = true } }, remove_on_collision = true },
      { area = { { -1.4, -4.4 }, { 1.4, -0.6 } }, required_tiles = { layers = { water_tile = true } },  remove_on_collision = true },
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
          scale = 0.5,
        }
      },
      animation = {
        south = {
          layers = {
            {
              filename = "__fishing-dock__/graphics/entities/fishing-dock.png",
              width = dock_width,
              height = dock_height,
              scale = 0.5,
            },
            {
              filename = "__fishing-dock__/graphics/entities/fishing-dock-shadow.png",
              width = dock_width,
              height = dock_height,
              scale = 0.5,
              draw_as_shadow = true,
            },
            {
              filename = "__fishing-dock__/graphics/entities/fishing-dock-glow.png",
              width = dock_width,
              height = dock_height,
              scale = 0.5,
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
              scale = 0.5,
            },
            {
              filename = "__fishing-dock__/graphics/entities/fishing-dock-shadow.png",
              width = dock_width,
              height = dock_height,
              x = dock_width,
              scale = 0.5,
              draw_as_shadow = true,
            },
            {
              filename = "__fishing-dock__/graphics/entities/fishing-dock-glow.png",
              width = dock_width,
              height = dock_height,
              x = dock_width,
              scale = 0.5,
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
              scale = 0.5,
            },
            {
              filename = "__fishing-dock__/graphics/entities/fishing-dock-shadow.png",
              width = dock_width,
              height = dock_height,
              x = dock_width * 2,
              scale = 0.5,
              draw_as_shadow = true,
            },
            {
              filename = "__fishing-dock__/graphics/entities/fishing-dock-glow.png",
              width = dock_width,
              height = dock_height,
              x = dock_width * 2,
              scale = 0.5,
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
              scale = 0.5,
            },
            {
              filename = "__fishing-dock__/graphics/entities/fishing-dock-shadow.png",
              width = dock_width,
              height = dock_height,
              x = dock_width * 3,
              scale = 0.5,
              draw_as_shadow = true,
            },
            {
              filename = "__fishing-dock__/graphics/entities/fishing-dock-glow.png",
              width = dock_width,
              height = dock_height,
              x = dock_width * 3,
              scale = 0.5,
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
      distance = 16,
    }
  },
  ---@type data.UnitPrototype
  {
    type = "unit",
    name = "fishing-boat",
    icon = "__fishing-dock__/graphics/icons/fishing-boat.png",
    flags = { "placeable-neutral", "placeable-off-grid", "not-repairable", "not-on-map" },
    max_health = 500,
    healing_per_tick = 10,
    subgroup = "agriculture",
    order = "cb",
    collision_box = { { -0.5, -0.8 }, { 0.5, 0.8 } },
    selection_box = { { -0.6, -1 }, { 0.6, 1 } },
    factoriopedia_alternative = "fishing-dock",
    hidden = true,
    attack_parameters = {
      type = "projectile",
      range = 0.5,
      cooldown = 100,
      ammo_category = "melee",
      ammo_type = {
        category = "melee",
        action = { type = "direct", action_delivery = { type = "instant", target_effects = { type = "damage", damage = { amount = 0, type = "physical" } } } }
      },
      animation = {
        layers = {
          {
            filename = "__fishing-dock__/graphics/entities/fishing-boat.png",
            width = boat_width,
            height = boat_height,
            scale = 0.5,
            line_length = 16,
            lines_per_file = 16,
            direction_count = 256
          }
        }
      }
    },
    resistances = {
      {
        type = "fire",
        percent = 100,
      },
      {
        type = "physical",
        percent = 100,
      },
      {
        type = "explosion",
        percent = 100,
      },
      {
        type = "impact",
        percent = 100,
      },
      {
        type = "acid",
        percent = 100,
      },
    },
    light =
    {
      {
        type = "oriented",
        minimum_darkness = 0.3,
        picture =
        {
          filename = "__core__/graphics/light-cone.png",
          priority = "extra-high",
          flags = { "light" },
          scale = 2,
          width = 200,
          height = 200
        },
        shift = { 0, -1 },
        size = 0.5,
        intensity = 0.6,
        color = { 0.92, 0.77, 0.3 }
      },
    },
    vision_distance = 0,
    movement_speed = 0.05,
    distance_per_frame = 0.1,
    -- pollution_to_join_attack = 0,
    distraction_cooldown = 0,
    dying_explosion = "explosion",
    ai_settings = {
      do_separation = false
    },
    run_animation = {
      layers = {
        {
          filename = "__fishing-dock__/graphics/entities/fishing-boat.png",
          width = boat_width,
          height = boat_height,
          scale = 0.5,
          line_length = 16,
          lines_per_file = 16,
          direction_count = 256,
          counterclockwise = true,
        },
        {
          filename = "__fishing-dock__/graphics/entities/fishing-boat-shadow.png",
          width = boat_width,
          height = boat_height,
          scale = 0.5,
          line_length = 16,
          lines_per_file = 16,
          direction_count = 256,
          draw_as_shadow = true,
          counterclockwise = true,
        },
        {
          filename = "__fishing-dock__/graphics/entities/fishing-boat-glow.png",
          width = boat_width,
          height = boat_height,
          scale = 0.5,
          line_length = 16,
          lines_per_file = 16,
          direction_count = 256,
          draw_as_glow = true,
          blend_mode = "additive",
          counterclockwise = true,
        }
      }
    },
    water_reflection = {
      rotate = true,
      pictures = {
        variation_count = 32,
        filename = "__fishing-dock__/graphics/entities/fishing-boat-water-reflection.png",
        lines_per_file = 4,
        line_length = 8,
        width = boat_width + 40,
        height = boat_height + 40,
        scale = 0.5,
        counterclockwise = true,
      }
    },
    collision_mask = { layers = { object = true, train = true, ground_tile = true } }, -- Can move on water
  },
})
