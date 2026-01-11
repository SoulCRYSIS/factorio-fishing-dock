local util = require("util")

local DOCK_NAME = "fishing-dock"
local BOAT_NAME = "fishing-boat"
local FISH_NAME = "raw-fish"
local RADIUS = 24
local MAX_FISH = 10

local function is_water(tile)
  return tile.collides_with("water_tile")
end

local function ensure_storage()
  if not storage.fishing_docks then storage.fishing_docks = {} end
end

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

local function on_built(event)
  local entity = event.created_entity or event.entity
  if not entity or not entity.valid or entity.name ~= DOCK_NAME then return end

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

      -- Boat Logic
      if boat and boat.valid then
        -- Check if dock is full or inactive
        local inventory = dock.get_inventory(defines.inventory.furnace_result)
        local is_full = inventory.is_full()

        -- Toggle active state to prevent consuming fuel when full
        if is_full then
          if dock.active then
            dock.active = false
            data.paused_by_full = true
          end
        elseif data.paused_by_full then
          dock.active = true
          data.paused_by_full = nil
        end

        local is_active = dock.is_crafting()

        -- Move boat

        -- Ripple effect based on movement (trust user request: speed != 0 proxy)
        -- Since we can't rely on accurate speed/moving state, we use distance moved.
        local last_pos = data.last_pos or boat.position
        local dist_moved = util.distance(boat.position, last_pos)

        if dist_moved > 0.01 then
          if game.tick % 10 == 0 then
            dock.surface.create_trivial_smoke { name = "ironclad-ripple", position = boat.position }
          end
        end
        data.last_pos = boat.position

        -- Boat Command Logic
        local dist_to_dock = util.distance(boat.position, dock.position)
        local commandable = boat.commandable

        if is_full or not is_active then
          -- Go back to dock and idle if full or inactive
          if dist_to_dock > 4 then -- Stay close to dock
            if data.state ~= "returning_to_dock" then
              game.print("Going back to dock")
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
              game.print("Stopping")
              commandable.set_command({
                type = defines.command.stop,
                distraction = defines.distraction.none
              })
              data.state = "stopped"
            end
          end
        else
          -- Leash: If too far, come back
          if dist_to_dock > RADIUS then
            if data.state ~= "leash" then
              game.print("Coming inside radius")
              commandable.set_command({
                type = defines.command.go_to_location,
                destination = dock.position,
                distractn = defines.distraction.none,
                radius = RADIUS - 5,
                no_break = true,
              })
              data.state = "leash"
            end
            -- Wander if idle
          else
            if data.state ~= "fishing" then
              game.print("Finding nearest fish")
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
                game.print("Moving to nearest fish")
                commandable.set_command({
                  type = defines.command.go_to_location,
                  destination_entity = nearest_fish,
                  distraction = defines.distraction.none,
                  radius = 2,
                  no_break = true,
                })
                data.state = "fishing"
                data.target_fish = nearest_fish
              end
            elseif data.state == "fishing" then
              -- Check if target fish is still valid
              if not data.target_fish or not data.target_fish.valid then
                game.print("Target fish is no longer valid, resetting state")
                data.state = "idle"
              end
            elseif dist_moved < 0.01 then
              game.print("Wandering")
              commandable.set_command({
                type = defines.command.wander,
                radius = RADIUS, -- Wander in short bursts
                distraction = defines.distraction.none,
                wander_in_group = false
              })
              data.state = "wandering"
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

      -- Spawn fish logic (only if active)
      local is_active = dock.is_crafting()
      if is_active and math.random() < 0.2 then -- 20% chance per second
        local nearby_fish = dock.surface.count_entities_filtered {
          type = "fish",
          position = dock.position,
          radius = RADIUS
        }
        if nearby_fish < MAX_FISH then
          local MIN_DIST = 5
          -- Spawn new fish
          local angle = math.random() * 2 * math.pi
          local dist = MIN_DIST + math.random() * (RADIUS - MIN_DIST)
          local dx = math.cos(angle) * dist
          local dy = math.sin(angle) * dist
          local target_pos = { x = dock.position.x + dx, y = dock.position.y + dy }

          local tile = dock.surface.get_tile(target_pos)
          if is_water(tile) then
            dock.surface.create_entity { name = "fish", position = target_pos }
            dock.surface.create_entity { name = "water-splash", position = target_pos }
          end
        end
      end
    end
  end
end

-- Events
script.on_event(defines.events.on_built_entity, on_built, { { filter = "name", name = DOCK_NAME } })
script.on_event(defines.events.on_robot_built_entity, on_built, { { filter = "name", name = DOCK_NAME } })
script.on_event(defines.events.script_raised_built, on_built)

script.on_event(defines.events.on_player_mined_entity, on_destroy, { { filter = "name", name = DOCK_NAME } })
script.on_event(defines.events.on_robot_mined_entity, on_destroy, { { filter = "name", name = DOCK_NAME } })
script.on_event(defines.events.on_entity_died, on_destroy, { { filter = "name", name = DOCK_NAME } })
script.on_event(defines.events.script_raised_destroy, on_destroy)

script.on_nth_tick(60, update_docks)
