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
    def initialize basepath = nil
      @basedir = File.expand_path(File.join(basepath || Dir.getwd, "wbem"))
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
    # find_and_parse_superclass_of
    #
    # Find the superclass name of a class, parse its mof file
    # returns Hash of { classname -> CIM::Class }
    #

    def find_and_parse_superclass_of c, options
      superclasses = {}
      # parent unknown
      #  try parent.mof
      begin
        parser = MOF::Parser.new options
        result = parser.parse [QUALIFIERS, "qualifiers_intel.mof", "#{c.superclass}.mof"]
        if result
          result.each_value do |r|
            r.classes.each do |parent|
              if parent.name == c.superclass
                c.parent = parent
                superclasses[parent.name] = parent
                superclasses.merge!(find_and_parse_superclass_of(parent,options)) if parent.superclass
              end
            end
          end
        else
          $stderr.puts "Warn: Parent #{c.superclass} of #{c.name} not known"
        end
      rescue Exception => e
        parser.error_handler e
      end
      superclasses
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
    def generate name
      require 'erb'
      template = File.read(File.join(File.dirname(__FILE__), "class_template.erb"))
      erb = ERB.new(template)
      code = erb.result(binding)
      file = File.join(@basedir, name + ".rb")
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
      mof = @classes[name][:mof] rescue nil
      unless mof
        # read .mof
        puts "Reading mof from #{mofpath}" if Wbem.debug
        mofs = @parser.parse [ QUALIFIERS, "qualifiers_intel.mof", mofpath ]
#        puts "==> #{mofs.inspect}"
        # Iterate over all parsed classes
        mofs[mofpath].classes.each do |mofclass|
          next unless mofclass.name == name
          @classes[name] = { :path => mofpath, :mof => mofclass }
          if mofclass.superclass
            class_for mofclass.superclass
          end
        end
      end
      generate name
      require classpath
      return Object.const_get("Wbem").const_get(name)
    end # def create
  end # class ClassFactory
end # module Wbem
