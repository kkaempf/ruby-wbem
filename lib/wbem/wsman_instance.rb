
module WsmanInstance

  require "wbem/wbem"
  require "openwsman"
  require "cim"
    #
    # Class constructor
    #   client - client instance, used for method invocation
    #            either a Wbem::CimxmlClient
    #            or a Wbem::WsmanClient
    #
    #   instance_ref - instance reference
    #                  either ObjectPath (Wbem::CimxmlClient) or
    #                  EndPointReference (Wbem::WsmanClient)
    #
    #   instance_data - instance data
    #                   Wbem::WsmanClient: Openwsman::XmlNode
    #                   Wbem::CimxmlClient: nil (instance_ref has all information)
    #
    def wsman_initialize client, epr_or_uri, node
#      STDERR.puts "Wbem::WsmanInstance.new epr_or_uri #{epr_or_uri}"
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
#        STDERR.puts "Wsman::Instance #{node}"
        yield [ node.name, node.text ]
      end
    end
    #
    # access attribute by name
    #
    def [] name
      name = name.to_s
      node = @node.find(nil, name) rescue nil
      return nil unless node
      begin
        type = _typemap()[name]
      rescue
        raise "Property #{name} of #{self.class} has unknown type"
      end
#      puts "#{self.class}[#{name}]: #{node.name}<#{type.inspect}>"
      Wbem::Conversion.to_ruby type, node
    end
    #
    # to_s - stringify
    #
    def to_s
      s = "#{@epr.classname}\n"
      @node.each do |child|
        s << "\t" << child.name << ": " 
        v = self[child.name]
        s << v.to_s if v
        s << "\n"
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
#      STDERR.puts "#{__FILE__}: #{self.class}#invoke #{name}<#{type}>(#{args.inspect})"
      result_type = type.shift
      argsin = {}
      argsout = {}
      loop do
        break if args.empty?
        if type.empty?
          raise "Excess argument '#{args.shift}' at pos #{argsin.size + argsout.size + 1} in call to #{self.class}.#{name}"
        end
        argname, argtype, direction = type.shift
        value = args.shift
        case direction
        when :in
          argsin[argname] = Wbem::Conversion.from_ruby( argtype, value )
        when :out
          unless value.nil? || value.is_a?(:symbol)
            raise "Argument '#{argname}' of #{self.class}.#{name} is 'out', pass nil to symbol instead of value"
          end
          argsout[argname] = value
        else
          raise "Arg #{argname} of #{self.class}.#{name} has bad direction #{direction.inspect}"
        end
      end
      STDERR.puts "\tproperties #{argsin.inspect}" if Wbem.debug
      STDERR.puts "\targsout #{argsout.inspect}" if Wbem.debug
      options = Openwsman::ClientOptions.new
      options.set_dump_request if Wbem.debug
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
  
    #
    # method_missing
    #   needs to be here to access TYPEMAP
    #
    def method_missing name, *args
#      STDERR.puts "Wbem::WsmanInstance.method_missing #{name}"
      # http://stackoverflow.com/questions/8960685/ruby-why-does-puts-call-to-ary
      raise NoMethodError if name == :to_ary
      name = name.to_s
      assign = false
      if name[-1,1] == '=' # assignment
        name = name[0...-1]
        assign = true
      end
      type = _typemap[name]
      if type.is_a? Array
        invoke(name, type, args)
      else
        return nil unless type # unknown property
        if assign
          # property assignment
          self[name] = Wbem::Conversion.from_ruby type, args[0]
        else
          # property read
          value = self[name]
          Wbem::Conversion.to_ruby type, value
        end
      end
    end # method_missing
end # module WsmanInstance