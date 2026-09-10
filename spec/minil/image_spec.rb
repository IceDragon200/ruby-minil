require 'minil/spec_helper'

describe Minil::Image do
  context '#create' do
    it 'should initialize an Image given a width and height' do
      described_class.new.create(128, 64)
    end

    it 'rejects non-positive dimensions' do
      expect { described_class.create(0, 1) }.to raise_error(ArgumentError)
      expect { described_class.create(1, -1) }.to raise_error(ArgumentError)
    end

    it 'rejects dimensions that would overflow the native stride' do
      expect { described_class.create((2**31) - 1, 1) }.to raise_error(ArgumentError)
    end
  end

  let(:imag) do
    img = described_class.new
    img.create(128, 128)
    img
  end

  context '#get_pixel' do
    it 'should get a pixel' do
      expect(imag.get_pixel(0, 0)).to eq(0x00000000)
    end
  end

  context '#set_pixel' do
    it 'should set a pixel' do
      imag.set_pixel(0, 0, 0xFFFF0000)
      expect(imag.get_pixel(0, 0)).to eq(0xFFFF0000)
    end
  end

  context '#fill_rect' do
    it 'should fill an area' do
      imag.fill_rect(32, 0, 64, 64, 0xFF00FF00)
    end
  end

  context '#fill_rect_r' do
    it 'should fill an area' do
      imag.fill_rect_r(Minil::Rect.new(32, 0, 64, 48), 0xFF0000FF)
    end
  end

  context '#gradient_bitdepth_fill_rect' do
  end

  context '#gradient_bitdepth_fill_rect_r' do
  end

  context '#gradient_fill_rect' do
    it 'includes both endpoint colors' do
      image = described_class.create(3, 1)
      image.gradient_fill_rect(0, 0, 3, 1, 0xFF000000, 0xFFFFFFFF)

      expect(image.get_pixel(0, 0)).to eq(0xFF000000)
      expect(image.get_pixel(2, 0)).to eq(0xFFFFFFFF)
    end
  end

  context '#gradient_fill_rect_r' do
  end

  context '#blit' do
    it 'keeps source and destination coordinates aligned while clipping' do
      src = described_class.create(2, 1)
      src.set_pixel(0, 0, 0xFFFF0000)
      src.set_pixel(1, 0, 0xFF00FF00)
      dest = described_class.create(2, 1)

      dest.blit(src, -1, 0, 0, 0, 2, 1)

      expect(dest.get_pixel(0, 0)).to eq(0xFF00FF00)
      expect(dest.get_pixel(1, 0)).to eq(0)
    end

    it 'supports overlapping copies within the same image' do
      image = described_class.create(3, 1)
      image.set_pixel(0, 0, 1)
      image.set_pixel(1, 0, 2)
      image.set_pixel(2, 0, 3)

      image.blit(image, 1, 0, 0, 0, 2, 1)

      expect(3.times.map { |x| image.get_pixel(x, 0) }).to eq([1, 1, 2])
    end
  end

  context '#blit_r' do
  end

  context '#blit_fill' do
    it 'tiles full and partial source rectangles' do
      src = described_class.create(2, 1)
      src.set_pixel(0, 0, 0xFFFF0000)
      src.set_pixel(1, 0, 0xFF00FF00)
      dest = described_class.create(3, 2)

      dest.blit_fill(src, 0, 0, 3, 2, 0, 0, 2, 1)

      expected = [0xFFFF0000, 0xFF00FF00, 0xFFFF0000]
      expect(3.times.map { |x| dest.get_pixel(x, 0) }).to eq(expected)
      expect(3.times.map { |x| dest.get_pixel(x, 1) }).to eq(expected)
    end
  end

  context '#blit_fill_rr' do
  end

  context '#alpha_blit' do
    it 'copies a fully opaque source exactly at full opacity' do
      src = described_class.create(1, 1).fill(0xFFFF0000)
      dest = described_class.create(1, 1)

      dest.alpha_blit(src, 0, 0, 0, 0, 1, 1, 255)

      expect(dest.get_pixel(0, 0)).to eq(0xFFFF0000)
    end

    it 'uses source-over alpha composition' do
      src = described_class.create(1, 1).fill(0x80FF0000)
      dest = described_class.create(1, 1).fill(0x800000FF)

      dest.alpha_blit(src, 0, 0, 0, 0, 1, 1, 255)

      expect(dest.get_pixel(0, 0)).to eq(0xC0AA0055)
    end

    it 'supports overlapping copies within the same image' do
      image = described_class.create(3, 1)
      image.set_pixel(0, 0, 0xFFFF0000)
      image.set_pixel(1, 0, 0xFF00FF00)
      image.set_pixel(2, 0, 0xFF0000FF)

      image.alpha_blit(image, 1, 0, 0, 0, 2, 1, 255)

      expect(3.times.map { |x| image.get_pixel(x, 0) }).to eq(
        [0xFFFF0000, 0xFFFF0000, 0xFF00FF00]
      )
    end
  end

  context '#alpha_blit_r' do
  end

  context '#alpha_blit_fill' do
    it 'tiles with opacity and handles remainder regions' do
      src = described_class.create(2, 1).fill(0xFFFFFFFF)
      dest = described_class.create(3, 2)

      dest.alpha_blit_fill(src, 0, 0, 3, 2, 0, 0, 2, 1, 255)

      expect(dest.palette).to eq([0xFFFFFFFF])
    end
  end

  context '#alpha_blit_fill_r' do
    it 'dispatches to the alpha tiled blit' do
      src = described_class.create(1, 1).fill(0xFFFFFFFF)
      dest = described_class.create(2, 2)

      dest.alpha_blit_fill_rr(src, Minil::Rect.new(0, 0, 2, 2),
                             Minil::Rect.new(0, 0, 1, 1), 255)

      expect(dest.palette).to eq([0xFFFFFFFF])
    end
  end

  context '#subimage' do
  end

  context '#subimage_r' do
  end

  context '#mirror' do
  end

  context '#rotate_90_cw' do
    it 'should rotate 90 degrees clockwise' do
      imag.rotate_90_cw
    end
  end

  context '#rotate_90_ccw' do
    it 'should rotate 90 degrees counter-clockwise' do
      imag.rotate_90_ccw
    end
  end

  context '#rotate_180' do
    it 'should rotate 180 degrees' do
      imag.rotate_180
    end
  end

  context '#pinwheel' do
    it 'should create a pinwheel image' do
      imag.pinwheel
    end
  end

  context '#skew' do
    it 'should skew horizontally' do
      imag.skew(16, 0)
    end

    it 'should skew horizontally (negative)' do
      imag.skew(-16, 0)
    end

    it 'should skew vertically' do
      imag.skew(0, 16)
    end

    it 'should skew vertically (negative)' do
      imag.skew(0, -16)
    end

    it 'should skew vertically and horizontally' do
      imag.skew(16, 16)
    end

    it 'should skew vertically and horizontally (negative)' do
      imag.skew(-16, -16)
    end

    it 'applies both axes when both offsets are non-zero' do
      image = described_class.create(3, 3)
      image.set_pixel(0, 2, 0xFFFFFFFF)

      result = image.skew(3, 1)

      expect(result.get_pixel(2, 2)).to eq(0xFFFFFFFF)
      expect(result.get_pixel(0, 2)).to eq(0)
    end
  end

  context '#replace_color' do
  end

  context '#palette' do
  end

  context '#reduce' do
  end

  context '#upscale' do
  end

  context '#downscale' do
  end

  context '#scale' do
    it 'supports fractional downscaling' do
      image = described_class.create(4, 2).fill(0xFFFFFFFF)

      result = image.scale(0.5)

      expect([result.width, result.height]).to eq([2, 1])
      expect(result.get_pixel(1, 0)).to eq(0xFFFFFFFF)
    end
  end

  context '#mask_blit' do
    it 'accepts matching non-square source and mask images' do
      src = described_class.create(2, 3).fill(0xFFFFFFFF)
      mask = described_class.create(2, 3).fill(0xFFFF0000)
      dest = described_class.create(2, 3)

      expect { dest.mask_blit(src, mask, 0, 0, 0, 0, 2, 3) }.not_to raise_error
      expect(dest.palette).to eq([0xFFFFFFFF])
    end

    it 'keeps source coordinates aligned when the destination is clipped' do
      src = described_class.create(2, 1)
      src.set_pixel(0, 0, 0xFFFF0000)
      src.set_pixel(1, 0, 0xFF00FF00)
      mask = described_class.create(2, 1).fill(0xFFFF0000)
      dest = described_class.create(2, 1)

      dest.mask_blit(src, mask, -1, 0, 0, 0, 2, 1)

      expect(dest.get_pixel(0, 0)).to eq(0xFF00FF00)
    end
  end

  context '#channel_select' do
    it 'should select the red color channel' do
      imag.channel_select('r')
    end

    it 'should select the green color channel' do
      imag.channel_select('g')
    end

    it 'should select the blue color channel' do
      imag.channel_select('b')
    end

    it 'should select the alpha color channel' do
      imag.channel_select('a')
    end

    it 'should select the red, green and blue color channels' do
      imag.channel_select('rgb')
    end
  end

  context '#to_alpha_mask' do
    it 'should convert image to a alpha mask Image' do
      imag.to_alpha_mask
    end
  end

  context '#channel_as_alpha_mask' do
    it 'should use red color channel as alpha' do
      imag.channel_as_alpha_mask('r')
    end

    it 'should use green color channel as alpha' do
      imag.channel_as_alpha_mask('g')
    end

    it 'should use blue color channel as alpha' do
      imag.channel_as_alpha_mask('b')
    end

    it 'should use alpha color channel as alpha' do
      imag.channel_as_alpha_mask('a')
    end
  end

  context '#invert' do
    it 'should invert color channels' do
      imag.invert
    end
  end

  context '#load_file' do
    it 'should load an image file' do
      img = described_class.new
      img.load_file(data_path('test_img.png'))
      img
    end
  end

  context '#save_file' do
    it 'should save to file' do
      imag.save_file(output_path('test_img_save.png'))
    end
  end
end
