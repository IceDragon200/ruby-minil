require 'minil_ext'

module Minil
  class Image
    private def lerp_pixel(c1, c2, t)
      a1 = (c1 >> 24) & 0xFF
      r1 = (c1 >> 16) & 0xFF
      g1 = (c1 >>  8) & 0xFF
      b1 = (c1 >>  0) & 0xFF
      a2 = (c2 >> 24) & 0xFF
      r2 = (c2 >> 16) & 0xFF
      g2 = (c2 >>  8) & 0xFF
      b2 = (c2 >>  0) & 0xFF

      d = (t * 255).floor

      a = a1 + (a2 - a1) * d / 255
      r = r1 + (r2 - r1) * d / 255
      g = g1 + (g2 - g1) * d / 255
      b = b1 + (b2 - b1) * d / 255

      a << 24 | r << 16 | g << 8 | b
    end

    # Args:
    # * `other_image` [Minil::Image]
    # * `delta` [Float]
    def lerp(other_image, delta)
      dest = Minil::Image.create(width, height)
      height.times do |y|
        width.times do |x|
          a = get_pixel(x, y)
          b = other_image.get_pixel(x, y)
          dest.set_pixel(x, y, lerp_pixel(a, b, delta))
        end
      end
      dest
    end

    # @param [Integer] x
    # @param [Integer] y
    # @param [Integer] w
    # @param [Integer] h
    # @return [Array<Integer>]
    def fit_rect(x, y, w, h)
      #if w < 0 || h < 0
      #  return x, y, 0, 0
      #end

      if w < 0
        x += w
        w = -w
      end

      if h < 0
        y += h
        h = -h
      end

      if x < 0
        w += x
        x = 0
      end

      if y < 0
        h += y
        y = 0
      end

      x2 = x + w
      y2 = y + h

      w -= x2 - width if x2 >= width
      h -= y2 - height if y2 >= height

      return x, y, w, h
    end

    # @return [Minil::Rect] rect representing the size of the image
    def rect
      Minil::Rect.new(0, 0, width, height)
    end

    # @param [Integer, Array<Integer>[4]] color
    def fill(color)
      fill_rect(0, 0, width, height, color)
    end

    # @param [Minil::Rect] rect
    # @param [Integer, Array<Integer>[4]] color
    def fill_rect_r(rect, color)
      x, y, w, h = *rect
      fill_rect(x, y, w, h, color)
    end

    def clear_rect(x, y, w, h)
      fill_rect(x, y, w, h, 0x00000000)
    end

    def clear_rect_r(rect)
      clear_rect(*rect)
    end

    def clear(color = 0x00000000)
      fill(color)
    end

    def gradient_fill_rect(x, y, w, h, c1, c2, v = false)
      a1 = (c1 >> 24) & 0xFF
      r1 = (c1 >> 16) & 0xFF
      g1 = (c1 >>  8) & 0xFF
      b1 = (c1 >>  0) & 0xFF
      a2 = (c2 >> 24) & 0xFF
      r2 = (c2 >> 16) & 0xFF
      g2 = (c2 >>  8) & 0xFF
      b2 = (c2 >>  0) & 0xFF

      ad = a2 - a1
      rd = r2 - r1
      gd = g2 - g1
      bd = b2 - b1

      if v
        m = h
        h.times do |n|
          c  = [[a1 + ad * n / m, 255].min, 0].max << 24
          c |= [[r1 + rd * n / m, 255].min, 0].max << 16
          c |= [[g1 + gd * n / m, 255].min, 0].max <<  8
          c |= [[b1 + bd * n / m, 255].min, 0].max <<  0
          fill_rect(x, y + n, w, 1, c)
        end
      else
        m = w
        w.times do |n|
          c  = [[a1 + ad * n / m, 255].min, 0].max << 24
          c |= [[r1 + rd * n / m, 255].min, 0].max << 16
          c |= [[g1 + gd * n / m, 255].min, 0].max <<  8
          c |= [[b1 + bd * n / m, 255].min, 0].max <<  0
          fill_rect(x + n, y, 1, h, c)
        end
      end
      self
    end

    def gradient_fill_rect_r(rect, c1, c2, v = false)
      x, y, w, h = *rect
      gradient_fill_rect(x, y, w, h, c1, c2, v)
    end

    def blit_r(img, x, y, rect)
      blit(img, x, y, *rect)
    end

    def blit_fill(img, x, y, dw, dh, sx, sy, sw, sh)
      w_segs, w_rem = *dw.divmod(sw)
      h_segs, h_rem = *dh.divmod(sh)
      w_segs.times do |xi|
        dx = x + xi * sw
        h_segs.times do |yi|
          blit img, dx, y + yi * sh, sx, sy, sw, sh
        end
        blit dx, y + h_segs * sh, img, sx, sy, sw, h_rem
      end
      dx = x + w_segs * sw
      h_segs.times do |yi|
        blit dx, y + yi * sh, img, sx, sy, w_rem, sh
      end
      blit dx, y + h_segs * sh, img, sx, sy, w_rem, h_rem
      self
    end

    def blit_fill_rr(img, dest_rect, src_rect)
      x, y, dw, dh = *dest_rect
      sx, sy, sw, sh = *src_rect
      blit_fill(img, x, y, dw, dh, sx, sy, sw, sh)
    end

    alias :__c_alpha_blit :alpha_blit

    def alpha_blit(img, ax, ay, sx, sy, w, h, alpha = 255)
      __c_alpha_blit(img, ax, ay, sx, sy, w, h, alpha)
    end

    def alpha_blit_r(img, x, y, rect, alpha = 255)
      sx, sy, w, h = *rect
      alpha_blit(img, x, y, sx, sy, w, h, alpha)
    end

    def alpha_blit_fill(img, x, y, dw, dh, sx, sy, sw, sh, alpha = 255)
      w_segs, w_rem = *dw.divmod(sw)
      h_segs, h_rem = *dh.divmod(sh)
      w_segs.times do |xi|
        dx = x + xi * sw
        h_segs.times do |yi|
          alpha_blit img, dx, y + yi * sh, sx, sy, sw, sh, alpha
        end
        alpha_blit dx, y + h_segs * sh, img, sx, sy, sw, h_rem, alpha
      end
      dx = x + w_segs * sw
      h_segs.times do |yi|
        alpha_blit dx, y + yi * sh, img, sx, sy, w_rem, sh, alpha
      end
      alpha_blit dx, y + h_segs * sh, img, sx, sy, w_rem, h_rem, alpha
      self
    end

    def alpha_blit_fill_rr(img, dest_rect, src_rect, alpha = 255)
      x, y, dw, dh = *dest_rect
      sx, sy, sw, sh = *src_rect
      blit_fill(img, x, y, dw, dh, sx, sy, sw, sh, alpha)
    end

    def subimage(x, y, w, h)
      image = self.class.new
      image.create(w, h)
      image.blit(self, 0, 0, x, y, w, h)
      image
    end

    def subimage_r(rect)
      subimage(*rect)
    end

    # Blits the (img) to this image, but filters pixels by a mask (red channel)
    #
    # @param [Minil::Image] img
    # @param [Minil::Image] mask
    # @param [Integer] x
    # @param [Integer] y
    # @param [Integer] sx
    # @param [Integer] sy
    # @param [Integer] sw
    # @param [Integer] sh
    # @return [self]
    def mask_blit(img, mask, x, y, sx, sy, sw, sh)
      if img.width != mask.width || img.height != mask.width
        raise ArgumentError, "Mask must be the same size as provided image"
      end

      sx, sy, sw, sh = img.fit_rect(sx, sy, sw, sh)
      x, y, sw, sh = fit_rect(x, y, sw, sh)

      sh.times do |row|
        sw.times do |col|
          px, py = sx + col, sy + row
          mask_pixel = mask.get_pixel(px, py)
          pixel = img.get_pixel(px, py)

          mask_alpha = (mask_pixel >> 16) & 0xFF
          alpha = (pixel >> 24) & 0xFF

          new_alpha = (alpha * mask_alpha / 255)
          new_pixel = (pixel & 0x00FFFFFF) | (new_alpha << 24)
          set_pixel x + col, y + row, new_pixel
        end
      end

      self
    end

    private def blend_colorf(r, g, b, a, r2, g2, b2, a2, &blend)
      return (blend.call(r / 255.0, r2 / 255.0) * 255).to_i,
        (blend.call(g / 255.0, g2 / 255.0) * 255).to_i,
        (blend.call(b / 255.0, b2 / 255.0) * 255).to_i,
        a * a2 / 255
    end

    def blend_hard_light_fill_rect(x, y, w, h, color)
      cr, cg, cb, ca = Minil::Color.cast_to_channels(color)
      h.times do |row|
        w.times do |col|
          dx, dy = x + col, y + row
          pixel = get_pixel(dx, dy)
          r, g, b, a = Minil::Color.decode(pixel)
          next if a == 0
          c =
            Minil::Color.encode(*blend_colorf(r, g, b, a, cr, cg, cb, ca) do |n, n2|
              if n2 <= 0.5
                2 * (n * n2)
              else
                1 - 2 * (1 - n) * (1 - n2)
              end
            end)
          set_pixel(dx, dy, c)
        end
      end
    end

    def blend_multiply_fill_rect(x, y, w, h, color)
      cr, cg, cb, ca = Minil::Color.cast_to_channels(color)
      h.times do |row|
        w.times do |col|
          dx, dy = x + col, y + row
          pixel = get_pixel(dx, dy)
          r, g, b, a = Minil::Color.decode(pixel)
          next if a == 0
          c = Minil::Color.encode(
            r * cr / 255,
            g * cg / 255,
            b * cb / 255,
            a * ca / 255
          )
          set_pixel(dx, dy, c)
        end
      end
    end

    def blend_overlay_fill_rect(x, y, w, h, color)
      cr, cg, cb, ca = Minil::Color.cast_to_channels(color)
      h.times do |row|
        w.times do |col|
          dx, dy = x + col, y + row
          pixel = get_pixel(dx, dy)
          r, g, b, a = Minil::Color.decode(pixel)
          next if a == 0
          c =
            Minil::Color.encode(*blend_colorf(r, g, b, a, cr, cg, cb, ca) do |n, n2|
              if n <= 0.5
                2 * (n * n2)
              else
                1 - 2 * (1 - n) * (1 - n2)
              end
            end)
          set_pixel(dx, dy, c)
        end
      end
    end

    def blend_blit_r(blend_mode, src_image, x, y, src_rect, opacity)
      w = src_rect.w
      h = src_rect.h
      h.times do |row|
        w.times do |col|
          color = src_image.get_pixel(src_rect.x + col, src_rect.y + row)
          cr, cg, cb, cca = Minil::Color.decode(color)
          #cca = cca * opacity / 255
          # premultiplied alpha
          ca = 255
          dx, dy = x + col, y + row
          old_pixel = self.get_pixel(dx, dy)
          r, g, b, a = Minil::Color.decode(old_pixel)
          next if a == 0

          c =
            if cca > 0 then
              case blend_mode
              when :multiply
                Minil::Color.encode(
                  r * cr / 255,
                  g * cg / 255,
                  b * cb / 255,
                  a * ca / 255
                )
              when :hard_light
                Minil::Color.encode(*blend_colorf(r, g, b, a, cr, cg, cb, ca) do |n, n2|
                  if n2 <= 0.5
                    2 * (n * n2)
                  else
                    1 - 2 * (1 - n) * (1 - n2)
                  end
                end)
              when :overlay
                Minil::Color.encode(*blend_colorf(r, g, b, a, cr, cg, cb, ca) do |n, n2|
                  if n <= 0.5
                    2 * (n * n2)
                  else
                    1 - 2 * (1 - n) * (1 - n2)
                  end
                end)
              end
            else
              old_pixel
            end

          self.set_pixel(dx, dy, c)
        end
      end
    end

    def mirror(vertical = false)
      dest = self.class.create(width, height)

      if vertical
        height.times do |y|
          y2 = height - y - 1
          width.times do |x|
            dest.set_pixel(x, y, get_pixel(x, y2))
          end
        end
      else
        width.times do |x|
          x2 = width - x - 1
          height.times do |y|
            dest.set_pixel(x, y, get_pixel(x2, y))
          end
        end
      end
      dest
    end

    def rotate_90_cw
      dest = self.class.create(height, width)

      height.times do |y|
        width.times do |x|
          dest.set_pixel(dest.width - y - 1, x, get_pixel(x, y))
        end
      end

      dest
    end

    def rotate_90_ccw
      dest = self.class.create(height, width)

      height.times do |y|
        width.times do |x|
          dest.set_pixel(y, dest.height - x - 1, get_pixel(x, y))
        end
      end

      dest
    end

    def rotate_180
      dest = self.class.create(width, height)

      height.times do |y|
        width.times do |x|
          dest.set_pixel(dest.width - x - 1, dest.height - y - 1, get_pixel(x, y))
        end
      end

      dest
    end

    def pinwheel
      img = self.class.create(width * 2, height * 2)
      img.blit(self, 0, 0, 0, 0, width, height)
      img.blit(rotate_90_cw, width, 0, 0, 0, width, height)
      img.blit(rotate_180, width, height, 0, 0, width, height)
      img.blit(rotate_90_ccw, 0, height, 0, 0, width, height)
      img
    end

    def skew(x, y)
      ox = [x, 0].min.abs
      oy = [y, 0].min.abs
      result = self.class.create(width + x.abs, height + y.abs)
      if x == 0 || y != 0
        # vertical skew
        width.times do |i|
          result.blit(self, i, oy + (y * i / width), i, 0, 1, height)
        end
      elsif y == 0 || x != 0
        # horizontal skew
        height.times do |i|
          result.blit(self, ox + (x * i / height), i, 0, i, width, 1)
        end
      else
        height.times do |i|
          width.times do |j|
            result.set_pixel(ox + j + (x * j / width),
                             oy + i + (y * i / height),
                             get_pixel(i, j))
          end
        end
      end
      result
    end

    def replace_color(src_color, new_color)
      height.times do |y|
        width.times do |x|
          set_pixel(x, y, new_color) if get_pixel(x, y) == src_color
        end
      end
      self
    end

    def replace_color_map(hash)
      height.times do |y|
        width.times do |x|
          new_color = hash[get_pixel(x, y)]
          set_pixel(x, y, new_color) if new_color
        end
      end
      self
    end

    def palette
      result = []
      height.times do |y|
        width.times do |x|
          value = get_pixel(x, y)
          result << value unless result.include?(value)
        end
      end
      result
    end

    def reduce(depth)
      (height / depth).times do |y|
        (width / depth).times do |x|
          value = get_pixel(x * depth, y * depth)
          depth.times do |yp|
            depth.times do |xp|
              set_pixel(x * depth + xp, y * depth + yp, value)
            end
          end
        end
      end
      self
    end

    def resize(new_width, new_height)
      img = self.class.create(new_width, new_height)
      img.height.times do |dy|
        img.width.times do |dx|
          value = get_pixel(self.width * dx / img.width, self.height * dy / img.height)

          img.set_pixel(dx, dy, value)
        end
      end
      img
    end

    def upscale(xs, ys = xs)
      img = self.class.create(width * xs, height * ys)
      height.times do |y|
        width.times do |x|
          value = get_pixel(x, y)
          ys.times do |yi|
            xs.times do |xi|
              img.set_pixel(x * xs + xi, y * ys + yi, value)
            end
          end
        end
      end
      img
    end

    def downscale(xs, ys = xs)
      img = self.class.create(width / xs, height / ys)
      img.height.times do |y|
        img.width.times do |x|
          value = get_pixel(x*xs, y*ys)
          img.set_pixel(x, y, value)
        end
      end
      img
    end

    def scale(xs, ys = xs)
      if xs < 1 && ys < 1
        downscale((xs / 1.0).to_i, (ys / 1.0).to_i)
      elsif xs >= 1 && ys >= 1
        upscale(xs, ys)
      else
        raise ArgumentError, "Mismatch scales, you cannot downscale and upscale at the same time."
      end
    end

    def channel_select(channel_name)
      channel_name = channel_name.to_s
      height.times do |y|
        width.times do |x|
          value = get_pixel(x, y)
          a = (value & 0xFF000000) >> 24
          case channel_name
          when "rgb"
            value = (value & 0x00FFFFFF)
            value = (a << 24) | value
          when "r"
            value = (value & 0x00FF0000) >> 16
            value = (a << 24) | (value << 16) | (value << 8) | (value)
          when "g"
            value = (value & 0x0000FF00) >> 8
            value = (a << 24) | (value << 16) | (value << 8) | (value)
          when "b"
            value = (value & 0x000000FF)
            value = (a << 24) | (value << 16) | (value << 8) | (value)
          when "a"
            value = (value & 0xFF000000) >> 24
            value = (a << 24) | (value << 16) | (value << 8) | (value)
          end
          set_pixel(x, y, value)
        end
      end
      self
    end

    def to_alpha_mask
      img = self.class.create(width, height)
      height.times do |y|
        width.times do |x|
          value = get_pixel(x, y)
          value = (value & 0xFF000000) >> 24
          value = (255 << 24) | (value << 16) | (value << 8) | (value)
          img.set_pixel(x, y, value)
        end
      end
      img
    end

    def channel_as_alpha_mask(channel_name = 'r')
      channel_name = channel_name.to_s
      height.times do |y|
        width.times do |x|
          value = get_pixel(x, y)
          case channel_name
          when 'r'
            value = (value & 0x00FF0000) >> 16
          when 'g'
            value = (value & 0x0000FF00) >> 8
          when 'b'
            value = (value & 0x000000FF)
          when 'a'
            value = (value & 0xFF000000) >> 24
          end
          value = 255 - value
          value = (value << 24) | (0 << 16) | (0 << 8) | (0)
          set_pixel(x, y, value)
        end
      end
      self
    end

    def invert
      height.times do |y|
        width.times do |x|
          value = get_pixel(x, y)
          r = (value & 0x00FF0000) >> 16
          g = (value & 0x0000FF00) >> 8
          b = (value & 0x000000FF)
          a = (value & 0xFF000000) >> 24
          value = (a << 24) | ((255-r) << 16) | ((255-g) << 8) | (255-b)
          set_pixel(x, y, value)
        end
      end
      self
    end

    def self.create(*args, &block)
      Image.new.tap { |i| i.create(*args, &block) }
    end

    def self.load_file(*args, &block)
      Image.new.tap { |i| i.load_file(*args, &block) }
    end
  end
end
