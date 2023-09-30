local data = require "lib.data.conversation"

local M = {}

function M.init()
  local self = {}

  function self.get_next_line(action)
    return data.topics[math.random(#data.topics)].statement
  end

  return self
end

return M
