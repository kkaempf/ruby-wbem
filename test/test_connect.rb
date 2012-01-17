$: << File.dirname(__FILE__)
require 'helper'
require 'wbem'

class TestConnect < Test::Unit::TestCase
  #def setup
  #end
  #def teardown
  #end
  def test_connect_http_80
    c = Wbem::Client.connect("http://wsman:secret@localhost")
    assert c
  end
  def test_connect_https_443
    c = Wbem::Client.connect("https://wsman:secret@localhost")
    assert c
  end
  def test_connect_port_5988
    # 5988 -> http, cimxml
    c = Wbem::Client.connect("http://wsman:secret@localhost:5988")
    assert c
    assert c.is_a? Wbem::CimxmlClient
  end
  def test_connect_port_5985
    # 5985 -> http, wman
    c = Wbem::Client.connect("http://wsman:secret@localhost:5985")
    assert c
    assert c.is_a? Wbem::WsmanClient
  end
  def test_connect_port_5989
    # 5989 -> https, cimxml
    c = Wbem::Client.connect("https://wsman:secret@localhost:5989")
    assert c
    assert c.is_a? Wbem::CimxmlClient
  end
  def test_connect_port_5986
    # 5986 -> https, wman
    c = Wbem::Client.connect("https://wsman:secret@localhost:5986")
    assert c
    assert c.is_a? Wbem::WsmanClient
  end
  def test_connect_protocol_http_cimxml
    c = Wbem::Client.connect("http://wsman:secret@localhost:5988", :cimxml)
    assert c
    assert c.is_a? Wbem::CimxmlClient
  end
  def test_connect_protocol_https_cimxml
    c = Wbem::Client.connect("https://wsman:secret@localhost:5989", :cimxml)
    assert c
    assert c.is_a? Wbem::CimxmlClient
  end
  def test_connect_protocol_http_wsman
    c = Wbem::Client.connect("http://wsman:secret@localhost:5985", :wsman)
    assert c
    assert c.is_a? Wbem::WsmanClient
  end
  def test_connect_protocol_https_wsman
   c = Wbem::Client.connect("https://wsman:secret@localhost:5986", :wsman)
    assert c
    assert c.is_a? Wbem::WsmanClient
  end
end

