CREATE OR REPLACE VIEW EPIC_GEO AS
select org_units.code as org_code,
       org_units.name,
       org_units.geo_point_code,
       geo_points.name as geo_name,
       country_code,
       reporting_code,
       organization_id
from org_units,
     geo_points
where geo_point_code = geo_points.code;
