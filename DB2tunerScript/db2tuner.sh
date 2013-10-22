#!/bin/sh

clear


#Colors

BLACK=$(tput setaf 0)
RED=$(tput setaf 1)
GREEN=$(tput setaf 2)
YELLOW=$(tput setaf 3)
LIME_YELLOW=$(tput setaf 190)
POWDER_BLUE=$(tput setaf 153)
BLUE=$(tput setaf 4)
MAGENTA=$(tput setaf 5)
CYAN=$(tput setaf 6)
WHITE=$(tput setaf 7)
BRIGHT=$(tput bold)
NORMAL=$(tput sgr0)
BLINK=$(tput blink)
REVERSE=$(tput smso)
UNDERLINE=$(tput smul)


db2path=`which db2`
#db2info
# Db2 information variables

#VERSION=`/usr/local/bin/db2ls |grep V |awk '{print $2}'`
#FIXPACK=`/usr/local/bin/db2ls |grep V |awk '{print $3}'`
#INSTPATH=`/usr/local/bin/db2ls |grep V |awk '{print $1}'`
#INSTDTE=`/usr/local/bin/db2ls |grep V |awk '{print $4, $5, $6, $7, $8}'`

# DB2 INFORMATION

#echo -e "--------------------Product Information------------------------------------------------\n"
#echo -e "${BRIGHT}DB2 VERSION\tFIXPACK\t\tINSTALLED ON\t\tPATH${NORMAL}"
#echo -e "${BRIGHT}$VERSION\t\t   $FIXPACK\t$INSTDTE\t$INSTPATH${NORMAL}"
#echo -e "${BRIGHT}INSTALLED ON : $INSTDTE${NORMAL}"
#echo -e "${BRIGHT}DB2 VERSION : $VERSION${NORMAL}"
#echo -e "${BRIGHT}FIXPACK : $FIXPACK${NORMAL}"
#echo -e "${BRIGHT}INSTALLATION PATH : $INSTPATH${NORMAL}"

#Selecting database
#dblist=`$db2path "list db directory"|grep "Database name"|wc -l`

#if [ $dblist != 1 ];
#then
#echo -e "\nYou have more than 1 database in this instance\n"
#$db2path "list db directory"|grep "Database name"|awk '{print $4}'
#printf "\n"
#read -p "Select a database : " dbname
#else
#dbname=`$db2path "list db directory"|grep "Database name"|awk '{print $4}'`
#fi


snapshot()
{

echo -e "\n"

# RESET MONITOR SWITCHES

echo -e "${YELLOW}RESETTING MONITOR SWITCHES ${NORMAL}"
$db2path "reset monitor all" > /dev/null
echo -e "${GREEN}DONE...${NORMAL}"
sleep 5s

#UPDATE MONITOR SWITCHES TO ON

echo -e "\n${YELLOW}UPDATING MONITOR SWITCHES TO ${GREEN}ON${NORMAL}"
$db2path "update dbm cfg using DFT_MON_BUFPOOL ON DFT_MON_LOCK ON DFT_MON_SORT ON DFT_MON_STMT ON DFT_MON_TABLE ON DFT_MON_TIMESTAMP ON DFT_MON_UOW ON" > /dev/null
$db2path "update monitor switches using BUFFERPOOL ON LOCK ON SORT ON STATEMENT ON TABLE ON TIMESTAMP ON UOW ON"  > /dev/null
echo -e "${GREEN}DONE...${NORMAL}"
echo -e "${YELLOW}Wait for 15 min and leave the session open to collect the information.....${NORMAL}\n"
sleep 15m

#COLLECT SNAPSHOTS

echo -e "${YELLOW}Collecting Snapshot information${NORMAL}\n"
$db2path "get snapshot for db on $dbname" > snap.out
$db2path "get snapshot for all bufferpools" >> snap.out
$db2path "get snapshot for dbm" >> snap.out


#UPDATE MONITOR SWITCHES TO OFF

echo -e "${YELLOW}UPDATING MONITOR SWITCHES TO ${RED}OFF${NORMAL}"
$db2path "update dbm cfg using  DFT_MON_LOCK OFF DFT_MON_SORT OFF DFT_MON_STMT OFF DFT_MON_TABLE OFF DFT_MON_TIMESTAMP OFF DFT_MON_UOW OFF" > /dev/null
$db2path "update monitor switches using LOCK OFF SORT OFF STATEMENT OFF TABLE OFF TIMESTAMP OFF UOW OFF"  > /dev/null
echo -e "${GREEN}DONE...${NORMAL}\n"

db2info
recommendations
}

