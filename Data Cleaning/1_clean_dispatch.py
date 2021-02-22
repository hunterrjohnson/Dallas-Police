# Set working directory
import os
os.chdir('/Users/hunterjohnson/Dropbox/Dallas Projects/')
os.getcwd()

# Load basic libraries
import pandas as pd
import numpy as np
import seaborn as sns
import matplotlib.pyplot as plt

# Get names of files in dispatch folder
os.listdir('/Users/hunterjohnson/Dropbox/Dallas Projects/Data/Raw/Dispatch')

# Get file names for years 2013-2018
from glob import glob
files = glob('/Users/hunterjohnson/Dropbox/Dallas Projects/Data/Raw/Dispatch/201[3-8]_CALLS_?.csv')
files

# Read dispatch files into data frame
df = pd.concat([pd.read_csv(fname) for fname in files], ignore_index=True)

print("df is a {} with {} rows and {} columns".format(type(df), len(df), len(df.columns)))
print("\nColumn names: \n", df.columns) # column names for reference

# Clean up Division entries
print(df['Division'].value_counts(dropna=False))
print("\nNumber of NaNs in Division: ", df.Division.isna().sum())
df = df[df.Division != 'Jack Evans HQ Bldg'] # remove strange entries for Division
df = df[df.Division != 'Homeland Security']
df = df[df.Division != 'Traffic']
df = df[df['Division'].notna()] # drop trivial number with missing Division

# Fix Sector entries
print("Values of Sector: ", df['Sector'].unique())
df = df[df.Sector != 'NorthCentral'] # remove incorrect entry for Sector
print("\nNumber of NaNs in Sector", df.Sector.isna().sum()) # NaNs shouldn't matter since there are other location variables

print("Number of Beats: ", len(df.Beat.unique()))
print("\nNumber of NaNs in Beat", df.Beat.isna().sum())

# Identify homeless shelters
df['Address'] = df['Address'].str.upper()
df['shelter_loc'] = 0
shelter_locs = ["HOMELESS","4636 ROSS","1818 CORSICANA","1100 CADIZ","4411 LEMMON",
               "3211 IRVING","4311 BRYAN","922 PARK","2929 HICKORY ST","1822 YOUNG ST",
               "408 PARK","5302 HARRY HINES","3211 IRVING BLVD"]
df.loc[df.Address.isin(shelter_locs), 'shelter_loc'] = 1
df.loc[df.Address.str.contains('402') & df.Address.str.contains('GOOD LATIMER'), 'shelter_loc'] = 1
df.loc[df.Address.str.contains('233') & df.Address.str.contains('10TH'), 'shelter_loc'] = 1
df.loc[df.Address.str.contains('2706') & df.Address.str.contains('2ND'), 'shelter_loc'] = 1
df.loc[df.Address.str.contains('711') & df.Address.str.contains('PAUL'), 'shelter_loc'] = 1
df.loc[df.Address.str.contains('224') & df.Address.str.contains('PAGE'), 'shelter_loc'] = 1

print("Number of observations at shelter location:", df['shelter_loc'].sum())

# Identify location frequency
df['loc_freq'] = df.groupby(by='Address')['Address'].transform('count')
np.set_printoptions(suppress=True)
print("Location Frequency Deciles:\n{}".format(np.percentile(df.Address.value_counts(), np.linspace(0,100,11))))

import datetime

# Rename column
df.rename(columns={'Fixed_Time_CallEnteredQueue': 'Time_Called'}, inplace=True)

# Get string length of Time_Cleared
df['tc_str_len'] = df.Time_Cleared.astype(str).apply(len)

# String lengths of 4 and 5 need to have response date added
df['tc_str_len'].value_counts()

# Fix Time_Cleared format
df.loc[df['tc_str_len'].isin([4,5]), 'Time_Cleared'] = df['Response Date'] + ' ' + df['Time_Cleared']

# Convert times to datetime
for column in df[['Time_Called','Time_Assigned','Time_Enroute','Time_Arrived','Time_Cleared']]:
    df[column] = df[column].str.replace(' AM', 'AM')
    df[column] = df[column].str.replace(' PM', 'PM')
    try:
        df[column] = pd.to_datetime(df[column], format = "%m/%d/%y %I:%M%p")
    except:
        df[column] = pd.to_datetime(df[column], format = "%m/%d/%y %H:%M", exact=False)
df['Response Date'] = pd.to_datetime(df['Response Date'], format = "%m/%d/%y")

