prompt
prompt Creating package WRITE_WAYBILL
prompt ==============================
prompt
create or replace package write_waybill is

   -- Author  : MARCO.VITTORINI
   -- Created : 02/06/2010 05:36:45 PM
   -- Purpose : 

   -- Author  : DANIELA.TALONE
   -- Modified : 25/10/2010
   -- Purpose : 

   dspmst_rec dispatch_masters%rowtype;
   dspdtl_rec dispatch_details%rowtype;
   dspfrmitm_rec dispatch_form_items%rowtype;

   p_return_message varchar2(2000);
   p_return_flag varchar2(1);
   p_loan loan_masters.loan_code%type;

   function get_transport_mode_code(p_text in varchar2 default null)
      return varchar2;

   function get_item_record_id(p_label in varchar2) return varchar2;

   procedure dispatch
   (
      p_return_message in out varchar2,
      p_return_flag in out varchar2,
      p_wbcode in varchar2 default null,
      p_dispatchdt in varchar2 default null,
      p_origintype in varchar2 default null,
      p_originloc in varchar2 default null,
      p_origincode in varchar2 default null,
      p_origindescr in varchar2 default null,
      p_destinloc in varchar2 default null,
      p_destincode in varchar2 default null,
      p_lti_id in varchar2 default null,
      p_loadingdt in varchar2 default null,
      p_consegnee_id in varchar2 default null,
      p_tt in varchar2 default null,
      p_vehiclereg in varchar2 default null,
      p_trailer_plate in varchar2 default null,
      p_tranmode in varchar2 default null,
      p_dspremarks in varchar2 default null,
      p_person_code in varchar2 default null,
      p_person_ouc in varchar2 default null,
      p_persontitle in varchar2 default null,
      p_transport_code in varchar2 default null,
      p_transport_ouc in varchar2 default null,
      p_drivername in varchar2 default null,
      p_driverlicence in varchar2 default null,
      p_container in varchar2 default null,
      p_compassite in varchar2 default null,
      p_coi in varchar2 default null,
      p_cmmcat in varchar2 default null,
      p_cmmcode in varchar2 default null,
      p_pckcode in varchar2 default null,
      p_alloccode in varchar2 default null,
      p_quality in varchar2 default null,
      p_net in varchar2 default null,
      p_gross in varchar2 default null,
      p_units in varchar2 default null,
      p_unit_net in varchar2 default null,
      p_unit_gross in varchar2 default null,
      p_odaid in varchar2 default null,
      p_losstype in varchar2 default null, --> new
      p_lossreason in varchar2 default null, --> NEW
      p_loannumber in varchar2 --> new 
   );

   procedure receipt
   (
      p_return_message in out varchar2,
      p_return_flag in out varchar2,
      p_wbcode in varchar2 default null,
      p_person_ouc in varchar2 default null,
      p_person_code in varchar2 default null,
      p_arrivaldt in varchar2 default null,
      p_goodunits in varchar2 default null,
      p_damagereason in varchar2 default null,
      p_damageunits in varchar2 default null,
      p_lossreason in varchar2 default null,
      p_lossunits in varchar2 default null,
      p_coi in varchar2 default null,
      p_cmmcat in varchar2 default null,
      p_cmmcode in varchar2 default null,
      p_pckcode in varchar2 default null,
      p_alloccode in varchar2 default null,
      p_quality in varchar2 default null
   );

   function validatedispacth return varchar2;

   procedure write_dspmst;
   procedure write_dspdtl;
   procedure write_dspfrmitm;

end write_waybill;
/

