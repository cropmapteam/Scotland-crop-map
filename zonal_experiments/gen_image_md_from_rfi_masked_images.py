"""
    when ran this, load the records into geocrud.image_bounds table, then create the 2 views using:
    create_image_bounds_views.sql
"""

import os
import rasterio
import csv


def generate_metadata(path_to_rfi_masked_images, out_csv_fname):

    # these are masked images for which there appear to be duplicates under
    # the processed_030719 folder. From looking at the duplicate images in
    # QGIS the regions of RFI that is masked varies between the 2. A decision
    # was made based on what was seen in QGIS on whether to stick with the original
    # masked image or instead use the newer duplicate masked image that was processed
    # around 030719. So new = use newer image. So orig = stick with older image
    dup_actions = {
        "S1A_20180928_30_asc_175845_175910_DV_Gamma-0_GB_OSGB_RCTK_SpkRL_rfi_removed.tif": "new",
        "S1B_20180817_30_asc_175815_175840_DV_Gamma-0_GB_OSGB_RCTK_SpkRL_rfi_removed.tif": "new",
        "S1A_20180904_30_asc_175844_175909_DV_Gamma-0_GB_OSGB_RCTK_SpkRL_rfi_removed.tif": "orig",
        "S1A_20180916_30_asc_175844_175909_DV_Gamma-0_GB_OSGB_RCTK_SpkRL_rfi_removed.tif": "orig",
        "S1B_20180910_30_asc_175816_175841_DV_Gamma-0_GB_OSGB_RCTK_SpkRL_rfi_removed.tif": "orig",
        "S1B_20180922_30_asc_175817_175842_DV_Gamma-0_GB_OSGB_RCTK_SpkRL_rfi_removed.tif": "orig"
    }

    rfi_images_to_use = []

    for root, folders, files in os.walk(path_to_rfi_masked_images):
        for fn in files:
            if os.path.splitext(fn)[-1] == ".tif":
                fn_to_use = None

                if fn in dup_actions:
                    dup_action = dup_actions[fn]
                    if dup_action == "new":
                        if "processed_030719" in root:
                            fn_to_use = os.path.join(root, fn)

                    if dup_action == "orig":
                        if "processed_030719" not in root:
                            fn_to_use = os.path.join(root, fn)

                    if fn_to_use is not None:
                        fn_to_use = os.path.join(root, fn_to_use)
                else:
                    fn_to_use = os.path.join(root, fn)

                if fn_to_use is not None:
                    rfi_images_to_use.append(fn_to_use)

    with open(out_csv_fname, "w") as outpf:
        my_writer = csv.writer(outpf, delimiter=",", quotechar='"', quoting=csv.QUOTE_NONNUMERIC)
        my_writer.writerow(["path_to_img", "img_min_x", "img_min_y", "img_max_x", "img_max_y"])

        for img in rfi_images_to_use:
            if os.path.exists(img):
                with rasterio.open(img) as src:
                    my_writer.writerow([
                        img,
                        src.bounds.left,
                        src.bounds.bottom,
                        src.bounds.right,
                        src.bounds.top
                    ])


def main():
    path_to_rfi_masked_images = "/home/james/serviceDelivery/CropMaps/RFI_masked_images"
    out_csv_fname = "/home/james/Desktop/image_bounds_data_from_rfi_masked_images.csv"
    generate_metadata(path_to_rfi_masked_images, out_csv_fname)


if __name__ == "__main__":
    main()
