$: << File.dirname(__FILE__)
require 'helper'
require 'wbem'

class TestNamespaces < Test::Unit::TestCase
  #def setup
  #end
  #def teardown
  #end
  def test_namespaces_cimxml
    c = Wbem::Client.connect("https://wsman:secret@localhost:5989", :cimxml)
    assert c
    ns = c.namespaces
    assert ns
    assert ns.size > 0
    puts ns.inspect
  end
  def xtest_namespaces_winrm
    c = Wbem::Client.connect("http://wsman:secret@wsman2003sp2.suse.de:5985", :wsman, :basic)
    assert c
    ns = c.namespaces
    assert ns
    assert ns.size > 0
    puts ns.inspect
  end
end
