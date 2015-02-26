$: << File.dirname(__FILE__)
require 'helper'
require 'wbem'

class TestEpr < Test::Unit::TestCase
  def show instance
    assert instance
    puts instance
  end
  #def setup
  #end
  #def teardown
  #end
  def test_epr_winrm
    c = Wbem::Client.connect("http://wsman:secret@wsman2003sp2.suse.de:5985", :wsman, :basic)
    assert c
    show c.profiles
  end
  def test_epr_iamt
    c = Wbem::Client.connect("http://admin:P4ssw0rd!@10.160.64.28:16992", :wsman, :digest)
    assert c
    c.systems.each do |epr|
      show c.get(epr)
      show c.get(epr.to_s)
    end
  end
end
