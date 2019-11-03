
library(tidyverse)
library(RPostgreSQL)

# 设定工作目录
setwd("F:/Rproject/echo_mimiciii_learn/notebook")

# 设定数据保存目录
data_dir <- file.path("..", "data")

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


sql <- readr::read_file(file.path(sql_dir, "tte-first.sql"))
sql


time_to_tte <- dbGetQuery(con, sql)
head(time_to_tte)
str(time_to_tte)


options(repr.plot.width = 6, repr.plot.height = 6)


time_to_tte %>%
  filter(!is.na(time_to_echo), time_to_echo >= -5, time_to_echo <= 15) %>%
  group_by(time_to_echo) %>%
  summarise(freq = n()) %>%
  mutate(dens = freq / sum(freq)) %>%
  ggplot() +
  geom_col(aes(x = time_to_echo, y = dens), width = .8,
           fill = rgb(66, 139, 202, maxColorValue = 255)) +
  # scale_x_continuous(breaks = c(-6, seq(-5, 15, 5), 16),
  #                    labels = c("<-5", seq(-5, 15, 5), ">15")) +
  labs(y = "Density", x = "Timing of Echo Orders (days wrt to Admission)") +
  theme_bw() +
  theme(panel.grid.minor.x = element_blank())
# rgb(12, 107, 185, maxColorValue = 255)



sql <- readr::read_file(file.path(sql_dir, "tte-summary.sql"))
sql


tte_summary <- dbGetQuery(con, sql)
head(tte_summary)
str(tte_summary)


options(repr.plot.width = 3.8, repr.plot.height = 6)


tte_summary %>%
  filter(echo_times > 0, echo_times < 6) %>%
  group_by(echo_times) %>%
  summarise(freq = n()) %>%
  mutate(dens = freq / sum(freq)) %>%
  ggplot() +
  geom_col(aes(x = echo_times, y = dens), width = .82,
           fill = rgb(66, 139, 202, maxColorValue = 255)) +
  theme_bw() +
  labs(x = "Number of Echo Orders per patient",
       y = "Density") +
  theme_bw() +
  theme(panel.grid.minor.x = element_blank(), panel.grid.major.x = element_blank())


dbDisconnect(con)
dbUnloadDriver(drv)


data.table::fwrite(tte_summary, file.path(data_dir, "echo_times.csv"))
data.table::fwrite(time_to_tte, file.path(data_dir, "time_to_tte.csv"))





