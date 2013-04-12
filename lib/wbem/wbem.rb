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
      @auth_scheme = auth_scheme.to_s.to_sym rescue nil
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

    def to_s
      "#{@product}(#{@url})"
    end

public
    # return list of classnames for ObjectPath op
    def class_names op, deep_inheritance=false
      raise "#{self.class}.class_names not implemented"
    end
  
    def system_class_name
      case @product
      when :winrm then "Win32_ComputerSystem"
      else
        "CIM_ComputerSystem"
      end
    end
    def systems ns="root/cimv2"
      ns = "" if @product == :iamt
      instance_names ns, system_class_name
    end
    
    def service_class_name
      case @product
      when :winrm then "Win32_Service"
      else
        "CIM_Service"
      end
    end
    def services ns="root/cimv2"
      ns = "" if @product == :iamt
      instance_names ns, service_class_name
    end
    def processes ns="root/cimv2"
      ns = "" if @product == :iamt
      instance_names ns, (@product == :winrm) ? "Win32_Process" : "CIM_Process"
    end
    def network_class_name
      case @product
      when :winrm then "Win32_NetworkAdapter"
      when :iamt then "CIM_NetworkPort"
      else
        "CIM_NetworkAdapter"
      end
    end
    def networks ns="root/cimv2"
      ns = "" if @product == :iamt
      instance_names ns, network_class_name
    end
    def storage_class_name
      case @product
      when :winrm then "Win32_DiskDrive"
      when :iamt then "CIM_StorageExtent"
      else
        "CIM_DiskDrive"
      end
    end
    def storages ns="root/cimv2"
      ns = "" if @product == :iamt
      instance_names ns, storage_class_name
    end

  end # Class
end # Module
