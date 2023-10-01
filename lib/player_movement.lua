local M = {
  z = 0.0,
  position = { x = 0, y = 0 },
  speed = { x = 0, y = 0 },
  freeze_movement_reasons = {
    generic = false,
  },

  FREEZE_REASON_LEVEL_INSTRUCTIONS = 101,
}

function M.reset()
  M.freeze_movement = false
  M.freeze_movement_reasons = {
    generic = false
  }
end

function M.is_frozen()
  for reason, frozen in pairs(M.freeze_movement_reasons) do
    if frozen then
      return true
    end
  end
  return false
end

function M.freeze(freeze, reason)
  if not reason then
    M.freeze_movement_reasons.generic = freeze
  else
    M.freeze_movement_reasons[reason] = freeze
  end
end

function M.set_position(pos_x, pos_y)
  if pos_x then
    M.position.x = pos_x
  end
  if pos_y then
    M.position.y = pos_y
  end
end

return M
