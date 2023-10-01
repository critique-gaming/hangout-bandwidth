local colors = require "crit.colors"

local vec4 = vmath.vector4
local from_hex = colors.from_hex

local color = {
  white = vec4(1.0, 1.0, 1.0, 1.0),
  black = vec4(0.0, 0.0, 0.0, 1.0),
  transparent_white = vec4(1.0, 1.0, 1.0, 0.0),
  transparent_black = vec4(0.0, 0.0, 0.0, 0.0),
  transparent = vec4(0.0, 0.0, 0.0, 0.0),
}

color.bright_gold = from_hex("#fcb15d")
color.bright_yellow = from_hex("#fff8a7")
color.error = from_hex("#e52b2b")
color.green_positive = from_hex("#7fff88")
color.red_negative = from_hex("#ff5151")
color.yellow_warning = from_hex("#ffc051")


color.agree = from_hex("#5d8b6d")
color.disagree = from_hex("#a0655e")
color.ask_for_more = from_hex("#65888f")
color.change_subject = from_hex("#8f6579")

color.actions = {
  yes = color.agree,
  no = color.disagree,
  change = color.change_subject,
  more = color.ask_for_more,
}

color.text_color = colors.gray(0.9)

color.button_outline = from_hex("#699dec")
color.button_background = colors.gray(0.0)
color.button_shadow = color.transparent_white

return color
