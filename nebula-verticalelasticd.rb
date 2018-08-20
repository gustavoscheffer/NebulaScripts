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


##############################################################################
# Paramentros de Entrada
##############################################################################

MET_CPU_MAX  = 0 # # treshold maxio de cpu
MET_MEMORY_MAX = 0 # # treshold maximo de memoria
MET_CPU_MIN  = 0 # treshold minimo de cpu
MET_MEMORY_MIN = 0 # treshold minimo de memoria
MET_VMS ="teste-" # nome dos hosts a serem monitorados pelo verticalelastic

# OpenNebula credentials
CREDENTIALS = "oneadmin:opennebula"
# XML_RPC endpoint where OpenNebula is listening
ENDPOINT    = "http://localhost:2633/RPC2"

client = Client.new(CREDENTIALS, ENDPOINT)

#1) Pegar lista de máquinas existentes;
vm_pool = VirtualMachinePool.new(client, -1)

#controla se houve erro na request
rc = vm_pool.info
if OpenNebula.is_error?(rc)
     puts rc.message
     exit -1
end

# novo array para guardar as vms filtradas
vms_filtradas = Array.new

#2) Filtrar as máquinas pelo nome e montar uma nova lista;
vm_pool.each do |vm|
  vm.info
  r = Regexp.new(MET_VMS)
  if (!r.match(vm.name.to_s).nil?)
    vms_filtradas.push vm
  end
end

#3) Verificar se estas máquinas ultrapassaram o limite de hardware (memoria ou cpu);
vms_filtradas.each do |vm_filtrada|
  #puts vm_filtrada.monitoring_xml
  puts vm_filtrada.monitoring(['MONITORING/CPU'])
end


#4) Gerar uma nova máquina com 30%mais recurso de memória e/ou mais 1 cpu;

#5) Excluir a máquina antiga;
