# Project

Trabalho final - Roitier

## Estrutura do Projeto

Este projeto contém vários componentes, incluindo servidores web, DHCP e DNS, configurados usando Docker e Docker Compose.

### Arquivos e Diretórios

- `website/index.html`: Página web simples usando Bootstrap.
- `Dockerfile.dhcp`: Dockerfile para configurar um servidor DHCP.
- `Dockerfile.client`: Dockerfile para configurar um cliente web usando Nginx.
- `Dockerfile.apache`: Dockerfile para configurar um servidor web Apache.
- `docker-compose.yml`: Arquivo de configuração do Docker Compose para orquestrar os containers.
- `configs/named.conf.options`: Configuração do servidor DNS.
- `configs/httpd.conf`: Configuração do servidor Apache.
- `configs/dhcp.conf`: Configuração do servidor DHCP.
- `bootstrap.sh`: Script de inicialização para configurar o ambiente.
- `README.md`: Este arquivo de documentação.

## Descrição dos Arquivos

### `website/index.html`

Página HTML simples que utiliza Bootstrap para estilização.

```html
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>My Web Server</title>
  <link href="https://stackpath.bootstrapcdn.com/bootstrap/4.5.2/css/bootstrap.min.css" rel="stylesheet">
  <style>
    body {
      padding-top: 50px;
    }
    .container {
      text-align: center;
    }
  </style>
</head>
<body>
  <nav class="navbar navbar-expand-lg navbar-light bg-light fixed-top">
    <a class="navbar-brand" href="#">My Web Server</a>
  </nav>
  <div class="container">
    <h1 class="display-4">Welcome to my web server!</h1>
    <p class="lead">This is a simple, beautiful web page using Bootstrap.</p>
  </div>
  <script src="https://code.jquery.com/jquery-3.5.1.slim.min.js"></script>
  <script src="https://cdn.jsdelivr.net/npm/@popperjs/core@2.5.4/dist/umd/popper.min.js"></script>
  <script src="https://stackpath.bootstrapcdn.com/bootstrap/4.5.2/js/bootstrap.min.js"></script>
</body>
</html>
```

### `Dockerfile.dhcp`

Dockerfile para configurar um servidor DHCP usando a imagem base do Ubuntu.

```dockerfile
FROM ubuntu:latest

RUN apt-get update && apt-get install -y isc-dhcp-server net-tools
RUN touch /var/lib/dhcp/dhcpd.leases

COPY configs/dhcp.conf /etc/dhcp/dhcpd.conf

EXPOSE 67/udp

CMD ["dhcpd", "-f", "-d", "--no-pid"]
```

### `Dockerfile.client`

Dockerfile para configurar um cliente web usando Nginx.

```dockerfile
FROM ubuntu:latest

# Instalar nginx e remover pacotes desnecessários
RUN apt-get update && apt-get install -y nginx && apt-get clean

# Copiar o arquivo index.html para o diretório padrão do nginx
COPY website/index.html /var/www/html/

# Expor a porta 80 para acessar o servidor web
EXPOSE 80

# Iniciar o nginx em primeiro plano
CMD ["nginx", "-g", "daemon off;"]
```

### `Dockerfile.apache`

Dockerfile para configurar um servidor web Apache.

```dockerfile
# Usar a imagem mais recente do Apache
FROM httpd:latest

# Copiar o arquivo de configuração do Apache
COPY configs/httpd.conf /usr/local/apache2/conf/httpd.conf

# Copiar arquivos do site para o diretório padrão do Apache
COPY ./website /usr/local/apache2/htdocs/

# Expor a porta padrão do Apache
EXPOSE 80
EXPOSE 443

# Comando padrão para rodar o Apache
CMD ["httpd-foreground"]
```

### `docker-compose.yml`

Arquivo de configuração do Docker Compose para orquestrar os containers de web, DHCP, DNS e cliente.

```yaml
version: "3.9"
services:
  web:
    build:
      context: .
      dockerfile: Dockerfile.apache
    ports:
      - "8080:80"
    volumes:
      - ./configs/httpd.conf:/usr/local/apache2/conf/httpd.conf
  dhcp:
    build:
      context: .
      dockerfile: Dockerfile.dhcp
    ports:
      - "67:67/udp"
    cap_add:
      - NET_ADMIN  # Required for DHCP server
  dns:
    build:
      context: .
      dockerfile: Dockerfile.dns
    ports:
      - "53:53/tcp"
      - "53:53/udp"
  client:
    build:
      context: .
      dockerfile: Dockerfile.client
    depends_on:
      - web
      - dns
      - dhcp
    ports:
      - "8081:80"  # Expose port 80 of the client container to port 8081 on the host
networks:
  default:
    ipam:
      config:
        - subnet: 192.168.1.0/24
```

### `configs/named.conf.options`

Configuração do servidor DNS, incluindo encaminhadores e permissões de consulta.

```plaintext
options {
    directory "/var/cache/bind";

    forwarders {
        8.8.8.8;  # Google Public DNS
        8.8.4.4;  # Google Public DNS
    };

    allow-query { any; };  # Allow queries from any client (for testing purposes - restrict in production)
    recursion yes;        # Enable recursion

    listen-on-v6 { none; }; # Disable IPv6 listening (optional)
};
```

### `configs/httpd.conf`

Configuração do servidor Apache, incluindo módulos carregados, diretórios e políticas de segurança.

