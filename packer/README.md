# Building a virtual machine template
In order to manage a system, you need to be able to login to it with an account that has administrative privileges. Furthermore, if you are not sittng at the system console, you will need a way to connect to the system remotely. The same is true for configuration management tools like Ansible, the one we will be using. However, before we can configure remote access and administrative accounts, the system has to first exist.  You could manually create a virtual machine in Proxmox and manually install an operating system on it, but that process is slow and prone to human error. Instead, we will use Terraform to create virtual machines according to our specifications. We will store these specifications in a configuration file which will be stored within our git repository. Storing all our configuration files in a version control system allows us to track changes over time and roll back to past versions if necessary.

Terraform will create new virtual machines in Proxmox by cloning them from existing virtual machine templates.  After Terraform clones a new virtual machine from a template, it may optionally modify the hardware according to our spcification. Once Terraform has finished configuring the virtual machine's hardware, will then start the virtual machine. Terraform will log into the virtual machine remotely after the operating system has booted, and use Ansible to change the configuration of the system from a generic clone to a system built for a specific purpose. All we need now is a virtual machine template which is already configured with a known administrative account that allows remote logins.  We could manually create the template from a manually created virtual machine with a manually installed operating system and remote access service and administrative account that were added by hand, but that doesn't sound like a reliable, repeatable process.  Enter Packer.

Packer is a tool for creating reusable system images for a variety of virtualization and cloud platforms.  Like Terraform, it will create a virtual machine acording to the settings in its configuration file. However, rather than cloning an existing template like Terraform, Packer will instead boot the operating system's installation media and drive the interactive installation of the operating system by sending the keystrokes needed to complete the installation process as if it were a person sitting at the system console. Depending on the operating system, the installation may be further automated through the use of an installer file. An installer file is a text file passed to the operating system's installer which contains answers to all the installer's questions. By passing the installer file to the installer at startup, Packer can bypass the rest of the interactive installation questions. On Red Hat based systems, the installer file is known as a "Kickstart" file and on Debian based systems it is known as a "Preseed" file.  Since the operating system installers are different, kickstart and preseed files have a different format even if they accomplish the same objective.

In addition to creating the virtual machine and driving the operating system's install process, Packer also, conveniently, pretends to be a web server which allows the operating system's installer to download the installer file (kickstart or pressed file) directly from Packer via HTTP.  Once the operating system has been installed and Packer has confirmed it can login, Packer can make additional changes such as copying SSH keys to allow remote access without a password. Once it has finsihed making changes, Packer shuts down the virtual machine and converts the virtual machine's disk into a reuseable image.  In the case of the Proxmox platform, this means converting the entire virtual machine into a virtual machine template.

Creating the virtual machine template Terraform will use is not difficult, but it does take more time than other automation steps.  Fortunately, this only has to be done when we create the initial template and any time we want to make changes to the template.  Once created, Terraform can reuse the template any number of times to create virtual machines significantly faster and more reliably than installing the operating system by hand.

# Overview of the process
> **Note:** Unless otherwise noted, you should be doing these steps from the shell prompt within the development container.

Here is the high level overview of the process:
1. Generate an SSH keypair for the configuration management account
1. Download the install media to storage within the Proxmox cluster
1. Create the Packer configuration file
1. Initialize the pcker plugins
1. Create the operating system installer file
1. Run Packer to create the template

## Generate an SSH keypair for the configuration management account
In order for Ansible to configure our virtual machines remotely, the virtual machines will need to have an administrative account which can login using SSH. It is best practice to disable the root account and instead use sudo from another account since privilege escalation using sudo is logged and can be constrained if needed.  Furthermore, it is also best practice to disable password authentication for SSH.  To accomplish both of these objectives, we will need to generate an SSH keypair for a new administrative account.

> **Note:** You can create your own keys as shown below or copy existing keys you may already be using, if you prefer.  Also, the provided packer build script will create these keys automatically if they do not already exist, so you can consider the rest of this section as informational.

> **Note:** I will be using `ansible` as the name of the administrative account in my examples.  You may wish to change this to something else, but this will require you to make changes to some of the sample files provided.

> **Note:** Since this account will have administrative rights to manage machines remotely, you need to protect the private key from falling into the wrong hands. I recommend you set a strong passphrase when ssh-keygen prompts you for one. If your private key is ever compromised, you will have to generate a new one **and** rebuild all your virtual machine templates (since the existing templates are configured to accept the old key).

