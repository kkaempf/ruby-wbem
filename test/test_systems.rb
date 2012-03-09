$: << File.dirname(__FILE__)
require 'helper'
require 'wbem'

class TestSystems < Test::Unit::TestCase
  def show systems
    assert systems
    assert systems.size > 0
    puts "test_systems_cimxml: #{systems.size} systems"
    systems.each do |system|
      puts "ns #{system.namespace}, class #{system.classname}, Name #{system.name}"
    end
  end
  #def setup
  #end
  #def teardown
  #end
  def test_systems_cimxml
    c = Wbem::Client.connect("https://wsman:secret@localhost:5989", :cimxml)
    assert c
    show c.systems
  end
  def test_systems_winrm
    c = Wbem::Client.connect("http://wsman:secret@wsman2003sp2.suse.de:5985", :wsman, :basic)
    assert c
    show c.systems
  end
end
