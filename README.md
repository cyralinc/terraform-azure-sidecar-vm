# Cyral sidecar module for Azure VM

Use this Terraform module to deploy a sidecar on Azure VM instances.

Refer to the [quickstart guide](https://github.com/cyral-quickstart/quickstart-sidecar-terraform-azure-vm#readme)
for more information on how to use this module or upgrade your sidecar.

## Architecture

![Deployment architecture](https://raw.githubusercontent.com/cyralinc/terraform-azure-sidecar-vm/main/images/azure_architecture.png)

The elements shown in the architecture diagram above are deployed by this module.
The module requires existing VPC and subnets in order to create the necessary
components for the sidecar to run. In a high-level, these are the resources deployed:

* VM
    * Scale set (responsible for managing VM instances)
    * Network load balancer (optional)
    * Security group
* Key Vault
    * Sidecar credentials
    * Sidecar CA certificate
    * Sidecar self-signed certificate
* IAM
    * Sidecar role
* Azure Analytics
    * Log group (optional)

## Usage

```hcl
provider "azurerm" {
  # This feature is to immediately destroy secrets when `terraform destroy`
  # is executed. We advise you to remove it for production sidecars.
  features {
    key_vault {
      purge_soft_delete_on_destroy = true
    }
  }
}

module "cyral_sidecar" {
  source = "cyralinc/sidecar-vm/azure"
  version = "~> 1.0" # terraform module version
  
  sidecar_id    = ""
  control_plane = ""
  client_id     = ""
  client_secret = ""

  # Leave empty if you prefer to perform upgrades directly
  # from the control plane.
  sidecar_version = ""

  # Considering MongoDB ports are from the range 27017 to 27019
  sidecar_ports = [443, 3306, 5432, 27017, 27018, 27019]

  # Subnets to use to deploy VMs
  subnets = [""]
  
  # Source address prefixes for SSH into the VM instances
  ssh_source_address_prefixes = ["0.0.0.0/0"]
  # Source address prefixes to access ports defined in `sidecar_ports`
  db_source_address_prefixes = ["0.0.0.0/0"]
  # Source address prefixes to monitor the VM instances (port 9000)
  monitoring_source_address_prefixes = ["0.0.0.0/0"]

  # Location that will be used to deploy the resource group
  # containing the sidecar resources
  resource_group_location = ""

  # Path to the public key that will be used to SSH into the VMs
  admin_ssh_key = file("/Users/me/.ssh/id_ed25519.pub")
}
```
**Note:**

- `name_prefix` is defined automatically. If you wish to define a custom
  `name_prefix`, please keep in mind that its length must be **at most 24
  characters**.

## Upgrade

### Module upgrade

If you are coming from `v4` of this module, read the
[upgrade notes](https://github.com/cyralinc/terraform-azure-sidecar-vm/blob/main/docs/upgrade-notes.md) for specific
instructions on how to upgrade this module.

### Sidecar upgrade

This module supports [1-click upgrade](https://cyral.com/docs/sidecars/manage/upgrade#1-click-upgrade).

To enable the 1-click upgrade feature, leave the variable `sidecar_version` empty and upgrade
the sidecar from Cyral control plane.

If you prefer to block upgrades from the Cyral control plane and use a **static version**, assign
the desired sidecar version to `sidecar_version`. To upgrade your sidecar, update this parameter
with the target version and run `terraform apply`.

Learn more in the [sidecar upgrade procedures](https://cyral.com/docs/sidecars/manage/upgrade) page.

## Advanced

Instructions for advanced deployment configurations are available for the following topics:

* [Advanced networking configuration](https://github.com/cyralinc/terraform-azure-sidecar-vm/blob/main/docs/networking.md)
* [Bring your own secret](https://github.com/cyralinc/terraform-azure-sidecar-vm/blob/main/docs/byos.md)
* [Customer initialization scripts](https://github.com/cyralinc/terraform-azure-sidecar-vm/blob/main/docs/custom-user-data.md)
* [Memory limits](https://github.com/cyralinc/terraform-azure-sidecar-vm/blob/main/docs/memlim.md)
* [Sidecar certificates](https://github.com/cyralinc/terraform-azure-sidecar-vm/blob/main/docs/certificates.md)
* [Sidecar instance metrics](https://github.com/cyralinc/terraform-azure-sidecar-vm/blob/main/docs/metrics.md)

<!-- BEGIN_TF_DOCS -->
<!-- END_TF_DOCS -->
