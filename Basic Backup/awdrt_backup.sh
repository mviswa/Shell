#!/bin/sh

##########   BACKUP ######################################################


/home/db2inst2/sqllib/bin/db2 "backup db awdrt online to /home/DB_BKPS compress include logs" > /dev/null 2>&1

sleep 90s

###### COPY TO 192.168.222.13 #############################################

scp /home/DB_BKPS/AWDRT.0.db2inst2.NODE0000.CATN0000.`date +%Y%m%d`* root@192.168.222.13:/home/DB_BKPS/ > /dev/null 2>&1

#cp /home/DB_BKPS/AWDRT.0.db2inst2.NODE0000.CATN0000.`date +%Y%m%d`* /media/FreeAgent_GoFlex_Drive/AWDRT 

#####     REMOVE OLD BACKUPS    ############################################

if [ -f /home/DB_BKPS/AWDRT.0.db2inst2.NODE0000.CATN0000.`date +%Y%m%d -d "5 days ago"`* ]; then

rm  /home/DB_BKPS/AWDRT.0.db2inst2.NODE0000.CATN0000.`date +%Y%m%d -d "5 days ago"`*  > /dev/null 2>&1

fi 



