module Wbem
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

    attr_reader :url, :response

    #
    # Wbem::Client.connect uri, protocol = nil
    #
    # Connect to remote client identified by uri and protocol
    # Possible values for protocol:
    # :cimxml - connect via CIM/XML
    # :wsman  - connect via WS-Management
    # else    - probe connection (cim/xml first)
    #
    def self.connect uri, protocol = nil
      STDERR.puts "Wbem::Client.connect(#{uri},#{protocol})" if Wbem.debug
      u = uri.is_a?(URI) ? uri : URI.parse(uri)
      case protocol
      when :wsman
        return WsmanClient.new u
      when :cimxml
        return CimxmlClient.new u
      end
      STDERR.puts "no connect, check known ports"
      # no connect, check known ports
      case u.port
      when 8888, 8889, 5985, 5986
        return WsmanClient.new u
      when 5988, 5989
        return CimxmlClient.new u
      end
      STDERR.puts "no known ports"
      port = u.port # keep orig port as we change u.port below
      [:wsman, :cimxml].each do |protocol|
        # enforce port if uri provides scheme and host only
        if port == 80 && u.scheme == 'http' # http://hostname
          u.port = (protocol == :cimxml) ? 5988: 5985
        end
        if port == 443 && u.scheme == 'https' # https://hostname
          u.port = (protocol == :cimxml) ? 5989: 5986
        end
        c = Wbem::Client.connect u, protocol
        if c
          STDERR.puts "Connect #{u} as #{c}"
          return c
        end
      end
    end

  end # Class
end # Module
