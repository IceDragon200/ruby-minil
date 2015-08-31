$:.unshift(File.expand_path("../lib", File.dirname(__FILE__)))
require 'minil/image'
require 'minil/color'
require 'minil/color/blender'
require 'minil/image/ruby_functions'
require 'minil/layout/gauges'
require 'minil/rect'
require 'fileutils'

def save_image(image, filename)
  dirname = File.join(File.dirname(__FILE__), 'out')
  FileUtils.mkdir_p(dirname)
  image.save_file(File.join(dirname, filename))
end
