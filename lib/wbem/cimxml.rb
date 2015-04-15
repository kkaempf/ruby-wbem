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

module Sfcc
  module Cim
    class ObjectPath
      def keys
        res = []
        each_key { |key,value| res << key }
        res
      end
    end
  end
end

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
    begin
      product = nil
      { "sfcb" => [ "root/interop", "CIM_ObjectManager" ],
        "pegasus" => [ "root/PG_Internal", "PG_ConfigSetting" ]
      }.each do |cimom, op|
        obj = objectpath *op
        @client.instances(obj).each do |inst|
          product = inst.Description || cimom
          break
        end
        break if product
      end
    rescue Sfcc::Cim::ErrorInvalidClass, Sfcc::Cim::ErrorInvalidNamespace
      raise "Unknown CIMOM"
    end
    product
  end

public

  #
  # parse ObjectPath to Sfcc::Cim::ObjectPath
  # 1. root/cimv2:Linux_ComputerSystem.CreationClassName="Linux_ComputerSystem",Name="foo.bar"
  # 2. localhost:5989/root/cimv2:Linux_ComputerSystem.CreationClassName="Linux_ComputerSystem",Name="heron.suse.de"
  #
  #
  def self.parse_object_path s
    op = nil
    front, values = s.split(".",2)
    STDERR.puts "self.parse_object_path >#{front}<(#{values})"
    frontargs = front.split(":")
    if frontargs.size == 2
      # case 1 above
      namespace, classname = frontargs
      op = Sfcc::Cim::ObjectPath.new(namespace, classname)
    elsif frontargs.size == 3
      host, port_and_namespace, classname = frontargs
      port, namespace = port_and_namespace.split("/", 2)
      op = Sfcc::Cim::ObjectPath.new(namespace, classname)      
    else
      raise "CimxmlClient.parse_object_path: Can't parse >#{frontargs.inspect}<"
    end
    # add values
    while values && !values.empty?
      puts "Values >#{values.inspect}<"
      name, rest = values.split("=", 2)
      arg, values = if rest[0,1] == '"' # quoted arg
                      rest[1..-1].split(/\",?/, 2)
                    else # non-quoted arg
                      rest.split(",", 2)
                    end
      puts "name(#{name}), arg(#{arg})"
      op.add_key(name, arg)
    end
    puts "Op #{op}"
    op
  end
  #
  # Initialize a CIMXML client connection
  #
  def initialize url, auth_scheme = nil
    super url, auth_scheme
    @client = Sfcc::Cim::Client.connect( { :uri => url, :verify => false } )
    @product = _identify
  end

  #
  # return list of namespaces
  #
  def namespaces
    result = []
    each_instance( "root/interop", "CIM_Namespace" ) do |inst|
      result << inst.Name
    end
    result.uniq
  end

  #
  # Create ObjectPath from namespace, classname, and properties
  #
  def objectpath namespace, classname = nil, properties = {}
    op = Sfcc::Cim::ObjectPath.new(namespace, classname, @client)
    properties.each do |k,v|
      op.add_key k,v
    end
    op
  end

  #
  # Return instances for namespace and classname
  #
  def each_instance( namespace_or_objectpath, classname = nil )
    op = if namespace_or_objectpath.is_a? Sfcc::Cim::ObjectPath
      namespace_or_objectpath
    else
      objectpath namespace_or_objectpath, classname
    end
    begin
      @client.instances(op).each do |inst|
        yield inst
      end
    rescue Sfcc::Cim::ErrorInvalidClass, Sfcc::Cim::ErrorInvalidNamespace
    end
  end
  
  #
  # Return list of classnames for given object_path
  #
  def class_names op, deep_inheritance = false
    ret = []
    unless op.is_a? Sfcc::Cim::ObjectPath
      op = Sfcc::Cim::ObjectPath.new(op.to_s, nil) # assume namespace
    end
    flags = deep_inheritance ? Sfcc::Flags::DeepInheritance : 0
    begin
      @client.class_names(op, flags).each do |name|
	ret << name.to_s
      end
    rescue Sfcc::Cim::ErrorInvalidNamespace
    end
    ret
  end

  #
  # Return list of Wbem::EndpointReference (object pathes) for instances
  #  of namespace, classname
  # @param namespace : String or Sfcc::Cim::ObjectPath
  # @param classname : String (optional)
  # @param properties : Hash (optional)
  #
  def instance_names namespace, classname=nil, properties={}
    case namespace
    when Sfcc::Cim::ObjectPath
      objectpath = namespace
      namespace = objectpath.namespace
    else
      objectpath = objectpath namespace.to_s, classname, properties
    end
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

  #
  # Return matching Wbem::Instance for first instance
  #  matching namespace, classname, properties
  # @param namespace : String or Sfcc::Cim::ObjectPath
  # @param classname : String (optional)
  # @param properties : Hash (optional)
  #
  def get_instance namespace, classname=nil, properties={}
    case namespace
    when Sfcc::Cim::ObjectPath
      objectpath = namespace
      namespace = objectpath.namespace
    else
      objectpath = objectpath namespace.to_s, classname, properties
    end
    ret = []
    @client.get_instance(objectpath)
  end
  
  #
  # get class
  #
  def get_class namespace, classname=nil
    objectpath = case namespace
                 when Sfcc::Cim::ObjectPath
                   namespace
                 when Sfcc::Cim::Instance
                   Sfcc::Cim::ObjectPath.new(namespace.namespace, namespace.classname)
                 else
                   raise "Classname missing" unless classname
                   Sfcc::Cim::ObjectPath.new(namespace.to_s, classname.to_s)
                 end
    @client.get_class objectpath
  end

  #
  # Return associations for instance
  #
  def each_association( objectpath )
    begin
      @client.associators(objectpath).each do |assoc|
        yield assoc
      end
    rescue Sfcc::Cim::ErrorInvalidClass, Sfcc::Cim::ErrorInvalidNamespace
    end
  end
  
  #
  # get instance by objectpath
  #
  def get_by_objectpath objpath
    @client.get_instance(objpath)
  end
end # class
end # module
