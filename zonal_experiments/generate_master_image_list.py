import glob
import os
import csv
import rasterio

processed_scenes_dates = ['20180101', '20180107', '20180113', '20180119', '20180125', '20180131', '20180206',
                          '20180212', '20180218', '20180224', '20180302', '20180308', '20180314', '20180320',
                          '20180326', '20180407', '20180413', '20180419', '20180425', '20180501', '20180507',
                          '20180513', '20180519', '20180525', '20180531', '20180606', '20180612', '20180618',
                          '20180624', '20180630', '20180706', '20180712', '20180718', '20180724', '20180730',
                          '20180805', '20180811', '20180817', '20180823', '20180829', '20180904', '20180910',
                          '20180916', '20180922', '20180928', '20181004', '20181010', '20181016', '20181022',
                          '20181028']

rfi_masked_images = [
    "S1B_20180218_30_asc_175812_175837_DV_Gamma-0_GB_OSGB_RCTK_SpkRL_rfi_removed.tif",
    "S1A_20180119_30_asc_175836_175901_DV_Gamma-0_GB_OSGB_RCTK_SpkRL_rfi_removed.tif",
    "S1A_20180624_30_asc_175840_175905_DV_Gamma-0_GB_OSGB_RCTK_SpkRL_rfi_removed.tif",
    "S1A_20180303_132_asc_175017_175042_DV_Gamma-0_GB_OSGB_RCTK_SpkRL_rfi_removed.tif",
    "S1B_20180113_30_asc_175813_175838_DV_Gamma-0_GB_OSGB_RCTK_SpkRL_rfi_removed.tif",
    "S1B_20180302_30_asc_175747_175812_DV_Gamma-0_GB_OSGB_RCTK_SpkRL_rfi_removed.tif",
    "S1A_20180531_30_asc_175838_175903_DV_Gamma-0_GB_OSGB_RCTK_SpkRL_rfi_removed.tif",
    "S1B_20180218_30_asc_175747_175812_DV_Gamma-0_GB_OSGB_RCTK_SpkRL_rfi_removed.tif",
    "S1B_20180618_30_asc_175812_175837_DV_Gamma-0_GB_OSGB_RCTK_SpkRL_rfi_removed.tif",
    "S1B_20180501_30_asc_175809_175834_DV_Gamma-0_GB_OSGB_RCTK_SpkRL_rfi_removed.tif",
    "S1B_20180724_30_asc_175814_175839_DV_Gamma-0_GB_OSGB_RCTK_SpkRL_rfi_removed.tif",
    "S1A_20180224_30_asc_175835_175900_DV_Gamma-0_GB_OSGB_RCTK_SpkRL_rfi_removed.tif",
    "S1A_20180823_30_asc_175843_175908_DV_Gamma-0_GB_OSGB_RCTK_SpkRL_rfi_removed.tif",
    "S1A_20180425_30_asc_175837_175902_DV_Gamma-0_GB_OSGB_RCTK_SpkRL_rfi_removed.tif",
    "S1B_20180805_30_asc_175814_175839_DV_Gamma-0_GB_OSGB_RCTK_SpkRL_rfi_removed.tif",
    "S1B_20180125_30_asc_175748_175813_DV_Gamma-0_GB_OSGB_RCTK_SpkRL_rfi_removed.tif",
    "S1B_20180101_30_asc_175814_175839_DV_Gamma-0_GB_OSGB_RCTK_SpkRL_rfi_removed.tif",
    "S1A_20180904_30_asc_175844_175909_DV_Gamma-0_GB_OSGB_RCTK_SpkRL_rfi_removed.tif",
    "S1B_20180419_30_asc_175808_175833_DV_Gamma-0_GB_OSGB_RCTK_SpkRL_rfi_removed.tif",
    "S1B_20180302_30_asc_175812_175837_DV_Gamma-0_GB_OSGB_RCTK_SpkRL_rfi_removed.tif",
    "S1B_20180120_132_asc_174936_175001_DV_Gamma-0_GB_OSGB_RCTK_SpkRL_rfi_removed.tif",
    "S1B_20180206_30_asc_175813_175838_DV_Gamma-0_GB_OSGB_RCTK_SpkRL_rfi_removed.tif",
    "S1B_20180125_30_asc_175813_175838_DV_Gamma-0_GB_OSGB_RCTK_SpkRL_rfi_removed.tif",
    "S1B_20180407_30_asc_175813_175838_DV_Gamma-0_GB_OSGB_RCTK_SpkRL_rfi_removed.tif",
    "S1A_20180212_30_asc_175835_175900_DV_Gamma-0_GB_OSGB_RCTK_SpkRL_rfi_removed.tif",
    "S1A_20180131_30_asc_175835_175900_DV_Gamma-0_GB_OSGB_RCTK_SpkRL_rfi_removed.tif",
    "S1B_20180829_30_asc_175816_175841_DV_Gamma-0_GB_OSGB_RCTK_SpkRL_rfi_removed.tif",
    "S1B_20180113_30_asc_175748_175813_DV_Gamma-0_GB_OSGB_RCTK_SpkRL_rfi_removed.tif",
    "S1B_20180712_30_asc_175813_175838_DV_Gamma-0_GB_OSGB_RCTK_SpkRL_rfi_removed.tif",
    "S1A_20180706_30_asc_175840_175905_DV_Gamma-0_GB_OSGB_RCTK_SpkRL_rfi_removed.tif",
    "S1B_20180630_30_asc_175813_175838_DV_Gamma-0_GB_OSGB_RCTK_SpkRL_rfi_removed.tif",
    "S1A_20180308_30_asc_175835_175900_DV_Gamma-0_GB_OSGB_RCTK_SpkRL_rfi_removed.tif",
    "S1B_20180922_30_asc_175817_175842_DV_Gamma-0_GB_OSGB_RCTK_SpkRL_rfi_removed.tif",
    "S1A_20180507_30_asc_175837_175902_DV_Gamma-0_GB_OSGB_RCTK_SpkRL_rfi_removed.tif",
    "S1A_20180916_30_asc_175844_175909_DV_Gamma-0_GB_OSGB_RCTK_SpkRL_rfi_removed.tif",
    "S1A_20180730_30_asc_175842_175907_DV_Gamma-0_GB_OSGB_RCTK_SpkRL_rfi_removed.tif",
    "S1B_20180206_30_asc_175748_175813_DV_Gamma-0_GB_OSGB_RCTK_SpkRL_rfi_removed.tif",
    "S1B_20180513_30_asc_175809_175834_DV_Gamma-0_GB_OSGB_RCTK_SpkRL_rfi_removed.tif",
    "S1B_20180606_30_asc_175811_175836_DV_Gamma-0_GB_OSGB_RCTK_SpkRL_rfi_removed.tif",
    "S1A_20180718_30_asc_175841_175906_DV_Gamma-0_GB_OSGB_RCTK_SpkRL_rfi_removed.tif",
    "S1B_20180525_30_asc_175810_175835_DV_Gamma-0_GB_OSGB_RCTK_SpkRL_rfi_removed.tif",
    "S1B_20180910_30_asc_175816_175841_DV_Gamma-0_GB_OSGB_RCTK_SpkRL_rfi_removed.tif",
    "S1A_20180519_30_asc_175838_175903_DV_Gamma-0_GB_OSGB_RCTK_SpkRL_rfi_removed.tif",
    "S1A_20180612_30_asc_175839_175904_DV_Gamma-0_GB_OSGB_RCTK_SpkRL_rfi_removed.tif",
    "S1A_20180107_30_asc_175836_175901_DV_Gamma-0_GB_OSGB_RCTK_SpkRL_rfi_removed.tif",
    "processed_030719/S1A_20180706_30_asc_175930_175955_DV_Gamma-0_GB_OSGB_RCTK_SpkRL_rfi_removed.tif",
    "processed_030719/S1A_20180811_30_asc_175933_175958_DV_Gamma-0_GB_OSGB_RCTK_SpkRL_rfi_removed.tif",
    "processed_030719/S1A_20180916_30_asc_175909_175934_DV_Gamma-0_GB_OSGB_RCTK_SpkRL_rfi_removed.tif",
    "processed_030719/S1A_20180425_30_asc_175902_175927_DV_Gamma-0_GB_OSGB_RCTK_SpkRL_rfi_removed.tif",
    "processed_030719/S1B_20180829_30_asc_175841_175906_DV_Gamma-0_GB_OSGB_RCTK_SpkRL_rfi_removed.tif",
    "processed_030719/S1A_20180809_1_asc_181508_181533_DV_Gamma-0_GB_OSGB_RCTK_SpkRL_rfi_removed.tif",
    "processed_030719/S1B_20180724_30_asc_175839_175904_DV_Gamma-0_GB_OSGB_RCTK_SpkRL_rfi_removed.tif",
    "processed_030719/S1B_20180817_30_asc_175815_175840_DV_Gamma-0_GB_OSGB_RCTK_SpkRL_rfi_removed.tif",
    "processed_030719/S1B_20180407_30_asc_175838_175903_DV_Gamma-0_GB_OSGB_RCTK_SpkRL_rfi_removed.tif",
    "processed_030719/S1A_20180624_30_asc_175930_175955_DV_Gamma-0_GB_OSGB_RCTK_SpkRL_rfi_removed.tif",
    "processed_030719/S1B_20180511_1_asc_181421_181446_DV_Gamma-0_GB_OSGB_RCTK_SpkRL_rfi_removed.tif",
    "processed_030719/S1A_20180716_1_asc_181507_181532_DV_Gamma-0_GB_OSGB_RCTK_SpkRL_rfi_removed.tif",
    "processed_030719/S1B_20180712_30_asc_175838_175903_DV_Gamma-0_GB_OSGB_RCTK_SpkRL_rfi_removed.tif",
    "processed_030719/S1A_20180224_30_asc_175900_175925_DV_Gamma-0_GB_OSGB_RCTK_SpkRL_rfi_removed.tif",
    "processed_030719/S1A_20180425_30_asc_175927_175952_DV_Gamma-0_GB_OSGB_RCTK_SpkRL_rfi_removed.tif",
    "processed_030719/S1A_20180928_30_asc_175845_175910_DV_Gamma-0_GB_OSGB_RCTK_SpkRL_rfi_removed.tif",
    "processed_030719/S1B_20180815_1_asc_181426_181451_DV_Gamma-0_GB_OSGB_RCTK_SpkRL_rfi_removed.tif",
    "processed_030719/S1A_20180624_30_asc_175905_175930_DV_Gamma-0_GB_OSGB_RCTK_SpkRL_rfi_removed.tif",
    "processed_030719/S1A_20180823_30_asc_175908_175933_DV_Gamma-0_GB_OSGB_RCTK_SpkRL_rfi_removed.tif",
    "processed_080719/S1A_20180308_30_asc_175925_175950_DV_Gamma-0_GB_OSGB_RCTK_SpkRL_rfi_removed.tif",
    "processed_080719/S1B_20181028_30_asc_175752_175817_DV_Gamma-0_GB_OSGB_RCTK_SpkRL_rfi_removed.tif",
    "processed_080719/S1A_20180119_30_asc_175926_175951_DV_Gamma-0_GB_OSGB_RCTK_SpkRL_rfi_removed.tif",
    "processed_080719/S1A_20180320_30_asc_175835_175900_DV_Gamma-0_GB_OSGB_RCTK_SpkRL_rfi_removed.tif",
    "processed_080719/S1B_20181028_30_asc_175817_175842_DV_Gamma-0_GB_OSGB_RCTK_SpkRL_rfi_removed.tif",
    "processed_080719/S1B_20181004_30_asc_175842_175907_DV_Gamma-0_GB_OSGB_RCTK_SpkRL_rfi_removed.tif",
    "processed_080719/S1B_20180314_30_asc_175812_175837_DV_Gamma-0_GB_OSGB_RCTK_SpkRL_rfi_removed.tif",
    "processed_080719/S1A_20181022_30_asc_175845_175910_DV_Gamma-0_GB_OSGB_RCTK_SpkRL_rfi_removed.tif",
    "processed_080719/S1B_20180326_30_asc_175813_175838_DV_Gamma-0_GB_OSGB_RCTK_SpkRL_rfi_removed.tif",
    "processed_080719/S1B_20180827_1_asc_181427_181452_DV_Gamma-0_GB_OSGB_RCTK_SpkRL_rfi_removed.tif",
    "processed_080719/S1B_20180326_30_asc_175748_175813_DV_Gamma-0_GB_OSGB_RCTK_SpkRL_rfi_removed.tif",
    "processed_080719/S1B_20181004_30_asc_175817_175842_DV_Gamma-0_GB_OSGB_RCTK_SpkRL_rfi_removed.tif",
    "processed_080719/S1A_20180107_30_asc_175926_175951_DV_Gamma-0_GB_OSGB_RCTK_SpkRL_rfi_removed.tif",
    "processed_080719/S1B_20180501_30_asc_175859_175924_DV_Gamma-0_GB_OSGB_RCTK_SpkRL_rfi_removed.tif",
    "processed_080719/S1B_20180314_30_asc_175747_175812_DV_Gamma-0_GB_OSGB_RCTK_SpkRL_rfi_removed.tif",
    "processed_080719/S1B_20180805_30_asc_175904_175929_DV_Gamma-0_GB_OSGB_RCTK_SpkRL_rfi_removed.tif",
    "processed_080719/S1B_20181016_30_asc_175817_175842_DV_Gamma-0_GB_OSGB_RCTK_SpkRL_rfi_removed.tif",
    "processed_080719/S1A_20181010_30_asc_175845_175910_DV_Gamma-0_GB_OSGB_RCTK_SpkRL_rfi_removed.tif",
    "processed_290719/S1B_20180501_30_asc_175744_175809_DV_Gamma-0_GB_OSGB_RCTK_SpkRL_rfi_removed.tif",
    "processed_290719/S1B_20180513_30_asc_175744_175809_DV_Gamma-0_GB_OSGB_RCTK_SpkRL_rfi_removed.tif",
    "processed_290719/S1B_20180525_30_asc_175810_175835_DV_Gamma-0_GB_OSGB_RCTK_SpkRL_rfi_removed.tif",
    "processed_290719/S1B_20180525_30_asc_175900_175925_DV_Gamma-0_GB_OSGB_RCTK_SpkRL_rfi_removed.tif",
    "processed_290719/S1B_20180606_30_asc_175746_175811_DV_Gamma-0_GB_OSGB_RCTK_SpkRL_rfi_removed.tif",
    "processed_290719/S1B_20180618_30_asc_175902_175927_DV_Gamma-0_GB_OSGB_RCTK_SpkRL_rfi_removed.tif",
    "processed_290719/S1B_20180724_30_asc_175749_175814_DV_Gamma-0_GB_OSGB_RCTK_SpkRL_rfi_removed.tif",
    "processed_290719/S1B_20180829_30_asc_175751_175816_DV_Gamma-0_GB_OSGB_RCTK_SpkRL_rfi_removed.tif",
    "processed_290719/S1B_20180910_30_asc_175751_175816_DV_Gamma-0_GB_OSGB_RCTK_SpkRL_rfi_removed.tif",
    "processed_290719/S1B_20180922_30_asc_175752_175817_DV_Gamma-0_GB_OSGB_RCTK_SpkRL_rfi_removed.tif",
    "processed_290719/S1B_20180922_30_asc_175907_175932_DV_Gamma-0_GB_OSGB_RCTK_SpkRL_rfi_removed.tif",
    "processed_290719/S1B_20181004_30_asc_175907_175932_DV_Gamma-0_GB_OSGB_RCTK_SpkRL_rfi_removed.tif",
    "processed_290719/S1B_20181028_30_asc_175752_175817_DV_Gamma-0_GB_OSGB_RCTK_SpkRL_rfi_removed.tif",
]

