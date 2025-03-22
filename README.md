Where to get it
================================================================================
Github repo available at:
```
https://github.com/zchfvy/home-pve
```

Tools Used
================================================================================

terraform
terragrunt
ansible

Please find install instructions for these online


Setting Up Proxmox
================================================================================

In order for proxmox to work properly you need to use the actual root
username/password as that is the only way to allow containers to do LXC mounts,
api keys or other accounts do not work.

you should make a file called `creds` inside this repository, with contenst like
below:

```
export PROXMOX_VE_USERNAME="root@pam"
export PROXMOX_VE_PASSWORD="my_secret_root_password"
```

When you run a new shell to use this, first run `source creds` to put those
variables into your environment before runnign anything.


Configuring ansible
================================================================================
install the inventory plugin `cloud.terraform.terraform_provider` by running the
command:
```
ansible-galaxy collection install cloud.terraform
```
https://github.com/ansible-collections/cloud.terraform/tree/main

Running
================================================================================

After that, you should be able to run individual books, or all of them via

```
terragrunt run-all apply
```
