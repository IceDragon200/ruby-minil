require_relative 'common'

mask = Minil::Image.create(32, 32)
mask.fill_rect(0, 0, mask.width, mask.height, 0xFFFFFFFF)
mask.fill_rect(1, 1, mask.width - 2, mask.height - 2, 0x00000000)

img = Minil::Image.create(32, 32)
img.fill(0xFF336699)
img.mask_blit(img, mask, 0, 0, 0, 0, mask.width, mask.height)

save_image(mask, "image_mask_blit-mask.png")
save_image(img, "image_mask_blit-result.png")
