import csv
import os
from datetime import date
import rasterio
from rasterio.windows import Window
from rasterstats import zonal_stats
from postgres import Postgres
import shapely.wkb
import numpy as np


def fetch_images():
    images = {}
    pg_conn_str = "postgres://james:MopMetal3@localhost:5432/cropmaps"
    db = Postgres(pg_conn_str)
    sql = "SELECT * FROM geocrud.image_bounds_meta_isect_w_gt"
    rs = db.all(sql)
    for r in rs:
        images[r.path_to_image] = [r.image_day, r.image_month, r.image_year]

    return images


def fetch_image_metadata_from_csv(md_csv_fname):
    """
    from view dump image metadata to csv by in pgadmin4 running this query

    SELECT path_to_image, image_day, image_month, image_year FROM geocrud.image_bounds_meta_isect_w_gt;

    and then save to a csv

    :param md_csv_fname:
    :return: a dict like this: {"<path_to_image>":["<image_day>", "<image_month>", "<image_year>"],}
    """
    image_metadata = {}
    if os.path.exists(md_csv_fname):
        with open(md_csv_fname, "r") as inpf:
            my_reader = csv.DictReader(inpf)
            for r in my_reader:
                image_metadata[r["path_to_image"]] = [r["image_day"], r["image_month"], r["image_year"]]

    return image_metadata



#TODO - pull from a (partitioned) shapefile rather than Pg
def fetch_ground_truth_polygons():
    gt_polygons = {}
    pg_conn_str = "postgres://james:MopMetal3@localhost:5432/cropmaps"
    db = Postgres(pg_conn_str)
    sql = "SELECT * FROM geocrud.ground_truth_v5_2018_inspection_kelso"
    rs = db.all(sql)

    for r in rs:
        gid = r.gid
        lcgroup = r.lcgroup
        lctype = r.lctype
        geom = shapely.wkb.loads(r.geom, hex=True)
        gt_polygons[gid] = {
            "geom": geom,
            "lcgroup": lcgroup,
            "lctype": lctype
        }

    return gt_polygons


def fetch_window_from_raster(fname, aoi_geo_min_x, aoi_geo_min_y, aoi_geo_max_x, aoi_geo_max_y, band=1, dbg=False):
    """
    use rasterio to fetch a sub-window from a raster

    :param fname: the raster to fetch from
    :param aoi_geo_min_x: llx of sub-window to fetch
    :param aoi_geo_min_y: lly of sub-window to fetch
    :param aoi_geo_max_x: urx of sub-window to fetch
    :param aoi_geo_max_y: ury of sub-window to fetch
    :param band: band to fetch from the raster
    :param dbg: print debug messages
    :return: the sub-region as a NumPy ndarray, the affine tranformation matrix for the sub-window
    """

    the_window = None
    window_all_nodata = False

    #with rasterio.open(fname, nodata='nan') as src:
    with rasterio.open(fname) as src:

        w = src.width
        h = src.height
        max_row = h  # y
        max_col = w  # x

        if dbg:
            print("Width: {}".format(w))
            print("Height: {}".format(h))

        # get transform for whole image that maps pixel (row,col) location to geospatial (x,y) location
        affine = src.transform

        if dbg:
            print(rasterio.transform.xy(affine, rows=[0, max_row], cols=[0, max_col]))

        rows, cols = rasterio.transform.rowcol(affine, xs=[aoi_geo_min_x, aoi_geo_max_x],
                                               ys=[aoi_geo_min_y, aoi_geo_max_y])

        aoi_img_min_col = cols[0]
        aoi_img_min_row = rows[0]
        aoi_img_max_col = cols[1]
        aoi_img_max_row = rows[1]

        if dbg:
            print(aoi_img_min_col, aoi_img_min_row, aoi_img_max_col, aoi_img_max_row)

        aoi_width = aoi_img_max_col - aoi_img_min_col
        aoi_height = aoi_img_min_row - aoi_img_max_row

        if dbg:
            print(aoi_width, aoi_height)

        # just read a window from the complete image
        # rasterio.windows.Window(col_off, row_off, width, height)
        this_window = Window(aoi_img_min_col, aoi_img_min_row - aoi_height, aoi_width, aoi_height)
        the_window = src.read(band, window=this_window)

        #TODO - replace with more robust np.isnan(src.read(1)).all() calls to check entire window for nodata
        # possibly unreliable test to check if the returned window is all nodata values i.e. the part of
        # the image contains no RS data
        first = the_window[0][0]
        last = the_window[the_window.shape[0] - 1][the_window.shape[1] - 1]
        if np.isnan(first) and np.isnan(last):
            window_all_nodata = True

        if dbg:
            print(the_window.size)

        if dbg:
            if window_all_nodata:
                print("window seems to be all nodata")
                print((the_window[0]).tolist())
                print((the_window[the_window.shape[0] - 1]).tolist())
            else:
                print("window seems NOT to be all nodata")
                print((the_window[0]).tolist())
                print((the_window[the_window.shape[0] - 1]).tolist())


        # the affine transformation of a window differs from the entire image
        # https://github.com/mapbox/rasterio/blob/master/docs/topics/windowed-rw.rst
        # so get transform just for the window that maps pixel (row, col) location to geospatial (x,y) location
        win_affine = src.window_transform(this_window)
        # print(win_affine)

        affine = win_affine

    # return the window (NumPy) array, the transformation matrix for the window providing img->geo location, and a
    # flag indicating if we think the window is just all nodata
    return the_window, affine, window_all_nodata


