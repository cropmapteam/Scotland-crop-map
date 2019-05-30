import os
import rasterio
import csv

base_path = "/home/james/serviceDelivery/CropMaps/data_from_cropmap_vm_240519/2018"

an_image = None

with open("/home/james/Desktop/image_bounds.csv", "w") as outpf:
    my_writer = csv.writer(outpf, delimiter=",", quotechar='"', quoting=csv.QUOTE_NONNUMERIC)
    my_writer.writerow(["path_to_img", "img_min_x", "img_min_y", "img_max_x", "img_max_y"])

    for root, folders, files in os.walk(base_path):
        for fn in files:
            if os.path.splitext(fn)[-1] == ".tif":
                path_to_img = os.path.join(root, fn)
                with rasterio.open(path_to_img) as src:
                    my_writer.writerow([path_to_img, src.bounds.left, src.bounds.bottom, src.bounds.right, src.bounds.top])











