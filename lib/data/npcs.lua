local M = {
  deer = { -- The defaults
    popularity = 0.5,
    p_deny_interruptions = 0.5,
    pes_interrupt_topic_end = 0.18,
    pes_interrupt_topic_start = 0.007,
    patience = 5,
    pes_expectation = 0.05,
    p_hide_expectation = 0.5,
    p_popularity_lying = 0.2,
    p_dislike_interrupt_topic_start = 0.8,
    p_dislike_interrupt_topic_end = 0.1,
  },
  deer1 = { extends = "deer" },
  deer2 = { extends = "deer" },
  deer3 = { extends = "deer" },
  deer4 = { extends = "deer" },

  dog = { -- The asshole
    popularity = 0.5,
    p_deny_interruptions = 0.7,
    pes_interrupt_topic_end = 0.2,
    pes_interrupt_topic_start = 0.08,
    patience = 3,
    pes_expectation = 0.05,
    p_hide_expectation = 0.5,
    p_popularity_lying = 0.2,
    p_dislike_interrupt_topic_start = 0.8,
    p_dislike_interrupt_topic_end = 0.1,
  },
  dog1 = { extends = "dog" },
  dog2 = { extends = "dog" },
  dog3 = { extends = "dog" },

  fox = { -- The star
    popularity = 0.8,
    p_deny_interruptions = 0.5,
    pes_interrupt_topic_end = 0.15,
    pes_interrupt_topic_start = 0.002,
    patience = 2,
    pes_expectation = 0.05,
    p_hide_expectation = 0.5,
    p_popularity_lying = 0.2,
    p_dislike_interrupt_topic_start = 0.6,
    p_dislike_interrupt_topic_end = 0.05,
  },
  fox1 = { extends = "fox" },
  fox2 = { extends = "fox" },
  fox3 = { extends = "fox" },

  cat = { -- The judge
    popularity = 0.7,
    p_deny_interruptions = 0.5,
    pes_interrupt_topic_end = 0,
    pes_interrupt_topic_start = 0,
    patience = 5,
    pes_expectation = 0.2,
    p_hide_expectation = 0.9,
    p_popularity_lying = 0.2,
    p_dislike_interrupt_topic_start = 0.8,
    p_dislike_interrupt_topic_end = 0.1,

  },
  cat1 = { extends = "cat" },
  cat2 = { extends = "cat" },
  cat3 = { extends = "cat" },

  frog = { -- The cheer
    popularity = 0.4,
    p_deny_interruptions = 0.7,
    pes_interrupt_topic_end = 0.05,
    pes_interrupt_topic_start = 0.01,
    patience = 4,
    pes_expectation = 0.2,
    p_hide_expectation = 0.1,
    p_popularity_lying = 0.2,
    p_dislike_interrupt_topic_start = 0.8,
    p_dislike_interrupt_topic_end = 0.1,
  },
  frog1 = { extends = "frog" },
  frog2 = { extends = "frog" },
  frog3 = { extends = "frog" },

  horse = { -- The perfect
    popularity = 0.9,
    p_deny_interruptions = 0.1,
    pes_interrupt_topic_end = 0.1,
    pes_interrupt_topic_start = 0.02,
    patience = 4,
    pes_expectation = 0.05,
    p_hide_expectation = 0.5,
    p_popularity_lying = 0.2,
    p_dislike_interrupt_topic_start = 0.8,
    p_dislike_interrupt_topic_end = 0.1,
  },
  horse1 = { extends = "horse" },
  horse2 = { extends = "horse" },
  horse3 = { extends = "horse" },

  rabbit = { -- The climber
    popularity = 0.3,
    p_deny_interruptions = 0.7,
    pes_interrupt_topic_end = 0.2,
    pes_interrupt_topic_start = 0.08,
    patience = 4,
    pes_expectation = 0.05,
    p_hide_expectation = 0.5,
    p_popularity_lying = 0.8,
    p_dislike_interrupt_topic_start = 0.8,
    p_dislike_interrupt_topic_end = 0.1,
  },
  rabbit1 = { extends = "rabbit" },
  rabbit2 = { extends = "rabbit" },
  rabbit3 = { extends = "rabbit" },

  elephant = { -- The coward
    popularity = 0.5,
    p_deny_interruptions = 0.1,
    pes_interrupt_topic_end = 0.1,
    pes_interrupt_topic_start = 0.001,
    patience = 10,
    pes_expectation = 0.03,
    p_hide_expectation = 0.7,
    p_popularity_lying = 0.5,
    p_dislike_interrupt_topic_start = 0.6,
    p_dislike_interrupt_topic_end = 0.05,
  },
  elephant1 = { extends = "elephant" },
  elephant2 = { extends = "elephant" },
  elephant3 = { extends = "elephant" },
}

local function resolve(t)
  if not t.extends then
    return
  end

  local superclass = M[t.extends]
  t.extends = nil
  resolve(superclass)

  for k, v in pairs(superclass) do
    if t[k] ~= nil then
      t[k] = v
    end
  end
end

for k, v in pairs(M) do
  resolve(v)
  v.id = k
end

return M
