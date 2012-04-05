conn testq_&&1/testq_&&1

SET NEWPAGE 0
SET SPACE 0
SET LINESIZE 250
SET PAGESIZE 0
--SET ECHO OFF
SET FEEDBACK OFF
SET HEADING OFF
SET LONG 2000
SET VER OFF

prompt creating trigger T_ORGU_MOD
CREATE OR REPLACE TRIGGER T_ORGU_MOD
 BEFORE
 INSERT OR UPDATE
 ON ORG_UNITS
 REFERENCING OLD AS OLD NEW AS NEW
 FOR EACH ROW
DECLARE
P_CURRENT_SITE ORG_UNITS.CODE%TYPE;
appo number;
a number;
BEGIN
if inserting then
    :new.recv_pack := :new.send_pack;
    :new.send_pack := null;
elsif not updating('offid') and
      not updating('send_pack') and
      not updating('recv_pack') then
--       compas_lib.check_record(:old.offid);
       :new.offid := null;
       :new.send_pack := null;
       :new.recv_pack := null;
       if :old.code != :new.code then
        update org_unit_types set org_unit_code = :new.code
        where org_unit_code = :old.code;
       end if;
 end if;
 if :new.offid is null then
        :new.last_mod_user := USER;
        :new.last_mod_date := sysdate;
    else
     begin
     select 1
       into a
        from site
       where org_unit_code=:new.offid;
        :new.last_mod_user := USER;
        :new.last_mod_date := SYSDATE;
     exception
     when no_data_found then null;
     end;
     END IF;
 if :new.stock_indicator = 'T' and :new.compaS_indicator = 'F' then
     begin
      select 1
        into appo
        from site
        where org_unit_code = :new.reporting_code;
      begin
       insert into site values(:new.code,user,sysdate);
       compas_lib.ins_notify (
              'USR',
               '1',
              :new.reporting_code,
              'New code <'||:new.code||'> is entered in the site table');
      exception
           when dup_val_on_index then
                 null;
      end;
     exception
            when no_data_found then
                 null;
       end;
    end if;
END;
/

commit;

prompt creating trigger T_STATSDDL_DEL
CREATE OR REPLACE TRIGGER T_STATSDDL_DEL
AFTER  DELETE 
ON statsddl
REFERENCING NEW AS NEW OLD AS OLD
FOR EACH ROW
BEGIN
--'COMPASW2 2.1.0'
	IF DELETING THEN
		INSERT INTO K$_statsddl
		VALUES (
			:OLD.RECORD_ID     ,
			:OLD.OFFID         ,
     NULL             ,
			:OLD.RECV_PACK     ,
   USER               ,
  SYSDATE             );
	END IF;
END;
/

commit;



--------------------
--create Objects.sql
--------------------
prompt creating script to compile invalid objects
SPOOL Objects.sql

select 'ALTER '|| DECODE(object_type,'PACKAGE BODY','PACKAGE',object_type) || ' '|| OBJECT_NAME|| ' compile ;' 
FROM USER_OBJECTS
WHERE STATUS NOT LIKE 'VALID'
and object_type not like 'MATE%'
/

select 'ALTER trigger '|| trigger_name || ' enable;' 
FROM USER_TRIGGERS
WHERE STATUS LIKE 'DIS%'
/

spool off;

--------------------
--run Objects.sql
--------------------

spool FIX_OBJ.log
SET NEWPAGE 0
SET SPACE 0
SET LINESIZE 400
SET PAGESIZE 0
SET ECHO ON
SET FEEDBACK OFF
SET HEADING ON
SET LONG 2000
SET VER oN


prompt displaying invalid objects
show user
 
select * from USER_OBJECTS WHERE STATUS NOT LIKE 'VALID'
/

select * from USER_TRIGGERS WHERE STATUS LIKE 'DIS%'
/

prompt compiling invalid objects
start objects.sql

prompt displaying invalid objects again... should be NONE!
SELECT * FROM USER_ERRORS
/

select * from USER_OBJECTS WHERE STATUS NOT LIKE 'VALID'
/

select * from USER_TRIGGERS WHERE STATUS LIKE 'DIS%'
/

SPOOL OFF;

exit
