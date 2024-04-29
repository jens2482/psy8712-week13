# Script Settings and Resources - removed tidyverse
setwd(dirname(rstudioapi::getActiveDocumentContext()$path))
library(keyring)
library(RMariaDB)

# Data Import and Cleaning - I'm assuming this all stays the same

conn <- dbConnect(MariaDB(),
                  dbname = "cla_tntlab", #needed to name database and this seemed like the simplest way
                  user="jens2482",
                  password = key_get("latis-mysql", "jens2482"),
                  host="mysql-prod5.oit.umn.edu",
                  port=3306,
                  ssl.ca = '../mysql_hotel_umn_20220728_interm.cer')

#extract employee table
dbGetQuery(conn, "SELECT * FROM datascience_employees")

#extract test scores table
dbGetQuery(conn, "SELECT * FROM datascience_testscores")

#extract offices table
dbGetQuery(conn, "SELECT * FROM datascience_offices")

#join data frames test score 
week13_tbl <- employees_tbl %>% 
  right_join(testscores_tbl, by = join_by(employee_id)) %>% #only want employees with test score
  inner_join(offices_tbl, by = join_by (city == office)) %>% #did inner join because we need both location and type columns
  write_csv("../data/week13.csv")


# Analysis

#print number of managers and unique number of managers
dbGetQuery(conn, 
           "SELECT COUNT(*) AS total_managers, 
           COUNT(DISTINCT datascience_employees.employee_id) AS unique_managers 
           FROM datascience_employees
           RIGHT JOIN datascience_testscores ON datascience_employees.employee_id=datascience_testscores.employee_id;"#need to include a join in order to eliminate those with no test scores
           )

#print only people who were hired as managers split by location
dbGetQuery(conn, 
           "SELECT city, COUNT(datascience_employees.employee_id) AS manager_location
           FROM datascience_employees
           RIGHT JOIN datascience_testscores ON datascience_employees.employee_id=datascience_testscores.employee_id
           WHERE manager_hire = 'N'
           GROUP BY city;"
           )

#print means and sds for years employed grouped by performance level
dbGetQuery(conn, 
           "SELECT performance_group, 
            AVG(yrs_employed) AS mean_employment_years, STDDEV(yrs_employed) AS sd_employment_years
            FROM datascience_employees
            RIGHT JOIN datascience_testscores ON datascience_employees.employee_id=datascience_testscores.employee_id
            GROUP BY performance_group;"
            )

#print only people who were hired as managers split by location
dbGetQuery(conn, 
           "SELECT type, datascience_employees.employee_id, test_score
           FROM datascience_employees 
           RIGHT JOIN datascience_testscores ON datascience_employees.employee_id=datascience_testscores.employee_id
           INNER JOIN datascience_offices ON city = office
           ORDER BY type, test_score DESC;"
           )

