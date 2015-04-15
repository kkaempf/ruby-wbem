#
# Class Factory
#
#
# Creates CIM class with ancestry chain
#
#  Base class: Wbem::Instance
#
module Wbem
  class ClassFactory
    MOFBASE = "/usr/share/mof/cim-current"
    AMTBASE = "/usr/share/mof/iAMT/MOF"
    QUALIFIERS = "qualifiers.mof"
    SCHEMATA = { MOFBASE => "CIM_Schema.mof", AMTBASE => "amt.mof" }
    require 'cim'
    require 'mof'
    require 'pathname'
    def initialize classbase
      @classbase = File.expand_path(classbase)
      # read SCHEMA and build class index to find .mof files quickly
      @classes = Hash.new
      includes = [ Pathname.new(".") ]
      SCHEMATA.each do |base, file|
        includes << base
        allow_cim = (file =~ /^CIM_/)
        File.open(File.join(base, file)) do |f|
          f.each do |l|
            if l =~ /^\#pragma\ include\ \(\"((\w+)\/(\w+)\.mof)\"\)$/
              #            puts "#{$1} #{$2} - #{$3}"
              unless allow_cim
                next if $3 =~ /^CIM_/ # skip CIM_ mofs unless allowed
              end
              if @classes[$3]
                raise "Dup #{$3} : #{@classes[$3]}"
              else
                @classes[$3] = $1
              end
            end
          end
        end
      end
      @parser = MOF::Parser.new :style => :cim, :includes => includes
    end
  private
    def generate mof, file
      file = File.join(@classbase, File.basename(file, ".mof") + ".rb")
      STDERR.puts "Generate #{file} for #{mof}"
      File.open(file, "w+") do |f|
        f.puts "module Wbem"
        f.puts "  class #{mof.name}"
        f.puts "  end"
        f.puts "end"
      end
    end
  public
    #
    # Class Factory
    #
    def class_for name, dir = nil
      mofname = name + ".mof"
      classpath = File.join(@classbase, name)
      if (File.readable?(classpath)) # already generated ?
        require classpath
        return Object.const_get("Wbem").const_get(name)
      end
      # find .mof file
      mofpath = @classes[name]
      unless mofpath # construct local path
        mofpath = mofname
        if dir
          mofpath = File.join(dir, mofpath)
        end
      end
      # read .mof
      puts "Reading mof from #{mofpath}"
      mofs = @parser.parse [ QUALIFIERS, mofpath ]
      # Iterate over all parsed classes
      mofs[mofpath].classes.each do |mofclass|
        next unless mofclass.name == name
        @classes[name] = mofpath
        if mofclass.superclass
          class_for mofclass.superclass
        end
        generate mofclass, mofpath
        require classpath
        return Object.const_get("Wbem").const_get(name)
      end
      nil
    end # def create
  end # class ClassFactory
end # module Wbem
