$:.unshift(File.expand_path("../lib", File.dirname(__FILE__)))
require 'minil/functions'
require "fileutils"

FileUtils.rm_rf(Dir.glob("test_img*.{png,bmp,tga}"))

image = Image.new
p image
w, h = 128, 128
p image.create(w, h)
#image.load_file("buttons_32x32.png")
#p image[0, 0]
#image[0, 0] = 0xFF22FFFF
#fill_gradient(image, image.width, image.height, 0x00000000, 0xFFFFFFFF)
image.fill(0xFF00AF00)
image.fill_rect(w/2, h/2, w/2, h/2, 0xFF0000AF)
image.gradient_fill_rect(0, 0, w/2, h/2, 0xFFAF0000, 0xFFAFAF00, false)
image.reduce(4)
image.alpha_blit(image, 0, w/2, 0, 0, w/4, h/2)
image.mirror
image.mirror(true)
uimage = image.upscale(2, 2)
dimage = image.downscale(2, 2)
#p "%x" % image[0, 0]
#p image.blob
image.save_file("test_img.bmp")
image.save_file("test_img.png")
image.save_file("test_img.tga")
uimage.save_file("test_img_u2x.bmp")
uimage.save_file("test_img_u2x.png")
uimage.save_file("test_img_u2x.tga")
dimage.save_file("test_img_d2x.bmp")
dimage.save_file("test_img_d2x.png")
dimage.save_file("test_img_d2x.tga")
