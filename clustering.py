#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
@authors: yaramasur and UjjwalAyyangar
"""
"""
#### v2 - x, y
#### v3 - x, y, slp - standard scaler
#### v4 - 100*x, 100*y, ele, slp - minmax scaler
#### v5 - 100*x, 100*y, slp, asp - minmax scaler
#### v6 - x, y, ele, slp - standard scaler, 100 pixels per harvestable area
#### v7 - x, y, asp - standard scaler, 100 pixels per harvestable area, only private lands(v3 data)
"""

from sklearn.metrics import silhouette_samples, silhouette_score
from sklearn.cluster import KMeans
from sklearn import preprocessing
import pandas as pd
import numpy as np
import sys
import matplotlib.pyplot as plt
from multiprocessing import Pool


def read_county(county_dir):
	print("reading county data received from the .R script")

	test = pd.read_csv(county_dir+"F3_data_ele_v3.csv")
	test_slp = pd.read_csv(county_dir+"F3_data_slp_v3.csv")
	test_asp = pd.read_csv(county_dir+"F3_data_asp_v3.csv")
	test_fhz = pd.read_csv(county_dir+"F3_data_fhz_v3.csv")
	test_fhz.fillna(method="ffill",inplace=True)
	test_asp.fillna(method="ffill",inplace=True)	

	return [test, test_slp, test_fhz, test_asp]


"""sub clustering""" # NEED TO REMOVE
def KK2(ind,f1,f2):
    X = np.array(list(zip(f1[ind],f2[ind])))#,f4[ind])))#,*[f_fhz.loc[ind,column] for column in f_fhz])))
    n = len(X)//100
    #print(X,len(X))
    if n==0:
        n+=1
    km = KMeans(n_clusters=n)
    km = km.fit(X)
    #print(len(km.labels_),len(X))
    #sys.exit(0)
    return (km.labels_, km.cluster_centers_)


# PCA - TODO
def cluster(county_dir, test, f1, f2):
	"""Initital clustering analyses"""
	X = np.column_stack((f1,f2)) # Faster alternative
	k = 20 # len(X)//100
        # 

	km = KMeans(n_clusters=k,precompute_distances=True)
	km = km.fit(X)

	test['Cluster1'] = km.labels_

	clusters = test['Cluster1']
	ind = [clusters==k for k in range(0,20)]

	with Pool() as p:
    		output = [p.apply_async(KK2, (i,f1,f2,)) for i in ind]
    		result = [res.get() for res in output]
    		p.close()
   	 	p.join()


	cluster2 = np.empty(clusters.shape)
	centers = pd.concat([pd.DataFrame(r[1]) for r in result])
	centers.columns = ['Center_X', 'Center_Y']#,'Center_layer1', 'Center_layer2', 'Center_layer3', 'Center_layer4']


	for i,j in enumerate(result):
		cluster2[ind[i]] = j[0] 

	test['Cluster2'] = cluster2
	test2 = test.groupby(['Cluster1','Cluster2']).count().add_suffix('_count').reset_index()[['Cluster1','Cluster2','x_count']]
	centers = pd.concat([centers.reset_index(), test2], axis=1).drop('index',axis=1)
	centers['Area'] = centers['x_count']*0.000247105*30*30
	stat = centers.Area.describe()
	test.to_csv(county_dir+"F3_data_kmeans100_v7.csv")
	centers.to_csv(county_dir+"F3_data_kmeans_centers100_v7.csv")
	stat.to_csv(county_dir+"F3_data_kmeans_stats100_v7.csv")


def start(county_name):
	county_dir = r"/gpfs/data1/cmongp/ujjwal/cec/Forest Data/counties/"+county_name+"/"
	

	test, test_slp, test_fhz, test_asp = read_county(county_dir)
	min_max_scaler = preprocessing.MinMaxScaler()
	standard_scaler = preprocessing.StandardScaler()

	f1 = standard_scaler.fit_transform(test['x'].values.reshape(-1, 1)).squeeze()
	f2 = standard_scaler.fit_transform(test['y'].values.reshape(-1, 1)).squeeze()
	#f3 = standard_scaler.fit_transform(test_slp['output_slope'].values.reshape(-1, 1)).squeeze()
	#f4 = standard_scaler.fit_transform(test_asp['output_aspect'].values.reshape(-1, 1)).squeeze()
	#f5 = standard_scaler.fit_transform(test['output_srtm'].values.reshape(-1, 1)).squeeze()

	f_fhz = pd.get_dummies(test_fhz.layer,prefix='fhz')

	print("Starting clustering")
	cluster(county_dir, test, f1, f2)
	print("Clustering finished")

