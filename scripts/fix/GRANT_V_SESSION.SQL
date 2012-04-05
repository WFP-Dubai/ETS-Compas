prompt connecting as sys
sys/COMPAS as sysdba

prompt granting select on sessions
set termout on
SET SQLCASE  UPPER
SET ECHO ON
set pagesize 200
set linesize 100

SPOOL GRANT_V_SESSION.log

SHOW USER

GRANT SELECT ON V_$SESSION TO testq_&&1;

GRANT SELECT ON V_$SESSION TO LOGtestq_&&1;

commit;


SPOOL OFF
exit;
