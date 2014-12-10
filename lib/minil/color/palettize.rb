require 'minil/color/blender'

module Minil
  module ColorPalettize
    def soft(color)
      [ColorBlender.selfadd(color, 0.13),
      ColorBlender.selfsubtract(color, 0.05),
      color.to_normalized_color,
      ColorBlender.selfsubtract(color, 0.16)]
    end

    def hard(color)
      [ColorBlender.selfadd(color, 0.53),
      ColorBlender.selfsubtract(color, 0.45),
      color.to_normalized_color,
      ColorBlender.selfsubtract(color, 0.62)]
    end

    def harsh(color)
      [ColorBlender.selfadd(color, 0.33),
      ColorBlender.selfsubtract(color, 0.25),
      color.to_normalized_color,
      ColorBlender.selfsubtract(color, 0.42)]
    end

    def rated(color, r)
      [ColorBlender.selfadd(color, r),
      color.to_normalized_color,
      ColorBlender.selfsubtract(color, r * 0.5),
      ColorBlender.selfsubtract(color, r)]
    end

    def circ(color, r)
      [ColorBlender.selfadd(color, r * Math.sin(r * Math::PI/2) * Math.cos(r * Math::PI/2)),
      color.to_normalized_color,
      ColorBlender.selfsubtract(color, (r * 0.1) + r * Math.sin(r * Math::PI/2) * 0.9),
      ColorBlender.selfsubtract(color, (r * 0.3) + r * Math.cos(r * Math::PI/2) * 0.7)]
    end

    def sq(color, r)
      rated(color, r * r)
    end

    def cubic(color, r)
      rated(color, r * r * r)
    end

    extend self
  end
end
