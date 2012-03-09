#
# wbem/cimxml.rb
# CimxmlClient implementation for ruby-wbem
#
# Copyright (c) SUSE Linux Products GmbH 2011
# Written by Klaus Kämpf <kkaempf@suse.de>
#
# Licensed under the MIT license
#
require "wbem/wbem"

module Wbem
class CimxmlClient < WbemClient
  require "sfcc"
private
  #
  # identify client
  # return identification string
  # on error return nil and set @response to http response code
  #
  def _identify
    # sfcb has /root/interop:CIM_ObjectManager
    sfcb_op = objectpath "root/interop", "CIM_ObjectManager"
    STDERR.puts "Looking for #{sfcb_op}"
    begin
      @client.instances(sfcb_op).each do |inst|
        @product = inst.Description
        break
      end
    rescue Sfcc::Cim::ErrorInvalidClass, Sfcc::Cim::ErrorInvalidNamespace
      # not sfcb
      raise "Unknown CIMOM"
    end
  end
public

  def initialize url, auth_scheme = nil
    super url, auth_scheme
    STDERR.puts "CIMXML.connect >#{url}<"
    @client = Sfcc::Cim::Client.connect( { :uri => url, :verify => false } )
    STDERR.puts "CIMXML.connect #{url} -> #{@client}" if Wbem.debug
    _identify
  end
  
  def objectpath namespace, classname = nil
    Sfcc::Cim::ObjectPath.new(namespace, classname)
  end

  #
  # Return instances for namespace and classname
  #
  def each_instance( ns, cn )
    op = objectpath ns, cn
    begin
      @client.instances(op).each do |inst|
        yield inst
      end
    rescue Sfcc::Cim::ErrorInvalidClass, Sfcc::Cim::ErrorInvalidNamespace
    end
  end
  
  #
  # Return list of classnames for given namespace
  #
  def class_names namespace, deep_inheritance = false
    STDERR.puts "#{@client}.class_names(#{namespace})"
    ret = []
    op = Sfcc::Cim::ObjectPath.new(namespace)
    flags = deep_inheritance ? Sfcc::Flags::DeepInheritance : 0
    begin
      @client.class_names(op,flags).each do |name|
	ret << name.to_s
      end
    rescue Sfcc::Cim::ErrorInvalidNamespace
    end
    ret
  end

  #
  # Return list of Wbem::EndpointReference (object pathes) for instances
  #  of namespace, classname
  #
  def instance_names namespace, classname
    objectpath = Sfcc::Cim::ObjectPath.new(namespace,classname)
    STDERR.puts "#{@client}.instance_names(#{objectpath})"
    ret = []
    begin
      @client.instance_names(objectpath).each do |path|
        path.namespace = namespace # add missing data
	ret << path
      end
    rescue Sfcc::Cim::ErrorInvalidClass, Sfcc::Cim::ErrorInvalidNamespace
    end
    ret
  end
end # class
end # module
