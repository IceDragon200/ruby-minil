require_relative 'common'

src = Minil::Image.create(64, 64)
src.fill(0xFF33FF33)

img = Minil::Image.create(128, 128)
img.blit(src, -64, -64, 32, 0, 128, 64)

save_image(img, "blit_test_over.png")
