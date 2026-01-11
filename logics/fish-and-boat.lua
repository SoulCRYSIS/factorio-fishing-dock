local util = require("util")

local DOCK_NAME = "fishing-dock"
local BOAT_NAME = "fishing-boat"
local RADIUS = 24
local MAX_FISH = 10

local function ensure_storage()
  if not storage.fishing_docks then storage.fishing_docks = {} end
  if not storage.fish_spawn_registry then storage.fish_spawn_registry = {} end
end

local function is_tile_valid_for_fish(tile, fish_name)
  -- Use registry for lookup
  local allowed_tiles = storage.fish_spawn_registry[fish_name]

  for _, tile_name in pairs(allowed_tiles) do
    if tile.name == tile_name then return true end
  end
  return false
end

-- Remote Interface
remote.add_interface("fishing_dock", {
  register_fish = function(fish_name, spawn_tiles)
    if not storage.fish_spawn_registry then ensure_storage() end
    storage.fish_spawn_registry[fish_name] = spawn_tiles
  end
})

local function get_spawn_pos(dock)
  local direction = dock.direction
  local position = dock.position
  local offset = { x = 0, y = 0 }

  -- Based on tile_buildability_rules: North means water is North (Top/Negative Y)
  if direction == defines.direction.north then
    offset = { x = 0, y = -3 }
  elseif direction == defines.direction.east then
    offset = { x = 3, y = 0 }
  elseif direction == defines.direction.south then
    offset = { x = 0, y = 3 }
  elseif direction == defines.direction.west then
    offset = { x = -3, y = 0 }
  else
    offset = { x = 0, y = -3 } -- Default to North if undefined
  end

  return { x = position.x + offset.x, y = position.y + offset.y }
end

local function spawn_fish(dock, fish_name)
  local MIN_DIST = 5
  local angle = math.random() * 2 * math.pi
  local dist = MIN_DIST + math.random() * (RADIUS - MIN_DIST)
  local dx = math.cos(angle) * dist
  local dy = math.sin(angle) * dist
  local target_pos = { x = dock.position.x + dx, y = dock.position.y + dy }

  local tile = dock.surface.get_tile(target_pos)
  if is_tile_valid_for_fish(tile, fish_name) then
    dock.surface.create_entity { name = fish_name, position = target_pos }
    dock.surface.create_entity { name = "water-splash", position = target_pos }
  end
end

local function check_recipe_requirements(entity, player_index)
  if not entity or not entity.valid or entity.name ~= DOCK_NAME then return end

  local recipe = entity.get_recipe()
  if not recipe then return end

  -- Determine fish name from recipe
  local fish_name = nil
  if recipe.name:find("^fishing%-") then
    fish_name = recipe.name:gsub("^fishing%-", "")
  end

  if not fish_name then return end

  ensure_storage()
  local valid_tiles = storage.fish_spawn_registry[fish_name]
  if not valid_tiles then
    -- Unknown fish type in registry
    return
  end

  -- Count valid tiles nearby
  -- We'll scan a smaller radius or the full radius?
  -- User asked: "if it < 50 block" (assuming 50 tiles count)
  local radius = RADIUS
  local surface = entity.surface
  local position = entity.position
  local area = {
    { position.x - radius, position.y - radius },
    { position.x + radius, position.y + radius }
  }

  local count = 0
  -- Optimization: Don't count ALL tiles, stop at 50
  count = surface.count_tiles_filtered {
    area = area,
    name = valid_tiles,
    limit = 100
  }

  if count < 100 then
    -- Not enough valid water
    entity.set_recipe(nil) -- Clear recipe
    if player_index then
      local player = game.get_player(player_index)
      if player then
        player.create_local_flying_text {
          text = { "fishing-dock-flying-text.not-enough-habitat", fish_name },
          position = position,
          color = { r = 1, g = 0, b = 0 },
        }
      end
    end
  end
end

