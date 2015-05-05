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

    def factory
      @factory ||= Wbem::ClassFactory.new
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

    #
    # Enumerate class refs
    # Returns Array of Instance References (Sfcc::Cim::ObjectPath or Openwsman::EndPointReference)
    #
    def enumerate classname
      raise "#{self.class}.enumerate not implemented"
    end

    #
    # get instance by reference
    #
    # call-seq
    #   get Openwsman::EndPointReference -> Wbem::Instance
    #   get Sfcc::Cim::ObjectPath -> Wbem::Instance
    #   get EndPointReference-as-String -> Wbem::Instance
    #   get ObjectPath-as-String -> Wbem::Instance
    #   get "ClassName", "key" => "value", :namespace => "root/interop"
    #
    def get instance_reference, keys = nil
      if keys
        if self.class == WsmanClient
          uri = Openwsman.epr_uri_for "", instance_reference
          instance_reference = Openwsman::EndPointReference.new(uri, nil, keys)
        elsif self.class == CimxmlClient
          namespace = keys.delete(:namespace) || "root/cimv2"
          instance_reference = Sfcc::Cim::ObjectPath.new(namespace, instance_reference)
          keys.each do |k,v|
            instance_reference.add_key k, v
          end
        end
      end
      puts "@client.get #{instance_reference.class}..." if Wbem.debug
      case instance_reference
      when Openwsman::EndPointReference
        get_by_epr instance_reference
      when Sfcc::Cim::ObjectPath
        get_by_objectpath instance_reference
      when String
        if self.class == WsmanClient
          get_by_epr Openwsman::EndPointReference.new(instance_reference)
        elsif self.class == CimxmlClient
          get_by_objectpath CimxmlClient.parse_object_path(instance_reference)
        else
          raise "Unsupported Wbem::get #{instance_reference.class} for #{self.class}"
        end
      else
        raise "Unsupported Wbem::get #{instance_reference.class}"
      end
    end
    #
    # ComputerSystem
    #
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

    #
    # RegisteredProfile
    #
    def profile_class_name
      "CIM_RegisteredProfile"
    end
    def profiles ns="root/cimv2"
      ns = "" if @product == :iamt
      instance_names ns, profile_class_name
    end

    #
    # Service
    #
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

    #
    # NetworkAdapter, NetworkPort
    #
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

    #
    # DiskDrive, StorageExtent
    #
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
