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
    attr_accessor :auth_scheme

    def initialize url, auth_scheme = :basic
      @url = (url.is_a? URI) ? url : URI.parse(url)
      @auth_scheme = auth_scheme.to_s.to_sym
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
    # assemble all namespaces
    def _namespaces ns, cn
      result = nil
      # each_instance is the downcall to cimxml or wsman
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
    def class_names ns, deep_inheritance=false
      raise "#{self.class}.class_names not implemented"
    end
  
    def systems ns="root/cimv2"
      instance_names ns, (@product == :winrm) ? "Win32_ComputerSystem" : "CIM_ComputerSystem"
    end
    def services ns="root/cimv2"
      instance_names ns, (@product == :winrm) ? "Win32_Service" : "CIM_Service"
    end
    def networks ns="root/cimv2"
      instance_names ns, (@product == :winrm) ? "Win32_NetworkAdapter" : "CIM_NetworkAdapter"
    end
    def storages ns="root/cimv2"
      instance_names ns, (@product == :winrm) ? "Win32_DiskDrive" : "CIM_DiskDrive"
    end

  end # Class
end # Module
