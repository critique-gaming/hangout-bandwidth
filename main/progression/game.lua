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

  local popularity = levels.player_start_popularity
  function run_level(level)
    levels.current_level = level
    levels.player_start_popularity = popularity
    screens.replace("game")()
    popularity = progression.wait_for_message(h_advance_scene).popularity
  end

  if env.current_level then
    run_level(env.current_level)
  end

  for i = 1, #levels.levels do
    run_level(i)
  end
end

return game