```properties
ServerRoot "/usr/local/apache2"
Listen 80

LoadModule mpm_prefork_module modules/mod_mpm_prefork.so
LoadModule authn_core_module modules/mod_authn_core.so
LoadModule authz_core_module modules/mod_authz_core.so
LoadModule dir_module modules/mod_dir.so
LoadModule mime_module modules/mod_mime.so
LoadModule log_config_module modules/mod_log_config.so
LoadModule alias_module modules/mod_alias.so
LoadModule headers_module modules/mod_headers.so

ServerName localhost:80

<Directory />
    AllowOverride none
    Require all denied
</Directory>

DocumentRoot "/usr/local/apache2/htdocs"
<Directory "/usr/local/apache2/htdocs">
    Options Indexes FollowSymLinks
    AllowOverride None
    Require all granted
</Directory>

ErrorLog /proc/self/fd/2
CustomLog /proc/self/fd/1 common

# Security Hardening
ServerTokens Prod
ServerSignature Off
TraceEnable Off
Header always append X-Frame-Options SAMEORIGIN
Header set X-Content-Type-Options nosniff
Header set Content-Security-Policy "default-src 'self'; script-src 'self' 'unsafe-inline'; style-src 'self' 'unsafe-inline'; img-src 'self' data:; font-src 'self'; object-src 'none'; frame-ancestors 'none'"
```

### `configs/dhcp.conf`

Configuração do servidor DHCP, incluindo sub-rede, intervalo de IPs e opções de rede.

```properties
subnet 192.168.1.0 netmask 255.255.255.0 {
  range 192.168.1.10 192.168.1.100;  # Adjusted range to avoid conflicts
  option routers 192.168.1.1;       # Default gateway (your firewall container)
  option domain-name-servers 192.168.1.2; # Your DNS server IP
  option domain-name "example.com";
  default-lease-time 600;
  max-lease-time 7200;
}
```

### `bootstrap.sh`

Script de inicialização para configurar o ambiente, incluindo a instalação de pacotes necessários e configuração do Docker e Docker Compose.

```bash
#!/bin/bash

set -e

# Disable systemd-resolved
sudo systemctl stop systemd-resolved
sudo systemctl disable systemd-resolved
sudo rm /etc/resolv.conf

# Set DNS
echo "nameserver 8.8.8.8" | sudo tee /etc/resolv.conf
echo "nameserver 8.8.4.4" | sudo tee -a /etc/resolv.conf

# Restart networking service to apply DNS changes
sudo systemctl restart networking

# Update package list
sudo apt-get update

# Install necessary packages
sudo apt-get install -y \
    docker.io \
    net-tools \
    curl

# Add vagrant user to docker group and apply immediately
sudo usermod -aG docker vagrant && newgrp docker

# Start Docker service
sudo systemctl start docker
sudo systemctl enable docker

# Verify docker is installed
docker --version

# Docker Compose install
sudo curl -L "https://github.com/docker/compose/releases/download/v2.24.1/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose

# Test docker-compose (Important!)
docker-compose version

# Project Setup
sudo mkdir -p /srv/www

# cp -r /vagrant/* /srv/www  # Alternative:  Use this if you're sure vagrant is in the project directory.  Then you would use "sudo dos2unix *" below the cd /srv/www command
cd /srv/www

# Correct file extensions
find . -name "*.txt" -exec sh -c 'mv "$1" "${1%.txt}"' _ {} \;

# Use dos2unix if possible, fall back to sed
if ! sudo apt-get install -y dos2unix > /dev/null 2>&1; then
    echo "dos2unix installation failed. Falling back to sed..."
    find . -type f \( -name "*.sh" -o -name "*.yml" -o -name "Dockerfile.*" \) -exec sed -i 's/\r$//' {} \;
else
    echo "Converting line endings with dos2unix..."
    sudo find . -type f \( -name "*.sh" -o -name "*.yml" -o -name "Dockerfile.*" \) -exec dos2unix {} \;
fi

# Ensure necessary config files exist
for file in configs/dhcp.conf configs/rndc.key configs/httpd.conf; do
    if [ ! -f $file ]; then
        echo "Error: $file not found!"
        exit 1
    fi
done

docker-compose up -d
```

## Como Usar

1. Clone o repositório:
    ```bash
    git clone https://github.com/usuario/projeto.git
    cd projeto
    ```

2. Execute o script de inicialização:
    ```bash
    ./bootstrap.sh
    ```

3. Inicie os containers usando Docker Compose:
    ```bash
    docker-compose up -d
    ```

4. Acesse o servidor web no navegador:
    - Apache: `http://localhost:8080`
    - Nginx: `http://localhost:8081`

## Subindo a VM

1. Certifique-se de que o Vagrant e o VirtualBox estão instalados.
2. No diretório do projeto, execute o comando:
    ```bash
    vagrant up
    ```

3. A VM será provisionada e configurada automaticamente. Isso pode levar alguns minutos.

## Iniciando os Containers

1. Após a VM estar em execução, acesse-a via SSH:
    ```bash
    vagrant ssh
    ```

2. Navegue até o diretório do projeto:
    ```bash
    cd /srv/www
    ```

3. Inicie os containers usando Docker Compose:
    ```bash
    docker-compose up -d
    ```

4. Verifique se os containers estão em execução:
    ```bash
    docker ps
    ```

## Acessando os Serviços

- Servidor Apache: `http://localhost:8080`
- Servidor Nginx: `http://localhost:8081`

## Testes 

 ## iniciando os conteineres com o comando "docker-compose up -d" 

![image](https://github.com/user-attachments/assets/79ae93dc-3c76-40f8-a271-1f424f553269)

## Logs utilizando o comando "docker-compose logs"

![image](https://github.com/user-attachments/assets/6b834e0c-865d-4f53-96c8-b3da207eeeb9)

![image](https://github.com/user-attachments/assets/62fec7ef-ddfc-411a-bc18-e826245ef211)

![image](https://github.com/user-attachments/assets/a6680eac-d0ed-45fb-ac57-a27162ff2c4b)
