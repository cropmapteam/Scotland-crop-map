import csv
import os

jncc_urls = []

with open("/home/james/serviceDelivery/CropMaps/theProject/Scotland-crop-map/zonal_experiments/data/Sentinel1_TotalProcessedScenes_20190712.csv", "r") as inpf:
    my_reader = csv.DictReader(inpf)
    for r in my_reader:
        cedaLocationPerDate = r["CEDALocationPerDate"]
        totalFoldersPerDate = int(r["TotalFoldersPerDate"])

        jncc_urls.append(cedaLocationPerDate)


with open("/home/james/Desktop/download_jncc_s1_images.sh", "w") as outpf:
    for i in jncc_urls:
        wget_cmd = "wget -e robots=off -m -nH --cut-dirs=8 -np --reject 'index.*' {}\n".format(
           i
        )
        outpf.write(wget_cmd)







        # img_month = (str(cedaLocationPerDate).split("/")[-3:])[0]
        # img_day = (str(cedaLocationPerDate).split("/")[-3:])[1]
        #
        # expected_path = os.path.join(base_path, img_month, img_day)
        # #print(expected_path, os.path.exists(expected_path))
        #
        # if os.path.exists(expected_path):
        #     num_subdirs = 0
        #
        #     for i in os.listdir(expected_path):
        #         subd = os.path.join(expected_path, i)
        #         if os.path.isdir(subd):
        #             num_subdirs += 1
        #
        #     if num_subdirs != totalFoldersPerDate:
        #         status = "Less subdirs for {} than expected ({} rather than {})".format(
        #             expected_path, num_subdirs, totalFoldersPerDate
        #         )
        #     else:
        #         status = "Seem to have correct number of sub-directories for {}".format(expected_path)
        #
        # else:
        #     status = "Not Found - {}".format(expected_path)
        #
        # print(cedaLocationPerDate, status)