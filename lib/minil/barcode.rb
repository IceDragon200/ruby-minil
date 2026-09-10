# frozen_string_literal: true

require_relative 'image'

module Minil
  module Barcode
    # Code 128 subset B, imported from the original standalone barcode script.
    module Code128
      PATTERNS = %w[
        11011001100 11001101100 11001100110 10010011000 10010001100
        10001001100 10011001000 10011000100 10001100100 11001001000
        11001000100 11000100100 10110011100 10011011100 10011001110
        10111001100 10011101100 10011100110 11001110010 11001011100
        11001001110 11011100100 11001110100 11101101110 11101001100
        11100101100 11100100110 11101100100 11100110100 11100110010
        11011011000 11011000110 11000110110 10100011000 10001011000
        10001000110 10110001000 10001101000 10001100010 11010001000
        11000101000 11000100010 10110111000 10110001110 10001101110
        10111011000 10111000110 10001110110 11101110110 11010001110
        11000101110 11011101000 11011100010 11011101110 11101011000
        11101000110 11100010110 11101101000 11101100010 11100011010
        11101111010 11001000010 11110001010 10100110000 10100001100
        10010110000 10010000110 10000101100 10000100110 10110010000
        10110000100 10011010000 10011000010 10000110100 10000110010
        11000010010 11001010000 11110111010 11000010100 10001111010
        10100111100 10010111100 10010011110 10111100100 10011110100
        10011110010 11110100100 11110010100 11110010010 11011011110
        11011110110 11110110110 10101111000 10100011110 10001011110
        10111101000 10111100010 11110101000 11110100010 10111011110
        10111101110 11101011110 11110101110 11010000100 11010010000
        11010011100 11000111010
      ].freeze

      START_B = 104
      STOP = 106
      TERMINATION = '11'.freeze

      module_function

      def values(data)
        bytes = String(data).b.bytes
        invalid = bytes.find { |byte| !byte.between?(32, 127) }
        if invalid
          raise ArgumentError,
                format('Code 128-B only accepts bytes 0x20..0x7F (got 0x%02X)', invalid)
        end

        bytes.map { |byte| byte - 32 }
      end

      def checksum(data)
        values(data).each_with_index.reduce(START_B) do |sum, (value, index)|
          sum + value * (index + 1)
        end % 103
      end

      def encode(data)
        encoded_values = values(data)
        check = encoded_values.each_with_index.reduce(START_B) do |sum, (value, index)|
          sum + value * (index + 1)
        end % 103

        ([START_B] + encoded_values + [check, STOP]).map { |value| PATTERNS.fetch(value) }.join + TERMINATION
      end

      def generate(image, data, module_width: nil, bar_height: nil, quiet_zone: 11,
                   dark: 0xFF000000, light: 0xFFFFFFFF)
        unless image.is_a?(Minil::Image)
          raise ArgumentError, 'generate expects a Minil::Image'
        end

        border = nonnegative_integer(quiet_zone, 'quiet_zone')
        sequence = encode(data)
        total_modules = sequence.length + border * 2
        width = if module_width.nil?
                  horizontal = image.width / total_modules
                  reserved_height = bar_height.nil? ? 1 : positive_integer(bar_height, 'bar_height')
                  vertical = border.zero? ? horizontal : (image.height - reserved_height) / (border * 2)
                  [horizontal, vertical].min
                else
                  positive_integer(module_width, 'module_width')
                end
        raise ArgumentError, 'image is too narrow for this barcode' if width < 1

        bars = bar_height.nil? ? image.height - border * width * 2 : positive_integer(bar_height, 'bar_height')
        raise ArgumentError, 'image is too short for this barcode' if bars < 1

        pixel_width = total_modules * width
        pixel_height = bars + border * width * 2
        if pixel_width > image.width || pixel_height > image.height
          raise ArgumentError, 'barcode does not fit the image'
        end

        origin_x = (image.width - pixel_width) / 2 + border * width
        origin_y = (image.height - pixel_height) / 2 + border * width
        image.fill(light)
        draw_bars(image, sequence, origin_x, origin_y, width, bars, dark)
        image
      end

      def create(data, module_width: 2, bar_height: 48, quiet_zone: 11,
                 dark: 0xFF000000, light: 0xFFFFFFFF)
        width = positive_integer(module_width, 'module_width')
        height = positive_integer(bar_height, 'bar_height')
        border = nonnegative_integer(quiet_zone, 'quiet_zone')
        sequence = encode(data)
        image = Minil::Image.create((sequence.length + border * 2) * width,
                                    height + border * width * 2)
        generate(image, data, module_width: width, bar_height: height,
                 quiet_zone: border, dark: dark, light: light)
      end

      def draw_bars(image, sequence, x, y, module_width, height, dark)
        index = 0
        while index < sequence.length
          unless sequence.getbyte(index) == 49
            index += 1
            next
          end

          run_start = index
          index += 1 while index < sequence.length && sequence.getbyte(index) == 49
          image.fill_rect(x + run_start * module_width, y,
                          (index - run_start) * module_width, height, dark)
        end
      end
      private_class_method :draw_bars

      def positive_integer(value, name)
        unless value.is_a?(Integer) && value > 0
          raise ArgumentError, "#{name} must be a positive integer"
        end
        value
      end
      private_class_method :positive_integer

      def nonnegative_integer(value, name)
        unless value.is_a?(Integer) && value >= 0
          raise ArgumentError, "#{name} must be a non-negative integer"
        end
        value
      end
      private_class_method :nonnegative_integer
    end

    module_function

    def encode(data)
      Code128.encode(data)
    end

    def generate(image, data, **options)
      Code128.generate(image, data, **options)
    end

    def create(data, **options)
      Code128.create(data, **options)
    end

    Code128B = Code128
  end
end
