local util = require("util")

local function ensure_storage()
  if not storage.fishing_docks then storage.fishing_docks = {} end
  if not storage.fish_spawn_data then
    ---@type table<string, RegisterFishOptions>
    storage.fish_spawn_data = {}
  end
  if not storage.dock_data then
    ---@type table<string, RegisterDockOptions>
    storage.dock_data = {}
  end
end

local function is_tile_valid_for_fish(tile, allowed_tiles)
  if not allowed_tiles then return false end
  for _, tile_name in pairs(allowed_tiles) do
    if tile.name == tile_name then return true end
  end
  return false
end

local function update_filters()
  if not storage.dock_data then return end
  local filters = {}
  for name, _ in pairs(storage.dock_data) do
    table.insert(filters, { filter = "name", name = name })
    table.insert(filters, { filter = "ghost_name", name = name })
  end

  if #filters == 0 then return end

  script.set_event_filter(defines.events.on_built_entity, filters)
  script.set_event_filter(defines.events.on_robot_built_entity, filters)
  script.set_event_filter(defines.events.on_player_mined_entity, filters)
  script.set_event_filter(defines.events.on_robot_mined_entity, filters)
  script.set_event_filter(defines.events.on_entity_died, filters)
  script.set_event_filter(defines.events.script_raised_destroy, filters)
end

---@class RegisterFishOptions
---@field spawn_entity_name string
---@field target_entity_name string?
---@field spawn_tiles string[]
---@field min_spawn_radius number?
---@field max_spawn_radius number?
---@field max_count number?
---@field spawn_angle number?
---@field boat_radius number?
---@field move_to_dock_after_spawn boolean?

---@class RegisterDockOptions
---@field boat_entity_name string
---@field seperation_distance number
---@field boat_collect_radius number
---@field boat_spawn_offset number

remote.add_interface("fishing_dock", {
  ---@param recipe_name string
  ---@param options RegisterFishOptions
  register_fish = function(recipe_name, options)
    ensure_storage()
    storage.fish_spawn_data[recipe_name] = {
      spawn_entity_name = options.spawn_entity_name,
      target_entity_name = options.target_entity_name or options.spawn_entity_name,
      spawn_tiles = options.spawn_tiles,
      min_spawn_radius = options.min_spawn_radius or 5,
      max_spawn_radius = options.max_spawn_radius or 20,
      max_count = options.max_count or 15,
      spawn_angle = options.spawn_angle or 1,
      boat_radius = options.boat_radius or 24,
      move_to_dock_after_spawn = options.move_to_dock_after_spawn or false
    }
  end,
  register_dock = function(dock_name, options)
    ensure_storage()
    storage.dock_data[dock_name] = {
      boat_entity_name = options.boat_entity_name,
      seperation_distance = options.seperation_distance,
      boat_collect_radius = options.boat_collect_radius,
      boat_spawn_offset = options.boat_spawn_offset,
    }
    update_filters()
  end,
})

local function get_spawn_pos(dock)
  local direction = dock.direction
  local position = dock.position
  local spawn_offset = storage.dock_data[dock.name].boat_spawn_offset
  local offset = { x = 0, y = 0 }

  -- Based on tile_buildability_rules: North means water is North (Top/Negative Y)
  if direction == defines.direction.north then
    offset = { x = 0, y = -spawn_offset }
  elseif direction == defines.direction.east then
    offset = { x = spawn_offset, y = 0 }
  elseif direction == defines.direction.south then
    offset = { x = 0, y = spawn_offset }
  elseif direction == defines.direction.west then
    offset = { x = -spawn_offset, y = 0 }
  else
    offset = { x = 0, y = -spawn_offset } -- Default to North if undefined
  end

  return { x = position.x + offset.x, y = position.y + offset.y }
end

