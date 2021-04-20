# Dallas Use of Force - Availability Instrument

# Packages used
lapply(c('dplyr','haven','stringr','data.table'), library, character.only = TRUE)

# Useful function to determine if something is in a set
'%!in%' <- function(x,y){
  !('%in%'(x,y))
}

setwd('/Users/hunterjohnson/Dropbox/Dallas Projects/')

#===============================================================================
# READ AND MODIFY ORIGINAL DATA FRAME

# Read calls for service data
df_orig <- haven::read_dta('1_Data/2_Clean/sample_for_availability.dta')

# Drop if inc_id is missing
df_orig <- df_orig[which(df_orig$inc_id != ''), ]

# Read officer demographic data
setwd('/Users/hunterjohnson/Dropbox/Dallas Police CJL/')
officers <- haven::read_dta('2-stata_data/DPD_officer_personel.dta')
setwd('/Users/hunterjohnson/Dropbox/Dallas Projects/')
df_orig <- left_join(df_orig, officers[,c('cfs_off_badge','off_gender_fem','off_race_wht',
                                          'off_race_blk','off_race_hsp','off_race_oth')], by='cfs_off_badge')

# Create shift variable based on date, watch, division
df_orig <- df_orig %>% mutate(shift = group_indices(., response_date, watch, cfs_division))

# Break down one year at a time due to vector memory error
df_orig$cfs_year <- substr(df_orig$response_date, 1, 4)

#===============================================================================
# CALCULATE AVAILABILITY FOR EACH YEAR INDIVIDUALLY

for (year in c(2009:2019)) {
  df <- subset(df_orig, df_orig$cfs_year == year)
  
  # Count officers by shift by sex
  setDT(df)[, c('n_shift_male','n_shift_female') :=
              .(sum(off_gender_fem==0, na.rm=T), sum(off_gender_fem==1, na.rm=T)), shift]
  df$n_shift <- df$n_shift_male + df$n_shift_female
  
  # Count unavailable officers by call by sex
  df[, c('n_unavail_male','n_unavail_female') :=
       df[df, on=.(shift, calledmin<=calledmin, clearedmin>=calledmin), allow.cartesian=TRUE,
          by=.EACHI, .(sum(x.off_gender_fem[x.inc_id != i.inc_id]==0, na.rm=T),
                       sum(x.off_gender_fem[x.inc_id != i.inc_id]==1, na.rm=T))][,(1L:3L) := NULL]]
  df$n_unavail <- df$n_unavail_female + df$n_unavail_male
  
  # Count officers by shift by race
  setDT(df)[, c('n_shift_blk','n_shift_wht','n_shift_hsp','n_shift_oth') :=
              .(sum(off_race_blk==1, na.rm=T), sum(off_race_wht==1, na.rm=T),
                sum(off_race_hsp==1, na.rm=T), sum(off_race_oth==1, na.rm=T)), shift]
  df$n_shift <- df$n_shift_male + df$n_shift_female
  
  # Count unavailable officers by call by race
  df[, c('n_unavail_blk','n_unavail_wht','n_unavail_hsp','n_unavail_oth') :=
       df[df, on=.(shift, calledmin<=calledmin, clearedmin>=calledmin), allow.cartesian=TRUE,
          by=.EACHI, .(sum(x.off_race_blk[x.inc_id != i.inc_id]==1, na.rm=T),
                       sum(x.off_race_wht[x.inc_id != i.inc_id]==1, na.rm=T),
                       sum(x.off_race_hsp[x.inc_id != i.inc_id]==1, na.rm=T),
                       sum(x.off_race_oth[x.inc_id != i.inc_id]==1, na.rm=T))][,(1L:3L) := NULL]]
  
  # Count available officers
  df <- df %>% mutate(n_avail = (n_shift - n_unavail_male - n_unavail_female),
                      n_avail_male = (n_shift_male - n_unavail_male),
                      n_avail_female = (n_shift_female - n_unavail_female),
                      n_avail_blk = (n_shift_blk - n_unavail_blk),
                      n_avail_wht = (n_shift_wht - n_unavail_wht),
                      n_avail_hsp = (n_shift_hsp - n_unavail_hsp),
                      n_avail_oth = (n_shift_oth - n_unavail_oth))
  
  # Calculate availability rate
  df <- df %>% mutate(avail_rate = n_avail / n_shift,
                      avail_rate_male = n_avail_male / n_avail,
                      avail_rate_female = n_avail_female / n_avail,
                      avail_rate_wht = n_avail_wht / n_avail,
                      avail_rate_blk = n_avail_blk / n_avail,
                      avail_rate_hsp = n_avail_hsp / n_avail,
                      avail_rate_oth = n_avail_oth / n_avail)
  
  summary(df$avail_rate, na.rm = T)
  summary(df$avail_rate_male, na.rm = T)
  summary(df$avail_rate_female, na.rm = T)
  summary(df$avail_rate_wht, na.rm = T)
  summary(df$avail_rate_blk, na.rm = T)
  summary(df$avail_rate_hsp, na.rm = T)
  summary(df$avail_rate_oth, na.rm = T)
  
  # Subset to desired columns
  df <- unique(df[, c(grep('inc_id', colnames(df)),
                      grep('shift', colnames(df)),
                      grep('avail', colnames(df))), with=F])
  print(paste0('Number of Duplicates - ', year, ':', sum(duplicated(df$inc_id))))
  
  # Write csv
  readr::write_csv(df, paste0('1_Data/2_Clean/Availability/',year,'_availability.csv'))

}

df$duplicate <- ifelse(duplicated(df$inc_id), 1, 0)

#===============================================================================
# MERGE INDIVIDUAL YEARS TOGETHER (NOT 2019 DUE TO DUPLICATES)

list.files()
setwd('/Users/hunterjohnson/Dropbox/Dallas Projects/1_Data/2_Clean/Availability/')
df_avail <- do.call(rbind, lapply(list.files(), data.table::fread))
uniqueN(df_avail$inc_id) == nrow(df_avail) # Check that there are no duplicated inc_ids

# Write dta
haven::write_dta(df_avail, 'DPD_availability.dta')



