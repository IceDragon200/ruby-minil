$:.unshift(File.expand_path("../lib", File.dirname(__FILE__)))
require 'minil/layout/gauges'
require 'minil/color'
require "fileutils"

@img = Image.create(128, 16)
vertical = true

options = {
  c1: Minil::Color.encode(117, 117, 117, 255), c2: Minil::Color.encode(66,  66,  66,  255),
  c3: Minil::Color.encode(91, 91, 91, 255), c4: Minil::Color.encode(42, 42, 42, 255),
  hg: Minil::Color.encode(255, 255, 255, 51), hg2: 0x00000000
}

10.times do |i|
  Minil::LayoutWrapper.new do |a|
    a.send("gauge#{i}", vertical)
  end.call(@img, @img.rect, options)
  @img.save_file("g#{i}.png")
end
