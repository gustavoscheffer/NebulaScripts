#!/usr/bin/env ruby

##############################################################################
# Paramentros de Entrada
##############################################################################

# OpenNebula credentials
CREDENTIALS = "oneadmin:opennebula"

# XML_RPC endpoint where OpenNebula is listening
ENDPOINT    = "http://localhost:2633/RPC2"

# Total de vms para o servico
QTD_VMS = 2

# treshold maximo de cpu
CPU_MAX  = 80

# treshold minimo de cpu
CPU_MIN  = 10

# nome do servico. Usar o padrao "nonme-""
VM_NOME = "vert_elastic-"

# Vezes em que deve ser ultrapassado o limite maximo de cpu
QTD_CHECKS = 5

# intervalo de cada check em segundos
INTERVALO = 30

# Template original
TEMPLATE_O = 'CONTEXT = [
  NETWORK = "YES",
  SSH_PUBLIC_KEY = "$USER[SSH_PUBLIC_KEY]" ]
CPU = "0.5"
DISK = [
  IMAGE_ID = "4" ]
GRAPHICS = [
  LISTEN = "0.0.0.0",
  TYPE = "VNC" ]
INPUTS_ORDER = ""
LOGO = "images/logos/fedora.png"
MEMORY = "768"
MEMORY_UNIT_COST = "MB"
OS = [
  ARCH = "x86_64",
  BOOT = "" ]'

# Template usado para subir aumentar o hardware em 10%
TEMPLATE_N1 = 'CONTEXT = [
  NETWORK = "YES",
  SSH_PUBLIC_KEY = "$USER[SSH_PUBLIC_KEY]" ]
CPU = "0.7"
DISK = [
  IMAGE_ID = "4" ]
GRAPHICS = [
  LISTEN = "0.0.0.0",
  TYPE = "VNC" ]
INPUTS_ORDER = ""
LOGO = "images/logos/fedora.png"
MEMORY = "768"
MEMORY_UNIT_COST = "MB"
OS = [
  ARCH = "x86_64",
  BOOT = "" ]'

##############################################################################
# Methods
##############################################################################

# metodo para criar uma nova vm
def create_new_vm(new_name, template, client)

  # Creates a VirtualMachine description
  xml = OpenNebula::VirtualMachine.build_xml
  vm  = OpenNebula::VirtualMachine.new(xml, client)

  # Creates a VirtualMachine and bring it up
  rc = vm.allocate(template)
  if OpenNebula.is_error?(rc)
      STDERR.puts rc.message
      exit(-1)
  end    
  #renomeia    
  rc = vm.rename(new_name + vm.id.to_s)
  if OpenNebula.is_error?(rc)
    STDERR.puts rc.message
    #deleta vm se nao renomeia
    rc = vm.delete
    if OpenNebula.is_error?(rc)
      STDERR.puts rc.message
      exit(-1)
    end
  else
    puts "VM #{new_name + vm.id.to_s} criada com sucesso!"
    return new_name + vm.id.to_s
  end
end

# metodo que filra as vms do servico
def get_vm_list(vm_name_pattern, client)
  vm_list = Array.new
  vm_pool = VirtualMachinePool.new(client, -1)
  #controla se houve erro na request
  rc = vm_pool.info
  if OpenNebula.is_error?(rc)
       puts rc.message
       exit -1
  end
  vm_pool.each do |vm|
    vm.info
    r = Regexp.new(vm_name_pattern)
    #verificamos se ha vms do servico em questao, se nao tiver criar essa miseria
    if (!r.match(vm.name.to_s).nil?)
      vm_list.push(vm) 
    end
  end
  return vm_list
end

# metodo para pegar a vm e suas metricas e coloca em uma nova lista
def get_cpu_value_by_vm(vms_encontradas)
  lista_vm_com_metrica = Array.new
  vms_encontradas.each do |vm|
    if ((vm.lcm_state_str <=> 'RUNNING') == 0)
      vm_com_metrica = Array.new
      cpu_object = vm.monitoring(['MONITORING/CPU'])
      cpu_values = cpu_object.fetch('MONITORING/CPU')
      last_value_cpu = cpu_values[cpu_values.length() -1][1].to_f 
      vm_com_metrica.push(vm.name)
      vm_com_metrica.push(last_value_cpu.to_f)
      lista_vm_com_metrica.push(vm_com_metrica)
    end
  end
  return lista_vm_com_metrica
