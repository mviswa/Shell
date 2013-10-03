#!/bin/sh

echo -e "connect to db-name ;" > db-name_runs.db2

/home/db2inst2/sqllib/bin/db2 "connect to db-name"  2>&1

/home/db2inst2/sqllib/bin/db2 "SELECT 'RUNSTATS ON TABLE '||LTRIM(RTRIM(TABSCHEMA))||'.'||LTRIM(RTRIM(TABNAME))||' WITH DISTRIBUTION ON ALL COLUMNS AND DETAILED INDEXES ALL ALLOW WRITE ACCESS ;' FROM SYSCAT.TABLES WHERE TYPE NOT IN 'V' AND TABSCHEMA='KSRTC'"|grep RUNSTATS >> db-name_runs.db2   2>&1

## INSERT COMMIT WORK EVERY 2 LINES

#sed 'N;s/.*/&\ncommit work ;/' db-name_runs.db2

echo -e "commit work ;\nconnect reset ;" >> db-name_runs.db2

db2 -tvf db-name_runs.db2
