import os
os.chdir('/Users/hunterjohnson/Dropbox/Dallas Projects/')
os.getcwd()

import pandas as pd
import numpy as np
import matplotlib.pyplot as plt
import seaborn as sns
import matplotlib.mlab as mlab
import matplotlib.patches as mpatches
import matplotlib
import time

from sklearn.manifold import TSNE
from sklearn.decomposition import PCA, TruncatedSVD

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

# Resample data to have balanced classes
df = df.sample(frac=1)

df_force = df.loc[df['force_used']==1]
df_noforce = df.loc[df['force_used']==0][:3234]
df_bal = pd.concat([df_force, df_noforce])

df_bal = df_bal.sample(frac=1, random_state=123)

# Classes are now balanced
print('Counts of force_used:\n', df_bal.force_used.value_counts(), sep='')
print('\n')
print('Percentages:\n', df_bal.force_used.value_counts()/len(df_bal), sep='')

sns.countplot(x='force_used', data=df_bal)
plt.title('Class Distribution:\n 0: Force Not Used | 1: Force Used')
plt.xlabel('Force Used')
plt.ylabel('Count')
plt.figure(figsize=(12,4))

# Correlation matrices
fig, (ax1, ax2) = plt.subplots(2, 1, figsize=(24,20))

# Imbalanced
df_corr = df.corr()
sns.heatmap(df_corr, cmap='coolwarm_r', annot_kws={'size':20}, ax=ax1)
ax1.set_title('Imbalanced Correlation Matrix')

# Balanced
df_bal_corr = df_bal.corr()
sns.heatmap(df_bal_corr, cmap='coolwarm_r', annot_kws={'size':20}, ax=ax2)
ax2.set_title('Balanced Correlation Matrix')
plt.show()

cols_to_keep = ['reported_inc','hour','priority','off_initiated','markout',
                'shelter_loc','loc_freq','n_units','n_offs','md_dispatch',
                'medhhinc','lessthanhs','bg_prop_white','bg_prop_black',
                'bg_prop_hisp','bg_prop_other','n_arrested','force_used']
df_num = df_bal[cols_to_keep]

# Simple clustering methods using numeric variables
df_num = df_num.dropna()
X = df_num.drop('force_used', axis=1)
y = df_num['force_used']

# t-SNE algorithm
t0 = time.time()
X_reduced_tsne = TSNE(n_components=2, random_state=123).fit_transform(X.values)
t1 = time.time()
print('t-SNE took {:2} seconds'.format(t1-t0))

# PCA algorithm
t0 - time.time()
X_reduced_pca = PCA(n_components=2, random_state=123).fit_transform(X.values)
t1 = time.time()
print('PCA took {:2} seconds'.format(t1-t0))

# Truncated SVD algorithm
t0 = time.time()
X_reduced_svd = TruncatedSVD(n_components=2, algorithm='randomized', random_state=123).fit_transform(X.values)
t1 = time.time()
print('Truncated SVD took {:2} seconds'.format(t1-t0))

fig, (ax1, ax2, ax3) = plt.subplots(1, 3, figsize=(24,6))
fig.suptitle('Clusters Using Dimensionality Reduction')

blue_patch = mpatches.Patch(color='#0A0AFF', label='No Force')
red_patch = mpatches.Patch(color='#AF0000', label='Force')

# t-SNE scatter plot
ax1.scatter(X_reduced_tsne[:,0], X_reduced_tsne[:,1], c=(y==0),
            cmap='coolwarm', label='No Force', linewidths=2)
ax1.scatter(X_reduced_tsne[:,0], X_reduced_tsne[:,1], c=(y==1),
            cmap='coolwarm', label='Force', linewidths=2)
ax1.set_title('t-SNE')
ax1.grid(True)
ax1.legend(handles=[blue_patch, red_patch])

# PCA scatter plot
ax2.scatter(X_reduced_pca[:,0], X_reduced_pca[:,1], c=(y==0),
            cmap='coolwarm', label='No Force', linewidths=2)
ax2.scatter(X_reduced_pca[:,0], X_reduced_pca[:,1], c=(y==1),
            cmap='coolwarm', label='Force', linewidths=2)
ax2.set_title('PCA')
ax2.grid(True)
ax2.legend(handles=[blue_patch, red_patch])

# Truncated SVD scatter plot
ax3.scatter(X_reduced_svd[:,0], X_reduced_svd[:,1], c=(y == 0), cmap='coolwarm', label='No Force', linewidths=2)
ax3.scatter(X_reduced_svd[:,0], X_reduced_svd[:,1], c=(y == 1), cmap='coolwarm', label='Force', linewidths=2)
ax3.set_title('Truncated SVD')
ax3.grid(True)
ax3.legend(handles=[blue_patch, red_patch])

plt.show()
