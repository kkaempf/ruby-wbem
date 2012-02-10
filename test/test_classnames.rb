$: << File.dirname(__FILE__)
require 'helper'
require 'wbem'

class TestClassnames < Test::Unit::TestCase
  #def setup
  #end
  #def teardown
  #end
  def test_classnames_cimxml
    c = Wbem::Client.connect("http://wsman:secret@localhost:5988", :cimxml)
    assert c
    names = c.class_names "root/cimv2"
    assert names
    assert names.size > 0
    puts "test_classnames_cimxml: #{names.size} classes"
  end
  def test_classnames_openwsman
    c = Wbem::Client.connect("http://wsman:secret@localhost:5985", :wsman)
    assert c
    names = c.class_names "root/cimv2"
    assert names
    assert names.size > 0
    puts "test_classnames_openwsman: #{names.size} classes"
  end
  def test_classnames_openwsman_deep
    c = Wbem::Client.connect("http://wsman:secret@localhost:5985", :wsman)
    assert c
    names = c.class_names "root/cimv2", true
    assert names
    assert names.size > 0
    puts "test_classnames_openwsman_deep: #{names.size} classes"
  end
  def test_classnames_winrm
    c = Wbem::Client.connect("http://wsman:secret@wsman2003sp2.suse.de:5985", :wsman)
    assert c
    names = c.class_names "root/cimv2"
    assert names
    assert names.size > 0
    puts "test_classnames_winrm: #{names.size} classes"
  end
  def test_classnames_winrm_deep
    c = Wbem::Client.connect("http://wsman:secret@wsman2003sp2.suse.de:5985", :wsman)
    assert c
    names = c.class_names "root/cimv2", true
    assert names
    assert names.size > 0
    puts "test_classnames_winrm_deep: #{names.size} classes"
  end
end
