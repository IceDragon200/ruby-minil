$:.unshift(File.expand_path("../lib", File.dirname(__FILE__)))
require_relative 'common'

img = Minil::Image.create(8, 8)
img.fill_rect(0, 0, 4, 8, 0xFF000000)
img.fill_rect(4, 0, 4, 8, 0xFFFFFFFF)
save_image(img, "mirror_test-no.png")
save_image(img.mirror, "mirror_test-yes.png")
