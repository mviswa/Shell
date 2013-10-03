#!/bin/sh

echo -e "connect to awdrt ;" > awdrt_runs.db2

/home/db2inst2/sqllib/bin/db2 "connect to awdrt"  2>&1

/home/db2inst2/sqllib/bin/db2 "SELECT 'RUNSTATS ON TABLE '||LTRIM(RTRIM(TABSCHEMA))||'.'||LTRIM(RTRIM(TABNAME))||' WITH DISTRIBUTION ON ALL COLUMNS AND DETAILED INDEXES ALL ALLOW WRITE ACCESS ;' FROM SYSCAT.TABLES WHERE TYPE NOT IN 'V' AND TABSCHEMA='KSRTC'"|grep RUNSTATS >> awdrt_runs.db2   2>&1

## INSERT COMMIT WORK EVERY 2 LINES

#sed 'N;s/.*/&\ncommit work ;/' awdrt_runs.db2

echo -e "commit work ;\nconnect reset ;" >> awdrt_runs.db2

db2 -tvf awdrt_runs.db2
