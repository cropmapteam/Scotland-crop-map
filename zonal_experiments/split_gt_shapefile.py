"""
    split a single shapefile with lots of records into a set of shapefiles with one record per shapefile
"""


import fiona
import os


def split_shapefile(shp_to_split_fn, output_path):
    """
    Take a shapefile and split into a set of sub-shapefiles, 1 per record
    in the input shapefile
    :param shp_to_split_fn:
    :param output_path:
    :return:
    """

    with fiona.open(shp_to_split_fn, "r") as src:
        for feature in src:
            gid = feature["properties"]["GID"]
            dst_schema = src.schema
            dst_driver = src.driver
            dst_crs = src.crs

            new_shp_fname = os.path.join(output_path, "".join(["gtpoly_", str(gid), ".shp"]))
            with fiona.open(new_shp_fname, "w", crs=dst_crs, driver=dst_driver, schema=dst_schema) as dst:
               dst.write(feature)


def main():
    shp_to_split_fn = "/home/james/serviceDelivery/CropMaps/GroundTruth/Ground_Truth_V5+2018_Inspection/JRCC250619/ground_truth_v5_2018_inspection_kelso_250619_c.shp"
    output_path = "/home/james/serviceDelivery/CropMaps/GroundTruth/Ground_Truth_V5+2018_Inspection/JRCC250619/indv_polys"

    split_shapefile(shp_to_split_fn, output_path)


if __name__ == "__main__":
    main()


