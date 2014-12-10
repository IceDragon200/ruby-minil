$:.unshift(File.expand_path("../lib", File.dirname(__FILE__)))
require 'minil/functions'

src = Image.create(32, 32)
src.fill(0xFF333333)

img = Image.create(512, 512)
img.fill(0xFFFFFFFF)

ites = (512 / 16)

ites.times do |xy|
  img.alpha_blit(src, xy * 16, xy * 16, 0, 0, src.width, src.height, 128)
  img.alpha_blit(src, xy * 16 + 48, xy * 16, 0, 0, src.width, src.height, 255)
end

img.save_file("alpha_blit_test.png")


img = Image.create(512, 512)
img.fill(0xFFFFFFFF)
ites = (512 / 16)

ites.times do |xy|
  img.rb_alpha_blit(src, xy * 16, xy * 16, 0, 0, src.width, src.height, 128)
  img.rb_alpha_blit(src, xy * 16 + 48, xy * 16, 0, 0, src.width, src.height, 255)
end

img.save_file("alpha_blit_test_rb.png")
