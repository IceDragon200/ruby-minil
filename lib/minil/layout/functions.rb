require 'minil/functions'
require 'minil/rect'

module Minil
  module Layout
    def slice(vertical, r, func1, func2)
      if vertical
        lambda do |image, rect, options|
          rect1 = rect.dup
          rect2 = rect.dup
          rect1.height *= r
          rect2.height -= rect1.height
          rect2.y += rect1.height
          func1.call(image, rect1, options)
          func2.call(image, rect2, options)
        end
      else
        lambda do |image, rect, options|
          rect1 = rect.dup
          rect2 = rect.dup
          rect1.width *= r
          rect2.width -= rect1.width
          rect2.x += rect1.width
          func1.call(image, rect1, options)
          func2.call(image, rect2, options)
        end
      end
    end

    def split(vertical, *funcs)
      if vertical
        lambda do |image, rect, options|
          ch = rect.height / funcs.size
          funcs.each_with_index do |func, i|
            cell = rect.dup
            cell.height = ch
            cell.y += ch * i
            func.call(image, cell, options)
          end
        end
      else
        lambda do |image, rect, options|
          cw = rect.width / funcs.size
          funcs.each_with_index do |func, i|
            cell = rect.dup
            cell.width = cw
            cell.x += cw * i
            func.call(image, cell, options)
          end
        end
      end
    end

    def split_horz(*funcs)
      split(false, *funcs)
    end

    def split_vert(*funcs)
      split(true, *funcs)
    end

    def chain(*funcs)
      lambda do |image, rect, options|
        funcs.each { |f| f.call(image, rect, options) }
      end
    end

    def contract(size, func)
      lambda do |image, rect, options|
        func.call(image, rect.contract(size), options)
      end
    end

    def clear
      lambda do |image, rect, options|
        image.clear_rect_r(rect)
      end
    end

    def fill(key)
      lambda do |image, rect, options|
        image.fill_rect_r(rect, options.fetch(key))
      end
    end

    def gradient(k1, k2, vertical)
      lambda do |image, rect, options|
        image.gradient_fill_rect_r(rect, options.fetch(k1), options.fetch(k2), vertical)
      end
    end

    def null
      lambda do |image, rect, options|

      end
    end

    def alpha_blend(func, alpha = 255)
      lambda do |image, rect, options|
        img = Image.create(rect.width, rect.height)
        rect2 = rect.dup
        rect2.x = 0
        rect2.y = 0
        func.call(img, rect2, options)
        image.alpha_blit(img, rect.x, rect.y, 0, 0, img.width, img.height, alpha)
      end
    end

    def padded_flat(ko, ki, size = 1)
      chain(fill(ko), contract(size, fill(ki)))
    end

    extend self
  end
  class LayoutWrapper
    include Layout

    attr_reader :func

    def initialize
      @func = yield self
    end

    def layout(&block)
      LayoutWrapper.new(&block)
    end

    def render(image, rect, options)
      @func.call(image, rect, options)
    end

    alias :call :render
  end
end
