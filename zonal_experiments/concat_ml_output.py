"""
    mp_py_zonal_stats.py will produce a csv for every partition of zones that zonal stats were calculated for
    this script concatenates these individual csv`s into a single csv. Concatenation is complicated by the fact
    that each of the individual csv`s may have a different number of columns as reflecting the images/dates which
    were available for that particular parttions. So the single concatenated csv file has a column count equal to
    the number of columns across the entire dataset with null values for the gaps.

    the script also does a bunch of validation of the individual csv files that mp_py_zonal_stats.py produced by
    checking the csvs against the src shapefiles and reports cases of:

    - missing csvs, i.e. have the src shapefile but no csv
    - reporting csv`s which have no records
    - reporting csv`s which have a record count which differs from the feature count of the src shapefile

    missing csv`s would indicate the processing job failed and needs to be investigated/re-ran
    csv`s which have no records would indicate that the src shape partition fell entirely outside image coverage
    csv`s which have a record count which is not equal to feature count of src shapefile would indicate that some of the
     features in the shapefile fell outside image coverage
"""
import csv
import glob
import os
import fiona


def form_empty_out_record():
    """
    representation of a record in the csv of S1 zonal stats that are passed to the R ml process

    this is the 5 std Id, FID_1, LCGROUP, LCTYPE, AREA columns
    plus number_of_dates x number_of_bands x number of zs stats i.e. 50 x 2 x 3 = 300
    so 305 columns overall

    IF dates changes this will need updated

    :return:
    """
    processed_scenes_dates = {
        1:'2018-01-01',
        2:'2018-01-07',
        3:'2018-01-13',
        4:'2018-01-19',
        5:'2018-01-25',
        6:'2018-01-31',
        7:'2018-02-06',
        8:'2018-02-12',
        9:'2018-02-18',
        10:'2018-02-24',
        11:'2018-03-02',
        12:'2018-03-08',
        13:'2018-03-14',
        14:'2018-03-20',
        15:'2018-03-26',
        16:'2018-04-07',
        17:'2018-04-13',
        18:'2018-04-19',
        19:'2018-04-25',
        20:'2018-05-01',
        21:'2018-05-07',
        22:'2018-05-13',
        23:'2018-05-19',
        24:'2018-05-25',
        25:'2018-05-31',
        26:'2018-06-06',
        27:'2018-06-12',
        28:'2018-06-18',
        29:'2018-06-24',
        30:'2018-06-30',
        31:'2018-07-06',
        32:'2018-07-12',
        33:'2018-07-18',
        34:'2018-07-24',
        35:'2018-07-30',
        36:'2018-08-05',
        37:'2018-08-11',
        38:'2018-08-17',
        39:'2018-08-23',
        40:'2018-08-29',
        41:'2018-09-04',
        42:'2018-09-10',
        43:'2018-09-16',
        44:'2018-09-22',
        45:'2018-09-28',
        46:'2018-10-04',
        47:'2018-10-10',
        48:'2018-10-16',
        49:'2018-10-22',
        50:'2018-10-28'
    }

    out_record = {
        1: ["Id", None],
        2: ["FID_1", None],
        3: ["LCGROUP", None],
        4: ["LCTYPE", None],
        5: ["AREA", None]
    }

    lut = {"Id": 1, "FID_1": 2, "LCGROUP": 3, "LCTYPE": 4, "AREA": 5}

    idx = 6
    for b in ("VV", "VH"):
        for i in range(1, 51):
            for stat in ("mean", "range", "variance"):
                fld_name  = "{}_{}_{}".format(processed_scenes_dates[i], b, stat)
                out_record[idx] = [fld_name, None]
                lut[fld_name] = idx
                idx += 1

    return out_record, lut


