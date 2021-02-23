# Packages
lapply(c('readxl','dplyr','data.table','tidyr','readr'), library, character.only = TRUE)

'%!in%' <- function(x,y){
  !('%in%'(x,y))
}

setwd('/Users/hunterjohnson/Dropbox/DPD ML/')

# Read data
uf13 <- read_excel("Data/Raw/Force_Public/Police_Response_to_Resistance_2013.xlsx")
uf14 <- read_excel("Data/Raw/Force_Public/Police_Response_to_Resistance_2014.xlsx")
uf15 <- read_excel("Data/Raw/Force_Public/Police_Response_to_Resistance_2015.xlsx")
uf16 <- read_excel("Data/Raw/Force_Public/Police_Response_to_Resistance_2016.xlsx")
uf17 <- read_excel("Data/Raw/Force_Public/Police_Response_to_Resistance_2017.xlsx")
uf18 <- read_excel("Data/Raw/Force_Public/Police_Response_to_Resistance_2018.xlsx")

# Drop columns
uf13[, c('OBJECTID','Match_addr','HIRE_DT','Cycles_Num','STREET_N','TAAG_Name',
               'STREET','street_g','street_t','DIST_NAME','GeoLocation','X','Y')] <- list(NULL)
uf14[, c('OBJECTID','HIRE_DT','Cycles_Num','DIST_NAME')] <- list(NULL)
uf15[, c('ID','HIRE_DT','Cycles_Num','DIST_NAME','Latitude','Longitude','GeoLocation')] <- list(NULL)
uf16[, c('OBJECTID','STREET_N','STREET','street_g','street_t','TAAG_Name',
               'X','Y','GeoLocation','Cycles_Num','DIST_NAME','HIRE_DT')] <- list(NULL)
uf17[, c('OBJECTID','HIRE_DT','Cycles_Num','DIST_NAME','TAAG_Name','STREET_N',
               'STREET','street_g','street_t','X','Y','GeoLocation')] <- list(NULL)
uf18[, c('OBJECTID','HIRE_DT','Cycles_Num','STREET_N','STREET','street_g','street_t',
               'DIST_NAME','TAAG_Name','X','Y','GeoLocation')] <- list(NULL)

# Rename columns
names(uf13) <- c('iano','uofnum','date','time','badge','offsex','offrace','off_injured',
                 'off_cond','off_hosp','service_type','force_type','uof_reason','force_effect',
                 'address','civnum','civrace','civsex','civ_injured','civ_cond','civ_arrest',
                 'civ_influence','civ_charge','RA','beat','sector','division')
names(uf14) <- c('iano','date','time','badge','offsex','offrace','off_injured',
                 'off_cond','off_hosp','service_type','uofnum','force_type','uof_reason','force_effect',
                 'civnum','civrace','civsex','civ_injured','civ_cond','civ_arrest','civ_influence',
                 'civ_charge','address','RA','beat','sector','division')
names(uf15) <- c('iano','date','time','badge','offsex','offrace','off_injured',
                 'off_cond','off_hosp','service_type','uofnum','force_type','uof_reason','force_effect',
                 'civnum','civrace','civsex','civ_injured','civ_cond','civ_arrest','civ_influence',
                 'civ_charge','address','RA','beat','sector','division')
names(uf16) <- c('iano','uofnum','address','date','time','badge','offsex','offrace','off_injured',
                 'off_cond','off_hosp','service_type','force_type','uof_reason','force_effect',
                 'civnum','civrace','civsex','civ_injured','civ_cond','civ_arrest','civ_influence',
                 'civ_charge','RA','beat','sector','division')
names(uf17) <- c('iano','uofnum','address','date','time','badge','offsex','offrace','off_injured',
                 'off_cond','off_hosp','service_type','force_type','uof_reason','force_effect',
                 'civnum','civrace','civsex','civ_injured','civ_cond','civ_arrest','civ_influence',
                 'civ_charge','RA','beat','sector','division')
names(uf18) <- c('iano','uofnum','date','time','badge','offsex','offrace','off_injured',
                 'off_cond','off_hosp','service_type','force_type','uof_reason','force_effect','address',
                 'civnum','civrace','civsex','civ_injured','civ_cond','civ_arrest','civ_influence',
                 'civ_charge','RA','beat','sector','division')

# Reorder columns
col_order <- c('iano','uofnum','date','time','badge','offsex','offrace','off_injured',
               'off_cond','off_hosp','service_type','force_type','uof_reason','force_effect',
               'address','civnum','civrace','civsex','civ_injured','civ_cond','civ_arrest',
               'civ_influence','civ_charge','RA','beat','sector','division')

