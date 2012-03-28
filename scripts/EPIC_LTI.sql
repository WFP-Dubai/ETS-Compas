set scan off
CREATE OR REPLACE VIEW EPIC_LTI
(lti_pk, lti_id, code, lti_date, expiry_date, transport_code, transport_ouc, transport_name, origin_type, origintype_desc, origin_location_code, origin_loc_name, origin_wh_code, origin_wh_name, destination_location_code, destination_loc_name, consegnee_code, consegnee_name, requested_dispatch_date, project_wbs_element, si_record_id, si_code, comm_category_code, commodity_code, cmmname, quantity_net, quantity_gross, number_of_units, unit_weight_net, unit_weight_gross, remarks, remarks_b)
AS
SELECT
LTIMST.LTI_ID||LTIDTL.SI_RECORD_ID
     ,  LTIMST.LTI_ID
     , LTIMST.CODE
     , LTI_DATE
     , EXPIRY_DATE
     , SUPPL.CODE TRANSPORT_CODE
     , SUPPL.ORG_UNIT_CODE TRANSPORT_OUC
     , SUPPL.NAME TRANSPORT_NAME
     , LTIMST.ORIGIN_TYPE
     , case
        when LTIMST.ORIGIN_TYPE= '2' then 'Warehouse'
        when LTIMST.ORIGIN_TYPE= '3' then 'Vehicle'
        when LTIMST.ORIGIN_TYPE= '1' then 'BillofLading'
       end  ORIGINTYPE_DESC
     , ORIGIN_LOCATION_CODE
     , OL.NAME ORIGIN_LOC_NAME
     , ORIGIN_CODE ORIGIN_WH_CODE
     , nvl(ow.name,ORIGIN_DESCR) ORIGIN_WH_name
     , DESTINATION_LOCATION_CODE
     , DL.NAME DESTINATION_LOC_NAME
     , ORG.ID CONSEGNEE_CODE
     , ORG.NAME CONSEGNEE_NAME
     , REQUESTED_DISPATCH_DATE
     , SITOPRJ.PROJECT_WBS_ELEMENT
     , LTIDTL.SI_RECORD_ID
     , SI_CODE
     , LTIDTL.COMM_CATEGORY_cODE
     , LTIDTL.COMMODITY_cODE
     , CMM.DESCRIPTION CMMNAME
     , LTIDTL.QUANTITY_NET
     , LTIDTL.QUANTITY_GROSS
     , NUMBER_OF_UNITS
     , UNIT_WEIGHT_NET
     , UNIT_WEIGHT_GROSS
     , LTIMST.REMARKS
     , LTIMST.REMARKS_B
 FROM LTI_MASTERS LTIMST,
      LTI_DETAILS LTIDTL,
      GEO_POINTS OL,
      GEO_POINTS DL,
      ORG_UNITS OW,
      SI_DETAILS SIDTL,
      SI_TO_PROJECTS SITOPRJ,
      ORGANIZATIONS ORG,
      COMMODITIES CMM,
      SUPPLIERS SUPPL
   WHERE LTIMST.TRANSPORTER_CODE = SUPPL.CODE
     AND LTIMST.SUPPLIER_OUC = SUPPL.ORG_UNIT_CODE
     AND LTIMST.LTI_ID = LTIDTL.LTI_ID
     AND LTIDTL.SI_RECORD_ID = SIDTL.SI_RECORD_ID
     AND LTIDTL.COMM_CATEGORY_CODE = CMM.COMM_CATEGORY_CODE
     AND LTIDTL.COMMODITY_CODE = CMM.CODE
     AND SIDTL.SI_RECORd_ID = SITOPRJ.SI_RECORd_ID
     and LTIMST.LTI_DATE between SITOPRJ.start_date
     and nvl(SITOPRJ.end_Date, to_date('31-12-3000', 'dd-mm-yyyy'))
     AND LTIMST.ORIGIN_LOCATION_CODE   =OL.CODE
     AND LTIMST.DESTINATION_LOCATION_CODE  =DL.CODE
     AND LTIMST.ORGANIZATION_ID=ORG.ID
     AND ORIGIN_CODE = OW.CODE(+)
     AND LTI_DATE >='01-JAN-2010';

	 
set scan on