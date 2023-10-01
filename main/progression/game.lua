local screens = require "lib.screens"
local progression = require "crit.progression"
local env = require "crit.env"
local levels = require "lib.data.levels"

local h_advance_scene = hash("advance_scene")

local function game()
  if not env.skip_intro then
    screens.replace("intro")()
    progression.wait_for_message(h_advance_scene)
  end

  if env.current_level then
    levels.current_level = env.current_level
    screens.replace("game")()
    progression.wait_for_message(h_advance_scene)
  end

  for i = 1, #levels.levels do
    levels.current_level = i
    screens.replace("game")()
    progression.wait_for_message(h_advance_scene)
  end
end

return game
