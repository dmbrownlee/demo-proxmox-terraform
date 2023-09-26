ARG debian_version=bookworm
FROM debian:${debian_version}

ARG username=user
ARG uid=1000
ARG gid=1000
#ARG addonpkgs="bash-completion tmux vim-nox vim-ale vim-airline vim-airline-themes vim-youcompleteme"
ARG addonpkgs="bash-completion vim-nox"
ARG terraform_version=1.5.7
ARG arch=amd64


RUN /usr/bin/apt update -y \
  && /usr/bin/apt install -y curl git gpg lsb-release openssh-client python3 python3-pip python3-venv python3-bcrypt software-properties-common sshpass sudo ${addonpkgs} unzip \
  && /usr/bin/curl -fsSL https://apt.releases.hashicorp.com/gpg | gpg --yes --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg \
  && /usr/bin/chmod 644 /usr/share/keyrings/hashicorp-archive-keyring.gpg \
  && /bin/echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg arch=amd64] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | tee /etc/apt/sources.list.d/apt_releases_hashicorp_com.list \
  && /usr/bin/apt update -y \
  && /usr/bin/apt install -y packer \
  && /usr/bin/apt clean -y \
  && /usr/bin/curl -o /tmp/terraform.zip https://releases.hashicorp.com/terraform/${terraform_version}/terraform_${terraform_version}_linux_${arch}.zip \
  && /usr/bin/unzip -d /usr/local/bin /tmp/terraform.zip \
  && /usr/bin/rm /tmp/terraform.zip \
  && /usr/sbin/groupadd -g ${gid} ${username} \
  && /usr/sbin/useradd -m -d /home/${username} -g ${username} -G sudo -s /bin/bash -u ${uid} ${username} \
  && /bin/echo "${username} ALL=(ALL) NOPASSWD: ALL" > /etc/sudoers.d/99${username}

USER ${username}
WORKDIR /home/${username}
RUN /bin/echo -e '\nif [ -f ~/.venv/ansible/bin/activate ]; then\n  . ~/.venv/ansible/bin/activate\nfi' | tee -a ~/.bashrc \
  && /bin/echo -e '\neval $(/usr/bin/ssh-agent -s)' | tee -a ~/.bashrc \
  && /usr/bin/git clone https://github.com/dmbrownlee/demo-proxmox-terraform.git \
  && /usr/bin/mkdir .venv \
  && /usr/bin/python3 -m venv .venv/ansible \
  && /bin/bash -c 'source ~/.venv/ansible/bin/activate && /usr/bin/env pip3 install ansible'

ENTRYPOINT ["/bin/bash"]
