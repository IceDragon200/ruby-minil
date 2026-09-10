[![Build Status](https://travis-ci.org/IceDragon200/ruby-minil.svg?branch=master)](https://travis-ci.org/IceDragon200/ruby-minil)
[![Code Climate](https://codeclimate.com/github/IceDragon200/ruby-minil/badges/gpa.svg)](https://codeclimate.com/github/IceDragon200/ruby-minil)
[![Test Coverage](https://codeclimate.com/github/IceDragon200/ruby-minil/badges/coverage.svg)](https://codeclimate.com/github/IceDragon200/ruby-minil)
# Minil (Minimal Image Library)

A small image loading, manipulation, and generation Ruby extension.

File Extensions supported:
```
.png
.tga
.bmp
```

Minil can only load ARGB32 non-indexed images, as it uses the stb_image library
underneath.

Usage:
```ruby
require 'minil/image'

img = Minil::Image.load_file('my_image.png')
img.get_pixel(0, 0)
img.set_pixel(0, 0, 0xFFFFFFFF)
```

## AI Disclosure

Agentic coding was used to locate and fix defects present in versions prior to 0.24.0.

If you are against using AI modified, or generated code, 0.23.0 remains available, but will not be fixed.

That is all.

## QR codes

Minil includes a dependency-free QR Code Model 2 encoder. It supports versions
1 through 40, error correction levels L/M/Q/H, and numeric, alphanumeric, byte,
and Kanji modes.

```ruby
require 'minil/qrcode'

image = Minil::QrCode.create('https://example.com',
                             error_correction: :m,
                             module_size: 4)
image.save_file('qrcode.png')

# Or render into an existing image. The largest integer module size that fits
# is selected automatically.
canvas = Minil::Image.create(256, 256)
Minil::QrCode.generate(canvas, 'HELLO WORLD')
```

Use `Minil::QrCode.encode` when you need the unscaled Boolean module matrix.
The default four-module quiet zone follows the QR Code specification.

## Code 128 barcodes

The imported barcode encoder supports Code 128 subset B (bytes `0x20..0x7F`):

```ruby
require 'minil/barcode'

image = Minil::Barcode::Code128.create('Hello',
                                       module_width: 2,
                                       bar_height: 48)
image.save_file('barcode.png')
```
