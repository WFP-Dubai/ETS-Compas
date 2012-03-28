-- sqlplus /nolog @2_create_testq.sql karx001
-- conn system as sysdba
conn sys/compas as sysdba

-- shutdown immediate
shutdown transactional
startup

drop user testw_&&1 cascade;
drop user testq_&&1 cascade;

WHENEVER SQLERROR EXIT SQL.SQLCODE
CREATE USER testq_&&1 IDENTIFIED BY testq_&&1 DEFAULT TABLESPACE CTS2_DATA TEMPORARY TABLESPACE TEMPORARY_DATA;

WHENEVER SQLERROR CONTINUE
GRANT CONNECT, RESOURCE, DBA TO testq_&&1;
grant compaS_all, ADM to testq_&&1 WITH ADMIN OPTION;
GRANT SELECT ON V_$SESSION TO testq_&&1;

set termout off
grant A101E to testq_&&1;
grant A101V to testq_&&1;
grant A102C to testq_&&1;
grant A102E to testq_&&1;
grant A102V to testq_&&1;
grant A105C to testq_&&1;
grant A107V to testq_&&1;
grant A201V to testq_&&1;
grant A203E to testq_&&1;
grant A203V to testq_&&1;
grant A204V to testq_&&1;
grant A301C to testq_&&1;
grant A301E to testq_&&1;
grant A301V to testq_&&1;
grant A302C to testq_&&1;
grant A302E to testq_&&1;
grant A302V to testq_&&1;
grant A303C to testq_&&1;
grant A303E to testq_&&1;
grant A303V to testq_&&1;
grant A304 to testq_&&1;
grant A4011C to testq_&&1;
grant A4011E to testq_&&1;
grant A4011V to testq_&&1;
grant A4012C to testq_&&1;
grant A4012E to testq_&&1;
grant A4012V to testq_&&1;
grant A4013C to testq_&&1;
grant A4013E to testq_&&1;
grant A4013V to testq_&&1;
grant A4014C to testq_&&1;
grant A4014E to testq_&&1;
grant A4014V to testq_&&1;
grant A4015C to testq_&&1;
grant A4015E to testq_&&1;
grant A4015V to testq_&&1;
grant A4018C to testq_&&1;
grant A4021E to testq_&&1;
grant A4021V to testq_&&1;
grant A4022V to testq_&&1;
grant A4023C to testq_&&1;
grant A4023E to testq_&&1;
grant A4023V to testq_&&1;
grant A4031C to testq_&&1;
grant A4031E to testq_&&1;
grant A4031V to testq_&&1;
grant A4033C to testq_&&1;
grant A4033E to testq_&&1;
grant A4033V to testq_&&1;
grant A4040C to testq_&&1;
grant A501C to testq_&&1;
grant A501E to testq_&&1;
grant A501V to testq_&&1;
grant A701 to testq_&&1;
grant A702 to testq_&&1;
grant A703 to testq_&&1;
grant A704 to testq_&&1;
grant A705 to testq_&&1;
grant A706 to testq_&&1;
set termout on

exit

