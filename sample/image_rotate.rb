$:.unshift(File.expand_path("../lib", File.dirname(__FILE__)))
require 'minil/functions'

img = Image.create(32, 32)
img.fill_rect(0, 0, img.width, img.height, 0xFF000000)
img.fill_rect(0, 0, 2, img.height, 0xFF330000)
img.fill_rect(0, 0, img.width, 2, 0xFF003300)
img.fill_rect(0, 0, 2, 2, 0xFF000033)

img2 = Image.create(64, 32)
img2.fill_rect(0, 0, img2.width, img2.height, 0xFF000000)
img2.fill_rect(0, 0, 2, img2.height, 0xFF330000)
img2.fill_rect(0, 0, img2.width, 2, 0xFF003300)
img2.fill_rect(0, 0, 2, 2, 0xFF000033)

img.save_file("sq_rotate_none.png")
img.rotate_90_cw.save_file("sq_rotate_90_cw.png")
img.rotate_90_ccw.save_file("sq_rotate_90_ccw.png")
img.rotate_180.save_file("sq_rotate_180_ccw.png")
img.pinwheel.save_file("pinwheel.png")

img2.save_file("rct_rotate_none.png")
img2.rotate_90_cw.save_file("rct_rotate_90_cw.png")
img2.rotate_90_ccw.save_file("rct_rotate_90_ccw.png")
img2.rotate_180.save_file("rct_rotate_180_ccw.png")
