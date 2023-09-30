local color_definitions = require "lib.color_definitions"

local vec4 = vmath.vector4
local inv_255 = 1.0 / 255.0
local inv_15 = 1.0 / 15.0

local M = {}

-- copy our color definitions into this table
for key, val in pairs(color_definitions) do
  M[key] = val
end

function M.clamp01(val)
  return math.max(math.min(val, 1.0), 0.0)
end

function M.clamp01vec4(vec)
  vec.x = M.clamp01(vec.x)
  vec.y = M.clamp01(vec.y)
  vec.z = M.clamp01(vec.z)
  vec.w = M.clamp01(vec.w)
  return vec
end

-- all hsv and rgb values are normalized (0.0 to 1.0)
local function hsv_to_rgb_internal(vec)
  local H = vec.x * 360.0
  local s = vec.y
  local v = vec.z

  local C = s * v -- chroma
  local X = C * (1.0 - math.abs(math.fmod(H / 60.0, 2.0) - 1.0))
  local m = v - C

  local rgb

  if H >= 0.0 and H < 60.0 then
    rgb = vmath.vector3(C, X, 0)
  elseif H >= 60.0 and H < 120.0 then
    rgb = vmath.vector3(X, C, 0)
  elseif H >= 120.0 and H < 180.0 then
    rgb = vmath.vector3(0, C, X)
  elseif H >= 180.0 and H < 240.0 then
    rgb = vmath.vector3(0, X, C)
  elseif H >= 240.0 and H < 300 then
    rgb = vmath.vector3(X, 0, C)
  else
    rgb = vmath.vector3(C, 0, X)
  end

  return vmath.vector4(rgb.x + m, rgb.y + m, rgb.z + m, 1.0)
end

-- all hsv and rgb values are normalized (0.0 to 1.0)
local function rgb_to_hsv_internal(vec)
  local r = vec.x
  local g = vec.y
  local b = vec.z

  local h, s, v

  local cmax = math.max(r, math.max(g, b))
  local cmin = math.min(r, math.min(g, b))
  local diff = cmax - cmin

  if cmax == cmin then
      h = 0
  elseif cmax == r then
      h = math.fmod(60 * ((g - b) / diff) + 360, 360)
  elseif cmax == g then
      h = math.fmod(60 * ((b - r) / diff) + 120, 360)
  elseif cmax == b then
      h = math.fmod(60 * ((r - g) / diff) + 240, 360)
  end

  if cmax == 0 then
      s = 0
  else
      s = (diff / cmax) -- * 100
  end

  v = cmax -- * 100
  h = h / 360 -- we are in normalized hue mode

  return vmath.vector4(h, s, v, vec.w)
end

-- get normalized rgb from normalized hsv
function M.hsv_to_rgb(vec)
  return hsv_to_rgb_internal(vec)
end

-- get 0-255 rgb from normalized hsv
function M.hsv_to_rgb255(vec)
  return hsv_to_rgb_internal(vec) * 255
end

-- get normalized hsv from normalized rgb
function M.rgb_to_norm_hsv(vec)
  local r = vec.x
  local g = vec.y
  local b = vec.z

  local h, s, v

  local cmax = math.max(r, math.max(g, b))
  local cmin = math.min(r, math.min(g, b))
  local diff = cmax - cmin

    if cmax == cmin then
        h = 0
    elseif cmax == r then
        h = math.fmod(60 * ((g - b) / diff) + 360, 360)
    elseif cmax == g then
        h = math.fmod(60 * ((b - r) / diff) + 120, 360)
    elseif cmax == b then
        h = math.fmod(60 * ((r - g) / diff) + 240, 360)
    end

    if cmax == 0 then
        s = 0
    else
        s = (diff / cmax) -- * 100
    end

    v = cmax -- * 100
    h = h / 360 -- we are in normalized hue mode
  return vmath.vector4(h, s, v, vec.w)
end

-- get hsv from normalized rgb
function M.rgb_to_hsv(vec)
  local hsv = rgb_to_hsv_internal(vec)
  return vmath.vector4(hsv.x * 360, hsv.y * 100, hsv.z * 100, vec.w)
end

function M.from_hex(hex)
  hex = hex:gsub("^#","")

  local r, g, b, a
  a = 1.0

  local len = #hex

  if len == 6 or len == 8 then
    r = tonumber("0x" .. hex:sub(1, 2)) * inv_255
    g = tonumber("0x" .. hex:sub(3, 4)) * inv_255
    b = tonumber("0x" .. hex:sub(5, 6)) * inv_255
    if len == 8 then
      a = tonumber("0x" .. hex:sub(7, 8)) * inv_255
    end
    return vec4(r, g, b, a)
  end

  if len == 3 or len == 4 then
    r = tonumber("0x" .. hex:sub(1, 1)) * inv_15
    g = tonumber("0x" .. hex:sub(2, 2)) * inv_15
    b = tonumber("0x" .. hex:sub(3, 3)) * inv_15
    if len == 4 then
      a = tonumber("0x" .. hex:sub(4, 4)) * inv_15
    end
    return vec4(r, g, b, a)
  end

  error("Invalid color format: " .. hex)
end

local min = math.min
local max = math.max

local function component_to_hex(x)
  return ("%02X"):format(max(0, min(255, x * 255)))
end

function M.to_hex(color)
  return
    component_to_hex(color.x) ..
    component_to_hex(color.y) ..
    component_to_hex(color.z) ..
    component_to_hex(color.w)
end

function M.to_hex_rgb(color)
  return
    component_to_hex(color.x) ..
    component_to_hex(color.y) ..
    component_to_hex(color.z)
end

function M.vmul(a, b)
  return vec4(a.x * b.x, a.y * b.y, a.z * b.z, a.w * b.w)
end

function M.darken(color, brightness)
  return vec4(color.x * brightness, color.y * brightness, color.z * brightness, color.w)
end

function M.fade(color, alpha)
  return vec4(color.x, color.y, color.z, color.w * alpha)
end

function M.with_alpha(color, alpha)
  return vec4(color.x, color.y, color.z, alpha)
end

function M.gray(value)
  return vec4(value, value, value, 1.0)
end

function M.gui_set_color_alpha(node, alpha)
  local color = gui.get_color(node)
  color.w = alpha
  gui.set_color(node, color)
end

function M.scale(value)
  return vmath.vector3(value, value, 1)
end

return M
