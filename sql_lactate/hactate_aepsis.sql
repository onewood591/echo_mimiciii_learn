set search_path to mimiciii;
create materialized view hactate_sepsis as
with high_lactate as
    (
        select subject_id, hadm_id,itemid, charttime, valuenum
        from labevents
        where itemid = 50813 and hadm_id is not null and valuenum is not null
        order by subject_id, hadm_id
    ),
     angusepsis as
    (
        select *
        from angus_sepsis
        where angus = 1
        order by subject_id, hadm_id
     )
select ans.subject_id, ans.hadm_id, ans.angus, hl.charttime, hl.valuenum
from high_lactate hl
right join angusepsis ans using (hadm_id)
order by ans.subject_id, ans.hadm_id, hl.charttime;