local function on_built(event)
  local entity = event.created_entity or event.entity
  if not entity or not entity.valid or entity.name ~= DOCK_NAME then return end

  check_recipe_requirements(entity, event.player_index)

  local surface = entity.surface

  ensure_storage()

  -- Spawn boat
  local spawn_pos = get_spawn_pos(entity)

  local boat = surface.create_entity {
    name = BOAT_NAME,
    position = spawn_pos,
    force = entity.force
  }

  storage.fishing_docks[entity.unit_number] = {
    dock = entity,
    boat = boat
  }
end

local function on_destroy(event)
  local entity = event.entity
  if not entity or not entity.valid or entity.name ~= DOCK_NAME then return end

  ensure_storage()

  -- If it's the dock being destroyed
  if storage.fishing_docks[entity.unit_number] then
    local data = storage.fishing_docks[entity.unit_number]
    if data.boat and data.boat.valid then
      data.boat.destroy()
    end
    storage.fishing_docks[entity.unit_number] = nil
  end
end

local function update_docks()
  ensure_storage()

  for unit_number, data in pairs(storage.fishing_docks) do
    local dock = data.dock
    local boat = data.boat

    if not dock.valid then
      storage.fishing_docks[unit_number] = nil
      if boat and boat.valid then boat.destroy() end
    else
      -- Check boat
      if not boat or not boat.valid then
        -- Respawn boat
        local spawn_pos = get_spawn_pos(dock)

        boat = dock.surface.create_entity {
          name = BOAT_NAME,
          position = spawn_pos,
          force = dock.force
        }
        data.boat = boat
      end

      -- Check fish population for pausing logic
      local nearby_fish_count = dock.surface.count_entities_filtered {
        type = "fish",
        position = dock.position,
        radius = RADIUS
      }

      -- Boat Logic
      if boat and boat.valid then
        -- Check if dock is full or inactive
        local inventory = dock.get_inventory(defines.inventory.furnace_result)
        local is_full = inventory.is_full()

        -- Check if we should pause (output full OR too many fish)
        local should_pause = is_full or (nearby_fish_count >= MAX_FISH)

        -- Toggle active state to prevent consuming fuel when full or overpopulated
        if should_pause then
          if dock.active then
            dock.active = false
            data.paused_by_logic = true
          end
        elseif data.paused_by_logic then
          dock.active = true
          data.paused_by_logic = nil
        end

        local is_active = dock.is_crafting()

        -- Move boat

        -- Ripple effect based on movement (trust user request: speed != 0 proxy)
        -- Since we can't rely on accurate speed/moving state, we use distance moved.
        local last_pos = data.last_pos or boat.position
        local dist_moved = util.distance(boat.position, last_pos)
        local is_moving = dist_moved > 0.01

        if is_moving then
          dock.surface.create_trivial_smoke { name = "ironclad-ripple", position = boat.position }
        end
        data.last_pos = boat.position

        -- Boat Command Logic
        local dist_to_dock = util.distance(boat.position, dock.position)
        local commandable = boat.commandable

        -- game.print(commandable.command.type)

        if is_full or not is_active then
          -- Go back to dock and idle if full or inactive
          if dist_to_dock > 4 then -- Stay close to dock
            if data.state ~= "returning_to_dock" then
              -- game.print("Going back to dock")
              commandable.set_command({
                type = defines.command.go_to_location,
                destination = dock.position,
                distraction = defines.distraction.none,
                radius = 4,
                no_break = true,
              })
              data.state = "returning_to_dock"
            end
          else
            if data.state ~= "stopped" then
              -- game.print("Stopping")
              commandable.set_command({
                type = defines.command.stop,
                distraction = defines.distraction.none
              })
              data.state = "stopped"
            end
          end
        else
          -- Leash: If too far, come back
          if dist_to_dock > RADIUS and data.state ~= "leash" then
            -- game.print("Coming inside radius")
            commandable.set_command({
              type = defines.command.go_to_location,
              destination = dock.position,
              distraction = defines.distraction.none,
              radius = RADIUS - 5,
            })
            data.state = "leash"
            -- Wander if idle
          else
            if data.state ~= "fishing" or not is_moving or commandable.command.type ~= defines.command.go_to_location then
              -- game.print("Finding nearest fish")
              -- Move to nearest fish
              local nearest_fish = nil
              local min_dist = math.huge

              local fish_list = dock.surface.find_entities_filtered {
                name = "fish",
                position = dock.position,
                radius = RADIUS
              }

              for _, fish in pairs(fish_list) do
                if fish.valid then
                  local dist = util.distance(boat.position, fish.position)
                  if dist < min_dist then
                    min_dist = dist
                    nearest_fish = fish
                  end
                end
              end

              if nearest_fish then
                -- game.print("Moving to nearest fish: " .. nearest_fish.position.x .. ", " .. nearest_fish.position.y)
                commandable.set_command({
                  type = defines.command.go_to_location,
                  destination = nearest_fish.position,
                  distraction = defines.distraction.none,
                  radius = 1,
                  no_break = true,
                })
                data.state = "fishing"
              else
                -- game.print("Wandering")
                commandable.set_command({
                  type = defines.command.wander,
                  radius = RADIUS / 2, -- Wander in short bursts
                  distraction = defines.distraction.none,
                  wander_in_group = false
                })
                data.state = "wandering"
              end
            end
          end
        end

        -- Collect fish (only if not full and active)
        if not is_full and is_active then
          local fish = dock.surface.find_entities_filtered {
            name = "fish",
            position = boat.position,
            radius = 3
          }
          for _, f in pairs(fish) do
            if f.valid then
              local f_pos = f.position
              if f.mine({ inventory = inventory }) then
                dock.surface.create_entity { name = "water-splash", position = f_pos }
              end
            end
          end
        end
      end

      -- Spawn fish logic (based on products_finished)
      -- This allows rate control via recipe time
      local current_products = dock.products_finished
      local last_products = data.last_products_finished or current_products

      if current_products > last_products then
        local count = current_products - last_products

        -- Determine fish type from recipe
        local recipe = dock.get_recipe()
        local fish_name = nil

        if recipe then
          -- Fallback to naming convention: "fishing-{fish_name}"
          if recipe.name:find("^fishing%-") then
            fish_name = recipe.name:gsub("^fishing%-", "")
          end
        end

        -- Spawn the fish
        if fish_name then
          for i = 1, count do
            if nearby_fish_count < MAX_FISH + count then -- Allow slight overflow or check per spawn?
              spawn_fish(dock, fish_name)
              nearby_fish_count = nearby_fish_count +
                  1 -- Update local count to prevent massive overflow if multiple crafted
            end
          end
        end
      end

      data.last_products_finished = current_products
    end
  end
end

local function on_init()
  ensure_storage()

  storage.fish_spawn_registry["fish"] = { "water", "deepwater", "water-green", "deepwater-green", "water-shallow" }
end

script.on_init(on_init)
script.on_configuration_changed(on_init)

local filter = { { filter = "name", name = DOCK_NAME } }
-- Events
script.on_event(defines.events.on_gui_closed, function(event)
  if event.entity and event.entity.name == DOCK_NAME then
    check_recipe_requirements(event.entity, event.player_index)
  end
end)

script.on_event(defines.events.on_entity_settings_pasted, function(event)
  check_recipe_requirements(event.destination, event.player_index)
end)

script.on_event(defines.events.on_robot_built_entity, on_built, filter)
script.on_event(defines.events.script_raised_built, on_built, filter)
script.on_event(defines.events.on_built_entity, on_built, filter)

script.on_event(defines.events.on_player_mined_entity, on_destroy, filter)
script.on_event(defines.events.on_robot_mined_entity, on_destroy, filter)
script.on_event(defines.events.on_entity_died, on_destroy, filter)
script.on_event(defines.events.script_raised_destroy, on_destroy)

script.on_nth_tick(60, update_docks)
