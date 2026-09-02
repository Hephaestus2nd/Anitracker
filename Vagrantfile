Vagrant.configure("2") do |config|
  config.vm.box = "ubuntu/jammy64"

  config.vm.define "frontend" do |frontend|
    frontend.vm.hostname = "frontend"
    frontend.vm.network "private_network", ip: "10.10.10.10"
    frontend.vm.network "forwarded_port", guest: 80, host: 8081
    frontend.vm.provider "virtualbox" do |vb|
      vb.memory = 1024
      vb.cpus = 1
    end
    frontend.vm.provision "shell", path: "provision/frontend.sh"
  end

  config.vm.define "api" do |api|
    api.vm.hostname = "api"
    api.vm.network "private_network", ip: "10.10.10.11"
    api.vm.network "forwarded_port", guest: 8080, host: 8080
    api.vm.provider "virtualbox" do |vb|
      vb.memory = 1536
      vb.cpus = 2
    end
    api.vm.provision "shell", path: "provision/api.sh"
  end

  config.vm.define "db" do |db|
    db.vm.hostname = "db"
    db.vm.network "private_network", ip: "10.10.10.12"
    db.vm.network "forwarded_port", guest: 5432, host: 5432
    db.vm.provider "virtualbox" do |vb|
      vb.memory = 1024
      vb.cpus = 1
    end
    db.vm.provision "shell", path: "provision/db.sh"
  end
end
