#!/bin/sh

/home/db2inst2/sqllib/bin/db2 "connect to awdrt"  2>&1

echo -e "connect to awdrt ;" > awdrt_rbnd.db2
/home/db2inst2/sqllib/bin/db2 "SELECT 'REBIND PACKAGE '||RTRIM (SUBSTR (PKGSCHEMA, 1, 10))||'.'||RTRIM (SUBSTR (PKGNAME, 1, 15)) ||' REOPT ONCE ;' as CMD FROM SYSCAT.PACKAGES  WHERE SYSCAT.PACKAGES.VALID NOT IN 'Y' " |grep REBIND | tee -a  awdrt_rbnd.db2
#sed 1i 'connect to awdrt;'  awdrt_rbnd.db2
echo -e "commit work ;\nconnect reset ;" | tee -a awdrt_rbnd.db2
db2 -tvf awdrt_rbnd.db2 > /dev/null 2>&1
#/home/db2inst2/sqllib/bin/db2 "connect reset"   2>&1
