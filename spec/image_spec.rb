require_relative 'spec_helper'

describe Image do
  context '#create' do
    it 'should initialize an Image given a width and height' do
      Image.new.create(128, 64)
    end
  end

  let(:imag) { i=Image.new; i.create(128, 128); i }

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
  end

  context '#gradient_fill_rect_r' do
  end

  context '#blit' do
  end

  context '#blit_r' do
  end

  context '#blit_fill' do
  end

  context '#blit_fill_rr' do
  end

  context '#alpha_blit' do
  end

  context '#alpha_blit_r' do
  end

  context '#alpha_blit_fill' do
  end

  context '#alpha_blit_fill_rr' do
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
      img = Image.new
      img.load_file(File.expand_path('test_img.png', File.dirname(__FILE__)))
      img
    end
  end

  context '#save_file' do
    it 'should save to file' do
      imag.save_file(File.expand_path('test_img_save.png', File.dirname(__FILE__)))
    end
  end
end
