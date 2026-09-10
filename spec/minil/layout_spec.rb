require 'minil/spec_helper'
require 'minil/layout/functions'

describe Minil::Layout do
  it 'splits Minil rectangles using their width and height aliases' do
    image = Minil::Image.create(4, 2)
    layout = described_class.split_horz(
      described_class.fill(:left),
      described_class.fill(:right)
    )

    layout.call(image, image.rect, left: 0xFFFF0000, right: 0xFF00FF00)

    expect(image.get_pixel(0, 0)).to eq(0xFFFF0000)
    expect(image.get_pixel(3, 0)).to eq(0xFF00FF00)
  end
end
