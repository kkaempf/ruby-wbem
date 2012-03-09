$: << File.dirname(__FILE__)
require 'helper'
require 'wbem'

class TestSystems < Test::Unit::TestCase
  #def setup
  #end
  #def teardown
  #end
  def test_systems_cimxml
    c = Wbem::Client.connect("https://wsman:secret@localhost:5989", :cimxml)
    assert c
    names = c.systems
    assert names
    assert names.size > 0
    puts "test_systems_cimxml: #{names.size} systems"
  end
  def test_systems_winrm
    c = Wbem::Client.connect("http://wsman:secret@wsman2003sp2.suse.de:5985", :wsman, :basic)
    assert c
    names = c.systems
    assert names
    assert names.size > 0
    puts "test_systems_winrm: #{names.size} systems"
  end
end
