#!/bin/sh
#----------------------------------------------------------------------#
# Sript Name   : db2_backup.sh
# Author        : VLN Manohar Viswanatha
# Company       : Radiant Info Systems
# Date Written  : Feb 2013
# Script Version:
# DB2 Version   : 9.1
# Purpose       : To check space , remove old backups and take backups
# Usage         :
# Change Log    :
#
# Date     Chg by              Ver.    Description
# -------- ------------------ ------- -----------------------------------
# 02/18/13 Manohar Viswanatha 1.0.1   First step
# 02/18/13 Manohar Viswanatha 1.0.2   Added Code to check profile file
# #----------------------------------------------------------------------#


#Copy taken backup to server 13

copy13()
{
echo -e "started copying AWDRT && GSRTC Backup's to 13" >> db2_backup.log 2>&1
scp /home/ftpusr/backup/AWDRT.0.db2inst1.NODE0000.CATN0000.`date +%Y%m%d`* root@192.168.222.13:/home/DB2_Backups/ >> db2_backup.log 2>&1
scp /home/ftpusr/backup/GSRTC.0.db2inst1.NODE0000.CATN0000.`date +%Y%m%d`* root@192.168.222.13:/home/DB2_Backups/ >> db2_backup.log 2>&1
}

#Check for a valid profile

prfile=~/sqllib/db2profile

profile()
{
echo -e "Checking profile file" >> db2_backup.log 2>&1
if [ -f $prfile ] && [ "$prfile" != "" ];
then
        . $prfile
else
        read -p "Enter a valid Profile : " prfile
        profile
fi
echo -e "DONE" >> db2_backup.log 2>&1
}

#Function to take backups

backup()
{
echo -e "AWDRT Backup Started ..." >> db2_backup.log 2>&1
#db2 "backup db awdrt online to /home/ftpusr/backup/ compress include logs" >> db2_backup.log 2>&1 
echo -e "AWDRT Backup done" >> db2_backup.log 2>&1
sleep 2m
echo -e "GSRTC Backup Started ..." >> db2_backup.log 2>&1
#db2 "backup db gsrtc online to /home/ftpusr/backup/ compress include logs" >> db2_backup.log 2>&1
echo -e "GSRTC Backup done" >> db2_backup.log 2>&1
}

#Function to purge old backup until the space > 2G

purge_old_backups()
{
while [ $(echo "$space <= 2" | bc) -ne 0 ]
do
echo -e "Purging backups(AWDRT && GSRTC) for the date : `date +%Y%m%d -d \"$i days ago\"`" >> db2_backup.log 2>&1
#rm  /home/ftpusr/backup/AWDRT.0.db2inst1.NODE0000.CATN0000.`date +%Y%m%d -d "$i days ago"`* >> db2_backup.log 2>&1
#rm  /home/ftpusr/backup/GSRTC.0.db2inst1.NODE0000.CATN0000.`date +%Y%m%d -d "$i days ago"`* >> db2_backup.log 2>&1
i=$[i-1]
done
}

#Main Script 

profile
space=`df -h|grep /dev/md0|awk '{print $4}'|sed 's/G//'`
echo -e "Space Before : $space" >> db2_backup.log 2>&1
i=100
purge_old_backups
backup
copy13
echo -e "Space After : $space" >> db2_backup.log 2>&1



