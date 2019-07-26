"""

   script to mask out (set to nodata) regions in S1 rasters that are occupied by radar interference as
   described by polygons held in shapefiles manually digitised in QGIS

   something like this:

   https://rasterio.readthedocs.io/en/stable/topics/masking-by-shapefile.html

   seems to take about 7 mins per image, so assuming 51 images we are talking ~6 hrs to do the lot

   this on my 16GB machine

   presumably things could be sped up with we did the masking on windowed regions as that way the entire
   image would not need to be read/written to, just the bits where there are RFI regions.

   https://rasterio.readthedocs.io/en/stable/topics/windowed-rw.html

"""

import os
import fiona
import rasterio
import rasterio.mask
from shapely.geometry import shape
import csv


def mask_out_rfi_regions(src_raster_fname, efi_regions_shp_fname, out_raster_fname):
    if os.path.exists(src_raster_fname):
        if os.path.exists(efi_regions_shp_fname):
            with fiona.open(efi_regions_shp_fname, "r") as shp_src:
                # fetch mask polygons from the shapefile
                # check that shapefile has at least 1 feature
                if len(shp_src) > 0:
                    # mask_polys = [feature["geometry"] for feature in shp_src]
                    mask_polys = []
                    # check that the geometry of each mask poly is valid
                    for feature in shp_src:
                        mask_poly = feature["geometry"]
                        s = shape(mask_poly)
                        if s.is_valid:
                            mask_polys.append(mask_poly)
                        else:
                            print(
                                "Found invalid polygon with id {} in {}".format(str(feature["properties"]["id"]), efi_regions_shp_fname))

                    # if we now have at least 1 valid mask polyon then mask out the polygons in the src image
                    if len(mask_polys) > 0:
                        with rasterio.open(src_raster_fname) as raster_src:
                            out_meta = raster_src.meta.copy()
                            out_image, out_transform = rasterio.mask.mask(raster_src, mask_polys, invert=True)

                        # write out the new image
                        with rasterio.open(out_raster_fname, "w", **out_meta) as dest:
                            dest.write(out_image)
                    else:
                        print("Skipped {} as shapefile {} has no records with valid geometry".format(src_raster_fname, efi_regions_shp_fname))
                else:
                    print("Skipped {} as shapefile {} has no records".format(src_raster_fname, efi_regions_shp_fname))


def get_mask_shp_raster_pairs():

    my_d = {}
    base_path_to_rfi_shapefiles = "/home/james/serviceDelivery/CropMaps/RFI_masks/rfi/RFI_Masks_040719"
    base_path_to_images = "/home/james/serviceDelivery/CropMaps/data_from_jncc_050619"

    for root, folders, files in os.walk(base_path_to_rfi_shapefiles):
        for f in files:
            if os.path.splitext(f)[-1] == ".shp":

                path_to_rfi_mask_shapefile = os.path.join(root, f)

                ymd = f.split("_")[1]
                y, m, d, sub_folder, img = ymd[:4], ymd[4:6], ymd[6:], os.path.splitext(f)[0], f.replace(".shp", ".tif")
                path_to_img_to_be_masked = os.path.join(base_path_to_images, m, d, sub_folder, img)
                if os.path.exists(path_to_img_to_be_masked):
                    if img in my_d:
                        my_d[img].append([path_to_img_to_be_masked, path_to_rfi_mask_shapefile])
                    else:
                        my_d[img] = [[path_to_img_to_be_masked, path_to_rfi_mask_shapefile]]
                else:
                    print("Could not find image for rfi_shapefile {}".format(path_to_rfi_mask_shapefile))

    return my_d


def get_mask_shp_raster_pairs_from_csv(csv_fn):
    """
    do masking based on a set of images/masks provided in a csv

    csv has format like this:

    "img","shp_mask"
    <path_to_img_to_mask>, <path_to_shp_mask>

    :param csv_fn:
    :return:
    """
    my_d = {}
    if os.path.exists(csv_fn):
        with open(csv_fn) as inpf:
            my_reader = csv.DictReader(inpf)
            for r in my_reader:
                img = r["img"]
                shp_mask = r["shp_mask"]
                k = os.path.split(img)[-1]
                print(k, img, shp_mask)

                if os.path.exists(img):
                    if k in my_d:
                        my_d[k].append([img, shp_mask])
                    else:
                        my_d[k] = [[img, shp_mask]]
                else:
                    print("Could not find image {}".format(img))

    return my_d


def main():
    base_output_path = "/home/james/geocrud/out_images"

    d = get_mask_shp_raster_pairs()
    #d = get_mask_shp_raster_pairs_from_csv("/home/james/Desktop/mask_shp_raster_pairs.csv")
    for i in d:
        if len(d[i]) == 1:
            path_to_img_to_be_masked = d[i][0][0]
            path_to_rfi_mask_shapefile = d[i][0][1]
            out_raster_fname = os.path.join(base_output_path, os.path.split(path_to_img_to_be_masked)[1].replace(".tif", "_rfi_removed.tif"))

            print("Masking out RFI in {} using {} --> {}".format(path_to_img_to_be_masked, path_to_rfi_mask_shapefile, out_raster_fname))
            mask_out_rfi_regions(path_to_img_to_be_masked, path_to_rfi_mask_shapefile, out_raster_fname)
        else:
            print("For image {} have multiple (count of {}) associated shapefiles, so skipped".format(i, str(len(d[i]))))


if __name__ == "__main__":
    main()
