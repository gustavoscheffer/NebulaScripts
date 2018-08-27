#!/usr/bin/env ruby

##############################################################################
# Paramentros de Entrada
##############################################################################

# treshold maximo de cpu
MET_CPU_MAX  = 0

# treshold maximo de memoria
MET_MEMORY_MAX = 0 

# treshold minimo de cpu
MET_CPU_MIN  = 0 

# treshold minimo de memoria
MET_MEMORY_MIN = 0 

# nome dos hosts a serem monitorados pelo verticalelastic
MET_VMS ="teste-" 

# OpenNebula credentials
CREDENTIALS = "oneadmin:opennebula"

# XML_RPC endpoint where OpenNebula is listening
ENDPOINT    = "http://localhost:2633/RPC2"

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


client = Client.new(CREDENTIALS, ENDPOINT)

# 1) Pegar lista de máquinas existentes;
vm_pool = VirtualMachinePool.new(client, -1)

#controla se houve erro na request
rc = vm_pool.info
if OpenNebula.is_error?(rc)
     puts rc.message
     exit -1
end

# novo array para guardar as vms filtradas
vms_filtradas = Array.new

# 2) Filtrar as máquinas pelo nome e montar uma nova lista;
vm_pool.each do |vm|
  vm.info
  r = Regexp.new(MET_VMS)
  if (!r.match(vm.name.to_s).nil?)
    vms_filtradas.push vm
  end
end

#metricas de cada vm
cpu_metrics_by_vm = Hash.new
cpu_values = Array.new
media_val_cpu #media da cpu

#verifico se foi encontrado alguma vm com o padrao do parametro
if (vms_filtradas.length != 0)

    #itera para pegar os dados de cada vm
    vms_filtradas.each do |vm_filtrada|  
      cpu_metrics_by_vm = vm_filtrada.monitoring(['MONITORING/CPU'])
      cpu_values = cpu_metrics_by_vm.fetch('MONITORING/CPU')
      
      #valor dos 3 ultimos checks 
      val1 = cpu_values[cpu_values.length() -1][1].to_f
      val2 = cpu_values[cpu_values.length() -2][1].to_f
      val3 = cpu_values[cpu_values.length() -3][1].to_f
      
      #calcula a media dos 3 ultimos checks 
      media_val_cpu  = (val1. + val2 + val3)/3
      
      #verifica em qual check esta agora
      if(round <= QTD_CHECKS)

        #3) Verificar se estas máquinas ultrapassaram o limite de hardware (memoria ou cpu);       
        if(media_val_cpu > MET_CPU_MAX)       
          #4) Gerar uma nova máquina com 30%mais recurso de memória e/ou mais 1 cpu;
           # ====COLOCAR O SCRIPT AQUI====#
           #5) Excluir a máquina antiga;
           # ====COLOCAR O SCRIPT AQUI====#
        end

        # COLOCAR O SLEEP AQUI!!!!!   
      end
    end
end 