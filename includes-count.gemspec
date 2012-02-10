# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "includes-count/version"

Gem::Specification.new do |s|
  s.name        = "includes-count"
  s.version     = IncludesCount::VERSION
  s.authors     = ["Santiago Palladino"]
  s.email       = ["spalladino@manas.com.ar"]
  s.homepage    = ""
  s.summary     = %q{Adds includes_count method to active record queries}
  s.description = %q{The includes_count method executes a SQL count on an association to retrieve its number of records, optionally filtered by a set of conditions.}

  s.rubyforge_project = "includes-count"

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]

  # specify any dependencies here; for example:
  # s.add_development_dependency "rspec"
  s.add_runtime_dependency "activerecord"
end
