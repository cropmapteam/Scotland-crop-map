"""
    initial attempt to dump S1 data clipped by fields
    to csv form for ingest into R. It turned out this
    was actually not in fact required and resized images
    are ok instead. If the data is required as csv then
    this might be useful as a starting point

"""

import os
import rasterio
import numpy as np
import csv
import fiona
from shapely.geometry import shape


def fetch_zonal_polygons_from_shapefile(shp_fname):
    zonal_polygons = {}
    if os.path.exists(shp_fname):
        with fiona.open(shp_fname, "r") as shp_src:
            for feature in shp_src:
                gid = feature["properties"]["GID"]
                fid_1 = feature["properties"]["FID_1"]
                geom = shape(feature["geometry"])
                area = geom.area
                lcgroup = feature["properties"]["LCGROUP"]
                lctype = feature["properties"]["LCTYPE"]
                zonal_polygons[gid] = {
                    "geom": geom,
                    "area": area,
                    "fid_1": fid_1,
                    "lcgroup": lcgroup,
                    "lctype": lctype
                }

    return zonal_polygons


def write_clipped_field_to_csv(src_img, out_path, poly):
    """
    dump the 2 bands of a

    :param src_img:
    :param out_path:
    :param poly:
    :return:
    """
    p_fid_id = poly["fid_1"]
    p_lctype = poly["lctype"]
    p_lcgroup = poly["lcgroup"]
    p_area = poly["area"]
    base_name = os.path.splitext(os.path.split(src_img)[-1])[0]
    band_values = [p_fid_id, p_lctype, p_lcgroup, p_area]
    img_width, img_height, out_row_length, out_csv_fn = None, None, None, None
    if os.path.exists(src_img):
        with rasterio.open(src_img, "r") as src:
            img_width = src.width
            img_height = src.height

            for band_n in (1, 2):
                band = src.read(band_n)
                out_np_band_fn = os.path.join(out_path, "".join([base_name, "_b", str(band_n), ".out"]))
                np.savetxt(out_np_band_fn, band, delimiter=",")
                if os.path.exists(out_np_band_fn):
                    with open(out_np_band_fn) as inpf:
                        my_reader = csv.reader(inpf)
                        for r in my_reader:
                            band_values += r

        out_csv_fn = os.path.join(out_path, "".join([base_name, ".csv"]))
        with open(out_csv_fn, "w") as outpf:
            my_writer = csv.writer(outpf, delimiter=",")
            my_writer.writerow(band_values)

    if out_csv_fn is not None:
        row_length = get_row_length(out_csv_fn)
        print("Check, for img, w x h is {} x {} = {}. Out row length is {}".format(
            img_width, img_height, (((img_width*img_height)*2)+4), row_length
        ))


def get_row_length(fn):
    row_length = 0
    if os.path.exists(fn):
        with open(fn) as inpf:
            my_reader = csv.reader(inpf)
            c = 1
            for r in my_reader:
                if c == 1:
                    row_length = len(r)
                c += 1

    return row_length


def main():
    src_shp_fname = "/home/james/serviceDelivery/CropMaps/GroundTruth/Ground_Truth_V5+2018_Inspection/JRCC250619/ground_truth_v5_2018_inspection_kelso_250619_c.shp"
    all_polys = fetch_zonal_polygons_from_shapefile(src_shp_fname)
    poly_gid = 89
    poly = all_polys[poly_gid]

    src_img_fn = "/home/james/geocrud/Clipped/Valid/S1A_20180425_30_asc_175837_175902_DV_Gamma-0_GB_OSGB_RCTK_SpkRL_89.tif"
    out_path = "/home/james/geocrud/CNNData"

    write_clipped_field_to_csv(src_img_fn, out_path, poly)


if __name__ == "__main__":
    main()