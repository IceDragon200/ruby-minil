module Minil
  class Rect
    attr_reader :x
    attr_reader :y
    attr_reader :width
    attr_reader :height

    def initialize(x, y, w, h)
      set(x, y, w, h)
    end

    def x=(x)
      @x = x.to_i
    end

    def y=(y)
      @y = y.to_i
    end

    def width=(width)
      @width = width.to_i
    end

    def height=(height)
      @height = height.to_i
    end

    def to_a
      return @x, @y, @width, @height
    end

    def set(x, y, w, h)
      @x, @y, @width, @height = x, y, w, h
    end

    def contract(cx, cy = cx)
      cx = cx.to_i
      cy = cy.to_i
      self.class.new x + cx, y + cy, width - cx * 2, height - cy * 2
    end

    def align(str, surface)
      rect = dup
      str.split(" ").each do |command|
        case command
        when "center"
          rect.cx = surface.cx
          rect.cy = surface.cy
        when "middle-horz"
          rect.cx = surface.cx
        when "middle-vert"
          rect.cy = surface.cy
        when "left"
          rect.x = surface.x
        when "right"
          rect.x2 = surface.x2
        when "top"
          rect.y = surface.y
        when "bottom"
          rect.y2 = surface.y2
        end
      end
      rect
    end

    def x2
      x + width
    end

    def x2=(x2)
      self.x = x2 - width
    end

    def y2
      y + height
    end

    def y2=(y2)
      self.y = y2 - height
    end

    def cx
      x + width / 2
    end

    def cx=(cx)
      self.x = cx - width / 2
    end

    def cy
      y + height / 2
    end

    def cy=(cy)
      self.y = cy - height / 2
    end

    def inside_xy?(ix, iy)
      ix.between?(x, x2 - 1) && iy.between?(y, y2 - 1)
    end

    def inside_vect?(vect)
      inside_xy?(vect.x, vect.y)
    end

    def inside?(*args)
      args.size == 2 ? inside_xy?(*args) : inside_vect?(args.first)
    end

    def clear
      self.x = 0
      self.y = 0
      self.w = 0
      self.h = 0
      self
    end
  end
end
