local screens = require "lib.screens"
local progression = require "crit.progression"
local env = require "crit.env"

local h_advance_scene = hash("advance_scene")

local function game()
  if not env.skip_intro then
    screens.replace("intro")()
    progression.wait_for_message(h_advance_scene)
  end

  screens.replace("game")()
end

return game
