## Python Geoprocessing scripts to process Sentinel S1 data

### Setup/Requirements

Python3 assumed

Create a Python3 Virtual Environment in your home directory

In the activated Virtual Environment, pip install:

- fiona
- shapely
- rasterio
- rasterstats

The run the required py script inside the Virtual Environment

### 1. Image Metadata

When processing the S1 data we need metadata which tells us which images are available to be processed etc

**gen_image_md_from_rfi_masked_images.py**

goes through a directory of S1 images (i.e. those that have had RFI artefacts masked)
and dumps their extents to a CSV file. This can be useful for understanding the coverage
of data that one has.

**data/image_bounds_meta.csv**

is a CSV containing the following columns:

- path_to_image - the full path to the S1 image on the filesystem
- image_day - the day the image was created (parsed from the image filename)
- image_month - the month the image was created (parsed from the image filename)
- image_year - the year the image was created (parsed from the image filename)
- geom_wkt - the geospatial extent geometry of the image as a polygon in OGC WKT format

This CSV is used as input to py_zonal_stats.py and controls which images zonal statistics
are calculated for. The CSV can be created using the output from gen_image_md_from_rfi_masked_images.py
e.g. by loading the CSV into a PostgreSQL/PostGIS db and building/outputting geometry etc. 

### 2. RFI Removal

The S1 radar data provided by JNCC to the team includes radar interference artefacts which need to be
removed before the S1 data can be classified. 

**mask_out_rfi.py**

masks out RFI artefacts present in S1 images using polygonal shapefiles
captured in QGIS that mark the location of the regions to be 
masked out

### 3. Zonal Statistics

Zonal Statistics which for a set of polygonal zones, provide for each polygonal zone summary statistics of the S1
data present within the zone. These Zonal Statistics are what the random forest ml model is built from and what
are fed to the ml model in order to classify fields with a crop type.

**py_zonal_stats.py**

generates zonal statistics for all zones (segmented fields or ground-truth polygons) held in a shapefile from S1 images.
This an alternative to generating zonal statistics in a desktop GIS like QGIS or ArcGIS etc.

It can be run from the commandline by doing:

(VirtualEnv)$ python py_zonal_stats.py ZONES_SHP_FNAME IMAGE_METADATA_FNAME OUTPUT_PATH

where:

ZONES_SHP_FNAME is the name of the shapefile containing the zones that zonal stats should be found for

IMAGE_METADATA_FNAME is the path to the CSV describing the complete set of images that zonal stats should be captured from
i.e. data\image_bounds_meta.csv inside this repo

OUTPUT_PATH is where the output CSV files should be written

**mp_py_zonal_stats.py**

is a version of py_zonal_stats.py which uses a multiprocessing pool to enable
a bunch of py_zonal_stats.py jobs to be spread across cpu cores to speed processing up.
Before mp_py_zonal_stats.py can be ran, the zones (segmented fields or ground-truth polyons) needs to be partitioned
into a set of sub-shapefiles so that each job (run of py_zonal_stats.py) in the multiprocessing pool is presented with
a different set of polygons to find zonal statistics for. One way to do this is to partition the zones using a standard
Ordnance Survey 10km x 10km grid such that each sub-shapefile contains all zones whose centroid falls within the extent
of a particular 10km x 10km gridsquare.

Once the data has been partitioned into a set of shapefiles, it can be run from the commandline by doing:

(VirtualEnv)$ python mp_py_zonal_stats.py PATH_TO_SHAPEFILES IMAGE_METADATA_FNAME OUTPUT_PATH NUM_OF_CORES

where

PATH_TO_SHAPEFILES is the path to the folder containing the shapefiles that zonal stats should be found for

IMAGE_METADATA_FNAME is the path to the CSV describing the complete set of images that zonal stats should be captured from
i.e. data\image_bounds_meta.csv inside this repo

OUTPUT_PATH is where the output csv files should be written

NUM_OF_CORES set the number of cpu cores to be allocated to the multiprocessing pool.

**concat_ml_output.py**

mp_py_zonal_stats.py will produce as output a load of _for_ml.csv files containing the zonal stats for all polygons
within a particular partition. concat_ml_output.py should be used to concatenate all of these individual files into
1 big csv file. 

### 4. Data preperation for (C)NN

For her MSc project only, Beata needed S1 data in a form that could be consumed by R ML libraries.
The requirements for this changed a lot, so there are a bunch of scripts related to this. 

**clip_images_to_field_extents.py**

runs gdalwarp from the commandline to clip S1 images to the extent of a 
polygon (i.e. a field boundary) shapefile.

**export_clipped_images_to_csv.py**

an attempt at dumping clipped S1 images to CSV.

**resize_clipped_images_to_64by64.py**

runs gdal_translate from the commandline to resize images clipped to field extents
by clip_images_to_field_extents.py to a standard 64x64 size since NN needs data to
be consistent in terms of size. 

**split_gt_shapefile.py**

given a shapefile with a gid column that uniquely identifies each record, this will
split the shapefile into a set of individual shapefiles, 1 per gid. The set of
shapefiles can be used as input for clip_images_to_field_extents.py 
