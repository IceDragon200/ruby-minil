require 'minil/spec_helper'
require 'minil/barcode'

describe Minil::Barcode::Code128 do
  describe '.encode' do
    it 'encodes Code 128-B start, data, checksum, stop, and termination bars' do
      expect(described_class.checksum('Hello')).to eq(76)
      expect(described_class.encode('Hello')).to eq(
        '110100100001100010100010110010000110010100001100101000010001111010110010100001100011101011'
      )
    end

    it 'accepts the complete Code 128-B byte range' do
      expect { described_class.encode((32..127).to_a.pack('C*')) }.not_to raise_error
    end

    it 'rejects bytes outside Code 128-B' do
      expect { described_class.encode("\n") }.to raise_error(ArgumentError, /0x0A/)
      expect { described_class.encode('é') }.to raise_error(ArgumentError)
    end
  end

  describe '.create' do
    it 'preserves the original script defaults' do
      image = described_class.create('Hello')

      expect([image.width, image.height]).to eq([224, 92])
      expect(image.get_pixel(0, 0)).to eq(0xFFFFFFFF)
      expect(image.get_pixel(22, 22)).to eq(0xFF000000)
    end
  end

  describe '.generate' do
    it 'renders into and returns an existing image' do
      image = Minil::Image.create(300, 100)

      result = described_class.generate(image, '123')

      expect(result).to equal(image)
      expect(image.palette).to contain_exactly(0xFF000000, 0xFFFFFFFF)
    end

    it 'rejects an undersized destination image' do
      image = Minil::Image.create(20, 20)

      expect { described_class.generate(image, 'Hello') }.to raise_error(ArgumentError)
    end
  end
end
