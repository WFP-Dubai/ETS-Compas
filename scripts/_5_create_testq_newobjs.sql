set scan on
conn testq_&&1/testq_&&1

prompt dropping trigger T_LGNON_MOD
drop trigger T_LGNON_MOD;

prompt dropping trigger T_LOGNOFF_MOD
drop trigger T_LOGNOFF_MOD;

set scan off
@ets_compas
@ewaybill_objs
@epic_lti
@write_waybill
@epic_geo
set scan on

-- not needed if we are re-creating
prompt creating role EPIC_VIEWONLY (errors are ok if we are refreshing)
create role EPIC_VIEWONLY;

prompt creating role EPIC_ALL (errors are ok if we are refreshing)
create role EPIC_ALL;

set termout off
@GrantAlltoEpic.sql
@GrantSelectToEpic_viewonly.sql
set termout on

prompt creating user TESTW_ (no errors are allowed)
WHENEVER SQLERROR EXIT SQL.SQLCODE
CREATE USER testw_&&1 IDENTIFIED BY testw_&&1 DEFAULT TABLESPACE CTS2_DATA TEMPORARY TABLESPACE TEMPORARY_DATA;
WHENEVER SQLERROR CONTINUE

prompt granting to TESTW_
grant create session, create synonym, epic_viewonly, epic_all to testw_&&1;
alter user testw_&&1 default role epic_viewonly;

prompt looking for invalid objects
col object_name format a30
col object_type format a30
select object_name, object_type from user_objects where status='INVALID';

exit