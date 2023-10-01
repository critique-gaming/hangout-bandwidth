local h_pixel = hash("pixel")

local M = {}

function M.try_play_flipbook(node, animation, default_animation)
  local ok = pcall(function ()
    gui.play_flipbook(node, animation)
  end)
  if not ok then
    pcall(function ()
      gui.play_flipbook(node, default_animation or h_pixel)
    end)
  end
end

function M.sprite_try_play_flipbook(sprite_url, animation, default_animation)
  local ok = pcall(function ()
    sprite.play_flipbook(sprite_url, animation)
  end)
  if not ok then
    pcall(function ()
      sprite.play_flipbook(sprite_url, default_animation or h_pixel)
    end)
  end
end

function M.remap_value(x, min, max, newmin, newmax)
  return newmax + (newmax - newmin) / (max - min) * (x - max)
end

function M.get_bar_fill(value, original_size, min_fill)
  return vmath.vector3(
    M.scale_value(value, 0, 1, min_fill, original_size.x),
    original_size.y,
    original_size.z
  )
end

function M.clamp(value, min, max)
  return math.max(math.min(value, max), min)
end

function M.clamp_vector(vec, minx, maxx, miny, maxy, minz, maxz)
  return vmath.vector3(
    M.clamp(vec.x, minx, maxx),
    M.clamp(vec.y, miny, maxy),
    M.clamp(vec.z, minz, maxz)
  )
end

function M.layout_centered(item_index, total_item_count, spacing)
  return (item_index - 0.5 - total_item_count/2) * spacing
end

function M.fit_text_node_by_height(node, orig_size, orig_scale, max_height)
  local metrics = gui.get_text_metrics_from_node(node)
  local text_height = metrics.height * orig_scale.y
  local y_overflow = text_height - max_height
  local overflow_ratio = max_height / text_height
  if y_overflow > 0 then
    gui.set_scale(node, orig_scale * overflow_ratio)
    local text_size = vmath.vector3(
      orig_size.x * 1 / overflow_ratio,
      orig_size.y,
      orig_size.z
    )
    gui.set_size(node, text_size)
  end
end

function M.table_sanitize_null_userdata(t)
  if not t or type(t) ~= "table" then
    print("You must provide a table to sanitize")
    return t
  end

  for key, val in pairs(t) do
    if (type(val) == "table") then
      M.table_sanitize_null_userdata(val)
    elseif val == json.null then
      t[key] = nil;
    end
  end

  return t
end

function M.json_decode_sanitized(json_string)
  return M.table_sanitize_null_userdata(json.decode(json_string));
end

return M
