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
    
    #
    # Constructor
    #
    def initialize basepath
      @basedir = File.expand_path(basepath)
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
                @classes[$3] = { :path => $1 }
              end
            end
          end
        end
      end
      @parser = MOF::Parser.new :style => :cim, :includes => includes, :quiet => true
    end
  private
    #
    # collect all (inherited) features
    #
    def collect_features mofclass, known = Hash.new
      features = Array.new
      if mofclass.superclass
        features += collect_features(@classes[mofclass.superclass][:mof], known)
      end
      mofclass.features.each do |f|
        override = known[f.name]
        if (override)
#          puts "Override #{override.name}"
          features.delete override
        end
        known[f.name] = f
        features << f
      end
      features
    end
    #
    # generate method parameter information
    # return nil if no parameters
    #
    def gen_method_parameters direction, parameters, file
      return if parameters.empty?
      file.print "#{direction.inspect} => ["
      first = true
      parameters.each do |p|
        if first
          first = false
        else
          file.print ", "
        end
        # [ <name>, <type>, <out>? ]
        file.print "#{p.name.inspect}, #{p.type.to_sym.inspect}"
      end
      file.print "]"
      return true
    end
    #
    # generate .rb class declaration
    #
    def generate mofclass
      require 'erb'
      template = File.read(File.join(File.dirname(__FILE__), "class_template.erb"))
      erb = ERB.new(template)
      c = mofclass
      code = erb.result(binding)
      file = File.join(@basedir, mofclass.name + ".rb")
      File.open(file, "w+") do |f|
        f.puts code
      end
    end
  public
    #
    # Class Factory
    #
    def class_for name, dir = nil
      mofname = name + ".mof"
      classpath = File.join(@basedir, name)
      if (File.readable?(classpath)) # already generated ?
        require classpath
        return Object.const_get("Wbem").const_get(name)
      end
      # find .mof file
      mofpath = @classes[name][:path] rescue nil
      unless mofpath # construct local path
        mofpath = mofname
        if dir
          mofpath = File.join(dir, mofpath)
        end
      end
      # read .mof
#      puts "Reading mof from #{mofpath}"
      mofs = @parser.parse [ QUALIFIERS, mofpath ]
      # Iterate over all parsed classes
      mofs[mofpath].classes.each do |mofclass|
        next unless mofclass.name == name
        @classes[name] = { :path => mofpath, :mof => mofclass }
        if mofclass.superclass
          class_for mofclass.superclass
        end
        generate mofclass
        require classpath
        return Object.const_get("Wbem").const_get(name)
      end
      nil
    end # def create
  end # class ClassFactory
end # module Wbem