local function spawn_fish(dock, recipe_name)
  local min_dist = storage.fish_spawn_data[recipe_name].min_spawn_radius
  local max_dist = storage.fish_spawn_data[recipe_name].max_spawn_radius
  local allowed_tiles = storage.fish_spawn_data[recipe_name].spawn_tiles
  local fish_entity_name = storage.fish_spawn_data[recipe_name].spawn_entity_name
  local spawn_angle = storage.fish_spawn_data[recipe_name].spawn_angle

  -- Determine dock facing (in radians), used as center of cone for <1 spawn_angle
  local facing_angle = 0
  if dock.direction == defines.direction.north then
    facing_angle = -math.pi / 2
  elseif dock.direction == defines.direction.east then
    facing_angle = 0
  elseif dock.direction == defines.direction.south then
    facing_angle = math.pi / 2
  elseif dock.direction == defines.direction.west then
    facing_angle = math.pi
  else
    facing_angle = -math.pi / 2 -- default north
  end

  -- Try up to 3 times to find a valid spawn location
  for i = 1, 3 do
    local angle
    if spawn_angle >= 1 then
      -- Full circle spawn
      angle = math.random() * 2 * math.pi
    else
      -- Limited cone (spawn_angle < 1), centered on dock facing
      local cone = spawn_angle * 2 * math.pi
      angle = facing_angle + (math.random() - 0.5) * cone
    end
    local dist = min_dist + math.random() * (max_dist - min_dist)
    local dx = math.cos(angle) * dist
    local dy = math.sin(angle) * dist
    local target_pos = { x = dock.position.x + dx, y = dock.position.y + dy }

    local tile = dock.surface.get_tile(target_pos)
    if is_tile_valid_for_fish(tile, allowed_tiles) then
      dock.surface.create_entity { name = "water-splash", position = target_pos }
      local fish = dock.surface.create_entity { name = fish_entity_name, position = target_pos }
      if storage.fish_spawn_data[recipe_name].move_to_dock_after_spawn then
        fish.commandable.set_command({
          type = defines.command.go_to_location,
          destination = get_spawn_pos(dock),
          distraction = defines.distraction.none,
          radius = 8,
        })
      end

      break
    end
  end
end

local function check_recipe_requirements(entity, player_index)
  if not entity or not entity.valid or storage.dock_data == nil or storage.dock_data[entity.name] == nil then return end

  local recipe = entity.get_recipe()
  if not recipe then return end

  -- Determine fish name from recipe
  local fish_data = storage.fish_spawn_data[recipe.name]
  if not fish_data then
    -- Log to console as well so it's visible why it's failing
    game.print("[Fishing Dock] Error: Recipe '" .. recipe.name .. "' is not registered via the fishing_dock interface.")
    entity.active = false
    return
  end

  local valid_tiles = fish_data.spawn_tiles
  if not valid_tiles then
    game.print("[Fishing Dock] Error: Recipe '" .. recipe.name .. "' is not registered any tile.")
    entity.active = false
    return
  end

  local count = entity.surface.count_tiles_filtered {
    name = valid_tiles,
    position = entity.position,
    radius = fish_data.max_spawn_radius,
  }
  local inside_count = entity.surface.count_tiles_filtered {
    name = valid_tiles,
    position = entity.position,
    radius = fish_data.min_spawn_radius,
  }

  if count - inside_count < 100 then
    -- Not enough valid water
    entity.set_recipe(nil) -- Clear recipe
    if player_index then
      local player = game.get_player(player_index)
      if player then
        player.create_local_flying_text {
          text = { "fishing-dock-flying-text.not-enough-habitat", fish_data.spawn_entity_name },
          position = entity.position,
          color = { r = 1, g = 0, b = 0 },
        }
      end
    end
  end
end

