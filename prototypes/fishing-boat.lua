local boat_width = 320
local boat_height = 320

data:extend({
  ---@type data.TrivialSmokePrototype
  {
    type = "trivial-smoke",
    name = "fishing-boat-ripple",
    duration = 200,
    fade_in_duration = 10,
    fade_away_duration = 190,
    spread_duration = 300,
    start_scale = 0.1,
    end_scale = 0.4,
    color = { r = 1, g = 1, b = 1, a = 1 },
    cyclic = true,
    affected_by_wind = false,
    render_layer = "above-tiles",   --"water-tile",
    movement_slow_down_factor = 0,
    show_when_smoke_off = true,
    animation =
    {
      filename = "__fishing-dock__/graphics/entities/water-ripple.png",
      width = 512,
      height = 512,
      line_length = 1,
      frame_count = 1,
      priority = "high",
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
      cooldown = 1000000,
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
          scale = 1,
          width = 200,
          height = 200
        },
        shift = { 0, -4 },
        size = 1,
        intensity = 0.7,
        color = { 0.8, 0.7, 0.5 }
      },
    },
    vision_distance = 0,
    movement_speed = 0.03,
    rotation_speed = 0.005,
    distance_per_frame = 0.1,
    -- pollution_to_join_attack = 0,
    distraction_cooldown = 1000000,
    dying_explosion = "explosion",
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
