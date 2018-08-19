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

#PARAMETROS
MET_CPU  = 0;
MET_MEMORY = 0;
MET_VMS ="teste-";

#1) Pegar lista de máquinas existentes;
vm_pool = VirtualMachinePool.new(client, -1)

#controla se houve erro na request
rc = vm_pool.info
if OpenNebula.is_error?(rc)
     puts rc.message
     exit -1
end

#2) Filtrar as máquinas pelo nome e montar uma nova lista;

# novo array para guardar as vms filtradas
vms_filtradas = Array.new

vm_pool.each do |vm|
  vm.info
  r = Regexp.new(MET_VMS)

  if (!r.match(vm.name.to_s).nil?)
    vms_filtradas.push vm.name.to_s
  end
end

puts vms_filtradas

#Verificar se estas máquinas ultrapassaram o limite de hardware (memoria ou cpu);
#Gerar uma nova máquina com 30%mais recurso de memória e/ou mais 1 cpu;
#Excluir a máquina antiga;
