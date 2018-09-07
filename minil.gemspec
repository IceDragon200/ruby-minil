#
# minil.gemspec
#
lib = File.expand_path('../lib/', __FILE__)
$LOAD_PATH.unshift lib unless $LOAD_PATH.include?(lib)

require 'date'
require 'minil/version'

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

  s.add_dependency 'rake', '~> 10.4'
  s.add_dependency 'rspec', '~> 3.1'
  s.add_development_dependency 'rake-compiler',             '~> 0.9'

  s.require_path = 'lib'
  s.extensions = Dir.glob('ext/**/extconf.rb')
  s.files = ['README.md'] +
            Dir.glob('lib/**/*.rb') +
            Dir.glob('spec/**/*.rb') +
            Dir.glob('ext/**/*.{c,h,rb}') +
            Dir.glob('test/**/*.rb')
end
