# Merge data, finalize features, collapse to call level

lapply(c('data.table','dplyr'), library, character.only = TRUE)

'%!in%' <- function(x,y){
  !('%in%'(x,y))
}

setwd('/Users/hunterjohnson/Dropbox/Dallas Projects')

#===============================================================================

# Read dispatch
dispatch <- fread('1_Data/2_Clean/dispatch.csv')
dispatch$V1 <- NULL

# Merge blockgroup data
blockgroups <- fread('1_Data/2_Clean/blockgroups.csv')
df <- left_join(dispatch, blockgroups[, c('dispatchnum','GEOID','medhhinc',
                                          'lessthanhs','bg_prop_white','bg_prop_black',
                                          'bg_prop_hisp','bg_prop_other')], by='dispatchnum')

# Merge arrest data
arrest <- fread('1_Data/2_Clean/arrest.csv')
arrest <- unique(arrest[, c('incidentnum','n_arrested')])
df <- left_join(df, arrest[, c('incidentnum','n_arrested')], by='incidentnum')

# Merge force data
force <- fread('1_Data/2_Clean/force.csv')
force$force_used <- 1
force <- unique(force[, c('incidentnum','force_used')]) # keep only an indicator for use of force
df <- left_join(df, force, by='incidentnum')

# Merge officer personnel data
officers <- fread('1_Data/2_Clean/officers.csv')
officers$badge <- as.character(officers$badge)
df <- left_join(df, officers, by='badge')

# Merge availability instrument
avail <- fread('1_Data/2_Clean/availability.csv')
df <- left_join(df, avail[, c(grep('dispatchnum', colnames(avail)),
                              grep('avail_rate', colnames(avail))), with=F], by='dispatchnum')

rm(avail, dispatch, blockgroups, arrest, force, officers)

# Define remaining features
# - all variables should be call level (i.e. dispatchnum is unique ID)
df$reported_inc <- ifelse(df$incidentnum!='nan', 1, 0)
df$n_arrested <- ifelse(is.na(df$n_arrested), 0, df$n_arrested)
df$force_used <- ifelse(is.na(df$force_used), 0, df$force_used)
df <- df %>% group_by(dispatchnum) %>% mutate(reported_inc = max(reported_inc),
                                              n_arrested = max(n_arrested),
                                              arrest = ifelse(n_arrested>0, 1, 0),
                                              force_used = max(force_used)) %>% ungroup()

# Reorder columns
df <- df[, c(1:24,42:48,25:26,51:52,27:41,53:59,60:61,49:50)]

# Write data
fwrite(df, '1_Data/2_Clean/analysis.csv')
haven::write_dta(df, '1_Data/2_Clean/analysis.dta')


