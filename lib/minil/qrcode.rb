# frozen_string_literal: true

# The QR matrix construction and error-correction implementation is based in
# part on Project Nayuki's QR Code generator:
# https://www.nayuki.io/page/qr-code-generator-library
#
# Copyright (c) Project Nayuki. (MIT License)
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.

require_relative 'image'

module Minil
  # Dependency-free QR Code Model 2 encoding and rendering.
  module QrCode
    ALPHANUMERIC = '0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ $%*+-./:'.freeze

    MODES = {
      numeric:      [0x1, [10, 12, 14]],
      alphanumeric: [0x2, [9, 11, 13]],
      binary:       [0x4, [8, 16, 16]],
      kanji:        [0x8, [8, 10, 12]]
    }.each_value { |mode| mode[1].freeze; mode.freeze }.freeze

    ERROR_CORRECTION = {
      l: [0, 1],
      m: [1, 0],
      q: [2, 3],
      h: [3, 2]
    }.each_value(&:freeze).freeze

    ERROR_CORRECTION_ALIASES = {
      low: :l,
      medium: :m,
      quartile: :q,
      high: :h
    }.freeze

    ECC_CODEWORDS_PER_BLOCK = [
      [-1, 7, 10, 15, 20, 26, 18, 20, 24, 30, 18, 20, 24, 26, 30, 22, 24, 28, 30, 28, 28, 28, 28, 30, 30, 26, 28, 30, 30, 30, 30, 30, 30, 30, 30, 30, 30, 30, 30, 30, 30],
      [-1, 10, 16, 26, 18, 24, 16, 18, 22, 22, 26, 30, 22, 22, 24, 24, 28, 28, 26, 26, 26, 26, 28, 28, 28, 28, 28, 28, 28, 28, 28, 28, 28, 28, 28, 28, 28, 28, 28, 28, 28],
      [-1, 13, 22, 18, 26, 18, 24, 18, 22, 20, 24, 28, 26, 24, 20, 30, 24, 28, 28, 26, 30, 28, 30, 30, 30, 30, 28, 30, 30, 30, 30, 30, 30, 30, 30, 30, 30, 30, 30, 30, 30],
      [-1, 17, 28, 22, 16, 22, 28, 26, 26, 24, 28, 24, 28, 22, 24, 24, 30, 28, 28, 26, 28, 30, 24, 30, 30, 30, 30, 30, 30, 30, 30, 30, 30, 30, 30, 30, 30, 30, 30, 30, 30]
    ].map(&:freeze).freeze

    NUM_ERROR_CORRECTION_BLOCKS = [
      [-1, 1, 1, 1, 1, 1, 2, 2, 2, 2, 4, 4, 4, 4, 4, 6, 6, 6, 6, 7, 8, 8, 9, 9, 10, 12, 12, 12, 13, 14, 15, 16, 17, 18, 19, 19, 20, 21, 22, 24, 25],
      [-1, 1, 1, 1, 2, 2, 4, 4, 4, 5, 5, 5, 8, 9, 9, 10, 10, 11, 13, 14, 16, 17, 17, 18, 20, 21, 23, 25, 26, 28, 29, 31, 33, 35, 37, 38, 40, 43, 45, 47, 49],
      [-1, 1, 1, 2, 2, 4, 4, 6, 6, 8, 8, 8, 10, 12, 16, 12, 17, 16, 18, 21, 20, 23, 23, 25, 27, 29, 34, 34, 35, 38, 40, 43, 45, 48, 51, 53, 56, 59, 62, 65, 68],
      [-1, 1, 1, 2, 4, 4, 4, 5, 6, 8, 8, 11, 11, 16, 16, 18, 16, 19, 21, 25, 25, 25, 34, 30, 32, 35, 37, 40, 42, 45, 48, 51, 54, 57, 60, 63, 66, 70, 74, 77, 81]
    ].map(&:freeze).freeze

    Segment = Struct.new(:mode, :count, :bits)

    class BitBuffer < Array
      def append_bits(value, length)
        unless length >= 0 && value >= 0 && value < (1 << length)
          raise ArgumentError, 'bit value does not fit its requested length'
        end

        (length - 1).downto(0) { |i| self << ((value >> i) & 1) }
        self
      end
    end

    # The encoded symbol before any quiet-zone or pixel scaling is applied.
    class Code
      attr_reader :version, :error_correction, :mask, :modules

      def initialize(version, error_correction, mask, modules)
        @version = version
        @error_correction = error_correction
        @mask = mask
        @modules = modules.map { |row| row.freeze }.freeze
      end

      def size
        @modules.length
      end

      def dark?(x, y)
        return false unless x.between?(0, size - 1) && y.between?(0, size - 1)

        @modules[y][x]
      end

      def to_a
        @modules.map(&:dup)
      end
    end

    class Encoder
      MASKS = [
        ->(x, y) { (x + y).even? },
        ->(_x, y) { y.even? },
        ->(x, _y) { (x % 3).zero? },
        ->(x, y) { ((x + y) % 3).zero? },
        ->(x, y) { ((x / 3 + y / 2) % 2).zero? },
        ->(x, y) { (x * y % 2 + x * y % 3).zero? },
        ->(x, y) { ((x * y % 2 + x * y % 3) % 2).zero? },
        ->(x, y) { (((x + y) % 2 + x * y % 3) % 2).zero? }
      ].freeze

      def initialize(version, error_correction, data_codewords, requested_mask)
        @version = version
        @error_correction = error_correction
        @ecc_ordinal, @format_bits = ERROR_CORRECTION.fetch(error_correction)
        @size = version * 4 + 17
        @modules = Array.new(@size) { Array.new(@size, false) }
        @function = Array.new(@size) { Array.new(@size, false) }

        draw_function_patterns
        draw_codewords(add_ecc_and_interleave(data_codewords))
        @mask = requested_mask.nil? ? select_mask : requested_mask
        apply_mask(@mask)
        draw_format_bits(@mask)
      end

      def code
        Code.new(@version, @error_correction, @mask, @modules)
      end

      private

      def draw_function_patterns
        @size.times do |i|
          set_function(6, i, i.even?)
          set_function(i, 6, i.even?)
        end

        draw_finder(3, 3)
        draw_finder(@size - 4, 3)
        draw_finder(3, @size - 4)

        positions = alignment_positions
        positions.each_with_index do |x, xi|
          positions.each_with_index do |y, yi|
            next if [xi, yi] == [0, 0]
            next if [xi, yi] == [0, positions.length - 1]
            next if [xi, yi] == [positions.length - 1, 0]

            draw_alignment(x, y)
          end
        end

        draw_format_bits(0)
        draw_version_bits
      end

      def draw_finder(cx, cy)
        (-4..4).each do |dy|
          (-4..4).each do |dx|
            x = cx + dx
            y = cy + dy
            next unless x.between?(0, @size - 1) && y.between?(0, @size - 1)

            distance = [dx.abs, dy.abs].max
            set_function(x, y, distance != 2 && distance != 4)
          end
        end
      end

      def draw_alignment(cx, cy)
        (-2..2).each do |dy|
          (-2..2).each do |dx|
            set_function(cx + dx, cy + dy, [dx.abs, dy.abs].max != 1)
          end
        end
      end

      def alignment_positions
        return [] if @version == 1

        count = @version / 7 + 2
        step = (@version * 8 + count * 3 + 5) / (count * 4 - 4) * 2
        positions = (count - 1).times.map { |i| @size - 7 - i * step }
        (positions + [6]).reverse
      end

      def draw_format_bits(mask)
        data = @format_bits << 3 | mask
        remainder = data
        10.times { remainder = (remainder << 1) ^ ((remainder >> 9) * 0x537) }
        bits = (data << 10 | remainder) ^ 0x5412

        6.times { |i| set_function(8, i, bit?(bits, i)) }
        set_function(8, 7, bit?(bits, 6))
        set_function(8, 8, bit?(bits, 7))
        set_function(7, 8, bit?(bits, 8))
        (9...15).each { |i| set_function(14 - i, 8, bit?(bits, i)) }

        8.times { |i| set_function(@size - 1 - i, 8, bit?(bits, i)) }
        (8...15).each do |i|
          set_function(8, @size - 15 + i, bit?(bits, i))
        end
        set_function(8, @size - 8, true)
      end

      def draw_version_bits
        return if @version < 7

        remainder = @version
        12.times { remainder = (remainder << 1) ^ ((remainder >> 11) * 0x1F25) }
        bits = @version << 12 | remainder
        18.times do |i|
          a = @size - 11 + i % 3
          b = i / 3
          set_function(a, b, bit?(bits, i))
          set_function(b, a, bit?(bits, i))
        end
      end

      def set_function(x, y, dark)
        @modules[y][x] = dark
        @function[y][x] = true
      end

      def add_ecc_and_interleave(data)
        block_count = NUM_ERROR_CORRECTION_BLOCKS[@ecc_ordinal][@version]
        ecc_length = ECC_CODEWORDS_PER_BLOCK[@ecc_ordinal][@version]
        raw_count = QrCode.raw_data_modules(@version) / 8
        short_block_count = block_count - raw_count % block_count
        short_block_length = raw_count / block_count
        divisor = reed_solomon_divisor(ecc_length)
        blocks = []
        offset = 0

        block_count.times do |i|
          data_length = short_block_length - ecc_length
          data_length += 1 if i >= short_block_count
          block_data = data.slice(offset, data_length)
          offset += data_length
          ecc = reed_solomon_remainder(block_data, divisor)
          block_data = block_data + [0] if i < short_block_count
          blocks << block_data + ecc
        end

        result = []
        blocks.first.length.times do |i|
          blocks.each_with_index do |block, j|
            next if i == short_block_length - ecc_length && j < short_block_count

            result << block[i]
          end
        end
        result
      end

      def reed_solomon_divisor(degree)
        result = Array.new(degree, 0)
        result[-1] = 1
        root = 1
        degree.times do
          degree.times do |i|
            result[i] = reed_solomon_multiply(result[i], root)
            result[i] ^= result[i + 1] if i + 1 < degree
          end
          root = reed_solomon_multiply(root, 2)
        end
        result
      end

      def reed_solomon_remainder(data, divisor)
        result = Array.new(divisor.length, 0)
        data.each do |byte|
          factor = byte ^ result.shift
          result << 0
          divisor.each_with_index do |coefficient, i|
            result[i] ^= reed_solomon_multiply(coefficient, factor)
          end
        end
        result
      end

      def reed_solomon_multiply(x, y)
        product = 0
        7.downto(0) do |i|
          product = (product << 1) ^ ((product >> 7) * 0x11D)
          product ^= x if ((y >> i) & 1) == 1
        end
        product
      end

      def draw_codewords(data)
        bit_index = 0
        right = @size - 1
        while right >= 1
          column = right <= 6 ? right - 1 : right
          upward = ((column + 1) & 2).zero?
          @size.times do |vertical|
            y = upward ? @size - 1 - vertical : vertical
            2.times do |j|
              x = column - j
              next if @function[y][x] || bit_index >= data.length * 8

              @modules[y][x] = bit?(data[bit_index >> 3], 7 - (bit_index & 7))
              bit_index += 1
            end
          end
          right -= 2
        end

        raise 'internal QR data-placement error' unless bit_index == data.length * 8
      end

      def select_mask
        best_mask = nil
        best_penalty = Float::INFINITY
        8.times do |mask|
          apply_mask(mask)
          draw_format_bits(mask)
          score = penalty_score
          if score < best_penalty
            best_mask = mask
            best_penalty = score
          end
          apply_mask(mask)
        end
        best_mask
      end

      def apply_mask(mask)
        pattern = MASKS.fetch(mask)
        @size.times do |y|
          @size.times do |x|
            @modules[y][x] = !@modules[y][x] if !@function[y][x] && pattern.call(x, y)
          end
        end
      end

      def penalty_score
        score = 0
        @modules.each { |row| score += line_penalty(row) }
        @size.times { |x| score += line_penalty(@size.times.map { |y| @modules[y][x] }) }

        (@size - 1).times do |y|
          (@size - 1).times do |x|
            color = @modules[y][x]
            score += 3 if @modules[y][x + 1] == color &&
                          @modules[y + 1][x] == color &&
                          @modules[y + 1][x + 1] == color
          end
        end

        dark = @modules.inject(0) { |sum, row| sum + row.count(true) }
        total = @size * @size
        balance = ((dark * 20 - total * 10).abs + total - 1) / total - 1
        score + balance * 10
      end

      def line_penalty(line)
        score = 0
        run_color = false
        run_length = 0
        history = Array.new(7, 0)

        line.each do |color|
          if color == run_color
            run_length += 1
            score += 3 if run_length == 5
            score += 1 if run_length > 5
          else
            add_run_history(run_length, history)
            score += finder_pattern_count(history) * 40 unless run_color
            run_color = color
            run_length = 1
          end
        end

        if run_color
          add_run_history(run_length, history)
          run_length = 0
        end
        run_length += @size
        add_run_history(run_length, history)
        score + finder_pattern_count(history) * 40
      end

      def add_run_history(length, history)
        length += @size if history[0].zero?
        history.unshift(length)
        history.pop
      end

      def finder_pattern_count(history)
        unit = history[1]
        core = unit > 0 && history[2] == unit && history[3] == unit * 3 &&
               history[4] == unit && history[5] == unit
        return 0 unless core

        count = 0
        count += 1 if history[0] >= unit * 4 && history[6] >= unit
        count += 1 if history[6] >= unit * 4 && history[0] >= unit
        count
      end

      def bit?(value, index)
        ((value >> index) & 1) != 0
      end
    end

    module_function

    def encode(data, type: nil, error_correction: :l, version: nil, mask: nil)
      correction = normalize_error_correction(error_correction)
      segment = make_segment(data, type)
      selected_version = version || select_version(segment, correction)
      validate_version!(selected_version)
      validate_mask!(mask)

      required = required_bits(segment, selected_version)
      capacity = data_codewords(selected_version, correction) * 8
      if required.nil? || required > capacity
        raise ArgumentError, "data does not fit QR version #{selected_version}-#{correction.to_s.upcase}"
      end

      bits = BitBuffer.new
      mode_bits, counts = MODES.fetch(segment.mode)
      bits.append_bits(mode_bits, 4)
      bits.append_bits(segment.count, counts[(selected_version + 7) / 17])
      bits.concat(segment.bits)
      bits.append_bits(0, [4, capacity - bits.length].min)
      bits.append_bits(0, (-bits.length) % 8)
      pad = 0xEC
      while bits.length < capacity
        bits.append_bits(pad, 8)
        pad ^= 0xFD
      end

      bytes = Array.new(bits.length / 8, 0)
      bits.each_with_index { |bit, i| bytes[i >> 3] |= bit << (7 - (i & 7)) }
      Encoder.new(selected_version, correction, bytes, mask).code
    end

    def matrix(data, **options)
      encode(data, **options).to_a
    end

    def generate(image, data, type: nil, error_correction: :l, version: nil,
                 mask: nil, module_size: nil, quiet_zone: 4,
                 dark: 0xFF000000, light: 0xFFFFFFFF)
      code = encode(data, type: type, error_correction: error_correction,
                    version: version, mask: mask)
      render(image, code, module_size: module_size, quiet_zone: quiet_zone,
             dark: dark, light: light)
    end

    def create(data, type: nil, error_correction: :l, version: nil, mask: nil,
               module_size: 4, quiet_zone: 4,
               dark: 0xFF000000, light: 0xFFFFFFFF)
      unit = positive_integer(module_size, 'module_size')
      border = nonnegative_integer(quiet_zone, 'quiet_zone')
      code = encode(data, type: type, error_correction: error_correction,
                    version: version, mask: mask)
      dimension = (code.size + border * 2) * unit
      image = Minil::Image.create(dimension, dimension)
      render(image, code, module_size: unit, quiet_zone: border,
             dark: dark, light: light)
    end

    def render(image, code, module_size: nil, quiet_zone: 4,
               dark: 0xFF000000, light: 0xFFFFFFFF)
      unless image.is_a?(Minil::Image) && code.is_a?(Code)
        raise ArgumentError, 'render expects a Minil::Image and Minil::QrCode::Code'
      end

      border = nonnegative_integer(quiet_zone, 'quiet_zone')
      symbol_modules = code.size + border * 2
      unit = if module_size.nil?
               [image.width / symbol_modules, image.height / symbol_modules].min
             else
               positive_integer(module_size, 'module_size')
             end
      raise ArgumentError, 'image is too small for this QR code' if unit < 1

      pixel_size = symbol_modules * unit
      raise ArgumentError, 'QR code does not fit the image' if pixel_size > image.width || pixel_size > image.height

      origin_x = (image.width - pixel_size) / 2
      origin_y = (image.height - pixel_size) / 2
      image.fill(light)

      code.modules.each_with_index do |row, y|
        x = 0
        while x < row.length
          unless row[x]
            x += 1
            next
          end

          run_start = x
          x += 1 while x < row.length && row[x]
          image.fill_rect(origin_x + (border + run_start) * unit,
                          origin_y + (border + y) * unit,
                          (x - run_start) * unit, unit, dark)
        end
      end
      image
    end

    def determine_version(type, data, error_correction = :l)
      select_version(make_segment(data, type), normalize_error_correction(error_correction))
    end

    def determine_type(data)
      return :binary unless data.is_a?(String)
      return :binary if data.empty?
      return :numeric if /\A[0-9]+\z/ =~ data
      return :alphanumeric if /\A[A-Z0-9 $%*+\.\/:\-]+\z/ =~ data

      :binary
    end

    def make_segment(data, requested_type)
      automatic = requested_type.nil?
      type = normalize_type(requested_type || determine_type(data))
      case type
      when :numeric
        text = String(data)
        raise ArgumentError, 'numeric QR data may only contain 0-9' unless /\A[0-9]*\z/ =~ text

        bits = BitBuffer.new
        text.scan(/.{1,3}/).each { |group| bits.append_bits(group.to_i, group.length * 3 + 1) }
        Segment.new(type, text.length, bits)
      when :alphanumeric
        text = String(data)
        unless text.each_char.all? { |character| ALPHANUMERIC.include?(character) }
          raise ArgumentError, 'alphanumeric QR data contains an unsupported character'
        end

        bits = BitBuffer.new
        characters = text.each_char.to_a
        characters.each_slice(2) do |pair|
          value = ALPHANUMERIC.index(pair[0])
          if pair.length == 2
            bits.append_bits(value * 45 + ALPHANUMERIC.index(pair[1]), 11)
          else
            bits.append_bits(value, 6)
          end
        end
        Segment.new(type, characters.length, bits)
      when :binary
        bytes = if data.is_a?(String)
                  automatic ? data.encode(Encoding::UTF_8).bytes : data.b.bytes
                else
                  Array(data)
                end
        unless bytes.all? { |byte| byte.is_a?(Integer) && byte.between?(0, 255) }
          raise ArgumentError, 'binary QR data must contain bytes in the range 0..255'
        end

        bits = BitBuffer.new
        bytes.each { |byte| bits.append_bits(byte, 8) }
        Segment.new(type, bytes.length, bits)
      when :kanji
        text = String(data)
        begin
          bytes = text.encode(Encoding::SJIS).bytes
        rescue Encoding::UndefinedConversionError, Encoding::InvalidByteSequenceError
          raise ArgumentError, 'kanji QR data must be representable as Shift_JIS double-byte characters'
        end
        raise ArgumentError, 'kanji QR data must contain only double-byte Shift_JIS characters' if bytes.length.odd?

        bits = BitBuffer.new
        bytes.each_slice(2) do |high, low|
          value = high << 8 | low
          adjusted = if value.between?(0x8140, 0x9FFC)
                       value - 0x8140
                     elsif value.between?(0xE040, 0xEBBF)
                       value - 0xC140
                     end
          unless adjusted
            raise ArgumentError, 'kanji QR data contains a character outside the QR Shift_JIS ranges'
          end
          bits.append_bits((adjusted >> 8) * 0xC0 + (adjusted & 0xFF), 13)
        end
        Segment.new(type, bytes.length / 2, bits)
      end
    end

    def normalize_type(type)
      value = type.to_s.downcase.to_sym
      value = :binary if value == :byte
      raise ArgumentError, "unsupported QR data type: #{type.inspect}" unless MODES.key?(value)

      value
    end

    def normalize_error_correction(level)
      value = level.to_s.downcase.to_sym
      value = ERROR_CORRECTION_ALIASES.fetch(value, value)
      unless ERROR_CORRECTION.key?(value)
        raise ArgumentError, "unsupported QR error correction level: #{level.inspect}"
      end

      value
    end

    def validate_version!(version)
      unless version.is_a?(Integer) && version.between?(1, 40)
        raise ArgumentError, 'QR version must be an integer in 1..40'
      end
    end

    def validate_mask!(mask)
      return if mask.nil?
      return if mask.is_a?(Integer) && mask.between?(0, 7)

      raise ArgumentError, 'QR mask must be nil or an integer in 0..7'
    end

    def select_version(segment, correction)
      (1..40).each do |version|
        required = required_bits(segment, version)
        return version if required && required <= data_codewords(version, correction) * 8
      end
      raise ArgumentError, 'data is too long for a version 40 QR code'
    end

    def required_bits(segment, version)
      _, counts = MODES.fetch(segment.mode)
      count_bits = counts[(version + 7) / 17]
      return nil if segment.count >= (1 << count_bits)

      4 + count_bits + segment.bits.length
    end

    def data_codewords(version, correction)
      ordinal = ERROR_CORRECTION.fetch(correction)[0]
      raw_data_modules(version) / 8 -
        ECC_CODEWORDS_PER_BLOCK[ordinal][version] *
        NUM_ERROR_CORRECTION_BLOCKS[ordinal][version]
    end

    def raw_data_modules(version)
      result = (16 * version + 128) * version + 64
      if version >= 2
        alignments = version / 7 + 2
        result -= (25 * alignments - 10) * alignments - 55
        result -= 36 if version >= 7
      end
      result
    end

    def positive_integer(value, name)
      unless value.is_a?(Integer) && value > 0
        raise ArgumentError, "#{name} must be a positive integer"
      end
      value
    end

    def nonnegative_integer(value, name)
      unless value.is_a?(Integer) && value >= 0
        raise ArgumentError, "#{name} must be a non-negative integer"
      end
      value
    end
  end
end