uf13 <- uf13[,col_order]
uf14 <- uf14[,col_order]
uf15 <- uf15[,col_order]
uf16 <- uf16[,col_order]
uf17 <- uf17[,col_order]
uf18 <- uf18[,col_order]

# This is necessary for rbind to work; otherwise dates are converted incorrectly
uf13$date <- as.character(uf13$date)
uf14$date <- as.character(uf14$date)
uf15$date <- as.character(uf15$date)
uf16$date <- as.character(uf16$date)
uf17$date <- as.character(uf17$date)
uf18$date <- as.character(uf18$date)

# 2013 dates are in different format
uf13$date <- ifelse(nchar(uf13$date)==22, paste0(substr(uf13$date,7,10),'-',substr(uf13$date,1,2),'-',substr(uf13$date,4,5)), uf13$date)

# check that all dates are now 10 characters and contain hyphens
nrow(uf13[which(grepl('-', uf13$date)),]) == nrow(uf13)
unique(nchar(uf13$date))

# 2017 and 2018 dates are also in different format
uf17$date <- paste0(substr(uf17$date,7,10),'-',substr(uf17$date,1,2),'-',substr(uf17$date,4,5))
uf18$date <- paste0(substr(uf18$date,7,10),'-',substr(uf18$date,1,2),'-',substr(uf18$date,4,5))

# Join together
uf <- rbind(uf13,uf14,uf15,uf16,uf17,uf18)

# Remove extra hyphen from iano of length 13
uf$iano <- ifelse(nchar(uf$iano)==13, paste0(substr(uf$iano,1,2), substr(uf$iano,4,13)), uf$iano)

# Remove extra characters of iano of length 16
uf$iano <- ifelse(nchar(uf$iano)==16, substr(uf$iano,1,12), uf$iano)

# Drop if iano is missing
uf <- uf[which(!is.na(uf$iano)),]

unique(nchar(uf$iano)) # 11 and 10 are missing leading zeros but should be OK

# Recode officer/civilian race/sex entries
uf$offrace <- ifelse(uf$offrace %in% c('Asian','Other','American Ind'), 'Other', uf$offrace)
uf <- uf[which(uf$civrace %!in% c('Unknown','NULL')),] # Drop if civilian race is not known
uf$civrace <- ifelse(uf$civrace %in% c('Asian','Other','American Ind'), 'Other', uf$civrace)
uf <- uf[which(uf$civsex %!in% c('Unknown')),] # Drop if civilian sex is not known
table(uf$offrace)
table(uf$offsex)

# Identify and drop badges with conflicting information (e.g. one badge with multiple races)
uf <- uf %>% group_by(badge) %>% mutate(inacc.off = ifelse(n_distinct(offrace) > 1 | n_distinct(offsex) > 1, 1, 0)) %>% ungroup()
uf <- uf[which(uf$inacc.off == 0),]

# Separate comma-separated civnums (i.e. multiple civilians listed in one observation as in civnum == "37037, 37038")
df <- uf[which(grepl(',',uf$civnum)),] # Identify rows with comma-separated civnums
df <- df %>%
  separate(civnum, into = c('first','second','third','fourth','fifth','sixth')) %>% # There are at most six civnums in one line
  group_by(first, second, third, fourth, fifth, sixth) %>%
  mutate(civnum = ifelse(row_number() == 1, first, # First number in line corresponds to first row
                         ifelse(row_number() == 2, second, # Second number in line corresponds to second row...
                                ifelse(row_number() == 3, third, 
                                       ifelse(row_number() == 4, fourth, 
                                              ifelse(row_number() == 4, fifth, sixth)))))) %>% ungroup() %>%
  select(c(-first, -second, -third, -fourth, -fifth, -sixth)) # New columns are no longer needed
uf <- uf[-which(grepl(',',uf$civnum)),] # Remove rows with comma-separated civnums from original data
uf <- rbind(uf, df) # rbind corrected rows with original data
rm(df)

# Identify and drop civilians with conflicting information (e.g. one civilian with multiple races)
uf <- uf %>% group_by(civnum) %>% mutate(inacc.civ = ifelse(n_distinct(civrace) > 1 | n_distinct(civsex) > 1, 1, 0)) %>% ungroup()
uf <- uf[which(uf$inacc.civ == 0),]

uf[, c('inacc.off','inacc.civ')] <- list(NULL)