end

# metodo para excluir uma vm
def remove_old_vm(vm_name, client)
  vm_pool = VirtualMachinePool.new(client, -1)
  rc = vm_pool.info
  if OpenNebula.is_error?(rc)
    puts rc.message
    exit -1
  end

  vm_pool.each do |vm|
    #get info about vm
    vm.info
    if ((vm.name <=> vm_name) == 0)
      #delete vm
      rc = vm.delete
      if OpenNebula.is_error?(rc)
        puts "Virtual Machine #{vm.id}: #{rc.message}"
      else
        puts "Virtual Machine #{vm.id}: Shutting down and Delete after!"
      end
    end
  end
end

# metodo para pegar o status de um vm
def get_status_vm(vm_name,client)
  vm_pool = VirtualMachinePool.new(client, -1)
  rc = vm_pool.info
  if OpenNebula.is_error?(rc)
    puts rc.message
    exit -1
  end
  vm_pool.each do |vm|
    if ((vm.name <=> vm_name) == 0)
      return vm.lcm_state_str
    end  
  end
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



##############################################################################
# Main do Programa
##############################################################################

# dados para iniciar a conexao
client = Client.new(CREDENTIALS, ENDPOINT)

# variavel que liga DEAMON
rodar = 1

# loop que simula o DEAMON
while rodar == 1
  
  # guarda as vms monitoradas pelo servico  
  vms_encontradas = Array.new
  # guardar uma lista de vms com sua metrica de CPU
  vms_com_cpu_metricas = Array.new

  # for usado para checar as metricars 
  for rodada in  1..QTD_CHECKS 
    # 2) Coleta os dados das vms
    vms_encontradas = get_vm_list(VM_NOME, client) 

    if vms_encontradas.length == 0
      for new_vms in  1..QTD_VMS 
        vm_status = ''
        vm_nome_nova = create_new_vm(VM_NOME, TEMPLATE_O, client)
        while vm_status != 'RUNNING'
          vm_status  = get_status_vm(vm_nome_nova, client)
          sleep(10)
        end
      end
    end

    #aguardar 1 minutos para pegar as metricas
    sleep(60)
    #vms encontradas
    vms_encontradas = get_vm_list(VM_NOME, client)
    
    vms_com_cpu_metricas = get_cpu_value_by_vm(vms_encontradas)

    puts get_cpu_value_by_vm(vms_encontradas)
    puts '----'  
    puts ''
    
    sleep(INTERVALO)
  end

  # verifica se a lista de vms com suas metricas esta vazia
  if vms_com_cpu_metricas.length != 0
    
    #pega as metricas junto das vms
    vms_com_cpu_metricas.each do |vm_e_metrica|
      consumo_cpu = vm_e_metrica[1]
      vm_nome_antiga = vm_e_metrica[0]

      puts consumo_cpu.to_f
      puts vm_nome_antiga
      
      # verifica se o consumo maximo foi alcancado e se a vm ja nao foi upgraded
      if (consumo_cpu.to_f > CPU_MAX.to_f) and (!vm_nome_antiga.include? "n1-")
        
        # cria nova vm com mais recurso
        vm_nome_nova = create_new_vm(VM_NOME+"n1-", TEMPLATE_N1, client)
        vm_status = ''
        
        # verificar se ela ja subiu
        while vm_status != 'RUNNING'
          vm_status  = get_status_vm(vm_nome_nova, client)
          sleep(5)
        end

        # maquina antiga removida quando a nova estiver ok
        remove_old_vm(vm_nome_antiga,client)
      else
        puts "Nao foi necessario elevar a VM."
      end

      # verifica se o consumo minimo foi alcancado e se a vm ja nao foi downgraded
      if (consumo_cpu.to_f < CPU_MIN.to_f) and (vm_nome_antiga.include? "n1-")
        
        # cria a nova vm 
        vm_nome_nova = create_new_vm(VM_NOME, TEMPLATE_O, client)
        vm_status = ''
        
        # verifica o status da nova vm
        while vm_status != 'RUNNING'
          vm_status  = get_status_vm(vm_nome_nova, client)
          sleep(5)
        end
        # maquina antiga removida quando a nova estiver ok.
        remove_old_vm(vm_nome_antiga,client)
      end
    end
  end
end

