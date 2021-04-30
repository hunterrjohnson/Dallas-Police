# Clean officer demographic data

lapply(c('dplyr','data.table'), library, character.only = TRUE)

'%!in%' <- function(x,y){
  !('%in%'(x,y))
}

setwd('/Users/hunterjohnson/Dropbox/Dallas Projects')

#===============================================================================

officer1 <- readxl::read_xlsx('1_Data/1_Raw/Officers/D001438.xlsx')
officer1 <- unique(officer1[,c('badge','race','sex')])
officer1 <- officer1[which(!is.na(officer1$badge)),]
setnames(officer1, old=c('badge','race','sex'), new=c('badge','off_race','off_sex'))
officer1$off_race <- ifelse(officer1$off_race %in% c('Native American','Asian','Other'), 'OTHER', officer1$off_race)
officer1$off_race <- ifelse(officer1$off_race=='White', 'WHITE', officer1$off_race)
officer1$off_race <- ifelse(officer1$off_race=='Black', 'BLACK', officer1$off_race)
officer1$off_race <- ifelse(officer1$off_race=='Hispanic', 'HISPANIC', officer1$off_race)
officer1$off_sex <- toupper(officer1$off_sex)

officer2 <- readxl::read_xlsx('1_Data/1_Raw/Officers/Police_PersonnelRecords_Complete_2.xlsx')
officer2 <- unique(officer2[,c('Badge Number','Ethnicity','Gender')])
setnames(officer2, old=c('Badge Number','Ethnicity','Gender'), new=c('badge','off_race','off_sex'))
officer2$off_race <- ifelse(officer2$off_race %in% c('CUBA','MEXA','PUER','SPAN'), 'HISPANIC', officer2$off_race)
officer2$off_race <- ifelse(officer2$off_race=='BLK', 'BLACK', officer2$off_race)
officer2$off_race <- ifelse(officer2$off_race=='WHT', 'WHITE', officer2$off_race)
officer2$off_race <- ifelse(officer2$off_race %!in% c('WHITE','BLACK','HISPANIC'), 'OTHER', officer2$off_race)
officer2$off_sex <- ifelse(officer2$off_sex=='M', 'MALE', officer2$off_sex)
officer2$off_sex <- ifelse(officer2$off_sex=='F', 'FEMALE', officer2$off_sex)
officer2 <- officer2[which(officer2$badge!='NA'),]

extra_offs <- officer2[which(officer2$badge %!in% officer1$badge),]
total_offs <- rbind(officer1, extra_offs)
sum(duplicated(total_offs$badge))

data.table::fwrite(total_offs, '1_Data/2_Clean/officers.csv')



