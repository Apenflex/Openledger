#!/bin/bash

# Logging Function
log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1"
}

# Error Handling Function
error_exit() {
    log "ERROR: $1"
    exit 1
}

# Validate Root Access
if [[ $EUID -ne 0 ]]; then
   error_exit "This script must be run as root or with sudo"
fi

# Advanced Firewall Configuration
log "Configuring Firewall"
# Disable and reset UFW first to prevent conflicts
ufw disable   
ufw reset -y  
ufw default deny incoming  
ufw default allow outgoing  
ufw allow ssh  
ufw allow 3389/tcp  # RDP Port  
echo "y" | ufw enable || error_exit "Failed to enable firewall"

# Start logging
log "Starting Docker and XRDP Installation Script"

# Update system packages with error checking
log "Updating system packages"
apt update || error_exit "Failed to update packages"
apt upgrade -y || error_exit "Failed to upgrade packages"

# Install required dependencies
log "Installing required dependencies"
apt install -y \
    apt-transport-https \
    ca-certificates \
    curl \
    software-properties-common \
    xfce4 \
    xfce4-goodies \
    gdebi \
    wget \
    unzip \
    || error_exit "Failed to install dependencies"

# Docker Installation
log "Adding Docker GPG key"
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg

log "Adding Docker repository"
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null

log "Updating package index"
apt update || error_exit "Failed to update package index"

log "Installing Docker"
apt install -y docker-ce docker-ce-cli containerd.io || error_exit "Docker installation failed"

# XRDP Configuration
log "Installing XRDP"
apt install -y xrdp || error_exit "XRDP installation failed"

# Configure XRDP for Xfce
echo "xfce4-session" > /root/.xsession

# Enable and start XRDP service
log "Enabling and starting XRDP service"
systemctl enable xrdp
systemctl restart xrdp || error_exit "Failed to start XRDP service"

# OpenLedger Node Installation Function
install_openledger_node() {
    # Change to home directory
    cd ~

    # Log download attempt
    log "Downloading OpenLedger Node Package"
    wget https://cdn.openledger.xyz/openledger-node-1.0.0-linux.zip || error_exit "Failed to download OpenLedger Node package"

    # Log extraction
    log "Extracting OpenLedger Node Package"
    unzip openledger-node-1.0.0-linux.zip || error_exit "Failed to extract OpenLedger Node package"

    # Find the .deb file
    DEB_FILE=$(find . -name "*.deb" | head -n 1)
    
    if [ -z "$DEB_FILE" ]; then
        error_exit "No .deb package found in the extracted files"
    fi

    # Log installation of .deb package
    log "Installing OpenLedger Node .deb Package"
    dpkg -i "$DEB_FILE" || error_exit "Failed to install OpenLedger Node package"

    # Ensure all dependencies are met
    log "Fixing any potential dependency issues"
    apt-get install -f -y || error_exit "Failed to resolve dependencies"

    # Log successful installation
    log "OpenLedger Node Package Installed Successfully"
}

# Get IP Address
IP_ADDRESS=$(hostname -I | awk '{print $1}')

# Final success log
log "Installation Complete!"
echo "===== NEXT STEPS ====="
echo "1. Login RDP:"
echo "   - IP: $IP_ADDRESS"
echo "   - Username: root"
echo "   - Password: Your VPS Root Password"
echo ""
echo "2. Download OpenLedger Node Package: Run in Terminal"
echo "   wget https://cdn.openledger.xyz/openledger-node-1.0.0-linux.zip"
echo ""
echo "3. Extract and Install Package:"
echo "   - Unzip the package"
echo "   - Install .deb package"
echo ""
echo "4. Run OpenLedger Node: Run in Terminal"
echo "   openledger-node --no-sandbox"
echo ""
echo "5. Follow Prompts to Setup Node"
echo ""
echo "6. Firewall Status:"
ufw status
echo ""
echo "7. Recommended: Review and customize firewall rules"
echo "===== END OF INSTRUCTIONS ====="

# Optionally, uncomment the following line to automatically install OpenLedger Node
# install_openledger_node

# Log the end of script execution
log "Script execution completed"
