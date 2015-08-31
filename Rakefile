require 'rake/extensiontask'
require 'rspec/core/rake_task'

gemspec = Gem::Specification.load('minil.gemspec')

Gem::PackageTask.new(gemspec) do |pkg|
end

RSpec::Core::RakeTask.new(:spec)
Rake::ExtensionTask.new('minil_ext')

task default: :compile
