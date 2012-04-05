--------------------------------------------------------
-- Export file for user TESTISBX002                   --
-- Created by marco.vittorini on 16/11/2011, 11:30:04 --
--------------------------------------------------------

spool ewaybill_objs.log

prompt
prompt Creating view EPIC_LOSSDAMAGEREASON
prompt ===================================
create or replace view epic_lossdamagereason as
select distinct b.type,
                     comm_category_code,
                     cause
              from loss_damage_causes,
                   loss_damage_names b
              where loss_damage_causes.name_record_id = b.record_id;

prompt
prompt Creating view EPIC_PERSONS
prompt ==========================
CREATE OR REPLACE VIEW EPIC_PERSONS AS
SELECT org_unit_code||code PERSON_PK, org_unit_code, code, type_of_document, organization_id,
       last_name, first_name, title, document_number, e_mail_address,
       mobile_phone_number, official_tel_number, fax_number,
       effective_date, expiry_date, location_code
  FROM persons
--  where org_unit_code='JERX001';

prompt
prompt Creating view EPIC_STOCK
prompt ========================
create or replace view epic_stock
(wh_pk, wh_regional, wh_country, wh_location, wh_code, wh_name, project_wbs_element, si_record_id, si_code, origin_id, reference_number, comm_category_code, commodity_code, cmmname, package_code, packagename, qualitycode, qualitydescr, quantity_net, quantity_gross, number_of_units, allocation_code)
as
select /*+rule*/
     stored_commodities.org_unit_code||stored_commodities.origin_id||stored_commodities.comm_category_code||
     stored_commodities.commodity_code||stored_commodities.package_code||allocation_code wh_pk,
      s_countries.rb_code wh_Regional,
      s_countries.sap_name Wh_Country,
      geo_points.name Wh_Location,
      Org_units.code wh_code,
      org_units.name wh_name,
      si_to_projects.project_wbs_element,
      si_details.si_record_id,
      si_details.si_code,
      stored_commodities.origin_id,
      commodity_origins.vessel_or_supplier,
      stored_commodities.comm_category_code,
      stored_commodities.commodity_code,
      commodities.description cmmname,
      stored_commodities.package_code,
      package_types.description packagename,
      stored_commodities.quality QualityCode,
      decode(stored_commodities.quality,'D','Damaged','G','Good','S','Spoiled','U',
         'Unavailable','OTHER') qualityDescr,
      (stored_commodities.quantity_net * percentage_n /100 ) quantity_net,
       (stored_commodities.quantity_gross * percentage_n /100 ) quantity_gross,
       number_of_units,
       stored_commodities.allocation_code
  from  stored_commodities ,
        org_units ,
        geo_points ,
        s_countries,
        coi_to_sis,
        commodity_origins,
        si_details,        
        si_to_projects,
        commodities,
        package_types
  where stored_commodities.org_unit_code=org_units.code
    and org_units.geo_point_code=geo_points.code
    and geo_points.country_code = s_countries.compas_code
    and stored_commodities.package_code=package_types.code
    and stored_commodities.comm_category_code=commodities.comm_category_code
    and stored_commodities.commodity_code=commodities.code
    and stored_commodities.origin_id=commodity_origins.origin_id
    and stored_commodities.origin_id=coi_to_sis.origin_id
    and coi_to_sis.si_record_id =si_details.si_record_id
    and si_details.si_record_id=si_to_projects.si_record_id
    and si_to_projects.end_date is null;

spool off
