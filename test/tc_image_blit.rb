$:.unshift(File.expand_path("../lib", File.dirname(__FILE__)))
require 'minil/functions'

src = Image.create(32, 32)
src.fill(0xFF333333)

img = Image.create(512, 512)
img.fill(0xFFFFFFFF)
ites = (512 / 32)

ites.times do |xy|
  img.blit(src, xy * 32, xy * 32, 0, 0, src.width, src.height)
end

img.save_file("blit_test.png")


img = Image.create(512, 512)
img.fill(0xFFFFFFFF)
ites = (512 / 32)

ites.times do |xy|
  img.rb_blit(src, xy * 32, xy * 32, 0, 0, src.width, src.height)
end

#File.open("blit_test_rb.bin", "wb") { |f| f.write(img.blob) }
img.save_file("blit_test_rb.png")
