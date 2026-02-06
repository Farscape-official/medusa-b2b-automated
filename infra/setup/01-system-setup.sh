#!/bin/bash

################################################################################
# Farscape B2B Platform - System Setup Script
################################################################################
# Purpose: Install and configure all system-level dependencies on fresh Ubuntu 24.04
# Author: Gaurav (gaurav@farscape.io)
# Organization: Farscape-official
# 
# What this script does:
# 1. Updates Ubuntu packages and installs essential tools
# 2. Installs Docker + Docker Compose
# 3. Installs Node.js 20 LTS + npm (or pnpm if specified)
# 4. Installs GitHub CLI (gh)
# 5. Configures UFW firewall (SSH, HTTP, HTTPS only)
# 6. Configures timezone and system hardening
# 7. Creates centralized logging directory
# 8. Sets up backup user and directories
#
# Note: fail2ban is NOT installed by this script. For SSH protection,
#       consider implementing rate limiting at the network level or
#       using SSH key-based authentication only (which this script enforces).
#
# Requirements:
# - Fresh Ubuntu 24.04 server
# - Root access (run with sudo)
# - Internet connectivity
#
# Usage:
#   sudo bash 01-system-setup.sh
#
# Environment Variables (for non-interactive execution):
#   ALLOW_UNSUPPORTED_OS=true    - Continue on non-24.04 Ubuntu versions
#   FORCE_NODE_REINSTALL=true    - Reinstall Node.js if wrong version detected
#   PACKAGE_MANAGER=npm|pnpm     - Choose package manager (default: npm)
#
# Exit codes:
#   0 = Success
#   1 = General error
#   2 = Not running as root
#   3 = Unsupported OS
################################################################################

set -euo pipefail  # Exit on error, undefined vars, pipe failures

################################################################################
# CONFIGURATION
################################################################################

# Logging
LOG_DIR="/var/log/farscape"
LOG_FILE="${LOG_DIR}/system-setup.log"
TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# System configuration
TIMEZONE="Asia/Kolkata"
SWAP_SIZE="2G"  # 2GB swap file

# Package manager choice (npm or pnpm)
PACKAGE_MANAGER="${PACKAGE_MANAGER:-npm}"  # Default to npm if not set

# Non-interactive execution flags
ALLOW_UNSUPPORTED_OS="${ALLOW_UNSUPPORTED_OS:-false}"    # Continue on non-24.04 versions
FORCE_NODE_REINSTALL="${FORCE_NODE_REINSTALL:-false}"    # Reinstall Node.js if wrong version

# Node.js version
NODE_MAJOR_VERSION=20

# Firewall ports
SSH_PORT=22
HTTP_PORT=80
HTTPS_PORT=443

# Backup configuration
BACKUP_DIR="/var/backups/farscape"
BACKUP_USER="farscape-backup"

################################################################################
# HELPER FUNCTIONS
################################################################################

# Logging function
log() {
    local level=$1
    shift
    local message="$*"
    echo -e "[${TIMESTAMP}] [${level}] ${message}" | tee -a "${LOG_FILE}"
}

# Info message (green)
info() {
    echo -e "${GREEN}[INFO]${NC} $*" | tee -a "${LOG_FILE}"
}

# Warning message (yellow)
warn() {
    echo -e "${YELLOW}[WARN]${NC} $*" | tee -a "${LOG_FILE}"
}

# Error message (red)
error() {
    echo -e "${RED}[ERROR]${NC} $*" | tee -a "${LOG_FILE}"
}

# Success message (blue)
success() {
    echo -e "${BLUE}[SUCCESS]${NC} $*" | tee -a "${LOG_FILE}"
}

# Check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Check if running as root
check_root() {
    if [[ $EUID -ne 0 ]]; then
        error "This script must be run as root"
        error "Please run: sudo bash $0"
        exit 2
    fi
}

# Check if OS is Ubuntu 24.04
check_os() {
    if [[ ! -f /etc/os-release ]]; then
        error "Cannot detect OS version"
        exit 3
    fi
    
    source /etc/os-release
    
    if [[ "$ID" != "ubuntu" ]]; then
        error "This script is designed for Ubuntu only"
        error "Detected OS: $ID"
        exit 3
    fi
    
    if [[ "$VERSION_ID" != "24.04" ]]; then
        warn "This script is tested on Ubuntu 24.04"
        warn "Detected version: $VERSION_ID"
        if [[ "$ALLOW_UNSUPPORTED_OS" == "true" ]]; then
            warn "ALLOW_UNSUPPORTED_OS=true, continuing anyway..."
        else
            error "Set ALLOW_UNSUPPORTED_OS=true to continue on unsupported versions"
            exit 3
        fi
    fi
}

