require 'minil/spec_helper'
require 'minil/rgss_bitmap'

describe Bitmap do
  it 'allows access until it is disposed' do
    bitmap = described_class.new(2, 3)

    expect([bitmap.width, bitmap.height]).to eq([2, 3])
    bitmap.dispose
    expect { bitmap.width }.to raise_error(RGSSError)
  end

  it 'fills rectangles with RGSS colors' do
    bitmap = described_class.new(2, 2)
    color = Color.new(255, 0, 0, 255)

    bitmap.fill_rect(0, 0, 2, 2, color)

    expect([bitmap.get_pixel(0, 0).red, bitmap.get_pixel(0, 0).alpha]).to eq([255, 255])
  end

  it 'copies RGSS colors and rectangles' do
    color = Color.new(Color.new(1, 2, 3, 4))
    rect = Rect.new(Rect.new(1, 2, 3, 4))

    expect([color.red, color.green, color.blue, color.alpha]).to eq([1, 2, 3, 4])
    expect(rect.to_a).to eq([1, 2, 3, 4])
  end
end
