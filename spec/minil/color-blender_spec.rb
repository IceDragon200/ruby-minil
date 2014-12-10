require_relative 'spec_helper'

@test_colors = [
  Minil::Color.rgba(255, 255, 255, 255),
  Minil::Color.rgba(192, 67, 43, 255),
  Minil::Color.rgba(0, 0, 0, 255)
]

describe Minil::ColorBlender do
  context '::normalize' do
    it 'should convert objects to NormalizedColors' do
      color = Minil::Color.rgba(255, 50, 20, 255)
      ncol = subject.normalize(color)
    end
  end

  context '::snormalize' do
    it 'should convert objects to NormalizedColors and singularize return' do
      color = Minil::Color.rgba(255, 50, 20, 255)
      ncol = subject.snormalize(color)
    end
  end

  context '::min' do
    it 'should return the color with the smallest channel sum' do
      ncol = subject.min(*@test_colors)
    end
  end

  context '::max' do
    it 'should return the color with the largest channel sum' do
      ncol = subject.max(*@test_colors)
    end
  end

  context '::darkest' do
    it 'should return the darkest color' do
      ncol = subject.darkest(*@test_colors)
    end
  end

  context '::lightest' do
    it 'should return the lightest color' do
      ncol = subject.lightest(*@test_colors)
    end
  end
end