# Create log directory
setup_logging() {
    mkdir -p "${LOG_DIR}"
    chmod 755 "${LOG_DIR}"
    touch "${LOG_FILE}"
    chmod 644 "${LOG_FILE}"
    
    info "Logging initialized at ${LOG_FILE}"
}

################################################################################
# INSTALLATION FUNCTIONS
################################################################################

# Update system packages
update_system() {
    info "Updating system packages..."
    
    # Update package lists
    apt-get update -qq
    
    # Upgrade existing packages (non-interactive)
    DEBIAN_FRONTEND=noninteractive apt-get upgrade -y -qq
    
    # Install essential build tools
    DEBIAN_FRONTEND=noninteractive apt-get install -y -qq \
        curl \
        wget \
        git \
        build-essential \
        software-properties-common \
        apt-transport-https \
        ca-certificates \
        gnupg \
        lsb-release \
        vim \
        htop \
        net-tools \
        ufw \
        unzip \
        tar \
        gzip \
        jq
    
    success "System packages updated"
}

# Install Docker
install_docker() {
    if command_exists docker; then
        local docker_version=$(docker --version | awk '{print $3}' | sed 's/,//')
        warn "Docker already installed: ${docker_version}"
        return 0
    fi
    
    info "Installing Docker..."
    
    # Add Docker's official GPG key
    install -m 0755 -d /etc/apt/keyrings
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
    chmod a+r /etc/apt/keyrings/docker.asc
    
    # Add Docker repository
    echo \
        "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
        $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
        tee /etc/apt/sources.list.d/docker.list > /dev/null
    
    # Update package lists
    apt-get update -qq
    
    # Install Docker Engine
    DEBIAN_FRONTEND=noninteractive apt-get install -y -qq \
        docker-ce \
        docker-ce-cli \
        containerd.io \
        docker-buildx-plugin \
        docker-compose-plugin
    
    # Start and enable Docker
    systemctl start docker
    systemctl enable docker
    
    # Verify installation
    if docker --version >/dev/null 2>&1; then
        success "Docker installed: $(docker --version)"
    else
        error "Docker installation failed"
        exit 1
    fi
    
    # Add current user to docker group (if not root)
    if [[ -n "${SUDO_USER:-}" ]]; then
        usermod -aG docker "${SUDO_USER}"
        info "Added ${SUDO_USER} to docker group (logout/login required)"
    fi
}

# Install Node.js
install_nodejs() {
    if command_exists node; then
        local node_version=$(node --version)
        warn "Node.js already installed: ${node_version}"
        
        # Check if it's the correct major version
        local major_version=$(node --version | cut -d'v' -f2 | cut -d'.' -f1)
        if [[ "$major_version" -eq "$NODE_MAJOR_VERSION" ]]; then
            return 0
        else
            warn "Installed version is v${major_version}, expected v${NODE_MAJOR_VERSION}"
            if [[ "$FORCE_NODE_REINSTALL" == "true" ]]; then
                warn "FORCE_NODE_REINSTALL=true, reinstalling correct version..."
            else
                warn "Set FORCE_NODE_REINSTALL=true to reinstall correct version"
                return 0
            fi
        fi
    fi
    
    info "Installing Node.js ${NODE_MAJOR_VERSION} LTS..."
    
    # Download and setup NodeSource repository
    curl -fsSL https://deb.nodesource.com/setup_${NODE_MAJOR_VERSION}.x | bash -
    
    # Install Node.js
    DEBIAN_FRONTEND=noninteractive apt-get install -y -qq nodejs
    
    # Verify installation
    if node --version >/dev/null 2>&1; then
        success "Node.js installed: $(node --version)"
        success "npm installed: $(npm --version)"
    else
        error "Node.js installation failed"
        exit 1
    fi
}

