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
  s.add_dependency("sfcc", [">= 0.3.1"])
  s.add_dependency("openwsman", [">= 0.3.2"])

  s.files        = Dir.glob("lib/**/*.rb") + %w(CHANGELOG.rdoc README.rdoc)
  s.require_path = 'lib'

  s.post_install_message = <<-POST_INSTALL_MESSAGE
  ____
/@    ~-.
\/ __ .- | remember to have fun! 
 // //  @  

  POST_INSTALL_MESSAGE
end
