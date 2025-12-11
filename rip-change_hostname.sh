#!/bin/sh
# Raspberry Pi OS hostname changer – pure POSIX sh (works with dash)
#Created by GuN® after long 10 minutes strugle! ;)

# Check root
if [ "$(id -u)" -ne 0 ]; then
    echo "This script must be run as root (sudo)"
    exit 1
fi

echo "=== Raspberry Pi OS – Change Hostname Changer ==="
echo

# Get new hostname with validation
while :; do
    printf "Enter new hostname (lowercase, no spaces): "
    read new_hostname || exit 1

    # lowercase + remove spaces
    new_hostname=$(echo "$new_hostname" | tr '[:upper:]' '[:lower:]' | tr -d ' \t\r')

    [ -z "$new_hostname" ] && { echo "Cannot be empty"; continue; }
    [ ${#new_hostname} -gt 63 ] && { echo "Max 63 characters"; continue; }

    # valid characters and does not start/end with hyphen
    case "$new_hostname" in
        -*|*-) echo "Cannot start or end with hyphen"; continue ;;
        *[!a-z0-9-]*) echo "Only a-z, 0-9 and hyphen allowed"; continue ;;
    esac
    break
done

old_hostname=$(cat /etc/hostname | tr -d '\n\r ')

echo
echo "Changing hostname:"
echo "   Old: $old_hostname"
echo "   New: $new_hostname"
echo

# 1. Official Raspberry Pi way
raspi-config nonint do_hostname "$new_hostname"

# 2. Clean and fix /etc/hosts
cp /etc/hosts /etc/hosts.bak.$(date +%Y%m%d-%H%M%S)

# Delete any line that contains the old hostname (except comments)
sed -i "/[[:space:]]$old_hostname\b/d" /etc/hosts

# Delete any old 127.0.1.1 line
sed -i '/^127\.0\.1\.1[[:space:]]/d' /etc/hosts

# Add the correct line after localhost line
sed -i "/^127\.0\.0\.1[[:space:]]\+localhost/a127.0.1.1\t$new_hostname" /etc/hosts

echo
echo "Done! New hostname is: $new_hostname"
echo
echo "Relevant lines in /etc/hosts:"
grep "^127\." /etc/hosts
echo
echo "Please reboot now:"
echo "   sudo reboot"
