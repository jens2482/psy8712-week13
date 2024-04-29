# Script Settings and Resources
setwd(dirname(rstudioapi::getActiveDocumentContext()$path))
library(keyring)
library(RMariaDB)
library(tidyverse)

# Data Import and Cleaning
conn <- dbConnect(MariaDB(),
                  dbname = "cla_tntlab", #needed to name database and this seemed like the simplest way
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
  right_join(testscores_tbl, by = join_by(employee_id)) %>% #only want employees with test score
  inner_join(offices_tbl, by = join_by (city == office)) %>% #did inner join because we need both location and type columns
  write_csv("../data/week13.csv")


# Analysis

#print summary table stating number of managers and unique number of managers
manager_totals <- week13_tbl %>%
  summarize(
    Total_Managers = n(), #count all rows
    Unique_Managers = n_distinct(employee_id) #count unique employee ids
  ) %>%
  print()

#print summary table with only people who were hired as managers split by location
manager_locations <- week13_tbl %>%
  filter(manager_hire == "N") %>%
  group_by(city) %>%
  summarize(
    Managers_by_Location = n(), #after filtering and grouping by city, count all rows
  ) %>%
  print()

#print summary table with means and sds for years employed grouped by performance level
years_and_level <- week13_tbl %>% 
  group_by(performance_group) %>% 
  summarize(Mean_Employment_Years = mean(yrs_employed),
            SD_Employment_Years = sd(yrs_employed)) %>%
  print()

#print summary table with only people who were hired as managers split by location
manager_scores_by_type <- week13_tbl %>%
  select(type, employee_id, test_score) %>% #only select columsn included in assignment
  arrange(type, desc(test_score)) %>% #arrange by two rows, alphabetically by type and then descending by test score
  print()

