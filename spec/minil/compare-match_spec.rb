require 'minil/spec_helper'
require 'minil/compare/match'

describe Minil::Image, 'comparison helpers' do
  it 'reports a ratio of one for identical images' do
    image = described_class.create(2, 2).fill(0xFFFFFFFF)

    expect(image.compare_ratio(image)).to eq(1.0)
  end

  it 'uses width and height in the correct order for rectangular comparisons' do
    image = described_class.create(2, 1).fill(0xFFFFFFFF)
    other = image.dup
    other.set_pixel(1, 0, 0)

    expect(image.compare_rect(other, 0, 0, 0, 0, 2, 1)).to be(false)
    expect(image.compare_rect_ratio(other, 0, 0, 0, 0, 2, 1)).to eq(0.5)
  end
end