# Install pnpm (optional)
install_pnpm() {
    if [[ "$PACKAGE_MANAGER" != "pnpm" ]]; then
        info "Skipping pnpm installation (using npm)"
        return 0
    fi

    if command_exists pnpm; then
        warn "pnpm already installed: $(pnpm --version)"
        return 0
    fi

    info "Installing pnpm..."

    # Install pnpm globally via npm
    npm install -g pnpm

    # Verify installation
    if pnpm --version >/dev/null 2>&1; then
        success "pnpm installed: $(pnpm --version)"
    else
        error "pnpm installation failed"
        exit 1
    fi
}

# Install GitHub CLI
install_github_cli() {
    if command_exists gh; then
        local gh_version=$(gh --version | head -n1 | awk '{print $3}')
        warn "GitHub CLI already installed: ${gh_version}"
        return 0
    fi

    info "Installing GitHub CLI..."

    # Add GitHub CLI GPG key
    curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg
    chmod go+r /usr/share/keyrings/githubcli-archive-keyring.gpg

    # Add GitHub CLI repository
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | \
        tee /etc/apt/sources.list.d/github-cli.list > /dev/null

    # Update and install
    apt-get update -qq
    DEBIAN_FRONTEND=noninteractive apt-get install -y -qq gh

    # Verify installation
    if gh --version >/dev/null 2>&1; then
        success "GitHub CLI installed: $(gh --version | head -n1 | awk '{print $3}')"
    else
        error "GitHub CLI installation failed"
        exit 1
    fi
}

# Configure UFW firewall
configure_firewall() {
    info "Configuring UFW firewall..."
    
    # Reset UFW to default state
    ufw --force reset
    
    # Set default policies
    ufw default deny incoming
    ufw default allow outgoing
    
    # Allow SSH (critical - do this first!)
    ufw allow ${SSH_PORT}/tcp comment 'SSH'
    
    # Allow HTTP and HTTPS
    ufw allow ${HTTP_PORT}/tcp comment 'HTTP'
    ufw allow ${HTTPS_PORT}/tcp comment 'HTTPS'
    
    # Enable UFW (non-interactive)
    ufw --force enable
    
    # Show status
    ufw status numbered | tee -a "${LOG_FILE}"
    
    success "Firewall configured (ports: ${SSH_PORT}, ${HTTP_PORT}, ${HTTPS_PORT})"
}

# Configure timezone
configure_timezone() {
    info "Setting timezone to ${TIMEZONE}..."
    
    timedatectl set-timezone "${TIMEZONE}"
    
    # Verify
    local current_tz=$(timedatectl | grep "Time zone" | awk '{print $3}')
    success "Timezone set to: ${current_tz}"
}

# Create swap file (if not exists)
create_swap() {
    if swapon --show | grep -q '/swapfile'; then
        warn "Swap file already exists"
        return 0
    fi
    
    info "Creating ${SWAP_SIZE} swap file..."
    
    # Create swap file
    fallocate -l "${SWAP_SIZE}" /swapfile
    chmod 600 /swapfile
    mkswap /swapfile
    swapon /swapfile
    
    # Make swap permanent
    if ! grep -q '/swapfile' /etc/fstab; then
        echo '/swapfile none swap sw 0 0' >> /etc/fstab
    fi
    
    success "Swap file created and enabled"
}

# Setup backup directories and user
setup_backup_infrastructure() {
    info "Setting up backup infrastructure..."
    
    # Create backup user (system user, no login)
    if ! id "${BACKUP_USER}" >/dev/null 2>&1; then
        useradd -r -s /bin/false -d "${BACKUP_DIR}" "${BACKUP_USER}"
        success "Created backup user: ${BACKUP_USER}"
    else
        warn "Backup user already exists: ${BACKUP_USER}"
    fi
    
    # Create backup directory structure
    mkdir -p "${BACKUP_DIR}"/{database,minio,app,scripts}
    
    # Set permissions (only root and backup user can access)
    chown -R root:${BACKUP_USER} "${BACKUP_DIR}"
    chmod -R 750 "${BACKUP_DIR}"
    
    success "Backup directories created at ${BACKUP_DIR}"
}

# System hardening
harden_system() {
    info "Applying system hardening..."
    
    # Disable root login via SSH (but keep for sudo users)
    sed -i 's/^#*PermitRootLogin.*/PermitRootLogin no/' /etc/ssh/sshd_config
    
    # Disable password authentication (key-based only)
    sed -i 's/^#*PasswordAuthentication.*/PasswordAuthentication no/' /etc/ssh/sshd_config
    
    # Enable SSH key-based authentication
    sed -i 's/^#*PubkeyAuthentication.*/PubkeyAuthentication yes/' /etc/ssh/sshd_config
    
    # Restart SSH to apply changes
    systemctl restart sshd
    
    success "System hardening applied (root login disabled, password auth disabled)"
}

