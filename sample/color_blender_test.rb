require_relative 'common'

size = [32, 32]

blends = [
  :blend_add,
  :blend_alpha,
  :blend_alpha2,
  :blend_burn,
  :blend_divide,
  :blend_dodge,
  :blend_multiply,
  :blend_overlay,
  :blend_screen,
  :blend_softlight,
  :blend_subtract,
]

rate_blends = [
  :normal,
  :lighten,
  :darken,
  :selfadd,
  :selfsubtract,
]


rates = 33.times.map do |i|
  i / 32.0
end

color1 = Minil::Color.new(0xFFA48799)
color2 = Minil::Color.new(0xFFC63842)

cw, ch = *size
img = Minil::Image.create(cw * 3, ch * blends.size)

blends.each_with_index do |blend_mode, i|
  color = Minil::ColorBlender.send(blend_mode, color1, color2)
  #puts [blend_mode, color]
  img.fill_rect(0, ch * i, cw, ch, color1.value)
  img.fill_rect(cw, ch * i, cw, ch, color.to_color.value)
  img.fill_rect(cw*2, ch * i, cw, ch, color2.value)
end

save_image(img, "color_blend_test.png")

img = Minil::Image.create(cw * rates.size, ch * rate_blends.size)

rate_blends.each_with_index do |blend_mode, i|
  rates.each_with_index do |rate, j|
    color = Minil::ColorBlender.send(blend_mode, color1, rate)
    img.fill_rect(j * cw, i * ch, cw, ch, color.to_color.value)
  end
end

save_image(img, "color_blend_test2.png")
