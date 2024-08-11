#
# minil.gemspec
#
require 'date'
require_relative 'lib/minil/version'

Gem::Specification.new do |s|
  s.name        = 'minil'
  s.summary     = 'Mini Image Library'
  s.description = 'A premitive and simple image library'
  s.homepage    = 'https://github.com/IceDragon200/minil'
  s.version     = Minil::Version::STRING
  s.platform    = Gem::Platform::RUBY
  s.date        = Time.now.to_date.to_s
  s.license     = 'MIT'
  s.authors     = ['Corey Powell']
  s.email       = 'mistdragon100@gmail.com'

  s.add_development_dependency 'rake',          '>= 11.0'
  s.add_development_dependency 'rspec',         '~> 3.10'
  s.add_development_dependency 'rake-compiler', '~> 1.2'

  s.require_path = 'lib'
  s.extensions = [
    'minil_ext/extconf.rb'
  ]
  s.files = ['CHANGELOG.md', 'README.md'] +
            Dir.glob('lib/**/*.rb') +
            Dir.glob('spec/**/*.rb') +
            Dir.glob('ext/**/*.{c,h,rb}') +
            Dir.glob('test/**/*.rb')
end
