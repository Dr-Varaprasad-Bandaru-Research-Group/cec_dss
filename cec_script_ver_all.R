load_libraries <- function(){
  library(sp)
  library(raster)
  library(rgdal)
  library(parallel)
  library(maptools)
}

set_clusters <- function(n){
  num_clusters <<- n
}

log <- function(...){
  arguments <- paste(list(...),collapse= ' ')
  print(arguments)
  
}


load_preproc_raster <- function(raster_name){
  # This function returns rasters
  raster_path <<- paste('preproc_rasters/',raster_name,sep='')
  log("loading",raster_path)
  return (raster(raster_path))
}



load_forest_data <- function(){
  # loading forest data rasters
  log("loading forest data")
  
  fl <<- list.files(pattern=glob2rx("Total*.tif$"))
  
  fl_1 <<- raster(fl[1])
  
  # All the rasters have fl_l's projection  
  fl.ele <<- load_preproc_raster("ele_raster.tif") # elevation
  fl.slp <<- load_preproc_raster("slp_raster.tif") # slope
  fl.asp <<- load_preproc_raster("asp_raster.tif") # aspect
  fl.sit <<- load_preproc_raster("sit_raster.tif") # sit
  
  log("Making a raster brick")
  fl.stack <<- stack(fl)
  fl.stack <<- stack(fl.stack, fl.sit)
  fl.brick <<- brick(fl.stack)
}

load_cdl <- function(){
  log("loading cdl ")
  cdl.prj.mask <<- load_preproc_raster("cdl_prj_mask.tif")
  
  
}

load_wilderness <- function(){
  log("loading wilderness")
  wild.prj <<- readOGR("wilderness_proj.shp") # wilderness areas shapefile 
}

load_ownership <- function(){
  log("loading ownership data")
  own.prj <<- load_preproc_raster("own_proj.tif")
  
}



f1 <- function(x){
  x[is.na(x)]<-0
  sum(x) > 0
}


  
#fl.ele.wild.cdl.own.masked <<- mask(fl.ele.wild.cdl.own, fl.brick.masked, maskvalue = 0)
#writeRaster(fl.ele.wild.cdl.own.masked,"fl_ele_wild_cdl_own_masked_ex.tif",overwrite=TRUE
  

trim_data <- function(){
  log("trimming data")
  # Get information from brick
  fl.brick.subset <<- subset(fl.brick,grep("BMSTM",names(fl.brick)))
  fl.brick.masked <<- clusterR(fl.brick.subset, calc, args=list(fun=f1))
  fl.ele.mask <<- mask(fl.ele,fl.brick.masked, maskvalue = 0)
  writeRaster(fl.ele.mask,"fl_ele_mask",overwrite=TRUE)
  df.ele <<- rasterToPoints(fl.ele.mask, spatial = T) 
  
  
}


load_shapefile <- function(){
  
  log("Loading Counties shapefile")
  shp <<- readOGR("CA_Counties/CA_Counties_TIGER2016.shp")
  log("preparing some raster files for processing")
  fhz <<- "fhszl06_132sn/c32fhszl06_1.shp"
  fl.fhz <<- spTransform(readOGR(fhz), proj4string(fl.ele))
  fl.raster <<- raster(fl.fhz,res=30)
  fl.fhz.raster <<- rasterize(fl.fhz, fl.raster, "HAZ_CODE")
  
}


load_county <- function(county_name){
  
  county_name <<- "Alpine"
  # loading the shapefile of the county
  log("Extracting",county_name,"shape file")
  shp.curr_county <- shp[shp$NAME==county_name,]
  
  log("Transforming the projection")
  shp.curr_county.prj <- spTransform(shp.curr_county, proj4string(fl.ele))
  
  log("Getting county's elevation data")
  df.ele.curr_county <<- over(df.ele, shp.curr_county.prj)
  df.ele.curr_county.na.omit <<- na.omit(cbind(df.ele@data,df.ele@coords,df.ele.curr_county$NAME))
  
  log("Writing into csv file")
  county_dir <- paste("counties/",county_name,sep="")
  write.csv(df.ele.curr_county.na.omit, paste(county_dir,"/F3_data_ele_v3.csv",sep = ""))
  
  log("Transforming coordinates")
  coordinates(df.ele.curr_county.na.omit) <- ~x+y
  proj4string(df.ele.curr_county.na.omit) <- proj4string(fl.ele)
  df.data.curr_county <<- extract(fl.brick, df.ele.curr_county.na.omit, sp=T)
  
  log("Writing output into csv files")
  fl.fhz.data <<- extract(fl.fhz.raster, df.ele.curr_county.na.omit, df=T)
  write.csv(fl.fhz.data, paste(county_dir,"/F3_data_fhz_v3.csv",sep=""))
  
  fl.slp.data <<- extract(fl.slp, df.ele.curr_county.na.omit, df=T)
  write.csv(fl.slp.data, paste(county_dir,"/F3_data_slp_v3.csv",sep=""))
  
  fl.asp.data <<- extract(fl.asp, df.ele.curr_county.na.omit, df=T)
  write.csv(fl.asp.data, paste(county_dir,"/F3_data_asp_v3.csv",sep=""))
  
  log("Getting the right crs for data frame")
  df.data.curr_county.latlon <<- spTransform(df.data.curr_county, CRS("+proj=longlat +datum=WGS84"))
  
  
}

