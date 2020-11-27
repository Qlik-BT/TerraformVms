## VARIABLE BLOCK
variable "subscription" {
  description = "Subscription ID from Azure Portal"
  default     = ""
}

variable "location" {
  description = "Azure Region"
  default     = ""
}

variable "owner" {
  description = "Your email address"
  default     = ""
}

variable "snap_rg_name" {
  description = "Name of Resource Group with the Snapshot"
  default     = ""
}

variable "snap_id" {
  description = "Resource ID of the Snaphot. Can be found under properties in the Azure Portal"
  default     = ""
}

variable "storage_account_type" {
  description = "The type of storage to use for the managed disk"
  default     = "Standard_LRS"
}

variable "public_ip" {
  description = "It's because of people like you that we cannot have nice things. Public IPs on Cloud VMs are generally a TERRIBLE idea. Do not use them unless you have a really, REALLY good reason. If you do, makes sure your VMs are up to date and you have all the appropriate security agents installed. Let the Security Team know. Then have a long hard think about the direction your life is taking."
  default     = false
}

variable "vnet_id" {
  description = "This can be found in the Azure portal under properties"
  default     = ""
}

variable "subnet_name" {
  description = "The name of the subnet you are going to deploy to"
  default     = ""
}

variable "os_type" {
  description = "The OS Type that the snapshot was made from. linux or windows. Case sensitive"
  default     = "windows"
}

variable "vm_rg_name" {
  description = "Name of Resource Group for the VM"
  default     = ""
}

variable "vm_number" {
  description = "The amount of VMs you need to create from a snapshot"
  default     = 1
}

variable "vm_name" {
  description = "The name of your VM. This will become a suffix, followed by a number. Eg: test-vm-0"
  default     = ""
}

variable "vm_size" {
  description = "The SKU of your VM. Must be a valid Azure size"
  default     = "Standard_B2s"
}

variable "vm_username" {
  description = "The username for logging into you VM"
  default = "qlikadmin"  
}

## LOCALS BLOCK ##

locals {
  disk_name = "${var.vm_name}-disk"
  ip_name   = "${var.vm_name}-ip"
  nic_name  = "${var.vm_name}-nic"
  subnet_id = "${var.vnet_id}/subnets/${var.subnet_name}"
  tags = {
    "Owner" = var.owner
    "ShutdownTime" = "1800"
  }
}

## PROVIDER BLOCK ##

provider "azurerm" {
  features {}
  subscription_id = var.subscription
}

## RESOURCES BLOCK ##

resource "azurerm_managed_disk" "vm_disk" {
  count                = var.vm_number
  name                 = "${local.disk_name}-${count.index}"
  location             = var.location
  resource_group_name  = var.vm_rg_name
  storage_account_type = var.storage_account_type
  create_option        = "Copy"
  source_resource_id   = var.snap_id
  os_type              = var.os_type
}

resource "azurerm_public_ip" "vm_ip" {
  count               = var.public_ip ? var.vm_number : 0
  name                = "${local.ip_name}-${count.index}"
  resource_group_name = var.vm_rg_name
  location            = var.location
  allocation_method   = "Dynamic"
  sku                 = "Basic"
}

resource "azurerm_network_interface" "private_nic" {
  count               = var.public_ip == false ? var.vm_number : 0
  name                = "${local.nic_name}-${count.index}"
  location            = var.location
  resource_group_name = var.vm_rg_name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = local.subnet_id
    private_ip_address_allocation = "Dynamic"

  }
}

resource "azurerm_network_interface" "public_nic" {
  count               = var.public_ip ? var.vm_number : 0
  name                = "${local.nic_name}-${count.index}"
  location            = var.location
  resource_group_name = var.vm_rg_name
  depends_on          = [azurerm_public_ip.vm_ip]

  ip_configuration {
    name                          = "public"
    subnet_id                     = local.subnet_id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.vm_ip[count.index].id

  }
}

resource "azurerm_network_security_group" "public_ip_nsg" {
  count               = var.public_ip ? 1 : 0
  name                = "${var.vm_name}-sg"
  location            = var.location
  resource_group_name = var.vm_rg_name

  security_rule {
    name                       = "Block_RDP"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Deny"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "3389"
    source_address_prefix      = "Internet"
    destination_address_prefix = "*"
  }
  security_rule {
    name                       = "Block_SSH"
    priority                   = 101
    direction                  = "Inbound"
    access                     = "Deny"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "Internet"
    destination_address_prefix = "*"
  }

}

resource "azurerm_network_interface_security_group_association" "sg_assoc" {
  count                     = var.public_ip ? var.vm_number : 0
  network_interface_id      = azurerm_network_interface.public_nic[count.index].id
  network_security_group_id = azurerm_network_security_group.public_ip_nsg[0].id
}

data "azurerm_network_interface" "vm_nic" {
  count               = var.vm_number
  name                = "${local.nic_name}-${count.index}"
  resource_group_name = var.vm_rg_name
  depends_on          = [azurerm_network_interface.public_nic, azurerm_network_interface.private_nic]
}

resource "azurerm_virtual_machine" "linux_vm" {
  count               = var.os_type == "linux" ? var.vm_number : 0
  resource_group_name = var.vm_rg_name
  location            = var.location
  name                = "${var.vm_name}-${count.index}"
  vm_size             = var.vm_size

  network_interface_ids = [
    data.azurerm_network_interface.vm_nic[count.index].id
  ]

  storage_os_disk {
    name = "${local.disk_name}-${count.index}"
    managed_disk_id = azurerm_managed_disk.vm_disk[count.index].id
    create_option   = "Attach"
    os_type = var.os_type

  }
  
  tags = local.tags

}

## There are two conditional VM resources as we will eventually move to the OS specific virtual machine resources
## This is because azurerm_virtual_machine is deprecated

resource "azurerm_virtual_machine" "windows_vm" {
  count               = var.os_type == "windows" ? var.vm_number : 0
  resource_group_name = var.vm_rg_name
  location            = var.location
  name                = "${var.vm_name}-${count.index}"
  vm_size             = var.vm_size

  network_interface_ids = [
    data.azurerm_network_interface.vm_nic[count.index].id
  ]

  storage_os_disk {
    name = "${local.disk_name}-${count.index}"
    managed_disk_id = azurerm_managed_disk.vm_disk[count.index].id
    create_option   = "Attach"
    os_type = var.os_type

  }
  
  tags = local.tags

}
