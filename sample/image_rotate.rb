$:.unshift(File.expand_path("../lib", File.dirname(__FILE__)))
require_relative 'common'

img = Minil::Image.create(32, 32)
img.fill_rect(0, 0, img.width, img.height, 0xFF000000)
img.fill_rect(0, 0, 2, img.height, 0xFF330000)
img.fill_rect(0, 0, img.width, 2, 0xFF003300)
img.fill_rect(0, 0, 2, 2, 0xFF000033)

img2 = Minil::Image.create(64, 32)
img2.fill_rect(0, 0, img2.width, img2.height, 0xFF000000)
img2.fill_rect(0, 0, 2, img2.height, 0xFF330000)
img2.fill_rect(0, 0, img2.width, 2, 0xFF003300)
img2.fill_rect(0, 0, 2, 2, 0xFF000033)

save_image(img, "sq_rotate_none.png")
save_image(img.rotate_90_cw, "sq_rotate_90_cw.png")
save_image(img.rotate_90_ccw, "sq_rotate_90_ccw.png")
save_image(img.rotate_180, "sq_rotate_180_ccw.png")
save_image(img.pinwheel, "pinwheel.png")

save_image(img2, "rct_rotate_none.png")
save_image(img2.rotate_90_cw, "rct_rotate_90_cw.png")
save_image(img2.rotate_90_ccw, "rct_rotate_90_ccw.png")
save_image(img2.rotate_180, "rct_rotate_180_ccw.png")
