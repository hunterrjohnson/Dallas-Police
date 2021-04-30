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
df_orig <- fread('1_Data/2_Clean/dispatch.csv')
df_orig$V1 <- NULL

# Read officer demographic data
officers <- fread('1_Data/2_Clean/officers.csv')
officers$badge <- as.character(officers$badge)
officers$off_race_blk <- ifelse(officers$off_race=='BLACK',1,0)
officers$off_race_hsp <- ifelse(officers$off_race=='HISPANIC',1,0)
officers$off_race_wht <- ifelse(officers$off_race=='WHITE',1,0)
officers$off_race_oth <- ifelse(officers$off_race=='OTHER',1,0)
officers$off_gender_fem <- ifelse(officers$off_sex=='FEMALE',1,0)
df_orig <- left_join(df_orig, officers, by='badge')
rm(officers)

# Create shift variable based on date, watch, division
df_orig$watch <- ifelse(df_orig$hour %in% c(0:7), 1, NA)
df_orig$watch <- ifelse(df_orig$hour %in% c(8:15), 2, df_orig$watch)
df_orig$watch <- ifelse(df_orig$hour %in% c(16:23), 3, df_orig$watch)
df_orig <- df_orig %>% mutate(shift = group_indices(., date, watch, division))

#===============================================================================
# CALCULATE AVAILABILITY FOR EACH YEAR INDIVIDUALLY

for (yr in c(2014:2018)) {
  df <- subset(df_orig, df_orig$year == yr)
  
  # Count officers by shift by sex
  setDT(df)[, c('n_shift_male','n_shift_female') :=
              .(sum(off_gender_fem==0, na.rm=T), sum(off_gender_fem==1, na.rm=T)), shift]
  df$n_shift <- df$n_shift_male + df$n_shift_female
  
  # Count unavailable officers by call by sex
  df[, c('n_unavail_male','n_unavail_female') :=
       df[df, on=.(shift, called_min<=called_min, cleared_min>=called_min), allow.cartesian=TRUE,
          by=.EACHI, .(sum(x.off_gender_fem[x.dispatchnum != i.dispatchnum]==0, na.rm=T),
                       sum(x.off_gender_fem[x.dispatchnum != i.dispatchnum]==1, na.rm=T))][,(1L:3L) := NULL]]
  df$n_unavail <- df$n_unavail_female + df$n_unavail_male
  
  # Count officers by shift by race
  setDT(df)[, c('n_shift_blk','n_shift_wht','n_shift_hsp','n_shift_oth') :=
              .(sum(off_race_blk==1, na.rm=T), sum(off_race_wht==1, na.rm=T),
                sum(off_race_hsp==1, na.rm=T), sum(off_race_oth==1, na.rm=T)), shift]
  df$n_shift <- df$n_shift_male + df$n_shift_female
  
  # Count unavailable officers by call by race
  df[, c('n_unavail_blk','n_unavail_wht','n_unavail_hsp','n_unavail_oth') :=
       df[df, on=.(shift, called_min<=called_min, cleared_min>=called_min), allow.cartesian=TRUE,
          by=.EACHI, .(sum(x.off_race_blk[x.dispatchnum != i.dispatchnum]==1, na.rm=T),
                       sum(x.off_race_wht[x.dispatchnum != i.dispatchnum]==1, na.rm=T),
                       sum(x.off_race_hsp[x.dispatchnum != i.dispatchnum]==1, na.rm=T),
                       sum(x.off_race_oth[x.dispatchnum != i.dispatchnum]==1, na.rm=T))][,(1L:3L) := NULL]]
  
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
  df <- unique(df[, c(grep('dispatchnum', colnames(df)),
                      grep('shift', colnames(df)),
                      grep('avail', colnames(df))), with=F])
  print(paste0('Number of Duplicates - ', yr, ':', sum(duplicated(df$dispatchnum))))
  
  # Write csv
  readr::write_csv(df, paste0('1_Data/2_Clean/Availability/',yr,'_availability.csv'))
  
}

#===============================================================================
# JOIN INDIVIDUAL YEARS TOGETHER

list.files()
setwd('/Users/hunterjohnson/Dropbox/Dallas Projects/1_Data/2_Clean/Availability/')
df_avail <- do.call(rbind, lapply(list.files(), data.table::fread))
uniqueN(df_avail$dispatchnum) == nrow(df_avail) # Check that there are no duplicated inc_ids

# Write dta
data.table::fwrite(df_avail, 'availability.csv')



