import glob
import fiona
import rasterio
import rasterio.mask
import os
#from rasterio.wrap import reproject, Resampling, calculate_default_transform
#from osgeo import gdal

import sys

def fetch(path):
	return glob.glob(path)

def load_preproc_raster(path):
	dir = os.path.join("preproc_rasters",path)
	return rasterio.open(dir)




data_dir = "/gpfs/data1/cmongp/ujjwal/cec/Forest_Data/"

total_path = "Total*.tif"
output_path = "output_*.tif"
sit_path = "ca_site_classes/ca_siteclcd_1_30m.tif"


fl_files = fetch(total_path)
output_files = fetch(output_path)
sit = fetch(sit_path)

print("total files are",fl_files)


fl_1 = rasterio.open(fl_files[0])
fl_elp = load_preproc_raster("ele_raster.tif")
fl_slp = load_preproc_raster("slp_raster.tif")
fl_asp = load_preproc_raster("asp_raster.tif")
fl_sit = load_preproc_raster("sit_raster.tif")





