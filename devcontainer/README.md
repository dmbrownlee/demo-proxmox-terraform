# The Development Container
The end goal of the exercises in this repo is to learn how to automate the provisioning and configuration of virtual machines running in a Proxmox cluster.  To achieve this, we are going to need to use multiple tools including Packer, Terraform, and Ansible.  Rather than try to write instructions for how to install multiple versions of these tools across many different Linux distrubutions, we are going to create a container to give us a consistent, repeatable environment to work with.

# Building the `demo-devcontainer` container image
The first step is to create a container image.  The `Dockerfile` in this directory will build a container image based on Debian Bookworm and install the tools we need for the rest of the project.

> Note: The Open Container Initiative (OCI) has standardized on `Containerfile` as the name of the file used for building container images.  However, `docker` still looks for `Dockerfile` by default. Podman will also look for `Dockerfile` if `Containerfile` does not exist, so that file name is used for backwards compatability.

> Note: The following command needs to download the official Debian container image and then install additional software within it.  Make sure you host as connectivity to the Internet.

```shell
 podman build -t demo-devcontainer:2023092301 -p 8300:8300 --build-arg username=$USER --build-arg uid=$(id -u $USER) --build-arg gid=$(id -g $USER) --squash-all .
 ```

The command to build a container image is `podman build`.  Here is a description of the other options:
|&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;Option&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;|Explanation|
|---|---|
|`-t`|The `-t demo-devcontainer:2003092301` option names the image `demo-devcontainer` with `2023092301` as an additional tag specifying a version of the image.  Both of these are arbitrary as you can name your images whatever you like and specifying an addtional version is not required.|
|`-p 8300:8300`|Packer will run a web server on port 8300 to serve up the preseed file to the operating system installer.  The virtual machine running in Proxmox cannot reach packer running inside the container, but it can reach the container host, so this will forward connections to port 8300 on the host to packer listening on port 8300 inside the container.
|`--build-arg=...`|The `--build-arg=...` options assign values to variables to override the defaults given on the `ARG` lines in the `Dockerfile`.  The result is the user account inside the container will have the same username, UID and GID of the account you are currently using on the host.|
|`--squash-all`|The `--squash-all` option instructs podman to build the container image as a single image rather than a stack of transparent images that get layered together.|

After the command options, there is a space and a `.` at the end of the line telling podman to look in the current directory (`.`) for the `Dockerfile`.

Veirfy the new image exists locally with:
```shell
podman image ls
```

# Starting the demo container
The container image is like a hard drive waiting to be booted.  To start a container based on this image and get a shell prompt, you use the `podman container run...` command.

```shell
podman container run -it --rm --name mydevcontainer -v mydevhome:/home/$USER localhost/demo-devcontainer:2023092301
```

|&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;Option&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;|Explanation|
|---|---|
|`-it`|The `-it` is actually two command line options combined, `-i` (interactive) and `-t` (allocate a terminal).  The order doesn't matter so `-ti` works the same.  The combination of these options ensures the shell inside the container is connected to our current terminal.|
|`--rm`|The `--rm` (remove) is a single, long option (well, two characters isn't **that** long) so it is preceed by two dashes.  This instructs podman to delete the container when we exit.  This means we get a brand new container everytime we start it which is great for repeatability.  It also means you don't have to stop the container manually when you are done using it.|
|`--name ...`|The `--name mydevcontainer` option just assigns a name to the container which could be anything.  If you don't specify a name, a name will be randomly generated so this isn't necessary, but it is helpful in identifying the container if you have other containers running on the same machine.|
|`-v ...`|The `-v mydevhome:/home/$USER` option attaches a persistent volume named `mydevhome` (which is created if it doesn't exist) to the `/home/$USER` directory inside the container.  This means changes within your home directory inside the container will be available in future containers so long as they are also started with this same option.  Note, since we are removing the container on exit, any changes outside of the home directory are lost.  This is great for ensuring a consistent set of utilities within the container while still allowing you save custom tweaks to your editor and git configurations.|

After the command line options, the `localhost/demo-devcontainer:2023092301` argument specifies which image we want to start. This should match the name you gave the image when you built it.

> Note: The hostname within the container is the first part of the container's ID so the host part of your shell prompt will be a hexideecimal string.

Since we preinstalled the tools we will be using, you should be able to confirm you can get the versions of packer and terraform.
```shell
packer --version
terraform --version
```

# Verifying a persistent home directory
To demonstrate (lack of) persistence, let's taint our pristine devcontainer by installing the nano editor.
```shell
sudo apt install nano
```
You can verify nano is installed by entering `nano` at the shell prompt (`Ctrl-x` will exit nano).

Now type `exit` at the shell prompt to exit and destroy the container.  Create a new container using the same `podman run...` command you used last time.  If you try to start nano now, the shell will report `bash: nano: command not found`.  This is because apt installs nano outside of our home directory.  However, running `ls` in your home directory shows the `demo-proxmox-terraform` directory still exists.

If you know you would like to tweak your git config or vim settings before continuing, free free.  When you are ready to continue, proceed to the `~/demo-proxmox-terraform/packer` directory (within the container) and follow the instructions in the README.md file there.

This exercise covered the absolute minimum needed to get a working container.  Consider learning more about containers as time permits.
- [Podman Documentation](https://podman.io/docs)
- [Dockerfile reference](https://docs.docker.com/engine/reference/builder/)
