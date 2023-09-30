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

  return self
end

function M.init_npc_agent(options)
  local self = M.init_agent(options)

  self.p_deny_interruptions = 0.5
  self.pes_interrupt_topic_end = 0.15
  self.pes_interrupt_topic_start = 0.002
  self.patience = 5
  self.p_dislike_interrupt_topic_start = 0.8
  self.p_dislike_interrupt_topic_end = 0.1
  self.p_popularity_lying = 0.2
  self.pes_expectation = 0.05
  self.p_hide_expectation = 0.5

  local interruption_deny_elapsed = -1
  local pending_expectation_like = 0
  local pending_expectation_like_target = nil

  local function get_action()
    return 'change'
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

    local probability_every_second = math.pow(1 - topic_progress, self.patience)
      * (self.pes_interrupt_topic_end - self.pes_interrupt_topic_start)
      + self.pes_interrupt_topic_start

    local probability = 1 - math.pow(1 - probability_every_second, dt)

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

  local function set_expectation(expectation)
    self.expectation = expectation

    local reported_expectation = expectation
    if expectation then
      if math.random() < self.p_hide_expectation then
        reported_expectation = "hidden"
      end
    end

    self.controller.on_set_expectation(self, reported_expectation)
  end

  function self.topic_started(topic)
    if self.expectation then
      pending_expectation_like = topic.action == self.expectation and 1 or -1
      pending_expectation_like_target = topic.speaker
    else
      pending_expectation_like = 0
      pending_expectation_like_target = nil
    end
  end

  return self
end

function M.init_controller(agents, options)
  local pending_interruption_duration = 1.0
  local denied_interrupt_bonus = 2.0
  local popularity_bonus_per_like = 0.1

  local current_topic = nil
  local time_remaining = 0

  local pending_topic = nil
  local pending_interruption_remaining = 0

  local self = options or {}
  self.agents = agents

  self.on_interruption_requested = self.on_interruption_requested or function (_pending_topic, _old_topic) end
  self.on_interruption_accepted = self.on_interruption_accepted or function (_pending_topic, _old_topic) end
  self.on_interruption_denied = self.on_interruption_denied or function (_pending_topic, _old_topic) end
  self.on_change_topic = self.on_change_topic or function (_topic) end
  self.on_gain_like = self.on_gain_like or function (_sender, _target, _like_amount, _old_popularity, _new_popularity) end
  self.on_set_expectation = self.on_set_expectation or function (_agent, _expectation) end

  local function start_speaking(topic)
    current_topic = topic
    time_remaining = topic.duration

    topic.duration = self.on_change_topic(topic) or topic.duration
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
    current_topic = nil
    self.on_change_topic()
  end

  function self.update(dt)
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

    local topic = {
      speaker = agent,
      action = action,
      duration = 5,
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

    return true
  end

  function self.give_like(sender, target, like_amount)
    local popularity_gain = popularity_bonus_per_like * like_amount * sender.popularity
    local old_popularity = target.popularity
    target.popularity = math.max(0, math.min(1, old_popularity + popularity_gain))
    self.on_gain_like(sender, target, like_amount, old_popularity, target.popularity)
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
