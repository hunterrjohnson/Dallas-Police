# Merge data, finalize features, collapse to call level

lapply(c('data.table','dplyr'), library, character.only = TRUE)

setwd('/Users/hunterjohnson/Dropbox/Dallas Projects')

#===============================================================================

# Read dispatch
dispatch <- fread('1_Data/2_Clean/dispatch.csv')
dispatch$V1 <- NULL

# Merge blockgroup data
blockgroups <- fread('1_Data/2_Clean/blockgroups.csv')
blockgroups$pop <- blockgroups$white+blockgroups$black+blockgroups$hispanic+blockgroups$other # population total
blockgroups <- blockgroups %>% group_by(dispatchnum) %>% mutate(maxpop = max(pop)) %>% ungroup()
blockgroups <- blockgroups[which(blockgroups$maxpop==blockgroups$pop),] # assume calls w/ multiple blockgroups are in most populous one
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

rm(dispatch, blockgroups, arrest, force)

# Define remaining features
# - all variables should be call level (i.e. dispatchnum is unique ID)
df$reported_inc <- ifelse(df$incidentnum!='nan', 1, 0)
df$n_arrested <- ifelse(is.na(df$n_arrested), 0, df$n_arrested)
df$force_used <- ifelse(is.na(df$force_used), 0, df$force_used)
df <- df %>% group_by(dispatchnum) %>% mutate(reported_inc = max(reported_inc),
                                              n_arrested = max(n_arrested),
                                              md_dispatch = mean(md_dispatch),
                                              off_initiated = mean(off_initiated),
                                              markout = mean(markout),
                                              force_used = max(force_used)) %>% ungroup()

# Collapse to call level
keep_cols <- c('dispatchnum','reported_inc','date','year','month','day','hour','problem','priority',
               'incident_type','off_initiated','markout','division','ra','sector','beat','latitude',
               'longitude','shelter_loc','loc_freq','n_units','n_offs','called_min','md_dispatch',
               'medhhinc','lessthanhs','bg_prop_white','bg_prop_black','bg_prop_hisp',
               'bg_prop_other','n_arrested','force_used')
df <- unique(df[, colnames(df) %in% keep_cols])
df <- df[, c(1,32,2:31)] # Move last column to second

# Check that level of observation is dispatchnum
uniqueN(df$dispatchnum) == nrow(df)

# Write data
readr::write_csv(df, file = '1_Data/2_Clean/analysis.csv')



