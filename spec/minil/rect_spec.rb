require 'minil/spec_helper'

describe Minil::Rect do
  context '.new' do
    it 'will create a new rect' do
      Minil::Rect.new(-12, 12, 48, 32)
    end

    it 'exposes width and height aliases' do
      rect = Minil::Rect.new(0, 0, 4, 5)
      rect.width = 6
      rect.height = 7

      expect(rect.to_a).to eq([0, 0, 6, 7])
    end
  end

  context '#sub_rect' do
    it 'will return a sub rect of the parent given other rect' do
      parent = Minil::Rect.new 32, 16, 16, 16
      child = Minil::Rect.new 4, 4, 8, 8
      result = parent.sub_rect child

      expect(result.x).to eq(36)
      expect(result.y).to eq(20)
      expect(result.w).to eq(8)
      expect(result.h).to eq(8)
    end

    it 'will adjust the result rect size to fit the parent' do
      parent = Minil::Rect.new 32, 16, 16, 16
      child = Minil::Rect.new 4, 4, 24, 24
      result = parent.sub_rect child
      expect(result.x).to eq(36)
      expect(result.y).to eq(20)
      expect(result.w).to eq(12)
      expect(result.h).to eq(12)
    end

    it 'clips children extending above and to the left' do
      parent = Minil::Rect.new(32, 16, 16, 16)
      child = Minil::Rect.new(-4, -3, 8, 8)

      result = parent.sub_rect(child)

      expect(result.to_a).to eq([32, 16, 4, 5])
      expect(parent.to_a).to eq([32, 16, 16, 16])
    end
  end
end
