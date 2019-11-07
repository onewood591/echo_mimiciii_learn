DROP MATERIALIZED VIEW IF EXISTS lactate_chart CASCADE;
CREATE MATERIALIZED VIEW lactate_chart AS

select subject_id, hadm_id, charttime as lactate_time, valuenum as lactate_value, valueuom 
from chartevents
where itemid in (818, 1531, 225668, 50813)
ORDER BY subject_id, hadm_id;