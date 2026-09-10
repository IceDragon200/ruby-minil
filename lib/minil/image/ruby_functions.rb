module Minil
  class Image
    def rb_fill(color)
      height.times do |y|
        width.times do |x|
          set_pixel(x, y, color)
        end
      end
      self
    end

    def rb_fill_rect(x, y, w, h, color)
      h.times do |ay|
        w.times do |ax|
          set_pixel(x + ax, y + ay, color)
        end
      end
      self
    end

    def rb_blit(img, ax, ay, sx, sy, w, h)
      h.times do |y|
        w.times do |x|
          set_pixel(x + ax, y + ay, img.get_pixel(x + sx, y + sy))
        end
      end
      self
    end

    def rb_alpha_blit(img, ax, ay, sx, sy, w, h, alpha = 255)
      alpha = [[alpha, 0].max, 255].min
      h.times do |y|
        w.times do |x|
          c1 = get_pixel(x + ax, y + ay)
          c2 = img.get_pixel(x + sx, y + sy)
          a1 = (c1 >> 24) & 0xFF
          r1 = (c1 >> 16) & 0xFF
          g1 = (c1 >>  8) & 0xFF
          b1 = (c1 >>  0) & 0xFF
          a2 = (c2 >> 24) & 0xFF
          r2 = (c2 >> 16) & 0xFF
          g2 = (c2 >>  8) & 0xFF
          b2 = (c2 >>  0) & 0xFF
          src_alpha = (a2 * alpha + 127) / 255
          inverse_alpha = 255 - src_alpha
          out_alpha_numerator = src_alpha * 255 + a1 * inverse_alpha
          if out_alpha_numerator == 0
            set_pixel(x + ax, y + ay, 0)
            next
          end

          r = (r2 * src_alpha * 255 + r1 * a1 * inverse_alpha + out_alpha_numerator / 2) / out_alpha_numerator
          g = (g2 * src_alpha * 255 + g1 * a1 * inverse_alpha + out_alpha_numerator / 2) / out_alpha_numerator
          b = (b2 * src_alpha * 255 + b1 * a1 * inverse_alpha + out_alpha_numerator / 2) / out_alpha_numerator
          a = (out_alpha_numerator + 127) / 255
          c = a << 24 | r << 16 | g << 8 | b
          set_pixel(x + ax, y + ay, c)
        end
      end
      self
    end
  end
end
