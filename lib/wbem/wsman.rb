#
# wbem/wsman.rb
# WsmanClient implementation for ruby-wbem
#
# Copyright (c) SUSE Linux Products GmbH 2011
# Written by Klaus Kämpf <kkaempf@suse.de>
#
# Licensed under the MIT license
#
require "wbem/wbem"
require "openwsman"

class AuthError < StandardError
end

module Openwsman
  class Transport
    def Transport.auth_request_callback( client, auth_type )
      STDERR.puts "\t *** Transport.auth_request_callback"
      return nil
    end
  end
  class ObjectPath
    attr_reader :namespace, :classname
    def initialize namespace, classname = nil
      @namespace = namespace
      @classname = classname
    end
  end
end

module Wbem
class WsmanClient < WbemClient
private
  #
  # WS-Identify
  # returns Openwsman::XmlDoc
  #
  def _identify
    STDERR.puts "Identify client #{@client} with #{@options}" if Wbem.debug
    doc = @client.identify( @options )
    unless doc
      raise RuntimeError.new "Identify failed: HTTP #{@client.response_code}, Err #{@client.last_error}:#{@client.fault_string}"
    end
    if doc.fault?
      fault = doc.fault
      STDERR.puts "Fault: #{fault.to_xml}"
      raise fault.to_s
    end
#    STDERR.puts "Return #{doc.to_xml}"
    doc
  end
public

  def initialize uri
    super uri
    @url.path = "/wsman" if @url.path.nil? || @url.path.empty?
#    Openwsman::debug = -1
    STDERR.puts "WsmanClient connecting to #{uri}" if Wbem.debug

    @client = Openwsman::Client.new @url.to_s
    raise "Cannot create Openwsman client" unless @client
    @client.transport.timeout = 5
    @client.transport.verify_peer = 0
    @client.transport.verify_host = 0
    # FIXME
#    @client.transport.auth_method = (@url.scheme == 'http') ? Openwsman::BASIC_AUTH_STR : Openwsman::DIGEST_AUTH_STR
    @client.transport.auth_method = Openwsman::BASIC_AUTH_STR
    @options = Openwsman::ClientOptions.new

    doc = _identify
#    STDERR.puts doc.to_xml
    @protocol_version = doc.ProtocolVersion.text
    @product_vendor = doc.ProductVendor.text
    @product_version = doc.ProductVersion.text
    if Wbem.debug
      STDERR.puts "Protocol_version '#{@protocol_version}'"
      STDERR.puts "Product vendor '#{@product_vendor}'"
      STDERR.puts  "Product version '#{@product_version}'"
    end
    #
    # Windows winrm 2.0
    # Protocol "http://schemas.dmtf.org/wbem/wsman/1/wsman.xsd"
    # Vendor "Microsoft Corporation"
    # Version "OS: 5.2.3790 SP: 2.0 Stack: 2.0"
    #
    # Windows winrm 1.1
    # Protocol "http://schemas.dmtf.org/wbem/wsman/1/wsman.xsd"
    # Vendor "Microsoft Corporation"
    # Version "OS: 5.1.2600 SP: 3.0 Stack: 1.1"
    #
    # Openwsman 2.2
    # Protocol "http://schemas.dmtf.org/wbem/wsman/1/wsman.xsd"
    # Vendor "Openwsman Project"
    # Version "2.2"
    #

    unless @protocol_version == Openwsman::XML_NS_WS_MAN
      raise "Unsupported WS-Management protocol '#{@protocol_version}'"
    end

    case @product_vendor
    when "Microsoft Corporation"
      @prefix = "http://schemas.microsoft.com/wbem/wsman/1/wmi/"
      if @product_version =~ /^OS:\s([\d\.]+)\sSP:\s([\d\.]+)\sStack:\s([\d\.]+)$/
        @product_version = $3
      else
        STDERR.puts "Unrecognized product version #{@product_version}"
      end
      @product = :winrm
    when "Openwsman Project"
      @prefix = "http://schemas.dmtf.org/wbem/wscim/1/cim-schema/2/"
      @product = :openwsman
    else
      STDERR.puts "Unsupported WS-Management vendor #{@product_vendor}"
      @prefix = "http://schemas.dmtf.org/wbem/wscim/1/cim-schema/2/"
      @product = :unknown
    end
    STDERR.puts "Connected to vendor '#{@product_vendor}', Version #{@product_version}" if Wbem.debug

  end

  def objectpath classname, namespace
    Openwsman::ObjectPath.new classname, namespace
  end

  def each_instance( ns, cn )
    @options.flags = Openwsman::FLAG_ENUMERATION_OPTIMIZATION
    @options.max_elements = 999
    resource = "#{@prefix}#{ns}/#{cn}"
    result = @client.enumerate( @options, nil, resource )
    return unless result
#    STDERR.puts "Result '#{result.to_xml}'"
    return if result.fault?
    items = result.body.EnumerateResponse.Items rescue nil
    items.each do |inst|
      yield inst
    end if items
  end

  def classnames namespace, deep_inheritance
    # enum_classnames is Openwsman-specific
    unless @product_vendor =~ /Openwsman/ && @product_version >= "2.2"
      STDERR.puts "ENUMERATE_CLASS_NAMES unsupported for #{@product_vendor} #{@product_version}"
      return []
    end
    @options.flags = Openwsman::FLAG_ENUMERATION_OPTIMIZATION
    @options.max_elements = 999
    @options.cim_namespace = namespace
    method = Openwsman::CIM_ACTION_ENUMERATE_CLASS_NAMES
    uri = Openwsman::XML_NS_CIM_INTRINSIC
    result = @client.invoke( @options, uri, method )
    if result.fault?
      puts "Enumerate class names (#{uri}) failed:\n\tResult code #{@client.response_code}, Fault: #{@client.fault_string}"
      return []
    end
    output = result.body[method]
    classes = []
    output.each do |c|
      classes << c.to_s
    end
    return classes
  end

  def instance_names object_path
    @options.flags = Openwsman::FLAG_ENUMERATION_OPTIMIZATION
    @options.max_elements = 999
    @options.cim_namespace = object_path.namespace
    # http://schemas.microsoft.com/wbem/wsman/1/wmi/root/cimv2/
    # CIM=http://schemas.dmtf.org/wbem/wscim/1/cim-schema/2
    # OpenWBEM=http://schema.openwbem.org/wbem/wscim/1/cim-schema/2
    # Linux=http://sblim.sf.net/wbem/wscim/1/cim-schema/2
    # OMC=http://schema.omc-project.org/wbem/wscim/1/cim-schema/2
    # PG=http://schema.openpegasus.org/wbem/wscim/1/cim-schema/2
    uri = "http://schemas.dmtf.org/wbem/wscim/1/cim-schema/2/"+object_path.classname
    result = @client.enumerate( @options, nil, uri )
    if result.fault?
      puts "Enumerate instances (#{uri}) failed:\n\tResult code #{@client.response_code}, Fault: #{@client.fault_string}"
      return []
    end
    output = result.body[method]
    instances = []
    output.each do |i|
      instances << i.to_s
    end
    return instances
  end
end
end # module