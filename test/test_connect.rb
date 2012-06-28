$: << File.dirname(__FILE__)
require 'helper'
require 'wbem'

class TestConnect < Test::Unit::TestCase
  #def setup
  #  Wbem.debug = true
  #end
  #def teardown
  #end
  def test_connect_http_80
    assert_raise Sfcc::Cim::ErrorFailed do
      Wbem::Client.connect("http://wsman:secret@localhost")
    end
  end
  def test_connect_https_443
    assert_raise RuntimeError do
      c = Wbem::Client.connect("https://wsman:secret@localhost")
      assert c
    end
  end
  def test_connect_port_5988
    assert_raise Sfcc::Cim::ErrorFailed do
      # 5988 -> http, cimxml
      c = Wbem::Client.connect("http://wsman:secret@localhost:5988")
      assert c
      assert c.is_a? Wbem::CimxmlClient
    end
  end
  def test_connect_port_5985
    # 5985 -> http, wsman
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
    assert_raise RuntimeError do
      # 5986 -> https, wsman
      c = Wbem::Client.connect("https://wsman:secret@localhost:5986")
      assert c
      assert c.is_a? Wbem::WsmanClient
    end
  end
  def test_connect_protocol_cimxml
    c = Wbem::Client.connect("https://wsman:secret@localhost", :cimxml)
    assert c
    assert c.is_a? Wbem::CimxmlClient
  end
  def test_connect_protocol_wsman
    c = Wbem::Client.connect("http://wsman:secret@localhost", :wsman)
    assert c
    assert c.is_a? Wbem::WsmanClient
  end
  def test_connect_protocol_http_cimxml
    assert_raise Sfcc::Cim::ErrorFailed do
      c = Wbem::Client.connect("http://wsman:secret@localhost:5988", :cimxml)
      assert c
      assert c.is_a? Wbem::CimxmlClient
    end
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
    assert_raise RuntimeError do
      c = Wbem::Client.connect("https://wsman:secret@localhost:5986", :wsman)
      assert c
      assert c.is_a? Wbem::WsmanClient
    end
  end
  def test_connect_amt
    assert_raise RuntimeError do
      c = Wbem::Client.connect("http://admin:P4ssw0rd!@10.10.103.60:16992/wsman", :wsman)
      assert c
      assert c.is_a? Wbem::WsmanClient
    end
  end
end
