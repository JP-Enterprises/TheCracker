#!/bin/bash
ip="$1"
GREEN='\033[0;32m'
RED='\033[0;31m' 
NC='\033[0m'

if [ ! -d "scans" ]; then
    mkdir scans
fi
if [ ! -d "scripts" ]; then
    mkdir scripts
fi


#nmap section
echo -e "${GREEN}Running Nmap on Target Host${NC}"
nmap -sVC $ip > ./scans/nmap.txt

if grep -q "ldap" "./scans/nmap.txt"; then
  domainname=$(cat ./scans/nmap.txt | grep -oP "(?<=Domain: )[A-Z0-9.-]+.*LOCAL" | head -n 1)
  echo -e "${RED}Domain name Found: $domainname${NC}"
fi


#enum4linux section
echo -e "${GREEN}Running Enum4Linux on Target Host${NC}"
enum4linux $ip > ./scans/enum4linux.txt

if grep -q "allows sessions using username '', password ''" "./scans/enum4linux.txt"; then
  echo -e "${RED}$ip allows sessions using username '', password ''${NC}"
fi

#kerbrute section
if [ ! -d "/usr/share/seclists" ]; then
  echo "Installing Seclists"      
  apt-get -qq install seclists >/dev/null 2>&1 
fi

if [ ! -f "./scripts/kerbrute_linux_amd64" ]; then
  cd scripts
  wget -q https://github.com/ropnop/kerbrute/releases/download/v1.0.3/kerbrute_linux_amd64
  cd ..
  chmod +x ./scripts/kerbrute_linux_amd64
fi
echo -e "${GREEN}Enumerating Users${NC}"

./scripts/kerbrute_linux_amd64 userenum -d $domainname /usr/share/seclists/Usernames/xato-net-10-million-usernames.txt --dc $ip  > scans/users.txt
