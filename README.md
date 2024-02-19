WIP section - stuff that will be put in another section once fixed
================================================================================

Turns out you need to be the root user to build containers right, even API key
isn't enough to allow the containers permissions to make mounts, so
username+password of root account it is


Tools Used
================================================================================

terraform
terragrunt
tfenv


Setting Up Proxmox
================================================================================

Essentially: https://github.com/Telmate/terraform-provider-proxmox/blob/master/docs/index.md

however, i have found the required perissions are in fact:
VM.Config.CPU, VM.Config.Options, VM.Config.Cloudinit, Sys.Modify, Sys.Console, VM.Config.HWType, VM.Audit, VM.Config.Network, Datastore.AllocateSpace, VM.Allocate, VM.Monitor, VM.Config.Memory, VM.Config.Disk, SDN.Use, Pool.Allocate, VM.PowerMgmt, VM.Config.CDROM, Sys.Audit, VM.Clone, VM.Migrate, Datastore.Audit

On  new PVE install,

1) Navigate to the datacenterin the left pane
2) Add a new user under Permissions/users
3) Call it something appropriate lke "terraform", it does not need a group, make
sure it is in the Proxmox realm, not PAM
4) Go to Permissions/API tokens, and create one for the terraform user, save the
credentials
5 Put the creds in this format inside a creds file:

```
export PROXMOX_VE_API_TOKEN="terraform@pve!terraform=xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxx"
```

6) Go to the permissions tab and add permissions, the ones in the link didn't
work for me though, so far I have found adding the following roles in the
"Permissions" tab to work...



While I was tryign I had an error, the following suggestion fixed it:
https://blog.griff.systems/published/2021/revert_node_certificates_to_default_in_proxmox_ve/

> Delete or move the following files:
> ```
> /etc/pve/pve-root-ca.pem
> /etc/pve/priv/pve-root-ca.key
> /etc/pve/nodes/<node>/pve-ssl.pem
> /etc/pve/nodes/<node>/pve-ssl.key
> ```
> 
> Regenerate certificates
> Afterwards, run the following command on each node of the cluster to re-generate the certificates and keys:
> 
> ```
> pvecm updatecerts -f
> ```

Configuring ansible
=
install the inventory plugin
cloud.terraform.terraform_provider
```
ansible-galaxy collection install cloud.terraform
```
https://github.com/ansible-collections/cloud.terraform/tree/main
