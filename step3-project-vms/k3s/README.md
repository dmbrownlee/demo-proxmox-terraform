# Minimalist Instructions
> [!note] The name of the variable files must match the name of the workspace for the commands below to work.

1. Create and initialize a Terraform (or OpenTofu) workspace named "myk3s".
    ```shell
    tofu workspace new myk3s
    tofu init
    ```
2. Copy and edit the example files with values appropriate to your installation.
    ```shell
    cp myk3s.tfvars.example myk3s.tfvars
    cp ansible/myk3s.vars.yml.example ansible/myk3s.vars.yml
    vim -p myk3s.tfvars ansible/myk3s.vars.yml
    ```
3. Run Terraform (or OpenTofu) to create the virtual machines.
    ```shell
    tofu apply -var-file $(tofu workspace show).tfvars -parallelism=1
    ```
4. Run Ansible to configure the virtual machines as a K3S cluster.
    ```shell
    ansible-playbook -e tf_workspace=$(tofu workspace show) ansible/playbook.yml
    ```
5. Run Ansible to configure the apps within the cluster.
    ```shell
    ansible-playbook -e tf_workspace=$(tofu workspace show) ansible/playbook-apps.yml
    ```
