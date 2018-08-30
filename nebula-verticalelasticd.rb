#!/usr/bin/env ruby

##############################################################################
# Paramentros de Entrada
##############################################################################

# OpenNebula credentials
CREDENTIALS = "oneadmin:opennebula"

# XML_RPC endpoint where OpenNebula is listening
ENDPOINT    = "http://localhost:2633/RPC2"

# treshold maximo de cpu
CPU_MAX  = 0

# nome da vm no padrao nome-
VM_NOME = "mysql-"

# Vezes em que deve ser ultrapassado o limite maximo de cpu
QTD_CHECKS = 3

# intervalo de cada check em minutos
INTERVALO = 10 

# Template original
TEMPLATE_O = 'CONTEXT = [
            NETWORK = "YES",
            REPORT_READY = "YES",
            SSH_PUBLIC_KEY = "$USER[SSH_PUBLIC_KEY]",
            TOKEN = "YES" ]
            CPU = "0.3"
            DESCRIPTION = "A small GNU/Linux system for testing"
            DISK = [
            IMAGE = "ttylinux",
            IMAGE_UNAME = "oneadmin" ]
            FEATURES = [
            ACPI = "no",
            APIC = "no" ]
            GRAPHICS = [
            LISTEN = "0.0.0.0",
            TYPE = "VNC" ]
            INPUTS_ORDER = ""
            MEMORY = "128"
            MEMORY_UNIT_COST = "MB"
            OS = [
            BOOT = "disk0" ]'

# Template usado para subir aumentar o hardware em 10%
TEMPLATE_N1 = 'CONTEXT = [
            NETWORK = "YES",
            REPORT_READY = "YES",
            SSH_PUBLIC_KEY = "$USER[SSH_PUBLIC_KEY]",
            TOKEN = "YES" ]
            CPU = "0.4"
            DESCRIPTION = "A small GNU/Linux system for testing"
            DISK = [
            IMAGE = "ttylinux",
            IMAGE_UNAME = "oneadmin" ]
            FEATURES = [
            ACPI = "no",
            APIC = "no" ]
            GRAPHICS = [
            LISTEN = "0.0.0.0",
            TYPE = "VNC" ]
            INPUTS_ORDER = ""
            MEMORY = "128"
            MEMORY_UNIT_COST = "MB"
            OS = [
            BOOT = "disk0" ]'

##############################################################################
# Methods
##############################################################################

def create_new_vm(new_name, template, client)

  # Creates a VirtualMachine description
  xml = OpenNebula::VirtualMachine.build_xml
  vm  = OpenNebula::VirtualMachine.new(xml, client)

  # Creates a VirtualMachine and bring it up
  rc = vm.allocate(template)
  if OpenNebula.is_error?(rc)
      STDERR.puts rc.message
      exit(-1)
  else
    rc = vm.rename(new_name + vm.id.to_s)
    if OpenNebula.is_error?(rc)
      STDERR.puts rc.message
      exit(-1)
    else
      puts "VM #{new_name + vm.id.to_s} criada com sucesso!"
    end
  end
end

def remove_old_vm()
  
end

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


# 2) Filtrar as máquinas pelo nome e montar uma nova lista;

vm_filtrada = ''
vm_pool.each do |vm|
  vm.info
  r = Regexp.new(VM_NOME)
  if (r.match(vm.name.to_s).nil?)
    # se não encontrar a vm ele a cria...
    create_new_vm(VM_NOME, TEMPLATE_O, client)
  end
    # se a vm for encontrada e estiver rodando, coletamos o uso da cpu
  if ((vm.lcm_state_str <=> 'RUNNING') == 0)
      vm_filtrada = vm
  
  else
    puts "Nao existe maquina em RUNNING"
    exit -1
  end

end

if ((vm_filtrada <=> '') != 0)
   metricas  = vm_filtrada.monitoring(['MONITORING/CPU'])
   metricas_cpu = metricas.fetch('MONITORING/CPU')
   cpu_metrica_valor_final = metricas_cpu[metricas_cpu.length() -1][1].to_f
   puts pu_metrica_valor_final

else
  puts "Nao foram encontradas maquinas"
  exit -1
end


# #metricas de cada vm
# cpu_metrics_by_vm = Hash.new
# cpu_values = Array.new
# cpu_value_final # valor final da cpu

# #verifico se foi encontrado alguma vm com o padrao do parametro
# if (vm_filtradas.length = 1)
#     #itera para pegar os dados de cada vm
#     vms_filtradas.each do |vm_filtrada|  
#       cpu_metrics_by_vm = vm_filtrada.monitoring(['MONITORING/CPU'])
#       cpu_values = cpu_metrics_by_vm.fetch('MONITORING/CPU')
      
#       #valor do ultimo check 
#       cpu_value_final = cpu_values[cpu_values.length() -1][1].to_f

#       #verifica em qual check esta agora
#       if(rodada >= QTD_CHECKS)

#         #3) Verificar se estas máquinas ultrapassaram o limite de hardware (memoria ou cpu);       
#         if(val_cpu_final > MET_CPU_MAX)       
#           #4) Gerar uma nova máquina com 30%mais recurso de memória e/ou mais 1 cpu;
#           template = <<-EOT
#           CONTEXT = [
#             NETWORK = "YES",
#             REPORT_READY = "YES",
#             SSH_PUBLIC_KEY = "$USER[SSH_PUBLIC_KEY]",
#             TOKEN = "YES" ]
#           CPU = "0.3"
#           DESCRIPTION = "A small GNU/Linux system for testing"
#           DISK = [
#             IMAGE = "ttylinux",
#             IMAGE_UNAME = "oneadmin" ]
#           FEATURES = [
#             ACPI = "no",
#             APIC = "no" ]
#           GRAPHICS = [
#             LISTEN = "0.0.0.0",
#             TYPE = "VNC" ]
#           INPUTS_ORDER = ""
#           MEMORY = "128"
#           MEMORY_UNIT_COST = "MB"
#           OS = [
#             BOOT = "disk0" ]
#           EOT

#           # Creates a VirtualMachine description
#           xml = OpenNebula::VirtualMachine.build_xml
#           vm  = OpenNebula::VirtualMachine.new(xml, client)

#           # VirtualMachine new name
#           NEWNAME = VM_NOME

#           # Creates a VirtualMachine and bring it up
#           rc = vm.allocate(template)
#           if OpenNebula.is_error?(rc)
#               STDERR.puts rc.message
#               exit(-1)
#           else
#               vm.rename(NEWNAME + vm.id.to_s)
#               puts "New VM Started:\nID = #{vm.id.to_s} "
#               vm.info
#               puts vm.name
#               puts vm.state


#               #5) Excluir a máquina antiga;
#               if vm_filtrada.name.to_s
#                  #delete vm
#                  rc = vm_filtrada.delete
#                  if OpenNebula.is_error?(rc)
#                       puts "Virtual Machine #{vm.id}: #{rc.message}"

#                   else
#                       puts "Virtual Machine #{vm.id}: Shutting down and Delete after!"

#                   end
#               end
#           end
#         end
        
#         if(val_cpu_final <= MET_CPU_MAX)       
#           #4) Voltar o hardware antigo
#            # ====COLOCAR O SCRIPT AQUI====#
#            #5) Excluir a máquina antiga;
#            # ====COLOCAR O SCRIPT AQUI====#
#         end   
#       end
#     end
# end
# #tempo antes de repetir a consulta dos hosts
# sleep(INTERVALO.minutes)