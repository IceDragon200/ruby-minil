require 'minil'
require 'minil/rect'

module Minil
  class Image
    def compare(other)
      return false if other.width != width || other.height != height
      height.times do |y|
        width.times do |x|
          return false unless self.get_pixel(x, y) == other.get_pixel(x, y)
        end
      end
      true
    end

    def compare_ratio(other)
      return false if other.width != width || other.height != height
      matches = 0
      height.times do |y|
        width.times do |x|
          matches += 1 if self.get_pixel(x, y) == other.get_pixel(x, y)
        end
      end
      matches.to_f / (width * height)
    end

    def compare_rect(other, x, y, sx, sy, w, h)
      h.times do |iy|
        w.times do |ix|
          return false unless self.get_pixel(x + ix, y + iy) == other.get_pixel(sx + ix, sy + iy)
        end
      end
      true
    end

    def compare_rect_ratio(other, x, y, sx, sy, w, h)
      matches = 0
      h.times do |iy|
        w.times do |ix|
          matches += 1 if self.get_pixel(x + ix, y + iy) == other.get_pixel(sx + ix, sy + iy)
        end
      end
      return 0.0 if w <= 0 || h <= 0

      matches.to_f / (w * h)
    end
  end
end