# change on epcc vm
base_path_to_rfi_images = "/data/Sentinel1/RFI_masked_images"

# change on epcc vm
base_path_to_jncc_images = "/data/Sentinel1/jncc_supplied_images/images_from_jncc_250719"

# change on epcc vm
out_csv_fname = "/home/geojamesc/image_bounds_meta_290719.csv"

jncc_images = []

for jncc_fn in glob.glob(os.path.join(base_path_to_jncc_images, "*.tif")):
    jncc_images.append(jncc_fn)

for jncc_fn in glob.glob(os.path.join(base_path_to_jncc_images, "to_be_masked/*.tif")):
    jncc_images.append(jncc_fn)

master_images = []

for jncc_fn in jncc_images:
    src_version = os.path.split(jncc_fn)[-1]
    rfi_version = None
    for rfi_fn in rfi_masked_images:
        if "/" in rfi_fn:
            rfi_img = (rfi_fn.split("/")[-1]).replace("_rfi_removed.tif", ".tif")
        else:
            rfi_img = rfi_fn.replace("_rfi_removed.tif", ".tif")

        if rfi_img == src_version:
            rfi_version = rfi_fn

    img_to_use = None

    if rfi_version is None:
        img_to_use = os.path.join(base_path_to_jncc_images, src_version)
    else:
        img_to_use = os.path.join(base_path_to_rfi_images, rfi_version)

    master_images.append(img_to_use)

