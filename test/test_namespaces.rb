$: << File.dirname(__FILE__)
require 'helper'
require 'wbem'

class TestNamespaces < Test::Unit::TestCase
  #def setup
  #end
  #def teardown
  #end
  def test_namespaces_cimxml
    c = Wbem::Client.connect("http://wsman:secret@localhost:5988", :cimxml)
    assert c
    ns = c.namespaces
    assert ns
    assert ns.size > 0
    puts ns.inspect
  end
  def test_namespaces_winrm
    c = Wbem::Client.connect("http://wsman:secret@wsman2003sp2.suse.de:5985", :wsman)
    assert c
    ns = c.namespaces
    assert ns
    assert ns.size > 0
    puts ns.inspect
  end
end
