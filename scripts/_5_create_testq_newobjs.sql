set scan on
conn testq_&&1/testq_&&1

drop trigger t_lgnon_mod;
drop trigger t_lognoff_mod;

set scan off
@ewaybill_objs
@epic_lti
@write_waybill
@epic_geo
set scan on

-- not needed if we are re-creating
create role epic_viewonly;
create role epic_all;

set termout off
@GrantAlltoEpic.sql
@GrantSelectToEpic_viewonly.sql
set termout on

WHENEVER SQLERROR EXIT SQL.SQLCODE
CREATE USER testw_&&1 IDENTIFIED BY testw_&&1 DEFAULT TABLESPACE CTS2_DATA TEMPORARY TABLESPACE TEMPORARY_DATA;
WHENEVER SQLERROR CONTINUE

grant create session, create synonym, epic_viewonly, epic_all to testw_&&1;
alter user testw_&&1 default role epic_viewonly;

col object_name format a30
col object_type format a30
select object_name, object_type from user_objects where status='INVALID';

exit