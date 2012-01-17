#
# wbem/wbem.rb
# WbemClient implementation for ruby-wbem
#
# Copyright (c) SUSE Linux Products GmbH 2011
# Written by Klaus Kämpf <kkaempf@suse.de>
#
# Licensed under the MIT license
#
module Wbem
  #
  # WbemClient - base class for CimxmlClient and WsmanClient
  #
  class WbemClient
    require 'uri'

    attr_reader :url, :response
    attr_reader :product

    def initialize url
      @url = (url.is_a? URI) ? url : URI.parse(url)
    end

    def response_code
      @client.response_code
    end

    def fault_string
      @client.fault_string
    end

    def objectpath namespace, classname
      raise "#{self.class}.objectpath not implemented"
    end

private
    def _namespaces ns, cn
      result = nil
      each_instance( ns, cn ) do |inst|
        result ||= [ns]
        name = "#{ns}/#{inst.Name}"
        unless result.include? name
          result << name
          result.concat(_namespaces name, cn)
        end
      end
      result || []
    end
public
    # return list of namespaces
    def namespaces
      STDERR.puts "Namespaces for #{@url}"
      result = []
      ['root', 'Interop', 'interop'].each do |ns|
        ["CIM_Namespace", "__Namespace", "__NAMESPACE"].each do |cn|
          result.concat(_namespaces ns, cn)
        end
      end
      result.uniq
    end

    # return list of classnames for namespace ns
    def classnames ns, deep_inheritance=false
      raise "#{self.class}.classnames not implemented"
    end
  
    def instance_names classname
      raise "#{self.class}.instance_names not implemented"
    end
  end # Class
end # Module
