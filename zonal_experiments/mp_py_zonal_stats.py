"""
use python multiprocessing to process zonal stats in parallel
using blocks of partitioned zonal shapefiles

on my local pc, spread across 4 cores, time reported to create
zonal stats from 16 copies of the kelso 413 poly shapefiles was

real	9m56.298s
user	37m21.889s
sys	0m33.066s
"""
import glob
from multiprocessing import Pool
# is our python stuff to generate the zonal stats
from py_zonal_stats import mp_fetch_zonal_stats_for_shapefile


def main():
    jobs = []
    # is the folder containing all of the shapefiles we want to generate zonal stats for
    path_to_shps = "/home/geojamesc/partitions/*.shp"

    # is a CSV describing which S1 images zonal stats are to found for
    image_metadata_fname = "data/image_bounds_meta.csv"

    # is where the output zonal stats csv`s should be placed
    output_path = "/home/geojamesc/geocrud/zonal_stats/mpzs"

    # assemble jobs list: [[zones_shp_fname, image_metadata_fname, output_path], ...]
    # each item in the list is a new job that will processed
    for zones_shp_fname in glob.glob(path_to_shps):
        jobs.append([zones_shp_fname, image_metadata_fname, output_path])

    # processed defaults to os.cpu_count
    # the epcc vm has 16 cores so set to 12
    pool = Pool(processes=12)
    pool.map(mp_fetch_zonal_stats_for_shapefile, jobs)


if __name__ == "__main__":
    main()
