# -*- encoding: utf-8 -*-
$LOAD_PATH.unshift File.expand_path("../lib", __FILE__)
require "famili/version"

Gem::Specification.new do |s|
  s.name        = "famili"
  s.version     = Famili::Version::STRING
  s.platform    = Gem::Platform::RUBY
  s.authors     = ["niquola", "mirasrael"]
  s.homepage    = "http://github.com/niquola/famili"
  s.summary     = "famili-#{Famili::Version::STRING}"
  s.description = "Yet another object mother pattern implementation."

  s.files            = `git ls-files -- lib/*`.split("\n")
  s.test_files       = `git ls-files -- {spec,features}/*`.split("\n")
  s.bindir           = 'exe'
  s.executables      = `git ls-files -- exe/*`.split("\n").map{ |f| File.basename(f) }
  s.rdoc_options     = ["--charset=UTF-8"]
  s.require_path     = "lib"
end