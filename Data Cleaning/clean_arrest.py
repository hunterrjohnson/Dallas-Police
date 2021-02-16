# Set working directory
import os
os.chdir('/Users/hunterjohnson/Dropbox/Dallas Projects/')
os.getcwd()

# Load basic libraries
import pandas as pd
import numpy as np
import seaborn as sns
import matplotlib.pyplot as plt

# Get names of files in Arrest folder
os.listdir('/Users/hunterjohnson/Dropbox/Dallas Projects/Data/Raw/Arrest')

df = pd.read_stata('Data/Raw/Arrest/arrests_request_2010-2018.dta')

# Keep years from 2013-2018
df = df[df['ArrestYr'].isin(['2013','2014','2015','2016','2017','2018'])]
print("Number of arrests: {}\nNumber of rows: {}".format(df['ArrestNumber'].nunique(), len(df)))
print("Number of rows with blank IncidentNum:", len(df.loc[df['IncidentNum']=='']))
print("Arrests per year:\n{}".format(df.ArrestYr.value_counts()))

# Count number of arrested civilians at each incident
df['n_arrested'] = df.groupby('IncidentNum')['ArrestNumber'].transform('nunique')
df['n_arrested'].value_counts()

# Count charges at each arrest
df['n_charges'] = df.groupby('ArrestNumber')['ArrestNumber'].transform('count')
print("Count of number of charges:\n{}".format(df['n_charges'].value_counts()))

# Recode civilian race entries
other = ["Asian","Middle Eastern","American Indian/Native American","Native Hawaiian or Pacific Islander","American Indian"]
df.loc[df.Race.isin(other), 'Race'] = 'other'
df.loc[df.Race == '', 'Race'] = 'Unknown'
df.loc[df.Race.isin(['Latin/Hispanic','Latin']), 'Race'] = 'hispanic'
df = df.loc[df['Race'] != 'TEST']
df.Race = df.Race.str.lower()
df['Race'].value_counts()

# Recode civilian sex entries
df.loc[df.Sex == '', 'Sex'] = 'Unknown'
df = df.loc[df['Sex'] != 'TEST']
df.Sex = df.Sex.str.lower()
df['Sex'].value_counts()

# Flag out of state arrests
df['arrest_outside_TX'] = 0
df.loc[df['ArLState'] != 'TX', 'arrest_outside_TX'] = 1

# String length of 8 implies missing "-"
df.loc[~df.ArrestNumber.str.contains('-'), 'ArrestNumber'] = df['ArrestNumber'].str.slice(0, 2) + '-' + df['ArrestNumber'].str.slice(start=2)

# Manually fix remaining strings
df.loc[df.ArrestNumber.str.contains('0132569-2014'), 'ArrestNumber'] = '14-132569'
df.loc[df.ArrestNumber.str.contains('132224-2014'), 'ArrestNumber'] = '14-132224'
df.loc[df.ArrestNumber.str.contains('132266-2014'), 'ArrestNumber'] = '14-132266'
df.loc[df.ArrestNumber.str.contains('14-23846'), 'ArrestNumber'] = '14-023846'
df.loc[df.ArrestNumber.str.contains('0133117-2014'), 'ArrestNumber'] = '14-133117'
df.loc[df.ArrestNumber.str.contains('14-23847'), 'ArrestNumber'] = '14-023847'
df.loc[df.ArrestNumber.str.contains('133441-2014'), 'ArrestNumber'] = '14-133441'
df.loc[df.ArrestNumber.str.contains('25-564'), 'ArrestNumber'] = '14-002564'

# Check string length of ArrestNumber
df.ArrestNumber.astype(str).apply(len).value_counts()

# Drop columns
df.drop(['H','HLAddress','HLApt','HLZip','HLRA','HLCity','HLState','empty'], axis=1, inplace=True)

