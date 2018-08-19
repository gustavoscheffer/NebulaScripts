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

client = Client.new(CREDENTIALS, ENDPOINT)

#metricas
MET_CPU  = 0;
MET_MEMORY = 0;

#Pegar lista de máquinas existentes;


vm_pool = VirtualMachinePool.new(client, -1)

rc = vm_pool.info
if OpenNebula.is_error?(rc)
     puts rc.message
     exit -1
end

puts rc
#Filtrar as máquinas pelo nome e montar uma nova lista;
#Verificar se estas máquinas ultrapassaram o limite de hardware (memoria ou cpu);
#Gerar uma nova máquina com 30%mais recurso de memória e/ou mais 1 cpu;
#Excluir a máquina antiga;