def concat_and_validate(path_to_zs_csvs, path_to_src_shps, zs_csv_ptn, output_csv_fn):
    """

    concatenate _zonal_stats_for_ml.csv files produced for each partition into a
    single csv file and do validation of the individual csv`s to check expected
    number of records against input zones etc.

    The concatenation is complicated by the fact that the number of columns
    present in each partition can vary depending on the number of images/dates that
    were present for that particular set of zones

    :param path_to_zs_csvs: the path to the folder of csv`s that mp_py_zonal_stats.py produced
    :param path_to_src_shps: the path to the folder of shapefiles that contain the partitioned zones
    :param zs_csv_ptn: a pattern used to identify the indv csvs files i.e. "*_for_ml.csv"
    :param output_csv_fn: the name of the new single csv file that indv files are concatenated into
    :return:
    """

    ml_csv_expected_count = 0
    ml_csv_actual_count = 0
    missing_or_empty = {"missing":[], "empty":[], "difft_counts":[]}
    shp_counts = {}
    print("\nDoing validation - issues will be reported below")

    for fn in glob.glob(os.path.join(path_to_src_shps, "*.shp")):
        p_id = (os.path.splitext(os.path.split(fn)[-1])[0]).split("_")[-1]
        with fiona.open(fn) as shp_src:
            num_features = len(shp_src)
            shp_counts[p_id] = num_features

        expected_csv = os.path.join(path_to_zs_csvs, "scotland_full_lpis_{}_zonal_stats_for_ml.csv".format(p_id))
        if os.path.exists(expected_csv):
            ml_csv_actual_count += 1
        else:
            missing_or_empty["missing"].append(expected_csv)

        ml_csv_expected_count += 1

    p_number = 1
    to_concat = []

    for fn in glob.glob(os.path.join(path_to_zs_csvs, zs_csv_ptn)):
        p_id = ((os.path.splitext(os.path.split(fn)[-1])[0]).replace("_zonal_stats_for_ml", "")).split("_")[-1]
        num_columns = -999
        row_count = 0
        with open(fn, "r") as inpf:
            my_reader = csv.DictReader(inpf)
            num_columns = len(my_reader.fieldnames)
            for r in my_reader:
                row_count += 1

            if row_count == 0:
                missing_or_empty["empty"].append(fn)
            else:
                to_concat.append(fn)

        num_of_zones_in_shp = None
        if p_id in shp_counts:
            num_of_zones_in_shp = shp_counts[p_id]

        #print("PartitionNumber: {} {} has {} records, {} columns".format(
        #    p_number, fn, row_count, num_columns
        #))

        if num_of_zones_in_shp is None:
            print("Warning! - number of expected rows not available")
        else:
            if row_count != 0:
                if row_count != num_of_zones_in_shp:
                    missing_or_empty["difft_counts"].append(
                        {"fn": fn, "shp_f_count": num_of_zones_in_shp, "csv_r_count": row_count}
                    )
        p_number += 1

    print("\nThere are {} of {} expected CSVs".format(ml_csv_actual_count, ml_csv_expected_count))

    if len(missing_or_empty["missing"]) > 0:
        print("\nThe following CSVs are missing:")
        for i in missing_or_empty["missing"]:
            print(i)

    if len(missing_or_empty["empty"]) > 0:
        print("\nThe following csv`s contain no records:")
        for i in missing_or_empty["empty"]:
            print(i)

    if len(missing_or_empty["difft_counts"]) > 0:
        print("\nThe following csv`s contain difft number of records from those in shape src:")
        for i in missing_or_empty["difft_counts"]:
            msg_str = "{} features in shp: {}, records in csv: {}".format(
                i["fn"], i["shp_f_count"], i["csv_r_count"]
            )
            print(msg_str)

    print("\nConcatenating indv CSVs into single CSV...")

    out_record, lut = form_empty_out_record()
    header = []
    upper_col_idx = len(out_record) + 1

    for i in range(1, upper_col_idx):
        header.append(out_record[i][0])

    with open(output_csv_fn, "w") as outpf:
        my_writer = csv.writer(outpf, delimiter=",", quotechar='"', quoting=csv.QUOTE_NONNUMERIC)

        my_writer.writerow(header)

        for fn in glob.glob(os.path.join(path_to_zs_csvs, zs_csv_ptn)):
            if (fn not in missing_or_empty["missing"]) and (fn not in missing_or_empty["empty"]):
                with open(fn, "r") as inpf:
                    my_reader = csv.DictReader(inpf)
                    fields_in_this_csv = []

                    for f in my_reader.fieldnames:
                        k = lut[f]
                        fields_in_this_csv.append((k, f))

                    for r in my_reader:
                        out_record, lut = form_empty_out_record()

                        for ff in fields_in_this_csv:
                            field_id = ff[0]

                            field_name = ff[1]
                            out_record[field_id][1] = r[field_name]

                        out_record_to_write = []
                        for i in range(1, upper_col_idx):
                            #TODO - write the data to the final concat csv as non-strings
                            # if i == 1:
                            #     out_record_to_write.append(int(out_record[i][1]))
                            # if (i > 1) and (i < 5):
                            #     out_record_to_write.append(out_record[i][1])
                            # else:
                            #     out_record_to_write.append(float(out_record[i][1]))

                            out_record_to_write.append(out_record[i][1])
                        my_writer.writerow(out_record_to_write)


def main():
    path_to_zs_csvs = "/home/james/geocrud/mpzs/for_ml"
    path_to_src_shps = "/home/james/geocrud/partitions"
    zs_csv_ptn = "*_for_ml.csv"
    output_csv_fn = "/home/james/Desktop/scotland_unlabelled_data_for_ml.csv"
    concat_and_validate(path_to_zs_csvs, path_to_src_shps, zs_csv_ptn, output_csv_fn)


if __name__ == "__main__":
    main()