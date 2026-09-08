#!/bin/bash
# Stop script if any individual command fails
set -e

echo "=========================================="
echo " Starting Jenkins Controller Installation"
echo " OS: Red Hat Enterprise Linux (RHEL)"
echo "=========================================="

echo "--> 1. Installing prerequisite packages..."
sudo dnf install -y fontconfig wget curl git unzip

echo "--> 2. Installing Java 21 OpenJDK (Jenkins LTS Requirement)..."
sudo dnf install -y java-21-openjdk java-21-openjdk-devel

echo "--> 3. Configuring official Jenkins repository and GPG key..."
sudo wget -O /etc/yum.repos.d/jenkins.repo https://pkg.jenkins.io/rpm-stable/jenkins.repo
sudo rpm --import https://pkg.jenkins.io/rpm-stable/jenkins.io-2023.key

echo "--> 4. Installing Jenkins..."
sudo dnf install -y jenkins

echo "--> 5. Enabling and starting Jenkins service..."
sudo systemctl daemon-reload
sudo systemctl enable --now jenkins

echo "--> 6. Waiting for Jenkins to initialize and generate admin password..."
MAX_ATTEMPTS=30
ATTEMPT=0
while [ ! -f /var/lib/jenkins/secrets/initialAdminPassword ]; do
  ATTEMPT=$((ATTEMPT + 1))
  if [ "$ATTEMPT" -ge "$MAX_ATTEMPTS" ]; then
    echo "ERROR: Timed out waiting for Jenkins initialAdminPassword after $((MAX_ATTEMPTS * 5)) seconds."
    echo "Checking Jenkins service status:"
    sudo systemctl status jenkins --no-pager
    exit 1
  fi
  echo "Waiting for Jenkins... (attempt $ATTEMPT/$MAX_ATTEMPTS)"
  sleep 5
done

# Fetch public IP if running on AWS EC2
PUBLIC_IP=$(curl -s --connect-timeout 2 http://169.254.169.254/latest/meta-data/public-ipv4 2>/dev/null || hostname -I | awk '{print $1}')

echo "============================================================"
echo " Jenkins Controller Installation Complete!"
echo " Web UI: http://${PUBLIC_IP}:8080"
echo " Initial Admin Password:"
sudo cat /var/lib/jenkins/secrets/initialAdminPassword
echo ""
echo "============================================================"