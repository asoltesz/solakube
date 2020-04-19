# SolaKube Vagrant box

There is a pre-built Vagrant box that can be used to run SolaKube without installing any of its code or dependencies on your computer.

That runs as a Virtual Machine (VM) on your computer.

# Requirements

You need to have Virtualbox and Vagrant installed on your computer. See publicly available guides for these.  

# Installation

Get the Vagrantfile from the SolaKube repo or checkout the whole repo.

Start the VM from the root folder of solacube (in which the Vagrantfile is placed):

```
vagrant up
```

NOTE: The folder, in which you have the Vagrantfile will be attached inside the VM as the /vagrant folder.



# Configuration

After the Vargrant/Virtualbox VM has been started you can start configuring parameters that drive the SolaKube cluster creaton process.

The configuration files and their contents are described in the [Configuration page](configuration.md).

You may edit the config files in the following ways:
- editing inside the VM (e.g.: with nano)
- sharing the ~/.solakube and other config folders from your host with VirtualBox's shared folder configurator tool and edit the files on the host
- sharing the VM's /home/solakube folder with Samba ([article](https://www.howtogeek.com/howto/ubuntu/share-ubuntu-home-directories-using-samba/) and edit the files from your host via an smb share (via your file manager like Dolphin, Thunar, Gnome Files...etc).

Login into the machine with **vagrant ssh** to execute solakube or edit files inside.

All further commands are intended to be executed inside the VM, unless otherwise stated.

## Ansible vault password

The default Ansible vault password in the box is not suitable for your use so you need to change it to something only you know.

Set the Ansible vault password into the vault-password file: 

```
nano ~/.solakube/ansible-vault-pass
```

### Create your own encrypted vault file with empty/sample values

This creates a default vault with empty/sample values in the vault file:

```
cd ~/solakube/ansible

rm -Rf group_vars/all/vault.yml

cp /vagrant/provision/vault-content.yaml group_vars/all/vault.yml
 
ansible-vault encrypt group_vars/all/vault.yml
```

You may edit the values in the vault with "~/solakube/scripts/edit-vault.sh"

## variables.sh

### Copying over your own

Assuming you place it in the shared "secret" subfolder to copy them over.
```
rm -Rf ~/.solakube/andromeda/variables.sh
cp /vagrant/secret/variables.sh ~/.solakube/andromeda/
```

### Editing within the box

```
nano ~/.solakube/andromeda/variables.sh
```

## SSL key pair

The id_rsa key pair is needed because its public key that will be defined in the VMs and they allow you and SolaKube/Terraform/Ansible to SSH into the machines for provisioning.

### Generating the keys

See the relevant section in the [Configuration page](configuration.md).

### Copying the SSL key pair

Assuming you had a keypair generated on your host, copy them into a folder name "secret" opening from the folder of your Vagrantfile and run these in the box.

```
cp /vagrant/secret/id_rsa ~/.ssh/
chmod 600 ~/.ssh/id_rsa
cp /vagrant/secret/id_rsa.pub ~/.ssh/
```
