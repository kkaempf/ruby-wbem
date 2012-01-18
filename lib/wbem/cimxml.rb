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

  def initialize url
    super url
    @client = Sfcc::Cim::Client.connect url
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
  def classnames namespace, deep_inheritance = false
    STDERR.puts "#{@client}.classnames(#{namespace})"
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
  # Return list of instance_names (object pathes) for given objectpath
  #
  def instance_names objectpath
    STDERR.puts "#{@client}.instance_names(#{objectpath})"
    ret = []
    begin
      @client.instance_names(objectpath).each do |path|
	ret << path
      end
    rescue Sfcc::Cim::ErrorInvalidClass, Sfcc::Cim::ErrorInvalidNamespace
    end
    ret
  end
end # class
end # module
