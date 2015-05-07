#
# Managed iAMT
#
# Written by Klaus Kämpf 2015
#
$:.unshift File.expand_path(File.join(File.dirname(__FILE__), "..", "lib"))

require 'wbem'

def usage msg = nil
  if msg
    STDERR.puts "** Err: #{msg}"
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
client = connect url
eprs = client.instance_names "", ARGV.shift
eprs.each do |epr|
  instance = client.get(epr)
  puts "#{instance.class}: #{instance}\n"
end
