#!/bin/bash
#--------------------
# YIO Remote software updater script
#--------------------

#--------------------
# 1. Show the update screen
#--------------------
fbv -d 1 /usr/bin/yio-remote/images/update.png
echo $(date -u) "Update image loaded" > /var/log/update.log


#--------------------
# 2. Create temp location
#--------------------
mkdir -p /usr/bin/yio-tmp
echo $(date -u) "Temp dir created" >> /var/log/update.log


#--------------------
# 3. Unzip the downloaded file
#--------------------
unzip /usr/bin/yio-remote/downloads/latest.zip -d /usr/bin/yio-tmp
echo $(date -u) "Update unzipped" >> /var/log/update.log


#--------------------
# 4. Give executable permissions to all .sh files
#--------------------
find /usr/bin/yio-tmp -type f -name "*.sh" -exec chmod 775 {} +
chmod +x /usr/bin/yio-tmp/remote
echo $(date -u) "File attributes set" >> /var/log/update.log


#--------------------
# 5. Launch a script with commands to run before the update
#--------------------
/usr/bin/yio-remote/before-update.sh
echo $(date -u) "Before update commands run" >> /var/log/update.log


#--------------------
# 6. Remove previous backups (should not be needed, unless this scripts fails somewhere, therefore not yet implemented)
#--------------------
rm -rf /usr/bin/yio-remote-backup
echo $(date -u) "Old backup removed" >> /var/log/update.log


#--------------------
# 7. Make a backup of the /usr/bin/yio-remote folder (if not already exist, maybe add timestamp to folder)
#--------------------
cp /usr/bin/yio-remote /usr/bin/yio-remote-backup
echo $(date -u) "New backup created" >> /var/log/update.log


#--------------------
# 8. Copy the update folder contents to /usr/bin/yio-remote
#--------------------
cp -rf /usr/bin/yio-tmp/* /usr/bin/yio-remote
echo $(date -u) "Update copied" >> /var/log/update.log
sleep 2


#--------------------
# 9. Launch a script with remaning commands
# this is used to copy/move files and execute commands with each update
#--------------------
/usr/bin/yio-remote/after-update.sh
echo $(date -u) "After update commands run" >> /var/log/update.log


#--------------------
# 10. Launch the remote app with the launcher bash script
#--------------------
echo $(date -u) "Launching app" >> /var/log/update.log
/usr/bin/yio-remote/app-launch.sh &
