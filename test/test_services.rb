$: << File.dirname(__FILE__)
require 'helper'
require 'wbem'

class Testservices < Test::Unit::TestCase
  def show services
    assert services
    assert services.size > 0
    puts "test_services_cimxml: #{services.size} services"
    services.each do |service|
      puts "ns #{service.namespace}, class #{service.classname}, Name #{service.Name}"
    end
  end
  #def setup
  #end
  #def teardown
  #end
  def test_services_cimxml
    c = Wbem::Client.connect("https://wsman:secret@localhost:5989", :cimxml)
    assert c
    show c.services
  end
  def test_services_winrm
    c = Wbem::Client.connect("http://wsman:secret@wsman2003sp2.suse.de:5985", :wsman, :basic)
    assert c
    show c.services
  end
  def test_services_iamt
    c = Wbem::Client.connect("http://admin:P4ssw0rd!@10.160.67.29:16992", :wsman, :digest)
    assert c
    show c.services
  end
end
