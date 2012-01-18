$: << File.dirname(__FILE__)
require 'helper'
require 'wbem'

class TestProduct < Test::Unit::TestCase
  def setup
    Wbem.debug = true
  end
  #def teardown
  #end
  def xtest_product_port_5988
    # 5988 -> http, cimxml
    c = Wbem::Client.connect("http://wsman:secret@localhost:5988")
    assert c
    assert c.is_a? Wbem::CimxmlClient
    assert c.product
    puts "#{c.url} : #{c.product}"
  end
  def xtest_product_port_5985
    # 5985 -> http, wman
    c = Wbem::Client.connect("http://wsman:secret@localhost:5985")
    assert c
    assert c.is_a? Wbem::WsmanClient
    assert c.product
    puts "#{c.url} : #{c.product}"
  end
  def test_product_protocol_cimxml
    c = Wbem::Client.connect("http://wsman:secret@localhost", :cimxml)
    assert c
    assert c.is_a? Wbem::CimxmlClient
    assert c.product
    puts "#{c.url} : #{c.product}"
  end
  def xtest_product_protocol_wsman
    c = Wbem::Client.connect("http://wsman:secret@localhost", :wsman)
    assert c
    assert c.is_a? Wbem::WsmanClient
    assert c.product
    puts "#{c.url} : #{c.product}"
  end
  def xtest_product_protocol_http_cimxml
    c = Wbem::Client.connect("http://wsman:secret@localhost:5988", :cimxml)
    assert c
    assert c.is_a? Wbem::CimxmlClient
    assert c.product
    puts "#{c.url} : #{c.product}"
  end
  def xtest_product_protocol_http_wsman
    c = Wbem::Client.connect("http://wsman:secret@localhost:5985", :wsman)
    assert c
    assert c.is_a? Wbem::WsmanClient
    assert c.product
    puts "#{c.url} : #{c.product}"
  end
end

