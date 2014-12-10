require 'minil/color'

class Float
  def to_color
    Minil::Color.rgba((self*255).to_i, (self*255).to_i, (self*255).to_i, 255)
  end

  def to_normalized_color
    Minil::NormalizedColor.new(self, self, self, 1.0)
  end
end

class Integer
  def to_color
    Minil::Color.rgba(self, self, self, 255)
  end

  def to_normalized_color
    Minil::NormalizedColor.new(self/255.0, self/255.0, self/255.0, 1.0)
  end
end

module Minil
  class Color
    def to_color
      Color.rgba(r,g,b,a)
    end

    def to_normalized_color
      NormalizedColor.new(r/255.0, g/255.0, b/255.0, a/255.0)
    end
  end

  class NormalizedColor
    attr_reader :r
    attr_reader :g
    attr_reader :b
    attr_reader :a

    def initialize(r, g, b, a)
      self.r = r
      self.g = g
      self.b = b
      self.a = a
    end

    def r=(r)
      @r = r.to_f
    end

    def g=(g)
      @g = g.to_f
    end

    def b=(b)
      @b = b.to_f
    end

    def a=(a)
      @a = a.to_f
    end

    def clamp_r
      [[r, 0].max, 1].min
    end

    def clamp_g
      [[g, 0].max, 1].min
    end

    def clamp_b
      [[b, 0].max, 1].min
    end

    def clamp_a
      [[a, 0].max, 1].min
    end

    def to_color
      Color.rgba((clamp_r*255).to_i,(clamp_g*255).to_i,(clamp_b*255).to_i,(clamp_a*255).to_i)
    end

    def to_normalized_color
      NormalizedColor.new(r,g,b,a)
    end

    def rgb
      NormalizedColor.new(r,g,b,1.0)
    end

    def sum
      (r + g + b) * a
    end

    def lum
      (0.3 * r + 0.59 * g + 0.11 * b) * a
    end

    def saturation
      ([r, g, b].max - [r, g, b].min) * a
    end

    def clamped
      NormalizedColor.new(clamp_r, clamp_g, clamp_b, clamp_a)
    end

    def *(other)
      other = other.to_normalized_color
      NormalizedColor.new(r * other.r, g * other.g, b * other.b, a)
    end

    def +(other)
      other = other.to_normalized_color
      NormalizedColor.new(r + other.r, g + other.g, b + other.b, a)
    end

    def -(other)
      other = other.to_normalized_color
      NormalizedColor.new(r - other.r, g - other.g, b - other.b, a)
    end

    def /(other)
      other = other.to_normalized_color
      NormalizedColor.new(r / other.r, g / other.g, b / other.b, a)
    end

    def -@
      NormalizedColor.new(1 - r, 1 - g, 1 - b, a)
    end

    def +@
      NormalizedColor.new(r, g, b, a)
    end
  end

  module ColorBlender
    def self.ncolor(symbol)
      newname = "normal_#{symbol}"

      alias_method(newname, symbol)

      define_method(symbol) do |*args, &block|
        send(newname, *(normalize(*args)), &block)
      end
      symbol
    end

    def self.sncolor(symbol)
      newname = "normal_#{symbol}"

      alias_method(newname, symbol)

      define_method(symbol) do |color, &block|
        send(newname, snormalize(color), &block)
      end
      symbol
    end

    private def singularize(*args)
      if args.size <= 1
        return args.first
      else
        return args
      end
    end

    private def new_color(r, g, b, a)
      NormalizedColor.new(r, g, b, a)
    end

    def normalize(*colors)
      colors.map(&:to_normalized_color)
    end

    def snormalize(*colors)
      singularize(*normalize(*colors))
    end

    def _calc_alpha(src, dst, a)
      ((dst) - (dst) + ((src) - (dst)) * (a))
    end

    ncolor def min(*colors)
      colors.min_by(&:sum)
    end

    ncolor def max(*colors)
      colors.max_by(&:sum)
    end

    ncolor def darkest(*colors)
      colors.min_by(&:lum)
    end

    ncolor def lightest(*colors)
      colors.max_by(&:lum)
    end

    sncolor def invert(color)
      new_color(1 - color.r, 1 - color.g, 1 - color.b, color.a).clamped
    end

    def new_lum(color, l)
      color = snormalize(color)
      d = (l - color.lum) * color.a
      new_color(color.r + d, color.g + d, color.b + d, color.a).clamped
    end

    def _blend_color(col1, col2)
      new_color(yield(col1.r, col2.r),
                yield(col1.g, col2.g),
                yield(col1.b, col2.b),
                col1.a).clamped
    end

    # blending
    ncolor def blend_alpha(col1, col2)
      a = col1.a
      _blend_color(col1, col2) do |n, n2|
        (n - n + (n2 - n) * a)
      end
    end

    ncolor def blend_add(col1, col2)
      _blend_color(col1, col2) do |n, n2|
        [n + n2, 1.0].min
      end
    end

    ncolor def blend_subtract(col1, col2)
      _blend_color(col1, col2) do |n, n2|
        [n - n2, 0.0].max
      end
    end

    ncolor def blend_screen(col1, col2)
      _blend_color(col1, col2) do |n, n2|
        1.0 - (1.0 - n) * (1.0 - n2)
      end
    end

    ncolor def blend_multiply(col1, col2)
      _blend_color(col1, col2) do |n, n2|
        (n * n2)
      end
    end

    ncolor def blend_divide(col1, col2)
      _blend_color(col1, col2) do |n, n2|
        n2 != 0 ? n / n2 : 1.0
      end
    end

    ncolor def blend_overlay(col1, col2)
      _blend_color(col1, col2) do |n, n2|
        if n < 0.5
          2 * (n * n2)
        else
          1 - 2 * (1 - n) * (1 - n2)
        end
      end
    end

    ncolor def blend_softlight(col1, col2)
      _blend_color(col1, col2) do |n, n2|
        if n2 < 0.5
          2 * n * n2 + n ** 2 * (1 - 2 * n2)
        else
          2 * n * (1 - n2) + Math.sqrt(n * (2 * n2 - 1))
        end
      end
    end

    ncolor def blend_dodge(col1, col2)
      _blend_color(col1, col2) do |n, n2|
        (n >= 1.0) ? n : [1.0, ((n2 / (1.0 - n)))].min
      end
    end

    ncolor def blend_burn(col1, col2)
      _blend_color(col1, col2) do |n, n2|
        (n <= 0.0) ? n : [0, (1.0 - ((1.0 - n2)) / n)].max
      end
    end

    ncolor def blend_alpha2(col1, col2)
      a = 1.0
      beta = a * col1.a
      result = new_color(col2.r, col2.g, col2.b, col2.a)
      if beta >= 1.0 || col2.a == 0
        result = new_color(col1.r, col1.g, col1.b, beta)
      elsif (beta > 0)
        result = new_color(_calc_alpha(col1.r, col2.r, beta),
                           _calc_alpha(col1.g, col2.g, beta),
                           _calc_alpha(col1.b, col2.b, beta),
                           col2.a < beta ? beta : col2.a)
      end
      result
    end

    # secondary blenders
    def normal(col1, _)
      col1.to_normalized_color
    end

    def lighten(col1, rate)
      col = snormalize(col1)
      blend_add(col, rate.to_normalized_color)
    end

    def darken(col1, rate)
      col = snormalize(col1)
      blend_subtract(col, rate.to_normalized_color)
    end

    def selfadd(col1, rate)
      col = snormalize(col1)
      blend_add(col, col * rate)
    end

    def selfsubtract(col1, rate)
      col = snormalize(col1)
      blend_subtract(col, col * rate)
    end

    extend self
  end
end
