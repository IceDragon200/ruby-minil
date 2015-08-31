require_relative 'common'

src = Minil::Image.create(32, 32)
src.fill(0xFF333333)

img = Minil::Image.create(512, 512)
img.fill(0xFFFFFFFF)
ites = (512 / 32)

ites.times do |xy|
  img.blit(src, xy * 32, xy * 32, 0, 0, src.width, src.height)
end

save_image(img, "blit_test.png")


img = Minil::Image.create(512, 512)
img.fill(0xFFFFFFFF)
ites = (512 / 32)

ites.times do |xy|
  img.rb_blit(src, xy * 32, xy * 32, 0, 0, src.width, src.height)
end

#File.open("blit_test_rb.bin", "wb") { |f| f.write(img.blob) }
save_image(img, "blit_test_rb.png")
