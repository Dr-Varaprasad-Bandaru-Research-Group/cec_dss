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
	return rasterio.open(dir).read()

def stack_rasters(ras_list, dst):

	print("getting meta data from {}".format(ras_list[0]))

	with rasterio.open(ras_list[0]) as src0:
		meta = src0.meta

	meta.update(count=len(ras_list))

	print('stacking and writing to {}'.format(dst))
	
	with rasterio.open(dst,'w',**meta) as dst:
		for id, layer in enumerate(ras_list, start=1):
			with rasterio.open(layer) as src1:
				dst.write_band(id,src1.read(1))


data_dir = "/gpfs/data1/cmongp/ujjwal/cec/Forest_Data/"

total_path = "Total*.tif"

fl_files = fetch(total_path)

print('reading forest files')
fl_1 = rasterio.open(fl_files[0])
fl_elp = load_preproc_raster("ele_raster.tif")
fl_slp = load_preproc_raster("slp_raster.tif")
fl_asp = load_preproc_raster("asp_raster.tif")
fl_sit = load_preproc_raster("sit_raster.tif")


sit_path = os.path.join("preproc_rasters","sit_raster.tif")
ras_list = [fl_files[0],sit_path]

# stack_rasters(ras_list,'fl_stack.tif')
print("reading stack")
fl_stack = load_preproc_raster("fl_stack.tif")
print("cdl prj")
cdl_prj_mask = load_preproc_raster("cdl_pj.tif")