# Setup automatic security updates
setup_auto_updates() {
    info "Configuring automatic security updates..."
    
    DEBIAN_FRONTEND=noninteractive apt-get install -y -qq unattended-upgrades
    
    # Enable automatic updates
    cat > /etc/apt/apt.conf.d/20auto-upgrades <<EOF
APT::Periodic::Update-Package-Lists "1";
APT::Periodic::Unattended-Upgrade "1";
APT::Periodic::AutocleanInterval "7";
EOF
    
    success "Automatic security updates enabled"
}

# Print installation summary
print_summary() {
    echo ""
    echo "════════════════════════════════════════════════════════════════"
    echo "  Farscape System Setup - Installation Summary"
    echo "════════════════════════════════════════════════════════════════"
    echo ""
    echo "✅ System packages updated"
    echo "✅ Docker installed: $(docker --version | awk '{print $3}')"
    echo "✅ Docker Compose installed: $(docker compose version | awk '{print $4}')"
    echo "✅ Node.js installed: $(node --version)"
    echo "✅ npm installed: v$(npm --version)"
    
    if command_exists pnpm; then
        echo "✅ pnpm installed: v$(pnpm --version)"
    fi

    if command_exists gh; then
        echo "✅ GitHub CLI installed: v$(gh --version | head -n1 | awk '{print $3}')"
    fi

    echo "✅ UFW firewall configured (ports: ${SSH_PORT}, ${HTTP_PORT}, ${HTTPS_PORT})"
    echo "✅ Timezone: $(timedatectl | grep 'Time zone' | awk '{print $3}')"
    echo "✅ Swap: ${SWAP_SIZE}"
    echo "✅ Backup infrastructure ready at ${BACKUP_DIR}"
    echo "✅ Logging directory: ${LOG_DIR}"
    echo ""
    echo "════════════════════════════════════════════════════════════════"
    echo "  Security Configuration"
    echo "════════════════════════════════════════════════════════════════"
    echo ""
    echo "⚠️  SSH root login: DISABLED"
    echo "⚠️  SSH password authentication: DISABLED"
    echo "✅ SSH key-based authentication: ENABLED"
    echo "✅ Automatic security updates: ENABLED"
    echo ""
    echo "════════════════════════════════════════════════════════════════"
    echo "  Next Steps"
    echo "════════════════════════════════════════════════════════════════"
    echo ""
    echo "1. Logout and login again to apply docker group membership"
    echo "2. Run: bash 02-create-monorepo.sh"
    echo "3. Check logs: tail -f ${LOG_FILE}"
    echo ""
    echo "════════════════════════════════════════════════════════════════"
    echo ""
}

################################################################################
# MAIN EXECUTION
################################################################################

main() {
    clear 2>/dev/null || true

    echo "════════════════════════════════════════════════════════════════"
    echo "  Farscape B2B Platform - System Setup"
    echo "════════════════════════════════════════════════════════════════"
    echo ""
    echo "This script will install and configure:"
    echo "  • Docker + Docker Compose"
    echo "  • Node.js ${NODE_MAJOR_VERSION} LTS + ${PACKAGE_MANAGER}"
    echo "  • GitHub CLI (gh)"
    echo "  • UFW Firewall (SSH, HTTP, HTTPS)"
    echo "  • System hardening"
    echo "  • Backup infrastructure"
    echo ""
    echo "════════════════════════════════════════════════════════════════"
    echo ""
    
    # Pre-flight checks
    check_root
    check_os
    setup_logging
    
    info "Starting system setup..."
    info "Detected OS: $(lsb_release -d | cut -f2)"
    info "Package manager: ${PACKAGE_MANAGER}"
    
    # Run installation steps
    update_system
    install_docker
    install_nodejs
    install_pnpm
    install_github_cli
    configure_firewall
    configure_timezone
    create_swap
    setup_backup_infrastructure
    harden_system
    setup_auto_updates
    
    # Print summary
    print_summary
    
    success "System setup completed successfully!"
    info "Log file: ${LOG_FILE}"
    
    exit 0
}

# Run main function
main "$@"
