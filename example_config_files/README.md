# Instructions

1. Copy the hidden files in this directory to your home directory:
    ```shell
    cp ./.*.yml $HOME
    ```

1. Edit their content as appropriate for your site:
    ```shell
    vim -p ~/.configuration_management.yml ~/.packer.yml ~/.proxmox.yml ~/.site.yml
    ```

These configuration files contain sensitive, site-specific information that
should not be kept in publicly accessible version control (i.e. GitHub).  For
that reason, the sample scripts provided expect to find them at the root of
your home directory.  In addition to keeping the actual files outside the git
repository, you should also set the file permissions so that only you have
read access and use ansible-vault to encrypt them.  This still may not be
enough depending on your security concerns, but this should be (personal
opinion) ok for a home lab.