# Check civilian race/sex
table(uf$civrace)
table(uf$civsex)

uf <- uf %>% group_by(iano) %>% mutate(n_forceoffs = n_distinct(badge)) %>% ungroup() # Count officers using force by iano
uf <- uf %>% group_by(iano) %>% mutate(n_forcecivs = n_distinct(civnum)) %>% ungroup() # Count civilians by iano

# Get year, day, hour
uf$year <- substring(uf$date, 1, 4)
uf$month <- substring(uf$date, 6, 7)
uf$day <- substring(uf$date, 9, 10)

# Check that dates look plausible
table(uf$year)
table(uf$month)
table(uf$day)

# Read requested force data
df2013a <- read_excel("Data/Raw/Force_Requested/UOF2013_Redacted_A.xlsx")
df2013b <- read_excel("Data/Raw/Force_Requested/UOF2013_Redacted_B.xlsx")
df2013c <- read_excel("Data/Raw/Force_Requested/UOF2013_Redacted_C.xlsx")
df2014a <- read_excel("Data/Raw/Force_Requested/UOF2014_Redacted_A.xlsx")
df2014b <- read_excel("Data/Raw/Force_Requested/UOF2014_Redacted_B_R.xlsx")
df2015a <- read_excel("Data/Raw/Force_Requested/UOF2015_Redacted_A.xlsx")
df2015b <- read_excel("Data/Raw/Force_Requested/UOF2015_Redacted_B.xlsx")
df2015c <- read_excel("Data/Raw/Force_Requested/UOF2015_Redacted_C.xlsx")
df2016a <- read_excel("Data/Raw/Force_Requested/UOF2016_Redacted_A.xlsx")
df2016b <- read_excel("Data/Raw/Force_Requested/UOF2016_Redacted_B.xlsx")
df2017a <- read_excel("Data/Raw/Force_Requested/UOF2017_Redacted_A_R.xlsx")
df2017b <- read_excel("Data/Raw/Force_Requested/UOF2017_Redacted_B.xlsx")
df2017c <- read_excel("Data/Raw/Force_Requested/UOF2017_Redacted_C.xlsx")
df2018a <- read_excel("Data/Raw/Force_Requested/UOF2018_Redacted_A_R.xlsx")
df2018b <- read_excel("Data/Raw/Force_Requested/UOF2018_Redacted_B_R.xlsx")

# Delete extra columns of NAs
df2014a <- df2014a[,1:12]
df2015a <- df2015a[,1:12]
df2018b <- df2018b[,1:12]

# Combine data sets
uf_req <- rbind(df2013a,df2013b,df2013c,df2014a,df2014b,df2015a,df2015b,df2015c,
            df2016a,df2016b,df2017a,df2017b,df2017c,df2018a,df2018b)

rm(df2013a,df2013b,df2013c,df2014a,df2014b,df2015a,df2015b,df2015c,
   df2016a,df2016b,df2017a,df2017b,df2017c,df2018a,df2018b)

uf_req <- uf_req[which(grepl('/', uf_req$`Received Date`)),] # Delete rows that don't contain actual dates

uf_req$`Received Date` <- as.Date(uf_req$`Received Date`, format = "%m/%d/%y") # Convert date to better format

setnames(uf_req, old = c('Service/Incident Number','IA No','Badge','Received Date'), new = c('incidentnum','iano','badge','rec.date'))

# Merge both force data sets; only need incidentnum from uf_req
uf <- left_join(uf, unique(uf_req[,c('iano','incidentnum')]), by = 'iano')

# Fix some incidentnums; note that incidentnums prior to mid-2014 have a different format
uf$incidentnum <- gsub("[a-zA-Z]", NA, uf$incidentnum)
uf$incidentnum <- gsub("20144", '2014', uf$incidentnum)
uf$incidentnum <- gsub("20107", '2017', uf$incidentnum)
uf$incidentnum <- gsub("20108", '2018', uf$incidentnum)
uf$incidentnum <- gsub("20177", '2017', uf$incidentnum)
uf$incidentnum <- gsub(",", '', uf$incidentnum)
uf$incidentnum <- ifelse(nchar(uf$incidentnum)==12, substr(uf$incidentnum, 2, 12), uf$incidentnum)

# Drop 2013 due to problems with incidentnum
uf <- uf[which(uf$year > 2013),]

# Check numbers of incidents and civilians
uniqueN(uf$iano)
uniqueN(uf$civnum)
nrow(uf)
head(uf)

# Save data
write_csv(uf, 'Data/Clean/force.csv')