recommendations()
{
#echo -e "\n"

# PARAMETERS

LPR=`grep "Log pages read" snap.out|awk '{print $5}'`             #Log Pages Read
LPW=`grep "Log pages written" snap.out |awk '{print $5}'`             #Log Pages Written
TS=`grep "Total sorts" snap.out |awk '{print $4}'`              #Total Sorts
CSA=`grep "Commit statements attempted" snap.out |awk '{print $5}'`             #Commit Statements Attempted
RSA=`grep "Rollback statements attempted" snap.out |awk '{print $5}'`             #Rollback Statements Attempted
SO=`grep "Sort overflows" snap.out |awk '{print $4}'`              #Sort Overflows


echo -e "\n${BRIGHT}RECOMMENDATIONS"
echo -e "${BRIGHT}----------------------------------------------------------------------"

#LOGBUFSZ

LPRT=$[LPR/(LPW+1)]
if [ $LPR -eq 0 ];
then
echo -e "[${GREEN}OK${NORMAL}]LOGBUFSZ"
fi
if [ $LPR -gt 0 ] && [ $LPR -lt 10 ] && [ $LPRT -eq 0 ];
then
echo -e "[${RED}**${NORMAL}]LOFBUFSZ should be increased a bit"
fi
if [ $LPR -gt 10 ] && [ $LPRT -ne 0 ];
then
echo -e "[${RED}**${NORMAL}]LOGBUFSZ should be considerably increased"
fi


#SORTHEAP and SHEAPTHRES

SPT=$[TS/(CSA+RSA)]
PSO=$[(SO*100)/TS]
if [ $SPT -gt 5 ];
then
echo -e "[${RED}****************${NORMAL}]Too many Sorts per transactions,Increase SORTHEAP${NORMAL}\n${BRIGHT}Note:-SHEAPTHRES should be a multiple of SORTHEAP"
elif [ $PSO -gt 3 ];
then
echo -e "[${RED}**${NORMAL}]Unexpexted Large Sorts Going on,Increase SORTHEAP (this is a temporary Solution, You need to add right indexes for this problem to solve${NORMAL}\n${BRIGHT}Note:-SHEAPTHRES should be a multiple of SORTHEAP"
else
echo -e "[${GREEN}OK${NORMAL}]SORTHEAP & SHEAPTHRES"
fi


# MAXAGENTS

AGW=`grep "Agents stolen from another application" snap.out |awk '{print $7}'`
AGS=`grep "Agents stolen from another application" snap.out |awk '{print $7}'`

if [ $AGW -ne 0 ] || [ $AGS -ne 0 ];
then
echo -e "[${RED}**${NORMAL}]Increase MAXAGENTS"
elif [ $AGW -eq 0 ] && [ $AGS -eq 0 ];
then
echo -e "[${GREEN}OK${NORMAL}]MAXAGENTS"
fi


# LOCKLIST

LLM=`grep "Lock list memory in use (Bytes)" snap.out |awk '{print $8}'`
LL=`$db2path "get db cfg for $dbname" | grep LOCKLIST | awk '{print $9}'`
LLC=$[LL/2]
if [ $LLM -gt $LLC ];
then
echo -e "[${RED}**${NORMAL}]Increase LOCKLIST"
else
echo -e "[${GREEN}OK${NORMAL}]LOCKLIST"
fi


#CATALOGCACHE_SZ(DB)

CCI=`grep "Catalog cache inserts" snap.out |awk '{print $5}'`
CCL=`grep "Catalog cache lookups" snap.out |awk '{print $5}'`
CCO=`grep "Catalog cache overflows" snap.out | awk '{print $5}'`
CCHR=$[(1-(CCI/CCL))*100]
if [ $CCHR -lt 95 ];
then
echo -e "[${RED}**${NORMAL}]CATALOGCACHE HIT RATIO is below 95 , INCREASE CATALOGCACHE_SZ"
fi
if [ $CCO -gt 0 ];
then
echo -e "[${RED}**${NORMAL}]Catlaog Cache Overflows Noticed , INCREASE CATALOGCACHE_SZ"
fi
if [ $CCHR -gt 94 ] && [ $CCO -eq 0 ];
then
echo -e "[${GREEN}OK${NORMAL}]CATALOGCACHE_SZ"
fi


#PKGCACHESZ (DB)

PKI=`grep "Package cache inserts" snap.out |awk '{print $5}'`
PKL=`grep "Package cache lookups" snap.out |awk '{print $5}'`
PKO=`grep "Package cache overflows" snap.out |awk '{print $5}'`
PCHR=$[(1-(PKI/PKL))*100]
if [ $PCHR -lt 95 ];
then
echo -e "[${RED}**${NORMAL}]PACKAGE CACHE HIT RATIO is below 95 , INCREASE PKGCACHESZ"
fi
if [ $CCO -gt 0 ];
then
echo -e "[${RED}**${NORMAL}]PACKAGE overflows Noticed , INCREASE PKGCACHESZ"
fi
if [ $CCHR -gt 94 ] && [ $CCO -eq 0 ];
then
echo -e "[${GREEN}OK${NORMAL}]PKGCACHE"
fi


#MAXFILOPEN

DBFC=`grep -m 1 "Database files closed" snap.out |awk '{print $5}'`
if [ $DBFC -ne 0 ];
then
echo -e "[${RED}**${NORMAL}]Increase MAXFILOP"
fi

if [ $DBFC -eq 0 ];
then
echo  -e "[${GREEN}OK${NORMAL}]MAXFILOP"
fi
}


