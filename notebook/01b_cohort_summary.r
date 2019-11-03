source('dbConnect.r')


sql_dir <- file.path("..", "SQL")
list.files(sql_dir)

# 统计所有败血症患者数量
dbGetQuery(con, "select count(*) from population where angus = 1;")

# 统计成年败血症患者数量
sql <- "
select count(*)
  from population
 where angus = 1
   and age >= 18
"
dbGetQuery(con, sql)

# 只统计第一次入住ICU的患者
sql <- "
select count(*)
  from population
 where angus = 1
   and age >= 18
   and icu_order = 1
"
dbGetQuery(con, sql)

# 只统计MICU和SICU的患者
sql <- "
select count(*)
  from population
 where angus = 1
   and age >= 18
   and icu_order = 1
   and first_careunit in ('MICU', 'SICU')
"
dbGetQuery(con, sql)

# 排除在入住ICU前或后做的TTE
sql <- "
select count(*)
  from population
 where angus = 1
   and age >= 18
   and icu_order = 1
   and first_careunit in ('MICU', 'SICU')
   and echo_exclude = 0
"
dbGetQuery(con, sql)

sql <- "
select count(*)
  from population
 where angus = 1
   and age >= 18
   and icu_order = 1
   and first_careunit in ('MICU', 'SICU')
   and echo_exclude = 1
"
dbGetQuery(con, sql)


sql <- "
select count(*)
  from population
 where angus = 1
   and age >= 18
   and icu_order = 1
   and first_careunit in ('MICU', 'SICU')
   and echo_include = 1
"
dbGetQuery(con, sql)


# 有做TTE的组
sql <- "
select count(*)
  from population
 where angus = 1
   and age >= 18
   and icu_order = 1
   and first_careunit in ('MICU', 'SICU')
   and echo_time is not null
   and echo_include = 1
"
dbGetQuery(con, sql)


source('dbDisconnect.r')































