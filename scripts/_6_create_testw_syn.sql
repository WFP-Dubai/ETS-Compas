set scan on
conn testw_&&1/testw_&&1

set termout off
@synonymforEpic
set termout on

prompt displying user_synonyms that start with EPIC_
col SYNONYM_NAME format a30
col TABLE_OWNER format a30
select SYNONYM_NAME, TABLE_OWNER from user_synonyms where synonym_name like 'EPIC_%';

prompt
prompt Describing view EPIC_GEO
prompt ==============================
desc EPIC_GEO

prompt
prompt Describing view EPIC_LOSSDAMAGEREASON
prompt ==============================
desc EPIC_LOSSDAMAGEREASON

prompt
prompt Describing view EPIC_LTI
prompt ==============================
desc EPIC_LTI

prompt
prompt Describing view EPIC_PERSONS
prompt ==============================
desc EPIC_PERSONS

prompt
prompt Describing view EPIC_STOCK
prompt ==============================
desc EPIC_STOCK

prompt
prompt Describing package write_waybill
prompt ==============================
desc write_waybill

prompt
prompt Describing package ets_compas
prompt ==============================
desc ets_compas


prompt
prompt Getting version number
prompt ==============================
select ets_compas.get_version from dual;
