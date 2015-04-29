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
require "cim"

class AuthError < StandardError
end

module Openwsman
  class Transport
    def Transport.auth_request_callback( client, auth_type )
      STDERR.puts "\t *** Transport.auth_request_callback"
      return nil
    end
  end
  #
  # Capture Fault as Exception
  #
  class Exception < ::RuntimeError
    def initialize fault
      unless fault.is_a? Openwsman::Fault
        raise "#{fault} is not a fault" unless fault.fault?
        fault = Openwsman::Fault.new fault
      end
      @fault = fault
    end
    def to_s
      "Fault code #{@fault.code}, subcode #{@fault.subcode}" +
      "\n\treason \"#{@fault.reason}\"" +
      "\n\tdetail \"#{@fault.detail}\""
    end
  end
  #
  # Capture namespace, classname, and properties as ObjectPath
  #
  class ObjectPath
    attr_reader :namespace, :classname, :properties
    def initialize namespace, classname = nil, properties = {}
      @namespace = namespace
      @classname = classname
      @properties = properties
    end
  end
  #
  # Provide Cim::ObjectPath like accessors for EndPointReference
  #
  class EndPointReference
    alias :keys :selector_names
    alias :key_count :selector_count
    alias :add_key :add_selector
    def each_key
      keys.each { |key| yield key }
    end
  end
end


module Wbem

  #
  # Capture XmlDoc + WsmanClient as Instance
  #
  class Instance
    def initialize client, epr_or_uri, node
#      STDERR.puts "Wsman::Instance.new epr_or_uri #{epr_or_uri}"
      @node = node.body.child rescue node
#      STDERR.puts "Wsman::Instance.new @node #{@node.class}"
      @epr = (epr_or_uri.is_a? Openwsman::EndPointReference) ? epr_or_uri : Openwsman::EndPointReference.new(epr_or_uri) if epr_or_uri
      @client = client
    end
    def classname
      @epr.classname
    end
    #
    # attribute iterator
    #
    def attributes
      @node.each do |node|
        STDERR.puts "Wsman::Instance #{node}"
        yield [ node.name, node.text ]
      end
    end
    #
    # access attribute by name
    #
    def [] name
      @node.find(nil, name.to_s).text rescue nil
    end
    #
    # to_s - stringify
    #
    def to_s
      s = ""
      @node.each do |child|
        s << "\t" << child.name << ": " << child.text << "\n"
      end
      s
    end
    #
    # Instance#invoke
    #   name => String
    #   type => [ :uint32, 
    #             [ "RequestedState", :uint16, :in ],
    #             [ "Job", :class, :out ],
    #             [ "TimeoutPeriod", :dateTime, :in ],
    #           ]
    #   args => Array
    #
    def invoke name, type, args
      STDERR.puts "#{__FILE__}: #{self.class}#invoke #{name}<#{type}>(#{args.inspect})"
      result_type = type.shift
      argsin = {}
      argsout = {}
      while !type.empty?
        argname, argtype, direction = type.shift
        value = args.shift
        case direction
        when :in
          argsin[argname] = Wbem::Conversion.from_ruby( argtype, value )
        when :out
          argsout[argname] = value
        else
          raise "Arg #{argname} of #{self.class}.#{name} has bad direction #{direction.inspect}"
        end
      end
      STDERR.puts "\tproperties #{argsin.inspect}" if Wbem.debug
      STDERR.puts "\targsout #{argsout.inspect}" if Wbem.debug
      options = Openwsman::ClientOptions.new
      options.set_dump_request
      options.properties = argsin
      @epr.each do |k,v|
        options.add_selector( k, v )
      end
      STDERR.puts "\tinvoke" if Wbem.debug
      res = @client.client.invoke(options, @epr.resource_uri, name.to_s)
      raise "Invoke failed with: #{@client.fault_string}" unless res
      raise Openwsman::Exception.new(res) if res.fault?
      STDERR.puts "\n\tresult #{res.to_xml}\n" if Wbem.debug
      result = res.find(uri, "#{name}_OUTPUT").find(uri, "ReturnValue").text
      Wbem::Conversion.to_ruby result_type, result
    end
  end
  
class WsmanClient < WbemClient
private
  #
  # create end point reference URI
  #
  def epr_uri_for(namespace,classname)
    case @product
    when :winrm
      # winrm embeds namespace in resource URI
      Openwsman::epr_uri_for(namespace,classname) rescue "http://schema.suse.com/wbem/wscim/1/cim-schema/2/#{namespace}/#{classname}"
    else
      (Openwsman::epr_prefix_for(classname)+"/#{classname}") rescue "http://schema.suse.com/wbem/wscim/1/cim-schema/2/#{classname}"
    end
  end

  #
  # Handle client connection or protocol fault
  #
  # @return: true if fault
  #
  def _handle_fault client, result
    if result.nil?
      STDERR.puts "Client connection failed:\n\tResult code #{client.response_code}, Fault: #{client.fault_string}" if Wbem.debug
      return true
    end
    if result.fault?
      fault = Openwsman::Fault.new result
      if Wbem.debug
        STDERR.puts "Client protocol failed for (#{client})"
        STDERR.puts "\tFault code #{fault.code}, subcode #{fault.subcode}"
        STDERR.puts "\t\treason #{fault.reason}"
        STDERR.puts "\t\tdetail #{fault.detail}"
      end
      return true
    end
    false
  end
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
      STDERR.puts "Fault: #{fault.to_xml}" if Wbem.debug
      raise Openwsman::Exception.new fault
    end