```shell
export ADMINUSER=ansible
mkdir ~/keys &&
cd ~/keys &&
ssh-keygen -b 4096 -t rsa -f $ADMINUSER
```

## Download the install media to storage within the Proxmox cluster
Your Proxmox cluster includes storage space for ISO images which you can use to store operating system installation media.  Since our demo build script will automate installing Debian Linux, we will need to download the Debian Linux installation media to the cluster's ISO storage space so packer can use it do install.

> **Note:** You can check https://cdimage.debian.org/debian-cd/current/amd64/iso-cd/ to see if a newer release of Debian is available.  However, the Packer files in this example expect this specific ISO file so you will need to update the provided files if you go with a newer version

Packer will need to virtually insert the operating system installation media into the virtual machine before booting it, so the ISO images must exist within Proxmox's ISO storage. You can download ISO images to your local machine and then upload them to Proxmox in a two-transfer process if you also want to put the ISO image on a flash drive.  However, if you only need the ISO image for Proxmox, you can have Proxmox download it directly to its ISO storage in a single transfer as described in these steps:
1. Use the Proxmox web interface to login as the cluster administrator
1. From the Server View tree in the upper left, expand the cluster and node which has the storage where you want to save the ISO image.

   > **Note:** Some cluster storage like NFS shares exported from NAS are shared between nodes. In these cases, it won't matter which cluster node you expand as the nodes all have the same access.

1. Select one of the storage pools in the node that supports ISO images and select "ISO Images" just to the right of Server View tree.
1. Click the Download from URL button at the top of the ISO image pane
1. Fill in the URL field with `https://cdimage.debian.org/debian-cd/current/amd64/iso-cd/debian-12.1.0-amd64-netinst.iso` and click the Query URL button (this should fill in the File name field automatically).
1. It is recommended that you select a hash algorithm and provide the corresponding checksum so Proxmox can verify the download was successfully, but this is not actually required (files containing the checksums are available in the same directory as the ISO images).
1. Click the Download button and wait for the download to complete.

![Download from URL dialog](proxmox-iso-upload.png)


## Create the Packer configuration file
Packer builds machine images according to the contents of its template file which is written in HCL2, HashiCorp's Configuration Language.  Creating the Packer template file from scratch is beyond the scope of this exercise. Instead, a working template file to built a minimal Debian machine is provided to get you started. You can read more about Packer's template file format in the [Packer Documentation](https://developer.hashicorp.com/packer/docs).

## Initialize the pcker plugins
```shell
packer init proxmox.pkr.hcl
```

## Create the operating system installer file
Automating Debian installs using preseed files is also beyond the scope of this tutorial, but a working preseed file to create a minimal installation of Debian Linux has been provided.  You can read more about Debian preseed files at .
Packer will use the Debian preseed file to answer the operating system install program's questions.

## Run Packer to create the template
Finally, we can run packer to create the virtual machine template. Our example packer configuration file includes a lot of variables that need to set which makes the packer command line rather long.  Instead of typing it in by hand and possibly forgetting to specify a value, we wrap the whole thing inside a simple Ansible playbook which has the added feature of ensuring our SSH keys have already been created.

Many of the variable values will be specific to your site and Proxmox installation.  Copy the (hidden) files in the ../example_config_files directory to your home directory and edit them so they contain the values appropriate for your site.  When you are finished editing the config files, you can run the ansible playbook.

```shell
cp ../example_config_files/.* $HOME
vim -p ~/.configuration_management.yml ~/.packer.yml ~/.proxmox.yml ~/.site.yml
./build-packer-templates
```

It will take a while for packer to create the virtual machine, install the operating system, and convert the virtual machine to a template that terraform can use.  You can follow the progress by watching the virtual machine's console, but don't interact with it or you might interfere with packer's operation.  When packer completes, you will have a virtual machine template in Proxmox which you can clone, either with terraform or manually, to create new virtual machines.

> **Note:** Packer does not manage the templates, it only creates them.  If you make changes to your packer configuration file or the preseed file and want to recreate the virtual machine template, you will need to manually delete the old template first.

If you have successfully created the virtual machine template, continue on to the ../terraform directory and read the README.md file there to learn how terraform can use it.