prompt
prompt Creating package body WRITE_WAYBILL
prompt ==============================
prompt
create or replace package body write_waybill is

   -- v_format_date
   vfd constant varchar2(8) := 'YYYYMMDD';

   /*LOAN DETAILS*/
   function get_dsploanid
   (
      p_loan in varchar2,
      p_coi in varchar2,
      p_cmmcat in varchar2,
      p_cmm in varchar2,
      p_type in varchar2
   ) return boolean is
   
   begin
   
      select londtl.lonmst_id,
             londtl.londtl_id
      into dspdtl_rec.lonmst_id,
           dspdtl_rec.londtl_id
      from loan_masters lonmst,
           loan_details londtl,
           coi_to_sis coisis,
           stored_commodities stdcmm
      where lonmst.lonmst_id = londtl.lonmst_id and
            londtl.delete_user_id is null and
            lonmst.loan_code = p_loan and
            londtl.si_record_id = coisis.si_record_id and
            coisis.origin_id = stdcmm.origin_id and
            stdcmm.origin_id = p_coi and
            stdcmm.comm_category_code = p_cmmcat and
            stdcmm.commodity_code = p_cmm;
      return true;
   
   exception
      when too_many_rows then
         raise_application_error(-20001,
                                 'Too many rows for the loan number: ' ||
                                 p_loan);
      when no_data_found then
         return false;
   end;

   /*LOAN DETAILS*/
   function get_dsprepayid
   (
      p_loan in varchar2,
      p_coi in varchar2,
      p_cmmcat in varchar2,
      p_cmm in varchar2,
      p_type in varchar2
   ) return boolean is
   
   begin
   
      select distinct londtl.lonmst_id,
                      londtl.londtl_id,
                      londtl.rpydtl_id
      into dspdtl_rec.lonmst_id,
           dspdtl_rec.londtl_id,
           dspdtl_rec.rpydtl_id
      from loan_masters lonmst,
           repay_details londtl,
           coi_to_sis coisis,
           stored_commodities stdcmm
      where lonmst.lonmst_id = londtl.lonmst_id and
            londtl.delete_user_id is null and
            lonmst.loan_code = p_loan and
            londtl.si_record_id = coisis.si_record_id and
            coisis.origin_id = stdcmm.origin_id and
            stdcmm.origin_id = p_coi and
            stdcmm.comm_category_code = p_cmmcat and
            stdcmm.commodity_code = p_cmm;
      return true;
   exception
      when too_many_rows then
         raise_application_error(-20001,
                                 'Too many rows for the loan number: ' ||
                                 p_loan);
      when no_data_found then
         return false;
   end;

   /*GET_TRANSPORT_MODE_CODE*/
   function get_transport_mode_code(p_text in varchar2 default null)
      return varchar2 is
   
      transport_mode_code transport_modes.code%type;
   
   begin
      select a.code
      into transport_mode_code
      from transport_modes a
      where a.code = p_text;
   
      return transport_mode_code;
   
   exception
      when no_data_found then
         raise_application_error(-20001,
                                 'Cannot find transport_modes code for description: ' ||
                                 p_text);
   end;

   /*GET_ITEM_RECORD_ID*/
   function get_item_record_id(p_label in varchar2) return varchar2 is
   
      customized_form_items_rec_id customized_form_items.record_id%type;
      v_current_site org_units.code%type := compas_lib.get_current_site;
   
   begin
      select record_id
      into customized_form_items_rec_id
      from customized_form_items
      where org_unit_code = v_current_site and
            upper(item_label) = p_label;
   
      return customized_form_items_rec_id;
   
   exception
      when no_data_found then
         raise_application_error(-20001,
                                 'Cannot find record_id in customized_form_items for current_site: ' ||
                                 v_current_site);
   end;

   /*GET_MESSAGE*/
   function get_message(p_message_number in number) return varchar2 is
      r_compas_messages compas_messages%rowtype;
   begin
      select *
      into r_compas_messages
      from compas_messages a
      where a.message_type = 'EW' and
            a.message_number = p_message_number;
   
      return r_compas_messages.message_text;
   
   exception
      when others then
         return 'ERROR_CODE: ' || p_message_number;
   end;

   /*GET_GEOPOINT*/
   function get_geopoint(p_geo_point_code in varchar2)
      return geo_points%rowtype is
   
      r geo_points%rowtype;
   
   begin
      select *
      into r
      from geo_points a
      where a.code = p_geo_point_code;
   
      return r;
   
   exception
      when no_data_found then
         return null;
   end;

   /*CHECK_ORG_UNIT*/
   function check_org_unit(p_origincode in varchar2) return boolean is
      v_dummy org_units%rowtype;
   begin
      select *
      into v_dummy
      from org_units a
      where a.code = p_origincode;
   
      return true;
   
   exception
      when no_data_found then
         return false;
   end;

   /*CHECK_ORG_UNIT*/
   function check_rcploancoi
   (
      p_loanid in varchar2,
      p_londtlid in varchar2,
      p_coi in varchar2,
      p_cat in varchar2
   ) return boolean is
      a number;
   begin
      select 1
      into a
      from loan_details londtl
      where londtl.lonmst_id = p_loanid and
            londtl.londtl_id = p_londtlid and
            receiving_origin_id = p_coi and
            comm_category_code = p_cat;
      return true;
   
   exception
      when no_data_found then
         return false;
   end;

   function check_rcprepaycoi
   (
      p_loanid in varchar2,
      p_londtlid in varchar2,
      p_coi in varchar2,
      p_cat in varchar2
   ) return boolean is
      a number;
   begin
      select 1
      into a
      from loan_details londtl
      where londtl.lonmst_id = p_loanid and
            londtl.londtl_id = p_londtlid and
            repaying_origin_id = p_coi and
            comm_category_code = p_cat;
      return true;
   
   exception
      when no_data_found then
         return false;
   end;

   /*GET_LTI_MASTERS*/
   function get_lti_masters(p_lti_id in varchar2) return lti_masters%rowtype is
      r lti_masters%rowtype;
   begin
      select *
      into r
      from lti_masters a
      where a.lti_id = p_lti_id;
   
      return r;
   
   exception
      when no_data_found then
         return null;
   end;

   /*GET_PERSON*/
   function get_person
   (
      p_person_code in varchar2,
      p_person_ouc in varchar2
   ) return persons%rowtype is
      r persons%rowtype;
   begin
      select *
      into r
      from persons a
      where a.org_unit_code = p_person_ouc and
            a.code = p_person_code;
   
      return r;
   
   exception
      when no_data_found then
         return null;
   end;

   /*DISPATCH*/
   procedure dispatch
   (
      p_return_message in out varchar2,
      p_return_flag in out varchar2,
      p_wbcode in varchar2 default null,
      p_dispatchdt in varchar2 default null,
      p_origintype in varchar2 default null,
      p_originloc in varchar2 default null,
      p_origincode in varchar2 default null,
      p_origindescr in varchar2 default null,
      p_destinloc in varchar2 default null,
      p_destincode in varchar2 default null,
      p_lti_id in varchar2 default null,
      p_loadingdt in varchar2 default null,
      p_consegnee_id in varchar2 default null,
      p_tt in varchar2 default null,
      p_vehiclereg in varchar2 default null,
      p_trailer_plate in varchar2 default null,
      p_tranmode in varchar2 default null,
      p_dspremarks in varchar2 default null,
      p_person_code in varchar2 default null,
      p_person_ouc in varchar2 default null,
      p_persontitle in varchar2 default null,
      p_transport_code in varchar2 default null,
      p_transport_ouc in varchar2 default null,
      p_drivername in varchar2 default null,
      p_driverlicence in varchar2 default null,
      p_container in varchar2 default null,
      p_compassite in varchar2 default null,
      p_coi in varchar2 default null,
      p_cmmcat in varchar2 default null,
      p_cmmcode in varchar2 default null,
      p_pckcode in varchar2 default null,
      p_alloccode in varchar2 default null,
      p_quality in varchar2 default null,
      p_net in varchar2 default null,
      p_gross in varchar2 default null,
      p_units in varchar2 default null,
      p_unit_net in varchar2 default null,
      p_unit_gross in varchar2 default null,
      p_odaid in varchar2 default null,
      p_losstype in varchar2 default null, --> new
      p_lossreason in varchar2 default null, --> NEW
      p_loannumber in varchar2 --> new 
   ) is
   
      v_wfpstock_type org_unit_class.wfpstock_type%type;
   
   begin
   
      p_return_message := null;
      p_return_flag := null;
      dbms_output.put_line(0);
      --> master    
      dspmst_rec.code := p_wbcode;
      dspmst_rec.document_code := 'WB';
      dspmst_rec.dispatch_date := to_date(p_dispatchdt, vfd);
      dspmst_rec.origin_type := p_origintype;
      dspmst_rec.origin_location_code := p_originloc;
      dspmst_rec.intvyg_code := null;
      dspmst_rec.intdlv_code := null;
      dspmst_rec.origin_code := p_origincode;
      dspmst_rec.origin_descr := p_origindescr;
      dspmst_rec.destination_location_code := p_destinloc;
      dspmst_rec.destination_code := p_destincode;
      dspmst_rec.pro_activity_code := null;
      dspmst_rec.activity_ouc := null;
      dspmst_rec.lndarrm_code := null;
      dspmst_rec.lti_id := p_lti_id;
      dspmst_rec.loan_id := null;
      dspmst_rec.loading_date := to_date(p_loadingdt, vfd);
      dspmst_rec.organization_id := p_consegnee_id;
      dspmst_rec.tran_type_code := p_tt;
      dspmst_rec.tran_type_descr := null;
      dspmst_rec.modetrans_code := get_transport_mode_code(p_tranmode);
      dspmst_rec.comments := p_dspremarks;
      dspmst_rec.person_code := p_person_code;
      dspmst_rec.person_ouc := p_person_ouc;
      dspmst_rec.certifing_title := p_persontitle;
      dspmst_rec.trans_contractor_code := p_transport_code;
      dspmst_rec.supplier1_ouc := p_transport_ouc;
      dspmst_rec.trans_subcontractor_code := null;
      dspmst_rec.supplier2_ouc := null;
      dspmst_rec.nmbplt_id := null;
      dspmst_rec.nmbtrl_id := null;
      dspmst_rec.driver_name := p_drivername;
      dspmst_rec.license := p_driverlicence;
      dspmst_rec.vehicle_registration := p_vehiclereg;
      dspmst_rec.trailer_plate := p_trailer_plate;
      dspmst_rec.container_number := p_container;
      dspmst_rec.atl_li_code := null;
      dspmst_rec.notify_indicator := 'T';
      dspmst_rec.customised := null;
      dspmst_rec.org_unit_code := compas_lib.get_current_site;
      dspmst_rec.printed_indicator := null;
      dspmst_rec.notify_org_unit_code := p_compassite;
      dspmst_rec.offid := null;
      dspmst_rec.send_pack := null;
      dspmst_rec.recv_pack := null;
      dspmst_rec.last_mod_user := null;
      dspmst_rec.last_mod_date := null;
   
      --> details
      dspdtl_rec.code := p_wbcode;
      dspdtl_rec.document_code := 'WB';
      dspdtl_rec.si_record_id := null;
      dspdtl_rec.origin_id := p_coi;
      dspdtl_rec.comm_category_code := p_cmmcat;
      dspdtl_rec.commodity_code := p_cmmcode;
      dspdtl_rec.package_code := p_pckcode;
      dspdtl_rec.allocation_destination_code := p_alloccode;
      dspdtl_rec.quality := p_quality;
      dspdtl_rec.quantity_net := p_net;
      dspdtl_rec.quantity_gross := p_gross;
      dspdtl_rec.number_of_units := p_units;
      dspdtl_rec.unit_weight_net := p_unit_net;
      dspdtl_rec.unit_weight_gross := p_unit_gross;
      dspdtl_rec.lonmst_id := null;
      dspdtl_rec.londtl_id := null;
      dspdtl_rec.rpydtl_id := null;
      dspdtl_rec.offid := null;
      dspdtl_rec.send_pack := null;
      dspdtl_rec.recv_pack := null;
      dspdtl_rec.last_mod_user := null;
      dspdtl_rec.last_mod_date := null;
   
      if dspmst_rec.tran_type_code in ('LOAN', 'REP', 'SWA1', 'SWA2') then
         p_loan := p_loannumber;
      end if;
   
      p_return_message := validatedispacth;
   
      -- Transaction Type Validation Start
      begin
         select a.wfpstock_type
         into v_wfpstock_type
         from org_unit_class a
         where a.org_unit_code = p_origincode;
      exception
         when no_data_found then
            raise_application_error(-20001, 'Invalid p_origincode');
      end;
   
      if not w2_waybill.dispatch(p_tran_type_code => p_tt, -- IN varchar2, -- ? dispatch.p_tt 
                                 p_origin_type => p_origintype, -- IN varchar2, -- ? dispatch.p_origintype
                                 p_wfpstock_type => v_wfpstock_type, -- IN varchar2, -- ? to be calculated
                                 p_organization_id => p_consegnee_id, -- IN varchar2, -- ? p_consegnee_id
                                 p_ttdescr => null -- IN varchar2) -- ? it not current managed by write_waybill ?  it is only for DISPOSAL 
                                 ) then
         raise_application_error(-20001, 'Invalid transaction type');
      end if;
      -- Transaction Type Validation End
   
      if p_return_message is not null then
         raise_application_error(-20001, p_return_message);
      end if;
   
      write_dspmst;
   
      write_dspdtl;
   
      if p_odaid is not null then
         dspfrmitm_rec.item_record_id := get_item_record_id('ODA Id');
         dspfrmitm_rec.item_value := p_odaid;
         dspfrmitm_rec.dispatch_code := dspmst_rec.code;
         dspfrmitm_rec.document_code := dspmst_rec.document_code;
         write_dspfrmitm;
      end if;
   
      if p_losstype is not null then
         dspfrmitm_rec.item_record_id := get_item_record_id('LOSS TYPE (PRE OR POST)');
         dspfrmitm_rec.item_value := p_losstype;
         dspfrmitm_rec.dispatch_code := dspmst_rec.code;
         dspfrmitm_rec.document_code := dspmst_rec.document_code;
         write_dspfrmitm;
      end if;
   
      if p_lossreason is not null then
         dspfrmitm_rec.item_record_id := get_item_record_id('LOSS CAUSE');
         dspfrmitm_rec.item_value := p_lossreason;
         dspfrmitm_rec.dispatch_code := dspmst_rec.code;
         dspfrmitm_rec.document_code := dspmst_rec.document_code;
         write_dspfrmitm;
      end if;
   
      commit;
   
      p_return_flag := 'S';
      p_return_message := null;
   
      /* exception
      when others then
      
        p_return_flag := 'E';
      
        if p_return_message is null then
           p_return_message := sqlerrm;
        end if;
      
        rollback;*/
   end dispatch;

   /*RECEIPT*/
   procedure receipt
   (
      p_return_message in out varchar2,
      p_return_flag in out varchar2,
      p_wbcode in varchar2 default null,
      p_person_ouc in varchar2 default null,
      p_person_code in varchar2 default null,
      p_arrivaldt in varchar2 default null,
      p_goodunits in varchar2 default null,
      p_damagereason in varchar2 default null,
      p_damageunits in varchar2 default null,
      p_lossreason in varchar2 default null,
      p_lossunits in varchar2 default null,
      p_coi in varchar2 default null,
      p_cmmcat in varchar2 default null,
      p_cmmcode in varchar2 default null,
      p_pckcode in varchar2 default null,
      p_alloccode in varchar2 default null,
      p_quality in varchar2 default null
   ) is
   
      r_receipt_masters receipt_masters%rowtype;
      v_wfpstock_typedis org_unit_class.wfpstock_type%type;
      v_wfpstock_typerec org_unit_class.wfpstock_type%type;
      r_dispatch_masters dispatch_masters%rowtype;
      r_dispatch_details dispatch_details%rowtype;
      v_damage_code loss_damage_causes.name_record_id%type;
      v_damage_cause_id loss_damage_causes.record_id%type;
      r_trans_losses trans_losses%rowtype;
      v_loss_code loss_damage_causes.name_record_id%type;
      v_loss_cause_id loss_damage_causes.record_id%type;
   
      p_net number;
      p_gross number;
      p_units number;
   
   begin
   
      p_return_message := null;
      p_return_flag := null;
   
      p_net := null;
      p_gross := null;
      p_units := null;
   
      /*
      CODE  JERX001100B99911P
      DOCUMENT_CODE WB
      */
   
      r_receipt_masters.document_code := 'WB';
      r_receipt_masters.code := compas_lib.get_current_site || p_wbcode || 'P';
      -- compas_lib.get_current_site || lpad(p_wbcode, 9, '0') || 'P';
      r_receipt_masters.org_unit_code := compas_lib.get_current_site;
   
      begin
         select *
         into r_dispatch_masters
         from dispatch_masters a
         where a.code = r_receipt_masters.code and
               a.document_code = r_receipt_masters.document_code;
      exception
         when no_data_found then
            raise_application_error(-20001,
                                    'Cannot find dispatch_masters with P_WBCODE: ' ||
                                    p_wbcode);
      end;
   
      -- Transaction Type Validation Start
      begin
         select a.wfpstock_type
         into v_wfpstock_typedis
         from org_unit_class a
         where a.org_unit_code = r_dispatch_masters.origin_code;
      exception
         when no_data_found then
            raise_application_error(-20001, 'Invalid origin_code');
      end;
   
      begin
         select a.wfpstock_type
         into v_wfpstock_typerec
         from org_unit_class a
         where a.org_unit_code = r_dispatch_masters.destination_code;
      exception
         when no_data_found then
            raise_application_error(-20001, 'Invalid destination_code');
      end;
   
      if not w2_waybill.receipt(p_tran_type_code => r_dispatch_masters.tran_type_code, -- IN varchar2,  -- ? p_tt
                                p_origin_type => r_dispatch_masters.origin_type, -- IN varchar2,  -- p_origintype
                                p_wfpstock_typedis => v_wfpstock_typedis, -- IN varchar2,  -- ? to be calculated from org_unit_class.WFPSTOCK_TYPE (origin code)
                                p_wfpstock_typerec => v_wfpstock_typerec, -- IN varchar2,  -- ? to be calculated from org_unit_class.WFPSTOCK_TYPE (receving code) -- destination code della dis mast
                                p_organization_id => r_dispatch_masters.organization_id, -- IN varchar2,  -- ? p_consignee_id
                                p_ttdescr => null -- IN varchar2   -- ? NULL -> it's not currently managed by write_waybill, but it's only for DISPOSAL (not needed)
                                ) then
         raise_application_error(-20001, 'Invalid transaction type');
      end if;
      -- Transaction Type Validation End
   
      if r_dispatch_masters.tran_type_code in
         ('LOAN', 'REP', 'SWA1', 'SWA2') then
         begin
            select *
            into r_dispatch_details
            from dispatch_details a
            where a.code = r_receipt_masters.code and
                  a.document_code = r_receipt_masters.document_code;
         exception
            when too_many_rows then
               raise_application_error(-20001,
                                       'Dispatch details with more than one line P_WBCODE: ' ||
                                       p_wbcode);
            when no_data_found then
               raise_application_error(-20001,
                                       'Cannot find dispatch_details with P_WBCODE: ' ||
                                       p_wbcode);
         end;
         if r_dispatch_masters.tran_type_code in ('LOAN', 'SWA1') then
            if not check_rcploancoi(r_dispatch_details.lonmst_id,
                                    r_dispatch_details.londtl_id,
                                    p_coi,
                                    p_cmmcat) then
               raise_application_error(-20001,
                                       'Invalid LOAN receipt commodity details with P_WBCODE: ' ||
                                       p_wbcode);
            end if;
         elsif r_dispatch_masters.tran_type_code in ('REP', 'SWA2') then
            if not check_rcprepaycoi(r_dispatch_details.lonmst_id,
                                     r_dispatch_details.londtl_id,
                                     p_coi,
                                     p_cmmcat) then
               raise_application_error(-20001,
                                       'Invalid REPAY receipt commodity details with P_WBCODE: ' ||
                                       p_wbcode);
            end if;
         end if;
      
      else
         begin
            select *
            into r_dispatch_details
            from dispatch_details a
            where a.code = r_receipt_masters.code and
                  a.document_code = r_receipt_masters.document_code and
                  a.origin_id = p_coi and
                  a.comm_category_code = p_cmmcat and
                  a.commodity_code = p_cmmcode and
                  a.package_code = p_pckcode and
                  a.allocation_destination_code = p_alloccode and
                  a.quality = p_quality;
         exception
            when no_data_found then
               raise_application_error(-20001,
                                       'Cannot find dispatch_details with P_WBCODE: ' ||
                                       p_wbcode);
         end;
      end if;
      if p_damagereason is not null then
         begin
            select loss_damage_causes.name_record_id damage_code,
                   loss_damage_causes.record_id damage_cause_id
            into v_damage_code,
                 v_damage_cause_id
            from loss_damage_causes,
                 loss_damage_names b
            where loss_damage_causes.name_record_id = b.record_id and
                  b.type = 'D' and
                  comm_category_code =
                  r_dispatch_details.comm_category_code and
                  cause = p_damagereason and
                  rownum = 1;
         exception
            when no_data_found then
               p_return_message := get_message(10);
               raise_application_error(-20001, p_return_message);
               --          raise_application_error(-20001,
            --                                'Cannot find loss_damage_* with P_DAMAGEREASON: ' ||
            --                              p_damagereason);
         end;
      end if;
   
      if p_lossreason is not null then
         begin
            select loss_code,
                   loss_cause_id
            into v_loss_code,
                 v_loss_cause_id
            from (select loss_damage_causes.name_record_id loss_code,
                         loss_damage_causes.record_id loss_cause_id
                  from loss_damage_causes,
                       loss_damage_names b
                  where loss_damage_causes.name_record_id = b.record_id and
                        b.type = 'L' and
                        comm_category_code =
                        r_dispatch_details.comm_category_code and
                        cause = p_lossreason
                  --  AND ROWNUM=1
                  order by to_number(loss_damage_causes.record_id))
            where rownum = 1;
         exception
            when no_data_found then
               p_return_message := get_message(9);
               --          raise_application_error(-20001,
            --                                'Cannot find loss_damage_* with P_LOSSREASON: ' ||
            --                              p_lossreason);
         
         end;
      end if;
   
      /*RECEIPT_MASTERS*/
      begin
         insert into receipt_masters
            (code, --  VARCHAR2(25)  
             document_code, -- VARCHAR2(2) 
             org_unit_code, -- VARCHAR2(13)  
             extra_code, --  VARCHAR2(25)  Y
             receipt_location_code, -- VARCHAR2(10)  
             receipt_code, --  VARCHAR2(13)  
             person_ouc_rec, --  VARCHAR2(13)  
             person_code_rec, -- VARCHAR2(7) 
             tran_type_code_rec, --  VARCHAR2(4) 
             tran_type_descr_rec, -- VARCHAR2(50)  Y
             arrival_date, --  DATE  
             start_discharge_date, --  DATE  
             end_discharge_date, --  DATE  
             distance_traveled, -- NUMBER(7,3) Y
             comments_rec, --  VARCHAR2(250) Y
             lti_id, --  VARCHAR2(25)  Y
             origin_location_code, --  VARCHAR2(10)  
             origin_type, -- VARCHAR2(1) 
             intvyg_code, -- VARCHAR2(25)  Y
             intdlv_code, -- NUMBER(2) Y
             origin_code, -- VARCHAR2(13)  Y
             origin_descr, --  VARCHAR2(50)  Y
             destination_location_code, -- VARCHAR2(10)  
             destination_code, --  VARCHAR2(13)  Y
             pro_activity_code, -- VARCHAR2(6) Y
             activity_ouc, --  VARCHAR2(13)  Y
             dispatch_date, -- DATE  
             loading_date, --  DATE  
             organization_id, -- VARCHAR2(12)  
             tran_type_code, --  VARCHAR2(4) 
             tran_type_descr, -- VARCHAR2(50)  Y
             lndarrm_code, --  VARCHAR2(25)  Y
             modetrans_code, --  VARCHAR2(2) 
             person_code, -- VARCHAR2(7) 
             person_ouc, --  VARCHAR2(13)  
             certifing_title, -- VARCHAR2(50)  Y
             trans_contractor_code, -- VARCHAR2(4) 
             supplier1_ouc, -- VARCHAR2(13)  
             trans_subcontractor_code, --  VARCHAR2(4) Y
             supplier2_ouc, -- VARCHAR2(13)  Y
             nmbplt_id, -- VARCHAR2(25)  Y
             nmbtrl_id, -- VARCHAR2(25)  Y
             atl_li_code, -- VARCHAR2(8) Y
             driver_name, -- VARCHAR2(50)  Y
             vehicle_registration, --  VARCHAR2(20)  Y
             license, -- VARCHAR2(20)  Y
             trailer_plate, -- VARCHAR2(20)  Y
             container_number, --  VARCHAR2(15)  Y
             customised, --  VARCHAR2(50)  Y
             offid, -- VARCHAR2(13)  Y
             send_pack, -- NUMBER(20)  Y
             recv_pack, -- NUMBER(20)  Y
             last_mod_user, -- VARCHAR2(30)  Y
             last_mod_date --  DATE  Y
             )
         values
            (r_receipt_masters.code, -- CODE, -- VARCHAR2(25)  
             r_receipt_masters.document_code, -- DOCUMENT_CODE, --  VARCHAR2(2) 
             r_receipt_masters.org_unit_code, -- ORG_UNIT_CODE, --  VARCHAR2(13)  
             null, -- EXTRA_CODE, -- VARCHAR2(25)  Y
             r_dispatch_masters.destination_location_code, -- RECEIPT_LOCATION_CODE, --  VARCHAR2(10)  
             r_dispatch_masters.destination_code, -- RECEIPT_CODE, -- VARCHAR2(13)  
             p_person_ouc, -- PERSON_OUC_REC, -- VARCHAR2(13)  
             p_person_code, -- PERSON_CODE_REC, --  VARCHAR2(7) 
             r_dispatch_masters.tran_type_code, -- TRAN_TYPE_CODE_REC, -- VARCHAR2(4) 
             r_dispatch_masters.tran_type_descr, -- TRAN_TYPE_DESCR_REC, --  VARCHAR2(50)  Y
             to_date(p_arrivaldt, vfd), -- ARRIVAL_DATE, -- DATE  
             to_date(p_arrivaldt, vfd), -- START_DISCHARGE_DATE, -- DATE  
             to_date(p_arrivaldt, vfd), -- END_DISCHARGE_DATE, -- DATE  
             null, -- DISTANCE_TRAVELED, --  NUMBER(7,3) Y
             null, -- COMMENTS_REC, -- VARCHAR2(250) Y
             r_dispatch_masters.lti_id, -- LTI_ID, -- VARCHAR2(25)  Y
             r_dispatch_masters.origin_location_code, -- ORIGIN_LOCATION_CODE, -- VARCHAR2(10)  
             r_dispatch_masters.origin_type, -- ORIGIN_TYPE, --  VARCHAR2(1) 
             r_dispatch_masters.intvyg_code, -- INTVYG_CODE, --  VARCHAR2(25)  Y
             r_dispatch_masters.intdlv_code, -- INTDLV_CODE, --  NUMBER(2) Y
             r_dispatch_masters.origin_code, -- ORIGIN_CODE, --  VARCHAR2(13)  Y
             r_dispatch_masters.origin_descr, -- ORIGIN_DESCR, -- VARCHAR2(50)  Y
             r_dispatch_masters.destination_location_code, -- DESTINATION_LOCATION_CODE, --  VARCHAR2(10)  
             r_dispatch_masters.destination_code, -- DESTINATION_CODE, -- VARCHAR2(13)  Y
             null, -- PRO_ACTIVITY_CODE, --  VARCHAR2(6) Y
             null, -- ACTIVITY_OUC, -- VARCHAR2(13)  Y
             r_dispatch_masters.dispatch_date, -- DISPATCH_DATE, --  DATE  
             r_dispatch_masters.loading_date, -- LOADING_DATE, -- DATE  
             r_dispatch_masters.organization_id, -- ORGANIZATION_ID, --  VARCHAR2(12)  
             r_dispatch_masters.tran_type_code, -- TRAN_TYPE_CODE, -- VARCHAR2(4) 
             r_dispatch_masters.tran_type_descr, -- TRAN_TYPE_DESCR, --  VARCHAR2(50)  Y
             null, -- LNDARRM_CODE, -- VARCHAR2(25)  Y
             r_dispatch_masters.modetrans_code, -- MODETRANS_CODE, -- VARCHAR2(2) 
             r_dispatch_masters.person_code, -- PERSON_CODE, --  VARCHAR2(7) 
             r_dispatch_masters.person_ouc, -- PERSON_OUC, -- VARCHAR2(13)  
             r_dispatch_masters.certifing_title, -- CERTIFING_TITLE, --  VARCHAR2(50)  Y
             r_dispatch_masters.trans_contractor_code, -- TRANS_CONTRACTOR_CODE, --  VARCHAR2(4) 
             r_dispatch_masters.supplier1_ouc, -- SUPPLIER1_OUC, --  VARCHAR2(13)  
             r_dispatch_masters.trans_subcontractor_code, -- TRANS_SUBCONTRACTOR_CODE, -- VARCHAR2(4) Y
             r_dispatch_masters.supplier2_ouc, -- SUPPLIER2_OUC, --  VARCHAR2(13)  Y
             null, -- NMBPLT_ID, --  VARCHAR2(25)  Y
             null, -- NMBTRL_ID, --  VARCHAR2(25)  Y
             null, -- ATL_LI_CODE, --  VARCHAR2(8) Y
             r_dispatch_masters.driver_name, -- DRIVER_NAME, --  VARCHAR2(50)  Y
             r_dispatch_masters.vehicle_registration, -- VEHICLE_REGISTRATION, -- VARCHAR2(20)  Y
             r_dispatch_masters.license, -- LICENSE, --  VARCHAR2(20)  Y
             r_dispatch_masters.trailer_plate, -- TRAILER_PLATE, --  VARCHAR2(20)  Y
             r_dispatch_masters.container_number, -- CONTAINER_NUMBER, -- VARCHAR2(15)  Y
             null, -- CUSTOMISED, -- VARCHAR2(50)  Y
             null, -- OFFID, --  VARCHAR2(13)  Y
             null, -- SEND_PACK, --  NUMBER(20)  Y
             null, -- RECV_PACK, --  NUMBER(20)  Y
             null, -- LAST_MOD_USER, --  VARCHAR2(30)  Y
             null -- LAST_MOD_DATE -- DATE  Y
             );
      exception
         when dup_val_on_index then
            update receipt_masters
            set code = r_receipt_masters.code, --    VARCHAR2(25)  
                document_code = r_receipt_masters.document_code, --     VARCHAR2(2) 
                org_unit_code = r_receipt_masters.org_unit_code, --     VARCHAR2(13)  
                receipt_location_code = r_dispatch_masters.destination_location_code, --    VARCHAR2(10)  
                receipt_code = r_dispatch_masters.destination_code, --   VARCHAR2(13)  
                person_ouc_rec = p_person_ouc, --    VARCHAR2(13)  
                person_code_rec = p_person_code, --     VARCHAR2(7) 
                tran_type_code_rec = r_dispatch_masters.tran_type_code, --   VARCHAR2(4) 
                tran_type_descr_rec = r_dispatch_masters.tran_type_descr, --    VARCHAR2(50)  Y
                arrival_date = to_date(p_arrivaldt, vfd), --   DATE  
                start_discharge_date = to_date(p_arrivaldt, vfd), --   DATE  
                end_discharge_date = to_date(p_arrivaldt, vfd), --   DATE  
                lti_id = r_dispatch_masters.lti_id, --   VARCHAR2(25)  Y
                origin_location_code = r_dispatch_masters.origin_location_code, --   VARCHAR2(10)  
                origin_type = r_dispatch_masters.origin_type, --    VARCHAR2(1) 
                intvyg_code = r_dispatch_masters.intvyg_code, --    VARCHAR2(25)  Y
                intdlv_code = r_dispatch_masters.intdlv_code, --    NUMBER(2) Y
                origin_code = r_dispatch_masters.origin_code, --    VARCHAR2(13)  Y
                origin_descr = r_dispatch_masters.origin_descr, --   VARCHAR2(50)  Y
                destination_location_code = r_dispatch_masters.destination_location_code, --    VARCHAR2(10)  
                destination_code = r_dispatch_masters.destination_code, --   VARCHAR2(13)  Y
                dispatch_date = r_dispatch_masters.dispatch_date, --    DATE  
                loading_date = r_dispatch_masters.loading_date, --   DATE  
                organization_id = r_dispatch_masters.organization_id, --    VARCHAR2(12)  
                tran_type_code = r_dispatch_masters.tran_type_code, --   VARCHAR2(4) 
                tran_type_descr = r_dispatch_masters.tran_type_descr, --    VARCHAR2(50)  Y
                modetrans_code = r_dispatch_masters.modetrans_code, --   VARCHAR2(2) 
                person_code = r_dispatch_masters.person_code, --    VARCHAR2(7) 
                person_ouc = r_dispatch_masters.person_ouc, --   VARCHAR2(13)  
                certifing_title = r_dispatch_masters.certifing_title, --    VARCHAR2(50)  Y
                trans_contractor_code = r_dispatch_masters.trans_contractor_code, --    VARCHAR2(4) 
                supplier1_ouc = r_dispatch_masters.supplier1_ouc, --    VARCHAR2(13)  
                trans_subcontractor_code = r_dispatch_masters.trans_subcontractor_code, --   VARCHAR2(4) Y
                supplier2_ouc = r_dispatch_masters.supplier2_ouc, --    VARCHAR2(13)  Y
                driver_name = r_dispatch_masters.driver_name, --    VARCHAR2(50)  Y
                vehicle_registration = r_dispatch_masters.vehicle_registration, --   VARCHAR2(20)  Y
                license = r_dispatch_masters.license, --    VARCHAR2(20)  Y
                trailer_plate = r_dispatch_masters.trailer_plate, --    VARCHAR2(20)  Y
                container_number = r_dispatch_masters.container_number --   VARCHAR2(15)  Y
            where code = r_receipt_masters.code and
                  document_code = r_receipt_masters.document_code and
                  org_unit_code = r_receipt_masters.org_unit_code;
      end;
   
      if p_goodunits is not null then
         --> bulk cargo
         if p_pckcode in ('BK01', 'BKBE', 'BKBG', 'BKBO', 'BKBT', 'BULK') then
            p_net := r_dispatch_details.quantity_net -
                     nvl(p_damageunits, 0) - nvl(p_lossunits, 0);
         
            p_gross := r_dispatch_details.quantity_gross -
                       nvl(p_damageunits, 0) - nvl(p_lossunits, 0);
         
         else
            p_net := (p_goodunits * r_dispatch_details.unit_weight_net) / 1000;
            p_gross := (p_goodunits * r_dispatch_details.unit_weight_gross) / 1000;
         
         end if;
         /*RECEIPT_DETAILS*/
         begin
            insert into receipt_details
               (code, --  VARCHAR2(25)  
                document_code, -- VARCHAR2(2) 
                org_unit_code, -- VARCHAR2(13)  
                origin_id, -- VARCHAR2(23)  
                comm_category_code, --  VARCHAR2(9) 
                commodity_code, --  VARCHAR2(18)  
                package_code, --  VARCHAR2(17)  
                allocation_destination_code, -- VARCHAR2(10)  
                quality, -- VARCHAR2(1) 
                quantity_net, --  NUMBER(11,3)  
                quantity_gross, --  NUMBER(11,3)  
                number_of_units, -- NUMBER(7) 
                unit_weight_net, -- NUMBER(8,3) Y
                unit_weight_gross, -- NUMBER(8,3) Y
                lonmst_id, -- VARCHAR2(25)  Y
                londtl_id, -- NUMBER  Y
                rpydtl_id, -- NUMBER  Y
                offid, -- VARCHAR2(13)  Y
                send_pack, -- NUMBER(20)  Y
                recv_pack, -- NUMBER(20)  Y
                last_mod_user, -- VARCHAR2(30)  Y
                last_mod_date --  DATE  Y
                )
            values
               (r_receipt_masters.code, -- CODE, -- VARCHAR2(25)  
                r_receipt_masters.document_code, -- DOCUMENT_CODE, --  VARCHAR2(2) 
                r_receipt_masters.org_unit_code, -- ORG_UNIT_CODE, --  VARCHAR2(13)  
                p_coi, -- ORIGIN_ID, --  VARCHAR2(23)  
                p_cmmcat, -- COMM_CATEGORY_CODE, -- VARCHAR2(9) 
                p_cmmcode, -- COMMODITY_CODE, -- VARCHAR2(18)  
                p_pckcode, -- PACKAGE_CODE, -- VARCHAR2(17)  
                p_alloccode, -- ALLOCATION_DESTINATION_CODE, --  VARCHAR2(10)  
                p_quality, -- QUALITY, --  VARCHAR2(1) 
                p_net, -- QUANTITY_NET, -- NUMBER(11,3)  
                p_gross, -- QUANTITY_GROSS, -- NUMBER(11,3)  
                p_goodunits, -- NUMBER_OF_UNITS, --  NUMBER(7) 
                r_dispatch_details.unit_weight_net, -- UNIT_WEIGHT_NET, --  NUMBER(8,3) Y
                r_dispatch_details.unit_weight_gross, -- UNIT_WEIGHT_GROSS, --  NUMBER(8,3) Y
                r_dispatch_details.lonmst_id, -- LONMST_ID, --  VARCHAR2(25)  Y
                r_dispatch_details.londtl_id, -- LONDTL_ID, --  NUMBER  Y
                r_dispatch_details.rpydtl_id, -- RPYDTL_ID, --  NUMBER  Y
                null, -- OFFID, --  VARCHAR2(13)  Y
                null, -- SEND_PACK, --  NUMBER(20)  Y
                null, -- RECV_PACK, --  NUMBER(20)  Y
                null, -- LAST_MOD_USER, --  VARCHAR2(30)  Y
                null -- LAST_MOD_DATE --  DATE  Y
                );
         exception
            when dup_val_on_index then
               update receipt_details
               set code = r_receipt_masters.code, --    VARCHAR2(25)  
                   document_code = r_receipt_masters.document_code, --     VARCHAR2(2) 
                   org_unit_code = r_receipt_masters.org_unit_code, --     VARCHAR2(13)  
                   origin_id = p_coi, --    VARCHAR2(23)  
                   comm_category_code = p_cmmcat, --   VARCHAR2(9) 
                   commodity_code = p_cmmcode, --   VARCHAR2(18)  
                   package_code = p_pckcode, --   VARCHAR2(17)  
                   allocation_destination_code = p_alloccode, --    VARCHAR2(10)  
                   quality = p_quality, --    VARCHAR2(1) 
                   quantity_net = p_net,
                   quantity_gross = p_gross,
                   number_of_units = p_goodunits, --     NUMBER(7) 
                   unit_weight_net = r_dispatch_details.unit_weight_net, --    NUMBER(8,3) Y
                   unit_weight_gross = r_dispatch_details.unit_weight_gross, --     NUMBER(8,3) Y
                   lonmst_id = r_dispatch_details.lonmst_id,
                   londtl_id = r_dispatch_details.londtl_id,
                   rpydtl_id = r_dispatch_details.rpydtl_id
               where code = r_receipt_masters.code and
                     document_code = r_receipt_masters.document_code and
                     org_unit_code = r_receipt_masters.org_unit_code and
                     origin_id = r_dispatch_details.origin_id and
                     comm_category_code =
                     r_dispatch_details.comm_category_code and
                     commodity_code = r_dispatch_details.commodity_code and
                     package_code = r_dispatch_details.package_code and
                     allocation_destination_code =
                     r_dispatch_details.allocation_destination_code and
                     quality = r_dispatch_details.quality;
         end;
      end if;
   
      if p_damageunits is not null then
         if p_pckcode in ('BK01', 'BKBE', 'BKBG', 'BKBO', 'BKBT', 'BULK') then
            p_net := nvl(p_damageunits, 0);
            p_gross := nvl(p_damageunits, 0);
            p_units := 1;
         else
            p_net := (p_damageunits * r_dispatch_details.unit_weight_net) / 1000;
            p_gross := (p_damageunits *
                       r_dispatch_details.unit_weight_gross) / 1000;
            p_units := p_damageunits;
         end if;
      
         /*TRANS_DAMAGES*/
         begin
            insert into trans_damages
               (receipt_code, --  VARCHAR2(25)  
                document_code, -- VARCHAR2(2) 
                org_unit_code, -- VARCHAR2(13)  
                origin_id, -- VARCHAR2(23)  
                package_code, --  VARCHAR2(17)  
                comm_category_code, --  VARCHAR2(9) 
                commodity_code, --  VARCHAR2(18)  
                allocation_code, -- VARCHAR2(10)  
                quality, -- VARCHAR2(1) 
                damage_code, -- VARCHAR2(25)  
                damage_record_id, --  VARCHAR2(25)  Y
                damage_cause_id, -- NUMBER  Y
                damage_date, -- DATE  
                quantity_net, --  NUMBER(11,3)  Y
                quantity_gross, --  NUMBER(11,3)  Y
                number_units, --  NUMBER(7) Y
                remarks, -- VARCHAR2(250) Y
                person_code, -- VARCHAR2(7) Y
                person_ouc, --  VARCHAR2(13)  Y
                offid, -- VARCHAR2(13)  Y
                send_pack, -- NUMBER(20)  Y
                recv_pack, -- NUMBER(20)  Y
                last_mod_user, -- VARCHAR2(30)  Y
                last_mod_date, -- DATE  Y
                lonmst_id, -- VARCHAR2(25)  Y
                londtl_id, -- NUMBER  Y
                rpydtl_id --  NUMBER  Y
                )
            values
               (r_receipt_masters.code, -- RECEIPT_CODE, -- VARCHAR2(25)  
                r_receipt_masters.document_code, -- DOCUMENT_CODE, --  VARCHAR2(2) 
                r_receipt_masters.org_unit_code, -- ORG_UNIT_CODE, --  VARCHAR2(13)  
                p_coi, -- ORIGIN_ID, --  VARCHAR2(23)  
                p_pckcode, -- PACKAGE_CODE, -- VARCHAR2(17)  
                p_cmmcat, -- COMM_CATEGORY_CODE, -- VARCHAR2(9) 
                p_cmmcode, -- COMMODITY_CODE, -- VARCHAR2(18)  
                p_alloccode, -- ALLOCATION_CODE, --  VARCHAR2(10)  
                p_quality, -- QUALITY, --  VARCHAR2(1) 
                v_damage_code, -- DAMAGE_CODE, --  VARCHAR2(25)  
                v_damage_code, -- DAMAGE_RECORD_ID, -- VARCHAR2(25)  Y 
                v_damage_cause_id, -- DAMAGE_CAUSE_ID, --  NUMBER  Y
                to_date(p_arrivaldt, vfd), -- DAMAGE_DATE, --  DATE  
                p_net, -- QUANTITY_NET, -- NUMBER(11,3)  Y
                p_gross, -- QUANTITY_GROSS, -- NUMBER(11,3)  Y
                p_units, -- NUMBER_UNITS, -- NUMBER(7) Y
                null, -- REMARKS, --  VARCHAR2(250) Y 
                p_person_code, -- PERSON_CODE, --  VARCHAR2(7) Y
                p_person_ouc, -- PERSON_OUC, -- VARCHAR2(13)  Y
                null, -- OFFID, --  VARCHAR2(13)  Y
                null, -- SEND_PACK, --  NUMBER(20)  Y
                null, -- RECV_PACK, --  NUMBER(20)  Y
                null, -- LAST_MOD_USER, --  VARCHAR2(30)  Y
                null, -- LAST_MOD_DATE, --  DATE  Y
                null, -- LONMST_ID, --  VARCHAR2(25)  Y
                null, -- LONDTL_ID, --  NUMBER  Y
                null -- RPYDTL_ID --  NUMBER  Y
                );
         exception
            when dup_val_on_index then
               update trans_damages
               set receipt_code = r_receipt_masters.code, --   VARCHAR2(25)   
                   document_code = r_receipt_masters.document_code, --    VARCHAR2(2)   
                   org_unit_code = r_receipt_masters.org_unit_code, --    VARCHAR2(13)    
                   origin_id = p_coi, --   VARCHAR2(23)    
                   package_code = p_pckcode, --  VARCHAR2(17)   
                   comm_category_code = p_cmmcat, --  VARCHAR2(9)  
                   commodity_code = p_cmmcode, --  VARCHAR2(18)   
                   allocation_code = p_alloccode, --   VARCHAR2(10)    
                   quality = p_quality, --   VARCHAR2(1)   
                   damage_code = v_damage_code, --    VARCHAR2(25)    
                   damage_record_id = v_damage_code, --   VARCHAR2(25)  Y   
                   damage_cause_id = v_damage_cause_id, --    NUMBER  Y 
                   damage_date = to_date(p_arrivaldt, vfd), --    DATE    
                   quantity_net = p_net,
                   quantity_gross = p_gross,
                   number_units = p_units, --  NUMBER(7) Y  
                   person_code = p_person_code, --   VARCHAR2(7) Y 
                   person_ouc = p_person_ouc --   VARCHAR2(13)  Y  
               where receipt_code = r_receipt_masters.code and
                     document_code = r_receipt_masters.document_code and
                     org_unit_code = r_receipt_masters.org_unit_code and
                     origin_id = r_dispatch_details.origin_id and
                     comm_category_code =
                     r_dispatch_details.comm_category_code and
                     commodity_code = r_dispatch_details.commodity_code and
                     package_code = r_dispatch_details.package_code and
                     allocation_code =
                     r_dispatch_details.allocation_destination_code and
                     quality = r_dispatch_details.quality and
                     damage_code = v_damage_code and
                     damage_record_id = v_damage_code and
                     damage_cause_id = v_damage_cause_id and
                     damage_date = to_date(p_arrivaldt, vfd);
         end;
      end if;
   
      if p_lossunits is not null then
      
         if p_pckcode in ('BK01', 'BKBE', 'BKBG', 'BKBO', 'BKBT', 'BULK') then
            p_net := nvl(p_lossunits, 0);
            p_gross := nvl(p_lossunits, 0);
            p_units := 1;
         else
            p_net := (p_lossunits * r_dispatch_details.unit_weight_net) / 1000;
            p_gross := (p_lossunits * r_dispatch_details.unit_weight_gross) / 1000;
            p_units := p_lossunits;
         end if;
      
         /*TRANS_LOSSES*/
         begin
            insert into trans_losses
               (trnloss_id, --  VARCHAR2(25)  
                intvyg_code, -- VARCHAR2(25)  Y
                intdlv_code, -- NUMBER(2) Y
                intcns_code, -- NUMBER  Y
                receipt_code, --  VARCHAR2(25)  Y
                document_code, -- VARCHAR2(2) Y
                org_unit_code, -- VARCHAR2(13)  Y
                origin_id, -- VARCHAR2(23)  Y
                comm_category_code, --  VARCHAR2(9) Y
                commodity_code, --  VARCHAR2(18)  Y
                package_code, --  VARCHAR2(17)  Y
                allocation_code, -- VARCHAR2(10)  Y
                quality, -- VARCHAR2(1) Y
                loss_code, -- VARCHAR2(25)  
                loss_record_id, --  VARCHAR2(25)  Y
                loss_cause_id, -- NUMBER  Y
                loss_date, -- DATE  
                loss_type, -- VARCHAR2(5) 
                quantity_net, --  NUMBER(11,3)  
                quantity_gross, --  NUMBER(11,3)  
                number_units, --  NUMBER(7) 
                remarks, -- VARCHAR2(250) Y
                person_code, -- VARCHAR2(7) 
                person_ouc, --  VARCHAR2(13)  
                offid, -- VARCHAR2(13)  Y
                send_pack, -- NUMBER(20)  Y
                recv_pack, -- NUMBER(20)  Y
                last_mod_user, -- VARCHAR2(30)  Y
                last_mod_date, -- DATE  Y
                lonmst_id, -- VARCHAR2(25)  Y
                londtl_id, -- NUMBER  Y
                rpydtl_id --  NUMBER  Y
                )
            values
               (compas_lib.get_current_site ||
                lpad(to_char(trnlss_seq.nextval), 18, '0'), -- TRNLOSS_ID, --  VARCHAR2(25)  
                null, -- INTVYG_CODE, --  VARCHAR2(25)  Y
                null, -- INTDLV_CODE, --  NUMBER(2) Y
                null, -- INTCNS_CODE, --  NUMBER  Y 
                r_receipt_masters.code, -- RECEIPT_CODE, -- VARCHAR2(25)  Y
                r_receipt_masters.document_code, -- DOCUMENT_CODE, -- VARCHAR2(2) Y
                r_receipt_masters.org_unit_code, -- ORG_UNIT_CODE, -- VARCHAR2(13)  Y
                p_coi, -- ORIGIN_ID, --  VARCHAR2(23)  Y
                p_cmmcat, -- COMM_CATEGORY_CODE, --  VARCHAR2(9) Y
                p_cmmcode, -- COMMODITY_CODE, --  VARCHAR2(18)  Y
                p_pckcode, -- PACKAGE_CODE, --  VARCHAR2(17)  Y
                p_alloccode, -- ALLOCATION_CODE, --  VARCHAR2(10)  Y
                p_quality, -- QUALITY, --  VARCHAR2(1) Y
                v_loss_code, -- LOSS_CODE, --  VARCHAR2(25)  
                v_loss_code, -- LOSS_RECORD_ID, -- VARCHAR2(25)  Y 
                v_loss_cause_id, -- LOSS_CAUSE_ID, --  NUMBER  Y 
                to_date(p_arrivaldt, vfd), -- LOSS_DATE, --  DATE  
                'POST', -- LOSS_TYPE, --  VARCHAR2(5) 
                p_net, -- QUANTITY_NET, -- NUMBER(11,3)  
                p_gross, -- QUANTITY_GROSS, -- NUMBER(11,3)  
                p_units, -- NUMBER_UNITS, -- NUMBER(7) 
                null, -- REMARKS, --  VARCHAR2(250) Y 
                p_person_code, -- PERSON_CODE, --  VARCHAR2(7) 
                p_person_ouc, -- PERSON_OUC, -- VARCHAR2(13)  
                null, -- OFFID, --  VARCHAR2(13)  Y
                null, -- SEND_PACK, --  NUMBER(20)  Y
                null, -- RECV_PACK, --  NUMBER(20)  Y
                null, -- LAST_MOD_USER, --  VARCHAR2(30)  Y
                null, -- LAST_MOD_DATE, --  DATE  Y
                null, -- LONMST_ID, --  VARCHAR2(25)  Y
                null, -- LONDTL_ID, --  NUMBER  Y
                null -- RPYDTL_ID -- NUMBER  Y
                );
         exception
            when dup_val_on_index then
               update trans_losses
               set loss_date = to_date(p_arrivaldt, vfd), --    DATE  
                   quantity_gross = p_gross,
                   quantity_net = p_net,
                   number_units = p_units, --    NUMBER(7) 
                   person_ouc = p_person_ouc, --    VARCHAR2(13)  
                   person_code = p_person_code, --     VARCHAR2(7) 
                   receipt_code = r_receipt_masters.code, --   VARCHAR2(25)  Y
                   loss_type = 'POST', --     VARCHAR2(5) 
                   allocation_code = p_alloccode, --     VARCHAR2(10)  Y
                   comm_category_code = p_cmmcat, --     VARCHAR2(9) Y
                   commodity_code = p_cmmcode, --     VARCHAR2(18)  Y
                   origin_id = p_coi, --     VARCHAR2(23)  Y
                   package_code = p_pckcode, --     VARCHAR2(17)  Y
                   quality = p_quality, --     VARCHAR2(1) Y
                   document_code = r_receipt_masters.document_code, --   VARCHAR2(2) Y
                   org_unit_code = r_receipt_masters.org_unit_code, --   VARCHAR2(13)  Y
                   loss_cause_id = v_loss_cause_id, --    NUMBER  Y 
                   loss_code = v_loss_code, --    VARCHAR2(25)  
                   loss_record_id = v_loss_code
               where receipt_code = r_receipt_masters.code and
                     document_code = r_receipt_masters.document_code and
                     org_unit_code = r_receipt_masters.org_unit_code and
                     origin_id = r_dispatch_details.origin_id and
                     comm_category_code =
                     r_dispatch_details.comm_category_code and
                     commodity_code = r_dispatch_details.commodity_code and
                     package_code = r_dispatch_details.package_code and
                     allocation_code =
                     r_dispatch_details.allocation_destination_code and
                     quality = r_dispatch_details.quality and
                     loss_code = v_loss_code and
                     loss_record_id = v_loss_code and
                     loss_cause_id = v_loss_cause_id and
                     loss_date = to_date(p_arrivaldt, vfd);
         end;
      end if;
   
      p_return_flag := 'S';
      p_return_message := null;
   
      commit;
   
   exception
      when others then
      
         p_return_flag := 'E';
      
         if p_return_message is null then
            p_return_message := sqlerrm;
         end if;
      
         rollback;
   end receipt;

   function validatedispacth return varchar2 is
   begin
      -- VALIDATIONS
      if dspmst_rec.code is null then
         p_return_message := 'P_WBCODE mandatory.';
      else
         dspmst_rec.code := dspmst_rec.org_unit_code || dspmst_rec.code || 'P';
      end if;
   
      -- P_DISPATCHDT
      if dspmst_rec.dispatch_date is null then
         p_return_message := 'P_DISPATCHDT mandatory.';
      end if;
   
      -- P_ORIGINTYPE     possible values are : 2;3 (mandatory)
      if dspmst_rec.origin_type not in ('2', '3') then
         p_return_message := get_message(1);
      end if;
   
      -- P_ORIGINLOC      code should be exist in GEO_POINTS (mandatory)
      if get_geopoint(dspmst_rec.origin_location_code).code is null then
         p_return_message := get_message(2);
      end if;
   
      -- P_ORIGINCODE     code should be exist in ORG_UNITS (Only when origin_type=2)
      if dspmst_rec.origin_type = 2 and
         not check_org_unit(dspmst_rec.origin_code) then
         p_return_message := get_message(3);
      end if;
   
      -- P_DESTINLOC      code should be exist in GEO_POINTS (mandatory)
      if get_geopoint(dspmst_rec.destination_location_code).code is null then
         p_return_message := get_message(4);
      end if;
   
      -- P_LTI_ID     code should be exist in LTI_MASTERS
      if dspmst_rec.lti_id is not null and get_lti_masters(dspmst_rec.lti_id)
        .code is null then
         p_return_message := get_message(5);
      end if;
   
      -- P_LOADINGDT
      if dspmst_rec.loading_date is null then
         p_return_message := 'P_LOADINGDT mandatory.';
      end if;
   
      -- P_CONSEGNEE_ID
      if dspmst_rec.organization_id is null then
         p_return_message := 'P_CONSEGNEE_ID mandatory.';
      end if;
   
      --> P_TT     possible values are 'DEL';'WIT'
      -->          DSP1 for Disposal Donation;
      -->          DSP2 for Disposal Destruction;
      -->         DSP3 for Disposal Sale;
   
      if dspmst_rec.tran_type_code not in
         ('DEL',
          'WIT',
          'DSP1',
          'DSP2',
          'DSP3',
          'LOAN',
          'DST',
          'AIR',
          'REP',
          'SWA1',
          'SWA2',
          'SHUN') then
         p_return_message := get_message(6);
      end if;
   
      if dspmst_rec.tran_type_code = 'DSP1' then
         dspmst_rec.tran_type_descr := 'DONA';
      elsif dspmst_rec.tran_type_code = 'DSP2' then
         dspmst_rec.tran_type_descr := 'DES';
      elsif dspmst_rec.tran_type_code = 'DSP3' then
         dspmst_rec.tran_type_descr := 'SALE';
      end if;
   
      if dspmst_rec.tran_type_code in ('DSP1', 'DSP2', 'DSP3') then
         dspmst_rec.tran_type_code := 'DSP';
      else
         dspmst_rec.tran_type_descr := owa_util.ite(dspmst_rec.origin_type = 3,
                                                    dspmst_rec.vehicle_registration,
                                                    null);
      end if;
   
      --> Verify loan details
      if dspmst_rec.tran_type_code in ('LOAN', 'SWA1') and
         not get_dsploanid(p_loan,
                           dspdtl_rec.origin_id,
                           dspdtl_rec.comm_category_code,
                           dspdtl_rec.commodity_code,
                           'D') then
         p_return_message := 'LOAN agreement not found.';
      end if;
   
      if dspmst_rec.tran_type_code in ('REP', 'SWA2') and
         not get_dsprepayid(p_loan,
                            dspdtl_rec.origin_id,
                            dspdtl_rec.comm_category_code,
                            dspdtl_rec.commodity_code,
                            'D') then
         p_return_message := 'Repayment-LOAN agreement not found.';
      end if;
   
      if dspmst_rec.modetrans_code is null then
         p_return_message := 'P_TRANMODE mandatory.';
      end if;
   
      -- P_PERSON_CODE, P_PERSON_OUC    code should be exists in PERSONS (mandatory)
      if get_person(dspmst_rec.person_code, dspmst_rec.person_ouc)
       .code is null then
         p_return_message := get_message(7);
      end if;
   
      -- P_TRANSPORT_CODE
      if dspmst_rec.trans_contractor_code is null then
         p_return_message := 'P_TRANSPORT_CODE mandatory.';
      
      end if;
      -- P_TRANSPORT_OUC
      if dspmst_rec.supplier1_ouc is null then
         p_return_message := 'P_TRANSPORT_OUC mandatory.';
      end if;
   
      -- P_COMPASSITE should be exists in ORG_UNIT_CODE
      if not check_org_unit(dspmst_rec.notify_org_unit_code) then
         p_return_message := get_message(8);
      end if;
   
      dspdtl_rec.code := dspmst_rec.code;
      -- P_CMMCAT
      if dspdtl_rec.comm_category_code is null then
         p_return_message := 'P_CMMCAT mandatory.';
      end if;
   
      -- P_CMMCODE
      if dspdtl_rec.commodity_code is null then
         p_return_message := 'P_CMMCODE mandatory.';
      end if;
   
      -- P_PCKCODE
      if dspdtl_rec.package_code is null then
         p_return_message := 'P_PCKCODE mandatory.';
      end if;
   
      -- P_ALLOCCODE
      if dspdtl_rec.allocation_destination_code is null then
         p_return_message := 'P_ALLOCCODE mandatory.';
      end if;
   
      -- P_QUALITY
      if dspdtl_rec.quality is null then
         p_return_message := 'P_QUALITY mandatory.';
      end if;
      if dspmst_rec.tran_type_code = 'DSP' and dspdtl_rec.quality != 'S' then
         p_return_message := 'P_QUALITY should be equal to S-Spoiled';
      end if;
      -- P_NET
      if dspdtl_rec.quantity_net is null then
         p_return_message := 'P_NET mandatory.';
      end if;
   
      -- P_GROSS
      if dspdtl_rec.quantity_gross is null then
         p_return_message := 'P_GROSS mandatory.';
      
      end if;
   
      -- P_UNITS
      if dspdtl_rec.number_of_units is null then
         p_return_message := 'P_UNITS mandatory.';
      end if;
   
      return p_return_message;
   end;

   procedure write_dspfrmitm is
   begin
      insert into dispatch_form_items
         (item_record_id, -- VARCHAR2(25)   
          dispatch_code, -- VARCHAR2(25)    
          document_code, -- VARCHAR2(2)   
          item_value, -- VARCHAR2(2000) Y ' '
          offid, -- VARCHAR2(13)  Y 
          send_pack, -- NUMBER  Y 
          recv_pack, -- NUMBER  Y 
          last_mod_user, -- VARCHAR2(30)  Y 
          last_mod_date -- DATE Y 
          )
      values
         (dspfrmitm_rec.item_record_id,
          dspfrmitm_rec.dispatch_code, -- dispatch_code -- VARCHAR2(25) 
          dspfrmitm_rec.document_code, -- document_code -- VARCHAR2(2) 
          dspfrmitm_rec.item_value, -- item_value, -- VARCHAR2(2000) Y ' '
          null, -- offid, -- VARCHAR2(13)  Y 
          null, -- send_pack, -- NUMBER  Y 
          null, -- recv_pack, -- NUMBER  Y 
          null, -- last_mod_user, -- VARCHAR2(30)  Y 
          null -- last_mod_date -- DATE Y          
          );
   exception
      when dup_val_on_index then
         update dispatch_form_items
         set item_record_id = dspfrmitm_rec.item_record_id,
             dispatch_code = dspfrmitm_rec.dispatch_code,
             document_code = dspfrmitm_rec.document_code,
             item_value = dspfrmitm_rec.item_value
         where item_record_id = dspfrmitm_rec.item_record_id and
               dispatch_code = dspfrmitm_rec.dispatch_code and
               document_code = dspfrmitm_rec.document_code;
   end;
   procedure write_dspmst is
   begin
      insert into dispatch_masters
         (code, -- VARCHAR2(25) 
          document_code, -- VARCHAR2(2) 
          dispatch_date, -- DATE  
          origin_type, -- VARCHAR2(1) 
          origin_location_code, -- VARCHAR2(13) 
          intvyg_code, -- VARCHAR2(25)  Y
          intdlv_code, -- NUMBER(2) Y
          origin_code, -- VARCHAR2(13)  Y
          origin_descr, -- VARCHAR2(50) Y
          destination_location_code, -- VARCHAR2(10)  
          destination_code, -- VARCHAR2(13) Y
          pro_activity_code, -- VARCHAR2(6) Y
          activity_ouc, -- VARCHAR2(13) Y
          lndarrm_code, -- VARCHAR2(25) Y
          lti_id, -- VARCHAR2(25) Y
          loan_id, -- VARCHAR2(25)  Y
          loading_date, -- DATE 
          organization_id, -- VARCHAR2(12)  
          tran_type_code, -- VARCHAR2(4)  
          tran_type_descr, -- VARCHAR2(50)  Y
          modetrans_code, -- VARCHAR2(2)  
          comments, -- VARCHAR2(250)  Y
          person_code, -- VARCHAR2(7) 
          person_ouc, -- VARCHAR2(13) 
          certifing_title, -- VARCHAR2(50)  Y
          trans_contractor_code, -- VARCHAR2(4) 
          supplier1_ouc, -- VARCHAR2(13)  
          trans_subcontractor_code, -- VARCHAR2(4)  Y
          supplier2_ouc, -- VARCHAR2(13)  Y
          nmbplt_id, -- VARCHAR2(25)  Y
          nmbtrl_id, -- VARCHAR2(25)  Y
          driver_name, -- VARCHAR2(50)  Y
          license, -- VARCHAR2(20)  Y
          vehicle_registration, -- VARCHAR2(20) Y
          trailer_plate, -- VARCHAR2(20)  Y
          container_number, -- VARCHAR2(15) Y
          atl_li_code, -- VARCHAR2(8) Y
          notify_indicator, -- VARCHAR2(1)  Y
          customised, -- VARCHAR2(50) Yw
          org_unit_code, -- VARCHAR2(13)  
          printed_indicator, -- VARCHAR2(1) Y
          notify_org_unit_code, -- VARCHAR2(13) Y
          offid, -- VARCHAR2(13)  Y
          send_pack, -- NUMBER(20)  Y
          recv_pack, -- NUMBER(20)  Y
          last_mod_user, -- VARCHAR2(30)  Y
          last_mod_date -- DATE  Y
          )
      values
         (dspmst_rec.code, -- code -- VARCHAR2(25) 
          dspmst_rec.document_code, -- document_code -- VARCHAR2(2) 
          dspmst_rec.dispatch_date, -- dispatch_date -- DATE  
          dspmst_rec.origin_type, -- origin_type -- VARCHAR2(1) 
          dspmst_rec.origin_location_code, -- origin_location_code -- VARCHAR2(13) 
          dspmst_rec.intvyg_code, -- intvyg_code -- VARCHAR2(25)  Y
          dspmst_rec.intdlv_code, -- intdlv_code -- NUMBER(2) Y
          dspmst_rec.origin_code, -- origin_code -- VARCHAR2(13)  Y
          dspmst_rec.origin_descr, -- origin_descr -- VARCHAR2(50) Y
          dspmst_rec.destination_location_code, -- destination_location_code -- VARCHAR2(10)  
          dspmst_rec.destination_code, -- destination_code -- VARCHAR2(13) Y
          dspmst_rec.pro_activity_code, -- pro_activity_code -- VARCHAR2(6) Y
          dspmst_rec.activity_ouc, -- activity_ouc -- VARCHAR2(13) Y
          dspmst_rec.lndarrm_code, -- lndarrm_code -- VARCHAR2(25) Y
          dspmst_rec.lti_id, -- lti_id -- VARCHAR2(25) Y
          dspmst_rec.loan_id, -- loan_id -- VARCHAR2(25)  Y
          dspmst_rec.loading_date, -- loading_date -- DATE 
          dspmst_rec.organization_id, -- organization_id -- VARCHAR2(12)  
          dspmst_rec.tran_type_code, -- tran_type_code -- VARCHAR2(4)  
          dspmst_rec.tran_type_descr, -- tran_type_descr -- VARCHAR2(50)  Y
          dspmst_rec.modetrans_code, -- modetrans_code -- VARCHAR2(2)  
          dspmst_rec.comments, -- comments -- VARCHAR2(250)  Y
          dspmst_rec.person_code, -- person_code -- VARCHAR2(7) 
          dspmst_rec.person_ouc, -- person_ouc -- VARCHAR2(13) 
          dspmst_rec.certifing_title, -- certifing_title -- VARCHAR2(50)  Y
          dspmst_rec.trans_contractor_code, -- trans_contractor_code -- VARCHAR2(4) 
          dspmst_rec.supplier1_ouc, -- supplier1_ouc -- VARCHAR2(13)  
          dspmst_rec.trans_subcontractor_code, -- 'TBD', -- trans_subcontractor_code -- VARCHAR2(4)  Y
          dspmst_rec.supplier2_ouc, -- 'TBD', -- supplier2_ouc -- VARCHAR2(13)  Y
          dspmst_rec.nmbplt_id, -- 'TBD', -- nmbplt_id -- VARCHAR2(25)  Y
          dspmst_rec.nmbtrl_id, -- 'TBD', -- nmbtrl_id -- VARCHAR2(25)  Y
          dspmst_rec.driver_name, -- driver_name -- VARCHAR2(50)  Y
          dspmst_rec.license, -- license -- VARCHAR2(20)  Y
          dspmst_rec.vehicle_registration, -- vehicle_registration -- VARCHAR2(20) Y
          dspmst_rec.vehicle_registration, -- trailer_plate -- VARCHAR2(20)  Y
          dspmst_rec.container_number, -- container_number -- VARCHAR2(15) Y
          dspmst_rec.atl_li_code, -- atl_li_code -- VARCHAR2(8) Y
          dspmst_rec.notify_indicator, -- notify_indicator -- VARCHAR2(1)  Y
          dspmst_rec.customised, -- customised -- VARCHAR2(50) Y
          dspmst_rec.org_unit_code, -- org_unit_code -- VARCHAR2(13)  
          dspmst_rec.printed_indicator, -- printed_indicator -- VARCHAR2(1) Y
          dspmst_rec.notify_org_unit_code, -- notify_org_unit_code -- VARCHAR2(13) Y
          dspmst_rec.offid, -- offid -- VARCHAR2(13)  Y
          dspmst_rec.send_pack, -- send_pack -- NUMBER(20)  Y
          dspmst_rec.recv_pack, -- recv_pack -- NUMBER(20)  Y
          dspmst_rec.last_mod_user, -- last_mod_user -- VARCHAR2(30)  Y
          dspmst_rec.last_mod_date -- last_mod_date -- DATE  Y
          );
   exception
      when dup_val_on_index then
         update dispatch_masters
         set code = dspmst_rec.code,
             document_code = dspmst_rec.document_code,
             dispatch_date = dspmst_rec.dispatch_date,
             origin_type = dspmst_rec.origin_type,
             origin_location_code = dspmst_rec.origin_location_code,
             origin_code = dspmst_rec.origin_code,
             origin_descr = dspmst_rec.origin_descr,
             destination_location_code = dspmst_rec.destination_location_code,
             destination_code = dspmst_rec.destination_code,
             lti_id = dspmst_rec.lti_id,
             loading_date = dspmst_rec.loading_date,
             organization_id = dspmst_rec.organization_id,
             tran_type_code = dspmst_rec.tran_type_code,
             tran_type_descr = dspmst_rec.tran_type_descr,
             modetrans_code = dspmst_rec.modetrans_code,
             comments = dspmst_rec.comments,
             person_code = dspmst_rec.person_code,
             person_ouc = dspmst_rec.person_ouc,
             certifing_title = dspmst_rec.certifing_title,
             trans_contractor_code = dspmst_rec.trans_contractor_code,
             supplier1_ouc = dspmst_rec.supplier1_ouc,
             driver_name = dspmst_rec.driver_name,
             license = dspmst_rec.license,
             vehicle_registration = dspmst_rec.vehicle_registration,
             trailer_plate = dspmst_rec.vehicle_registration,
             container_number = dspmst_rec.container_number,
             org_unit_code = dspmst_rec.org_unit_code,
             notify_org_unit_code = dspmst_rec.notify_org_unit_code
         where code = dspmst_rec.code and
               document_code = dspmst_rec.document_code;
   end;
   procedure write_dspdtl is
      -- DISPATCH_DETAILS
   begin
      insert into dispatch_details
         (code, -- VARCHAR2(25)  
          document_code, --  VARCHAR2(2) 
          si_record_id, -- VARCHAR2(25)  Y
          origin_id, --  VARCHAR2(23)  Y
          comm_category_code, -- VARCHAR2(9) 
          commodity_code, -- VARCHAR2(18)  
          package_code, -- VARCHAR2(17)  
          allocation_destination_code, --  VARCHAR2(10)  
          quality, --  VARCHAR2(1) 
          quantity_net, -- NUMBER(11,3)  
          quantity_gross, -- NUMBER(11,3)  
          number_of_units, --  NUMBER(7) 
          unit_weight_net, --  NUMBER(8,3) Y
          unit_weight_gross, --  NUMBER(8,3) Y
          lonmst_id, --  VARCHAR2(25)  Y
          londtl_id, --  NUMBER  Y
          rpydtl_id, --  NUMBER  Y
          offid, --  VARCHAR2(13)  Y
          send_pack, --  NUMBER(20)  Y
          recv_pack, --  NUMBER(20)  Y
          last_mod_user, --  VARCHAR2(30)  Y
          last_mod_date --  DATE  Y
          )
      values
         (dspdtl_rec.code, -- code -- VARCHAR2(25) 
          dspdtl_rec.document_code, -- document_code -- VARCHAR2(2) 
          dspdtl_rec.si_record_id, -- si_record_id -- VARCHAR2(25)  Y
          dspdtl_rec.origin_id, -- origin_id --  VARCHAR2(23)  Y
          dspdtl_rec.comm_category_code, -- comm_category_code -- VARCHAR2(9) 
          dspdtl_rec.commodity_code, -- commodity_code -- VARCHAR2(18)  
          dspdtl_rec.package_code, -- package_code -- VARCHAR2(17)  
          dspdtl_rec.allocation_destination_code, -- allocation_destination_code --  VARCHAR2(10)  
          dspdtl_rec.quality, -- quality --  VARCHAR2(1) 
          dspdtl_rec.quantity_net, -- quantity_net -- NUMBER(11,3)  
          dspdtl_rec.quantity_gross, -- quantity_gross -- NUMBER(11,3)  
          dspdtl_rec.number_of_units, -- number_of_units --  NUMBER(7) 
          dspdtl_rec.unit_weight_net, -- unit_weight_net --  NUMBER(8,3) Y
          dspdtl_rec.unit_weight_gross, -- unit_weight_gross --  NUMBER(8,3) Y
          dspdtl_rec.lonmst_id, -- lonmst_id --  VARCHAR2(25)  Y
          dspdtl_rec.londtl_id, -- londtl_id --  NUMBER  Y
          dspdtl_rec.rpydtl_id, -- rpydtl_id --  NUMBER  Y
          dspdtl_rec.offid, -- offid --  VARCHAR2(13)  Y
          dspdtl_rec.send_pack, -- send_pack --  NUMBER(20)  Y
          dspdtl_rec.recv_pack, -- recv_pack --  NUMBER(20)  Y
          dspdtl_rec.last_mod_user, -- last_mod_user --  VARCHAR2(30)  Y
          dspdtl_rec.last_mod_date -- last_mod_date --  DATE  Y
          );
   exception
      when dup_val_on_index then
         update dispatch_details
         set code = dspdtl_rec.code,
             document_code = dspdtl_rec.document_code,
             origin_id = dspdtl_rec.origin_id,
             comm_category_code = dspdtl_rec.comm_category_code,
             commodity_code = dspdtl_rec.commodity_code,
             package_code = dspdtl_rec.package_code,
             allocation_destination_code = dspdtl_rec.allocation_destination_code,
             quality = dspdtl_rec.quality,
             quantity_net = dspdtl_rec.quantity_net,
             quantity_gross = dspdtl_rec.quantity_gross,
             number_of_units = dspdtl_rec.number_of_units,
             unit_weight_net = dspdtl_rec.unit_weight_net,
             unit_weight_gross = dspdtl_rec.unit_weight_gross
         where code = dspdtl_rec.code and
               document_code = dspdtl_rec.document_code and
               origin_id = dspdtl_rec.origin_id and
               comm_category_code = dspdtl_rec.comm_category_code and
               commodity_code = dspdtl_rec.commodity_code and
               package_code = dspdtl_rec.package_code and
               allocation_destination_code =
               dspdtl_rec.allocation_destination_code and
               quality = dspdtl_rec.quality;
   end;

end write_waybill;
/
