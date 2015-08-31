require 'minil/functions'
require 'minil/color'
require 'minil/rect'

class RGSSError < RuntimeError
end

class Color
  attr_reader :__color__

  def initialize(*args)
    @__color__ = Minil::Color.new
    set(*args)
  end

  def set(*args)
    case args.size
    when 1
      color = args.first
      if color === Color
        @__color__ = color.__color__.dup
      else
        raise TypeError, 'expected Color'
      end
    when 3
      @__color__.a = 255
      @__color__.r, @__color__.g, @__color__.b = *args
    when 4
      @__color__.r, @__color__.g, @__color__.b, @__color__.a = *args
    else
      raise ArgumentError, "got #{args.size} (expcted 1, 3 or 4)"
    end
  end

  def red
    @__color__.r
  end

  def red=(red)
    @__color__.r = [[red, 0].max, 255].min
  end

  def green
    @__color__.g
  end

  def green=(green)
    @__color__.g = [[green, 0].max, 255].min
  end

  def blue
    @__color__.b
  end

  def blue=(blue)
    @__color__.b = [[blue, 0].max, 255].min
  end

  def alpha
    @__color__.a
  end

  def alpha=(alpha)
    @__color__.a = [[alpha, 0].max, 255].min
  end
end

class Rect < Minil::Rect
  def initialize(*args)
    super 0, 0, 0, 0
    set(*args)
  end

  def set(*args)
    case args.size
    when 1
      obj = args.first
      if obj === Rect
        super(*obj.to_a)
      else
        raise TypeError, 'expected Rect'
      end
    when 4
      super(*args)
    else
      raise ArgumentError, "got #{args.size} (expcted 1 or 4)"
    end
  end
end

class Font
  attr_accessor :name
  attr_accessor :size
  attr_accessor :bold
  attr_accessor :italic
  attr_accessor :shadow
  attr_accessor :outline
  attr_accessor :out_color
  attr_accessor :color

  def initialize
    @name = self.class.default_name.dup
    @size = self.class.default_size
    @bold = self.class.default_bold
    @italic = self.class.default_italic
    @shadow = self.class.default_shadow
    @outline = self.class.default_outline
    @out_color = self.class.default_out_color.dup
    @color = self.class.default_color.dup
  end

  class << self
    attr_accessor :default_name
    attr_accessor :default_size
    attr_accessor :default_bold
    attr_accessor :default_italic
    attr_accessor :default_shadow
    attr_accessor :default_outline
    attr_accessor :default_out_color
    attr_accessor :default_color
  end

  self.default_name = ['Arial']
  self.default_size = 18
  self.default_bold = false
  self.default_italic = false
  self.default_shadow = false
  self.default_outline = false
  self.default_out_color = Color.new(0, 0, 0, 128)
  self.default_color = Color.new(255, 255, 255, 255)
end

