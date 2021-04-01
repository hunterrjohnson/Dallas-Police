import os
os.chdir('/Users/hunterjohnson/Dropbox/Dallas Projects/')
os.getcwd()

import pandas as pd
import numpy as np
import matplotlib.pyplot as plt
import seaborn as sns
import matplotlib
import time

%matplotlib inline

# Read data
df = pd.read_csv('1_Data/2_Clean/analysis.csv')
df.head()

print('Number of calls:', len(df))
print('Variables:\n', df.columns)

# Classes are highly imbalanced
print('Counts of force_used:\n', df.force_used.value_counts(), sep='')
print('\n')
print('Percentages:\n', df.force_used.value_counts()/len(df), sep='')

sns.countplot(x='force_used', data=df)
plt.title('Class Distribution:\n 0: Force Not Used | 1: Force Used')
plt.xlabel('Force Used')
plt.ylabel('Count')
plt.figure(figsize=(12,4))

# Correlation matrix
df_corr = df.corr()
sns.heatmap(df_corr, cmap='coolwarm_r', annot_kws={'size':20})
plt.title('Correlation Matrix')
plt.figure(figsize=(12,10))

# One-Hot Encoding
df = pd.get_dummies(df, columns=['year','month','day','hour','problem',
                                 'incident_type','division'], drop_first=True)

# Keep only numeric columns for classification
df = df.select_dtypes(['number'])
df = df.dropna(axis=0)

# Split data
from sklearn.model_selection import train_test_split
X = df.drop('force_used', axis=1)
y = df['force_used']

X_train, X_test, y_train, y_test = train_test_split(X, y, test_size=0.2, random_state=123)

# Fit logistic model
from sklearn.linear_model import LogisticRegression
model = LogisticRegression()
model.fit(X_train, y_train) # fit model
model.score(X_test, y_test) # model accuracy

# Predict on test set
y_pred = model.predict(X_test)

# Confusion matrix
from sklearn.metrics import confusion_matrix
conf_matrix = confusion_matrix(y_test, y_pred)
print(conf_matrix)

# Other performance metrics
from sklearn.metrics import classification_report
print(classification_report(y_test, y_pred))



