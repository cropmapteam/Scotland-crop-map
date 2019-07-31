import csv
import glob
import pprint
import os

ml_csv_expected_count = 0
ml_csv_actual_count = 0
missing_ml_csvs = []
missing_or_empty = {"missing":[], "empty":[]}

logs = {}
log_id = 1

for fn in glob.glob("/home/james/geocrud/partitions/*.shp"):
    p_id = (os.path.splitext(os.path.split(fn)[-1])[0]).split("_")[-1]
    expected_csv = os.path.join("/home/james/Desktop/ZS_Scotland", "scotland_full_training_{}_zonal_stats_for_ml.csv".format(p_id))
    if os.path.exists(expected_csv):
        ml_csv_actual_count += 1
    else:
        missing_or_empty["missing"].append(expected_csv)

    ml_csv_expected_count += 1

print("There are {} of {} expected CSVs".format(ml_csv_actual_count, ml_csv_expected_count))
print("The following CSVs are missing:")


if len(missing_or_empty["missing"]) > 0:
    for i in missing_or_empty["missing"]:
        print(i)

print("\nNumber of records/columns in each csv as follows:")
p_number = 1

to_concat = []
for fn in glob.glob("/home/james/Desktop/ZS_Scotland/*_for_ml.csv"):
    num_columns = -999
    with open(fn, "r") as inpf:
        my_reader = csv.DictReader(inpf)
        num_columns = len(my_reader.fieldnames)
        c = 0
        for r in my_reader:
            c += 1

        if c == 0:
            missing_or_empty["empty"].append(fn)
        else:
            to_concat.append(fn)

    print("PartitionNumber: {} {} has {} records, {} columns".format(
        p_number, fn, c, num_columns
    ))

    p_number += 1

print("\nThe following csv`s contain no records:")
if len(missing_or_empty["empty"]) > 0:
    for i in missing_or_empty["empty"]:
        print(i)


print(len(missing_or_empty["missing"]))
print(len(missing_or_empty["empty"]))


def form_empty_out_record():
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


out_record, lut = form_empty_out_record()
header = []
for i in range(1, 306):
    header.append(out_record[i][0])

with open("/home/james/Desktop/scotland_labelled_data_for_ml.csv", "w") as outpf:
    my_writer = csv.writer(outpf, delimiter=",", quotechar='"', quoting=csv.QUOTE_NONNUMERIC)

    my_writer.writerow(header)

    for fn in glob.glob("/home/james/Desktop/ZS_Scotland/*_for_ml.csv"):
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
                    for i in range(1, 306):
                        out_record_to_write.append(out_record[i][1])

                    my_writer.writerow(out_record_to_write)