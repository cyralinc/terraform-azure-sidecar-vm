resource "azurerm_network_security_group" "nsg" {
  name                = "${local.name_prefix}-network-security-group"
  location            = azurerm_resource_group.resource_group.location
  resource_group_name = azurerm_resource_group.resource_group.name
}

resource "azurerm_network_security_rule" "security_rule_ssh" {
  count = length(var.ssh_source_address_prefixes) == 0 ? 0 : 1

  resource_group_name         = azurerm_resource_group.resource_group.name
  name                        = "${local.name_prefix}-nsr-ssh"
  priority                    = 101
  direction                   = "Inbound"
  access                      = "Allow"
  source_port_range           = "*"
  protocol                    = "Tcp"
  destination_port_range      = 22
  source_address_prefixes     = var.ssh_source_address_prefixes
  destination_address_prefix  = "*"
  network_security_group_name = azurerm_network_security_group.nsg.name
}

resource "azurerm_network_security_rule" "security_rule_monitoring" {
  count = length(var.monitoring_source_address_prefixes) == 0 ? 0 : 1

  resource_group_name         = azurerm_resource_group.resource_group.name
  name                        = "${local.name_prefix}-nsr-monitoring"
  priority                    = 100
  direction                   = "Inbound"
  access                      = "Allow"
  source_port_range           = "*"
  protocol                    = "Tcp"
  destination_port_range      = 9000
  source_address_prefixes     = var.monitoring_source_address_prefixes
  destination_address_prefix  = "*"
  network_security_group_name = azurerm_network_security_group.nsg.name
}

resource "azurerm_network_security_rule" "security_rule_sidecar_inbound" {
  count = length(var.sidecar_ports)

  resource_group_name         = azurerm_resource_group.resource_group.name
  name                        = "${local.name_prefix}-nsr-${element(var.sidecar_ports, count.index)}"
  priority                    = 102 + count.index
  direction                   = "Inbound"
  access                      = "Allow"
  source_port_range           = "*"
  protocol                    = "Tcp"
  destination_port_range      = element(var.sidecar_ports, count.index)
  source_address_prefixes     = var.db_source_address_prefixes
  destination_address_prefix  = "*"
  network_security_group_name = azurerm_network_security_group.nsg.name
}

resource "azurerm_subnet_network_security_group_association" "subnet_nsg_association" {
  count                     = length(var.subnets)
  subnet_id                 = var.subnets[count.index]
  network_security_group_id = azurerm_network_security_group.nsg.id
}
