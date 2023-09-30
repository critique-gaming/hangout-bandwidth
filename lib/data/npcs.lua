local M = {
  alice = { -- The defaults
    popularity = 0.5,
    p_deny_interruptions = 0.5,
    pes_interrupt_topic_end = 0.15,
    pes_interrupt_topic_start = 0.002,
    patience = 5,
  },
  bob = { -- The asshole
    popularity = 0.8,
    p_deny_interruptions = 0.7,
    pes_interrupt_topic_end = 0.15,
    pes_interrupt_topic_start = 0.08,
    patience = 4,
  },
}

for k, v in pairs(M) do
  v.id = v.id or k
end

return M
