$: << File.dirname(__FILE__)
require 'helper'
require 'wbem'

class TestSystems < Test::Unit::TestCase
  def show systems
    assert systems
    assert systems.size > 0
    puts "test_systems_cimxml: #{systems.size} systems"
    systems.each do |system|
      puts "**>#{system}<**"
#      puts "ns #{system.namespace}, class #{system.classname}, Name #{system.Name}"
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
  def test_profiles_iamt
    c = Wbem::Client.connect("http://admin:P4ssw0rd!@10.160.64.28:16992", :wsman, :digest)
    assert c
    show c.systems
  end
end
