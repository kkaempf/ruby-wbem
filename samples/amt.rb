#
# Managed iAMT
#   SOL (serial-over-lan)
# https://software.intel.com/sites/manageability/AMT_Implementation_and_Reference_Guide/WordDocuments/enablingthesolinterface.htm
#   KVM (keyboard-video-moust)
# https://software.intel.com/sites/manageability/AMT_Implementation_and_Reference_Guide/WordDocuments/kvmconfiguration.htm
#
# Written by Klaus Kämpf 2015
#
$:.unshift File.expand_path(File.join(File.dirname(__FILE__), "..", "lib"))

require 'wbem'

def usage msg = nil
  if msg
    STDERR.puts "** Err: #{msg}"
    STDERR.puts "amt [-d] {sol|kvm} {start|stop} <uri>"
    exit 1
  end
end

def connect url
  usage "<url> missing" unless url
  return Wbem::Client.connect url, :wsman
end

def enable_listener instance
  unless instance.ListenerEnabled
    instance.ListenerEnabled = true
    instance.put
  end
end

def sol_start client
  instance = client.get "AMT_RedirectionService", "Name" => "Intel(r) AMT Redirection Service"
  case instance.EnabledState
  when 32770
    puts "SOL is enabled and IDE-R is disabled"
  when 32771
    puts "SOL and IDE-R are enabled"
  when 32768
    # SOL and IDE-R are disabled
    instance.RequestStateChange(32770)
  when 32769
    # SOL is disabled and IDE-R is enabled
    instance.RequestStateChange(32771)
  end
end

def sol_stop client
  instance = client.get "AMT_RedirectionService", "Name" => "Intel(r) AMT Redirection Service"
  case instance.EnabledState
  when 32770
    # SOL is enabled and IDE-R is disabled
    instance.RequestStateChange(32768)
  when 32771
    # SOL and IDE-R are enabled
    instance.RequestStateChange(32769)
  when 32768
    # SOL and IDE-R are disabled
  when 32769
    # SOL is disabled and IDE-R is enabled
  end
end

def kvm_start client
  sap = client.get "CIM_KVMRedirectionSAP", "Name" => "KVM Redirection Service Access Point"
  unless sap.EnabledState
    data = client.get "IPS_KVMRedirectionSettingData", "InstanceID" => "Intel(r) KVM Redirection Settings"
    if data.EnabledByMEBx
      result = sap.RequestStateChange(2)
      if result == 0
        # enable listener
      else
      end
    end
  else
    puts "KVM already enabled"
  end
end

def kvm_stop client
  sap = client.get "CIM_KVMRedirectionSAP", "Name" => "KVM Redirection Service Access Point"
  if sap.EnabledState
    data = client.get "IPS_KVMRedirectionSettingData", "InstanceID" => "Intel(r) KVM Redirection Settings"
    if data.EnabledByMEBx
      result = sap.RequestStateChange(3)
      if result == 0
        # disable listener
      else
      end
    end
  else
    puts "KVM already disabled"
  end
end

# ---------------------------------------------------------
target = nil
loop do
  target = ARGV.shift
  break unless target && target[0,1] == '-'
  case target[1..-1]
  when 'd'
    Wbem.debug = 99
  else
    usage "Unknown option '#{target}'"
  end
end

cmd = ARGV.shift
url = ARGV.shift

case [target, cmd]
when ["sol", "start"]
  sol_start( connect(url) )
when ["sol", "stop"]
  sol_stop( connect(url) )
when ["kvm", "start"]
  kvm_start( connect(url) )
when ["kvm", "stop"]
  kvm_stop( connect(url) )
else
  usage "Unknown command: #{target.inspect} #{cmd.inspect}"
end
