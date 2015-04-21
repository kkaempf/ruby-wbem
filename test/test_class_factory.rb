$: << File.dirname(__FILE__)
require 'helper'
require 'wbem'

class TestClassFactory < Test::Unit::TestCase
  def setup
    @factory = Wbem::ClassFactory.new File.join(File.dirname(__FILE__), "wbem")
  end
  #def teardown
  #end
  def test_initialize
    assert @factory
  end
  def test_create_cim
    klass = @factory.class_for "CIM_ManagedElement"
    assert klass
    assert klass.new(nil,nil).is_a? Wbem::CIM_ManagedElement
  end
  def test_create_ips
    klass = @factory.class_for "IPS_KVMRedirectionSettingData"
    assert klass
    assert klass.new(nil,nil).is_a? Wbem::IPS_KVMRedirectionSettingData
  end
end
