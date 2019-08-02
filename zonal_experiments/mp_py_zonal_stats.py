"""
    use python multiprocessing to process zonal stats in parallel
    using blocks of partitioned zonal shapefiles
"""
import glob
import os
from multiprocessing import Pool
import click
# is our python stuff to generate the zonal stats
from py_zonal_stats import mp_fetch_zonal_stats_for_shapefile


@click.command()
@click.argument('path_to_shapefiles', type=click.Path(exists=True))
@click.argument('image_metadata_fname', type=click.Path(exists=True))
@click.argument('output_path', type=click.Path(exists=True))
@click.argument('num_of_cores', type=click.IntRange(min=1, max=os.cpu_count()))
def fetch_zonal_stats_for_shapefiles(path_to_shapefiles, image_metadata_fname, output_path, num_of_cores):
    jobs = []
    # is the folder containing all of the shapefiles we want to generate zonal stats for
    path_to_shps = os.path.join(path_to_shapefiles, "*.shp")

    # is a CSV describing which S1 images zonal stats are to found for
    #image_metadata_fname = "data/image_bounds_meta.csv"

    # is where the output zonal stats csv`s should be placed
    #output_path = "/home/geojamesc/geocrud/zonal_stats/mpzs"

    # assemble jobs list: [[zones_shp_fname, image_metadata_fname, output_path], ...]
    # each item in the list is a new job that will processed
    for zones_shp_fname in glob.glob(path_to_shps):
        jobs.append([zones_shp_fname, image_metadata_fname, output_path])

    # processed defaults to os.cpu_count
    # the epcc vm has 16 cores so set to 12
    pool = Pool(processes=num_of_cores)
    pool.map(mp_fetch_zonal_stats_for_shapefile, jobs)


if __name__ == "__main__":
    fetch_zonal_stats_for_shapefiles()