local function on_built(event)
  local entity = event.created_entity or event.entity
  if not entity or not entity.valid then return end

  -- Check if it is a registered dock
  local dock_data = storage.dock_data[entity.name] or
  (entity.type == "entity-ghost" and storage.dock_data[entity.ghost_name])
  if not dock_data then return end

  local is_ghost = entity.name == "entity-ghost"
  local dock_name = is_ghost and entity.ghost_name or entity.name
  local current_dock_data = storage.dock_data[dock_name]
  if not current_dock_data then return end

  local seperation_distance = current_dock_data.seperation_distance

  -- Check for nearby docks (exclusion zone)
  local surface = entity.surface
  local position = entity.position

  -- Create a filter list of all dock names
  local dock_names = {}
  for name, _ in pairs(storage.dock_data) do
    table.insert(dock_names, name)
  end

  local nearby_docks = surface.find_entities_filtered {
    name = dock_names,
    position = position,
    radius = seperation_distance,
  }

  local nearby_ghosts = surface.find_entities_filtered {
    ghost_name = dock_names,
    position = position,
    radius = seperation_distance,
  }

  local too_close = false
  for _, dock in pairs(nearby_docks) do
    if dock.valid and dock.unit_number ~= entity.unit_number then
      too_close = true
      break
    end
  end

  if not too_close then
    for _, dock in pairs(nearby_ghosts) do
      if dock.valid and dock.unit_number ~= entity.unit_number then
        too_close = true
        break
      end
    end
  end

  if too_close then
    -- Found another dock too close
    if event.player_index then
      local player = game.get_player(event.player_index)
      if player then
        player.create_local_flying_text {
          text = { "fishing-dock-flying-text.too-close" },
          position = position,
          color = { r = 1, g = 0, b = 0 },
        }
        if not is_ghost then
          -- Try to return item to cursor or inventory
          -- Assuming item name matches entity name or we try to insert based on entity name
          local items_to_place = entity.prototype.items_to_place_this
          local item_name = (items_to_place and items_to_place[1] and items_to_place[1].name) or dock_name

          if player.cursor_stack.valid_for_read and player.cursor_stack.name == item_name then
            player.cursor_stack.count = player.cursor_stack.count + 1
          else
            player.insert({ name = item_name, count = 1 })
          end
        end
      elseif not is_ghost then
        local items_to_place = entity.prototype.items_to_place_this
        local item_name = (items_to_place and items_to_place[1] and items_to_place[1].name) or dock_name
        surface.spill_item_stack { position = position, stack = { name = item_name, count = 1 }, enable_looted = true, force = entity.force, allow_belts = false }
      end
    elseif not is_ghost then
      local items_to_place = entity.prototype.items_to_place_this
      local item_name = (items_to_place and items_to_place[1] and items_to_place[1].name) or dock_name
      surface.spill_item_stack { position = position, stack = { name = item_name, count = 1 }, enable_looted = true, force = entity.force, allow_belts = false }
    end

    entity.destroy()
    return
  end

  if is_ghost then return end

  check_recipe_requirements(entity, event.player_index)

  ensure_storage()

  -- Spawn boat
  local spawn_pos = get_spawn_pos(entity)

  local boat = surface.create_entity {
    name = current_dock_data.boat_entity_name,
    position = spawn_pos,
    force = "neutral"
  }

  storage.fishing_docks[entity.unit_number] = {
    dock = entity,
    boat = boat
  }
end

