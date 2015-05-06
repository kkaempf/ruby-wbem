#
# wbem.rb
#
# A CIM client abstraction layer on top of sfcc (cim/xml) and openwsman (WS-Management)
#
# Copyright (c) 2011, SUSE Linux Products GmbH
# Written by Klaus Kaempf <kkaempf@suse.de>
#
# Licensed under the MIT license
#
module Wbem
  require 'wbem/class_factory'
  require 'wbem/conversion'

  @@debug = nil
  def Wbem.debug
    @@debug
  end
  def Wbem.debug= level
    @@debug = (level == 0) ? nil : level
  end

  class Client
    require 'uri'
    require 'wbem/wsman'
    require 'wbem/cimxml'

    #
    # Wbem::Client.connect uri, protocol = nil
    #
    # Connect to remote client identified by uri and protocol
    # Possible values for protocol:
    # :cimxml - connect via CIM/XML
    # :wsman  - connect via WS-Management
    # else    - probe connection (cim/xml first)
    #
    def self.connect uri, protocol = nil, auth_scheme = nil
      STDERR.puts "Wbem::Client.connect(#{uri},#{protocol},#{auth_scheme})" if Wbem.debug
      unless uri.is_a?(URI)
        u = URI.parse(uri)
        # u.port will be set in any case, so check the uri for port specification
        protocol_given = uri.match(/:\d/)
      else
        u = uri
        protocol_given = uri.port
      end
      case protocol.to_s
      when "wsman"
        unless protocol_given
          u.port = (u.scheme == "http") ? 5985 : 5986
        end
        return WsmanClient.new u, auth_scheme
      when "cimxml"
        unless protocol_given
          u.port = (u.scheme == "http") ? 5988 : 5989
        end
        return CimxmlClient.new u
      end
      # no connect, check known ports
      case u.port
      when 8888, 8889, 5985, 5986
        return Wbem::Client.connect u, :wsman, auth_scheme
      when 5988, 5989
        return Wbem::Client.connect u, :cimxml, auth_scheme
      end
#      STDERR.puts "no known ports"
      port = u.port # keep orig port as we change u.port below
      [:wsman, :cimxml].each do |protocol|
        # enforce port if uri provides scheme and host only
        if port == 80 && u.scheme == 'http' # http://hostname
          u.port = (protocol == :cimxml) ? 5988: 5985
        end
        if port == 443 && u.scheme == 'https' # https://hostname
          u.port = (protocol == :cimxml) ? 5989: 5986
        end
        Wbem::Client.connect u, protocol, auth_scheme
      end
    end

  end # Class
end # Module
