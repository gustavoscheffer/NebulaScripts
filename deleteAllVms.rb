#!/usr/bin/env ruby
#
###############################################################################
## Environment Configuration
###############################################################################
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

        client = Client.new(CREDENTIALS, ENDPOINT)

        vm_pool = VirtualMachinePool.new(client, -1)

        rc = vm_pool.info
        if OpenNebula.is_error?(rc)
             puts rc.message
                  exit -1
                  end

                  vm_pool.each do |vm|
                       rc = vm.delete
                            if OpenNebula.is_error?(rc)
                                      puts "Virtual Machine #{vm.id}: #{rc.message}"
                                          else
                                                     puts "Virtual Machine #{vm.id}: Shutting down"
                                                          end
                                                          end
                                                       exit 0
