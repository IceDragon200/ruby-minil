$:.unshift(File.expand_path("../lib", File.dirname(__FILE__)))
require 'minil/functions'
require 'minil/color/palettize'

size = [32, 32]

meths = [
  :soft,
  :hard,
  :harsh,
]

rates = 33.times.map do |i|
  i / 32.0
end

color1 = Minil::Color.new(0xFFA48799)
color2 = Minil::Color.new(0xFFC63842)

cw, ch = *size

img = Image.create(cw * 4, ch * meths.size)

meths.each_with_index do |meth, i|
  colors = Minil::ColorPalettize.send(meth, color1)
  colors.each_with_index do |color, j|
    img.fill_rect(j * cw, i * ch, cw, ch, color.to_color.value)
  end
end

img.save_file("color_palettize_test.png")


[:rated, :circ, :sq, :cubic].each do |meth|
  img = Image.create(cw * 4, ch * rates.size)

  rates.each_with_index do |rate, i|
    colors = Minil::ColorPalettize.send(meth, color1, rate)
    colors.each_with_index do |color, j|
      img.fill_rect(j * cw, i * ch, cw, ch, color.to_color.value)
    end
  end

  img.save_file("color_palettize_test_#{meth}.png")
end
