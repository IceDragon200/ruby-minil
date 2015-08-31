require 'minil/spec_helper'

describe Minil::Color do
  context '.rgb' do
    subject { Minil::Color }

    it 'should create a new Color' do
      color = subject.rgb(128, 64, 96)
      expect(color.r).to eq(128)
      expect(color.g).to eq(64)
      expect(color.b).to eq(96)
      expect(color.a).to eq(255)
    end
  end

  context '.rgba' do
    subject { Minil::Color }

    it 'should create a new Color' do
      color = subject.rgba(128, 64, 96, 24)
      expect(color.r).to eq(128)
      expect(color.g).to eq(64)
      expect(color.b).to eq(96)
      expect(color.a).to eq(24)
    end
  end

  context '#r[=]' do
    let(:color) { Minil::Color.new }

    it 'should change the red channel value' do
      color.r = 12
      expect(color.r).to eq(12)
    end

    it 'should not affect other channels' do
      color.r = 12
      color.g = 1
      color.b = 2
      color.a = 3
      expect(color.r).to eq(12)
      expect(color.g).to eq(1)
      expect(color.b).to eq(2)
      expect(color.a).to eq(3)
    end
  end

  context '#g[=]' do
    let(:color) { Minil::Color.new }

    it 'should change the green channel value' do
      color.g = 27
      expect(color.g).to eq(27)
    end

    it 'should not affect other channels' do
      color.r = 1
      color.g = 27
      color.b = 2
      color.a = 3
      expect(color.r).to eq(1)
      expect(color.g).to eq(27)
      expect(color.b).to eq(2)
      expect(color.a).to eq(3)
    end
  end

  context '#b[=]' do
    let(:color) { Minil::Color.new }

    it 'should change the blue channel value' do
      color.b = 42
      expect(color.b).to eq(42)
    end

    it 'should not affect other channels' do
      color.r = 1
      color.g = 2
      color.b = 42
      color.a = 3
      expect(color.r).to eq(1)
      expect(color.g).to eq(2)
      expect(color.b).to eq(42)
      expect(color.a).to eq(3)
    end
  end

  context '#a[=]' do
    let(:color) { Minil::Color.new }

    it 'should change the alpha channel value' do
      color.a = 128
      expect(color.a).to eq(128)
    end

    it 'should not affect other channels' do
      color.r = 1
      color.g = 2
      color.b = 3
      color.a = 128
      expect(color.r).to eq(1)
      expect(color.g).to eq(2)
      expect(color.b).to eq(3)
      expect(color.a).to eq(128)
    end
  end
end
