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
os.listdir('/Users/hunterjohnson/Dropbox/Dallas Projects/1_Data/1_Raw/Arrest')

df = pd.read_csv('1_Data/1_Raw/Arrest/Police_Arrests_7_19_19.csv')

# Keep years from 2014-2018
df = df[df['ArrestYr'].isin(['2014','2015','2016','2017','2018'])]
print("Number of arrests: {}\nNumber of rows: {}".format(df['ArrestNumber'].nunique(), len(df)))
print("Number of rows with blank IncidentNum:", len(df.loc[df['IncidentNum']=='']))
print("Arrests per year:\n{}".format(df.ArrestYr.value_counts()))

# Count number of arrested civilians at each incident
df['n_arrested'] = df.groupby('IncidentNum')['ArrestNumber'].transform('nunique')
df['n_arrested'].value_counts()
print("Count of number arrested:\n{}".format(df['n_arrested'].value_counts()))

# Recode civilian race entries
other = ["Asian","Middle Eastern","American Indian or Alaska Native","Native Hawaiian/Pacific Islander"]
df.loc[df.Race.isin(other), 'Race'] = 'other'
df.loc[df.Race == '', 'Race'] = 'Unknown'
df.loc[df.Race.isin(['Hispanic or Latino']), 'Race'] = 'hispanic'
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
df.loc[~df['ArState'].isin(['','TX']), 'arrest_outside_TX'] = 1
df['arrest_outside_TX'].value_counts()

# Check string length of ArrestNumber (a trivial amount appear to be wrong, but this should not matter)
df.ArrestNumber.astype(str).apply(len).value_counts()

# Check string length of IncidentNum (these matter for merge)
df.IncidentNum.astype(str).apply(len).value_counts()

# Remove leading zeros in IncidentNum
df.loc[df['IncidentNum'].str.len() == 12, 'IncidentNum'] = df['IncidentNum'].str.strip('0')

# Manually fix the rest if possible; a trivial amount will not get fixed
df.loc[df['IncidentNum'].str.contains('133979-204'), 'IncidentNum'] = '133979-2014'
df.loc[df['IncidentNum'].str.contains('88255/2014'), 'IncidentNum'] = '088255-2014'
df.loc[df['IncidentNum'].str.contains('126509 -2017'), 'IncidentNum'] = '126509-2017'
df.loc[df['IncidentNum'].str.match('133619'), 'IncidentNum'] = '133619-2014'

# Check that ArArrestDate is in standard form
df.ArArrestDate.astype(str).apply(len).value_counts()

# Check that ArArrestTime is in standard form
df.ArArrestTime.astype(str).apply(len).value_counts()

# Drop time from ArArrestDate
df['ArArrestDate'] = df['ArArrestDate'].str.slice(0,10)

# Get year, month, day, hour
df['year'] = df['ArArrestDate'].str.slice(6,10)
df['month'] = df['ArArrestDate'].str.slice(0,2)
df['day'] = df['ArArrestDate'].str.slice(3,5)
df['hour'] = df['ArArrestTime'].str.slice(0,2)

# Fix unreasonable values for AgeAtArrestTime
df.loc[df['AgeAtArrestTime'] == 408.0, 'AgeAtArrestTime'] = ''
df.loc[df['AgeAtArrestTime'] == 108.0, 'AgeAtArrestTime'] = ''
df['AgeAtArrestTime'].value_counts()

# Rename columns
df.rename(columns={'IncidentNum': 'incidentnum',
                   'ArrestNumber': 'arrestnum',
                   'ArrestYr': 'arrest_year',
                   'ArArrestDate': 'arrest_date',
                   'ArArrestTime': 'arrest_time',
                   'ArBkDate': 'book_date',
                   'ArresteeName': 'civ_name',
                   'AgeAtArrestTime': 'civ_age',
                   'BirthPlace': 'civ_birthplace',
                   'Race': 'civ_race',
                   'Sex': 'civ_sex',
                   'HBeat': 'civ_home_beat',
                   'ArLAddress': 'arrest_loc',
                   'ArLZip': 'arrest_zip',
                   'ArLCity': 'arrest_city',
                   'ArState': 'arrest_state',
                   'ArLRA': 'arrest_ra',
                   'ArLBeat': 'arrest_beat',
                   'ArOfcr1': 'arresting_off1',
                   'ArOfcr2': 'arresting_off2',
                   'ArADOW': 'arrest_dow',
                   'ArPremises': 'arrest_premises',
                   'ArWeapon': 'arrest_weapon'}, inplace=True)

# Convert column names to lowercase
df.columns = df.columns.str.lower()

# Reorder columns, dropping some
df = df.reindex(columns=['incidentnum','arrestnum','arrest_year','arrest_date','arrest_time','arrest_dow',
                         'year','month','day','hour','civ_name','civ_age','civ_birthplace','civ_race','civ_sex',
                         'civ_home_beat','arrest_loc','arrest_zip','arrest_city','arrest_state',
                         'arrest_outside_tx','arrest_ra','arrest_beat','arresting_off1','arresting_off2',
                         'arrest_premises','arrest_weapon','n_arrested'])

# Reformat arrest date
df['arrest_date'] = df['arrest_date'].str.slice(0,2)+'-'+df['arrest_date'].str.slice(3,5)+'-'+df['arrest_date'].str.slice(6,10)

# Convert to integer
df['arrest_zip'] = df['arrest_zip'].astype('Int64')
df['arrest_ra'] = df['arrest_ra'].astype('Int64')
df['arrest_beat'] = df['arrest_beat'].astype('Int64')

# Convert to uppercase
df['civ_race'] = df['civ_race'].str.upper()
df['civ_sex'] = df['civ_sex'].str.upper()
df['arrest_premises'] = df['arrest_premises'].str.upper()
df['arrest_weapon'] = df['arrest_weapon'].str.upper()
                         
# Save data
df.to_csv('1_Data/2_Clean/arrest.csv')



