require_relative 'common'

src1 = Minil::Image.create(64, 128)
src1.fill(0xFF336699)

src2 = Minil::Image.create(128, 64)
src2.fill(0xFF996633)

img = Minil::Image.create(256, 320)
img.blit(src1, 0, 0, 0, 0, 64, 64)
img.blit(src2, -32, -32, 0, 0, 64, 64)

img.blit(src1, img.width - 64, 0, 0, 0, 64, 64)
img.blit(src2, img.width - 32, -32, 0, 0, 64, 64)

img.blit(src1, img.width - 64, img.height - 64, 0, 0, 64, 64)
img.blit(src2, img.width - 32, img.height - 32, 0, 0, 64, 64)

img.blit(src1, 0,   img.height - 64, 0, 0, 64, 64)
img.blit(src2, -32, img.height - 32, 0, 0, 64, 64)

img.blit(src1, 128, 64, 0, 0, 64, 64)
img.blit(src2, 144, 80, 0, 0, 32, 32)
img.blit(src2, 64, 64, 0, 0, 64, 64)
img.blit(src1, 80, 80, 0, 0, 32, 32)

img.blit(src2, img.width - 16, 64, 16, 16, 32, 32)
img.blit(src2, -16, 64, 16, 16, 32, 32)

img.blit(src2, 64, -16, 16, 16, 32, 32)
img.blit(src2, 64, img.height - 16, 16, 16, 32, 32)

img.blit(src1, -64, 0, 0, 0, 128, 128)

save_image(img, "image_blit-oversize.png")
