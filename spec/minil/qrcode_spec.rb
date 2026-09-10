require 'minil/spec_helper'
require 'minil/qrcode'

describe Minil::QrCode do
  let(:hello_world_matrix) do
    <<~MATRIX.lines.map(&:chomp)
      111111100010101111111
      100000101110001000001
      101110100010101011101
      101110100010101011101
      101110101011101011101
      100000100111001000001
      111111101010101111111
      000000000000000000000
      101010100100100010010
      011110001001000010001
      000111111101001011000
      111101011001110101110
      010011110101001110101
      000000001010001000101
      111111100000100101100
      100000100110001101000
      101110101100101111111
      101110100011010100010
      101110101111011101001
      100000100001110001011
      111111101101011100001
    MATRIX
  end

  describe '.encode' do
    it 'matches a known version 1-M symbol' do
      code = described_class.encode('HELLO WORLD', error_correction: :m)

      expect([code.version, code.size, code.mask]).to eq([1, 21, 0])
      expect(code.modules.map { |row| row.map { |cell| cell ? '1' : '0' }.join })
        .to eq(hello_world_matrix)
    end

    it 'supports every data mode' do
      expect(described_class.encode('012345', type: :numeric).size).to eq(21)
      expect(described_class.encode('ABC 123', type: :alphanumeric).size).to eq(21)
      expect(described_class.encode("\x00\xFF".b, type: :binary).size).to eq(21)
      expect(described_class.encode('漢字', type: :kanji).size).to eq(21)
    end

    it 'supports every error correction level and versions above 6' do
      %i[l m q h].each do |level|
        code = described_class.encode('x' * 300, type: :binary,
                                      error_correction: level)
        expect(code.version).to be_between(1, 40)
        expect(code.error_correction).to eq(level)
        expect(code.modules.length).to eq(code.version * 4 + 17)
      end

      expect(described_class.encode('x' * 500, type: :binary,
                                    error_correction: :h).version).to be >= 7
    end

    it 'accepts explicit version and mask values' do
      code = described_class.encode('hello', version: 5, mask: 7)

      expect([code.version, code.mask, code.size]).to eq([5, 7, 37])
    end

    it 'rejects invalid modes, values, and oversized data' do
      expect { described_class.encode('abc', type: :numeric) }.to raise_error(ArgumentError)
      expect { described_class.encode('abc', error_correction: :z) }.to raise_error(ArgumentError)
      expect { described_class.encode('abc', mask: 8) }.to raise_error(ArgumentError)
      expect { described_class.encode('a' * 3000, type: :binary) }.to raise_error(ArgumentError)
    end
  end

  describe '.determine_version' do
    it 'selects the smallest version that can hold the segment' do
      expect(described_class.determine_version(:numeric, '1' * 41)).to eq(1)
      expect(described_class.determine_version(:numeric, '1' * 42)).to eq(2)
    end
  end

  describe '.create' do
    it 'renders integer-sized modules with a four-module quiet zone' do
      image = described_class.create('HELLO WORLD', error_correction: :m,
                                     module_size: 2)

      expect([image.width, image.height]).to eq([58, 58])
      expect(image.get_pixel(0, 0)).to eq(0xFFFFFFFF)
      expect(image.get_pixel(8, 8)).to eq(0xFF000000)
    end
  end

  describe '.generate' do
    it 'renders into and returns an existing image' do
      image = Minil::Image.create(100, 80)

      result = described_class.generate(image, '1234')

      expect(result).to equal(image)
      expect(image.palette).to contain_exactly(0xFF000000, 0xFFFFFFFF)
    end

    it 'rejects images that cannot hold one pixel per module' do
      image = Minil::Image.create(20, 20)

      expect { described_class.generate(image, 'x') }.to raise_error(ArgumentError)
    end
  end
end