# Get year, month, day based on Response Date
df['year'] = df['Response Date'].dt.strftime('%Y')
df['month'] = df['Response Date'].dt.strftime('%m')
df['day'] = df['Response Date'].dt.strftime('%d')
df['hour'] = df['Time_Called'].dt.strftime('%H') # Use Time_Called for hour since Response Date has date only

# Convert time variables to minutes since Jan. 1, 1960
df['called_min'] = ((df.Time_Called - pd.to_datetime('1960-01-01')).dt.total_seconds() / 60).astype(int)
df['assigned_min'] = ((df.Time_Assigned - pd.to_datetime('1960-01-01')).dt.total_seconds() / 60).astype(int)
df['enroute_min'] = ((df.Time_Enroute - pd.to_datetime('1960-01-01')).dt.total_seconds() / 60).astype('Int64')
df['arrived_min'] = ((df.Time_Arrived - pd.to_datetime('1960-01-01')).dt.total_seconds() / 60).astype('Int64')
df['cleared_min'] = ((df.Time_Cleared - pd.to_datetime('1960-01-01')).dt.total_seconds() / 60).astype('Int64')

# Calculate minute difference between call and dispatch
df['md_dispatch'] = df['Time_Assigned'] - df['Time_Called']

# Some time differences are negative or far too long
print("Minimum time between call and dispatch:", df['md_dispatch'].min())
print("Maximum time between call and dispatch:", df['md_dispatch'].max())
print("99.9th percentile of time between call and dispatch:", df['md_dispatch'].quantile(.999))
print("Number of negative time differences:", len(df[df['md_dispatch'] < datetime.timedelta(minutes=0)]))
print("Number of time differences > 99.9th percentile:", len(df[df['md_dispatch'] > datetime.timedelta(hours=11, minutes=27, seconds=30)]))

# Flag negative time differences or time differences > 99.9th percentile
df['md_dispatch_flag'] = 0
df.loc[df['md_dispatch'] < datetime.timedelta(minutes=0), 'md_dispatch_flag'] = 1
df.loc[df['md_dispatch'] > datetime.timedelta(hours=12, minutes=0, seconds=0), 'md_dispatch_flag'] = 1
print("Number of flagged time differences:", df['md_dispatch_flag'].sum())

# Standard format is similar to 123456-2014 (length 11)
df['new_cn'] = df['Case_Number']
df['new_cn'].str.len().value_counts()

# Remove leading zeros if string length is 12
df.loc[df['new_cn'].str.len() == 12, 'new_cn'] = df['new_cn'].str.strip('0')

# Add hyphen and year if string length is 6
df.loc[df['new_cn'].str.len() == 6, 'new_cn'] = df['new_cn'].astype(str) + '-' + df['year'].astype(str)

# Add leading 0, hyphen and year if string length is 5
df.loc[df['new_cn'].str.len() == 5, 'new_cn'] = '0' + df['new_cn'].astype(str) + '-' + df['year'].astype(str)

# Count observations with missing Inc_num; drop these
print("Number of missing dispatch numbers:", df.Inc_num.isna().sum())
df = df[df['Inc_num'].notna()]

# Remove duplicated rows (e.g. same officer appears twice for one call)
print("Number of duplicated rows:", df.duplicated().sum())
df = df[df.duplicated() == False]

# Identify officer-initiated responses
df['Problem'] = df['Problem'].str.upper()
df["off_initiated"] = 0
off_inits = ["BCA - BAIT CAR ACTIVATION","15 - ASSIST OFFICER","15A - ASSIST OFFICER W/AMB",
             "76 - WARRANT SERVICE","42 - CHASE","42FP - FOOT PURSUIT","55 - TRAFFIC STOP",
             "ODJ - OFF DUTY JOB","70 - ETS ACTIVATION","58 - ROUTINE INVESTIGATION",
             "ET - EXECUTIVE THREAT","MW - MOST WANTED","PK - PARK CHECK","WIC - WALK IN CASE #",
             "62 - PUBLIC SERVICE","**PD REQUESTED BY FIRE","*PD REQUESTED BY FIRE",
             "18 - STRUCTURE FIRE","18A - VEHICLE FIRE"]
df.loc[df.Problem.isin(off_inits), 'off_initiated'] = 1

print("Number of officer-initiated responses:", df.off_initiated.sum())

