# Get ACS Data

lapply(c('tigris','acs','sf','raster'), library, character.only = TRUE)

'%!in%' <- function(x,y){
  !('%in%'(x,y))
}

setwd('/Users/hunterjohnson/Dropbox/Dallas Police CJL')

#===============================================================================

# Read call data and get lat/lons
calls <- haven::read_dta("2-stata_data/DPD_calls_for_service.dta")
calls <- calls[, c('inc_id','cfs_lon','cfs_lat')]
calls <- unique(calls)
calls <- calls[which(!is.na(calls$cfs_lon)),]
calls <- calls[which(!is.na(calls$cfs_lat)),]

# Write calls
readr::write_csv(calls, '1-raw_data/Dallas_Blockgroups/calls_latlons.csv')

api.key.install('a96bec964e4ba4c500e72bb55ce34cb098714c23') # Census API key
dallas_geo <- geo.make(state = 'TX', county = 'Dallas', tract = '*', block.group = '*') # geo.make required to retrieve data

# Retrieve block group data for Dallas County for 2015 from ACS 5-year survey
# - B02001: Race table
# - B03002: Hispanic/Latino table
# - B19013: Median household income
# - B15003: Educational attainment
dallas_bgdata <- acs.fetch(endyear = 2015, span = 5, geography = dallas_geo, table.number = c('B02001','B03002','B19013','B15003'))

# Clean up data
dat <- data.frame(dallas_bgdata@estimate)
dat <- dat %>% mutate(state = dallas_bgdata@geography$state,
                      county = dallas_bgdata@geography$county,
                      tract = dallas_bgdata@geography$tract,
                      blockgroup = dallas_bgdata@geography$blockgroup)

# Write raw data to csv
readr::write_csv(dat, '1-raw_data/Dallas_Blockgroups/dallas_bg_acs_raw.csv')

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
dallas_shp <- tigris::block_groups(state = 'Texas', county = 'Dallas', year = 2015)
summary(nchar(dallas_shp$TRACTCE))
summary(nchar(dat$tract))

# Write shapefile
shapefile(as_Spatial(st_as_sf(dallas_shp)), filename = '1-raw_data/Dallas_Blockgroups/dallas_bg_shapefile.shp', overwrite = TRUE)

# Add leading zeros to df tract for merge with dallas_shp
dat$tract <- ifelse(nchar(dat$tract) == 3, paste0('000', dat$tract),
                    ifelse(nchar(dat$tract) == 4, paste0('00', dat$tract),
                           ifelse(nchar(dat$tract) == 5, paste0('0', dat$tract), dat$tract)))

# Now all tracts can merge with shapefile geometry
length(which(dat$tract %in% dallas_shp$TRACTCE))

# Join geometry to df
dallas_shp <- st_as_sf(dallas_shp)
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

rm(dallas_bgdata, dallas_geo, dallas_shp, dat)

setnames(calls, old = c('cfs_lon','cfs_lat'), new = c('longitude','latitude'))
calls$longitude <- paste0('-', calls$longitude) # Add negative sign to longitude
calls <- st_as_sf(calls, coords = c('longitude','latitude'), remove = FALSE, crs = 4326) # Get coordinates for spatial join

# Merge blockgroup data to calls by spatial join
calls <- st_join(calls, left=TRUE, st_as_sf(df, crs=4326))

# Check number of rows with missing block group data
nrow(calls[which(is.na(calls$GEOID)),]) / nrow(calls)

# Write clean block group data
calls$geometry <- NULL
haven::write_dta(calls, '2-stata_data/DPD_blockgroups.dta')



