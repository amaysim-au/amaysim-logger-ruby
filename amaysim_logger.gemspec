# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'amaysim_logger/version'

Gem::Specification.new do |gem|
  gem.name          = 'amaysim_logger'
  gem.version       = AmaysimLogger::VERSION
  gem.authors       = ['Daniel Deng']
  gem.email         = ['daniel.deng@amaysim.com.au']

  gem.summary       = 'A common logger gem for various amaysim projects'
  gem.description   = gem.summary
  gem.homepage      = 'https://www.amaysim.com.au'

  # Prevent pushing this gem to RubyGems.org by setting 'allowed_push_host', or
  # delete this section to allow pushing this gem to any host.
  if gem.respond_to?(:metadata)
    gem.metadata['allowed_push_host'] = 'Nah'
  else
    raise 'RubyGems 2.0 or newer is required to protect against public gem pushes.'
  end

  gem.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features|tasks)/}) }
  gem.bindir        = 'exe'
  gem.executables   = gem.files.grep(%r{^exe/}) { |f| File.basename(f) }
  gem.require_paths = ['lib']

  gem.add_runtime_dependency 'activesupport'
  gem.add_runtime_dependency 'request_store', '~> 1.3'

  gem.add_development_dependency 'actionpack'
  gem.add_development_dependency 'bundler', '~> 1.13'
  gem.add_development_dependency 'rake', '~> 12.0'
  gem.add_development_dependency 'rspec', '~> 3.5'
  gem.add_development_dependency 'timecop', '~> 0.8'
  gem.add_development_dependency 'rack-test', '~> 0.6'
  gem.add_development_dependency 'simplecov', '~> 0.12'
  gem.add_development_dependency 'pry', '~> 0.10'
  gem.add_development_dependency 'rubocop', '~> 1.50'
  gem.add_development_dependency 'rubocop-rspec', '~> 1.9'
  gem.add_development_dependency 'codeclimate-test-reporter', '~> 1.0'
  gem.add_development_dependency 'tzinfo-data', '~> 1.2017'
end
