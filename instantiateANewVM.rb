#!/usr/bin/env ruby

##############################################################################
# Environment Configuration
##############################################################################
ONE_LOCATION=ENV["ONE_LOCATION"]

if !ONE_LOCATION
    RUBY_LIB_LOCATION="/usr/lib/one/ruby"
else
    RUBY_LIB_LOCATION=ONE_LOCATION+"/lib/ruby"
end

$: << RUBY_LIB_LOCATION

##############################################################################
# Required libraries
##############################################################################
require 'opennebula'

include OpenNebula

# OpenNebula credentials
CREDENTIALS = "oneadmin:opennebula"
# XML_RPC endpoint where OpenNebula is listening
ENDPOINT    = "http://localhost:2633/RPC2"


# Connection data
client = Client.new(CREDENTIALS, ENDPOINT)


# Create a template used to instantiate a new vm
template = <<-EOT
CONTEXT = [
  NETWORK = "YES",
  SSH_PUBLIC_KEY = "$USER[SSH_PUBLIC_KEY]" ]
CPU = "0.1"
DESCRIPTION = "A small GNU/Linux system for testing"
DISK = [
  IMAGE = "ttylinux" ]
FEATURES = [
  ACPI = "no",
  APIC = "no" ]
GRAPHICS = [
  LISTEN = "0.0.0.0",
  TYPE = "vnc" ]
MEMORY = "128"
NIC = [
  NETWORK = "cloud" ]
EOT

# Creates a VirtualMachine description
xml = OpenNebula::VirtualMachine.build_xml
vm  = OpenNebula::VirtualMachine.new(xml, client)

# VirtualMachine new name
NEWNAME = "teste-"

# Creates a VirtualMachine and bring it up
rc = vm.allocate(template)
if OpenNebula.is_error?(rc)
    STDERR.puts rc.message
    exit(-1)
else
    vm.rename(NEWNAME + vm.id.to_s)
    puts "New VM Started:\nID = #{vm.id.to_s} "
    vm.info
    puts vm.name
    puts vm.state

end



# puts "Before info:"
# puts vm.to_xml
#
# puts
#
# vm.info
#
# puts "After info:"
# puts vm.to_xml
