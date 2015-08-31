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
          beta = (a2 * alpha) >> 8
          c  = (beta > a1 ? beta : a1) << 24
          c |= [[r1 + (((r2 - r1) * beta) >> 8), 255].min, 0].max << 16
          c |= [[g1 + (((g2 - g1) * beta) >> 8), 255].min, 0].max <<  8
          c |= [[b1 + (((b2 - b1) * beta) >> 8), 255].min, 0].max <<  0
          set_pixel(x + ax, y + ay, c)
        end
      end
      self
    end
  end
end