def my_variance(x):
    """
    rasterstats does not provide a variance statistic as part of the
    suite of zonal statistics that it provides so we need to use it`s
    ability to include user-defined statistics to return the variance

    https://pythonhosted.org/rasterstats/manual.html#user-defined-statistics
    https://docs.scipy.org/doc/numpy/reference/generated/numpy.var.html

    :param x:
    :return:
    """
    return np.var(x)


#TODO - gt_polygons src needs to be a shapefile i.e. a partition of shapes
def generate_zonal_stats(aoi_geo_min_x, aoi_geo_min_y, aoi_geo_max_x, aoi_geo_max_y, image_metadata):
    """

    :param aoi_geo_min_x: AOI min x
    :param aoi_geo_min_y: AOI min y
    :param aoi_geo_max_x: AOI max x
    :param aoi_geo_max_y: AOI max y
    :param image_metadata: a dict like this: {"<path_to_image>":["<image_day>", "<image_month>", "<image_year>"],}
    :return:
    """
    gt_polygons = fetch_ground_truth_polygons()

    with open("/home/james/Desktop/zonal_stats.csv", "w") as outpf:
        my_writer = csv.writer(outpf, delimiter=',', quotechar='"', quoting=csv.QUOTE_NONNUMERIC)
        my_writer.writerow(
            ["gt_poly_id", "lcgroup", "lctype", "img_fname", "img_date", "band", "zs_count", "zs_mean", "zs_range", "zs_variance"])

        # loop through images
        for img_fname in image_metadata:

            image_day = image_metadata[img_fname][0]
            image_month = image_metadata[img_fname][1]
            image_year = image_metadata[img_fname][2]

            image_date = date(int(image_year), int(image_month), int(image_day))

            this_win_b1, this_affine_b1, window_all_nodata_b1 = fetch_window_from_raster(img_fname, aoi_geo_min_x, aoi_geo_min_y, aoi_geo_max_x, aoi_geo_max_y, band=1)
            this_win_b2, this_affine_b2, window_all_nodata_b2 = fetch_window_from_raster(img_fname, aoi_geo_min_x, aoi_geo_min_y, aoi_geo_max_x, aoi_geo_max_y, band=2)

            # skip calculating zonal stats for images where the returned window onto the image is all nodata
            if (not window_all_nodata_b1) and (not window_all_nodata_b2):
                # in each image, loop through gt polygons
                for gid in gt_polygons:
                    gt_poly = gt_polygons[gid]["geom"]
                    lcgroup = gt_polygons[gid]["lcgroup"]
                    lctype =  gt_polygons[gid]["lctype"]

                    #fetch zonal stats
                    #variance and is provided by rasterstats user defined statistic
                    #TODO - only a subset of these mean, range and variance is actually needed
                    zs_b1 = zonal_stats(
                        gt_poly,
                        this_win_b1,
                        affine=this_affine_b1,  # affine needed as we are passing in an ndarray
                        stats=["count", "mean", "range"],  # zonal stats we want
                        add_stats={'variance': my_variance},
                        all_touched=False  # include every cell touched by geom or only cells with center within geom
                    )[0]

                    band = 1
                    my_writer.writerow([
                        gid, lcgroup, lctype, img_fname, image_date, band, zs_b1["count"], zs_b1["mean"], zs_b1["range"], zs_b1["variance"]
                    ])

                    # fetch zonal stats
                    # var is variance and is provided by rasterstats user defined statistic
                    zs_b2 = zonal_stats(
                        gt_poly,
                        this_win_b2,
                        affine=this_affine_b2,  # affine needed as we are passing in an ndarray
                        stats=["count", "mean", "range"],  # zonal stats we want
                        add_stats={'variance': my_variance},
                        all_touched=False  # include every cell touched by geom or only cells with center within geom
                    )[0]

                    band = 2
                    my_writer.writerow([
                        gid, lcgroup, lctype, img_fname, image_date, band, zs_b2["count"], zs_b2["mean"], zs_b2["range"], zs_b2["variance"]
                    ])
            else:
                print("Skipped {} since window seemed to be all nodata".format(img_fname))


