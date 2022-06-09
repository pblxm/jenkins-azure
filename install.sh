#!/bin/bash
# INSTALL TERRAFORM, ANSIBLE AND DOCKER

read -r -p "Choose OS: Ubuntu (1), CentOS (2), Amazon Linux (3), Fedora (4) = " choice

case $choice in
  1)
    curl -fsSL https://apt.releases.hashicorp.com/gpg | sudo apt-key add -
    sudo apt-add-repository "deb [arch=amd64] https://apt.releases.hashicorp.com $(lsb_release -cs) main"
    sudo apt-get update && sudo apt-get install terraform -y
    sudo apt install software-properties-common -y
    sudo add-apt-repository --yes --update ppa:ansible/ansible
    sudo apt install ansible -y 
    sudo apt-get install ca-certificates curl gnupg lsb-release -y
    sudo test -d /etc/apt/keyrings || sudo mkdir -p /etc/apt/keyrings
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
    sudo apt-get update; sudo apt-get install docker-ce docker-ce-cli containerd.io docker-compose-plugin docker-compose -y
    curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash ;;
  2)
    sudo yum install -y yum-utils
    sudo yum-config-manager --add-repo https://rpm.releases.hashicorp.com/RHEL/hashicorp.repo
    sudo yum -y install terraform epel-release ansible 
    sudo yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo 
    sudo yum install docker-ce docker-ce-cli containerd.io docker-compose-plugin 
    curl -L https://aka.ms/InstallAzureCli | bash ;;
  3)
    sudo yum install -y yum-utils
    sudo yum-config-manager --add-repo https://rpm.releases.hashicorp.com/AmazonLinux/hashicorp.repo
    sudo yum -y install terraform docker docker-compose
    sudo amazon-linux-extras install ansible2 -y 
    curl -L https://aka.ms/InstallAzureCli | bash ;;
  4)
    sudo dnf install -y dnf-plugins-core
    sudo dnf config-manager --add-repo https://rpm.releases.hashicorp.com/fedora/hashicorp.repo
    sudo dnf -y install terraform ansible
    sudo dnf config-manager --add-repo https://download.docker.com/linux/fedora/docker-ce.repo 
    sudo dnf install docker-ce docker-ce-cli containerd.io docker-compose-plugin 
    sudo rpm --import https://packages.microsoft.com/keys/microsoft.asc
    sudo dnf install -y https://packages.microsoft.com/config/rhel/8/packages-microsoft-prod.rpm
    sudo dnf install azure-cli ;;
  *)
    exit ;;
esac