# Rename columns
df.rename(columns={'ChargeDesc': 'charge',
                   'ArrestNumber': 'arrestnum',
                   'IncidentNum': 'incidentnum',
                   'ArrestYr': 'arrest_year',
                   'ArArrestDate': 'arrest_date',
                   'ArArrestTime': 'arrest_time',
                   'ArBkDate': 'book_date',
                   'Name': 'civ_name',
                   'Age': 'civ_age',
                   'BirthPlace': 'civ_birthplace',
                   'Race': 'civ_race',
                   'Sex': 'civ_sex',
                   'HLBeat': 'civ_home_beat',
                   'HLDivision': 'civ_home_div',
                   'ArrestLocation': 'arrest_loc',
                   'ArLZip': 'arrest_zip',
                   'ArLCity': 'arrest_city',
                   'ArLState': 'arrest_state',
                   'ArLRA': 'arrest_ra',
                   'ArLBeat': 'arrest_beat',
                   'ArOfCr1': 'arresting_off1',
                   'ArOfCr2': 'arresting_off2',
                   'ArOfCr3': 'arresting_off3',
                   'UCRWord': 'ucr_word',
                   'UCROffense': 'ucr_offense'}, inplace=True)

# Convert column names to lowercase
df.columns= df.columns.str.lower()

# Check string length of ArrestNumber
df.incidentnum.astype(str).apply(len).value_counts()

# Fix incidentnum issues

# Unnecessary whitespace
df.loc[df['incidentnum'].str.len() == 12, 'incidentnum'] = df['incidentnum'].str.replace(' ', '')

# Remove leading zeros
df.loc[df['incidentnum'].str.len() == 12, 'incidentnum'] = df['incidentnum'].str.strip('0')

# NULL incidentnum
df.loc[df['incidentnum'] == "NULL", 'incidentnum'] = ''

# Repeated years
df.loc[df['incidentnum'].str.len() == 16, 'incidentnum'] = df['incidentnum'].str.slice(0,11)

# Manually fix the rest
df.loc[df.incidentnum.str.contains('88255/2014'), 'incidentnum'] = '088255-2014'
df.loc[df.incidentnum.str.contains('133979-204'), 'incidentnum'] = '133979-2014'
df.loc[df.incidentnum.str.contains('01133117-2014'), 'incidentnum'] = '133117-2014'
df.loc[df.incidentnum.str.contains('133619'), 'incidentnum'] = '133619-2014'

# Count blank incidentnums; these presumably cannot merge with dispatch data
print("Number of rows:", len(df))
print("Number of rows where incidentnum is missing:", len(df.loc[df['incidentnum']=='']))
print("Proportion missing:", len(df.loc[df['incidentnum']==''])/len(df))
df = df.loc[df['incidentnum']!='']
print('Number of rows w/ blanks removed:', len(df))

# Note that many arrest_dates are missing but not book dates
df['arrest_date'].isna().sum()
print("Number of blank arrest_dates:", len(df.loc[df['arrest_date'] == '']))
print("Number of blank book_dates:", len(df.loc[df['book_date'] == '']))

# Replace unreasonable ages with missing
df.loc[df['civ_age'] == '408', 'civ_age'] = ''

# Convert book_date to more conventional date format
import datetime as dt
start = dt.datetime(1960,1,1)
df['date'] = start + df['book_date'].astype(int).map(dt.timedelta)
df['year'] = df['date'].dt.strftime('%Y')
df['month'] = df['date'].dt.strftime('%m')
df['day'] = df['date'].dt.strftime('%d')
df.head()

# Reorder columns, dropping some
df = df.reindex(columns=['arrestnum','incidentnum','charge','pclass','ucr_word','ucr_offense',
                         'date','year','month','day','arrest_time','book_date','civ_name','civ_age',
                         'civ_birthplace','civ_race','civ_sex','civ_home_div','civ_home_beat',
                         'arrest_state','arrest_city','arrest_ra','arrest_beat','arrest_zip',
                         'arrest_loc','arresting_off1','arresting_off2','arresting_off3',
                         'n_arrested','n_charges','arrest_outside_tx'])
                         
# Save data
df.to_csv('Data/Clean/arrest.csv')



