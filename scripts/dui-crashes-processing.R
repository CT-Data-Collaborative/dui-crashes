library(dplyr)
library(datapkg)
library(readxl)
library(tidyr)

##################################################################
#
# Processing Script for DUI Crashes
# Created by Jenna Daly	
# On 06/18/2018
#
##################################################################

#Setup environment
sub_folders <- list.files()
raw_location <- grep("raw$", sub_folders, value=T)
path_to_raw_data <- (paste0(getwd(), "/", raw_location))
data_location <- grep("data$", sub_folders, value=T)
path_to_data <- (paste0(getwd(), "/", data_location))
crash_df <-  dir(path_to_raw_data, recursive=T, pattern = "DUI") 

#Bring in each sheet of the file, assign variable accordingly
dui_crashes <- read_excel(paste0(path_to_raw_data, "/", crash_df), sheet=2, skip=0)
dui_crashes$Variable <- "DUI Crashes"

dui_fatalities <- read_excel(paste0(path_to_raw_data, "/", crash_df), sheet=3, skip=0)
dui_fatalities$Variable <- "DUI Fatalities"

dui_injuries <- read_excel(paste0(path_to_raw_data, "/", crash_df), sheet=4, skip=0)
dui_injuries$Variable <- "DUI Injuries"

#Combine and gather year columns into one
dui_data <- rbind(dui_crashes, dui_fatalities, dui_injuries)
dui_data <- gather(dui_data, Year, Value, 2:9, factor_key=F)

#Create total for CT
ct_dui_data <- dui_data %>% 
  group_by(Variable, Year) %>% 
  summarise(Value = sum(Value))

ct_dui_data$Town <- "Connecticut"

ct_dui_data <- as.data.frame(ct_dui_data)

#Merge CT back into main df
dui_data <- rbind(dui_data, ct_dui_data)

#Merge in FIPS
town_fips_dp_URL <- 'https://raw.githubusercontent.com/CT-Data-Collaborative/ct-town-list/master/datapackage.json'
town_fips_dp <- datapkg_read(path = town_fips_dp_URL)
fips <- (town_fips_dp$data[[1]])

dui_data_fips <- merge(dui_data, fips, by = "Town", all=T)

#Assign MT
dui_data_fips$`Measure Type` <- "Number"

#Order and sort columns
dui_data_fips <- dui_data_fips %>% 
  select(Town, FIPS, Year, `Measure Type`, Variable, Value) %>% 
  arrange(Town, Year, Variable)

# Write to File
write.table(
  dui_data_fips,
  file.path(getwd(), "data", "dui-crashes-2017.csv"),
  sep = ",",
  row.names = F
)
