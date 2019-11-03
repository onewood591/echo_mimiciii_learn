library(RPostgreSQL)
library(tidyverse)

dbDriver <- 'PostgreSQL'
host <- '127.0.0.1'
port <- '5432'
user <- 'postgres'
password <- '9607015'
dbname <- 'mimic'
schema <- 'mimiciii'

drv <- dbDriver(dbDriver)
con <- dbConnect(drv = drv, host = host, port = port, 
                 user = user, password = password,
                 dbname = dbname)
dbSendQuery(conn = con, 
            statement = paste('set search_path to ', schema, sep = ''))
