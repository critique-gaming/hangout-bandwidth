local data = require "lib.data.conversation"
local table_util = require "crit.table_util"

local M = {}

local function get_random_non_repeating(items, history, should_loop)
  local current_pass = history.current_pass or 1

  local selection_pool = {}
  local selection_pool_count = 0
  local total_weight = 0

  for _, item in ipairs(items) do
    local history_item = history[item]
    if history_item == nil or history_item.pass == nil or history_item.pass < current_pass then
      local weight = item.weight or 1
      total_weight = total_weight + weight

      -- Add to selection pool at random position
      selection_pool_count = selection_pool_count + 1
      local swap_index = math.random(selection_pool_count)
      if swap_index ~= selection_pool_count then
        selection_pool[selection_pool_count] = selection_pool[swap_index]
      end
      selection_pool[swap_index] = item
    end
  end

  if selection_pool_count == 0 then
    if should_loop then
      history.current_pass = current_pass + 1
      return get_random_non_repeating(items, history, should_loop)
    end
    return nil
  end

  local roll = math.random() * total_weight
  for _, item in ipairs(selection_pool) do
    local weight = item.weight or 1
    if roll < weight then
      local history_item = history[item]
      if history_item == nil then
        history_item = {}
        history[item] = history_item
      end
      history_item.pass = current_pass
      return item
    end
    roll = roll - weight
  end

  return nil -- Should never reach
end

function M.init()
  local self = {}

  local history = {}
  local more_history = {}
  local fallback_no_more_history = {}
  local fallback_yes_history = {}
  local fallback_no_history = {}
  local topic_history = { more = {}, yes = {}, no = {}}
  local topic = nil

  function self.get_next_line(action)
    if topic == nil or action == "change" then
      topic = get_random_non_repeating(data.topics, history, true)
      topic_history = { more = {}, yes = {}, no = {}}
      return topic.statement

    elseif action == "more" then
      return get_random_non_repeating(data.ask_for_more, more_history, true)

    elseif action == "followup_more" then
      return get_random_non_repeating(topic.more, topic_history.more, false)
        or get_random_non_repeating(data.fallback_no_more, fallback_no_more_history, true)

    elseif action == "yes" then
      return get_random_non_repeating(topic.yes, topic_history.yes, false)
        or get_random_non_repeating(data.fallback_yes, fallback_yes_history, true)

    elseif action == "no" then
      return get_random_non_repeating(topic.no, topic_history.no, false)
        or get_random_non_repeating(data.fallback_no, fallback_no_history, true)

    else
      -- Should not reach this
      return data.topics[math.random(#data.topics)].statement

    end

  end

  return self
end

return M
