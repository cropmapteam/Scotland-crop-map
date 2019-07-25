"""
   as input for the CNN ml, beata needed the set of images produced by
   resize_clipped_images_to_64by64.py greyscaled and then the images
   placed into a Test/Train directory structure specifically required
   by the R CNN ml process. Beata did the greyscaling herself. What
   this script does is take the folder of greyscaled images and creates
   and moves the images into the Test/Train directory structure

   Under each Train/Test folder is a sub-folder for every LCTYPE which
   contains all the images of that LCTYPE

   there is a 60/40 Train/Test split

   if there are less than 4 instances of a particular LCTYPE, the LCTYPE is
   skipped (because 2 in Test/Train in such cases is not enough samples

   data/kelso_image_clips_LUT.csv gives the labels of each image, given:

   S1B_20180922_30_asc_175817_175842_DV_Gamma-0_GB_OSGB_RCTK_SpkRL_450_resized.tif

   450 is an id which there is a record for in data/kelso_image_clips_LUT.csv
"""
import csv
import glob
import os
import shutil


def create_file_structure(base_path_to_images_to_be_moved, base_output_path):
    my_d = {}

    with open("data/kelso_image_clips_LUT.csv", "r") as inpf:
        my_reader = csv.DictReader(inpf)
        for r in my_reader:
            lctype = r["lctype"]
            gid = r["gid"]
            if lctype in my_d:
                my_d[lctype].append(gid)
            else:
                my_d[lctype] = [gid]

    if not os.path.exists(os.path.join(base_output_path, "Test")):
        os.makedirs(os.path.join(base_output_path, "Test"))

    if not os.path.exists(os.path.join(base_output_path, "Train")):
        os.makedirs(os.path.join(base_output_path, "Train"))

    for lctype in my_d:
        instance_gids = my_d[lctype]
        num_instances = len(instance_gids)
        if num_instances < 4:
            # there needs to be at least 4 instances of a feature, otherwise the feature is skipped
            print("Too few instances for {}".format(lctype))
        else:
            print("Number of instances for {} is {}".format(lctype, num_instances))

            split_point = int(round((num_instances / 100.0) * 60))
            idx = 1
            test_or_train_type = None

            for i in instance_gids:
                if idx <= split_point:
                    test_or_train_type = "Train"
                else:
                    test_or_train_type = "Test"
                idx += 1

                images_to_move_path = (os.path.join(base_path_to_images_to_be_moved, "*_SpkRL_{}_*.tif")).format(
                    str(i)
                )

                images_to_move = glob.glob(images_to_move_path)
                num_images_to_move = len(images_to_move)

                for img_to_move in images_to_move:
                    img_to_move_dst = os.path.join(
                        base_output_path,
                        test_or_train_type,
                        lctype,
                        os.path.split(img_to_move)[-1]
                    )

                    if not os.path.exists(os.path.join(base_output_path, test_or_train_type, lctype)):
                        os.makedirs(os.path.join(base_output_path, test_or_train_type, lctype))

                    shutil.copyfile(img_to_move, img_to_move_dst)


def main():
    create_file_structure(
        base_path_to_images_to_be_moved="/home/james/Desktop/KelsoGreyscale-Band2",
        base_output_path="/home/james/Desktop/KelsoGreyscaleRestructuredb2"
    )


if __name__ == "__main__":
    main()