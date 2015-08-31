#!/usr/bin/env bash
rm -vrf sample/out
bundle exec ruby sample/color_blender_test.rb
bundle exec ruby sample/color_palettize.rb
bundle exec ruby sample/image_alpha_blit.rb
bundle exec ruby sample/image_blit.rb
bundle exec ruby sample/image_create.rb
bundle exec ruby sample/image_fill_rect.rb
bundle exec ruby sample/image_mirror.rb
bundle exec ruby sample/image_rotate.rb
bundle exec ruby sample/layout_gauge.rb
