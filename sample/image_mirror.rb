$:.unshift(File.expand_path("../lib", File.dirname(__FILE__)))
require 'minil/functions'

img = Image.create(8, 8)
img.fill_rect(0, 0, 4, 8, 0xFF000000)
img.fill_rect(4, 0, 4, 8, 0xFFFFFFFF)
img.save_file("mirror_test-no.png")
img.mirror.save_file("mirror_test-yes.png")
