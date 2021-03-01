# Packages
lapply(c('readxl','dplyr','data.table','tidyr','readr'), library, character.only = TRUE)

# Read data
setwd('/Users/hunterjohnson/Dropbox/Dallas Projects/1_Data/1_Raw/Force_Requested/')
filelist <- list.files(pattern='*.xlsx')
datalist = lapply(filelist, function(x) readxl::read_excel(x))
dat <- data.table::rbindlist(datalist, fill=TRUE)

# Remove column 13 which is all NA
dat <- dat[,1:12]

# Delete rows that don't contain actual dates
dat <- dat[which(grepl('/', dat$`Received Date`)),]

# Reset working directory
setwd('/Users/hunterjohnson/Dropbox/Dallas Projects/')
                  
# Convert date to better format
dat$`Received Date` <- as.Date(dat$`Received Date`, format = "%m/%d/%y")

# Drop year 2013
dat$year <- substr(dat$`Received Date`, 1, 4)
dat <- dat[which(dat$year!=2013),]
dat$year <- NULL

# Rename columns
setnames(dat,
         old=c('Received Date','IA No','Badge','Officer Last Name','Officer First Name',
               'Citizen Last Name','Citizen First Name','Type of Force Used',
               'Citizen Resistance','Effective or Not','Division','Service/Incident Number'),
         new=c('date','iano','badge','off_lname','off_fname','civ_lname','civ_fname',
               'force_type','civ_resistance','force_effective','division','incidentnum'))

# Convert string columns to uppercase
dat <- mutate_all(dat, .funs=toupper)
                  
# Drop if civilian last name is "DOG"
dat <- dat[which(dat$civ_lname!="DOG"),]
                  
# Standardize division entries
dat$division <- trimws(gsub('PATROL','', dat$division))
dat$division <- trimws(gsub('DIV','', dat$division))
                  
# Remove all leading zeros from incidentnum
dat$incidentnum <- sub("^[0]+", "", dat$incidentnum)

# Manually fix some problems with incidentnum
dat$incidentnum <- gsub("20144", '2014', dat$incidentnum)
dat$incidentnum <- gsub("20107", '2017', dat$incidentnum)
dat$incidentnum <- gsub("20108", '2018', dat$incidentnum)
dat$incidentnum <- gsub("20177", '2017', dat$incidentnum)
dat$incidentnum <- gsub(",", '', dat$incidentnum)
                  
# Check numbers of incidents and civilians
uniqueN(dat$iano)
nrow(dat)
head(dat)
                  
# Save data
write_csv(dat, '1_Data/2_Clean/force.csv')
                  
                  
                  
