module Minil
  class Color
    attr_accessor :value

    def initialize(value = 0x00000000)
      @value = value
    end

    def clamp_channel_value(value)
      value < 0 ? 0 : (value > 255 ? 255 : value)
    end

    def r
      @value >> 16 & 0xFF
    end

    def g
      @value >> 8 & 0xFF
    end

    def b
      @value & 0xFF
    end

    def a
      @value >> 24 & 0xFF
    end

    def r=(r)
      @value = (@value ^ (@value & 0x00FF0000)) | ((clamp_channel_value(r)) << 16)
    end

    def g=(g)
      @value = (@value ^ (@value & 0x0000FF00)) | ((clamp_channel_value(g)) << 8)
    end

    def b=(b)
      @value = (@value ^ (@value & 0x000000FF)) | clamp_channel_value(b)
    end

    def a=(a)
      @value = (@value ^ (@value & 0xFF000000)) | (clamp_channel_value(a) << 24)
    end

    def +(other)
      self.class.rgba(other.r + r, other.g + g, other.b + b, other.a + a)
    end

    def -(other)
      self.class.rgba(other.r - r, other.g - g, other.b - b, other.a - a)
    end

    def *(other)
      self.class.rgba(other.r * r, other.g * g, other.b * b, other.a * a)
    end

    def /(other)
      self.class.rgba(other.r / r, other.g / g, other.b / b, other.a / a)
    end

    def opaque
      dup.tap { |c| c.a = 255 }
    end

    def opaque_render
      dup.tap do |c|
        c.r = c.r * c.a / 255
        c.g = c.g * c.a / 255
        c.b = c.b * c.a / 255
        c.a = 255
      end
    end

    def to_i
      @value
    end

    def to_a
      self.class.decode(@value)
    end

    def to_s
      "(#{r}, #{g}, #{b}, #{a})"
    end

    def self.encode(r, g, b, a)
      a << 24 | r << 16 | g << 8 | b
    end

    def self.decode(value)
      return value >> 16 & 0xFF, value >> 8 & 0xFF, value & 0xFF, value >> 24 & 0xFF
    end

    def self.rgba(r, g, b, a)
      new encode(r, g, b, a)
    end

    def self.rgb(r, g, b)
      rgba(r, g, b, 255)
    end

    def self.cast_to_channels(obj)
      case obj
      when Integer
        decode(obj)
      when Array
        obj
      else
        raise ArgumentError, "expected an Integer or Array<Integer>"
      end
    end

    private :clamp_channel_value
  end
end
