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

        template = <<-EOT
        NAME    = "Red LAN"

        # Now we'll use the host private network (physical)
        BRIDGE  = vbr0

	VN_MAD	= dummy

        # Custom Attributes to be used in Context
        GATEWAY = 192.168.0.1
        DNS     = 192.168.0.1

        LOAD_BALANCER = 192.168.0.3

        AR = [
            TYPE = IP4,
                IP   = 192.168.0.1,
                    SIZE = 255
                    ]
                    EOT

                    xml = OpenNebula::VirtualNetwork.build_xml
                    vn  = OpenNebula::VirtualNetwork.new(xml, client)

                    rc = vn.allocate(template)
                    if OpenNebula.is_error?(rc)
                        STDERR.puts rc.message
                            exit(-1)
                            else
                                puts "ID: #{vn.id.to_s}"
                                end

                                puts "Before info:"
                                puts vn.to_xml

                                puts

                                vn.info

                                puts "After info:"
                                puts vn.to_xml
