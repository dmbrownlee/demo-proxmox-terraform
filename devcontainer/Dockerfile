ARG debian_version=bookworm
FROM debian:${debian_version}

ARG username=user
ARG uid=1000
ARG gid=1000
#ARG addonpkgs="bash-completion tmux vim-nox vim-ale vim-airline vim-airline-themes vim-youcompleteme"
ARG addonpkgs="bash-completion vim-nox"
ARG terraform_version=1.5.7
ARG arch=amd64


RUN apt update -y \
  && apt install -y curl git gpg lsb-release openssh-client python3 python3-pip python3-venv software-properties-common sshpass sudo ${addonpkgs} unzip \
  && curl -fsSL https://apt.releases.hashicorp.com/gpg | gpg --yes --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg \
  && chmod 644 /usr/share/keyrings/hashicorp-archive-keyring.gpg \
  && echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg arch=amd64] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | tee /etc/apt/sources.list.d/apt_releases_hashicorp_com.list \
  && apt update -y \
  && apt install -y packer \
  && apt clean -y \
  && curl -o /tmp/terraform.zip https://releases.hashicorp.com/terraform/${terraform_version}/terraform_${terraform_version}_linux_${arch}.zip \
  && unzip -d /usr/local/bin /tmp/terraform.zip \
  && rm /tmp/terraform.zip \
  && /usr/sbin/groupadd -g ${gid} ${username} \
  && /usr/sbin/useradd -m -d /home/${username} -g ${username} -G sudo -s /bin/bash -u ${uid} ${username} \
  && echo "${username} ALL=(ALL) NOPASSWD: ALL" > /etc/sudoers.d/99${username}

USER ${username}
WORKDIR /home/${username}
RUN mkdir .venv \
  && python3 -m venv .venv/ansible \
  && exec /bin/bash \
  && source .venv/ansible/bin/activate \
  && pip3 install ansible \
  && echo -e 'if [ -f ~/.venv/ansible/bin/activate ]; then\n  . ~/.venv/ansible/bin/activate\nfi\n' | tee -a ~/.bashrc \
  && echo -e 'source $(/usr/bin/ssh-agent -s)' | tee -a ~/.bashrc \
  && git clone https://github.com/dmbrownlee/demo-proxmox-terraform.git

ENTRYPOINT ["/bin/bash"]
