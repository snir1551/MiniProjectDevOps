resource "azurerm_linux_virtual_machine" "this" {
  name                = var.vm.name
  resource_group_name = var.resource_group_name
  location            = var.location
  size                = var.vm.size
  admin_username      = var.vm.admin_user

  network_interface_ids = [var.network_interface_id]

  admin_ssh_key {
    username   = var.vm.admin_user
    public_key = var.ssh_public_key
  }

  os_disk {
    caching              = var.vm.disk_caching
    storage_account_type = var.vm.disk_storage_type
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts-gen2"
    version   = "latest"
  }

  tags = var.tags

  custom_data = base64encode(<<EOF

  sudo apt-get update -y
  sudo apt-get install -y docker.io

  sudo systemctl enable docker
  sudo systemctl start docker

  # Docker Compose
  sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
  sudo chmod +x /usr/local/bin/docker-compose
  sudo ln -s /usr/local/bin/docker-compose /usr/bin/docker-compose

  # Setup Swap (optional)
  if ! swapon --show | grep -q '/swapfile'; then
    sudo fallocate -l 1G /swapfile
    sudo chmod 600 /swapfile
    sudo mkswap /swapfile
    sudo swapon /swapfileש
    echo '/swapfile none swap sw 0 0' | sudo tee -a /etc/fstab
  fi
EOF
)
}