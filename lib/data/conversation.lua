local csv = require "lib.csv"

local function nullify(x)
  if x == "" then
    return nil
  end
  return x
end

local function load()
  local csv_file = csv.openstring(sys.load_resource("/data/batches.csv"), {
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

  local csv_data = {}
  local topics = {}
  csv_data.topics = topics

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

  return csv_data
end

return load()
