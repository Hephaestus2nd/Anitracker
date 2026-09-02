# -*- mode: ruby -*-
# vi: set ft=ruby :

Vagrant.configure("2") do |config|
  config.vm.box = "ubuntu/jammy64"
  config.vm.synced_folder ".", "/vagrant", disabled: false
  config.vm.provider "virtualbox" do |vb|
    vb.memory = 2048
    vb.cpus = 2
  end

  config.vm.define "db" do |db|
    db.vm.hostname = "movie-db"
    db.vm.network "private_network", ip: "192.168.56.10"
    db.vm.network "forwarded_port", guest: 5432, host: 5433
    db.vm.provision "shell", path: "provision/db_provision.sh"
  end

  config.vm.define "api" do |api|
    api.vm.hostname = "movie-api"
    api.vm.network "private_network", ip: "192.168.56.11"
    api.vm.network "forwarded_port", guest: 8080, host: 8081
    api.vm.provision "shell", path: "provision/api_provision.sh"
  end

  config.vm.define "web" do |web|
    web.vm.hostname = "movie-web"
    web.vm.network "private_network", ip: "192.168.56.12"
    web.vm.network "forwarded_port", guest: 80, host: 8080
    web.vm.provision "shell", path: "provision/web_provision.sh"
  end
end
