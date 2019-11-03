
library(tidyverse)
library(RPostgreSQL)

# 设定工作目录
setwd("F:/DownLoad/echo-mimiciii-master/echo-mimiciii-master/notebooks")

# 导入设置文件
source("utils.R")

# 设定SQL文件目录
sql_dir <- file.path("..", "sql")

# Load configuration settings
dbdriver <- 'PostgreSQL'
host  <- '127.0.0.1'
port  <- '5432'
user  <- 'postgres'
password <- '9607015'
dbname <- 'mimic'
schema <- 'mimiciii'
# Connect to the database using the configuration settings
con <- dbConnect(dbDriver(dbdriver), dbname = dbname, host = host, port = port,
                 user = user, password = password)
# Set the default schema
dbExecute(con, paste("SET search_path TO ", schema, sep=" "))


# 运行population.sql
cat("-- Generate view population --\n")

sql <- file_to_sql_view(file.path(sql_dir, "population.sql"),
                        "population", "view")
dbSendQuery(con, sql)


c("cohort", "basics", "icd9", "drugs", "lab_tests", "vital_signs") %>%
  walk(function(x) {
    cat(sprintf("-- Generate materialized view %s --\n", x))

    x %>%
      file_to_sql_view(file.path(sql_dir, paste0(., ".sql")), .) %>%
      dbSendQuery(con, .)
  })


vs <- "select distinct(label) from vital_signs" %>%
  dbGetQuery(con, .) %>%
  pull(label)
vs


sql_template <-
  "with summary as (
    select distinct icustay_id, label
    , first_value(valuenum) over (partition by icustay_id, label order by charttime) as fst_val
    , first_value(valuenum) over (partition by icustay_id, label order by valuenum) as min_val
    , first_value(valuenum) over (partition by icustay_id, label order by valuenum desc) as max_val
    from vital_signs
)

select icustay_id
, %s
from summary
group by icustay_id
"


sql <- c("max(case when label = '%1$s' then 1 else 0 end) as vs_%1$s_flag",
         "max(case when label = '%1$s' then fst_val else null end) as vs_%1$s_first",
         "max(case when label = '%1$s' then min_val else null end) as vs_%1$s_min",
         "max(case when label = '%1$s' then max_val else null end) as vs_%1$s_max") %>%
  paste(collapse = "\n, ") %>%
  sprintf(vs) %>%
  paste(collapse = "\n, ") %>%
  sprintf(sql_template, .)
cat(sql, file = file.path(sql_dir, "vital_signs_unpivot.sql"))




labs <- "select distinct(label) from lab_tests" %>%
  dbGetQuery(con, .) %>%
  pull(label)
labs



sql_template <-
  "with lab_summary as (
    select distinct hadm_id, label
    , first_value(valuenum) over (partition by hadm_id, label order by charttime) as fst_val
    , first_value(valuenum) over (partition by hadm_id, label order by valuenum) as min_val
    , first_value(valuenum) over (partition by hadm_id, label order by valuenum desc) as max_val
    , first_value(abnormal) over (partition by hadm_id, label order by abnormal desc) as abnormal
    from lab_tests
)

select hadm_id
, %s
from lab_summary
group by hadm_id
"


sql <- c("max(case when label = '%1$s' then 1 else 0 end) as lab_%1$s_flag",
         "max(case when label = '%1$s' then fst_val else null end) as lab_%1$s_first",
         "max(case when label = '%1$s' then min_val else null end) as lab_%1$s_min",
         "max(case when label = '%1$s' then max_val else null end) as lab_%1$s_max",
         "max(case when label = '%1$s' then abnormal else null end) as lab_%1$s_abnormal") %>%
  paste(collapse = "\n, ") %>%
  sprintf(labs) %>%
  paste(collapse = "\n, ") %>%
  sprintf(sql_template, .)
cat(sql, file = file.path(sql_dir, "lab_unpivot.sql"))



c("vital_signs", "lab") %>%
  walk(function(x) {
    cat(sprintf("-- Generate materialized view %s_unpivot --\n", x))

    x %>%
      { file_to_sql_view(file.path(sql_dir, sprintf("%s_unpivot.sql", .)),
                         sprintf("%s_unpivot", .)) } %>%
      dbSendQuery(con, .)
  })




cat("-- Generate materialized view merged_data_raw --\n")

sql <- file_to_sql_view(file.path(sql_dir, "merge_data_raw.sql"),
                        "merged_data_raw")
dbSendQuery(con, sql)


sql_template <-
  "select %s
, %s
from merged_data_raw;
"


feature <- dbGetQuery(con, "select * from merged_data_raw limit 1;") %>% names
flag <- feature %>% grep("flag", ., value = TRUE)
non_flag <- setdiff(feature, flag)

flag



flag_sql <- flag %>%
  sprintf("case when %1$s is null then 0 else %1$s end as %1$s", .) %>%
  paste(collapse = "\n, ")



non_flag_sql <- non_flag %>% paste(collapse = "\n, ")


sql <- sprintf(sql_template, non_flag_sql, flag_sql)


cat(sql, file = file.path(sql_dir, "merge_data.sql"))


cat("-- Generate materialized view merged_data --\n")

sql <- file_to_sql_view(file.path(sql_dir, "merge_data.sql"),
                        "merged_data")
dbSendQuery(con, sql)



dbDisconnect(con)
