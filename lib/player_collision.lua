local dispatcher = require "crit.dispatcher"
local movement = require "lib.player_movement"

local h_collision_touch = hash("collision_touch")
local h_collision_detach = hash("collision_detach")

local AXIS_HORIZ = 1
local AXIS_VERT = 2

local CT_TIMER_JUMP = 1

local rc_simple = {
  bot = { from = 0.0, len = -110.0, axis = AXIS_VERT },
  bot2 = { from = 0.0, len = -125.0, axis = AXIS_VERT },
}

local collision = {
  coyote_time = 0.064,
  ct_timers = {},
  hitbox_correction = vmath.vector3(0.0),
  groups = {},
  groups_list = {},
  on_platform = false,
}

local function raycast_from_center(rc)
  local pos_x, pos_y = movement.position.x, movement.position.y
  local to_pos_x, to_pos_y
  if rc.axis == AXIS_HORIZ then
    pos_x = pos_x + rc.from
    to_pos_x = pos_x + rc.len
    to_pos_y = pos_y
  elseif rc.axis == AXIS_VERT then
    pos_y = pos_y + rc.from
    to_pos_x = pos_x
    to_pos_y = pos_y + rc.len
  end

  local raycast_from = vmath.vector3(pos_x, pos_y, 0.0)
  local raycast_to = vmath.vector3(to_pos_x, to_pos_y, 0.0)
  return physics.raycast(raycast_from, raycast_to, collision.groups_list)
end

local function timers(timer_id, cancel)
  if cancel then
    if collision.ct_timers[timer_id] then
      timer.cancel(collision.ct_timers[timer_id])
      collision.ct_timers[timer_id] = nil
    end
    return
  end
  collision.ct_timers[timer_id] = timer.delay(collision.coyote_time, false, function ()
    if timer_id == CT_TIMER_JUMP then
      collision.on_platform = false
      dispatcher.dispatch(h_collision_detach, collision.groups_list)
    end
    collision.ct_timers[timer_id] = nil
  end)
end


function collision.set_groups(groups_list)
  for i, group in ipairs(groups_list) do
    collision.groups[group] = true
  end
  collision.groups_list = groups_list
end


function collision.resolve_hitbox_collision(response)
  if collision.groups[response.group] then
    local penetration = response.distance
    if penetration > 0 then
      local normal = response.normal
      local projection  = vmath.project(collision.hitbox_correction, normal * penetration)
      if projection < 1 then
        local comp = (penetration - penetration * projection) * normal
        local old_pos = vmath.vector3(movement.position.x, movement.position.y, 0.0)
        local new_pos = old_pos + comp

        movement.set_position(new_pos.x, new_pos.y)
        collision.hitbox_correction = collision.hitbox_correction + comp
      end
    end
  end
end

function collision.update()
  collision.hitbox_correction = vmath.vector3(0.0)
end

function collision.resolve_platformer_raycasts()
  local rc_result_bottom = raycast_from_center(rc_simple.bot)
  local rc_result_bottom2 = raycast_from_center(rc_simple.bot2)

  if rc_result_bottom then
    timers(CT_TIMER_JUMP, true)
    -- detect landing on platform from air
    local is_falling = movement.speed.y < 0.0
    if not collision.on_platform and is_falling then
      local normal = -rc_result_bottom.normal.y
      local penetration = normal * rc_simple.bot.len * (1.0 - rc_result_bottom.fraction)
      movement.set_position(nil, movement.position.y + penetration)
      dispatcher.dispatch(h_collision_touch, { group = rc_result_bottom.group })
      collision.on_platform = true

    elseif collision.on_platform and rc_result_bottom2 then
      local penetration = -rc_simple.bot.len * (1.0 - rc_result_bottom.fraction)
      movement.set_position(nil, movement.position.y + penetration)
      collision.on_platform = true
    end

  -- walk off ledges
  elseif collision.on_platform and not rc_result_bottom2 then
    timers(CT_TIMER_JUMP)
  end
end

function collision.reset_on_platform()
  collision.on_platform = false
end

return collision