#    STDERR.puts "Return #{doc.to_xml}"
    doc
  end
  #
  # Get Wbem::Instance by EndPointReference
  #
  def get_by_epr epr
    options = Openwsman::ClientOptions.new
    options.set_dump_request if Wbem.debug
    puts "***\t@client.get_from_epr #{epr.GroupComponent}"
    doc = @client.get_from_epr( options, epr )
    unless doc
      raise RuntimeError.new "Identify failed: HTTP #{@client.response_code}, Err #{@client.last_error}:#{@client.fault_string}"
    end
    puts doc.to_xml if Wbem.debug
    if doc.fault?
      raise Openwsman::Fault.new(doc).to_s
    end
    klass = @factory.class_for epr.classname
    klass.new self, epr, doc
  end

public
  attr_reader :client

  def initialize uri, auth_scheme = nil
    super uri, auth_scheme
    @url.path = "/wsman" if @url.path.nil? || @url.path.empty?
    Openwsman::debug = -1 if Wbem.debug
    STDERR.puts "WsmanClient connecting to #{uri}, auth #{@auth_scheme.inspect}" if Wbem.debug

    @client = Openwsman::Client.new @url.to_s
    raise "Cannot create Openwsman client" unless @client
    @client.transport.timeout = 5
    @client.transport.verify_peer = 0
    @client.transport.verify_host = 0
    case @auth_scheme.to_s
    when nil, ""
      @client.transport.auth_method = nil # negotiate
    when /none/i
      @client.transport.auth_method = Openwsman::NO_AUTH_STR
    when /basic/i
      @client.transport.auth_method = Openwsman::BASIC_AUTH_STR
    when /digest/i
      @client.transport.auth_method = Openwsman::DIGEST_AUTH_STR
    when /pass/i
      @client.transport.auth_method = Openwsman::PASS_AUTH_STR
    when /ntlm/i
      @client.transport.auth_method = Openwsman::NTLM_AUTH_STR
    when /gss/i
      @client.transport.auth_method = Openwsman::GSSNEGOTIATE_AUTH_STR
    else
      raise "Unknown auth_scheme #{@auth_scheme.inspect}"
    end
    @options = Openwsman::ClientOptions.new

#    STDERR.puts "auth #{@auth_scheme.inspect} -> #{@client.transport.auth_method}"

    doc = _identify
#    STDERR.puts doc.to_xml
    @protocol_version = doc.ProtocolVersion.text
    @product_vendor = doc.ProductVendor.text
    @product_version = doc.ProductVersion.text
    if Wbem.debug
      STDERR.puts "Protocol_version '#{@protocol_version}'"
      STDERR.puts "Product vendor '#{@product_vendor}'"
      STDERR.puts "Product version '#{@product_version}'"
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
    when /Microsoft/i
      @prefix = "http://schemas.microsoft.com/wbem/wsman/1/wmi/"
      if @product_version =~ /^OS:\s([\d\.]+)\sSP:\s([\d\.]+)\sStack:\s([\d\.]+)$/
        @product_version = $3
      else
        STDERR.puts "Unrecognized product version #{@product_version}"
      end
      @product = :winrm
    when /Openwsman/i
      @prefix = "http://schemas.dmtf.org/wbem/wscim/1/cim-schema/2/"
      @product = :openwsman
    when /Intel/i
      @prefix = "http://schemas.dmtf.org/wbem/wscim/1/cim-schema/2/"
      @product = :iamt
      if @product_version =~ /^AMT\s(\d\.\d)$/
        @product_version = $1
      end
    else
      STDERR.puts "Unsupported WS-Management vendor #{@product_vendor}"
      @prefix = "http://schemas.dmtf.org/wbem/wscim/1/cim-schema/2/"
      @product = :unknown
    end
    STDERR.puts "Connected to vendor '#{@product_vendor}', Version #{@product_version}" if Wbem.debug

  end

