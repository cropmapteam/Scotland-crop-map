import csv
import os
from datetime import date
import rasterio
from rasterio.windows import Window
from rasterstats import zonal_stats
import numpy as np
import fiona
import shapely
from shapely.geometry import shape, Polygon
from shapely.wkt import loads


def get_aoi_from_shapefile(shp_fname, buffer_d=100):
    """
    from a shapefile obtain it`s buffered extent as an AOI

    :param shp_fname:
    :param buffer_d:
    :return:
    """
    aoi_min_x, aoi_min_y, aoi_max_x, aoi_max_y = None, None, None, None

    if os.path.exists(shp_fname):
        with fiona.open(shp_fname, "r") as shp_src:
            (min_x, min_y, max_x, max_y) = shp_src.bounds
            shp_src_extent = Polygon([(min_x, min_y), (max_x, min_y), (max_x, max_y), (min_x, max_y)])
            aoi = shp_src_extent.buffer(buffer_d)
            (aoi_min_x, aoi_min_y, aoi_max_x, aoi_max_y) = aoi.bounds

    return aoi_min_x, aoi_min_y, aoi_max_x, aoi_max_y


def fetch_image_metadata_from_csv_filtered(md_csv_fname, zones_shp_fname, buffer_d=100):

    image_metadata = None
    all_record_count, filtered_record_count = 0, 0

    if os.path.exists(zones_shp_fname):
        aoi_geom = None

        if os.path.exists(zones_shp_fname):
            with fiona.open(zones_shp_fname, "r") as shp_src:
                (min_x, min_y, max_x, max_y) = shp_src.bounds
                shp_src_extent = Polygon([(min_x, min_y), (max_x, min_y), (max_x, max_y), (min_x, max_y)])
                aoi_geom = shp_src_extent.buffer(buffer_d)

        if aoi_geom is not None:
            image_metadata = {}

            if os.path.exists(md_csv_fname):
                with open(md_csv_fname, "r") as inpf:
                    my_reader = csv.DictReader(inpf)
                    for r in my_reader:
                        path_to_image = r["path_to_image"]
                        image_day = r["image_day"]
                        image_month = r["image_month"]
                        image_year = r["image_year"]
                        geom_wkt = r["geom_wkt"]
                        md_geom = shapely.wkt.loads(geom_wkt)
                        if md_geom.intersects(aoi_geom):
                            image_metadata[path_to_image] = [image_day, image_month, image_year]
                            filtered_record_count += 1
                        all_record_count += 1

    return image_metadata


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


def fetch_window_from_raster(fname, aoi_geo_min_x, aoi_geo_min_y, aoi_geo_max_x, aoi_geo_max_y, band=1, dbg=True):
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

        # TODO - replace with more robust np.isnan(src.read(1)).all() calls to check entire window for nodata
        #  possibly unreliable test to check if the returned window is all nodata values i.e. the part of
        #   the image contains no RS data
        if dbg:
            print("Testing if entire window is nodata for img {}".format(fname))
            print("Window Shape", the_window.shape, the_window.shape(0), the_window.shape(1))

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

# TODO write the csv directly in the form that write_data_to_csv_for_ml() provides to avoid writing, reading and then
#  rewriting the csv
def generate_zonal_stats(image_metadata, zones_shp_fname, output_path):
    """

    :param image_metadata:
    :param zones_shp_fname:
    :return:
    """

    gt_polygons = fetch_zonal_polygons_from_shapefile(shp_fname=zones_shp_fname)
    aoi_geo_min_x, aoi_geo_min_y, aoi_geo_max_x, aoi_geo_max_y = get_aoi_from_shapefile(zones_shp_fname)

    zs_fname = os.path.join(output_path, (os.path.split(zones_shp_fname)[-1]).replace(".shp", "_zonal_stats.csv"))

    with open(zs_fname, "w") as outpf:
        my_writer = csv.writer(outpf, delimiter=',', quotechar='"', quoting=csv.QUOTE_NONNUMERIC)
        my_writer.writerow(
            ["gt_poly_id", "gt_fid_1", "lcgroup", "lctype", "area", "img_fname", "img_date", "band", "zs_count", "zs_mean", "zs_range", "zs_variance"])

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
                    gt_poly_area = gt_polygons[gid]["area"]
                    gt_fid_1 = gt_polygons[gid]["fid_1"]
                    lcgroup = gt_polygons[gid]["lcgroup"]
                    lctype = gt_polygons[gid]["lctype"]

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
                        gid, gt_fid_1, lcgroup, lctype, gt_poly_area, img_fname, image_date, band, zs_b1["count"], zs_b1["mean"], zs_b1["range"], zs_b1["variance"]
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
                        gid, gt_fid_1, lcgroup, lctype, gt_poly_area, img_fname, image_date, band, zs_b2["count"], zs_b2["mean"], zs_b2["range"], zs_b2["variance"]
                    ])
            else:
                print("Skipped {} since window seemed to be all nodata".format(img_fname))

    return zs_fname


