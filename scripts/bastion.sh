#!/bin/bash
# Stop script if any individual command fails
set -e
echo "--> Ensuring AWS SSM Agent is installed and active..."
sudo dnf install -y https://s3.amazonaws.com/ec2-downloads-windows/SSMAgent/latest/linux_amd64/amazon-ssm-agent.rpm || true
sudo systemctl enable --now amazon-ssm-agent

echo "=========================================================="
echo " Starting Bastion / Jenkins Worker Installation on RHEL"
echo "=========================================================="

echo "--> 1. Installing base utility packages..."
sudo dnf install -y yum-utils git wget curl unzip tar make jq

echo "--> 2. Installing Java 21 OpenJDK (Required for Jenkins Remoting Agent)..."
sudo dnf install -y java-21-openjdk java-21-openjdk-devel

echo "--> 3. Installing Terraform..."
sudo yum-config-manager --add-repo https://rpm.releases.hashicorp.com/RHEL/hashicorp.repo -y
sudo dnf install -y terraform

echo "--> 4. Installing AWS CLI v2..."
curl -sSL "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "/tmp/awscliv2.zip"
unzip -q /tmp/awscliv2.zip -d /tmp
sudo /tmp/aws/install --update
rm -rf /tmp/aws /tmp/awscliv2.zip

echo "--> 5. Installing Docker CE..."
sudo dnf remove -y docker \
                  docker-client \
                  docker-client-latest \
                  docker-common \
                  docker-latest \
                  docker-latest-logrotate \
                  docker-logrotate \
                  docker-engine \
                  podman \
                  runc || true

sudo dnf config-manager --add-repo https://download.docker.com/linux/rhel/docker-ce.repo
sudo dnf install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
sudo systemctl enable --now docker

# Grant Docker access to ec2-user and devops user if exists
sudo usermod -aG docker ec2-user
if id "devops" &>/dev/null; then
    sudo usermod -aG docker devops
fi

echo "--> 6. Installing Kubernetes Tools (Kind & Kubectl)..."
if [ "$(uname -m)" = "x86_64" ]; then
    curl -Lo ./kind https://kind.sigs.k8s.io/dl/v0.27.0/kind-linux-amd64
    chmod +x ./kind
    sudo mv -f ./kind /usr/bin/kind
else
    echo "Skipping kind: Not an x86_64 architecture"
fi

KUBECTL_VERSION="v1.30.0"
curl -sSLOf "https://dl.k8s.io/release/${KUBECTL_VERSION}/bin/linux/amd64/kubectl"
sudo install -o root -g root -m 0755 kubectl /usr/bin/kubectl
rm -f kubectl

echo "--> 7. Creating KinD Cluster for RoboShop..."
if ! sudo kind get clusters | grep -q "roboshop"; then
    sudo kind create cluster --name=roboshop
fi

echo "--> Configuring kubeconfig for ec2-user..."
mkdir -p /home/ec2-user/.kube
sudo kind get kubeconfig --name=roboshop > /home/ec2-user/.kube/config
sudo chown -R ec2-user:ec2-user /home/ec2-user/.kube
chmod 600 /home/ec2-user/.kube/config

if id "devops" &>/dev/null; then
    mkdir -p /home/devops/.kube
    sudo cp /home/ec2-user/.kube/config /home/devops/.kube/config
    sudo chown -R devops:devops /home/devops/.kube
    chmod 600 /home/devops/.kube/config
fi

echo "--> 8. Installing Helm 3..."
curl -fsSL https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash

echo "--> 9. Installing k9s..."
sudo dnf install -y https://github.com/derailed/k9s/releases/latest/download/k9s_linux_amd64.rpm || echo "k9s rpm installation skipped"

echo "--> 10. Installing SonarScanner CLI for SonarQube Scans..."
SONAR_SCANNER_VER="6.2.1.4610"
curl -sSLo /tmp/sonar-scanner.zip "https://binaries.sonarsource.com/Distribution/sonar-scanner-cli/sonar-scanner-cli-${SONAR_SCANNER_VER}-linux-x64.zip"
sudo unzip -q /tmp/sonar-scanner.zip -d /opt
sudo ln -sf "/opt/sonar-scanner-${SONAR_SCANNER_VER}-linux-x64/bin/sonar-scanner" /usr/bin/sonar-scanner
rm -f /tmp/sonar-scanner.zip

echo "--> 11. Installing Trivy Container Vulnerability Scanner..."
cat << 'EOF' | sudo tee /etc/yum.repos.d/trivy.repo
[trivy]
name=Trivy repository
baseurl=https://aquasecurity.github.io/trivy-repo/rpm/releases/$basearch/
gpgcheck=1
enabled=1
gpgkey=https://aquasecurity.github.io/trivy-repo/rpm/public.key
EOF
sudo dnf install -y trivy

echo "--> 12. Configuring Shell Aliases for ec2-user..."
PROFILE="/home/ec2-user/.bashrc"
if [ -f "$PROFILE" ]; then
    if ! grep -q "# --- Kubectl Shortcuts Added via Script ---" "$PROFILE"; then
        cat << 'EOF' >> "$PROFILE"

# --- Kubectl Shortcuts Added via Script ---
alias k='kubectl'
if command -v kubectl &> /dev/null; then
    source <(kubectl completion bash)
    complete -F __start_kubectl k
fi
# ------------------------------------------
EOF
        sudo chown ec2-user:ec2-user "$PROFILE"
    fi
fi

echo "=========================================================="
echo " Bastion / Jenkins Worker Setup Completed Successfully!"
echo " Tools Installed: Java 21, Docker, Kind, Kubectl, Helm 3,"
echo "                  Terraform, AWS CLI, SonarScanner, Trivy"
echo "=========================================================="