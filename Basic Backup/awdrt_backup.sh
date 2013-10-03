#!/bin/sh

##########   BACKUP ######################################################


/home/db2inst2/sqllib/bin/db2 "backup db db-name online to /home/DB_BKPS compress include logs" > /dev/null 2>&1

sleep 90s

###### COPY TO 192.168.222.13 #############################################

scp /home/DB_BKPS/DB_NAME.0.db2inst2.NODE0000.CATN0000.`date +%Y%m%d`* user@remote-host:/home/DB_BKPS/ > /dev/null 2>&1

#cp /home/DB_BKPS/DB_NAME.0.db2inst2.NODE0000.CATN0000.`date +%Y%m%d`* /media/PATH/DB_NAME 

#####     REMOVE OLD BACKUPS    ############################################

if [ -f /home/DB_BKPS/DB_NAME.0.db2inst2.NODE0000.CATN0000.`date +%Y%m%d -d "5 days ago"`* ]; then

rm  /home/DB_BKPS/DB_NAME.0.db2inst2.NODE0000.CATN0000.`date +%Y%m%d -d "5 days ago"`*  > /dev/null 2>&1

fi 



