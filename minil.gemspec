#
# minil.gemspec
#
lib = File.expand_path('../lib/', __FILE__)
$:.unshift lib unless $:.include?(lib)

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

  s.require_path = 'lib'
  s.files = ["README.md", "CHANGELOG.md"] +
            Dir.glob('lib/**/*') +
            Dir.glob('spec/**/*') +
            Dir.glob('ext/**/*') +
            Dir.glob('test/**/*')
end