class Bitmap
  attr_reader :__image__
  attr_accessor :font

  def initialize(*args)
    @font = Font.new
    @__disposed__ = false
    @__image__ = begin
      case args.size
      when 1
        Image.load_file(args.first)
      when 2
        Image.create(*args)
      else
        raise ArgumentError, "got #{args.size} (expected 1 or 2)"
      end
    end
  end

  def initialize_copy(other)
    super other
    @__image__ = other.__image__.dup
    @font = other.font.dup
    self
  end

  def dispose
    @__image__ = nil
    @__disposed__ = true
  end

  def disposed?
    @__disposed__
  end

  def check_disposed
    raise RGSSError, 'cannot access disposed Bitmap'
  end

  def width
    check_disposed
    @__image__.width
  end

  def height
    check_disposed
    @__image__.height
  end

  def rect
    check_disposed
    Rect.new(0, 0, width, height)
  end

  def blt(*args)
    check_disposed
    case args.size
    when 4
      tx, ty, sbitmap, srect = *args
      opacity = 255
    when 5
      tx, ty, sbitmap, srect, opacity = *args
    else
      raise ArgumentError, "got #{args.size} (expected 4, or 5)"
    end
    sbitmap.check_disposed
    @__image__.alpha_blit_r(sbitmap.__image__, tx, ty, srect, opacity)
    self
  end

  def stretch_blt(*args)
    check_disposed
    case args.size
    # dest_rect, src_bitmap, src_rect
    when 3
      dest_rect, src_bitmap, src_rect = *args
      opacity = 255
    # dest_rect, src_bitmap, src_rect, opacity
    when 4
      dest_rect, src_bitmap, src_rect, opacity = *args
    else
      raise ArgumentError, "got #{args.size} (expected 3, or 4)"
    end
    src_bitmap.check_disposed
    # (IceDragon) TODO: implement stretch_blt
    self
  end

  def clear
    check_disposed
    @__image__.clear
    self
  end

  def clear_rect(*args)
    check_disposed
    case args.size
    # rect
    when 1
      rect, = *args
      x, y, w, h = *rect
    # x, y, width, height
    when 4
      x, y, w, h = *args
    else
      raise ArgumentError, "got #{args.size} (expected 1, or 4)"
    end
    @__image__.clear_rect(x, y, w, h)
    self
  end

  def blur
    check_disposed
    # (IceDragon) TODO: implement blur
    self
  end

  def radial_blur(angle, division)
    check_disposed
    # (IceDragon) TODO: implement radial_blur
    self
  end

  def get_pixel(x, y)
    check_disposed
    Color.new(*Minil::Color.decode(@__image__.get_pixel(x, y)))
  end

  def set_pixel(x, y, color)
    check_disposed
    @__image__.set_pixel(x, y, color.__color__.value)
    self
  end

  def fill_rect(*args)
    check_disposed
    case args.size
    # rect, color
    when 2
      rect, color = *args
      x, y, w, h = *rect
    # x, y, width, height, color
    when 5
      x, y, w, h, color = *args
    else
      raise ArgumentError, "got #{args.size} (expected 2, or 5)"
    end
    @__image__.fill_rect(x, y, w, h, color.__color__)
    self
  end

  def gradient_fill_rect(*args)
    check_disposed
    vertical = false
    case args.size
    # rect, color1, color2
    when 3
      rect, color1, color2 = *args
      x, y, w, h = *rect
    # rect, color1, color2, vertical
    when 4
      rect, color1, color2, vertical = *args
      x, y, w, h = *rect
    # x, y, width, height, color1, color2
    when 6
      x, y, w, h, color1, color2 = *args
    # x, y, width, height, color1, color2, vertical
    when 7
      x, y, w, h, color1, color2, vertical = *args
    else
      raise ArgumentError, "expected 3, 4, 6 or 7 but recieved #{args.size}"
    end
    @__image__.gradient_fill_rect(x, y, w, h, color1, color2, vertical)
    self
  end

  def draw_text(*args)
    check_disposed
    align = 0
    case args.size
    # Hash hash
    when 1
      x, y, w, h = 0, 0, 0, 0
      text = ""
      align = 0
      hsh, = args
      x      = hsh[:x]      if hsh.has_key?(:x)
      y      = hsh[:y]      if hsh.has_key?(:y)
      width  = hsh[:width]  if hsh.has_key?(:width)
      height = hsh[:height] if hsh.has_key?(:height)
      text   = hsh[:text]   if hsh.has_key?(:text)
      align  = hsh[:align]  if hsh.has_key?(:align)
      x, y, w, h = Rect.cast(hsh[:rect]).to_a if hsh.has_key?(:rect)
    # Rect rect, String text
    when 2
      rect, text = *args
      x, y, w, h = *rect
    # Rect rect, String text, ALIGN align
    # Rect rect, String text, ANCHOR align
    when 3
      rect, text, align = *args
      x, y, w, h = *rect
    # Integer x, Integer y, Integer width, Integer height, String text
    when 5
      x, y, w, h, text = *args
    # Integer x, Integer y, Integer width, Integer height, String text, ALIGN align
    # Integer x, Integer y, Integer width, Integer height, String text, ANCHOR align
    when 6
      x, y, w, h, text, align = *args
    else
      raise(ArgumentError, "expected 2, 3, 5, or 6 but recieved #{args.size}")
    end
    # (IceDragon) TODO: implement draw_text
    self
  end

  def text_size(*args)
    # (IceDragon) TODO: implement text_size
    Rect.new(0, 0, 32, 24)
  end

  def hue_change(hue)
    # (IceDragon) TODO: implement hue_change
    self
  end
end