# Identify officer mark outs and calls with immediate dispatch
df['markout'] = 0
df.loc[df['md_dispatch'] == datetime.timedelta(minutes=0), 'markout'] = 1
df.loc[df['Event_Dispo'].str.contains('Mark', na=False), 'markout'] = 1
df.loc[df['Unit_Dispo'].str.contains('Mark', na=False), 'markout'] = 1
print("Number of mark outs:", df.markout.sum())

# Count number of units by Inc_num
df['n_units'] = df.groupby(by='Inc_num')['Unit'].transform('nunique')

# Count number of officers by Inc_num
df['n_offs'] = df.groupby(by='Inc_num')['R_O_Badge'].transform('nunique')

# Create new data frame with just Inc_num and assigned_min
min_df = df[['Inc_num', 'assigned_min']].copy()
min_df = min_df[min_df.duplicated() == False]

# Sort min_df
min_df.sort_values(['Inc_num','assigned_min'], inplace=True)

# Get nth row by Inc_num
min_df['disp_order'] = min_df.groupby(['Inc_num']).cumcount()+1
print(min_df.disp_order.value_counts())
min_df

# Merge by dispatchnum and assigned_min back to df
df = pd.merge(df, min_df, on=['Inc_num','assigned_min'])

df.sort_values(['Inc_num','assigned_min'])

# Rename variables
df.rename(columns={'Inc_num': 'dispatchnum',
                   'new_cn': 'incidentnum',
                   'Response Date': 'date',
                   'Incident_Type': 'incident_type',
                   'Priority_Num': 'priority',
                   'Caller Location': 'caller_loc',
                   'R_O_Badge': 'badge'}, inplace=True)

# Convert column names to lowercase
df.columns= df.columns.str.lower()

# Drop columns
df.drop(['priority_desc','agency_type','md_dispatch','case_number','tc_str_len'], axis=1, inplace=True)

# Recreate md_dispatch
df['md_dispatch'] = df['assigned_min'] - df['called_min']

# Convert beat to integer
df['beat'] = df['beat'].astype('Int64')

# Reorder columns
df = df.reindex(columns=['dispatchnum','incidentnum','date','year','month','day','hour',
                         'problem','priority','incident_type','unit_dispo','event_dispo',
                         'off_initiated','markout','division','ra','sector','beat','latitude',
                         'longitude','address','caller_loc','shelter_loc','loc_freq','unit',
                         'badge','n_units','n_offs','disp_order','called_min','assigned_min',
                         'enroute_min','arrived_min','cleared_min','md_dispatch','md_dispatch_flag',
                         'time_called','time_assigned','time_enroute','time_arrived','time_cleared',])
                         
# Density of time between call and dispatch
sns.distplot(df['md_dispatch'].loc[df['md_dispatch_flag'] == 0])
plt.title("Time Between Call and Dispatch")
plt.xlabel('Minutes')
plt.xlim(-10,150)
plt.axvline(x = np.mean(df['md_dispatch'].loc[df['md_dispatch_flag'] == 0]),
            linewidth=1, color='r', linestyle='dashed', label='mean') # mean
plt.axvline(x = np.median(df['md_dispatch'].loc[df['md_dispatch_flag'] == 0]),
            linewidth=1, color='g', linestyle='dashed', label = 'median') # mean
plt.legend()
plt.grid(True)
plt.savefig('Results/time_btw_call_dispatch.png')

# Create call level df for some variables
call_df = df[['dispatchnum','n_units','n_offs']].copy()
call_df = call_df[call_df.duplicated() == False]

# Plot distribution of n_offs and n_units
fig, axes = plt.subplots(ncols=2, figsize=(20,5))
sns.countplot(x = 'n_units', data = call_df, order=sorted(pd.value_counts(call_df['n_units']).iloc[:10].index), ax = axes[0])
axes[0].set_title("Counts of Calls by Number of Units Dispatched")
axes[0].set_xlabel('Number of Units')
axes[0].set_ylabel('Count')
axes[0].grid()
axes[0].set_axisbelow(True)
sns.countplot(x = 'n_offs', data = call_df, order=sorted(pd.value_counts(call_df['n_offs']).iloc[:10].index), ax = axes[1])
axes[1].set_title("Counts of Calls by Number of Officers Dispatched")
axes[1].set_xlabel('Number of Officers')
axes[1].set_ylabel('Count')
axes[1].grid()
axes[1].set_axisbelow(True)
plt.savefig('Results/n_units_officers.png')

# Save data
df.to_csv('Data/Clean/dispatch.csv')



