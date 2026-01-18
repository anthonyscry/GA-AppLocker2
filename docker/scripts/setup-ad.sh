#!/bin/bash
# Setup script for Samba AD DC
# Creates test OUs, users, and computers for GA-AppLocker testing

set -e

echo "Waiting for Samba AD to be fully initialized..."
sleep 30

# Function to run samba-tool commands
run_samba_tool() {
    samba-tool "$@" --username=Administrator --password="${DOMAINPASS}"
}

echo "Creating test Organizational Units..."

# Create OU structure for testing
run_samba_tool ou create "OU=Workstations,DC=yourlab,DC=local" 2>/dev/null || true
run_samba_tool ou create "OU=Servers,DC=yourlab,DC=local" 2>/dev/null || true
run_samba_tool ou create "OU=Development,OU=Workstations,DC=yourlab,DC=local" 2>/dev/null || true
run_samba_tool ou create "OU=Production,OU=Workstations,DC=yourlab,DC=local" 2>/dev/null || true
run_samba_tool ou create "OU=Test,OU=Workstations,DC=yourlab,DC=local" 2>/dev/null || true

echo "Creating test users..."

# Create test users
run_samba_tool user create testuser1 'TestPass123!' \
    --given-name="Test" --surname="User1" \
    --mail-address="testuser1@yourlab.local" 2>/dev/null || true

run_samba_tool user create testuser2 'TestPass123!' \
    --given-name="Test" --surname="User2" \
    --mail-address="testuser2@yourlab.local" 2>/dev/null || true

run_samba_tool user create svc_applocker 'SvcPass123!' \
    --given-name="AppLocker" --surname="Service" \
    --description="GA-AppLocker Service Account" 2>/dev/null || true

echo "Creating test computer accounts..."

# Create computer accounts in different OUs
run_samba_tool computer create DEVWS001 --ou="OU=Development,OU=Workstations,DC=yourlab,DC=local" 2>/dev/null || true
run_samba_tool computer create DEVWS002 --ou="OU=Development,OU=Workstations,DC=yourlab,DC=local" 2>/dev/null || true
run_samba_tool computer create PRODWS001 --ou="OU=Production,OU=Workstations,DC=yourlab,DC=local" 2>/dev/null || true
run_samba_tool computer create PRODWS002 --ou="OU=Production,OU=Workstations,DC=yourlab,DC=local" 2>/dev/null || true
run_samba_tool computer create TESTWS001 --ou="OU=Test,OU=Workstations,DC=yourlab,DC=local" 2>/dev/null || true
run_samba_tool computer create SRV001 --ou="OU=Servers,DC=yourlab,DC=local" 2>/dev/null || true
run_samba_tool computer create SRV002 --ou="OU=Servers,DC=yourlab,DC=local" 2>/dev/null || true

echo "Creating security groups..."

# Create security groups for AppLocker testing
run_samba_tool group add "AppLocker-Admins" --description="AppLocker Administrators" 2>/dev/null || true
run_samba_tool group add "AppLocker-Operators" --description="AppLocker Operators" 2>/dev/null || true
run_samba_tool group add "Development-Users" --description="Development Department Users" 2>/dev/null || true
run_samba_tool group add "Production-Users" --description="Production Department Users" 2>/dev/null || true

# Add users to groups
run_samba_tool group addmembers "AppLocker-Admins" "Administrator" 2>/dev/null || true
run_samba_tool group addmembers "AppLocker-Operators" "testuser1" 2>/dev/null || true
run_samba_tool group addmembers "Development-Users" "testuser1,testuser2" 2>/dev/null || true

echo "AD test environment setup complete!"
echo ""
echo "Domain: YOURLAB.LOCAL"
echo "DC: dc1.yourlab.local (172.28.0.10)"
echo ""
echo "Test OUs:"
echo "  - OU=Workstations,DC=yourlab,DC=local"
echo "  - OU=Development,OU=Workstations,DC=yourlab,DC=local"
echo "  - OU=Production,OU=Workstations,DC=yourlab,DC=local"
echo "  - OU=Test,OU=Workstations,DC=yourlab,DC=local"
echo "  - OU=Servers,DC=yourlab,DC=local"
echo ""
echo "Test Users: testuser1, testuser2, svc_applocker"
echo "Test Computers: DEVWS001, DEVWS002, PRODWS001, PRODWS002, TESTWS001, SRV001, SRV002"
