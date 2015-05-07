#
# Openwsman helper methods for wbem/wsman-instance
#

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
