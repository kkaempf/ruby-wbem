$: << File.dirname(__FILE__)
require 'helper'

class TestLoading < Test::Unit::TestCase
  #def setup
  #end
  #def teardown
  #end
  def test_loading
    require 'wbem'
  end
end

