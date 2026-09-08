#!/bin/bash

# Exit immediately if a command exits with a non-zero status
set -e
echo "--> Ensuring AWS SSM Agent is installed and active..."
sudo dnf install -y https://s3.amazonaws.com/ec2-downloads-windows/SSMAgent/latest/linux_amd64/amazon-ssm-agent.rpm || true
sudo systemctl enable --now amazon-ssm-agent

# --- CONFIGURATION VARIABLES ---
SONAR_VERSION="10.8.0.101718" # Replace with the specific version you need
DB_USER="sonar"
DB_PASS="YourSecurePasswordHere" # Change this to your actual DB password
DB_URL="jdbc:postgresql://localhost:5432/sonarqube"
# -------------------------------

echo "=========================================="
echo " Starting SonarQube Installation on RHEL"
echo "=========================================="

# 1. Update OS and Install System Prerequisites
echo "--> Installing system prerequisites (Java 17, unzip, wget)..."
dnf update -y
dnf install java-17-openjdk-devel unzip wget -y

# 2. Configure System Kernel Limits (Required for Elasticsearch)
echo "--> Configuring system kernel limits (sysctl)..."
SYSCTL_CONF="/etc/sysctl.d/99-sonarqube.conf"
cat <<EOF > $SYSCTL_CONF
vm.max_map_count=524288
fs.file-max=131072
EOF
sysctl --system

# 3. Create Dedicated SonarQube User
echo "--> Creating dedicated 'sonarqube' system user..."
if ! id "sonarqube" &>/dev/null; then
    useradd -r -m -s /bin/bash sonarqube
fi

# 4. Configure User Security Limits
echo "--> Configuring user security limits..."
LIMITS_CONF="/etc/security/limits.d/99-sonarqube.conf"
cat <<EOF > $LIMITS_CONF
sonarqube   soft   nofile   131072
sonarqube   hard   nofile   131072
sonarqube   soft   nproc    8192
sonarqube   hard   nproc    8192
EOF

# 5. Download and Extract SonarQube
echo "--> Downloading SonarQube v${SONAR_VERSION}..."
cd /opt
if [ ! -f "sonarqube-${SONAR_VERSION}.zip" ]; then
    wget https://sonarsource.com{SONAR_VERSION}.zip
fi

echo "--> Extracting SonarQube files..."
unzip -q sonarqube-${SONAR_VERSION}.zip
rm -rf sonarqube
mv sonarqube-${SONAR_VERSION} sonarqube

# 6. Configure Database Settings in sonar.properties
echo "--> Updating database configurations in sonar.properties..."
SONAR_PROP="/opt/sonarqube/conf/sonar.properties"

# Backup original file
cp $SONAR_PROP "${SONAR_PROP}.bak"

# Append DB credentials (uncommenting or replacing as needed)
sed -i "s|^#sonar.jdbc.username=.*|sonar.jdbc.username=${DB_USER}|" $SONAR_PROP || echo "sonar.jdbc.username=${DB_USER}" >> $SONAR_PROP
sed -i "s|^#sonar.jdbc.password=.*|sonar.jdbc.password=${DB_PASS}|" $SONAR_PROP || echo "sonar.jdbc.password=${DB_PASS}" >> $SONAR_PROP
sed -i "s|^#sonar.jdbc.url=jdbc:postgresql:.*|sonar.jdbc.url=${DB_URL}|" $SONAR_PROP || echo "sonar.jdbc.url=${DB_URL}" >> $SONAR_PROP

# 7. Set Permissions
echo "--> Setting folder permissions for 'sonarqube' user..."
chown -R sonarqube:sonarqube /opt/sonarqube

# 8. Create Systemd Service File
echo "--> Creating systemd service configuration..."
cat <<EOF > /etc/systemd/system/sonarqube.service
[Unit]
Description=SonarQube service
After=syslog.target network.target

[Service]
Type=forking
ExecStart=/opt/sonarqube/bin/linux-x86-64/sonar.sh start
ExecStop=/opt/sonarqube/bin/linux-x86-64/sonar.sh stop
User=sonarqube
Group=sonarqube
Restart=always
LimitNOFILE=131072
LimitNPROC=8192

[Install]
WantedBy=multi-user.target
EOF

# 9. Start and Enable SonarQube Service
echo "--> Starting SonarQube service..."
systemctl daemon-reload
systemctl enable sonarqube
systemctl start sonarqube

echo "=========================================="
echo " SonarQube installation complete!"
echo " Status: check using 'systemctl status sonarqube'"
echo " Logs: available at /opt/sonarqube/logs/"
echo "=========================================="
