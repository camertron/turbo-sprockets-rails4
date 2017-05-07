$:.unshift File.join(File.dirname(__FILE__), 'lib')
require 'turbo-sprockets/version'

Gem::Specification.new do |s|
  s.name     = 'turbo-sprockets-rails4'
  s.version  = ::TurboSprockets::VERSION
  s.authors  = ['Cameron Dutro']
  s.email    = ['camertron@gmail.com']
  s.homepage = 'http://github.com/camertron'

  s.description = s.summary = 'Speed up asset precompliation by compiling assets in parallel.'

  s.platform = Gem::Platform::RUBY
  s.has_rdoc = true

  s.add_dependency 'parallel', '~> 1.0'
  s.add_dependency 'railties', '>= 4', '< 5'
  s.add_dependency 'sprockets', '~> 3.0'

  s.require_path = 'lib'
  s.files = Dir['{lib,spec}/**/*', 'Gemfile', 'README.md', 'Rakefile', 'turbo-sprockets-rails4.gemspec']
end