unq = []
not_unq = 0

for img in master_images:
    fn = os.path.split(img)[-1]
    if fn not in unq:
        unq.append(fn)
    else:
        not_unq += 1

if not_unq != 0:
    print("Duplicates are present")

df_master_images = []
for img in master_images:
    fn = os.path.split(img)[-1]
    processed_date = fn.split("_")[1]
    if processed_date in processed_scenes_dates:
        df_master_images.append(img)
    else:
        print("{} is not in processed_scenes_date, so excluded")

print("Master set of images is:")

rfi_masked_count = 0
non_rfi_masked_count = 0
total_number_of_images = len(df_master_images)
unfound_image_count = 0

unfound_images = []
for img in df_master_images:
    if not os.path.exists(img):
        unfound_image_count += 1
        unfound_images.append(img)

    if "RFI_masked_images" in img:
        rfi_masked_count += 1
    else:
        non_rfi_masked_count += 1
    print(img)

print("Total Number of images: {}, of which {} are untouched, {} have been RFI-masked".format(
    total_number_of_images,
    non_rfi_masked_count,
    rfi_masked_count
))

with open(out_csv_fname, "w") as outpf:
    my_writer = csv.writer(outpf, delimiter=",", quotechar='"', quoting=csv.QUOTE_NONNUMERIC)
    my_writer.writerow(["path_to_img", "img_min_x", "img_min_y", "img_max_x", "img_max_y"])

    for img in df_master_images:
        if not os.path.exists(img):
            unfound_image_count += 1
            unfound_images.append(img)
        else:
            with rasterio.open(img) as src:
                my_writer.writerow([
                    img,
                    src.bounds.left,
                    src.bounds.bottom,
                    src.bounds.right,
                    src.bounds.top
                ])

        if "RFI_masked_images" in img:
            rfi_masked_count += 1
        else:
            non_rfi_masked_count += 1
        print(img)


if unfound_image_count > 0:
    print("Warning! {} of images not found".format(unfound_image_count))
    for ufimg in unfound_images:
        print(ufimg)