Visualization <- function(county_name){
  
  log("Preparing kmeans raster file for",county_name)
  county_dir <- paste("counties/",county_name,sep="")
  log("Countery directory is",county_dir)
  
  plot_file <- paste("/plot/",county_name,"_all.tif",sep="")
  log("Plot file location is",plot_file)
  
  
  f3_data_file <- paste(county_dir,"/F3_data_kmeans100_v7.csv",sep="")
  log("kmeans csv location is",f3_data_file)
  
  plot.kmeans.fhz <- read.csv(f3_data_file)
  raster.kmeans100.fhz <- rasterFromXYZ(plot.kmeans.fhz[c(4,5,8)])
  
  proj4string(raster.kmeans100.fhz) <- proj4string(raster(fl[1]))
  
  log("Writing kmeans raster for",county_name,"in to memory.","File name is : ",plot_file)
  writeRaster(raster.kmeans100.fhz, paste(county_dir,plot_file,sep=""), overwrite=T)
  
}

dbSafeNames = function(names) {
  names = gsub('[^a-z0-9]+','_',tolower(names))
  names = make.names(names, unique=TRUE, allow_=TRUE)
  names = gsub('.','_',names, fixed=TRUE)
  names
}

Output <- function(county_name){
  
  log("Preparing kmeans data frame for county,",county_name)
  county_dir <<- paste("counties/",county_name,sep="")
  
  # reading kmeans csv
  
  test.kmeans100 <- read.csv(paste(county_dir,"/F3_data_kmeans100_v7.csv",sep=""))
  test.kmeans100.filt <- test.kmeans100[,c('Cluster1','Cluster2')]
  test.kmeans100.filt<-spCbind(df.data.curr_county.latlon,test.kmeans100.filt) #Error
  
  
  # convert into data frame
  
  test.kmeans100.filt.df <<- as.data.frame(test.kmeans100.filt)
  test.kmeans100.filt.df[is.na(test.kmeans100.filt.df)]<-0
  
  colnames(test.kmeans100.filt.df)<-dbSafeNames(colnames(test.kmeans100.filt.df))
  test.kmeans100.filt.df$cluster_no <- test.kmeans100.filt.df$cluster1 * 2500 + test.kmeans100.filt.df$cluster2
  
  headers <<- paste0(colnames(test.kmeans100.filt.df), " ", "REAL", " ", "NOT NULL")
  writeLines(headers, file("table_headers.txt"))
  write.csv(test.kmeans100.filt.df, paste(county_dir,"/",county_name,"final2.csv",sep=""), row.names = F)
  
  
  merge_own_wild_df(county_name=county_name,
                    test.kmeans100.filt=test.kmeans100.filt,
                    test.kmeans100.filt.df=test.kmeans100.filt.df)
  
}



merge_own_wild_df <- function(county_name,test.kmeans100.filt,test.kmeans100.filt.df){
  
  log("Merging ownership and wilderness data for",county_name)
  county_dir <<- paste("counties/",county_name,sep="")
  
  log("Getting ownership data")
  own_cdl <<- load_preproc_raster("fl_ele_own_cdl.tif")
  proj4string(own_cdl) = proj4string(own.prj)
  
  log("Getting wilderness data")
  wild_cdl = load_preproc_raster("fl_ele_wild_cdl.tif")
  proj4string(wild_cdl) = proj4string(own.prj)
  
  # making use of existing dataframe
  helper <- raster(test.kmeans100.filt)
  
  # changing the projection of shapefile
  shp.curr_county.prj2 <- spTransform(shp.curr_county.prj, proj4string(helper)) 
  
  
  # cropping wilderness according to common extent & matching it's projection
  
  wild_kmeans_prj = projectRaster(wild_cdl,helper)
  wild_cropped <<- crop(wild_kmeans_prj, extent(shp.curr_county.prj2))
  
  own_kmeans_prj = projectRaster(own_cdl,helper)
  own_cropped <<- crop(own_kmeans_prj,extent(shp.curr_county.prj2))
  
  # stacking cropped ownership and wilderness rasters
  com_st = stack(wild_cropped,own_cropped)
  
  # Giving the stack layers meaningfull names
  names(com_st) = c("Wilderness_Areas","Ownership_Areas")
  
  # plot(com_st)
  
  # converting raster stack to spatial data frame
  com_st_df = rasterToPoints(com_st,spatial=T)
  
  # converting raster stack to normal data frame
  com_st_normal = as.data.frame(com_st_df) 
  
  # merging
  log("Merging")
  merged_df = merge(x=test.kmeans100.filt.df,y=com_st_normal,by=c("x","y"),all.x=TRUE,all.y=TRUE)
  
  # writing the merged data frame into memory
  
  log("Writing merged data frame into memory")
  write.csv(merged_df, paste(county_dir,"/",county_name,"with_wild_own.csv",sep=""), row.names = F)
  
}



load_data <- function(){
  log("Starting")
  
  # loading data
  load_forest_data()
  load_cdl() 
  load_wilderness()
  load_ownership()
  
  # preparing data
  trim_data()
  load_shapefile() # for all counties
}

save_results <- function(county_name){
  Visualization(county_name = county_name)
  Output(county_name = county_name)
}



#county_names <<<- c("Alpine","Amador","Butte","Calaveras","El Dorado","Fresno","Inyo","Kern","Madera","Mariposa",
#                   "Mono","Nevada","Placer","Plumas","Sierra","Tulare","Tuolumne","Yuba")


# load libraries

setup <- function(){
  load_libraries()
  beginCluster(num_clusters)
  rasterOptions(maxmemory = 1e+09) # comment this out if the machine is not powerful enough
  setwd("/gpfs/data1/cmongp/ujjwal/cec/Forest Data/") # sets the directory path
  
}

# loads libraries and sets clusters
set_clusters(35) # change num_clusters here
setup()
load_data()

# data prep
county_name <<- 'Alpine'
load_county(county_name)
save_results(county_name)


endCluster()
