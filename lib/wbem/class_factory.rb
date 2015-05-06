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
    CLASSDIR = "wbem"
    require 'cim'
    require 'mof'
    require 'pathname'
    
    #
    # Constructor
    #
    def initialize basepath = nil
      @basedir = File.expand_path(File.join(basepath || Dir.getwd, CLASSDIR))
    end
  private

    #
    # parse_with_ancestors
    #
    # Find the superclass name of a class, parse its mof file
    # returns Hash of { classname -> CIM::Class }
    #

    def parse_with_ancestors name
      # find .mof file
      mofdata = classmap()[name]
      unless mofdata
        raise "Can't find MOF for #{name}"
      end
      mofpath = mofdata[:path]
      # parsed before ?
      mof = mofdata[:mof] rescue nil
      unless mof
        # not parsed, parse now
        puts "Reading mof from #{mofpath}" if Wbem.debug
        begin
          mofs = parser().parse [ QUALIFIERS, "qualifiers_intel.mof", mofpath ]
        rescue Exception => e
          parser.error_handler e
        end
#        puts "==> #{mofs.inspect}"
        # Iterate over all parsed classes
        mofs[mofpath].classes.each do |mofclass|
          next unless mofclass.name == name
          classmap()[name] = { :path => mofpath, :mof => mofclass }
          if mofclass.superclass
            parse_with_ancestors mofclass.superclass
          end
        end
      end
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
    def generate name, file
      require 'erb'
      template = File.read(File.join(File.dirname(__FILE__), "class_template.erb"))
      erb = ERB.new(template)
      code = erb.result(binding)
      Dir.mkdir(@basedir) unless File.directory?(@basedir)
      File.open(file, "w+") do |f|
        f.puts code
      end
    end
    
    #
    # classmap - generate map of classes and their .mof files
    #
    def classmap
      return @classmap if @classmap
      # read SCHEMA and build class index to find .mof files quickly
      @classmap = Hash.new
      @includes = [ Pathname.new(".") ]
      SCHEMATA.each do |base, file|
        @includes << base
        allow_cim = (file =~ /^CIM_/) # allow CIM_ only for CIM_Schema.mof
        File.open(File.join(base, file)) do |f|
          f.each do |l|
            if l =~ /^\#pragma\sinclude\s?\(\"(([\w\/_]+)\.mof)\"\).*/
              # $1 Foo/Bar.mof
              # $2 Foo/Bar
              path = $1
              names = $2.split("/")
              name = names[1] || names[0]
              next unless name =~ /_/ # class name must have underscore (rules out 'qualifiers.mof')
#              puts "#{path}:#{name}"
              next if !allow_cim && name =~ /^CIM_/ # skip CIM_ mofs unless allowed
              if @classmap[name]
                raise "Dup #{name} : #{@classmap[name]}"
              else
                @classmap[name] = { :path => path }
              end
            end
          end
        end
      end
      STDERR.puts "Found MOFs for #{@classmap.size} classes" if Wbem.debug
      @classmap
    end

    #
    # MOF parser access
    #
    def parser
      @parser ||= MOF::Parser.new :style => :cim, :includes => @includes, :quiet => true
    end
  public
    #
    # Class Factory
    #
    def class_for name
      begin
        require "./#{CLASSDIR}/#{name}"
        return Object.const_get("Wbem").const_get(name)
      rescue LoadError
        raise "Use 'genclass' of ruby-wbem to generate class '#{name}'"
      end
    end
    #
    # gen_class
    #
    def gen_class name
      mofname = name + ".mof"
      classpath = File.join(@basedir, "#{name}.rb")
      parse_with_ancestors name
      generate name, classpath
      class_for name
    end # def create
  end # class ClassFactory
end # module Wbem
