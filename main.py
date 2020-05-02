#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
@author: UjjwalAyyangar
"""
from clustering import start
import os

def warn(*args, **kwargs):
	pass

import warnings
warnings.warn = warn


def build_directory(county_name):
	root_dir = r"/gpfs/data1/cmongp/ujjwal/cec/Forest Data/counties/"
	county_dir = root_dir + county_name
	plot_dir = county_dir+"/plot/"
	os.chmod(root_dir,0o777)
	#os.chmod(plot_dir,0o777)
	if not os.path.exists(county_dir):
		os.makedirs(county_dir)

	if not os.path.exists(plot_dir):
		os.makedirs(plot_dir)	


def prepare():
	counties = ["Alpine","Amador","Butte","Calaveras","El Dorado","Fresno","Inyo","Kern","Madera","Mariposa",
              "Mono","Nevada","Placer","Plumas","Sierra","Tulare","Tuolumne","Yuba"]

	for county_name in counties:
		build_directory(county_name)



def analyze_county(county_name):
	try:
		print("Current county",county_name)	
		start(county_name)
	except Exception as e:
		print(e)
		print("Issue while processing {}".format(county_name))


def analyze_counties():

	counties = ["Alpine","Amador","Butte","Calaveras","El Dorado","Fresno","Inyo","Kern","Madera","Mariposa",
              "Mono","Nevada","Placer","Plumas","Sierra","Tulare","Tuolumne","Yuba"]

	for county_name in counties:
		analyze_county(county_name)


analyze_county("Alpine")


# Name of the county
#county_name="Amador"

"""
for county_name in counties:
	try:
	
		# before running the .R script
		print("Current county",county_name)	
		build_directory(county_name)
		# after running the .R script
		start(county_name)
	except:
		print("Issue while processing {}".format(county_name))
"""




