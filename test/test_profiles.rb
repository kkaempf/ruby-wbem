$: << File.dirname(__FILE__)
require 'helper'
require 'wbem'

class TestProfiles < Test::Unit::TestCase
  def show profiles
    assert profiles
    assert profiles.size > 0
    puts "test_profiles_cimxml: #{profiles.size} profiles"
    profiles.each do |profile|
      puts "ns #{profile.namespace}, class #{profile.classname}, InstanceID #{profile.InstanceID}"
    end
  end
  #def setup
  #end
  #def teardown
  #end
  def test_profiles_cimxml
    c = Wbem::Client.connect("https://wsman:secret@localhost:5989", :cimxml)
    assert c
    show c.profiles
  end
  def test_profiles_winrm
    c = Wbem::Client.connect("http://wsman:secret@wsman2003sp2.suse.de:5985", :wsman, :basic)
    assert c
    show c.profiles
  end
  def test_profiles_iamt
    c = Wbem::Client.connect("http://admin:P4ssw0rd!@10.160.67.29:16992", :wsman, :digest)
    assert c
    show c.profiles
  end
end