###########################Database Information######################################################

# Db2 information variables

VERSION=`/usr/local/bin/db2ls |grep V |awk '{print $2}'`
FIXPACK=`/usr/local/bin/db2ls |grep V |awk '{print $3}'`
INSTPATH=`/usr/local/bin/db2ls |grep V |awk '{print $1}'`
INSTDTE=`/usr/local/bin/db2ls |grep V |awk '{print $4, $5, $6, $7, $8}'`

# DB2 INFORMATION

echo -e "----------------------Product Information-------------------------------------------------\n"
echo -e "${BRIGHT}DB2 VERSION\tFIXPACK\t\tINSTALLED ON\t\tPATH${NORMAL}"
echo -e "${BRIGHT}$VERSION\t\t   $FIXPACK\t$INSTDTE\t$INSTPATH${NORMAL}"
#echo -e "${BRIGHT}INSTALLED ON : $INSTDTE${NORMAL}"
#echo -e "${BRIGHT}DB2 VERSION : $VERSION${NORMAL}"
#echo -e "${BRIGHT}FIXPACK : $FIXPACK${NORMAL}"
#echo -e "${BRIGHT}INSTALLATION PATH : $INSTPATH${NORMAL}"


db2info()
{
echo -e "\n----------------------Features Activated-------------------------------------------------"

HADR=`db2pd -db awdrt -hadr|grep Connected|awk '{print $1}'`

case "$HADR" in
        "Connected" )
        printf "${GREEN}HADR\t${NORMAL}"
        ;;
        *)
        printf "${RED}HADR\t${NORMAL}"
        ;;
esac

ARC=`db2 "get db cfg for awdrt"|grep "Log retain for recovery enabled"|awk '{print $8}'`

case "$ARC" in
        "RECOVERY" )
        printf "${GREEN}ARCHIVAL\t${NORMAL}"
        ;;
        *)
        printf "${RED}ARCHIVAL\t${NORMAL}"
        ;;
esac

a=`grep "Rows selected" snap.out | awk '{print $4}'`
b=`grep "Select SQL statements executed" snap.out |awk '{print $6}'`
c=$[ a/b ]
if [ $c -le 10 ];
then
printf "${GREEN}OLTP\t${NORMAL}"
else
printf "${RED}OLTP\t${NORMAL}"
fi

if [ $c -gt 10 ];
then
printf "${GREEN}DW\t${NORMAL}"
else
printf "${RED}DW\t${NORMAL}"
fi

echo -e "\n-----------------------------------------------------------------------------------------"

}

#db2info

########################Selecting database##########################################################

dblist=`$db2path "list db directory"|grep "Database name"|wc -l`

if [ $dblist != 1 ];
then
echo -e "\nMultiple Databases found \n"
$db2path "list db directory"|grep "Database name"|awk '{print $4}'
printf "\n"
read -p "Select a database : " dbname
else
dbname=`$db2path "list db directory"|grep "Database name"|awk '{print $4}'`
fi


if [ -s snap.out ];
then
echo -e "\nSnapshot file ${YELLOW}snap.out${NORMAL} already exists${NORMAL}"
read -p "Press ${YELLOW}'C'${NORMAL}(Continue) to continue with this file ,${YELLOW}'N'${NORMAL}(New) to take a new snapshot [C/N] : " value


case $value in
	C|c)
	recommendations
	;;
	N|n)
	snapshot
	;;
	*)
	echo -e "Enter C or N , You have entered wrong option"
	echo -e "Exiting .... "
	exit 1
	;;
esac

fi