public
  #
  # return list of namespaces
  #
  def namespaces ns = "root", cn = "__Namespace"
    result = []
    each_instance( ns, cn ) do |inst|
      name = "#{ns}/#{inst.Name}"
      result << name
      result.concat namespaces name, cn
    end
    result.uniq
  end

  #
  # Create ObjectPath from namespace, classname, and properties
  #
  def objectpath namespace, classname = nil, properties = {}
    Openwsman::ObjectPath.new namespace, classname, properties
  end

  #
  # Enumerate instances
  #
  def each_instance( namespace_or_objectpath, classname = nil )
    op = if namespace_or_objectpath.is_a? Openwsman::ObjectPath
      namespace_or_objectpath
    else
      objectpath namespace_or_objectpath, classname
    end
    @options.flags = Openwsman::FLAG_ENUMERATION_OPTIMIZATION
    @options.max_elements = 999
    uri = epr_uri_for op.namespace, op.classname
    result = @client.enumerate( @options, nil, uri )
    loop do
      if _handle_fault @client, result
        break
      end
      items = result.Items rescue nil
      if items
        items.each do |inst|
          yield Wbem::Instance.new(self, uri, inst)
        end
      end
      context = result.context
      break unless context
      result = @client.pull( @options, nil, uri, context )
    end
  end

  #
  # Enumerate class names
  #
  def class_names op, deep_inheritance = false
    @options.flags = Openwsman::FLAG_ENUMERATION_OPTIMIZATION
    @options.max_elements = 999
    namespace = (op.is_a? Sfcc::Cim::ObjectPath) ? op.namespace : op
    classname = (op.is_a? Sfcc::Cim::ObjectPath) ? op.classname : nil
    case @product
    when :openwsman
      if @product_version < "2.2"
        STDERR.puts "ENUMERATE_CLASS_NAMES unsupported for #{@product_vendor} #{@product_version}, please upgrade"
        return []
      end
      method = Openwsman::CIM_ACTION_ENUMERATE_CLASS_NAMES
      uri = Openwsman::XML_NS_CIM_INTRINSIC
      @options.cim_namespace = namespace
      @options.add_selector("DeepInheritance", "True") if deep_inheritance
      result = @client.invoke( @options, uri, method )
    when :winrm
      # see https://github.com/kkaempf/openwsman/blob/master/bindings/ruby/tests/winenum.rb
      filter = Openwsman::Filter.new
      query = "select * from meta_class"
      query << " where __SuperClass is #{classname?classname:'null'}" unless deep_inheritance
      filter.wql query
      uri = "#{@prefix}#{namespace}/*"
      result = @client.enumerate( @options, filter, uri )
    else
      raise "Unsupported for WSMAN product #{@product}"
    end
    
    if _handle_fault @client, result
      return []
    end
    
    classes = []
    
    case @product
    when :openwsman
      # extract invoke result
      output = result.body[method]
      output.each do |c|
        classes << c.to_s
      end
    when :winrm
      # extract enumerate/pull result
      loop do
        output = result.Items
        output.each do |node|
          classes << node.name.to_s
        end if output
        context = result.context
        break unless context
        # get the next chunk
        result = @client.pull( @options, nil, uri, context)
        break if _handle_fault @client, result
      end
    end
    return classes
  end

  #
  # Return list of Wbem::EndpointReference (object pathes) for instances
  #  of namespace, classname
  # @param namespace : String or Sfcc::Cim::ObjectPath
  # @param classname : String (optional)
  # @param properties : Hash (optional)
  #
  def instance_names namespace, classname=nil, properties = {}
    case namespace
    when Openwsman::ObjectPath
      classname = namespace.classname
      properties = namespace.properties
      namespace = namespace.namespace
      uri = epr_uri_for(namespace,classname)
    when Openwsman::EndPointReference
      namespace.each do |k,v|
        properties[k] = v
      end
      classname = namespace.classname
      uri = namespace.resource_uri
      namespace = namespace.namespace
    else
      uri = epr_uri_for(namespace, classname)
    end
    @options.flags = Openwsman::FLAG_ENUMERATION_ENUM_EPR | Openwsman::FLAG_ENUMERATION_OPTIMIZATION
    @options.max_elements = 999
    @options.cim_namespace = namespace if @product == :openwsman
    @options.set_dump_request if Wbem.debug
    @options.selectors = properties unless properties.empty?
    start = Time.now
    STDERR.puts "instance_names enumerate (#{uri})" if Wbem.debug
    result = @client.enumerate( @options, nil, uri )
    names = []
    loop do
      if _handle_fault @client, result
        break
      end
      items = result.Items
      if items
        # expect <n:Item><a:EndpointReference>...
        items.each do |epr|
          names << Openwsman::EndPointReference.new(epr)
        end
      end
      context = result.context
      break unless context
      result = @client.pull( @options, nil, uri, context )
    end
    STDERR.puts "Enumerated #{names.size} items in #{Time.now-start} seconds" if Wbem.debug
    return names
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
    when Openwsman::ObjectPath
      classname = namespace.classname
      properties = namespace.properties
      namespace = namespace.namespace
      uri = epr_uri_for(namespace, classname)
    when Openwsman::EndPointReference
      namespace.each do |k,v|
        properties[k] = v
      end
      classname = namespace.classname
      uri = namespace.resource_uri
      namespace = namespace.namespace
    else
      uri = epr_uri_for(namespace, classname)
    end
    @options.set_dump_request if Wbem.debug
    @options.cim_namespace = namespace if @product == :openwsman
    @options.selectors = properties unless properties.empty?
    STDERR.puts "@client.get(namepace '#{@options.cim_namespace}', props #{properties.inspect}, uri #{uri}" if Wbem.debug
    res = @client.get(@options, uri)
    raise Openwsman::Exception.new res if res.fault?
    Wbem::Instance.new self, Openwsman::EndPointReference.new(uri, "", properties), res
  end

end # class WsmanClient
end # module Wbem