def validate_zonal_stats(fname="/home/james/Desktop/zonal_stats.csv"):
    if os.path.exists(fname):
        odd = {}

        with open(fname, "r") as inpf:
            my_reader = csv.DictReader(inpf)
            for r in my_reader:
                zs_count = r["zs_count"]
                if zs_count == '0':
                    img_fname = r["img_fname"]
                    gt_poly_id = r["gt_poly_id"]
                    if img_fname in odd:
                        if gt_poly_id not in odd[img_fname]:
                            odd[img_fname].append(gt_poly_id)
                    else:
                        odd[img_fname] = [gt_poly_id]

        if len(odd) > 0:
            print("Validation found some problems:")
            for o in odd:
                print(o, len(odd[o]))

#TODO - needs modified so that structure is in the form that Beata needs to ingest into R
def build_ml_labels_features(fname="/home/james/Desktop/zonal_stats.csv"):
    labels_d, features_d = None, None

    if os.path.exists(fname):

        labels_d = {}
        features_d = {}

        with open(fname, "r") as inpf:
            my_reader = csv.DictReader(inpf)
            for r in my_reader:
                zs_count = r["zs_count"]

                # for now, skip cases where image was not read correctly
                # for some reason

                if zs_count != '0':
                    gt_poly_id = int(r["gt_poly_id"])
                    gt_lcgroup = r["lcgroup"]
                    gt_lctype = r["lctype"]
                    band = r["band"]
                    zs_mean = r["zs_mean"]
                    gt_img_date = r["img_date"]
                    # print(gt_poly_id, gt_lcgroup, gt_lctype, gt_img_date, band, zs_mean)

                    if gt_poly_id not in labels_d:
                        labels_d[gt_poly_id] = {"lcgroup": gt_lcgroup, "lctype": gt_lctype}

                    if gt_poly_id in features_d:
                        if gt_img_date in features_d[gt_poly_id]:
                            features_d[gt_poly_id][gt_img_date][band] = zs_mean
                        else:
                            features_d[gt_poly_id][gt_img_date] = {"1": None, "2": None}
                            features_d[gt_poly_id][gt_img_date][band] = zs_mean
                    else:
                        features_d[gt_poly_id] = {gt_img_date: {"1": None, "2": None}}
                        features_d[gt_poly_id][gt_img_date][band] = zs_mean

    return labels_d, features_d


def main():
    aoi_geo_min_x = 363645.98
    aoi_geo_min_y = 619078.236
    aoi_geo_max_x = 380358.43
    aoi_geo_max_y = 636682.04
    md_csv_fname = "/home/james/Downloads/some_images_meta.csv"
    image_metadata = fetch_image_metadata_from_csv(md_csv_fname)

    print("[1] generating zonal stats")
    generate_zonal_stats(aoi_geo_min_x, aoi_geo_min_y, aoi_geo_max_x, aoi_geo_max_y, image_metadata)

    print("[2] validating zonal stats")
    validate_zonal_stats()

    print("[3] build labels and features")
    labels, features = build_ml_labels_features()

    id = 1

    if (labels is not None) and (features is not None):
        print("have built labels and features")

        with open("/home/james/Desktop/sentinel_crop_data_for_ml.csv", "w") as outpf:
            my_writer = csv.writer(outpf, delimiter=",", quotechar='"', quoting=csv.QUOTE_NONNUMERIC)
            my_writer.writerow(["id", "gt_poly_id", "lctype", "lcgroup", "sample_date", "band_1_mean", "band_2_mean"])

            for gt_poly_id in sorted(features.keys()):
                lctype = labels[gt_poly_id]["lctype"]
                lcgroup = labels[gt_poly_id]["lcgroup"]
                for sample_date in features[gt_poly_id]:
                    band_1_measure = features[gt_poly_id][sample_date]["1"]
                    band_2_measure = features[gt_poly_id][sample_date]["2"]
                    my_writer.writerow([id, gt_poly_id, lctype, lcgroup, sample_date, band_1_measure, band_2_measure])
                    id += 1

    else:
        print("both labels and features are empty")


if __name__ == "__main__":
    main()