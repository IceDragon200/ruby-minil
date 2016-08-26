module Minil
  class Rect
    attr_reader :x
    attr_reader :y
    attr_reader :w
    attr_reader :h

    def initialize(x, y, w, h)
      set(x, y, w, h)
    end

    def x=(x)
      @x = x.to_i
    end

    def y=(y)
      @y = y.to_i
    end

    def w=(w)
      @w = w.to_i
    end

    def h=(h)
      @h = h.to_i
    end

    def to_a
      return @x, @y, @w, @h
    end

    def set(x, y, w, h)
      @x, @y, @w, @h = x, y, w, h
    end

    def contract(cx, cy = cx)
      cx = cx.to_i
      cy = cy.to_i
      self.class.new x + cx, y + cy, w - cx * 2, h - cy * 2
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
      x + w
    end

    def x2=(x2)
      self.x = x2 - w
    end

    def y2
      y + h
    end

    def y2=(y2)
      self.y = y2 - h
    end

    def cx
      x + w / 2
    end

    def cx=(cx)
      self.x = cx - w / 2
    end

    def cy
      y + h / 2
    end

    def cy=(cy)
      self.y = cy - h / 2
    end

    def contains_xy?(ix, iy)
      ix.between?(x, x2 - 1) && iy.between?(y, y2 - 1)
    end

    def contains_vect?(vect)
      contains_xy?(vect.x, vect.y)
    end

    def contains?(*args)
      args.size == 2 ? contains_xy?(*args) : contains_vect?(args.first)
    end

    def clear
      self.x = 0
      self.y = 0
      self.w = 0
      self.h = 0
      self
    end

    # Returns a rectangle applyin the `other` as a relative coord
    # The final rect has it's coordinates set in it's parent.
    #
    # @param [Minil::Rect] other
    # @return [Minil::Rect]
    def sub_rect(other)
      nx = x + other.x
      ny = y + other.y
      nw = other.w
      nh = other.h
      if nx < x
        w -= x - nx
        nx = x
      end
      if ny < y
        h -= y - ny
        ny = y
      end
      if (nx + nw) > x2
        nw = x2 - nx
      end
      if (ny + nh) > y2
        nh = y2 - ny
      end
      Minil::Rect.new nx, ny, nw, nh
    end
  end
end
