set scan on
conn testw_&&1/testw_&&1

set termout off
@synonymforEpic
set termout on

col SYNONYM_NAME format a30
col TABLE_OWNER format a30
select SYNONYM_NAME, TABLE_OWNER from user_synonyms where synonym_name like 'EPIC_%';

desc EPIC_GEO
desc EPIC_LOSSDAMAGEREASON
desc EPIC_LTI
desc EPIC_PERSONS
desc EPIC_STOCK
desc write_waybill
