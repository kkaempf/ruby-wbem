#
# Type conversion
#

require 'openwsman'

module Wbem
  class Conversion
  #
  # Convert CIM DateTime string representation (see DSP0004, 2.2.1)
  # to Ruby Time (timestamp) or Float (interval, as seconds with fraction)
  #           00000000001111111111222222
  #           01234567890123456789012345
  # East:     yyyymmddhhmmss.mmmmmm+utc -> Time (utc = offset in minutes)
  # West:     yyyymmddhhmmss.mmmmmm-utc -> Time
  # Interval: ddddddddhhmmss.mmmmmm:000 -> Float (interval in seconds, with fraction)
  #
  def self.cimdatetime_to_ruby str
#    puts "Cmpi.cimdatetime_to_ruby(#{str})"
    case str[21,1]
    when '+', '-'
      # create Time from yyyymmddhhmmss and utc
      t = Time.new(str[0,4].to_i, str[4,2].to_i, str[6,2].to_i, str[8,2].to_i, str[10,2].to_i, str[12,2].to_i, str[22,3].to_i * ((str[21,1]=='+')?60:-60))
      off = str[15,6].to_i / 1000
      # Add fractional part
      return t + off
    when ':'
      # time offset
      off = str[0,8].to_i * 24 * 60 * 60
      off += str[8,2].to_i * 60 * 60 + str[10,2].to_i * 60 + str[12,2].to_i
      off += str[15,6].to_i / 1000
      return off
    else
      raise RCErrInvalidParameter.new(CMPI_RC_ERR_INVALID_PARAMETER, "Invalid CIM DateTime '#{str}'")
    end
  end

  #
  # Convert Ruby value to CIM DateTime string representation (see DSP0004, 2.2.1)
  #           00000000001111111111222222
  #           01234567890123456789012345
  # East:     yyyymmddhhmmss.mmmmmm+utc -> Time (utc = offset in minutes, mmmmmm is the microsecond within the second
  # West:     yyyymmddhhmmss.mmmmmm-utc -> Time
  # Interval: ddddddddhhmmss.mmmmmm:000 -> Float (interval in seconds, with fraction)
  #
  def self.ruby_to_cimdatetime val
    require 'date'
#    puts "Cmpi.ruby_to_cimdatetime(#{val}[#{val.class}])"
    t = nil
    case val
    when Time
      s = val.strftime "%Y%m%d%H%M%S.%6N"
      utc = val.utc_offset # offset in seconds
      if utc < 0
        s << "-"
        utc = -utc
      else
        s << "+"
      end
      val = s + ("%03d" % (utc/60))
    when Numeric
      if val < 0
        # treat it as seconds before epoch
        val = self.ruby_to_cimdatetime( Time.at(val) )
      else
        # treat as interval in microseconds
        secs = (val / 1000000).to_i
        usecs = (val % 1000000).to_i
        days = secs / (24 * 60 * 60)
        secs = secs % (24 * 60 * 60) # seconds within the day
        hours = (secs / (60 * 60)).to_i
        secs = secs % (60 * 60)
        mins = (secs / 60).to_i
        secs = secs % 60
        val = "%08d%02d%02d%02d.%06d:000" % [ days, hours, mins, secs, usecs ]
      end
    when /^\d{14}\.\d{6}[-+:]\d{3}$/
      # fallthru
    when String
      val = self.ruby_to_cimdatetime val.to_f # retry as Numeric
    else
      val = self.ruby_to_cimdatetime val.to_s # retry as string
    end
    val
  end
  
    # generic type conversion
    # CIM -> Ruby
    #
    def self.to_ruby type, value
      text = case value
             when Openwsman::XmlNode
               value.text
             when String
               value
             else
               value.to_s
             end
      case type
      when :null,:void
        nil
      when :boolean
        text == 'true'
      when :char16
        text.to_i
      when :string
        text
      when :uint8,:sint8,:uint16,:sint16,:uint32,:sint32,:uint64,:sint64
        text.to_i
      when :real32,:real64
        text.to_f
      when :dateTime
        Wbem::Conversion.cimdatetime_to_ruby text
      when :class
        puts "to_ruby :class, #{value.to_xml}"
        # assume EndpointReference
        Openwsman::EndPointReference.new(value.to_xml).to_s
      #      when :class
      #      when :reference
      #      when :array
      else
        raise "Unhandled type in to_ruby #{type.inspect}"
      end
    end
    # generic type conversion
    # Ruby -> CIM
    #
    def self.from_ruby type, value
      case type
      when :null,:void
        ""
      when :boolean
        (value)?'true':'false'
      when :char16
        value.to_s
      when :string
        value.to_s
      when :uint8,:sint8,:uint16,:sint16,:uint32,:sint32,:uint64,:sint64
        value.to_i.to_s
      when :real32,:real64
        value.to_f.to_s
      when :dateTime
        Wbem::Conversion.ruby_to_cimdatetime value
      #      when :class
      #      when :reference
      #      when :array
      else
        raise "Unhandled type in from_ruby #{type.inspect}"
      end
    end
  end # class Conversion
end # module Wbem
