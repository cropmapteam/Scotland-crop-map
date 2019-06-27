"""
    use GDAL gdalwarp cmdline tool to clip S1 radar images to field boundaries
"""
import glob
import os
import subprocess
from postgres import Postgres
import rasterio
import numpy as np
import shutil


def check_image_is_valid(fn):
    """
    Given an S1 image check if it is valid. Invalidity is deemed
    to be an image where all pixels in all bands are nodata

    :param fn:
    :return:
    """
    is_valid = True

    if os.path.exists(fn):
        with rasterio.open(fn) as src:
            b1_all_nan = np.isnan(src.read(1)).all()
            b2_all_nan = np.isnan(src.read(2)).all()
            if b1_all_nan and b2_all_nan:
                is_valid = False

    return is_valid


def fetch_images():
    """

    :return:
    """
    images = {}
    pg_conn_str = "postgres://james:MopMetal3@localhost:5432/cropmaps"
    db = Postgres(pg_conn_str)
    sql = "SELECT * FROM geocrud.image_bounds_meta_isect_w_gt"
    rs = db.all(sql)
    for r in rs:
        images[r.path_to_image] = [r.image_day, r.image_month, r.image_year]

    return images


def clip_raster_to_shp_polygon(raster_to_clip_fn, shp_fn, out_raster_fn):
    """
    use gdalwarp to crop a raster image to a polygon shapefile

    :param raster_to_clip_fn:
    :param shp_fn:
    :param out_raster_fn:
    :return:
    """
    gdalwarp_cmd = "gdalwarp -of GTiff -cutline {} -crop_to_cutline {} {}".format(
            shp_fn,
            raster_to_clip_fn,
            out_raster_fn
    )

    subprocess.call(gdalwarp_cmd, shell=True)


def main():
    path_to_gt_shapefiles = "/home/james/serviceDelivery/CropMaps/GroundTruth/Ground_Truth_V5+2018_Inspection/JRCC250619/indv_polys"
    images = fetch_images()

    for img_fname in images:
        if os.path.exists(img_fname):
            for fn in glob.glob(os.path.join(path_to_gt_shapefiles, "*.shp")):
                gt_poly_id = (os.path.splitext(os.path.split(fn)[-1])[0]).split("_")[-1]

                out_raster_fn = os.path.join(
                    "/home/james/geocrud/Clipped", (os.path.split(img_fname)[-1]).replace(".tif", "".join(["_", str(gt_poly_id), ".tif"]))
                )
                clip_raster_to_shp_polygon(img_fname, fn, out_raster_fn)

    for fn in glob.glob("/home/james/geocrud/Clipped/*.tif"):
        image_is_valid = check_image_is_valid(fn)
        if image_is_valid:
            dst_path = "/home/james/geocrud/Clipped/Valid"
        else:
            dst_path = "/home/james/geocrud/Clipped/NotValid"

        shutil.move(fn, dst_path)


if __name__ == "__main__":
    main()