local table_util = require "crit.table_util"

local M = {}

function M.init_agent(options)
  local self = options or {}
  self.popularity = self.popularity or 0.5

  function self.init(controller)
    self.controller = controller
  end

  function self.update()
  end

  function self.request_interruption()
  end

  function self.interrupted()
  end

  function self.interruption_denied()
  end

  function self.topic_started()
  end

  function self.topic_finished()
  end

  return self
end

local function from_pes(pes, dt)
  return 1 - math.pow(1 - pes, dt)
end

local all_actions = { "yes", "no", "more", "change" }
local op_valid_actions = { "more", "change" }
local opinionated_actions = { "change" }

function M.init_npc_agent(options)
  local self = M.init_agent(options)

  self.p_deny_interruptions = self.p_deny_interruptions or 0.5
  self.pes_interrupt_topic_end = self.pes_interrupt_topic_end or 0.18
  self.pes_interrupt_topic_start = self.pes_interrupt_topic_start or 0.006
  self.patience = self.patience or 5
  self.p_dislike_interrupt_topic_start = self.p_dislike_interrupt_topic_start or 0.8
  self.p_dislike_interrupt_topic_end = self.p_dislike_interrupt_topic_end or 0.1
  self.p_popularity_lying = self.p_popularity_lying or 0.2
  self.pes_expectation = self.pes_expectation or 0.2
  self.p_hide_expectation = self.p_hide_expectation or 0.4
  self.pes_expectation_like = self.pes_expectation_like or 0.8
  self.pes_speak_when_free = self.pes_speak_when_free or self.pes_interrupt_topic_end

  local interruption_deny_elapsed = -1
  local pending_expectation_like = 0
  local pending_expectation_like_target = nil
  local requested_more = false
  local said_opinion = false

  local function meets_expectation(topic_action, expectation)
    return topic_action == expectation or topic_action == "followup_more" and expectation == "more"
  end

  local function get_action()
    local op = self.controller.get_original_poster()
    if op == nil then
      return "change"
    end

    local valid_actions = all_actions
    if op == self then
      valid_actions = op_valid_actions
    elseif said_opinion then
      valid_actions = opinionated_actions
    end

    if math.random() < self.p_popularity_lying then
      local max_popularity_gain = 0
      local max_popularity_gain_action = nil

      for _, action in ipairs(valid_actions) do
        local popularity_gain = 0

        for _, agent in ipairs(self.controller.agents) do
          if agent ~= self and agent.expectation ~= nil then
            local like_amount = meets_expectation(action, agent.expectation) and 1 or -1
            popularity_gain = popularity_gain
              + like_amount * self.controller.popularity_bonus_per_like * agent.popularity
          end
        end

        if popularity_gain > max_popularity_gain then
          max_popularity_gain = popularity_gain
          max_popularity_gain_action = action
        end
      end

      if max_popularity_gain_action ~= nil then
        return max_popularity_gain_action
      end
    end

    if self.expectation then
        return self.expectation
    end

    if requested_more then
      return "more"
    end

    return all_actions[math.random(#valid_actions)]
  end

  local function set_expectation(expectation)
    if expectation == self.expectation then
      return
    end

    self.expectation = expectation

    local reported_expectation = expectation
    if expectation then
      if math.random() < self.p_hide_expectation then
        reported_expectation = "hidden"
      end
    end

    self.controller.on_set_expectation(self, reported_expectation, expectation)
  end

  function self.update(dt)
    if interruption_deny_elapsed ~= -1 then
      interruption_deny_elapsed = interruption_deny_elapsed - dt
      if interruption_deny_elapsed <= 0 then
        interruption_deny_elapsed = -1
        self.controller.deny_interruption(self)
      end
    end

    local current_topic, topic_progress = self.controller.get_current_topic()
    if current_topic ~= nil and current_topic.speaker == self then
      return
    end

    if current_topic ~= nil then
      if pending_expectation_like ~= 0 then
        if math.random() < from_pes(self.pes_expectation_like, dt) then
          self.controller.give_like(self, pending_expectation_like_target, pending_expectation_like)
          pending_expectation_like = 0
        end
      elseif self.expectation == nil then
        if math.random() < from_pes(self.pes_expectation, dt) then
          local new_expectation = all_actions[math.random(#all_actions)]
          set_expectation(new_expectation)
        end
      end
    end

    local probability_every_second = topic_progress <= 0
      and self.pes_speak_when_free
      or (math.pow(1 - topic_progress, self.patience)
        * (self.pes_interrupt_topic_end - self.pes_interrupt_topic_start)
        + self.pes_interrupt_topic_start)

    local probability = from_pes(probability_every_second, dt)

    if math.random() < probability then
      self.controller.try_speaking(self, get_action())
    end
  end

  function self.request_interruption(interruptee, interruption_duration)
    if self.controller.can_deny_interruption() then
      if math.random() < self.p_deny_interruptions then
        interruption_deny_elapsed = interruption_duration * 0.75
      end
    end

    local _, topic_progress = self.controller.get_current_topic()
    local p_dislike_interrupt = (1 - topic_progress)
      * (self.p_dislike_interrupt_topic_end - self.p_dislike_interrupt_topic_start)
      + self.p_dislike_interrupt_topic_start
    if math.random() < p_dislike_interrupt then
      self.controller.give_like(self, interruptee, -1)
    end
  end

  function self.topic_started(topic)
    if topic.speaker ~= self and self.expectation then
      pending_expectation_like = meets_expectation(topic.action, self.expectation) and 1 or -1
      pending_expectation_like_target = topic.speaker
    else
      pending_expectation_like = 0
      pending_expectation_like_target = nil
    end
    set_expectation(nil)

    if topic.action == "change" then
      said_opinion = false
    elseif topic.speaker == self and (topic.action == "yes" or topic.action == "no") then
      said_opinion = true
    end

    requested_more = self.controller.get_original_poster() == self
      and topic.speaker ~= self
      and topic.action == "more"
  end

  function self.topic_finished()
    if requested_more then
      self.controller.try_speaking(self, get_action())
    end
  end

  return self
end

function M.init_controller(agents, options)
  local current_topic = nil
  local time_remaining = 0

  local pending_topic = nil
  local pending_interruption_remaining = 0

  local original_poster = nil

  local self = options or {}

  local pending_interruption_duration = 1.0
  local denied_interrupt_bonus = 2.0
  local default_topic_duration = 4
  self.popularity_bonus_per_like = 0.1

  self.agents = agents

  self.on_interruption_requested = self.on_interruption_requested or function (_pending_topic, _old_topic) end
  self.on_interruption_accepted = self.on_interruption_accepted or function (_pending_topic, _old_topic) end
  self.on_interruption_denied = self.on_interruption_denied or function (_pending_topic, _old_topic) end
  self.on_change_topic = self.on_change_topic or function (_topic, _old_topic) end
  self.on_gain_like = self.on_gain_like or function (_sender, _target, _like_amount, _old_popularity, _new_popularity) end
  self.on_set_expectation = self.on_set_expectation or function (_agent, _expectation) end
  self.on_duration_expired = self.on_duration_expired or function () end
  self.on_game_over = self.on_game_over or function () end

  local function start_speaking(topic)
    local old_topic = current_topic
    current_topic = topic
    time_remaining = topic.duration

    if topic.action == "change" then
      original_poster = topic.speaker
    end

    topic.duration = self.on_change_topic(topic, old_topic) or topic.duration
    time_remaining = topic.duration

    for _, agent in ipairs(agents) do
      agent.topic_started(topic)
    end
  end

  local function accept_interruption()
    local topic = pending_topic
    local old_topic = current_topic

    pending_topic = nil
    pending_interruption_remaining = 0

    start_speaking(topic)

    if old_topic then
      old_topic.speaker.interrupted()
    end

    self.on_interruption_accepted(topic, old_topic)
  end

  local function topic_finished()
    local topic = current_topic
    current_topic = nil

    if self.duration and self.duration <= 0 then
      self.on_game_over()
    else
      for _, agent in ipairs(agents) do
        agent.topic_finished(topic)
      end
      self.on_change_topic(nil, topic)
    end
  end

  function self.update(dt)
    if self.duration then
      self.duration = self.duration - dt
      if self.duration <= 0 and not self.expired_fired then
        self.expired_fired = true
        self.on_duration_expired()
      end
    end

    if pending_topic ~= nil then
      if pending_interruption_remaining <= dt then
        accept_interruption()
      else
        pending_interruption_remaining = pending_interruption_remaining - dt
      end
    else
      if current_topic ~= nil then
        if time_remaining <= dt then
          topic_finished()
        else
          time_remaining = time_remaining - dt
        end
      end
    end

    for _, agent in ipairs(agents) do
      agent.update(dt)
    end
  end

  function self.get_current_topic()
    local topic_progress = current_topic and (time_remaining  / current_topic.duration) or 0
    return current_topic, topic_progress, time_remaining
  end

  function self.get_pending_topic()
    return pending_topic, pending_interruption_remaining / pending_interruption_duration, pending_interruption_remaining
  end

  function self.try_speaking(agent, action)
    if not self.can_agent_interrupt(agent) then
      return
    end

    if action == "more" and original_poster == agent then
      action = "followup_more"
    end

    local topic = {
      speaker = agent,
      action = action,
      duration = default_topic_duration,
    }

    if current_topic == nil then
      start_speaking(topic)
    else
      pending_topic = topic
      pending_interruption_remaining = pending_interruption_duration
      current_topic.speaker.request_interruption(agent, pending_interruption_remaining)
      self.on_interruption_requested(pending_topic, current_topic)
    end
  end

  function self.can_deny_interruption()
    if pending_topic == nil or current_topic == nil then
      return false
    end
    return current_topic.speaker.popularity >= pending_topic.speaker.popularity
  end

  function self.deny_interruption(agent)
    if not self.can_deny_interruption() then
      return
    end

    if current_topic.speaker ~= agent then
      return
    end

    local old_pending_topic = pending_topic
    pending_topic = nil
    pending_interruption_remaining = 0
    time_remaining = time_remaining + denied_interrupt_bonus

    old_pending_topic.speaker.interruption_denied(old_pending_topic, current_topic)
    self.on_interruption_denied(old_pending_topic, current_topic)
  end

  function self.can_agent_interrupt(agent)
    if pending_topic ~= nil then
      return false
    end

    if current_topic ~= nil and current_topic.speaker == agent then
      return false
    end

    if self.duration and self.duration <= 0 then
      return false
    end

    return true
  end

  function self.give_like(sender, target, like_amount)
    local popularity_gain = self.popularity_bonus_per_like * like_amount * sender.popularity
    local old_popularity = target.popularity
    target.popularity = math.max(0, math.min(1, old_popularity + popularity_gain))
    self.on_gain_like(sender, target, like_amount, old_popularity, target.popularity)
  end

  function self.get_original_poster()
    return original_poster
  end

  for _, agent in ipairs(agents) do
    agent.init(self)
  end

  return self
end

function M.load_agents_from_level(player, level, npcs)
  local agents = { player }
  for _, agent_id in ipairs(level.npcs) do
    agents[#agents+1] = M.init_npc_agent(table_util.clone(npcs[agent_id]))
  end
  return agents
end

return M
