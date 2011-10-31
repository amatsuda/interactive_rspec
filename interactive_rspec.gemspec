# -*- encoding: utf-8 -*-
$:.push File.expand_path('../lib', __FILE__)
require 'interactive_rspec/version'

Gem::Specification.new do |s|
  s.name        = 'interactive_rspec'
  s.version     = InteractiveRspec::VERSION
  s.authors     = ['Akira Matsuda']
  s.email       = ['ronnie@dio.jp']
  s.homepage    = 'https://github.com/amatsuda/interactive_rspec'
  s.summary     = %q{RSpec on IRB}
  s.description = %q{RSpec on IRB}

  s.rubyforge_project = 'interactive_rspec'

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ['lib']

  # specify any dependencies here; for example:
  s.add_runtime_dependency 'rspec'
end
