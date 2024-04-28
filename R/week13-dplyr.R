# Script Settings and Resources
setwd(dirname(rstudioapi::getActiveDocumentContext()$path))
library(keyring)
library(RMariaDB)
library(tidyverse)

# Data Import and Cleaning
conn <- dbConnect(MariaDB(),
                  dbname = "cla_tntlab",
                  user="jens2482",
                  password = key_get("latis-mysql", "jens2482"),
                  host="mysql-prod5.oit.umn.edu",
                  port=3306,
                  ssl.ca = '../mysql_hotel_umn_20220728_interm.cer')

#extract employee table, convert into tibble and save as csv
employees_tbl <- dbGetQuery(conn, "SELECT * FROM datascience_employees") %>%
  as_tibble() %>%
  write_csv("../data/employees.csv")

#extract test scores table, convert into tibble and save as csv
testscores_tbl<- dbGetQuery(conn, "SELECT * FROM datascience_testscores") %>%
  as_tibble() %>%
  write_csv("../data/testscores.csv")

#extract offices table, convert into tibble and save as csv
offices_tbl <- dbGetQuery(conn, "SELECT * FROM datascience_offices") %>%
  as_tibble() %>%
  write_csv("../data/offices.csv")

#join data frames test score 
week13_tbl <- employees_tbl %>% 
  right_join(testscores_tbl, by = join_by(employee_id)) %>%
  inner_join(offices_tbl, by = join_by (city == office)) %>%
  write_csv("../data/week13.csv")


# Analysis

#print summary table stating number of managers and unique number of managers
manager_totals <- week13_tbl %>%
  summarize(
    Total_Managers = n(),
    Unique_Managers = n_distinct(employee_id)
  ) %>%
  print()

#print summary table with only people who were hired as managers split by location
manager_locations <- week13_tbl %>%
  filter(manager_hire == "N") %>%
  group_by(city) %>%
  summarize(
    Managers_by_Location = n(),
  ) %>%
  print()

#print summary table with only people who were hired as managers split by location
manager_scores_by_type <- week13_tbl %>%
  select(type, employee_id, test_score) %>%
  arrange(type, desc(test_score)) %>%
  print()
