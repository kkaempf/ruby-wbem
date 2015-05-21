# -*- encoding: utf-8 -*-
lib = File.expand_path('../lib/', __FILE__)
$:.unshift lib unless $:.include?(lib)
require "wbem/version"

Gem::Specification.new do |s|
  s.name        = "wbem"
  s.version     = Wbem::VERSION
  s.platform    = Gem::Platform::RUBY
  s.authors     = ["Klaus Kämpf"]
  s.email       = ["kkaempf@suse.de"]
  s.homepage    = "http://www.github.com/kkaempf/ruby-wbem"
  s.summary = "WBEM client for Ruby based on ruby-sfcc and openwsman"
  s.description = "ruby-wbem allows to access a CIMOM transparently through CIM/XML or WS-Management"

  s.required_rubygems_version = ">= 1.3.6"
  s.add_development_dependency("yard", [">= 0.5"])
  s.add_dependency("sfcc", [">= 0.4.1"])
  s.add_dependency("openwsman", [">= 2.5.0"])
  s.add_dependency("cim", [">= 1.4.2"])
  s.add_dependency("mof", [">= 1.2.4"])

  s.files         = `git ls-files`.split("\n")
  s.files.reject! { |fn| fn == '.gitignore' }
  s.require_path = 'lib'
  s.extra_rdoc_files    = Dir['README.rdoc', 'CHANGES.rdoc', 'MIT-LICENSE']
  s.test_files    = `git ls-files -- test/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }

  s.post_install_message = <<-POST_INSTALL_MESSAGE
  ____
/@    ~-.
\/ __ .- | remember to have fun! 
 // //  @  

  POST_INSTALL_MESSAGE
end