def write_data_to_csv_for_ml(zs_csv_fname, csv_for_ml_fname):
    """
    write the zonal stats to a form that is needed for R

    :param zs_csv_fname:
    :param csv_for_ml_fname:
    :return:
    """
    all_dates = []

    if os.path.exists(zs_csv_fname):
        out_data = {}
        with open(zs_csv_fname, "r") as inpf:
            my_reader = csv.DictReader(inpf)
            for r in my_reader:
                zs_count = r["zs_count"]
                if zs_count != 0:
                    gt_poly_id = int(r["gt_poly_id"])
                    gt_fid_1 = r["gt_fid_1"]
                    lcgroup = r["lcgroup"]
                    lctype = r["lctype"]
                    area = r["area"]
                    band = r["band"]
                    zs_mean = r["zs_mean"]
                    zs_range = r["zs_range"]
                    zs_variance = r["zs_variance"]
                    img_date = r["img_date"]
                    if img_date not in all_dates:
                        all_dates.append(img_date)

                    skip = False

                    # we need to skip cases where the data is like this
                    if zs_mean == "" and zs_range == "" and zs_variance == "--":
                        skip = True

                    # or this
                    if zs_mean == "0.0" and zs_range == "0.0" and zs_variance == "0.0":
                        skip = True

                    if not skip:
                        if gt_poly_id not in out_data:
                            out_data[gt_poly_id] = {
                                "gt_fid_1": gt_fid_1,
                                "lcgroup": lcgroup,
                                "lctype": lctype,
                                "area": area,
                                "band_data": {
                                    1: {},
                                    2: {}
                                }
                            }

                        out_data[gt_poly_id]["band_data"][int(band)][img_date] = [zs_mean, zs_range, zs_variance]

        indexed_all_dates = {}
        idx = 1
        for i in sorted(all_dates):
            indexed_all_dates[idx] = i
            idx += 1

        header = ["Id", "FID_1", "LCGROUP", "LCTYPE", "AREA"]
        # band1 is VV
        # band2 is VH
        for b in (1, 2):
            for i in sorted(indexed_all_dates.keys()):
                datestamp = indexed_all_dates[i]
                if b == 1:
                    header.append("_".join([datestamp, "VV", "mean"]))
                    header.append("_".join([datestamp, "VV", "range"]))
                    header.append("_".join([datestamp, "VV", "variance"]))
                if b == 2:
                    header.append("_".join([datestamp, "VH", "mean"]))
                    header.append("_".join([datestamp, "VH", "range"]))
                    header.append("_".join([datestamp, "VH", "variance"]))

        with open(csv_for_ml_fname, "w") as outpf:
            my_writer = csv.writer(outpf, delimiter=',', quotechar='"', quoting=csv.QUOTE_NONNUMERIC)
            my_writer.writerow(header)

            for gt_poly_id in sorted(out_data.keys()):
                ml_data = [gt_poly_id]
                fid_1 = out_data[gt_poly_id]["gt_fid_1"]
                ml_data.append(fid_1)

                lcgroup = out_data[gt_poly_id]["lcgroup"]
                ml_data.append(lcgroup)

                lctype = out_data[gt_poly_id]["lctype"]
                ml_data.append(lctype)

                area = out_data[gt_poly_id]["area"]
                ml_data.append(area)

                for b in (1, 2):
                    band_data = out_data[gt_poly_id]["band_data"][b]
                    for i in sorted(indexed_all_dates.keys()):
                        datestamp = indexed_all_dates[i]
                        zs_mean = None
                        zs_range = None
                        zs_variance = None
                        if datestamp in band_data:
                            zs_mean = band_data[datestamp][0]
                            zs_range = band_data[datestamp][1]
                            zs_variance = band_data[datestamp][2]
                        ml_data.append(zs_mean)
                        ml_data.append(zs_range)
                        ml_data.append(zs_variance)
                my_writer.writerow(ml_data)


def fetch_zonal_stats_for_shapefile(zones_shp_fname, image_metadata_fname, output_path):
    # get image metadata which determines which images we collect zonal stats from
    image_metadata = fetch_image_metadata_from_csv_filtered(image_metadata_fname, zones_shp_fname, buffer_d=100)

    # generate zonal stats
    print("[1] generating zonal stats for {}".format(zones_shp_fname))
    zs_fname = generate_zonal_stats(image_metadata, zones_shp_fname, output_path)

    # reformat the zonal stats csv into the form needed for R
    print("[2] reformatting zonal stats to csv form needed for R")
    csv_for_ml_fname = zs_fname.replace(".csv", "_for_ml.csv")
    write_data_to_csv_for_ml(zs_fname, csv_for_ml_fname)


def mp_fetch_zonal_stats_for_shapefile(job_params):
    """

    version of fetch_zonal_stats_for_shapefile() to have list of params
    mapped to it in a processing pool

    :param job_params: params of fetch_zonal_stats_for_shapefile() as a list
    :return:
    """
    zones_shp_fname = job_params[0]
    image_metadata_fname = job_params[1]
    output_path = job_params[2]

    # get image metadata which determines which images we collect zonal stats from
    image_metadata = fetch_image_metadata_from_csv_filtered(image_metadata_fname, zones_shp_fname, buffer_d=100)

    # generate zonal stats
    print("[1] generating zonal stats for {}".format(zones_shp_fname))
    zs_fname = generate_zonal_stats(image_metadata, zones_shp_fname, output_path)

    # reformat the zonal stats csv into the form needed for R
    print("[2] reformatting zonal stats to csv form needed for R")
    csv_for_ml_fname = zs_fname.replace(".csv", "_for_ml.csv")
    write_data_to_csv_for_ml(zs_fname, csv_for_ml_fname)


def main():
    zones_shp_fname = "/data/Ground_Truth_Polys/kelso/ground_truth_v5_2018_inspection_kelso_250619.shp"
    image_metadata_fname = "data/image_bounds_meta.csv"
    output_path = "/home/geojamesc/geocrud/zonal_stats"

    fetch_zonal_stats_for_shapefile(zones_shp_fname, image_metadata_fname, output_path)


if __name__ == "__main__":
    main()
