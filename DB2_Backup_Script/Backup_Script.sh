# What does this script do 
1. Check for the space in the server
2. Take a backup (full online compress in this example)
3. Copy it to another server
4. Remove Old Backup’s 

if [ -f /home/db2inst1/sqllib/db2profile ]; then
    . /home/db2inst1/sqllib/db2profile
fi

#!/bin/sh

# Check for the space in specific partition you are taking backup,in my case it’s /dev/md0 , type df –h and you will know yours and replace /dev/md0 with that 

space=`df | grep /dev/md0 | awk  '{print $4}'`

# I checked for space to < 1.1G , Change it to your requirements 

if [ $space -lt 1111111 ]; then
 
echo -e "No enough space to take backup , Clear some space in the filesystem for the Backup to be Taken\n" | tee –a /path/backup_logs.out
else
echo -e "--------------------------------------------------\n" | tee –a  /path/backup_logs.out
echo -e "Backup Summary DB-NAME for date:`date +%Y-%m-%d`\n" >> /path/backup_logs.out
echo -e "--------------------------------------------------\n" | tee –a  /path/backup_logs.out
 
# Check if the backup already exists else take a backup 

if [ -f /path/DB-NAME.0.db2inst1.NODE0000.CATN0000.`date +%Y%m%d`* ] ; then
        echo -e "The backup for this `date +%Y-%m-%d` already exists " | tee –a  /path/backup_logs.out
		exit 2
else
 
/home/db2inst1/sqllib/bin/db2 connect to db-name
/home/db2inst1/sqllib/bin/db2 backup db db-name online to /path/ compress include logs
 
# Check for the exit status and report back up successfully done or not 

        if [ "$?" -eq 0 ]; then
                echo -e "Backup for DB-NAME completed successfully for the date:`date +%Y-%m-%d`\n" | tee –a  /path/backup_logs.out
                else
                echo -e "Backup for DB-NAME did not complete successfully for the date:`date +%Y-%m-%d`\n" | tee –a  /path/backup_logs.out
        fi

/home/db2inst1/sqllib/bin/db2 connect reset

# Make the server idle for some time because immediately after taking backup the load on the server would be high , so to avoid that 

sleep 90s

# Start Copying the backup and log the output, To make this happen you need to make the two servers Paswordless , for that you need to generate a rsh pub and priv key and add pub key to the target server so that you will not be prompted for the password 

echo -e "Started copying backup for the date:`date +Y-%m-%d` to serverIP:/path-to-copy \n" >> /path/backup_logs.out
scp /path/DB-NAME.0.db2inst1.NODE0000.CATN0000.`date +%Y%m%d`* username@serverIP:/path-to-copy 
echo -e "Copying Completed at `date`\n" | tee –a  /path/backup_logs.out
sleep 10s
fi

# Remove Old Backup according to retention policy , In this example I have done it for 5 days 

if [ -f /path/DB-NAME.0.db2inst1.NODE0000.CATN0000.`date +%Y%m%d -d "5 days ago"`* ]; then
        rm /path/DB-NAME.0.db2inst1.NODE0000.CATN0000.`date +%Y%m%d -d "5 days ago"`*
        echo -e "The Backup taken on `date +%Y%m%d -d "5 days ago"` has been removed\n" | tee –a  /path/backup_logs.out
  else
  echo -e "The Backup for the date:`date +%Y%m%d -d "5 days ago"` was not found , so no file is deleted\n" | tee –a  /path/backup_logs.out
fi