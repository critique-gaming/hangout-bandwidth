local csv = require "lib.csv"

local M = {
  ask_for_more = {
    "What do you mean?",
    "Can you explain that?",
    "You made me curious!",
    "I'd like to hear more about that!",
    "Go on...",
    "Why though?",
    "I think that should come with an explanation!",
  },
  fallback_no_more = {
    "Sorry, I phased out for a second and forgot what we were talking about.",
    "Omg, slow down for a second, processing lag.",
    "Idk honestly, haven't thought about it more than that.",
    "It's quite self-evident at this point, isn't it?",
    "I really don't see what more is to say about it.",
    "Dig any deeper into it and we could write an essay.",
    "I'm a bit bored. Anyone wanna order some pizza?",
    "Damn, my phone ran out of battery! I hate when that happens.",
    "Wow, doesn't this give you max deja vu?",
    "Aaaaaand so the cookie crumbles.",
    "Can-not com-pute. Out of me-mo-ry. Please in-sert new disk!",
  },
  fallback_yes = {
    "Totally!",
    "Fair enough!",
    "Sounds bout right!",
    "Hear hear!",
    "Yep!",
    "Word!",
    "That's what I was saying!",
  },
  fallback_no = {
    "Ain't that a bit much?",
    "Idk, doesn't sound quite right to me!",
    "Are you sure of that?",
    "Hmmm",
    "That's not what I was expecting to hear today!",
    "Aaaaaakward!",
  },
}

local function nullify(x)
  if x == "" then
    return nil
  end
  return x
end

local function load_topics()
  local csv_file

  csv_file = csv.openstring(sys.load_resource("/data/batches.csv"), {
    columns = {
      weight = { name = "Weight", transform = tonumber },
      statement = { name = "Initial Statement" },
      yes1 = { name = "Agreement 1", transform = nullify },
      yes2 = { name = "Agreement 2", transform = nullify },
      yes3 = { name = "Agreement 3", transform = nullify },
      no1 = { name = "Disagreement 1", transform = nullify },
      no2 = { name = "Disagreement 2", transform = nullify },
      no3 = { name = "Disagreement 3", transform = nullify },
      more1 = { name = "Explanation 1", transform = nullify },
      more2 = { name = "Explanation 2", transform = nullify },
      more3 = { name = "Explanation 3", transform = nullify },
    }
  })

  local topics = {}

  local index = 1
  for v in csv_file:lines() do
    v.yes = { v.yes1, v.yes2, v.yes3 }
    v.no = { v.no1, v.no2, v.no3 }
    v.more = { v.more1, v.more2, v.more3 }
    v.yes1 = nil
    v.yes2 = nil
    v.yes3 = nil
    v.no1 = nil
    v.no2 = nil
    v.no3 = nil
    v.more1 = nil
    v.more2 = nil
    v.more3 = nil

    topics[index] = v
    index = index + 1
  end

  csv_file:close()

  return topics
end

M.topics = load_topics()

return M
