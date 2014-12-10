[![Build Status](https://travis-ci.org/IceDragon200/ruby-minil.svg?branch=master)](https://travis-ci.org/IceDragon200/ruby-minil)
[![Code Climate](https://codeclimate.com/github/IceDragon200/ruby-minil/badges/gpa.svg)](https://codeclimate.com/github/IceDragon200/ruby-minil)
[![Test Coverage](https://codeclimate.com/github/IceDragon200/ruby-minil/badges/coverage.svg)](https://codeclimate.com/github/IceDragon200/ruby-minil)
# Minil (Minimal Image Library)

A small Image loading/saving ruby extension

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
require 'minil'

img = Image.load_file('my_image.png')
img.get_pixel(0, 0)
img.set_pixel(0, 0, 0xFFFFFFFF)
```
