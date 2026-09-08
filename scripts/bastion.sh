#!/bin/bash
# Stop script if any individual command fails
set -e

echo "Install terraform"
sudo yum install -y yum-utils
sudo yum-config-manager --add-repo https://rpm.releases.hashicorp.com/RHEL/hashicorp.repo -y
sudo yum -y install terraform

echo "download azure cli rpm"
sudo rpm --import https://packages.microsoft.com/keys/microsoft-2025.asc

echo "install azure cli rpm package"
sudo dnf install -y https://packages.microsoft.com/config/rhel/10/packages-microsoft-prod.rpm

echo "install azure cli"
sudo dnf -y install azure-cli

echo "download kind"
if [ "$(uname -m)" = "x86_64" ]; then
    curl -Lo ./kind https://kind.sigs.k8s.io/dl/v0.31.0/kind-linux-amd64
    chmod +x ./kind
    # CHANGED: Using /usr/bin instead of /usr/local/bin for reliable RHEL compatibility
    sudo mv -f ./kind /usr/bin/kind
else
    echo "Skipping kind: Not an x86_64 architecture"
fi

echo "download kubectl"
KUBECTL_VERSION="v1.30.0"
curl -LOf "https://dl.k8s.io/release/${KUBECTL_VERSION}/bin/linux/amd64/kubectl"

echo "install kubectl"
# CHANGED: Target /usr/bin directly to avoid path lookup errors
sudo install -o root -g root -m 0755 kubectl /usr/bin/kubectl

# Clean up local file
rm -f kubectl

echo "install docker"
sudo dnf remove docker \
                  docker-client \
                  docker-client-latest \
                  docker-common \
                  docker-latest \
                  docker-latest-logrotate \
                  docker-logrotate \
                  docker-engine \
                  podman \
                  runc

sudo dnf -y install dnf-plugins-core
sudo dnf config-manager --add-repo https://download.docker.com/linux/rhel/docker-ce.repo
sudo dnf install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin -y
sudo systemctl enable --now docker
# Check if devops user exists before adding to group to prevent failure
if id "devops" &>/dev/null; then
    sudo usermod -aG docker devops
fi

echo "create roboshop cluster"
sudo kind create cluster --name=roboshop

echo "configure kubeconfig for devops user"
mkdir -p /home/devops/.kube
sudo kind get kubeconfig --name=roboshop > /home/devops/.kube/config
sudo chown -R devops:devops /home/devops/.kube





# 1. Determine the correct profile file
if [ -f "$HOME/.bashrc" ]; then
    PROFILE="$HOME/.bashrc"
elif [ -f "$HOME/.bash_profile" ]; then
    PROFILE="$HOME/.bash_profile"
else
    PROFILE="$HOME/.bashrc"
    touch "$PROFILE"
fi

echo "Target profile: $PROFILE"

# 2. Prevent duplicate entries by checking if the block already exists
if ! grep -q "# --- Kubectl Shortcuts Added via Script ---" "$PROFILE"; then
    cat << 'EOF' >> "$PROFILE"

# --- Kubectl Shortcuts Added via Script ---
alias k='kubectl'
# alias kg='kubectl get'
# alias kgp='kubectl get pods'
# alias kgs='kubectl get services'
# alias kd='kubectl describe'
# alias kdel='kubectl delete'
# alias kl='kubectl logs'
# alias kex='kubectl exec -it'

# Fix autocompletion for the 'k' shortcut
if command -v kubectl &> /dev/null; then
    source <(kubectl completion bash)
    complete -F __start_kubectl k
fi
# ------------------------------------------
EOF
    echo "Aliases successfully appended to $PROFILE"
else
    echo "Aliases already exist in $PROFILE. Skipping append."
fi

# Temporarily disable 'exit on error' because sourcing profile files 
# in non-interactive SSH shells often returns non-zero status codes.
# Temporarily disable 'exit on error'
set +e
source "$PROFILE"
echo "install makefile"
sudo dnf install make -y       


echo "install k9s"
sudo dnf install -y https://github.com/derailed/k9s/releases/latest/download/k9s_linux_amd64.rpm

echo helm installation
curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-4 | sudo bash
set -e 

echo "Please run: source $PROFILE to activate them in your current session."
echo "All installations completed successfully!"