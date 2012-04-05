prompt
prompt Creating package ETS_COMPAS
prompt ==============================
set scan on
create or replace package ets_compas is

   VERSION constant varchar2(100) := '&&2';
   
   function get_version return varchar2;

end ets_compas;
/
create or replace package body ets_compas is

   function get_version return varchar2 is
		
   begin
		return VERSION;
   end get_version;

end ets_compas;
/
