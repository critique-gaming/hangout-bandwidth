local Button = require "crit.button"
local colors = require "lib.colors"
local util = require "lib.util"
local table_util = require "crit.table_util"

-- C:\Users\Cata\AppData\Local\Programs\Microsoft VS Code\Code.exe
local h__button_rect = hash("button_rect/button")
local h__button_rect_label = hash("button_rect/label")
local h__button_rect_shadow = hash("button_rect/shadow")
local h__button_rect_background = hash("button_rect/background")
local h__button_rect_image = hash("button_rect/image")
local h__button_rect_hitbox = hash("button_rect/hitbox")

local ALIGN_CENTER = 1
local ALIGN_LEFT = 2
local ALIGN_RIGHT = 3

local button_rect = {
  ALIGN_CENTER = ALIGN_CENTER,
  ALIGN_LEFT = ALIGN_LEFT,
  ALIGN_RIGHT = ALIGN_RIGHT,
  anim_duration = 0.1,
  default_darken = 0.7,
}

local noop = function () end

local function button_rect_on_state_change(button, state, old_state)
  local nodes = button.nodes
  local size_x = button.background_size.x
  if state == Button.STATE_PRESSED then
    size_x = size_x + 10.0
  elseif state == Button.STATE_HOVER then
    size_x = size_x + 10.0
  end
  local size = vmath.vector3(
    size_x,
    button.background_size.y,
    button.background_size.z
  )
  gui.play_flipbook(button.nodes.background, button.background_images[state])
  gui.cancel_animation(nodes.background, gui.PROP_SIZE)
  gui.animate(nodes.background, gui.PROP_SIZE, size, gui.EASING_OUTCIRC, button_rect.anim_duration)
end

local function align_button(nodes, align, original_size)
  local button_size = gui.get_size(nodes.background)
  local original_positions = {}
  for id, node in pairs(nodes) do
    original_positions[id] = gui.get_position(node)
  end
  local x_offset
  if align == button_rect.ALIGN_CENTER then
    x_offset = 0.0
  elseif align == button_rect.ALIGN_LEFT then
    x_offset = - button_size.x * 0.5
  elseif align == button_rect.ALIGN_RIGHT then
    x_offset = button_size.x * 0.5
  else
    x_offset = 0.0
  end

  local size_diff_x = button_size.x - original_size.x
  for id, node in pairs(nodes) do
    if id ~= "root" then
      local original_pos = original_positions[id]
      local position = vmath.vector3(
        original_pos.x + x_offset,
        original_pos.y,
        original_pos.z
      )
      if id == "image" and original_pos.x ~= 0 then
        position = vmath.vector3(
          original_pos.x + x_offset + size_diff_x / 2,
          original_pos.y,
          original_pos.z
        )
      end
      gui.set_position(node, position)
    end
  end
end

function button_rect.make_button(template_node, opts)
  opts = opts or {}
  local nodes = gui.clone_tree(template_node)

  local node_root = nodes[h__button_rect]
  local node_label = nodes[h__button_rect_label]
  local node_shadow = nodes[h__button_rect_shadow]
  local node_background = nodes[h__button_rect_background]
  local node_image = nodes[h__button_rect_image]
  local node_hitbox = nodes[h__button_rect_hitbox]

  local original_size = gui.get_size(node_background)
  local original_shadow_size = gui.get_size(node_shadow)
  local shadow_padding = vmath.vector3(
    original_shadow_size.x - original_size.x,
    original_shadow_size.y - original_size.y,
    original_shadow_size.x - original_size.z
  )
  local original_text_metrics = gui.get_text_metrics_from_node(node_label)
  local text_scale = gui.get_scale(node_label)

  local button_padding = vmath.vector3(
    original_size.x - original_text_metrics.width * text_scale.x,
    original_size.y - original_text_metrics.height + text_scale.y,
    0.0
  )

  local color = opts.color or colors.button_background
  local pressed_color = opts.pressed_color or colors.white
  local text = opts.text or ""
  local label_color = opts.label_color or colors.text_color
  local scale = opts.scale or 1.0
  local image_scale = opts.image_scale or 1.0

  if opts.image then
    util.try_play_flipbook(node_image, opts.image)
  else
    gui.delete_node(node_image)
  end

  local text_metrics
  if text then
    gui.set_text(node_label, text)
    text_metrics = gui.get_text_metrics_from_node(node_label)
  else
    gui.set_enabled(node_label, false)
  end

  local size = vmath.vector3()
  size.x = opts.size_x or original_size.x
  size.y = opts.size_y or original_size.y
  size.z = original_size.z

  if opts.resize_x and text_metrics then
    size.x = text_metrics.width * text_scale.x + button_padding.x
  end

  gui.set_size(node_background, size)
  gui.set_size(node_hitbox, size)
  gui.set_size(node_shadow, size + shadow_padding)

  local button_nodes = {
    root = node_root,
    label = node_label,
    shadow = node_shadow,
    background = node_background,
    image = node_image,
    hitbox = node_hitbox,
  }

  align_button(button_nodes, opts.align or button_rect.ALIGN_CENTER, original_size)

  local background_images = {
    [Button.STATE_DEFAULT] = hash("button_"  .. opts.action_name .. "_default"),
    [Button.STATE_HOVER] = hash("button_"  .. opts.action_name .. "_hover"),
    [Button.STATE_PRESSED] = hash("button_"  .. opts.action_name .. "_hover"),
    [Button.STATE_DISABLED] = hash("button_"  .. opts.action_name .. "_disabled")
  }

  local label_colors = {
    [Button.STATE_DEFAULT] = label_color,
    [Button.STATE_HOVER] = colors.white,
    [Button.STATE_PRESSED] = colors.gray(0.7),
    [Button.STATE_DISABLED] = colors.gray(0.5)
  }

  gui.set_enabled(node_root, true)
  gui.set_enabled(node_hitbox, false)
  gui.set_scale(node_root, vmath.vector3(scale))
  gui.set_scale(node_image, vmath.vector3(image_scale))

  gui.set_color(node_label, label_color)
  gui.set_color(node_background, color)
  gui.set_color(node_image, opts.image_color or colors.white)
  gui.set_color(node_shadow, opts.shadow_colors or colors.button_shadow)
  local action = opts.action or noop

  local default_on_state_change = {
    button_rect_on_state_change,
    Button.tint({
      duration = button_rect.anim_duration,
      color = label_colors,
      node = node_label,
    })
  }

  local button
  button = Button.new(node_hitbox, table_util.assign({
    on_state_change = opts.override_on_state_change and
      { opts.override_on_state_change } or default_on_state_change,
    action = function ()
      action()
    end,
    background_images = background_images,
    nodes = button_nodes,
    background_size = size,
  }, opts.button_opts))

  if opts.pick then
    button.pick = opts.pick
  end
  return button
end

return button_rect
