# Officer Assignment by Location and Watch

lapply(c('dplyr','haven','data.table','readr','dummies','Rfast','ggplot2'), library, character.only = TRUE)

'%!in%' <- function(x,y){
  !('%in%'(x,y))
}

setwd('/Users/hunterjohnson/Dropbox/Policing- Projects with Dallas')

#===============================================================================

# Read data
dat <- haven::read_dta("2-stata_data/DPD_calls_for_service.dta")
dat$year <- substr(dat$response_date, 1, 4)
dat$month <- substr(dat$response_date, 6, 7)
dat <- dat[dat$year %in% c(2014,2015,2016,2017,2018), ]

# Subset to desired columns
dat <- dat[,c('cfs_off_badge','cfs_sector','month')]

# Get dummies
dat <- cbind(dat, dummy(dat$cfs_sector, sep = "_"))

# Get sums of dat_ columns (division counts) by badge and time
dat <- setDT(dat)[,  lapply(.SD, sum) , by = list(cfs_off_badge, month), .SDcols = grep('dat_', colnames(dat))]

# Get matrix of locations
df <- dat[, grep('dat_', colnames(dat)), with=FALSE]

# Create new data frame for dat_
d_df <- data.frame(matrix(NA, nrow(dat), ncol(df)))
setnames(d_df, old = names(d_df), new = names(df))

# Get the row-wise nth largest value across dat_ columns; store in d_df
for (i in 1:ncol(d_df)) {
  for (j in 1:nrow(dat)) {
    d_df[j,i] <- rownth(as.matrix(dat[j, grep('dat_', colnames(dat)), with=FALSE]), i, descending = TRUE)
  }
}

# Get total calls by officer and time
d_df$dat_total <- rowSums(as.matrix(d_df[, grep('dat_', colnames(d_df)) ]), na.rm = TRUE)

# Join to officers
df <- cbind(dat[,c('cfs_off_badge','month')], d_df)
df <- df[order(df$cfs_off_badge, df$month),]

# Get proportions for each officer
df2 <- data.frame(df2)
df2[cols] <- lapply( df2[grep("^dat_", names(df2))], `/`, df2$dat_total)

props_by_dat <- colMeans(df2[sapply(df2, is.numeric)])

# Put in data frame for plot
ggdf <- data.frame(props_by_dat)
setDT(ggdf, keep.rownames = TRUE)
ggdf$rn <- substr(ggdf$rn, 5, 7)
ggdf$rn <- rownames(ggdf)

# Bar plot
gg_sector <- ggplot(data = ggdf[1:35,], aes(x = reorder(rn, sort(as.numeric(rn))), y = props_by_dat)) +
  geom_bar(stat = 'identity') +
  theme_light() +
  theme(legend.position = 'bottom') +
  labs(title = '',
       x = 'Nth Most Common Sector',
       y = 'Percent of Total Calls') +
  theme(axis.text.x = element_text(angle = 90, vjust = 0.5, hjust=1)) +
  scale_y_continuous(breaks = seq(0, 0.21, .05), limits = c(0, 0.21))
ggsave("z1-logs_results/assignment_sector_month.png", gg_sector, scale = 1.2)

# Write data to dta
#haven::write_dta(df, 'z1-logs_results/assignment_sector_month.dta')



