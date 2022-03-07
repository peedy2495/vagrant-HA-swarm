
# -*- mode: ruby -*-
# vi: set ft=ruby :

VAGRANTFILE_API_VERSION = 2

# generate ssh keys for passwordless vice versa guest accesses
puts `chmod +x assets/createSSHKeys.sh`
puts `assets/createSSHKeys.sh`

# get external dependencies
puts `chmod +x assets/pull_gitrepos.sh`
puts `assets/pull_gitrepos.sh`

# get external binaries
puts `chmod +x assets/pull_binaries.sh`
puts `assets/pull_binaries.sh`

# get external certs
puts `chmod +x assets/pull_certs.sh`
puts `assets/pull_certs.sh`

# Ensure yaml module is loaded
require 'yaml'

#requires: plugin vagrant-reload
require 'vagrant-reload'

# get hostname
require "socket"
HOST = Socket.gethostname

# Read yaml node definitions to create **Update environment.yml to reflect any changes
environment = YAML.load_file('assets/environment.yaml')

# get common environment keys
env_common = environment['env_common']

ASSETS = env_common["assets"]

# get global settings in variables
virt_settings = environment['virt']

# get nodes to be used
nodes = environment['nodes']

Vagrant.configure(VAGRANTFILE_API_VERSION) do |config|
    
    # Provide assets to every instance
    #config.vm.synced_folder "assets/", "/mnt/vagrant", mount_options: ["vers=3,tcp"]
    
    #Disabling the default /vagrant share
    config.vm.synced_folder ".", "/vagrant", disabled: true

    #Provide assets to every instance
    config.vm.provision "file", source: "assets" , destination: "#{ASSETS}"

    config.vm.provision :shell, :path => "assets/provision_base.sh", :args => ["#{ASSETS}"]

    nodes.each_with_index do |nodes, index|
        if HOST == nodes["host"]
            config.vm.define nodes["name"] do |node|
                node.vm.hostname = "#{nodes["name"]}.#{env_common["domain"]}"
                node.vm.box = virt_settings['box']
                ints = nodes["interfaces"]
                ints.each do |int|
                    if int["method"] == "static" and int["type"] == "private_network" and int["network_name"] != "None" and int["auto_config"] == "True"
                        node.vm.network "private_network", ip: int["ip"], virtualbox__intnet: int["network_name"]
                    end
                    if int["method"] == "static" and int["type"] == "private_network" and int["network_name"] != "None" and int["auto_config"] == "False"
                        node.vm.network "private_network", ip: int["ip"], virtualbox__intnet: int["network_name"], auto_config: false
                    end
                    if int["method"] == "static" and int["type"] == "private_network" and int["network_name"] == "None" and int["auto_config"] == "True"
                        node.vm.network "private_network", ip: int["ip"]
                    end
                    if int["method"] == "static" and int["type"] == "private_network" and int["network_name"] == "None" and int["auto_config"] == "False"
                        node.vm.network "private_network", ip: int["ip"], auto_config: false
                    end
                    if int["method"] == "dhcp" and int["type"] == "private_network"
                        node.vm.network "private_network", type: "dhcp"
                    end
                end

                node.vm.provider "libvirt" do |libvirt|
                    libvirt.memory = nodes["mem"]
                    libvirt.cpus = nodes["cpus"]
                    libvirt.storage_pool_name = "machines"
                    libvirt.driver = "kvm"
                    libvirt.cpu_mode = 'host-model'
                    libvirt.cpu_model = 'qemu64'
                    libvirt.storage :file, :size => '10G', :format => 'qcow2'
                end

                node.vm.provision :reload
                node.vm.provision "file", source: "assets" , destination: "#{ASSETS}"
                node.vm.provision :shell, :path => "assets/provision_docker.sh", :args => ["install"]
                node.vm.provision :shell, :path => "assets/provision_gluster.sh", :args => ["install"]

                if nodes["type"] == "init"
                    node.vm.provision :shell, :path => "assets/provision_gluster.sh", :args => ["peer"]
                    node.vm.provision :shell, :path => "assets/provision_gluster.sh", :args => ["mkvol"]
                    node.vm.provision :shell, :path => "assets/provision_docker.sh", :args => ["swarm-rollout"]
                end

                node.vm.provision :shell, :path => "assets/provision_gluster.sh", :args => ["mntvol"]
                node.vm.provision :shell, :path => "assets/provision_keepalived.sh"

                if nodes["type"] == "init"
                    node.vm.provision :shell, :path => "assets/deploy_stacks.sh"
                end
            end
        end
    end
end