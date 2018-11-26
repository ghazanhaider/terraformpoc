provider "azurerm" {
    subscription_id = "${var.subscription_id}"
    client_id       = "${var.client_id}"
    client_secret   = "${var.client_secret}"
    tenant_id       = "${var.tenant_id}"
}


resource "azurerm_resource_group" "rg" {
        name = "${var.resource_group}"
        location = "${var.location}"
}

resource "azurerm_virtual_network" "vnet" {
    name                = "my_vnet"
    address_space       = ["10.0.0.0/16"]
    location            = "${azurerm_resource_group.rg.location}"
    resource_group_name = "${azurerm_resource_group.rg.name}"
}

resource "azurerm_subnet" "subnet" {
    name                 = "my_subnet"
    resource_group_name  = "${azurerm_resource_group.rg.name}"
    virtual_network_name = "${azurerm_virtual_network.vnet.name}"
    address_prefix       = "10.0.2.0/24"
}

resource "azurerm_public_ip" "publicip" {
    name                         = "my_publicip"
    location                     = "${azurerm_resource_group.rg.location}"
    resource_group_name          = "${azurerm_resource_group.rg.name}"
    public_ip_address_allocation = "dynamic"
}

resource "azurerm_network_security_group" "nsg" {
    name                = "my_nsg"
    location            = "${azurerm_resource_group.rg.location}"
    resource_group_name = "${azurerm_resource_group.rg.name}"

    security_rule {
        name                       = "SSH"
        priority                   = 1001
        direction                  = "Inbound"
        access                     = "Allow"
        protocol                   = "Tcp"
        source_port_range          = "*"
        destination_port_range     = "22"
        source_address_prefix      = "*"
        destination_address_prefix = "*"
    }
}


resource "azurerm_network_interface" "nic" {
    name                = "my_nic"
    location            = "${azurerm_resource_group.rg.location}"
    resource_group_name = "${azurerm_resource_group.rg.name}"
    network_security_group_id = "${azurerm_network_security_group.nsg.id}"

    ip_configuration {
        name                          = "my_nic_configuration"
        subnet_id                     = "${azurerm_subnet.subnet.id}"
        private_ip_address_allocation = "dynamic"
        public_ip_address_id          = "${azurerm_public_ip.publicip.id}"
    }
}












resource "azurerm_virtual_machine" "vm" {
    name                  = "${var.vm_name}"
    location              = "${azurerm_resource_group.rg.location}"
    resource_group_name   = "${azurerm_resource_group.rg.name}"
    network_interface_ids = ["${azurerm_network_interface.nic.id}"]
    vm_size               = "${var.vm_size}"

    storage_os_disk {
        name              = "my_osdisk"
        caching           = "ReadWrite"
        create_option     = "FromImage"
        managed_disk_type = "Standard_LRS"
    }

    storage_image_reference {
        publisher = "Canonical"
        offer     = "UbuntuServer"
        sku       = "18.04-LTS"
        version   = "latest"
    }

    os_profile {
        computer_name  = "${var.vm_name}"
        admin_username = "${var.username}"
    }

    os_profile_linux_config {
        disable_password_authentication = true
        ssh_keys {
            path     = "/home/${var.username}/.ssh/authorized_keys"
            key_data = "${var.ssh_key}"
        }
    }

}


