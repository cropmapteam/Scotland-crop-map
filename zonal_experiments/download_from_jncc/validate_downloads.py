import csv
import os
import pprint

rfi_base_path = "/home/james/serviceDelivery/CropMaps/RFI_masked_images"

c = 1

existing_rfi_masked = []

for root, folders, files in os.walk(rfi_base_path):
    for fn in files:
        if os.path.splitext(fn)[-1] == ".tif":
            if fn not in existing_rfi_masked:
                existing_rfi_masked.append(fn)

with open("/home/james/Desktop/image_urls.csv", "r") as inpf:
    my_reader = csv.reader(inpf)
    for r in my_reader:
        img_fname = r[0].split("/")[-1]
        expected_masked_img_fname = img_fname.replace(".tif", "_rfi_removed.tif")

        if expected_masked_img_fname in existing_rfi_masked:
            print(c, os.path.join(rfi_base_path, expected_masked_img_fname))
            c += 1