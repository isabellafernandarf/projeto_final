Vagrant.configure("2") do |config|
  # Atualizando para a última versão do Ubuntu
  config.vm.box = "ubuntu/jammy64"  # Para Ubuntu 22.04 LTS (mais recente no momento)

  # Configuração de rede
  config.vm.network "private_network", ip: "192.168.50.5"  # IP estático (ajuste conforme necessário)

  # Redirecionamento de porta
  config.vm.network "forwarded_port", guest: 80, host: 8081  # Mapeia porta 80 da VM para 8081 no host

  # Script de provisionamento
  config.vm.provision "shell", path: "bootstrap.sh"  # Script para configuração inicial

  # Timeout para boot (ajuda em conexões lentas)
  config.vm.boot_timeout = 1200

  # Desabilita a pasta compartilhada padrão
  config.vm.synced_folder ".", "/vagrant", disabled: true

  # Sincroniza a pasta do projeto com a VM
  config.vm.synced_folder ".", "/srv/www", type: "rsync", 
    rsync__exclude: [".git/", ".vagrant/", "node_modules/"]  # Exclui arquivos/folders desnecessários

  # Configura recursos de hardware da VM
  config.vm.provider "virtualbox" do |vb|
    vb.memory = "2048"   # Memória RAM (ajuste conforme necessidade)
    vb.cpus = 2          # Número de CPUs
  end
end
