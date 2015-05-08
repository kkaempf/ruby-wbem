#
# ruby-wbem sample code
#
# Get instance
#
# Written by Klaus Kämpf 2015
#
$:.unshift File.expand_path(File.join(File.dirname(__FILE__), "..", "lib"))

require 'wbem'

def usage msg = nil
  if msg
    STDERR.puts "** Err: #{msg}"
    STDERR.puts "Usage:"
    STDERR.puts "get [-d] <url> <class> <key>=<value> [<key>=<value> ...]"
    exit 1
  end
end

def connect url
  usage "<url> missing" unless url
  return Wbem::Client.connect url
end

url = ARGV.shift
if url == "-d"
  Wbem.debug = -1
  url = ARGV.shift
end
usage "<url> missing" unless url
klass = ARGV.shift
usage "<class> missing" unless klass
args = {}
while arg = ARGV.shift
  k,v = arg.split("=")
  usage "Bad <key>=<value> pair" unless k && v
  args[k] = v
end
usage "needs at least one <key>=<value> pair" if args.empty?
client = connect url
instance = client.get klass, args
if instance
  puts "#{instance.class}: #{instance}\n"
else
  puts "Not found"
end
