require_relative '../minil'

class Image

  def fill(color)
    height.times do |y|
      width.times do |x|
        set_pixel(x, y, color)
      end
    end
    self
  end

  def fill_rect(x, y, w, h, color)
    h.times do |ay|
      w.times do |ax|
        set_pixel(x + ax, y + ay, color)
      end
    end
    self
  end

  def gradient_fill_rect(x, y, w, h, c1, c2, v=false)
    a1 = (c1 >> 24) & 0xFF
    r1 = (c1 >> 16) & 0xFF
    g1 = (c1 >>  8) & 0xFF
    b1 = (c1 >>  0) & 0xFF
    a2 = (c2 >> 24) & 0xFF
    r2 = (c2 >> 16) & 0xFF
    g2 = (c2 >>  8) & 0xFF
    b2 = (c2 >>  0) & 0xFF
    if v
      h.times do |ay|
        n, m = ay, h
        c  = [[a1 + ((a2 - a1) * n) / m, 255].min, 0].max << 24
        c |= [[r1 + ((r2 - r1) * n) / m, 255].min, 0].max << 16
        c |= [[g1 + ((g2 - g1) * n) / m, 255].min, 0].max <<  8
        c |= [[b1 + ((b2 - b1) * n) / m, 255].min, 0].max <<  0
        fill_rect(x, y + ay, w, 1, c)
      end
    else
      w.times do |ax|
        n, m = ax, w
        c  = [[a1 + ((a2 - a1) * n) / m, 255].min, 0].max << 24
        c |= [[r1 + ((r2 - r1) * n) / m, 255].min, 0].max << 16
        c |= [[g1 + ((g2 - g1) * n) / m, 255].min, 0].max <<  8
        c |= [[b1 + ((b2 - b1) * n) / m, 255].min, 0].max <<  0
        fill_rect(x + ax, y, 1, h, c)
      end
    end
    self
  end

  def alpha_blit(ax, ay, img, src_rect, alpha=255)
    sx, sy, w, h = *src_rect
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

  def blit(ax, ay, img, src_rect)
    sx, sy, w, h = *src_rect
    h.times do |y|
      w.times do |x|
        set_pixel(x + ax, y + ay, img.get_pixel(x + sx, y + sy))
      end
    end
    self
  end

  def mirror(v=false)
    src = dup
    if v
      height.times do |y|
        y2 = height - y - 1
        width.times do |x|
          set_pixel(x, y, src.get_pixel(x, y2))
        end
      end
    else
      width.times do |x|
        x2 = width - x - 1
        height.times do |y|
          set_pixel(x, y, src.get_pixel(x2, y))
        end
      end
    end
    self
  end

  def replace_color(src_color, new_color)
    h.times do |y|
      w.times do |x|
        set_pixel(x, y, new_color) if get_pixel(x, y) == src_color
      end
    end
  end

end