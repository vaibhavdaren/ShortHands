#!/bin/bash
## This script should be used to fix date / time of the VM
## My vm date and time used to drift out when it was not in use from my macbook
## This script can simply be run to fix it.

# Ensure the script is run as root
if [ "$EUID" -ne 0 ]; then
  echo "Please run as root or with sudo"
  exit 1
fi

echo "--- Fedora Time & Date Sync Tool ---"

# 1. Force a rough date update using a web header if NTP is failing
# This is useful when the date is so far off that chrony ignores it.
echo "Fetching current date from global servers..."
HTTP_DATE=$(curl -s --head http://google.com | grep ^Date: | sed 's/Date: //g')

if [ -n "$HTTP_DATE" ]; then
    echo "Setting system clock to web time: $HTTP_DATE"
    date -s "$HTTP_DATE" > /dev/null
else
    echo "Could not fetch web time. Proceeding with NTP sync..."
fi

# 2. Manage chronyd service
if ! systemctl is-active --quiet chronyd; then
    echo "Starting chronyd service..."
    systemctl start chronyd
fi

# 3. Request a fast burst and force a step
echo "Attempting high-priority NTP burst sync..."
chronyc burst 4/4
sleep 2
# Force an immediate jump regardless of how large the offset is
chronyc makestep

# 4. Sync the Hardware Clock (RTC)
# This writes the current system time to the VM's virtual BIOS
echo "Syncing hardware clock..."
hwclock --systohc

# 5. Sanity check for massive drift
CURRENT_YEAR=$(date +%Y)
if [ "$CURRENT_YEAR" -lt 2024 ]; then
    echo "WARNING: System date still appears incorrect ($CURRENT_YEAR)."
    echo "Please ensure the VM host time is correct and network access is available."

    read -p "Would you like to manually set the date as a last resort? (y/n): " confirm
    if [[ $confirm == [yY] || $confirm == [yY][eE][sS] ]]; then
        echo "Enter the current date and time in format: YYYY-MM-DD HH:MM:SS"
        read -p "Date/Time: " manual_date
        date -s "$manual_date" && hwclock --systohc
    fi
fi

# 6. Show final status
echo "--- Final Sync Status ---"
chronyc tracking
echo "Current System Time: $(date)"

echo "Update process complete."
