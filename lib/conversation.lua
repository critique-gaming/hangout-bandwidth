local M = {}

function M.init()
  local self = {}

  function self.get_next_line(action)
    return "This is a line of dialogue " .. math.random(100)
  end

  return self
end

return M