local function on_destroy(event)
  local entity = event.entity
  if not entity or not entity.valid then return end

  -- Check if it was a dock by checking storage or name
  if not storage.fishing_docks[entity.unit_number] then return end

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
  for unit_number, data in pairs(storage.fishing_docks) do
    local dock = data.dock
    local boat = data.boat

    if not dock.valid then
      storage.fishing_docks[unit_number] = nil
      if boat and boat.valid then boat.destroy() end
    else
      local dock_data = storage.dock_data[dock.name]
      if not dock_data then
        -- Dock type no longer registered?
        -- Should probably disable or log, but keeping boat logic might be safe if boat exists
      end

      -- Check boat
      if not boat or not boat.valid then
        -- Respawn boat
        if dock_data then
          local spawn_pos = get_spawn_pos(dock)

          boat = dock.surface.create_entity {
            name = dock_data.boat_entity_name,
            position = spawn_pos,
            force = dock.force
          }
          data.boat = boat
        end
      end

      -- Check fish population for pausing logic
      local recipe = dock.get_recipe()
      local fish_data = recipe and storage.fish_spawn_data[recipe.name]

      local nearby_fish_count = 0
      if fish_data then
        nearby_fish_count = dock.surface.count_entities_filtered {
          name = fish_data.spawn_entity_name,
          position = dock.position,
          radius = fish_data.boat_radius
        }
      end
      
      if recipe and not fish_data then
        if dock.active then
          dock.active = false
         game.print("[Fishing Dock] Error: Recipe '" .. recipe.name .. "' on dock " .. unit_number ..
            " is not registered. Disabling dock.")
        end
      elseif fish_data and dock_data then
        -- Boat Logic
        if boat and boat.valid then
          -- Check if dock is full or inactive
          local inventory = dock.get_inventory(defines.inventory.furnace_result)
          local is_full = inventory.is_full()
          local max_count = fish_data.max_count

          -- Check if we should pause (output full OR too many fish)
          local should_pause = is_full or (nearby_fish_count >= max_count)

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

          if dist_moved > 1 then
            dock.surface.create_trivial_smoke { name = "fishing-boat-ripple", position = boat.position }
          end
          data.last_pos = boat.position

          -- Boat Command Logic
          local dist_to_dock = util.distance(boat.position, dock.position)
          local commandable = boat.commandable

          -- game.print(commandable.command.type)

          if is_full or (not is_active and not data.paused_by_logic) then
            -- Go back to dock and idle if full or inactive (and not paused by our logic)
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
            local boat_radius = fish_data.boat_radius
            if dist_to_dock > boat_radius and data.state ~= "leash" then
              -- game.print("Coming inside radius")
              commandable.set_command({
                type = defines.command.go_to_location,
                destination = dock.position,
                distraction = defines.distraction.none,
                radius = boat_radius - 5,
              })
              data.state = "leash"
              -- Wander if idle
            else
              if data.state ~= "fishing" or not is_moving or not commandable.has_command and commandable.command.type ~= defines.command.go_to_location then
                -- game.print("Finding nearest fish")
                -- Move to nearest fish
                local nearest_fish = nil
                local min_dist = math.huge

                local fish_list = dock.surface.find_entities_filtered {
                  name = fish_data.target_entity_name,
                  position = dock.position,
                  radius = boat_radius
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
                    destination_entity = nearest_fish,
                    distraction = defines.distraction.none,
                    radius = 1,
                    no_break = true,
                  })
                  data.state = "fishing"
                else
                  -- game.print("Wandering")
                  commandable.set_command({
                    type = defines.command.wander,
                    radius = boat_radius / 2, -- Wander in short bursts
                    distraction = defines.distraction.none,
                    wander_in_group = false
                  })
                  data.state = "wandering"
                end
              end
            end
          end

          -- Collect fish (only if not full and active/paused by logic)
          if not is_full and (is_active or data.paused_by_logic) then
            local fish = dock.surface.find_entities_filtered {
              name = fish_data.target_entity_name,
              position = boat.position,
              radius = dock_data.boat_collect_radius
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
          local recipe_name = recipe.name

          -- Spawn the fish
          for i = 1, count do
            if nearby_fish_count < fish_data.max_count + count then -- Allow slight overflow or check per spawn?
              
              spawn_fish(dock, recipe_name)
              nearby_fish_count = nearby_fish_count +
                  1 -- Update local count to prevent massive overflow if multiple crafted
            end
          end
        end

        data.last_products_finished = current_products
      end
    end
  end
end

local function on_init()
  ensure_storage()

  remote.call(
    "fishing_dock",
    "register_dock",
    "fishing-dock",
    {
      boat_entity_name = "fishing-boat",
      seperation_distance = 24,
      boat_collect_radius = 3,
      boat_spawn_offset = 3
    }
  )

  remote.call(
    "fishing_dock",
    "register_fish",
    "fishing-fish",
    {
      spawn_entity_name = "fish",
      spawn_tiles = {
        "water",
        "deepwater",
        "water-green",
        "deepwater-green",
        "water-shallow",
      }
    }
  )

  if script.active_mods["pelagos"] then
    remote.call(
      "fishing_dock",
      "register_fish",
      "fishing-fish-pelagos",
      {
        spawn_entity_name = "fish",
        spawn_tiles = { "pelagos-deepsea", "water" }
      }
    )
  end
end

local function on_load()
  update_filters()
end

script.on_init(on_init)
script.on_configuration_changed(on_init)
script.on_load(on_load)

script.on_event(defines.events.on_gui_closed, function(event)
  if event.entity and storage.dock_data and storage.dock_data[event.entity.name] then
    check_recipe_requirements(event.entity, event.player_index)
  end
end)

script.on_event(defines.events.on_entity_settings_pasted, function(event)
  check_recipe_requirements(event.destination, event.player_index)
end)

script.on_event(defines.events.on_robot_built_entity, on_built)
script.on_event(defines.events.on_built_entity, on_built)

script.on_event(defines.events.on_player_mined_entity, on_destroy)
script.on_event(defines.events.on_robot_mined_entity, on_destroy)
script.on_event(defines.events.on_entity_died, on_destroy)
script.on_event(defines.events.script_raised_destroy, on_destroy)

script.on_nth_tick(60, update_docks)
