# Get ACS Data

lapply(c('tigris','acs','sf','raster','dplyr','data.table'), library, character.only = TRUE)

'%!in%' <- function(x,y){
  !('%in%'(x,y))
}

setwd('/Users/hunterjohnson/Dropbox/Dallas Projects')

#===============================================================================

# Read call data and get lat/lons
calls <- data.table::fread("1_Data/2_Clean/dispatch.csv")
calls$V1 <- NULL
calls <- calls[, c('dispatchnum','longitude','latitude')]
calls$longitude <- as.numeric(calls$longitude)
calls$latitude <- as.numeric(calls$latitude)
calls <- unique(calls)
calls <- calls[which(!is.na(calls$longitude)),]
calls <- calls[which(!is.na(calls$latitude)),]

# Write calls
readr::write_csv(calls, '1_Data/1_Raw/Dallas_Blockgroups/calls_latlons.csv')

get_raw_acs <- function(county_num, county_name) {
  
  api.key.install('a96bec964e4ba4c500e72bb55ce34cb098714c23') # Census API key
  
  dat_geo <- geo.make(state = 'TX', county = county_num, tract = '*', block.group = '*')
  dat_bgdata <- acs.fetch(endyear = 2015, span = 5, geography = dat_geo, table.number = c('B02001','B03002','B19013','B15003'))
  dat <- data.frame(dat_bgdata@estimate)
  dat <- dat %>% mutate(state = dat_bgdata@geography$state,
                        county = dat_bgdata@geography$county,
                        tract = dat_bgdata@geography$tract,
                        blockgroup = dat_bgdata@geography$blockgroup)
  # Write raw data to csv
  data.table::fwrite(dat, file = paste0('1_Data/1_Raw/Dallas_Blockgroups/County_Data/',county_name,'_bg_acs_raw.csv'))
  
  # Assign to environment
  assign(paste0(county_name,'_dat'), dat, envir=.GlobalEnv)
  
}

# Get Dallas and all adjacent counties
get_raw_acs(county_num = 113, county_name = 'dallas')
get_raw_acs(county_num = 85, county_name = 'collin')
get_raw_acs(county_num = 397, county_name = 'rockwall')
get_raw_acs(county_num = 257, county_name = 'kaufman')
get_raw_acs(county_num = 139, county_name = 'ellis')
get_raw_acs(county_num = 251, county_name = 'johnson')
get_raw_acs(county_num = 439, county_name = 'tarrant')
get_raw_acs(county_num = 121, county_name = 'denton')

dat <- rbind(dallas_dat, collin_dat, rockwall_dat, kaufman_dat, ellis_dat, johnson_dat, tarrant_dat, denton_dat)
rm(list=setdiff(ls(), c('dat','calls')))

# Write raw data to csv
readr::write_csv(dat, '1_Data/1_Raw/Dallas_Blockgroups/dallas_bg_acs_raw.csv')

# Rename variables
# - B02001_002: white alone
# - B02001_003: black alone
# - B02001_004 through 007: other alone
# - B03002_012: Hispanic
setnames(dat, old = c('B02001_002','B02001_003','B02001_004','B03002_012','B19013_001'),
         new = c('white','black','other','hispanic','medhhinc'))

# Count up all types of other
dat$other <- dat$other + dat$B02001_005 + dat$B02001_006 + dat$B02001_007

# Calculate proportion with less than HS degree
educ_vars <- c('B15003_002','B15003_003','B15003_004','B15003_005','B15003_006','B15003_007','B15003_008','B15003_009',
               'B15003_010','B15003_011','B15003_012','B15003_013','B15003_014','B15003_015','B15003_016')
dat$lessthanhs <- apply(dat[educ_vars], 1, sum) # Total with less than HS degree
dat$lessthanhs <- dat$lessthanhs / dat$B15003_001
summary(dat$lessthanhs)

# Remove extra columns
dat <- dat[, -which(grepl('_', colnames(dat)))]

# Get shapefile for Dallas block groups
dallas_shp <- tigris::block_groups(state = 'Texas', county = 113, year = 2015)
collin_shp <- tigris::block_groups(state = 'Texas', county = 85, year = 2015)
rockwall_shp <- tigris::block_groups(state = 'Texas', county = 397, year = 2015)
kaufman_shp <- tigris::block_groups(state = 'Texas', county = 257, year = 2015)
ellis_shp <- tigris::block_groups(state = 'Texas', county = 139, year = 2015)
johnson_shp <- tigris::block_groups(state = 'Texas', county = 251, year = 2015)
tarrant_shp <- tigris::block_groups(state = 'Texas', county = 439, year = 2015)
denton_shp <- tigris::block_groups(state = 'Texas', county = 121, year = 2015)
dallas_shp <- rbind(dallas_shp, collin_shp, rockwall_shp, kaufman_shp,
                    ellis_shp, johnson_shp, tarrant_shp, denton_shp)
rm(list=setdiff(ls(), c('dallas_shp','dat','calls')))

# Need to make sure tracts in both data sets can merge
summary(nchar(dallas_shp$TRACTCE))
summary(nchar(dat$tract))

# Write shapefile
shapefile(as_Spatial(st_as_sf(dallas_shp)), filename = '1_Data/1_Raw/Dallas_Blockgroups/dallas_bg_shapefile.shp', overwrite = TRUE)

# Add leading zeros to df tract for merge with dallas_shp
dat$tract <- ifelse(nchar(dat$tract) == 3, paste0('000', dat$tract),
                    ifelse(nchar(dat$tract) == 4, paste0('00', dat$tract),
                           ifelse(nchar(dat$tract) == 5, paste0('0', dat$tract), dat$tract)))

# Now all tracts can merge with shapefile geometry
length(which(dat$tract %in% dallas_shp$TRACTCE))

# Join geometry to df
dallas_shp <- st_as_sf(dallas_shp)
dat$county <- ifelse(dat$county==85, '085', as.character(dat$county))
dat$GEOID <- paste0(dat$state, dat$county, dat$tract, dat$blockgroup) # Get GEOID variable in common for merge
length(which(dat$GEOID %in% dallas_shp$GEOID))
df <- left_join(dat, dallas_shp[, c('GEOID')], by = 'GEOID')

# Calculate proportions
df <- df %>% mutate(bg_prop_white = white / (white + black + hispanic + other),
                    bg_prop_black = black / (white + black + hispanic + other),
                    bg_prop_hisp = hispanic / (white + black + hispanic + other),
                    bg_prop_other = other / (white + black + hispanic + other))

# Reorder columns
df <- df[,c(11,6,7,8,9,1,2,3,4,5,10,13,14,15,16,12)]

rm(list=setdiff(ls(), c('df','calls')))

# Get coordinates for spatial join
calls <- st_as_sf(calls, coords = c('longitude','latitude'), remove = FALSE, crs = 4326)

# Merge blockgroup data to calls by spatial join
calls <- st_join(calls, left=TRUE, st_as_sf(df, crs=4326))

# Check number of rows with missing block group data
nrow(calls[which(is.na(calls$GEOID)),]) / nrow(calls)

calls$geometry <- NULL

# Assume calls assigned to multiple blockgroups are in most populous one
calls$pop <- calls$white+calls$black+calls$hispanic+calls$other # population total
calls <- calls %>% group_by(dispatchnum) %>% mutate(maxpop = max(pop)) %>% ungroup()
calls <- calls[which(calls$maxpop==calls$pop),]

# Write clean block group data
data.table::fwrite(calls, '1_Data/2_Clean/blockgroups.csv')



