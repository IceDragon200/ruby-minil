require_relative 'common'

src = Minil::Image.create(512, 512)
src_rb = Minil::Image.create(512, 512)

src.fill(0xFF000000)
src_rb.fill(0xFF000000)

[0xFF000000, 0xFFFF0000, 0xFF00FF00, 0xFF0000FF, 0xFFFFFFFF,
 0x7F000000, 0x7FFF0000, 0x7F00FF00, 0x7F0000FF, 0x7FFFFFFF].each_with_index do |c, i|
  src.fill_rect(i * 32, i * 32, 32, 32, c)
  src_rb.rb_fill_rect(i * 32, i * 32, 32, 32, c)
end

save_image(src, "test_img_fill_rect.png")
save_image(src_rb, "test_img_fill_rect_rb.png")
